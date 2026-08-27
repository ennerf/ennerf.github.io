@echo off
rem Serves the blog at http://localhost:4000 with live reload. Needs Docker Desktop; gems are cached in a Docker volume after the first run.
docker run --rm -it -p 4000:4000 -v "%~dp0:/srv" -v ennerf-blog-gems:/usr/local/bundle -w /srv ruby:3.3 bash -c "bundle install && bundle exec jekyll serve --config _config.yml,_config.local.yml --host 0.0.0.0 --force_polling"
