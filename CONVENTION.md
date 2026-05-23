# Convention

Universal language between Salem and any agent (Claude / pi / future) working
in any project that has this `.pi/` installed. Read it before assuming what
any term means. If ambiguous, stop and clarify here before proceeding —
ambiguity in this file = bugs everywhere downstream.

Location: `.pi/CONVENTION.md` is the canonical home. No symlinks, no pointer
files. Ships with `.pi/` to every project.

---

## CORE (managed by `wf-sync-skills` — do not edit unless changing the system itself)

### Architectural terms

- **Skill ≡ Workflow** — same unit, two words. A pi-runtime triggerable
  directory at `.pi/skills/<name>/` containing `SKILL.md` + scripts + its
  own data. Self-contained: everything the workflow needs lives inside its
  folder unless the user explicitly points elsewhere. "Workflow" emphasises
  the sequence of steps; "skill" emphasises the pi-runtime nature.

- **Component** — a small reusable unit of operation. One job. Lives at
  `.pi/component/<name>/`. Components are pure code modules — not pi
  skills. Workflows reference components via Python import inside their
  scripts. The agent never invokes a component directly.

- **Infrastructure workflow** — a workflow whose job is to own
  cross-cutting state for other workflows. Examples: `wf-capture-signal`
  (owns `data/signals.jsonl`), `wf-detect-patterns`, `wf-log-decision`.
  Other workflows call these instead of writing to a shared folder.
  **There is no shared `workspace/` folder.**

- **Workflow dependency** — when workflow A calls workflow B, A declares
  `uses: [B]` in its `SKILL.md` frontmatter.

- **Runner** — a shared executor at `.pi/component/runner/`. Reads a
  workflow's `steps` list and executes them in order, dispatching by
  `type`. This is what makes auto-execution possible without an agent in
  the loop.

### Workflow file format (the universal DSL)

Every workflow's `SKILL.md` has YAML frontmatter with:

- `name`, `description` — standard pi fields
- `uses: [<other-workflow>, ...]` — workflow dependencies
- `managed_by: core` — present if this is a generic system workflow;
  omit for project-specific workflows
- `triggers:` — list of triggers (see below)
- `steps:` — ordered list of steps to execute

Markdown body below the frontmatter is freeform context the agent reads
when invoking the workflow manually.

### Step types (initial vocabulary, extend as needed)

- `code` — run a script. Fields: `run` (path), optional `component`.
- `agent` — prompt the agent to act/judge. Fields: `prompt`.
- `wait` — pause. Fields: `seconds`.
- `parallel` — run branches concurrently. Fields: `branches`.
- `call-workflow` — invoke another workflow. Fields: `workflow`, `args`.
- `human-approval` — pause for explicit user OK.

### Triggers

Each workflow may declare one or more triggers in frontmatter. Two kinds:

- `event` — deterministic (bash command match, file save, cron). Fires
  via a real hook installed by the harness installer.
- `context` — fuzzy (description match). Fires when an agent loads the
  skill in a matching conversation. Equivalent to pi's native behaviour.

A workflow with no `triggers` block is context-only by default.

### Capture modes (how new workflows come into existence)

- **Top-down** — user invokes the meta-skill (`wf-build-skill`) and
  describes the workflow they want. Meta-skill interviews and scaffolds.
- **Bottom-up** — `wf-capture-signal` collects signals during normal
  conversation. `wf-detect-patterns` surfaces patterns. If a pattern has
  N+ signals, it suggests building a workflow; on user approval, hands
  off to `wf-build-skill`.

Both modes produce the same output: a fully-scaffolded
`.pi/skills/<new-wf>/` folder.

### Portability model

Entire system lives at `.pi/` inside each project. Install in a new
project = copy `.pi/` (manually, or via `wf-sync-skills`).
Project-specific workflows live alongside generic ones in the same
`.pi/skills/` folder; `managed_by: core` frontmatter marks the generic
ones so sync knows what to overwrite vs leave alone.

---

## PROJECT-SPECIFIC (yours — edit freely; sync won't touch)

### This project's domain terms

(none yet — fill in as workflows introduce them. Likely additions:
"Medium ladder", "Design Eye", "the brand vs internal track distinction",
"north star".)

### This project's stage scope

**Stage 1 ships (locked 2026-05-22):**

- `.pi/component/runner/` — the DSL executor
- `.pi/skills/wf-push-preview/` — project-specific workflow
- `.pi/skills/wf-capture-signal/` — infrastructure workflow
- Trigger installer for Claude Code (registers the bash-command hook)

**Stage 2+ deferred:**

- `wf-build-skill` (the meta-skill — top-down + bottom-up)
- `wf-detect-patterns`
- `wf-log-decision`
- `wf-sync-skills`
- Real business workflows (content, consulting, thesis)

### Still open (decide during spec/plan)

- [ ] Component referencing convention (path vs name vs import)
- [ ] Trigger installer concrete form (settings.json hook? wrapper script?)
- [ ] How step results pass between steps (variables, shared context)
- [ ] Error handling mid-workflow (skip / retry / abort)

### Locked decisions log

- 2026-05-22 — Skill ≡ Workflow
- 2026-05-22 — Component lives at `.pi/component/<name>/`
- 2026-05-22 — Cross-cutting data lives inside infrastructure workflows;
  no shared `workspace/`
- 2026-05-22 — Workflow format: declarative YAML DSL + scripts; runner
  executes step list dispatched by `type`
- 2026-05-22 — Trigger mechanism: workflows declare event + context
  triggers; harness installer registers actual hooks
- 2026-05-22 — Meta-skill: single `wf-build-skill` with top-down and
  bottom-up entry modes
- 2026-05-22 — Portability: per-project `.pi/`, copy or future
  `wf-sync-skills`; `managed_by: core` distinguishes generic vs
  project-specific
- 2026-05-22 — `.pi/CONVENTION.md` is the canonical home (system-level
  artefact, not skill-owned, alongside `component/` and `skills/`)
