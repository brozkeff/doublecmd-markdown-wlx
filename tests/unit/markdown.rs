use super::render_to_html;

#[test]
fn empty_input_still_returns_a_complete_document() {
    let html = render_to_html("");
    assert!(html.starts_with("<!doctype html>"));
    assert!(html.ends_with("</body></html>"));
}

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
