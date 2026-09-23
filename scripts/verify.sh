#!/usr/bin/env bash
# Pre-deploy checks. Exits non-zero on anything that would break a deploy or
# leak a credential; prints warnings for things worth a human glance.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/_routes.sh

fail=0; warn=0
err()  { echo "FAIL  $*" >&2; fail=$((fail+1)); }
note() { echo "WARN  $*" >&2; warn=$((warn+1)); }
ok()   { echo "ok    $*"; }

echo "== 1. route set =="
for r in "${ROUTES[@]}"; do
  p="public/${r:+$r/}index.html"
  if [ -f "$p" ]; then ok "$(printf '%-14s %8d bytes' "${r:-/}" "$(wc -c < "$p")")"
  else err "missing ${p}"; fi
done
extra=$(find public -type f ! -name index.html 2>/dev/null | head -20)
[ -z "$extra" ] || note "non-index files under public/ (fine if intentional):"$'\n'"$extra"

echo
echo "== 2. manifest =="
if [ ! -f manifest.json ]; then
  note "manifest.json absent - run ./scripts/manifest.sh"
else
  while IFS= read -r line; do
    f=$(echo "$line" | sed -E 's/.*"([^"]+)": \{.*/\1/')
    want=$(echo "$line" | sed -E 's/.*"sha256": "([a-f0-9]+)".*/\1/')
    have=$(sha256sum "public/$f" 2>/dev/null | cut -c1-64)
    if [ "$want" = "$have" ]; then ok "$f"
    else err "$f sha256 drift (manifest $want, disk ${have:-absent}) - re-run ./scripts/manifest.sh"; fi
  done < <(grep '"sha256"' manifest.json)
fi

echo
echo "== 3. self-contained (no CDN-loaded libraries) =="
# The dashboards must carry all their JS/CSS inline - they run behind access
# control and CDN-dependent libraries are a standing constraint of this project.
hits=$(grep -oEn '<(script[^>]+src|link[^>]+href)="https?://[^"]+"' public/*/index.html public/index.html 2>/dev/null \
       | grep -vE 'fonts\.(googleapis|gstatic)\.com' || true)
if [ -z "$hits" ]; then ok "no external <script src> / <link href>"
else err "external resource references found:"$'\n'"$hits"; fi

echo
echo "== 4. credentials =="
# Sheet IDs are expected (the data lives in link-shared Google Sheets). Tokens,
# keys and service-account material are not.
cred=$(grep -oEn 'sk-ant-[A-Za-z0-9_-]{10,}|AIza[A-Za-z0-9_-]{20,}|ya29\.[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|"private_key"|client_secret' \
       public/index.html public/*/index.html 2>/dev/null || true)
if [ -z "$cred" ]; then ok "no credential-shaped strings"
else err "possible credential in committed HTML:"$'\n'"$cred"; fi

echo
echo "== 5. data sources (informational) =="
# Sheet IDs appear both as full gviz URLs and as bare constants the page
# concatenates into one, so look for both shapes.
{ grep -ohE '/spreadsheets/d/[A-Za-z0-9_-]{30,}' public/index.html public/*/index.html 2>/dev/null | sed 's|/spreadsheets/d/||'
  grep -ohE '["'"'"']1[A-Za-z0-9_-]{42,}["'"'"']' public/index.html public/*/index.html 2>/dev/null | tr -d '"'"'"'"'
} | sort -u | sed 's/^/      sheet /' || true

echo
echo "== 6. personal data spot-check =="
mails=$(grep -ohE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' public/index.html public/*/index.html 2>/dev/null \
        | grep -viE '@(finanshels|example|schema|w3)\.' | sort -u || true)
if [ -z "$mails" ]; then ok "no third-party email addresses baked into the HTML"
else note "email addresses found in committed HTML - confirm these are not client contacts:"$'\n'"$(echo "$mails" | head -20)"; fi

echo
echo "-------------------------------------------"
echo "$fail failure(s), $warn warning(s)"
[ "$fail" -eq 0 ] || exit 1
