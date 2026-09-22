# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

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

### Not yet tested

- GTK2, GTK3, and Qt6 F3 integration in a running Double Commander instance.
- Full CommonMark or GitHub-Flavored Markdown compatibility.
