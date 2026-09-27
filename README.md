# Markdown WLX viewer for Double Commander

Standalone Linux Qt5 and Apple Silicon macOS Cocoa WLX (Lister) plugin for
quick F3 previews of Markdown files inside Double Commander. The plugin is
implemented in Rust and does not require a Double Commander fork or rebuild.

Copyright (C) 2026 Martin Brozkeff Malec. Licensed under the [European Union
Public Licence 1.2](LICENSE).

Version **0.3.0** adds a native Apple Silicon Cocoa backend alongside Linux Qt5.

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

## WLX interface and native targets

The plugin exports the Total Commander-compatible WLX functions
`ListGetDetectString`, `ListLoad`, and `ListCloseWindow`, plus
`MarkdownWlxLicense` and `MarkdownWlxVersion`. It detects:

```text
EXT="MD" | EXT="MARKDOWN" | EXT="MDOWN"
```

The shared Rust library implements the WLX interface and rendering. On Linux,
a small C++ shim creates and destroys a read-only `QTextBrowser` inside the existing Qt5 host
widget. It uses the host's Qt event loop and does not start another Qt
application. The Linux build is for Qt5 Double Commander only; do not load it
into Qt6 or GTK builds.

On Apple Silicon macOS, a small ARC Objective-C++ shim creates an `NSView`
containing a `WKWebView` in the Cocoa host. It displays the same sanitized
HTML and CSS, with JavaScript disabled, a nonpersistent data store, restrictive
content security policy, and navigation and new windows blocked. It uses
the host's application and main thread; no Qt libraries are needed on macOS.

## Requirements

Shared build requirements:

- Rust 1.82 or newer and Cargo;
- a C++17 compiler.

Linux additionally requires `pkg-config` and Qt 5.15 Widgets development
files. Apple Silicon macOS requires Apple's Command Line Tools
(`xcode-select --install`), a native ARM64 Rust toolchain, and Python 3 for
the ABI smoke check. WebKit APIs require macOS 11 or newer; older systems
have not been tested.

Python 3 is required for the ABI smoke check on both platforms. Linux GUI
smoke checks also require the Qt5 development files and C++ compiler.

At runtime, the matching Qt5 libraries are supplied by the host system. Qt
libraries are dynamically linked and are not bundled into the plugin.
On macOS, AppKit and WebKit are supplied by the operating system.

## Build and install

Build the native plugin locally:

```sh
./scripts/build.sh
```

On Linux the output is `build/markdown-wlx-<architecture>-linux-qt5.wlx`.
On Apple Silicon macOS it is `build/markdown-wlx-aarch64-darwin-cocoa.wlx`.
Explicit `./scripts/build.sh qt5` on Linux and `./scripts/build.sh cocoa` on
macOS are also accepted. Each build selects only its native platform, rejects
mismatched backends, and overrides Cargo's configured target. No cross builds
or universal binaries are produced. Run the helper from any working directory.
The build strips non-loadable symbols and debug information while retaining
the exported WLX functions. macOS artifacts are ad-hoc signed after stripping.
Rust dependencies are locked in `Cargo.lock`.

Install the resulting file in Double Commander under Options → Plugins → WLX.
Select a Markdown file and press F3. The plugin must match the running Double
Commander's widgetset and architecture: Qt5 on Linux, native ARM64 Cocoa on
macOS.

Optionally copy the macOS artifact to a user plugin directory first:

```sh
./scripts/install-macos.sh
# Or choose a destination:
./scripts/install-macos.sh /path/to/plugins/markdown-wlx
```

The default destination is
`~/Library/Application Support/doublecmd/plugins/markdown-wlx/`. The helper
prints the installed path; register it manually under Options → Plugins → WLX.
It does not change Double Commander's configuration or app bundle. Restart
Double Commander before using a replacement for an already loaded plugin.

## Verification

Run Rust checks and the ABI smoke test with:

```sh
cargo fmt --all -- --check
cargo test --locked --all-features
cargo clippy --locked --all-targets --all-features -- -D warnings
./scripts/smoke-test.sh
```

The smoke test checks exported WLX symbols, shared-library loading, native
dependencies, detection string, license, and version. Linux additionally
checks an offscreen host's widget creation, resize, and close lifecycle.
macOS checks Mach-O ARM64 architecture, AppKit/WebKit linkage, absence of Qt,
and the ad-hoc signature; Cocoa GUI testing is manual.

The optional `./scripts/benchmark-render.sh` requires Free Pascal and compares
the shared Markdown subset against the archived v0.1 Pascal parser. The v0.2.0
build was manually verified with F3 in Qt5 Double Commander.

### Manual macOS acceptance test

The initial target is Double Commander 1.2.7 gamma, revision 359, commit
`3a3c1ab3e`, `aarch64-Darwin-cocoa`, on macOS 27.0.0. The Cocoa plugin has
been built and ABI checked locally, and the user reports that manual testing
of the copied plugin works. The checklist below is available for broader
release validation. Linux runtime regression checks must be run separately
on Linux.

- Register the Cocoa artifact, then preview `tests/fixtures/manual.md` with F3.
  Check headings, tables, task lists, footnotes, code, Unicode, and wrapping.
- Scroll, select and copy text, resize the Lister, and press Escape. Repeat
  opening and closing, including an immediate close while WebKit starts.
- Raw HTML must display as text. Script examples must not execute; images,
  local files, and remote URLs must not load, and link labels must not navigate.
- Preview a file with a Unicode filename, a UTF-8 BOM, and invalid UTF-8.
  Files larger than 4 MiB and nonregular inputs must fall back without hanging.
- Restart Double Commander after updating the plugin. Report crashes,
  rendering differences, or unexpected network activity before release.

## Repository layout

```text
Cargo.toml, Cargo.lock       Rust cdylib package and pinned dependencies
build.rs                     Native platform shim build configuration
src/lib.rs                   WLX ABI and bounded file handling
src/markdown.rs              Safe Markdown event filtering and rendering
src/qt5_shim.cpp             Minimal Qt5 widget bridge
src/cocoa_shim.mm            Minimal Cocoa/WebKit view bridge
tests/                       Separate Rust unit tests and offscreen Qt host checks
benchmarks/                  Shared renderer benchmark fixture and harness
scripts/build.sh             Native release build (Linux Qt5 / macOS Cocoa)
scripts/smoke-test.sh        ABI and load smoke test
scripts/install-macos.sh     Copy Cocoa plugin and print registration instructions
v0.1/                        Archived Pascal implementation for review
build/                        Ignored generated WLX artifact
```

Project version history is in [CHANGELOG.md](CHANGELOG.md). Architecture
decisions are in [`docs/decisions/`](docs/decisions/). Read the [Rust and Qt
boundary assessment](docs/security/rust-qt-ffi-assessment-2026-09-23.md) for
the FFI lifecycle findings.
