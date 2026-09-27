#!/bin/sh

# Copyright (C) 2026 Martin Brozkeff Malec
# Licensed under the EUPL, Version 1.2.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/scripts/platform.sh"
[ "$SYSTEM" = Darwin ] || {
  printf 'This installer requires macOS.\n' >&2
  exit 1
}
if [ "$#" -gt 1 ]; then
  printf 'Usage: %s [plugin-directory]\n' "$0" >&2
  exit 2
fi
PLUGIN="$ROOT/build/$PLUGIN_NAME"
[ -f "$PLUGIN" ] || {
  printf 'Build the plugin first: %s/scripts/build.sh\n' "$ROOT" >&2
  exit 1
}
DESTINATION=${1:-"$HOME/Library/Application Support/doublecmd/plugins/markdown-wlx"}
codesign --verify --strict "$PLUGIN"
mkdir -p "$DESTINATION"
cp "$PLUGIN" "$DESTINATION/$PLUGIN_NAME"
printf 'Installed: %s/%s\n' "$DESTINATION" "$PLUGIN_NAME"
printf 'In Double Commander: Options → Plugins → WLX → Add the installed file.\n'
printf 'Select a Markdown file and press F3. Restart Double Commander after replacing a loaded plugin.\n'
