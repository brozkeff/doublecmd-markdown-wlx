# Rust and Qt FFI Security Assessment

- **Date:** 2026-09-23
- **Scope:** Rust WLX boundary, Qt5 C++ shim, and host/widget lifecycle
- **Method:** Independent, read-only penetration assessment with isolated
  local Qt probes

## Summary

No exploitable defect was found for valid WLX calls made by Double Commander.
The Rust/C++ boundary is narrow, its ABI signatures match Double Commander’s
local WLX prototypes, and the normal viewer close order is compatible with the
plugin’s widget ownership. The findings below describe the limits of that
contract and the checks performed.

## Verified behavior

- The WLX function signatures match Double Commander’s `uwlxprototypes.pas`.
- An isolated Qt harness completed both normal host close and the queued Escape
  close path.
- Double Commander’s normal close path calls `ListCloseWindow` before it
  destroys the viewer and its child widgets. This avoids parent-first
  destruction during the audited host lifecycle.
- The plugin and installed Double Commander resolve the same system Qt5
  libraries.
- The release binary has immediate binding, full RELRO, a non-executable
  stack, and stack-canary support.
- Markdown raw HTML is escaped, while link destinations and image resources
  are removed before content reaches `QTextBrowser`.

## FFI assumptions and failure cases

The plugin must trust the host to pass valid pointers with the lifetimes
required by the WLX ABI. `CStr::from_ptr` requires a readable NUL-terminated
path; `ListGetDetectString` requires a writable buffer of the stated length;
and `ListCloseWindow` requires the live widget handle returned by `ListLoad`,
exactly once, on the Qt GUI thread. Null and size checks cannot validate an
arbitrary non-null pointer.

Qt owns the `QTextBrowser` as a child of the host widget, and
`ListCloseWindow` also explicitly deletes the returned widget handle. In
isolated subprocesses, destroying the parent before calling
`ListCloseWindow`, or calling `ListCloseWindow` twice, caused a native crash
(exit status 139). Those calls violate the WLX handle contract and are not
reachable in the audited Double Commander close sequence. Rust
`catch_unwind` and C++ `catch (...)` do not catch use-after-free faults or
other native memory errors.

## Scope limits and optional hardening

Sanitizer-guided fuzzing was not performed, and teardown behavior in other WLX
hosts was not checked. If support for hosts with uncertain handle lifetimes is
added, a GUI-thread live-widget registry using `QPointer` could make teardown
idempotent. The audited Double Commander lifecycle does not currently require
that extra state.

The small C++ shim remains appropriate for this fixed WLX ABI and single
host-parented widget. The Rust code owns file validation and Markdown
rendering; Qt operations stay inside the C++ boundary.
