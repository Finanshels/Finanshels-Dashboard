# Rollback

## Vercel (seconds, no git)

Project → **Deployments** → the last good one → **⋯ → Promote to Production**.
Vercel keeps every previous deployment, so this is immediate and reversible.
Do this first when something is wrong in production; fix the repo afterwards.

## Git (the durable fix)

```bash
git log --oneline -- public/recon/index.html   # find the good commit
git revert <bad-commit>                        # keeps history honest
# or, to restore a single dashboard without touching the others:
git checkout <good-commit> -- public/recon/index.html
./scripts/manifest.sh && ./scripts/verify.sh
git commit -am "revert recon to <good-commit>" && git push
```

`git revert` is preferred over `reset --hard` on a shared branch — the deployed
history stays traceable, which is the point of moving off ZIP uploads.

## Cloudflare (while it is still live)

The hub project keeps prior deployments; the previous version is one click away
under Deployments → Rollback. If Vercel and Cloudflare have diverged, rebuild
from the repo rather than promoting an old Cloudflare deployment:

```bash
git checkout <good-commit> && ./scripts/make-bundle.sh
```

## Verifying a rollback landed

`manifest.json` at the rolled-back commit records the sha256 of every file. To
confirm production actually serves those bytes:

```bash
curl -s https://<deployment>/recon/ | shasum -a 256
```

and compare against the `recon/index.html` entry in `manifest.json`.

## What a rollback does *not* fix

The dashboards read live Google Sheets. Rolling back the site restores the
*code*, never the data — a bad sync or a broken sheet tab has to be fixed at
source. If a dashboard looks wrong but the HTML is unchanged, suspect the sheet
before the deployment.
