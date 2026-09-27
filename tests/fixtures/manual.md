# Markdown Cocoa manual test — čeština 🦀

Resize the Lister, scroll, select and copy text, and close it with Escape.
Open and close it repeatedly, including closing immediately after F3.

## Markdown formatting

**Bold**, *italic*, ~~strikethrough~~, and `inline code`.

- [x] Completed task
- [ ] Pending task
  - Nested item

1. First item
2. Second item

> Block quote with a longer line that should wrap when the window is narrow.

| Platform | Backend | Architecture |
| --- | --- | --- |
| Linux | Qt5 | Native |
| macOS | Cocoa / WebKit | Apple Silicon |

```rust
fn main() {
    println!("No code in this document executes.");
}
```

A footnote reference.[^example]

[^example]: Footnote content should be visible; navigation stays disabled.

## Inert content

[Remote link label](https://example.com/markdown-wlx-manual-test)

[Local file label](file:///etc/passwd)

![Remote image alt text](https://example.com/markdown-wlx-test.png)

![Local image alt text](file:///etc/passwd)

<script>alert('This must be shown as text, never executed.')</script>

<img src="https://example.com/raw-html-test.png" onerror="alert('blocked')">

<iframe src="https://example.com/"></iframe>

<a href="file:///etc/passwd">Raw HTML link must be displayed as text.</a>

## Long text

The quick brown fox jumps over the lazy dog. Příliš žluťoučký kůň úpěl
ďábelské ódy. This paragraph should wrap naturally when resizing the Lister
and remain selectable. The plugin must not fetch any resources while
rendering this document.
