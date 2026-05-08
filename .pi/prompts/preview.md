---
description: Commit and push to preview branch, get a preview URL to check
---

Commit all current changes and push to the `preview` branch. After pushing,
fetch the Cloudflare build logs and report the preview URL to the user.

**Step 0 — Skill check**

Before proceeding, check if any superpowers skills apply to this task.
This is an operational prompt (commit + push) — no creative or code changes.
If no skills apply, skip to Step 1.

**Step 1 — Stage and commit**

Stage all changes and commit with a descriptive message based on what changed.
If nothing is staged, tell the user and stop.

```bash
cd C:/CLI/small-projects/my-cv
git add -A
git status  # review what's being committed
git commit -m "<descriptive message>"
```

**Step 2 — Ensure we're on the preview branch**

If the current branch is not `preview`, switch to it. If `preview` is behind
`main`, merge `main` into `preview` first to keep them in sync.

```bash
git checkout preview
git merge main  # only if needed
```

**Step 3 — Push to preview**

```bash
git push origin preview
```

**Step 4 — Wait for build and report**

Wait ~60 seconds, then fetch the latest deployment status using the Cloudflare API:

```bash
TOKEN=$(grep oauth_token "$APPDATA/xdg.config/.wrangler/config/default.toml" | cut -d'"' -f2)
ACCOUNT_ID="00b7e159c67efe0662f8f90f7ec0db04"

DEPLOY_ID=$(curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/salem-portfolio/deployments" \
  -H "Authorization: Bearer $TOKEN" | python -c "import json,sys; print(json.load(sys.stdin)['result'][0]['id'])")
```

Then fetch the logs and report:
- **Build status:** success or failure
- **Preview URL:** the deployment URL
- **If failed:** show the last 20 lines of the build log so the user can see what went wrong

**Step 5 — Tell the user**

Report the preview URL and build status. Remind the user:
> "This is a preview — it does NOT affect salem.australia-gpa.com. When you're happy, use `/ship` to merge into main."
