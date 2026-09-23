#!/usr/bin/env bash
# Serve public/ locally exactly as Vercel will (folder -> index.html).
#   ./scripts/preview.sh [port]   then open http://localhost:8080/
set -euo pipefail
cd "$(dirname "$0")/../public"
PORT="${1:-8080}"
echo "Serving $(pwd) on http://localhost:$PORT/  (Ctrl-C to stop)"
exec python3 -m http.server "$PORT"
