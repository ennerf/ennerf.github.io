# jekyll-asciidoc promotes `:page-tags: a, b, c` to a single String, but Chirpy and
# jekyll-archives expect `tags` to be an Array.
#
# Two passes are needed: jekyll-archives runs its generator before jekyll-asciidoc's
# Integrator has read any AsciiDoc header, so the tags have to be parsed out of the raw
# source at :post_read for the archives (and site.tags) to see them, and split again
# after the Integrator has overwritten them with its own String value.
module AsciidocTags
  KEYS = %w[tags categories].freeze

  def self.split(value)
    value.split(',').map(&:strip).reject(&:empty?)
  end

  def self.normalize(post)
    KEYS.each do |key|
      value = post.data[key]
      post.data[key] = split(value) if value.is_a?(String)
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each do |post|
    next unless File.extname(post.path) == '.adoc'

    AsciidocTags::KEYS.each do |key|
      match = post.content[/^:page-#{key}:[ \t]*(.*)$/, 1]
      post.data[key] = AsciidocTags.split(match) if match
    end
  end
end

module Jekyll
  class AsciidocTagSplitter < Generator
    safe true
    priority :low

    def generate(site)
      site.posts.docs.each { |post| AsciidocTags.normalize(post) }
    end
  end
end
