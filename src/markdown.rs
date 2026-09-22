// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2.

use pulldown_cmark::{html, Event, Options, Parser, Tag, TagEnd};

const STYLE: &str = r#"
body { font-family: sans-serif; font-size: 10pt; margin: 12px; }
h1, h2, h3, h4, h5, h6 { margin-top: 12px; margin-bottom: 4px; }
p { margin: 4px 0; }
pre, code { font-family: monospace; }
pre { background-color: #eeeeee; padding: 6px; white-space: pre-wrap; }
blockquote { margin-left: 12px; padding-left: 8px; border-left: 3px solid #888888; }
table { border-collapse: collapse; }
th, td { border: 1px solid #888888; padding: 4px; }
"#;

fn safe_event(event: Event<'_>) -> Option<Event<'_>> {
    match event {
        // The parser recognizes raw HTML, but it is only displayed as escaped text.
        Event::Html(raw) | Event::InlineHtml(raw) => Some(Event::Text(raw)),
        // Keep link labels and image alt text, while omitting their destinations.
        Event::Start(Tag::Link { .. })
        | Event::End(TagEnd::Link)
        | Event::Start(Tag::Image { .. })
        | Event::End(TagEnd::Image) => None,
        // QTextBrowser does not reliably render form controls; use inert markers.
        Event::TaskListMarker(checked) => {
            Some(Event::Text(if checked { "[x] " } else { "[ ] " }.into()))
        }
        other => Some(other),
    }
}

pub fn render_to_html(source: &str) -> String {
    let mut options = Options::empty();
    options.insert(Options::ENABLE_TABLES);
    options.insert(Options::ENABLE_TASKLISTS);
    options.insert(Options::ENABLE_STRIKETHROUGH);
    options.insert(Options::ENABLE_FOOTNOTES);

    let parser = Parser::new_ext(source, options).filter_map(safe_event);
    let mut document = String::with_capacity(source.len().saturating_add(512));
    document.push_str("<!doctype html><html><head><meta charset=\"utf-8\"><style>");
    document.push_str(STYLE);
    document.push_str("</style></head><body>");
    html::push_html(&mut document, parser);
    document.push_str("</body></html>");
    document
}

#[cfg(test)]
mod tests {
    use super::render_to_html;

    #[test]
    fn renders_commonmark_and_gfm_extensions() {
        let html = render_to_html(
            "# Heading\n\n~~old~~ **bold**\n\n| A | B |\n| - | - |\n| 1 | 2 |\n\n- [x] done\n- [ ] todo\n",
        );

        assert!(html.contains("<h1>Heading</h1>"));
        assert!(html.contains("<del>old</del>"));
        assert!(html.contains("<strong>bold</strong>"));
        assert!(html.contains("<table>"));
        assert!(html.contains("[x] done"));
        assert!(html.contains("[ ] todo"));
    }

    #[test]
    fn renders_footnotes_without_external_destinations() {
        let html = render_to_html("Text[^note].\n\n[^note]: Footnote text.\n");

        assert!(html.contains("Footnote text."));
        assert!(html.contains("href=\"#"));
        assert!(!html.contains("https://"));
    }

    #[test]
    fn renders_raw_html_as_escaped_text() {
        let html = render_to_html("<script>alert(1)</script>\n<img src=x onerror=alert(1)>\n");

        assert!(html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"));
        assert!(html.contains("&lt;img src=x onerror=alert(1)&gt;"));
        assert!(!html.contains("<script"));
        assert!(!html.contains("<img"));
    }

    #[test]
    fn renders_links_as_text_and_images_as_alt_text() {
        let html = render_to_html(
            "[external label](https://example.test) [unsafe label](javascript:alert(1)) ![image alt](https://example.test/image.png)\n",
        );

        assert!(html.contains("external label"));
        assert!(html.contains("unsafe label"));
        assert!(html.contains("image alt"));
        assert!(!html.contains("href=\"https://"));
        assert!(!html.contains("href=\"javascript:"));
        assert!(!html.contains("src=\""));
    }
}
