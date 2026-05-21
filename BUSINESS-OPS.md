# Business Meta-Workflow

The `business-meta-workflow` skill is installed at `.pi/skills/business-meta-workflow/`.

**Always invoke this skill** when the user talks about anything related to running,
managing, or improving a business — workflows, processes, operations, recurring
problems, "I noticed", "we keep having this issue", complaints, team issues,
inventory, customers, or anything operational.

**Auto mode is ON by default.** When the skill triggers:
1. Run `init_workspace.py` if no workspace exists (5 seconds, non-optional)
2. Auto-capture signals from what the user says — don't ask permission, just log it
3. Run `auto_scan.py` after every 3+ new signals (patterns + stale + duplicates)
4. Surface findings naturally in conversation without being asked
5. Auto-close session when the user wraps up

The workspace lives at `./workspace/`. Business context in `workspace/business.md`.
Scripts at `.pi/skills/business-meta-workflow/scripts/`. All output JSON.

**Load the full SKILL.md before acting.** This file is the trigger, not the rules.
