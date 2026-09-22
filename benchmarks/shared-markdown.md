# Rendering benchmark

This fixture covers the Markdown constructs supported by both v0.1 and v0.2.
It gives a repeatable parser-and-HTML-renderer comparison without widget setup.

## Section one

This paragraph has **strong emphasis**, *emphasis*, `inline code`, and a
[link label](https://example.test/path) whose destination is discarded by the
new renderer.

- first unordered item
- second item with **bold text**
- third item with `code`

1. first ordered item
2. second ordered item

```text
fenced code block
with two lines
```

## Section two

Another paragraph with enough repeated prose to exercise text escaping and
HTML generation on a realistic small preview document. Markdown previews are
bounded to four MiB, but most notes are much shorter than the input limit.

- heading parsing
- paragraph parsing
- list parsing
- inline formatting
- code block rendering

## Section three

This fixture intentionally uses only constructs supported by both renderers.
The new parser additionally supports tables, task lists, strikethrough, and
footnotes.
