# Plans

## v0.2.0 Rust rewrite

- [x] Replace the Pascal/Lazarus implementation with a Rust Qt5 WLX plugin.
- [x] Keep Qt widget construction in a narrow C++ shim and retain the WLX ABI.
- [x] Replace the custom parser with CommonMark and selected GFM extensions.
- [x] Preserve the 4 MiB input limit and prevent active content or resource loads.
- [x] Archive the v0.1 implementation under `v0.1/` for review.
- [x] Add Rust build and ABI smoke-test scripts.
- [x] Supersede prior implementation and scope decisions without deleting ADR history.

## v0.2.1 follow-up

- [x] Close the active Qt5 Lister window on Escape.
- [x] Keep Rust unit test bodies in separate files under `tests/unit/`.
