# website-jaspr — Salem Malibary's site (Jaspr)

The live site. Built with Jaspr (Dart web framework with SSG output) and
content-driven via YAML / markdown files under `content/`. Includes a
local-only admin panel at `/admin/*` for editing that content.

## Tech stack

- **Jaspr** 0.23 — Dart web framework, Flutter-like component model, renders real HTML/CSS
- **`jaspr_router`** 0.8 — multi-route SSG (one HTML file per Route at build time)
- **`yaml` + `yaml_edit`** — read/write `content/_data/*.yaml`
- **`markdown`** — render blog post bodies to HTML at build time
- **`shelf`** + **`shelf_router`** — local-only save server for the admin (`tool/save_server.dart`)
- **Static Site Generation** — pre-renders to plain HTML, no SSR runtime

## Why Jaspr (not Flutter web)

Flutter web is canvas-rendered and poor for SEO. Jaspr renders real HTML/CSS
with a Flutter-like component API in Dart. Same language, web-native output.

## Data flow

```
                                       ┌─────────────────────────┐
                                       │  /admin/* (Jaspr pages) │
                                       │  passcode: 1379         │
                                       └────────────┬────────────┘
                                                    │ POST JSON
                                                    ▼
                              ┌──────────────────────────────────────┐
   ┌─────────────────┐        │  tool/save_server.dart (shelf, :9090)│
   │  jaspr serve    │        │  /api/profile  /api/posts            │
   │  :8080          │        │  /api/papers   /api/upload           │
   └────────┬────────┘        └──────────────┬───────────────────────┘
            │                                │ writes
            │ reads at build time            ▼
            └──────►  content/_data/site.yaml
                     content/_data/papers.yaml
                     content/blog/<id>/post.json + final.md
                     web/images/<uploaded>
```

The public site reads these files via `lib/data/*.dart` loaders during
pre-rendering. The admin writes them via the save server. Edit in admin →
save → jaspr rebuilds → homepage reflects the change.

## Structure

```
website-jaspr/
├── content/                       ← source of truth for site copy
│   ├── _data/
│   │   ├── site.yaml              ← name, tagline, bio, hero copy, photos, socials
│   │   └── papers.yaml            ← research papers list
│   └── blog/
│       └── <id>/
│           ├── post.json          ← post metadata
│           └── final.md           ← markdown body
├── lib/
│   ├── main.server.dart           ← entry point — runs at pre-render time
│   ├── main.client.dart           ← entry point — hydrates @client components
│   ├── app.dart                   ← Document + Router with all routes
│   ├── data/                      ← YAML/JSON loaders (build-time only)
│   │   ├── site_data.dart
│   │   ├── blog_data.dart
│   │   └── paper_data.dart
│   ├── pages/
│   │   ├── home.dart              ← /
│   │   ├── blog_post.dart         ← /blog/<slug> (one Route per post)
│   │   └── admin/
│   │       ├── login.dart         ← /admin/login (passcode 1379)
│   │       ├── profile.dart       ← /admin/profile (edits site.yaml)
│   │       ├── blog.dart          ← /admin/blog (edits blog/*)
│   │       └── research.dart      ← /admin/research (edits papers.yaml)
│   └── components/
│       ├── nav.dart, hero.dart, footer.dart   ← public site
│       ├── research_grid.dart, writing_list.dart
│       ├── social_icons.dart, theme_toggle.dart
│       └── admin/
│           ├── admin_shell.dart   ← rail + auth gate wrapper
│           ├── rail.dart          ← persistent left rail
│           └── topbar.dart        ← section name + saved chip
├── tool/
│   ├── save_server.dart           ← shelf API on :9090, writes to content/* + web/images
│   └── dev.dart                   ← runs jaspr serve + save_server together
├── web/
│   ├── styles.css                 ← public site styles (B1 magazine-split)
│   ├── admin.css                  ← admin styles (namespaced under .adm)
│   └── images/
└── pubspec.yaml
```

## Conventions

- Imports: every component file needs **both**
  ```dart
  import 'package:jaspr/jaspr.dart';   // Component, StatelessComponent
  import 'package:jaspr/dom.dart';     // div, span, a, section, etc.
  ```
- HTML element classes are `final class` types — call them like constructors:
  `div(classes: 'foo', [child1, child2])`
- Reserved names get a trailing underscore: `main` → `main_`
- Inline content (text or raw HTML): `text('...')` and `raw('<svg>...</svg>')`
- `build()` returns a **single** `Component` (not `Iterable<Component>`).
  For multiple children at the top level: `return Component.fragment([...])`
- `<script>` is special: `script(content: '...')` for inline JS,
  `script(src: '...')` for external. **Does not take children** —
  passing `[...]` as a positional arg fails to compile.

## Theming

- Single global CSS at `web/styles.css`; admin styles in `web/admin.css`
- Light/dark via `[data-theme]` on `<html>`, with CSS custom properties
- Theme toggle: client-side JS, persists via `localStorage` key `salem-theme`
- Pre-paint script in `<head>` sets the theme before render (no flash)
- Admin styles all namespaced under `.adm` (e.g. `.adm .btn`) so they
  never collide with the public site's `.btn`/`.card`/`.nav`/etc.

## Bilingual rules

- `<html lang="ar" dir="rtl">` set via `Document(lang: 'ar')` and CSS
- Arabic primary, English secondary throughout
- **Bidi gotcha**: Arabic + Latin digit + Latin word (e.g. "على 3 projects")
  reorders unless wrapped in `<bdi>`. In Jaspr you can use:
  ```dart
  raw('على <bdi>3 projects</bdi> متوازية')
  ```

## Content workflow (this is the live data flow)

**Public-facing copy lives in `content/` — never hardcoded in Dart.**
The migration off hardcoded copy is complete. Touch-ups go through these
data loaders (`lib/data/site_data.dart`, `blog_data.dart`, `paper_data.dart`).
If you need a new field, add it in three places: yaml file, data model,
and the consumer component (and the admin editor if Salem should be able
to edit it via UI).

### Hero lede emphasis

The lede paragraphs (`lede_ar` / `lede_en` in `site.yaml`) support inline
emphasis via `*phrase*` syntax — rendered as `<em>phrase</em>` by
`Hero._renderEmphasis()`. Stick to single-asterisk pairs; nesting and
double-asterisk (markdown bold) are not handled.

## Admin panel — `/admin/*`

Local-only authoring UI. Lock icon in the public footer is the entry point.

- **Auth**: client-side passcode `1379` checked against `sessionStorage['admin-auth']`. Cosmetic, not real security. Don't deploy admin to production without replacing this.
- **Layout**: V3 Workspace — persistent rail on the start edge (right in RTL), no separate dashboard, lands directly in the last edited section.
- **Editor pages**: profile (single-item form), blog (picker + tabs + markdown body with live preview), research (picker + per-paper form, single-file API).
- **Save flow**: forms POST JSON to `:9090`; save server uses `yaml_edit` to preserve formatting/comments and `JsonEncoder.withIndent` for `post.json`.
- **Photo upload**: `POST /api/upload` accepts `{filename, base64}`, sanitises the basename, restricts to image extensions, writes to `web/images/`. The admin profile editor has UPLOAD buttons that handle this end-to-end.
- **Markdown live preview**: blog editor includes `marked.min.js` from CDN and renders the body to HTML in a side pane on every keystroke.

The admin layout system was decided via the Track-2 mockup workflow
(layout exploration in `mockups/admin-l3-v3-picker/`). That mockup is
the source-of-truth for the visual decisions; the implementation lives in
`lib/pages/admin/` and `lib/components/admin/`.

## Build / run

```sh
cd website-jaspr
dart run tool/dev.dart       # starts BOTH jaspr serve (:8080) and save_server (:9090)
```

Or start them separately:

```sh
jaspr serve                       # public site dev server
dart run tool/save_server.dart    # admin save endpoint
```

On Windows the `jaspr` CLI lives at
`%LOCALAPPDATA%\Pub\Cache\bin\jaspr.bat`. `tool/dev.dart` resolves this
automatically.

If incremental builds get stuck (jaspr reports "wrote 0 outputs" but the
served HTML is stale), nuke the build cache:

```sh
rm -rf .dart_tool/build build
```

Then restart `dart run tool/dev.dart`.

## Deployment

Only the public site is deployed. Run `jaspr build` and ship `build/jaspr/`
to any static host: GitHub Pages, Cloudflare Pages, Netlify, Vercel.
**Do not deploy the admin** — its passcode is cosmetic and the save endpoint
is local-only. If you ever do, replace `1379` with real auth and host the
save server somewhere reachable.

## Don't

- Don't add hardcoded copy in Dart components when a yaml/markdown field
  would do — it makes admin editing impossible.
- Don't import Flutter packages here — Jaspr is its own framework.
- Don't bypass the `<bdi>` wrapper when mixing Arabic + Latin + digits.
- Don't change the visual design without a mockup pass.
- Don't pass children to `script(...)` — use `content:` (inline JS) or
  `src:` (external URL).
- Don't deploy `/admin/*` to production without replacing the passcode
  with real auth.
- Don't write to `content/` from public-site components — that direction
  is for admin → save_server only.
