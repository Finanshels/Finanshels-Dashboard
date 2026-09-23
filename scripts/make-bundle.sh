#!/usr/bin/env bash
# Build a Cloudflare Pages direct-upload ZIP from public/, so the existing
# dual-deploy (Vercel + Cloudflare hub) keeps working while both run in parallel.
# Cloudflare replaces the whole site on every direct upload, so the bundle
# always contains the full route set - that is expected, not a bug.
#
#   ./scripts/make-bundle.sh            -> dist/finanshels-hub-YYYYMMDD-HHMM.zip
#
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/_routes.sh

./scripts/verify.sh >/dev/null || { echo "verify.sh failed - not bundling" >&2; exit 1; }

mkdir -p dist
OUT="dist/finanshels-hub-$(date -u +%Y%m%d-%H%M).zip"
rm -f "$OUT"
( cd public && zip -qrX "../$OUT" . -x '.*' -x '__MACOSX/*' )

n=$(unzip -l "$OUT" | grep -c 'index\.html' || true)
echo "$OUT  ($(wc -c < "$OUT") bytes, $n files)"
[ "$n" -eq "${#ROUTES[@]}" ] || { echo "expected ${#ROUTES[@]} files, got $n" >&2; exit 1; }
echo
echo "Upload to the HUB project (finanshels-all-live-automated-dashboard),"
echo "not the standalone one. See docs/deploy.md."
