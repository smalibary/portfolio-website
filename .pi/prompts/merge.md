---
description: Merge current branch into target, discuss approach first
argument-hint: "[target-branch]"
---

You are about to help merge the current git branch. Follow these steps IN ORDER. Do NOT skip ahead.

**Step 0 — Skill check**

Before proceeding, invoke these superpowers skills if available:
- `finishing-a-development-branch` — this prompt IS a branch completion workflow; that skill should guide the structure
- `verification-before-completion` — verify tests pass before any merge
- Any other skill that might apply to the current situation

Announce which skills you're using, then follow them alongside the steps below.
If the skill's process contradicts a step below, follow the skill.

**Step 1 — Status check**

Run these and report the results clearly:
- `git branch --show-current` — what branch are we on?
- `git status --short` — any uncommitted changes?
- `git log --oneline -5` — recent commits on this branch
- `git log --oneline main..HEAD` (or the target branch) — commits ahead of target

If there are uncommitted changes, STOP and tell me. Ask whether to commit or stash them first.

**Step 2 — Verify tests**

Run the project's build/check before offering merge options:

```bash
cd C:/CLI/small-projects/my-cv/website-jaspr && dart run tool/build.dart
```

If the build fails, STOP. Report failures. Do not proceed to merge options.

**Step 3 — Present merge options**

Show me these options clearly numbered:

1. **Fast-forward merge** — clean linear history (only works if no divergence)
2. **Merge commit** — preserves branch history, creates a merge commit
3. **Squash merge** — squashes all branch commits into one clean commit on target
4. **Rebase then merge** — rewrites branch commits on top of target, then fast-forward
5. **Delete branch only** — already merged, just clean up the branch

For each option, note if it's possible given the current state (e.g. fast-forward only works if no divergence).

**Step 4 — Wait for my choice**

Do NOT proceed until I pick an option. If I want to discuss trade-offs, answer my questions.

**Step 5 — Execute**

After I confirm:
1. Switch to the target branch (default: `main`)
2. Pull latest if remote exists
3. Perform the merge using my chosen method
4. Ask if I want to delete the source branch
5. Ask if I want to push to remote (RULES.md §7 — repo is public, don't push without confirmation)

**Step 6 — Verify**

Run `git log --oneline -5` on the target branch and confirm the merge is clean.
Per `verification-before-completion`: show the evidence, then state the result.
