# Known issues carried over from production

The HTML in `public/` is a byte-exact copy of the Cloudflare hub bundle
(`finanshels-hub-recon-v3.zip`, 3,069,861 bytes,
sha256 `b5059fbd0c94e09ef5787d79f3ce4a462bf53c6ce912b404baa02bb90fa0cc26`).
Nothing was edited on import. These two things are worth knowing before the
Vercel deployment is shared with anyone.

## 1. Seven dashboards link back to the Cloudflare hub by absolute URL

`bench`, `budget`, `channel`, `clients`, `marketing`, `mrr` and `pnl` each carry
a "Data health ↗" link:

```html
<a class="hl-link" href="https://finanshels-all-live-automated-dashboard.pages.dev/#home" target="_top">
```

Opened from the Vercel hub, that link leaves Vercel and lands the user back in
the Cloudflare hub — with `target="_top"` it replaces the whole window, not just
the frame. Everything else about the page works; only this one link escapes.

The link is absolute on purpose: these dashboards are *also* deployed as their
own standalone Cloudflare projects, where a relative `/#home` would point at the
dashboard itself rather than at the hub.

A fix that is correct on all three deployments — Vercel hub, Cloudflare hub, and
standalone — resolves the target at click time instead of hard-coding it:

```js
// framed by a hub on this origin -> stay on this origin; standalone -> the hub
href = (window.top !== window.self) ? '/#home'
                                    : 'https://finanshels-all-live-automated-dashboard.pages.dev/#home';
```

This has **not** been applied. It is a change to seven production dashboards and
belongs in its own reviewed commit, not in the repo import.

## 2. The hub's "open standalone" links point at Cloudflare

`public/index.html` carries a `standalone:` URL per dashboard
(`finanshels-mrr.pages.dev`, `finanshels-pnl.pages.dev`, and nine more). These
are correct while Cloudflare and Vercel run in parallel — the standalone
projects are genuinely there.

They become wrong the moment Cloudflare is retired. At that point each one
should become the matching Vercel route (`/mrr/`, `/pnl/`, …), or the standalone
concept should be dropped in favour of the hub route. Worth folding into the
cutover, whenever that happens.

## Not an issue

- **Sheet IDs in the HTML.** Eleven distinct Google Sheets are referenced by ID.
  That is how the gviz reads work and is by design — but it is the reason the
  GitHub repo must stay private and the reason access control on the Vercel
  deployment is still open. `./scripts/verify.sh` lists them.
- **`1980-00-00` timestamps in the source bundle.** An artefact of the
  hand-rolled in-browser ZIP writer; the file contents are unaffected.
