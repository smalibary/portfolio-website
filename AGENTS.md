# my-cv — Salem Malibary's personal site & CV

Entry point for any AI agent. **Read this first**, then go to the file
that matches your task.

## Read first — every session

| File | When to read | What it has |
|---|---|---|
| **`RULES.md`** | Before any decision, code, or copy change | Always-on rules: writing style, bilingual, SEO/AEO, public copy, git, "Don'ts" |
| **`DESIGN.md`** | Before understanding the system architecture or token philosophy | 3-tier architecture, brand-vs-interactive rule, dependency rules, worked examples |
| **`WORKFLOWS.md`** | Before any visual change, new route, or admin feature | Track 1/2 mockup loops, Flutter embed pattern, route + admin checklists |

If a rule needs to change, update RULES.md as part of the same commit.
Don't decide silently in a chat that future sessions can't see.

## What this is

Salem Malibary's personal site and writing platform. Bilingual (Arabic
primary, English secondary). Visual identity: research-lab DNA — dark/
light theme, IBM Plex Sans Arabic + JetBrains Mono pairing, teal accent.

Built with **Jaspr** (Dart web framework, Flutter-like component model,
renders real HTML for SEO/AEO). Content is markdown/yaml-driven — public
site reads from `website-jaspr/content/` at build time, with a local-only
admin panel at `/admin/*` for editing those files via a UI (passcode 1379,
cosmetic). See `website-jaspr/AGENTS.md` for the full architecture.

## Subdirectories

| Folder | Purpose | Read first |
|---|---|---|
| `website-jaspr/` | The live site — Jaspr, source of truth | `website-jaspr/AGENTS.md` |
| `mockups/` | HTML design exploration before applying to Jaspr | `mockups/AGENTS.md` |
| `inbox/` | Drop zone for unsorted materials (move them out, don't reference) | `inbox/AGENTS.md` |
| `thesis-structure/` | Quarto+Typst PhD thesis build (separate concern) | `thesis-structure/rules/` |
| `context/` | Brand context for The Design Eye / عين التصميم content brand | `context/AGENTS.md` then `context/INDEX.md` |
| `tools/` | Small Python utilities (word counter, OG card generator) |  |

## Entry points by task

| Task | Read |
|---|---|
| deployment / CI / Cloudflare Pages | `DEPLOY.md` |
| any decision, rule, or constraint | `RULES.md` |
| token / CSS / spacing / radius change | `website-jaspr/web/tokens/TOKENS.md` (loads in scope) |
| new component or component modification | `website-jaspr/lib/components/COMPONENTS.md` (loads in scope) |
| understanding the design system architecture | `DESIGN.md` |
| visual / layout / new route changes | `WORKFLOWS.md` then `mockups/AGENTS.md` |
| what to build next on the site | `ROADMAP.md` (100+ items, gitignored — local only) |
| Jaspr component code (live site) | `website-jaspr/AGENTS.md` |
| admin panel changes (`/admin/*`) | `website-jaspr/AGENTS.md` "Admin panel" section |
| save server / API endpoints | `website-jaspr/tool/save_server.dart` |
| sitemap / SEO scaffolding | `website-jaspr/tool/generate_sitemap.dart`; RULES.md §5 |
| OG card generation | `tools/generate_og.py`; RULES.md §5.4 |
| sorting dropped files | `inbox/AGENTS.md` |
| brand voice / Arabic writing | `context/voice.md` |
| brand strategy / positioning / content scope | `context/AGENTS.md` |
| writing a public-facing post / article / script / bio | RULES.md §3 first; then `context/voice.md`, `topical-scope.md`, `guardrails.md` |
| thesis chapters / pipeline | `thesis-structure/rules/` |

## Design system

This project has a documented 3-tier design system. The philosophy lives
in `DESIGN.md`. Procedural rules are scoped:
- When working with tokens (`web/tokens/`, `web/styles.css`, `web/admin.css`):
  `website-jaspr/web/tokens/TOKENS.md` codifies the "when to add a token"
  decision tree.
- When working with components (`lib/components/`):
  `website-jaspr/lib/components/COMPONENTS.md` codifies component
  classification and the "when to create a component" decision tree.

Default behaviour: **REUSE before EXTENDING before CREATING.** Both scoped
files contain mandatory decision trees — work through them in order before
any addition.

## Prompt templates (`.pi/prompts/`)

Pi slash-commands for common workflows. Type `/name` in the pi editor to invoke.
Every prompt includes a **Step 0 — Skill check** that scans superpowers skills
before acting. If a skill applies, it takes priority over the prompt's defaults.

| Command | What it does | Skills it triggers |
|---|---|---|
| `/dev` | Kills orphaned processes on dev ports, starts `dart run tool/dev.dart` | _(operational — no skills usually apply)_ |
| `/merge` | Merge current branch into target with guided options | `finishing-a-development-branch`, `verification-before-completion` |

To add a new prompt, create `.pi/prompts/<name>.md` with a YAML frontmatter
`description` field. Always add a Step 0 skill check. See pi docs
(`docs/prompt-templates.md`) for the full format.

---

## Quick orientation — the 30-second version

- **Public copy** lives in yaml/markdown under `website-jaspr/content/`, never hardcoded in Dart
- **Public-facing positioning** flows from `context/`, never written from scratch
- **All visual decisions** follow the scoped rules — `website-jaspr/web/tokens/TOKENS.md` for tokens, `website-jaspr/lib/components/COMPONENTS.md` for components. `DESIGN.md` covers the architecture and brand-vs-interactive philosophy
- **Two design tracks** (brand vs layout) — see WORKFLOWS.md before mockups
- **Minimal components** — don't create a new component variant unless something genuinely needs different structure. Use tokens (radius, spacing, border) to differentiate, not new CSS classes
- **Public repo** at `github.com/smalibary/portfolio-website` — strict gitignore at root keeps `context/`, `inbox/`, `mockups/`, `ROADMAP.md`, blog drafts private
- **Production builds:** `dart run tool/build.dart` (NOT `jaspr build` directly — see RULES.md §8)
- **Deployed on Cloudflare Pages** — auto-deploys on push to `main`. See `DEPLOY.md` for full details
- **Don't deploy `/admin/*`** to production — passcode is cosmetic, save server is local-only
