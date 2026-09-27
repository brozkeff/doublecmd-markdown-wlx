#!/bin/sh

# Copyright (C) 2026 Martin Brozkeff Malec
# Licensed under the EUPL, Version 1.2.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR="$ROOT/build"
STRIP=${STRIP:-strip}
. "$ROOT/scripts/platform.sh"

if [ "$#" -gt 1 ] || [ "${1:-$BACKEND}" != "$BACKEND" ]; then
  printf 'Usage on this host: %s [%s]\n' "$0" "$BACKEND" >&2
  exit 2
fi

HOST_TARGET=$(rustc -vV | sed -n 's/^host: //p')
case "$SYSTEM:$HOST_TARGET" in
  Linux:*-unknown-linux-*) ;;
  Darwin:aarch64-apple-darwin) ;;
  *) printf 'Rust toolchain must match the native host: %s\n' "$HOST_TARGET" >&2; exit 1 ;;
esac

mkdir -p "$BUILD_DIR"
# Explicit target prevents a Cargo configuration from selecting a foreign target.
# Keep all Cargo artifacts inside this checkout even when called from elsewhere.
cargo build --locked --release --manifest-path "$ROOT/Cargo.toml" --lib \
  --target "$HOST_TARGET" --target-dir "$ROOT/target"

OUTPUT="$BUILD_DIR/$PLUGIN_NAME"
cp "$ROOT/target/$HOST_TARGET/release/libmarkdown_wlx.$LIB_EXTENSION" "$OUTPUT"
case "$SYSTEM" in
  Linux) "$STRIP" --strip-unneeded "$OUTPUT" ;;
  Darwin)
    "$STRIP" -x "$OUTPUT"
    codesign --force --sign - "$OUTPUT"
    codesign --verify --strict "$OUTPUT"
    [ "$(lipo -archs "$OUTPUT")" = arm64 ]
    ;;
esac
printf 'built: %s\n' "$OUTPUT"
