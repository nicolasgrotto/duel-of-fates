#!/usr/bin/env bash
set -euo pipefail

godot_binary="${1:?usage: export_web.sh <godot binary> [output folder]}"
output="${2:-build/web}"
build_id="dof-$(git rev-parse --short=8 HEAD)"

rm -rf "$output"
mkdir -p "$output"
"$godot_binary" --headless --path . --export-release "Web" "$output/$build_id.html"
mv "$output/$build_id.html" "$output/index.html"
grep -q "$build_id" "$output/index.html"
test -f "$output/$build_id.pck"
test -f "$output/$build_id.wasm"
echo "Exported $build_id"
