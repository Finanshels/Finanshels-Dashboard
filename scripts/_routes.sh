#!/usr/bin/env bash
# Single source of truth for the hub's route set.
# Root index.html + 13 dashboard folders = 14 deployed files.
# Order matches the hub's own nav; keep in sync with public/index.html.
ROUTES=(
  ""              # root hub page  -> public/index.html
  "pbudget"       # Partnership budget vs actual
  "recon"         # Finance Books - Reconciliation
  "recon-summary" # Reconciliation summary
  "mrr"           # MRR / revenue bridge
  "pnl"           # Service-wise P&L
  "channel"       # Channel-wise P&L
  "clients"       # Client tracker
  "bench"         # Industry benchmark
  "budget"        # Budget vs actual
  "marketing"     # Marketing ROI
  "mbudget"       # Marketing budget vs actual
  "sales"         # Sales intelligence
  "performance"   # Three-statement performance
)
