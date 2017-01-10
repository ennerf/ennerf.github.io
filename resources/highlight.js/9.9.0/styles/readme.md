# Adding MATLAB-style syntax highlighting to Asciidoc

The highlight.js version bundled by default does not include support for MATLAB. Additionally, the standard styles don't work well for highlighting MATLAB syntax. The code below can be used to to remove the default highlighter and add a stylesheet that overrides the style for MATLAB to match the default editor.

Deactivate source highlighter by specifying invalid string

```asciidoc
:source-highlighter: none
```

Pass-through highlight.js styles and scripts

```html
++++
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/styles/github.min.css">
<link rel="stylesheet" href="https://cdn.rawgit.com/ennerf/ennerf.github.io/master/resources/highlight.js/9.9.0/styles/matlab-override.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/highlight.min.js"></script>
<script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/languages/matlab.min.js"></script>
<script>hljs.initHighlightingOnLoad()</script>
++++
```