# Deploy Guide — Cloudflare Pages

## How it works

Every push to `main` auto-deploys to production (`smalibary.me`).
Pushes to `preview` get preview URLs (`*.salem-portfolio.pages.dev`).

## Architecture

```
GitHub push → Cloudflare Pages builds → live site
```

- **Root directory:** `website-personal`
- **Build command:** `bash build.sh` (installs Dart SDK, runs `dart run tool/build.dart`)
- **Build output:** `build/jaspr`
- **Config:** `website-personal/wrangler.toml`
- **Build script:** `website-personal/build.sh`

## The jaspr CLI problem (and how it was solved)

**Problem:** The `jaspr` CLI is installed via `dart pub global activate jaspr_cli`. On Cloudflare Pages CI:

1. `dart pub global activate jaspr` activates the **framework** package (not the CLI) — no binary created.
2. `dart pub global activate jaspr_cli` does create the binary, but it's slow (needs to compile a snapshot) and the binary ends up in a location that varies by environment and isn't on PATH.

**Solution:** `jaspr_cli` is listed as a dev dependency in `website-personal/pubspec.yaml`. The build tool (`tool/build.dart`) tries the local pub cache paths first, then falls back to `dart run jaspr_cli:jaspr` which works from the project's own dependencies without any global activation.

The resolver (`_resolveJasprCmd` in `tool/build.dart`) returns `(executable, [args])`:
- Local dev: `(jaspr.bat, [])` or `($HOME/.pub-cache/bin/jaspr, [])`
- CI fallback: `(dart, ['run', 'jaspr_cli:jaspr'])`

## Manual deploy (if needed)

If CI is broken or you need to deploy from your machine:

```bash
cd website-personal
dart run tool/build.dart
wrangler pages deploy build/jaspr --project-name salem-portfolio
```

## Cloudflare CLI (Wrangler)

```bash
# Login
wrangler login

# List deployments
wrangler pages deployment list --project-name salem-portfolio

# Check build logs (via API)
ACCOUNT_ID="00b7e159c67efe0662f8f90f7ec0db04"
DEPLOY_ID="<from deployment list>"
TOKEN=$(grep oauth_token "$APPDATA/xdg.config/.wrangler/config/default.toml" | cut -d'"' -f2)

curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/salem-portfolio/deployments/$DEPLOY_ID/history/logs" \
  -H "Authorization: Bearer $TOKEN" | python -c "
import json,sys
for line in json.load(sys.stdin)['result']['data']:
    print(line['line'])
"
```

## Environment variables / secrets

Set on the Pages project (per-environment) via `wrangler pages secret put NAME --project-name salem-portfolio` or the dashboard at *Pages → salem-portfolio → Settings → Variables and Secrets*.

| Name | Where | Purpose |
|---|---|---|
| `RESEND_API_KEY` | Production + Preview | Resend API key for `/api/contact` |
| `CONTACT_EMAIL` | Production + Preview | Recipient for contact-form emails (e.g. `hey@smalibary.me`) |
| `FROM_EMAIL` (optional) | Production | Override "From:" address. Defaults to `Salem Portfolio <onboarding@resend.dev>` |

Secrets are environment-scoped — setting one on Preview does NOT set it on Production. Verify both with:
```bash
wrangler pages secret list --project-name salem-portfolio
```

## Email Routing (`@smalibary.me` addresses)

Custom email like `hey@smalibary.me` is handled by Cloudflare Email Routing (free, separate from Pages):

1. Cloudflare → `smalibary.me` zone → **Email** → **Email Routing**
2. Enable it — Cloudflare auto-adds 3 MX records + DKIM + SPF since the zone is in the same account
3. **Routes** tab → **Create address** → enter `hey` (custom) → forward to your real Gmail
4. Verify the destination Gmail (one-time click on the verification email)

**Important:** any sender address using `@smalibary.me` needs Email Routing set up first, otherwise `CONTACT_EMAIL=hey@smalibary.me` will silently drop incoming mail.

## Changing the domain (full playbook)

Steps that actually need to happen, in order, based on the May 2026 migration from `salem.australia-gpa.com` → `smalibary.me`:

### 1. Add the new domain to the Pages project

Dashboard: `Pages → salem-portfolio → Custom domains → Set up a custom domain`. If the new domain is in the same Cloudflare account, DNS is configured automatically (no manual CNAME). Wait until status shows `Active` (~30 s, plus 1–5 min for SSL).

### 2. Update all code references

Search the repo for the old hostname and replace:
```bash
grep -rn "<OLD_DOMAIN>" .
```
Files that typically need updating (based on the last migration):

| File | What changes |
|---|---|
| `website-personal/content/_data/site.yaml` | `base_url:` |
| `website-personal/lib/data/site_data.dart` | `baseUrl:` (fallback) |
| `website-personal/web/sitemap.xml` | every `<loc>` entry |
| `website-personal/web/robots.txt` | header comment + `Sitemap:` line |
| `website-personal/content/blog/*/post.json` | `canonical_url` for each post |
| `website-personal/lib/pages/admin/blog.dart` | the slug hint text |
| `website-personal/functions/api/contact.js` | sender-domain comment |
| `tools/generate_og.py` | label on generated OG images |
| `DEPLOY.md`, root docs | the "Production" URL in this file |

### 3. Update Pages secrets if email moves with the domain

If `CONTACT_EMAIL` was on the old domain (e.g. `me@old.com`), update it to the new domain *after* you've configured Email Routing on the new zone (see above):
```bash
echo "hey@<NEW_DOMAIN>" | wrangler pages secret put CONTACT_EMAIL --project-name salem-portfolio
```

### 4. Commit + push to `main` → triggers redeploy

### 5. Verify the new domain serves correctly
```bash
curl -sI https://<NEW_DOMAIN>/ | head -5         # should be HTTP/2 200
curl -s   https://<NEW_DOMAIN>/sitemap.xml | head # should list new URLs
```

### 6. Remove the old custom domain from Pages

Dashboard: `Pages → salem-portfolio → Custom domains → ⋯ → Remove`. After this, the old hostname stops resolving. **If you want a 301 redirect from old → new, do NOT remove the old domain yet** — instead leave it attached and set up a Cloudflare Redirect Rule (this requires the old zone to still be in your Cloudflare account).

### 7. Google Search Console

The "Change of address" tool requires 301 redirects from old → new. If you skipped that (like in the May 2026 migration), the old indexed pages will 404 out over weeks. The recovery path is to start fresh:

1. Search Console → **+ Add property** → **Domain** → enter the new domain
2. Verify via DNS (Cloudflare integration auto-adds the TXT record — click `Start verification` → allow access)
3. Left sidebar → **Sitemaps** → submit `sitemap.xml`
4. Use **URL Inspection** → request indexing of the homepage + any priority pages
5. Optionally remove the old property (`Settings → Remove property`) or keep it for historical data

Expect: verification in minutes, sitemap processed in hours, homepage indexed in 1–7 days, full reindex in 2–6 weeks, search-rank recovery is the slow part.

### 8. Optional — `www.` subdomain redirect

If you want `www.<NEW_DOMAIN>` → `<NEW_DOMAIN>`:
1. Add `www.<NEW_DOMAIN>` as a second custom domain on the Pages project
2. Cloudflare → zone → **Rules → Redirect Rules → Create rule** with:
   - Match: wildcard `https://www.<NEW_DOMAIN>/*`
   - Target: `https://<NEW_DOMAIN>/${1}`, status `301`, preserve query string

## Quick links

| What | URL |
|---|---|
| **Production** | https://smalibary.me |
| **Latest preview** | See `website-personal/preview.md` (updated by `/preview` prompt) |
| **Dashboard** | https://dash.cloudflare.com/00b7e159c67efe0662f8f90f7ec0db04/pages/view/salem-portfolio |

## Key files

| File | Purpose |
|---|---|
| `website-personal/wrangler.toml` | Cloudflare Pages config (project name, output dir) |
| `website-personal/build.sh` | CI build script (installs Dart, runs build) |
| `website-personal/tool/build.dart` | Build orchestrator (sitemap + jaspr build) |
| `website-personal/pubspec.yaml` | Includes `jaspr_cli` as dev dependency for CI |

## Dart SDK version on CI

The build script pins Dart 3.11.5. When upgrading Dart locally, update the URL in `website-personal/build.sh`:

```
https://storage.googleapis.com/dart-archive/channels/stable/release/<VERSION>/sdk/dartsdk-linux-x64-release.zip
```

Available versions: https://storage.googleapis.com/storage/v1/b/dart-archive/o?prefix=channels/stable/release/&delimiter=/
