# Setup & Security Guide

## 1. Activate the team in any repo (30 seconds)

From the **root of any git repository**:

```bash
curl -fsSL https://raw.githubusercontent.com/RadhaKrishna0018/claude-engineering-team/master/scripts/install.sh | bash
```

What it does:

1. Creates `.claudecode/{plans,handoffs}` and installs `instructions.md` (the 7-role skill).
2. Creates the `metrics.json` ledger stamped with your repo name (kept if one already exists).
3. Appends a marker block to `CLAUDE.md` so Claude Code loads the team automatically.
4. Adds `handoffs/` and the private cost ledger to `.gitignore`.

Then open Claude Code in that repo and state a goal:

```
> Build a rate-limited REST API for orders with tests, budget $10.
```

The CTO agent plans, sets the budget cap, spawns parallel waves, and QA opens the PR.
**No UI is required — the terminal is the full product.**

Using a **private fork** as the source? Point the installer at it:

```bash
TEAM_SRC=https://raw.githubusercontent.com/<org>/<fork>/master \
  bash <(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" $TEAM_SRC/scripts/install.sh)
```

## 2. Multi-tenant / colleague onboarding

Each colleague simply runs the same one-liner in their clone. Because Claude Code executes
with **their** local credentials (`ANTHROPIC_API_KEY` / their Claude subscription), every
instance is fully isolated: separate budgets, separate ledgers, zero shared state, nothing
leaves their machine. The repo ships configuration, never credentials.

## 3. Optional dashboard

### Local (recommended)

```bash
# from the repo root where the team is installed — serve the repo root so the
# dashboard can read ../.claudecode/metrics.json same-origin
python -m http.server 4780
# → http://localhost:4780/dashboard/   (default access key: neon-override)
```

Any static server works (`npx serve`, `caddy file-server`, VS Code Live Server). Opened
straight from disk it falls back to animated demo data (browsers block `file://` fetch).

### Change the access key (do this first)

```bash
echo -n "my-new-passphrase" | sha256sum
```

Paste the hash into `ACCESS_HASH` at the top of `dashboard/index.html`.

## 4. Hosting the dashboard on private GitHub Pages

The build is zero-backend, so Pages works — but **only** with these guardrails:

1. **Private repo + Pages access control (required).** Repo → *Settings → Pages →
   Visibility: Private*. This restricts the Pages site to people with repo access and
   requires GitHub SSO. ⚠️ Available on GitHub **Enterprise Cloud** only — on Free/Pro
   plans, Pages sites are always public even from private repos. If you're not on
   Enterprise Cloud, **do not use Pages**; use local serving (§3) or Cloudflare Access /
   Tailscale in front of any static host.
2. **Never publish the ledger.** `metrics.json` contains repo names, task titles, and
   spend data. The installer already gitignores it. The provided workflow deploys
   `dashboard/` only — never widen it to the repo root.
3. **The login gate is a deterrent, not a boundary.** The SHA-256 gate stops shoulder-surfers
   and casual URL sharing; anyone with the HTML can brute-force a weak passphrase offline.
   Real access control = private hosting (item 1). Use a long passphrase regardless.
4. **Keep crawlers out.** `<meta name="robots" content="noindex">` is already set; the
   workflow also drops a `robots.txt`.
5. **No secrets in the HTML — ever.** No API keys, no tokens, no internal URLs. The dashboard
   is read-only by design and must stay that way.

Enable it: push the repo → *Settings → Pages → Source: GitHub Actions* → the included
[.github/workflows/pages.yml](../.github/workflows/pages.yml) deploys on pushes to `master`
that touch `dashboard/`. Since the ledger isn't published, the hosted copy runs in demo mode
unless you point `METRICS_URL` at a same-origin snapshot you deliberately export.

## 5. Verifying an install

```bash
ls .claudecode/                      # instructions.md, metrics.json, plans/, handoffs/
grep -A2 claude-engineering-team CLAUDE.md
python -c "import json;json.load(open('.claudecode/metrics.json'));print('ledger OK')"
```
