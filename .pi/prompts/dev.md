---
description: Kill orphaned processes and start the Jaspr dev server
---

Kill any orphaned dart processes holding the dev ports, then start the dev server.

**Step 0 — Skill check**

Before proceeding, check if any superpowers skills apply to this task.
This is an operational prompt (start a server) — no creative or code changes.
If no skills apply, skip to Step 1.

**Step 1 — Kill orphaned processes**

Run this PowerShell command to free ports 9090, 5567, 8080, 8181:

```powershell
Get-NetTCPConnection -LocalPort 9090,5567,8080,8181 -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
```

**Step 2 — Start the dev server**

```bash
cd C:/CLI/small-projects/my-cv/website-jaspr && dart run tool/dev.dart
```

**Step 3 — Report**

Wait for both `[save]` and `[jaspr]` lines to indicate readiness, then report the local URLs to the user.
