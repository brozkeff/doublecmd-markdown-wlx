# Markdown WLX viewer for Double Commander

Standalone Linux Qt5 WLX (Lister) plugin for quick F3 previews of Markdown
files inside Double Commander. The plugin is implemented in Rust and does not
require a Double Commander fork or rebuild.

Copyright (C) 2026 Martin Brozkeff Malec. Licensed under the [European Union
Public Licence 1.2](LICENSE).

## Features and safety

The plugin claims `.md`, `.markdown`, and `.mdown` files and renders CommonMark
with tables, task lists, strikethrough, and footnotes. It also supports
headings, paragraphs, lists, emphasis, inline and fenced code, block quotes,
and UTF-8 files with an optional UTF-8 BOM.
Press Escape to close the active Lister window.

Raw HTML is displayed as escaped text. Markdown links are rendered as their
labels, and images as their alt text. Link destinations and image resources
are not loaded; scripts and remote resources are never executed or fetched.
Files larger than 4 MiB are rejected so Double Commander can use its normal
fallback viewer. Invalid UTF-8 bytes are replaced safely for display.

The Rust parser is [pulldown-cmark](https://github.com/pulldown-cmark/pulldown-cmark),
a CommonMark parser with optional GFM-style extensions. The plugin enables its
HTML writer but filters raw HTML, links, and images before rendering. The
optional SIMD feature is disabled. See [third-party notices](THIRD-PARTY-NOTICES.md)
for dependency license details.

## WLX interface and Qt5 target

The plugin exports the Total Commander-compatible WLX functions
`ListGetDetectString`, `ListLoad`, and `ListCloseWindow`, plus
`MarkdownWlxLicense` and `MarkdownWlxVersion`. It detects:

```text
EXT="MD" | EXT="MARKDOWN" | EXT="MDOWN"
```

The Rust library implements the WLX interface and rendering. A small C++ shim
creates and destroys a read-only `QTextBrowser` inside the existing Qt5 host
widget. It uses the host's Qt event loop and does not start another Qt
application. This build is for Qt5 Double Commander only; do not load it into
Qt6 or GTK builds.

## Requirements

Build requirements:

- Rust 1.82 or newer and Cargo;
- a C++17 compiler and `pkg-config`;
- Qt 5.15 Widgets development files.

At runtime, the matching Qt5 libraries are supplied by the host system. Qt
libraries are dynamically linked and are not bundled into the plugin.

## Build and install

Build the Qt5 plugin:

```sh
./scripts/build.sh qt5
```

The output is written to `build/markdown-wlx-<architecture>-linux-qt5.wlx`.
The build strips non-loadable symbols and debug information while retaining
the exported WLX functions. Rust dependencies are locked in `Cargo.lock`.

Install the resulting file in Double Commander under Options → Plugins → WLX.
Select a Markdown file and press F3. The plugin must match the Qt5 widgetset
and architecture of the running Double Commander.

## Verification

Run Rust checks and the ABI smoke test with:

```sh
cargo fmt --all -- --check
cargo test --locked --all-features
cargo clippy --locked --all-targets --all-features -- -D warnings
./scripts/smoke-test.sh
./scripts/benchmark-render.sh
```

The smoke test checks exported WLX symbols, shared-library loading, Qt5
linkage, detection string, license, version, and an offscreen host's widget
creation, resize, and close lifecycle. The renderer benchmark compares the
shared Markdown subset against the archived v0.1 Pascal parser. The v0.2.0
build was manually verified with F3 in Qt5 Double Commander.

## Repository layout

```text
Cargo.toml, Cargo.lock       Rust cdylib package and pinned dependencies
build.rs                     Qt5 C++ shim build configuration
src/lib.rs                   WLX ABI and bounded file handling
src/markdown.rs              Safe Markdown event filtering and rendering
src/qt5_shim.cpp             Minimal Qt5 widget bridge
tests/                       Separate Rust unit tests and offscreen Qt host checks
benchmarks/                  Shared renderer benchmark fixture and harness
scripts/build.sh             Qt5 release build
scripts/smoke-test.sh        ABI and load smoke test
v0.1/                        Archived Pascal implementation for review
build/                        Ignored generated WLX artifact
```

Project version history is in [CHANGELOG.md](CHANGELOG.md). Architecture
decisions are in [`docs/decisions/`](docs/decisions/). Read the [Rust and Qt
boundary assessment](docs/security/rust-qt-ffi-assessment-2026-09-23.md) for
the FFI lifecycle findings.
