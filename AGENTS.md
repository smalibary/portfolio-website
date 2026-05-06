# my-cv — Salem Malibary's personal site & CV

Entry point for any AI agent. **Read this first**, then go to the file
that matches your task.

## Read first — every session

| File | When to read | What it has |
|---|---|---|
| **`RULES.md`** | Before any decision, code, or copy change | Always-on rules: writing style, bilingual, SEO/AEO, public copy, git, "Don'ts" |
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
| any decision, rule, or constraint | `RULES.md` |
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

## Quick orientation — the 30-second version

- **Public copy** lives in yaml/markdown under `website-jaspr/content/`, never hardcoded in Dart
- **Public-facing positioning** flows from `context/`, never written from scratch
- **Two design tracks** (brand vs layout) — see WORKFLOWS.md before mockups
- **Public repo** at `github.com/smalibary/portfolio-website` — strict gitignore at root keeps `context/`, `inbox/`, `mockups/`, `ROADMAP.md`, blog drafts private
- **Production builds:** `dart run tool/build.dart` (NOT `jaspr build` directly — see RULES.md §8)
- **Don't deploy `/admin/*`** to production — passcode is cosmetic, save server is local-only
