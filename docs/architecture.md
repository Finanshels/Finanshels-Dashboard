# Architecture

## Shape of the thing

```
Zoho Books ──┐
Zoho CRM ────┤   Apps Script / Ads Script syncs
FinCore ─────┼──────────────────────────────►  Google Sheets  ◄── source of truth
Ad platforms ┘                                      │
                                                    │  gviz JSONP, read-only,
                                                    │  from the visitor's browser
                                                    ▼
                                    public/<route>/index.html  (this repo)
                                                    │
                                                    ▼
                                         Vercel static hosting
```

Nothing server-side belongs to this repo. Vercel serves fourteen HTML files;
every number on screen is fetched by the visitor's own browser from Google
Sheets at load time. That is why there is no build step, no API routes, no
environment variables and no secrets.

The syncs that fill those sheets — Zoho Books, Zoho CRM, Google Ads, the invoice
uploader — live in Google Apps Script and Google Ads Scripts, outside this repo.
Moving the site to Vercel changes nothing about them.

## Why each dashboard is one self-contained file

Two constraints, both load-bearing:

1. **No CDN-loaded libraries.** The dashboards run behind access control, and
   external script/stylesheet loads are not dependable there. All JavaScript and
   CSS is inline. `scripts/verify.sh` fails the build on a static
   `<script src="http…">` or `<link href="http…">`.
2. **No server.** Everything — parsing, the MRR bridge, allocation logic,
   drilldowns, Excel export — runs client-side. The xlsx export is a
   hand-rolled stored-ZIP implementation over `TextEncoder`/`Uint8Array` for
   exactly this reason: no DEFLATE library, no CDN.

Consequences worth knowing before editing: files are large (the MRR dashboard is
over a megabyte), a change is a change to one big file, and `git diff` on them is
noisy. `manifest.json` exists so that a deployment can still be pinned to an
exact set of bytes despite that.

## Data access

Reads use the Google Visualization query endpoint
(`/spreadsheets/d/<id>/gviz/tq`) via JSONP. No OAuth, no publish-to-web, no
token in the page. The trade-off is that **the sheet ID in the HTML is the
access control** — anyone who can read the page can read the sheet behind it.
Hence the private GitHub repo, and hence the unresolved access question in
`docs/deploy.md`.

To list every sheet the site currently reads:

```bash
./scripts/verify.sh        # section 5 prints the distinct sheet IDs
```

## Client-side storage

Some dashboards hand large payloads between pages using `window.name` rather
than `localStorage`, which caps out well below the sizes involved (1 MB+
exports). If a navigation appears to lose state, that mechanism is where to
look — and it is same-tab only by design.

## Changing a dashboard

1. Edit `public/<route>/index.html`.
2. `./scripts/preview.sh` and load the route locally — the sheets are read from
   the browser, so local preview shows real, live data.
3. `./scripts/manifest.sh && ./scripts/verify.sh`.
4. Commit and push; check the Vercel preview URL before promoting to production.

## Adding a dashboard

1. Add the slug to `ROUTES` in `scripts/_routes.sh`.
2. Create `public/<slug>/index.html`.
3. Add a tile to `public/index.html`.
4. `./scripts/manifest.sh && ./scripts/verify.sh`.

The scripts and CI derive the expected file set from `_routes.sh` alone, so a
dashboard added without that line will be reported as an untracked extra rather
than silently shipped.
