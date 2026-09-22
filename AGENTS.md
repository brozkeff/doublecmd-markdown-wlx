# Agent Notes

This repository contains a standalone Linux Qt5 WLX (Lister) plugin for
Double Commander. The production plugin is a Rust `cdylib`; a small
exception-safe C++ shim in `src/qt5_shim.cpp` is the only Qt widget boundary.
The source and documentation are licensed under EUPL 1.2; copyright is held
by Martin Brozkeff Malec. See `README.md`, `LICENSE`, and
`THIRD-PARTY-NOTICES.md` before changing distribution or attribution details.

The renderer uses `pulldown-cmark` with a safe event filter. Keep raw HTML
escaped, link destinations and image resources inactive, scripts and remote
resources disabled, and the preview limit at 4 MiB. Keep unsafe Rust code at
the WLX/Qt FFI boundary, document each unsafe block with a local `SAFETY`
comment, and prevent Rust panics and C++ exceptions from crossing the C ABI.

Build the Qt5 plugin with `./scripts/build.sh qt5` and run
`./scripts/smoke-test.sh`. Outputs belong in ignored `build/`; Cargo state is
under ignored `target/`. Run `cargo fmt --all -- --check`, `cargo test
--locked`, and `cargo clippy --locked --all-targets -- -D warnings` when
validating code changes. For release validation, manually test F3 in matching
Qt5 Double Commander; the v0.2.0 build has been confirmed in the host.

The replaced v0.1 Pascal sources and build scripts are retained under `v0.1/`
for review and may be removed later. Release binaries are published manually
as GitHub release assets; there are no GitHub Actions.

Architecture decisions are in `docs/decisions/`, starting at `0001`. Write a
new numbered ADR for a significant decision using minimal YAML metadata
(`status`, `date`), an H1 title, and the required `Context and Problem
Statement` and `Decision Outcome` sections. Keep it to two or three short
paragraphs, mark confirmed decisions `Accepted`, and supersede rather than
rewrite an accepted ADR.
