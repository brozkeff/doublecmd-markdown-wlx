#!/bin/sh

# Copyright (C) 2026 Martin Brozkeff Malec
# Licensed under the EUPL, Version 1.2.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ITERATIONS=${1:-2000}
FIXTURE="$ROOT/benchmarks/shared-markdown.md"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM
mkdir -p "$TEMP_DIR/units"

fpc \
  -Fu"$ROOT/v0.1" \
  -FU"$TEMP_DIR/units" \
  -FE"$TEMP_DIR" \
  -o"$TEMP_DIR/old-pascal-bench" \
  "$ROOT/v0.1/benchmarks/old_pascal_bench.pas" >/dev/null

cargo run --quiet --locked --release --features render-bench \
  --manifest-path "$ROOT/Cargo.toml" --bin render-bench -- "$FIXTURE" "$ITERATIONS"
"$TEMP_DIR/old-pascal-bench" "$FIXTURE" "$ITERATIONS"
