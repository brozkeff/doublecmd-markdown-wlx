# Agent Notes

This repository contains a standalone Linux WLX (Lister) plugin for Double
Commander. It is written in Free Pascal/Lazarus, uses the minimal API
declarations in `sdk/`, and provides Qt5, Qt6, GTK2, and GTK3 backends. The
implementation and documentation are licensed under EUPL 1.2; copyright is
held by Martin Brozkeff Malec. See `README.md` and `LICENSE` before changing
distribution or attribution details.

Important limits: the renderer supports only a safe Markdown subset, does not
process active content or remote resources, and rejects previews larger than
4 MiB. Use `./scripts/build.sh {qt5|qt6|gtk2|gtk3|all}` and
`./scripts/smoke-test.sh` when dependencies are available. Build outputs and
local compiler state are ignored; release binaries are published manually as
GitHub release assets. There are no GitHub Actions currently.

Architecture decisions are in `docs/decisions/`, starting at `0001`. Write a
new numbered ADR for a significant decision: use minimal YAML metadata
(`status`, `date`), an H1 title, and the required `Context and Problem
Statement` and `Decision Outcome` sections. Keep it to two or three short
paragraphs, mark confirmed decisions `Accepted`, and supersede rather than
rewrite an accepted ADR.
