#!/usr/bin/env bash
# Regenerate manifest.json - size + sha256 for every deployed file.
# Run after any change to public/ and commit the result alongside it, so a
# deployment can always be traced back to an exact set of bytes.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/_routes.sh

{
  echo "{"
  echo "  \"generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"files\": {"
  first=1
  for r in "${ROUTES[@]}"; do
    p="public/${r:+$r/}index.html"
    [ -f "$p" ] || continue
    [ $first -eq 1 ] || echo ","
    first=0
    printf '    "%s": { "bytes": %s, "sha256": "%s" }' \
      "${r:+$r/}index.html" "$(wc -c < "$p")" "$(sha256sum "$p" | cut -c1-64)"
  done
  echo
  echo "  }"
  echo "}"
} > manifest.json

echo "manifest.json written ($(grep -c sha256 manifest.json) files)"
