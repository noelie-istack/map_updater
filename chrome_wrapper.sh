#!/bin/bash
# Strip --no-sandbox from args passed by Flutter
args=()
for arg in "$@"; do
  [[ "$arg" == "--no-sandbox" ]] && continue
  args+=("$arg")
done
exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "${args[@]}"
