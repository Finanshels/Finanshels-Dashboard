# Deploy

## One-time: GitHub

The repo is already initialised with a first commit. Create an **empty private**
repo on GitHub (no README, no .gitignore — they exist here), then:

```bash
git remote add origin git@github.com:<you>/finanshels-dashboard-hub.git
git branch -M main
git push -u origin main
```

Private matters: the committed HTML contains the Google Sheet IDs behind every
dashboard. Those sheets are link-shared, so a sheet ID is effectively a key to
the data in it.

## One-time: Vercel

1. vercel.com → **Add New → Project** → import the GitHub repo.
2. Framework preset: **Other**. Leave Build Command empty.
3. Output Directory: **`public`** (already set in `vercel.json`; Vercel will
   pick it up, but confirm it on the import screen).
4. Deploy.

That is the whole setup — there is no build, no install step, no environment
variables. `vercel.json` handles the rest:

- `trailingSlash: true` — `/recon` → `/recon/`, matching Cloudflare's behaviour
  so existing links and the hub's own nav keep working.
- HTML served `must-revalidate` — a deploy is visible on refresh, with no stale
  dashboard cached at the edge.
- `nosniff`, `SAMEORIGIN`, a referrer policy, and a permissions policy.

`X-Frame-Options: SAMEORIGIN` is what lets the hub embed its own dashboards in
frames while blocking anyone else from embedding them. If a hub tile ever needs
to frame a page from a different origin, that header is the thing to revisit —
this is the same class of problem as the cross-origin frame fix in the project
log (doc 50).

## Every change after that

```bash
./scripts/manifest.sh && ./scripts/verify.sh
git commit -am "..." && git push
```

Pushing to `main` deploys production. Pushing any other branch, or opening a
PR, gives a preview URL — the safest way to look at a dashboard change against
live sheet data before it goes to production.

## Keeping Cloudflare in step (while both run)

Cloudflare Pages direct upload replaces the entire site, so a one-file change
still needs all fourteen files. That is what `make-bundle.sh` produces:

```bash
./scripts/make-bundle.sh
```

Then in Cloudflare: the **hub** project `finanshels-all-live-automated-dashboard`
→ Create deployment → Production → drag the ZIP → Save and deploy.

Two standing rules from the project log still apply while Cloudflare is live:

- Upload to the **hub** project breadcrumb, never the standalone one.
- Dashboard changes go to both `finanshels-reconciliation` and the hub's
  `recon/` folder.

Once Vercel becomes the single production target, both rules retire along with
`make-bundle.sh`.

## Access control

Cloudflare Access currently gates these dashboards. Vercel has no equivalent
turned on by default, so a fresh deployment is reachable by anyone with the URL.
Three ways to close it:

| Option | What it does | Cost |
| --- | --- | --- |
| **Vercel Authentication** | Only logged-in members of the Vercel team can open the deployment. | Preview deployments on any plan; production protection needs Pro. |
| **Password protection** | One shared password on the deployment. | Pro. |
| **Keep Cloudflare in front** | Point a Cloudflare-proxied hostname at the Vercel deployment and leave Access on it. | No new cost; keeps the current identity rules. |

Until one is in place, treat the Vercel URL as sensitive and do not share it.
