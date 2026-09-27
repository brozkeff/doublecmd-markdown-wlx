#!/bin/sh

# Copyright (C) 2026 Martin Brozkeff Malec
# Licensed under the EUPL, Version 1.2.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/scripts/platform.sh"
PLUGIN="$ROOT/build/$PLUGIN_NAME"

[ -f "$PLUGIN" ] || {
  printf 'missing plugin: %s\n' "$PLUGIN" >&2
  exit 1
}

case "$SYSTEM" in
  Linux)
    SYMBOLS=$(nm -D --defined-only "$PLUGIN")
    PREFIX=
    ldd "$PLUGIN" | grep -q 'libQt5Widgets'
    ;;
  Darwin)
    file "$PLUGIN" | grep -q 'Mach-O 64-bit dynamically linked shared library arm64'
    [ "$(lipo -archs "$PLUGIN")" = arm64 ]
    codesign --verify --strict "$PLUGIN"
    SYMBOLS=$(nm -gU "$PLUGIN")
    PREFIX=_
    DEPENDENCIES=$(otool -L "$PLUGIN")
    printf '%s\n' "$DEPENDENCIES" | grep -q '/AppKit.framework/'
    printf '%s\n' "$DEPENDENCIES" | grep -q '/WebKit.framework/'
    if printf '%s\n' "$DEPENDENCIES" | grep -q 'Qt'; then
      printf 'unexpected Qt dependency in Cocoa plugin\n' >&2
      exit 1
    fi
    ;;
esac
for SYMBOL in ListLoad ListCloseWindow ListGetDetectString MarkdownWlxLicense MarkdownWlxVersion; do
  printf '%s\n' "$SYMBOLS" | grep -q " $PREFIX$SYMBOL\$"
done

PLUGIN="$PLUGIN" python3 - <<'PY'
import ctypes
import os

plugin = ctypes.CDLL(os.environ["PLUGIN"])
buffer = ctypes.create_string_buffer(128)
plugin.ListGetDetectString.argtypes = [ctypes.POINTER(ctypes.c_char), ctypes.c_int]
plugin.ListGetDetectString(buffer, len(buffer))
assert buffer.value == b'EXT="MD" | EXT="MARKDOWN" | EXT="MDOWN"', buffer.value

license_fn = plugin.MarkdownWlxLicense
license_fn.restype = ctypes.c_char_p
assert b'EUPL 1.2' in license_fn(), license_fn()

version_fn = plugin.MarkdownWlxVersion
version_fn.restype = ctypes.c_char_p
assert version_fn() == b'0.3.0', version_fn()
print(f"ok: {os.path.basename(os.environ['PLUGIN'])}: {buffer.value.decode()}")
PY

# Cocoa widget behavior is tested manually in the actual Double Commander host.
[ "$SYSTEM" = Linux ] || exit 0

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM
QT5_CFLAGS=$(pkg-config --cflags Qt5Widgets)
QT5_LIBS=$(pkg-config --libs Qt5Widgets)
${CXX:-c++} -std=c++17 $QT5_CFLAGS \
  "$ROOT/tests/qt5_host_smoke.cpp" -o "$TEMP_DIR/qt5-host-smoke" \
  $QT5_LIBS -ldl
QT_QPA_PLATFORM=offscreen "$TEMP_DIR/qt5-host-smoke" \
  "$PLUGIN" "$ROOT/tests/fixtures/smoke.md"
