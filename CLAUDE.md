# my-cv — Salem Malibary's personal site & CV

Entry point for any AI agent working in this repo. Read this first, then read the
relevant subdirectory's CLAUDE.md before doing work inside it.

## What this is

Salem Malibary's personal site and writing platform. Bilingual (Arabic primary,
English secondary). Visual identity: research-lab DNA — dark/light theme, IBM
Plex Sans Arabic + JetBrains Mono pairing, teal accent.

The site is built with **Jaspr** (Dart web framework, Flutter-like component
model, renders real HTML for SEO/AEO). Content is markdown/yaml-driven — the
public site reads from `website-jaspr/content/` at build time, and there's a
local-only admin panel at `/admin/*` for editing those files via a UI
(passcode 1379, cosmetic — see `website-jaspr/CLAUDE.md` for the full
architecture).

## Subdirectories

| Folder | Purpose | Read first |
|---|---|---|
| `website-jaspr/` | The live site — Jaspr, source of truth | `website-jaspr/CLAUDE.md` |
| `mockups/` | HTML design exploration before applying to Jaspr | `mockups/CLAUDE.md` |
| `inbox/` | Drop zone for unsorted materials (move them out, don't reference) | `inbox/CLAUDE.md` |
| `thesis-structure/` | Quarto+Typst PhD thesis build (separate concern) | `thesis-structure/rules/` |
| `context/` | Brand context for The Design Eye / عين التصميم content brand | `context/CLAUDE.md` then `context/INDEX.md` |
| `tools/` | Small Python utilities |  |

## Design → implementation workflow

Two tracks. Choose based on whether the page is a brand surface or a
derivative of one. Never edit the live site without going through the
relevant mockup loop first.

### Track 1 — Brand exploration (public-facing, new identity)

Use this for the public site, new visual identities, or anything customer-
facing where the brand itself is being designed.

1. **Three directions** — three deliberately different HTML mockups in
   `mockups/` (different colour world, typography, layout, mood). Range,
   not similarity.
2. **User picks one** (A / B / C).
3. **Three refinements** of the picked direction.
4. **Iterate** the chosen variant until happy.
5. **Port to Jaspr** in `website-jaspr/`. Move assets out of `inbox/` or
   `mockups/` into `website-jaspr/web/` (static) or `web/images/` (assets).
6. **Delete throwaway mockups** once shipped.

### Track 2 — Layout exploration (admin, internal, derivative)

Use this for admin pages, dashboards, settings screens, or any new page
within an existing product. The design system is already settled; what's
being explored is composition.

1. **Three layouts** — three deliberately different layouts, all using
   the **same** existing design tokens (colours, fonts, accent, spacing,
   nav style). Vary composition: single-pane vs split, list-first vs
   editor-first, density, where actions live.
2. **User picks one** (A / B / C).
3. **Three detail variations** of the picked layout (e.g. save button
   placement, inline vs modal editing, tab order, empty states).
4. **Iterate** until happy.
5. **Port to Jaspr** and delete throwaway mockups.

When in doubt about which track applies, ask before spawning the three
mockups — picking the wrong track wastes a round.

## Bilingual rules

- Arabic is primary on every public page — RTL, larger type, presented first.
- English appears as a secondary subtitle / translation, smaller and muted.
- Mixed inline text (Arabic + Latin digit + Latin word) needs `<bdi>` isolation
  in HTML, or wrap with `raw('<bdi>...</bdi>')` in Jaspr components.
  Without it, sequences like "على 3 projects" render as "projects 3".

## SEO / AEO

The Jaspr site renders real HTML at build time — pages are crawlable by
Google and AI answer engines (Perplexity, ChatGPT search, Claude search,
Gemini) without execution. No SSR server needed; output is plain static
HTML/CSS/JS.

## Content data flow

Public site copy lives in `website-jaspr/content/`:

- `content/_data/site.yaml` — name, tagline, bio, hero copy (status line,
  lede with `*emphasis*`, meta items), photos (light + dark), socials.
- `content/_data/papers.yaml` — research papers list.
- `content/blog/<id>/post.json` + `final.md` — one folder per blog post.

Public-site components read these via `lib/data/*.dart` loaders during
pre-rendering. The admin panel writes them via a local-only Dart shelf
server (`tool/save_server.dart` on `:9090`). Edit in admin → save →
jaspr rebuilds → homepage reflects the change. Image uploads land in
`web/images/` via `POST /api/upload`.

When adding a new piece of public-facing copy, put it in yaml first and
read it via a data loader — don't hardcode in Dart components.

## When the user wants a Flutter "app" page

Jaspr is the right tool for everything content-shaped (pages, articles,
lists). It is **not** the right tool for genuinely app-shaped experiences
(interactive data viz, drawing tools, simulations, games, dashboards with
heavy state). For those, you can embed a Flutter web app inside one Jaspr
page as an escape hatch.

Pattern (when needed, not now):

1. Build the Flutter app as a separate package (e.g. `apps/<name>/`,
   sibling to `website-jaspr/`).
2. `flutter build web --release` → static output.
3. Copy/symlink the build output into `website-jaspr/web/app/<name>/`
   so it ships with the static bundle.
4. Mount it from a Jaspr page either via `iframe` (simplest, isolates
   runtime) or by injecting `flutter_bootstrap.js` into a `div` (heavier
   integration, shared origin).

Trade-offs to flag to the user before going down this road:

- Bundle is multi-MB even for small Flutter apps — slow first paint.
- That page is **not** crawlable; exclude its route from sitemap.xml.
- Two Dart runtimes on the page (Jaspr-pre-rendered + Flutter at runtime).
- No code sharing without extracting shared logic into a plain Dart package
  consumed by both — design that boundary up front.

Default answer: do it in Jaspr. Reach for Flutter embed only when the
interaction model genuinely requires it.

**Quick rule of thumb for the boundary:**

- **Inputs and submit?** (forms, contact, multi-step wizards, file upload,
  conditional fields, validation) → **Jaspr.** The web platform handles
  this natively — autofill, password managers, mobile keyboards, screen
  readers, native validation. Flutter web makes forms worse, not better.
- **Custom canvas-style interaction?** (drawing, drag-and-drop builder,
  real-time collab editor, simulation, signature pad) → **Flutter embed.**

If it's "fields + submit," even a long fancy one, it's Jaspr.

## Always-on constraints

- Australian English spelling in academic writing
- APA 7th edition citations in academic content
- Hejazi Saudi dialect in Arabic content
- No em dashes (—) in Arabic content (use بعكس / بعد كدا / و لكن instead)
- See `context/voice.md` if working on brand voice or content writing

## Entry points by task

| Task | Read |
|---|---|
| what to build next on the site / feature backlog | `ROADMAP.md` (100-item checklist at repo root) |
| visual / layout changes | `mockups/CLAUDE.md` |
| Jaspr component code (live site) | `website-jaspr/CLAUDE.md` |
| admin panel changes (`/admin/*`) | `website-jaspr/CLAUDE.md` "Admin panel" section |
| save server / API endpoints | `website-jaspr/tool/save_server.dart` |
| embed a Flutter app page | "When the user wants a Flutter 'app' page" section above |
| sorting dropped files | `inbox/CLAUDE.md` |
| brand voice / Arabic writing | `context/voice.md` |
| brand strategy / positioning / content scope | `context/CLAUDE.md` |
| writing a public-facing post / article / script / bio | `context/CLAUDE.md` first; then `voice.md` + `topical-scope.md` + `guardrails.md` |
| thesis chapters / pipeline | `thesis-structure/rules/` |

## Public-facing copy / about pages / bio text

Any public-facing text that describes Salim, the brand, or what he covers
(site about pages, LinkedIn bio, video descriptions, talk bios, book pitch,
proposals) must flow from `context/`. Don't write positioning text from
scratch — pull it from `context/identity.md`, `context/topical-scope.md`,
and `context/guardrails.md`. If those files would need to change to support
the copy, update them first via the decisions log, then write the copy.

Common positioning elements to pull from `context/`:
- He is an "academic practitioner — architect + environmental psychology PhD"
  (not "architect" alone, not "designer", not "AI educator")
- The brand covers the **built environment universe** at every scale
  (object → city + practice), not "AI for designers" or "creative leadership"
- Career endgame trio: full professor / CCO / solo high-fee consultant
- No religion or politics framing — see `context/guardrails.md`

## Git / GitHub

This repo is initialised at the `my-cv/` root and pushed to a **public**
remote: `https://github.com/smalibary/portfolio-website`. Anything you
commit becomes part of public history, even if force-pushed later.

The root `.gitignore` excludes private working materials:

| Path | Why ignored |
|---|---|
| `context/` | Brand strategy, positioning, monetisation, clients — private |
| `inbox/` | Unsorted in-progress materials |
| `mockups/` | Throwaway design explorations (Track 1 / Track 2) |
| `ROADMAP.md` | Private 100-item feature backlog |
| `website-jaspr/content/blog/` | Blog drafts — kept out of public history; the live site builds from the local copy |
| `.claude/`, `.zed/`, `.dart_tool/`, `build/` | Tool/editor caches and build artifacts |
| `.env*`, `*.key`, `*credentials*` | Defensive secrets exclusion |

What **is** tracked publicly:

- `website-jaspr/lib/`, `web/`, `tool/`, `pubspec.yaml`, `analysis_options.yaml`, `README.md` — the site source
- `website-jaspr/content/_data/site.yaml` and `papers.yaml` — public profile + research list (already public-facing)
- `tools/word_count.py` — utility script
- This file (`CLAUDE.md`) and `website-jaspr/CLAUDE.md` — agent guidance

**Before adding a new top-level folder** with anything sensitive, update
`.gitignore` first, then commit. **Before adding a credential or env
file anywhere**, double-check the gitignore covers it.

## Don't

- Don't hardcode site copy in Dart components — it should come from
  `content/_data/*.yaml` or `content/blog/<id>/` via the data loaders.
- Don't reference files in `inbox/` from production code; move them first.
- Don't change the visual design without a mockup pass.
- Don't add a third locale until ar is fully wired alongside en.
- Don't deploy `/admin/*` to production — passcode is cosmetic and the
  save server is local-only.
- Don't write public positioning text without reading `context/CLAUDE.md` first.
- Don't suggest live-performance content formats (live podcasts, panels,
  on-camera video, in-person speaking) before the medium ladder reaches
  that phase — see `context/medium-ladder.md`.
- Don't track `context/`, `inbox/`, `mockups/`, `ROADMAP.md`, or any
  `website-jaspr/content/blog/` drafts in git. They're listed in the root
  `.gitignore` for a reason.
