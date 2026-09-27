---
status: Accepted
date: 2026-09-27
---
# Native Cocoa Apple Silicon Backend

## Context and Problem Statement

The macOS Apple Silicon build of Double Commander uses Cocoa and NSView WLX
handles, so it cannot host the existing Qt5 widget. Markdown parsing, bounded
file reading, safety filtering, and the WLX ABI should remain shared.

## Decision Outcome

Keep one Rust implementation with a platform-selected native bridge: Qt5 C++
on Linux and ARC Objective-C++ with WKWebView on Apple Silicon macOS. Reuse
the sanitized HTML and CSS, disable JavaScript, restrict resources with CSP,
and block navigation and new windows. Preserve the 4 MiB limit, inert links
and images, and panic/exception containment. This supersedes the Qt5-only
target restriction in [ADR 0005](0005-rust-rewrite-and-qt5-primary.md); its
Rust architecture and renderer decisions remain in effect.

Build only the native host platform, with no universal or cross-platform
artifacts. Link system frameworks on macOS and ad-hoc sign the stripped
ARM64 plugin locally. Automate Rust and ABI checks, but validate Cocoa GUI
behavior manually in Double Commander; do not modify its app bundle or
automatically register the plugin.
