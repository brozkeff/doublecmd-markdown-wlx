#!/bin/sh

# Copyright (C) 2026 Martin Brozkeff Malec
# Licensed under the EUPL, Version 1.2.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR="$ROOT/build"
ARCH=$(uname -m)
STRIP=${STRIP:-strip}

if [ "$#" -ne 1 ] || [ "$1" != "qt5" ]; then
  printf 'Usage: %s qt5\n' "$0" >&2
  exit 2
fi

mkdir -p "$BUILD_DIR"
cargo build --locked --release --manifest-path "$ROOT/Cargo.toml" --lib

# Keep build/ limited to the current Qt5 plugin artifact.
rm -f "$BUILD_DIR"/markdown-wlx-*.wlx

OUTPUT="$BUILD_DIR/markdown-wlx-$ARCH-linux-qt5.wlx"
cp "$ROOT/target/release/libmarkdown_wlx_qt5.so" "$OUTPUT"
"$STRIP" --strip-unneeded "$OUTPUT"
printf 'built: %s\n' "$OUTPUT"
