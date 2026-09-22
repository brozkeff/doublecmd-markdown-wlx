---
status: Accepted
date: 2026-09-22
---
# Strip Release Plugin Artifacts

## Context and Problem Statement

The Qt5 and Qt6 WLX artifacts were approximately 30 MiB even though their Qt
and QtPas runtime libraries were dynamically linked. The excess size came
primarily from compiler debug information and non-loadable symbol tables; the
Lazarus widgetset units are also normally compiled into the plugin.

## Decision Outcome

The build script strips every generated WLX artifact with
`strip --strip-unneeded`, preserving exported WLX entry points and dynamic
library dependencies. Qt, GTK, and QtPas remain host-provided shared
dependencies; converting Lazarus LCL units into runtime-shared packages is
outside this plugin's portable release model.
