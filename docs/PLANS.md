# Plans

## v0.2.0

- [ ] Replace the entire Pascal/Lazarus implementation with Rust.
  - Keep the standalone Linux WLX plugin interface and Qt/GTK compatibility.
  - Load the host widgetset libraries dynamically instead of compiling the
    plugin with Pascal/Lazarus.
  - Preserve the safe Markdown subset, input-size limit, and ABI smoke tests.

Double Commander itself may remain compiled with Pascal/Lazarus. Its plugin
ABI does not require independently developed plugins to use the same language
or toolchain, so the rewrite can reduce the plugin's build-time and runtime
coupling to Lazarus while retaining compatibility with Double Commander.
