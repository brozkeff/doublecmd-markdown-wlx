# Markdown WLX viewer for Double Commander

Standalone Linux WLX (Lister) plugin for quick F3 previews of Markdown files
inside Double Commander. It does not require a Double Commander fork or
rebuild.

Copyright (C) 2026 Martin Brozkeff Malec. Licensed under the [European Union
Public Licence 1.2](LICENSE).

This code was co-created with OpenAI Codex using GPT-5.6.

## What it does

The plugin claims these file extensions:

- `.md`
- `.markdown`
- `.mdown`

When F3 opens one of these files, Double Commander loads the plugin into its
existing viewer window. The plugin reads the file once, converts a small safe
Markdown subset to native widget markup, and displays the result read-only.

Supported features:

- headings;
- paragraphs and line wrapping;
- unordered and numbered lists;
- emphasis and strong emphasis;
- inline code;
- fenced code blocks;
- UTF-8 files, including a UTF-8 BOM.

For safety and predictable quick previews, it does not render raw HTML, fetch
remote resources, load images, open links, or execute scripts. It is not a
full CommonMark/GitHub-Flavored Markdown implementation.

Files larger than 4 MiB are not rendered. The plugin returns an invalid WLX
handle for those files so Double Commander can use its normal fallback viewer;
this avoids loading and rendering an unexpectedly expensive input inside the
file manager.

## How it works

Double Commander uses the Total Commander-compatible WLX API. The plugin
exports:

- `ListGetDetectString` — claims Markdown extensions;
- `ListLoad` — creates the embedded viewer widget and renders the file;
- `ListCloseWindow` — destroys the widget;
- `MarkdownWlxLicense` — exposes the copyright and license notice from the
  binary.
- `MarkdownWlxVersion` — exposes the SemVer-compatible version

The rendering backend follows the Double Commander widgetset:

- Qt5 and Qt6 builds use `QTextBrowser` with generated safe HTML;
- GTK2 builds use a `GtkLabel` with escaped Pango markup;
- GTK3 builds use `GtkTextView` with Pango markup.

Each plugin binary must match the widgetset and architecture of the running
Double Commander. Do not load the Qt5 binary into a Qt6 or GTK3 build.

## Requirements

Build requirements:

- Linux x86_64 or another supported FPC target;
- Free Pascal Compiler 3.2.2 or newer;
- Lazarus 4.8 or newer;
- the matching Lazarus LCL widgetset package (`gtk2`, `gtk3`, `qt5`, or `qt6`);
- GTK2 or GTK3 development libraries for the corresponding GTK build;
- the matching QtPas development library for Qt builds;
- GTK3 development libraries for the GTK3 build.

Runtime requirements are the same Qt or GTK libraries already required by the
corresponding Double Commander build.

## Build

Build one widgetset:

```sh
./scripts/build.sh qt5
./scripts/build.sh qt6
./scripts/build.sh gtk2
./scripts/build.sh gtk3
```

Build all available variants:

```sh
./scripts/build.sh all
```

The script accepts `LAZARUS_DIR` when Lazarus is installed outside the usual
Debian path:

```sh
LAZARUS_DIR=/opt/lazarus ./scripts/build.sh qt5
```

The output files are written below `build/`:

- `build/markdown-wlx-x86_64-linux-qt5.wlx`;
- `build/markdown-wlx-x86_64-linux-qt6.wlx`;
- `build/markdown-wlx-x86_64-linux-gtk2.wlx`;
- `build/markdown-wlx-x86_64-linux-gtk3.wlx`.

The build script strips release artifacts automatically. This removes compiler
debug information and non-loadable symbol tables; the exported WLX entry
points and runtime dependencies remain intact. Set `STRIP` to an alternative
target strip tool when cross-compiling.

The Qt and GTK widgetset units from Lazarus are compiled into each plugin, as
Pascal LCL packages are not runtime-shared libraries in this build. The Qt,
GTK, and QtPas libraries themselves remain dynamic dependencies supplied by
the host system. This is why the unstripped Qt artifacts were large even
though Qt was not statically linked, and why stripping reduces them from about
30 MiB to about 10 MiB on the development system.

Generated compiler units, local Lazarus configuration, linker shims, and `.wlx`
artifacts under `build/` are ignored by Git. The binaries remain available in
the working tree for local installation and release testing, but are not
committed.

## Install

1. Open Double Commander.
2. Go to Options → Plugins → WLX.
3. Add the binary matching the running widgetset.
4. Select a Markdown file and press F3.

The plugin supplies this detection string automatically:

```text
EXT="MD" | EXT="MARKDOWN" | EXT="MDOWN"
```

If an older configuration does not refresh the plugin list immediately,
restart Double Commander and add the plugin again.

## Tests and verification

The following was verified on the development machine:

- Qt5, Qt6, and GTK2 compiled and linked; WLX symbols, `dlopen`, and detection passed.
- GTK3 compiled and linked; WLX symbols and `dlopen` passed.
- Only the Qt5 binary was loaded and tested interactively with Double Commander
  1.2.8.
- GTK2, GTK3, and Qt6 were compiled and smoke-tested, but have not yet been
  loaded or tested interactively in Double Commander.

Build platform and versions:

- Debian-packaged Linux environment, x86_64;
- Free Pascal 3.2.2;
- Lazarus 4.8.0.0;
- Qt 5.15.3;
- GTK3 3.24.33;
- Double Commander 1.2.8, commit `d5756c496`, build date 2026-08-09.

For the verified Ubuntu 22.04 Qt6 build, the system packages were
`qt6-base-dev`, `qt6-base-dev-tools`, and `libqt6core5compat6-dev` from the
Ubuntu Jammy/updates repositories. The Pascal Qt6 bridge was supplied by
[`davidbannon/libqt6pas`](https://github.com/davidbannon/libqt6pas), using
`libqt6pas6_6.2.10-1_amd64.deb` and
`libqt6pas6-dev_6.2.10-1_amd64.deb`.

Run the smoke tests with:

```sh
./scripts/smoke-test.sh
```

The smoke tests do not replace an interactive F3 test. They verify that the
shared library can be loaded and that its WLX detection function is callable.

## Repository layout

```text
markdown-wlx.lpi       Lazarus project
markdown-wlx.lpr       WLX entry points and widget integration
mdrender.pas           dependency-free Markdown subset renderer
sdk/                   minimal standalone WLX declarations
build/                 ignored compiled plugin artifacts
scripts/build.sh       reproducible widgetset build wrapper
scripts/smoke-test.sh  ABI and detection smoke test
```

## Versioning

This project follows Semantic Versioning.
Release history is maintained in [CHANGELOG.md](CHANGELOG.md).
Important project decisions are recorded in [`docs/decisions/`](docs/decisions/).

## License

The implementation is released under the [EUPL 1.2](LICENSE).

The repository contains the minimal WLX declarations needed to build this
plugin;
they are provided as part of this implementation for standalone use.
Double Commander itself is a separate project with its own license and is not
bundled here.
