---
status: Accepted
date: 2026-09-22
---
# Rust Rewrite and Qt5 Primary Target

## Context and Problem Statement

The v0.1.x plugin used a custom limited Markdown parser and four Pascal/Lazarus
widgetset builds. v0.2.0 needs a fuller Markdown implementation with a small,
safe Rust build focused on the primary Qt5 Double Commander target.

## Decision Outcome

Replace the production plugin with a Rust 2021 `cdylib` for Qt5 only. Retain
the WLX ABI and 4 MiB bound, use a narrow exception-safe C++ shim for Qt
widgets, and contain panics and exceptions at the FFI boundary. The v0.1
sources remain archived under `v0.1/` for review.

Use `pulldown-cmark` for CommonMark, tables, task lists, strikethrough, and
footnotes. Filter raw HTML, link destinations, and image resources before
rendering; never execute active content or fetch resources. This supersedes
ADRs 0002, 0003, and 0004.
