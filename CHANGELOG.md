# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [v0.2.0] - 2026-09-22

### Changed

- Replaced the Pascal/Lazarus implementation with a Rust Qt5 WLX plugin.
- Replaced the custom Markdown subset parser with `pulldown-cmark` CommonMark
  and tables, task lists, strikethrough, and footnotes.
- Archived replaced v0.1 implementation files under `v0.1/` for review.

### Security

- Keep the 4 MiB preview limit and safely replace invalid UTF-8.
- Display raw HTML only as escaped text; do not navigate Markdown links, load
  images or remote resources, or execute active content.
- Contain Rust panics and C++ exceptions at the WLX boundary.

### Tested

- Manually verified F3 preview in Qt5 Double Commander.

### Build

- Build the Qt5 plugin as a Rust `cdylib` with a minimal C++ widget shim.
- Keep Qt5 dynamically linked and strip debug information from the release
  artifact.

## [v0.1.1] - 2026-09-22

### Changed

- Strip release WLX artifacts to remove debug information and non-loadable
  symbol tables, reducing Qt5 and Qt6 binaries from about 30 MiB to about
  10 MiB while retaining dynamic Qt/QtPas dependencies and exported WLX
  symbols.

## [v0.1.0] - 2026-09-22

### Added

- Initial standalone Linux WLX plugin for Markdown F3 previews.
- Qt5 and GTK3 native viewer backends.
- GTK2 native viewer backend using Pango markup.
- Conditional Qt6 backend implementation.
- Safe dependency-free Markdown subset renderer.
- UTF-8 and UTF-8 BOM input handling.
- Reproducible widgetset build and ABI smoke-test scripts.
- EUPL 1.2 licensing and repository ownership metadata.

### Security

- Bound Markdown input to 4 MiB and reject oversized or missing-file inputs
  before rendering, allowing Double Commander to use its normal fallback.
- Escape generated Qt HTML and GTK/Pango markup; do not load raw HTML, links,
  images, remote resources, or scripts from Markdown files.

### Tested

- Qt5, Qt6, GTK2, and GTK3 x86_64 Linux builds.
- Qt6 linking with Ubuntu 22.04 Qt6 packages and the `libqt6pas` 6.2.10
  amd64 DEBs from `davidbannon/libqt6pas`.
- WLX symbol exports and shared-library loading.
- Qt5 F3 integration with Double Commander 1.2.8; GTK2, GTK3, and Qt6 remain
  untested interactively in Double Commander.
