---
description: Merge preview into main, push to production, switch back to preview
---

Merge the `preview` branch into `main`, push to production (which triggers
the live deploy to salem.australia-gpa.com), then switch back to `preview`.

**Step 0 — Skill check**

Before proceeding, check if any superpowers skills apply to this task.
If `verification-before-completion` applies, run verification first.
If `finishing-a-development-branch` applies, follow its flow.
This prompt is a quick operational flow — if skills add valuable checks,
use them before proceeding.

**Step 1 — Verify preview is up to date**

Make sure everything on preview is committed:

```bash
cd C:/CLI/small-projects/my-cv
git status
```

If there are uncommitted changes, commit them first (like `/preview` Step 1).
Do NOT proceed with uncommitted work.

**Step 2 — Merge preview into main**

```bash
git checkout main
git merge preview
```

If there are merge conflicts, stop and report them to the user. Do not
resolve conflicts silently.

**Step 3 — Push to main (this triggers the live deploy)**

```bash
git push origin main
```

**Step 4 — Switch back to preview**

```bash
git checkout preview
git merge main  # keep preview in sync
```

**Step 5 — Wait for build and report**

Wait ~60 seconds, then check the deployment status:

```bash
TOKEN=$(grep oauth_token "$APPDATA/xdg.config/.wrangler/config/default.toml" | cut -d'"' -f2)
ACCOUNT_ID="00b7e159c67efe0662f8f90f7ec0db04"

# Get latest deployment
curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/salem-portfolio/deployments" \
  -H "Authorization: Bearer $TOKEN" | python -c "
import json,sys
d=json.load(sys.stdin)['result'][0]
print(f'Status: {d[\"latest_stage\"][\"status\"]}')
print(f'URL: {d[\"url\"]}')
"
```

Report to the user:
- **Build status:** success or failure
- **Live URL:** `https://salem.australia-gpa.com`
- **If failed:** show the relevant error lines from the build log

**Step 6 — Reminder**

> "You're now back on the `preview` branch. Any new work will go to preview first."
