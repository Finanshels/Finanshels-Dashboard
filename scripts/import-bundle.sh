#!/usr/bin/env bash
# Import a Cloudflare Pages hub bundle (the ZIP built for direct upload)
# into public/. Existing files are replaced; nothing outside public/ is touched.
#
#   ./scripts/import-bundle.sh ~/Downloads/finanshels-hub-recon-v3.zip
#
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/_routes.sh

ZIP="${1:-}"
[ -n "$ZIP" ] || { echo "usage: $0 <bundle.zip>" >&2; exit 2; }
[ -f "$ZIP" ] || { echo "not found: $ZIP" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q "$ZIP" -d "$TMP"

# Cloudflare bundles are sometimes zipped with a single wrapping folder.
ROOT="$TMP"
if [ ! -f "$ROOT/index.html" ]; then
  CAND="$(find "$TMP" -maxdepth 2 -name index.html -print -quit)"
  [ -n "$CAND" ] || { echo "no index.html in bundle" >&2; exit 1; }
  ROOT="$(dirname "$CAND")"
fi

missing=0
for r in "${ROUTES[@]}"; do
  src="$ROOT/${r:+$r/}index.html"
  if [ -f "$src" ]; then
    mkdir -p "public/${r}"
    cp "$src" "public/${r:+$r/}index.html"
    printf '  %-14s %8d bytes\n' "${r:-/}" "$(wc -c < "$src")"
  else
    echo "  MISSING       ${r:-/}" >&2
    missing=$((missing+1))
  fi
done

# Anything in the bundle that is not a known route - report, do not silently drop.
while IFS= read -r f; do
  rel="${f#"$ROOT"/}"
  [ -f "public/$rel" ] || echo "  EXTRA (not imported): $rel" >&2
done < <(find "$ROOT" -type f)

echo
if [ "$missing" -gt 0 ]; then
  echo "$missing route(s) missing from the bundle - repo is incomplete." >&2
  exit 1
fi
echo "Imported ${#ROUTES[@]} files. Next: ./scripts/manifest.sh && ./scripts/verify.sh"
