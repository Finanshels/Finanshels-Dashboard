# Finanshels Dashboard Hub

The live financial intelligence layer for Finanshels — fourteen single-file HTML
dashboards served as one static site, reading directly from Google Sheets.

Today the hub is deployed to Cloudflare Pages by dragging a ZIP into the
dashboard. This repo replaces that with `git push`, while keeping the Cloudflare
path available (`scripts/make-bundle.sh`) for as long as both run in parallel.

## Routes

| Path             | Dashboard                        |
| ---------------- | -------------------------------- |
| `/`              | Hub (tiles + nav)                |
| `/pbudget/`      | Partnership budget vs actual     |
| `/recon/`        | Finance Books — Reconciliation   |
| `/recon-summary/`| Reconciliation summary           |
| `/mrr/`          | MRR / revenue bridge             |
| `/pnl/`          | Service-wise P&L                 |
| `/channel/`      | Channel-wise P&L                 |
| `/clients/`      | Client tracker                   |
| `/bench/`        | Industry benchmark               |
| `/budget/`       | Budget vs actual                 |
| `/marketing/`    | Marketing ROI                    |
| `/mbudget/`      | Marketing budget vs actual       |
| `/sales/`        | Sales intelligence               |
| `/performance/`  | Three-statement performance      |

The route list lives in `scripts/_routes.sh` and every script reads it from
there, so adding a dashboard is a one-line change plus a folder.

## Layout

```
public/            the deployed site — one index.html per route, nothing else
scripts/           import, manifest, verify, bundle, preview
docs/              deploy, rollback, architecture
manifest.json      size + sha256 of every deployed file
vercel.json        static config: no build step, headers, trailing slashes
```

There is no build step and no dependencies. Each dashboard is a self-contained
HTML file with its JavaScript inline — a hard constraint of this project, not a
stylistic one (see `docs/architecture.md`).

## Everyday use

```bash
./scripts/preview.sh              # serve public/ at http://localhost:8080/
# edit public/<route>/index.html
./scripts/manifest.sh             # refresh sizes + hashes
./scripts/verify.sh               # route set, hashes, self-containment, credentials
git add -A && git commit -m "recon: ..." && git push
```

Vercel deploys `main` automatically. Every push also gets a preview URL, so a
change can be opened and checked before it becomes production.

To also refresh the Cloudflare hub while both run in parallel:

```bash
./scripts/make-bundle.sh          # dist/finanshels-hub-<timestamp>.zip
```

## First-time setup

`docs/deploy.md` — creating the GitHub repo, importing it into Vercel, and the
settings that matter.

## Open item: access control

On Cloudflare these dashboards sit behind Cloudflare Access. A Vercel
deployment has no equivalent by default: **anyone who has the URL can open it**,
and these pages show client-level revenue. Options are written up in
`docs/deploy.md` under "Access control" — this is deliberately unresolved and
should be settled before the Vercel URL is shared with anyone.
