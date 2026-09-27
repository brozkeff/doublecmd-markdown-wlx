#!/bin/sh

# Copyright (C) 2026 Martin Brozkeff Malec
# Licensed under the EUPL, Version 1.2.
# Sourced by native build and verification helpers.

SYSTEM=$(uname -s)
ARCH=$(uname -m)
case "$SYSTEM" in
  Linux)
    BACKEND=qt5
    PLATFORM=linux
    LIB_EXTENSION=so
    ;;
  Darwin)
    [ "$ARCH" = arm64 ] || {
      printf 'Cocoa builds require native Apple Silicon (arm64).\n' >&2
      exit 1
    }
    ARCH=aarch64
    BACKEND=cocoa
    PLATFORM=darwin
    LIB_EXTENSION=dylib
    ;;
  *) printf 'Unsupported host platform: %s\n' "$SYSTEM" >&2; exit 1 ;;
esac
PLUGIN_NAME="markdown-wlx-$ARCH-$PLATFORM-$BACKEND.wlx"
