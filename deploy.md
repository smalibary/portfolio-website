# Deploy Guide — Cloudflare Pages

## How it works

Every push to `main` auto-deploys to production (`salem.australia-gpa.com`).
Pushes to `preview` get preview URLs (`*.salem-portfolio.pages.dev`).

## Architecture

```
GitHub push → Cloudflare Pages builds → live site
```

- **Build command:** `bash build.sh` (installs Dart SDK, runs `dart run tool/build.dart`)
- **Build output:** `website-jaspr/build/jaspr`
- **Config:** `wrangler.toml` (root)
- **Build script:** `build.sh` (root)

## The jaspr CLI problem (and how it was solved)

**Problem:** The `jaspr` CLI is installed via `dart pub global activate jaspr_cli`. On Cloudflare Pages CI:

1. `dart pub global activate jaspr` activates the **framework** package (not the CLI) — no binary created.
2. `dart pub global activate jaspr_cli` does create the binary, but it's slow (needs to compile a snapshot) and the binary ends up in a location that varies by environment and isn't on PATH.

**Solution:** `jaspr_cli` is listed as a dev dependency in `website-jaspr/pubspec.yaml`. The build tool (`tool/build.dart`) tries the local pub cache paths first, then falls back to `dart run jaspr_cli:jaspr` which works from the project's own dependencies without any global activation.

The resolver (`_resolveJasprCmd` in `tool/build.dart`) returns `(executable, [args])`:
- Local dev: `(jaspr.bat, [])` or `($HOME/.pub-cache/bin/jaspr, [])`
- CI fallback: `(dart, ['run', 'jaspr_cli:jaspr'])`

## Manual deploy (if needed)

If CI is broken or you need to deploy from your machine:

```bash
cd website-jaspr
dart run tool/build.dart
cd ..
wrangler pages deploy website-jaspr/build/jaspr --project-name salem-portfolio
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

## Changing the domain

1. Update `base_url` in `website-jaspr/content/_data/site.yaml`
2. Push to `main` (triggers rebuild)
3. In Cloudflare dashboard: Workers & Pages → salem-portfolio → Custom domains → update
4. Old domain redirects are not automatic — set up a Cloudflare Page Rule if needed

## Key files

| File | Purpose |
|---|---|
| `wrangler.toml` | Cloudflare Pages config (project name, output dir) |
| `build.sh` | CI build script (installs Dart, runs build) |
| `website-jaspr/tool/build.dart` | Build orchestrator (sitemap + jaspr build) |
| `website-jaspr/pubspec.yaml` | Includes `jaspr_cli` as dev dependency for CI |

## Dart SDK version on CI

The build script pins Dart 3.11.5. When upgrading Dart locally, update the URL in `build.sh`:

```
https://storage.googleapis.com/dart-archive/channels/stable/release/<VERSION>/sdk/dartsdk-linux-x64-release.zip
```

Available versions: https://storage.googleapis.com/storage/v1/b/dart-archive/o?prefix=channels/stable/release/&delimiter=/
