// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2.

use pulldown_cmark::{html, Event, Options, Parser, Tag, TagEnd};

#[cfg(test)]
#[path = "../tests/unit/markdown.rs"]
mod tests;

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
