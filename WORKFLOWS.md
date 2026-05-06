# WORKFLOWS — process specs for design + build

How we *do* things. RULES.md is what's true; this file is how to act on it.

---

## Design → implementation: two tracks

Choose a track based on whether the page is a brand surface or a derivative
of one. **Never edit the live site without going through the relevant
mockup loop first.**

### Track 1 — Brand exploration (public-facing, new identity)

Use this for the public site, new visual identities, or anything
customer-facing where the brand itself is being designed.

1. **Three directions** — three deliberately different HTML mockups in `mockups/` (different colour world, typography, layout, mood). Range, not similarity.
2. **User picks one** (A / B / C).
3. **Three refinements** of the picked direction.
4. **Iterate** the chosen variant until happy.
5. **Port to Jaspr** in `website-jaspr/`. Move assets out of `inbox/` or `mockups/` into `website-jaspr/web/` (static) or `web/images/` (assets).
6. **Delete throwaway mockups** once shipped.

### Track 2 — Layout exploration (admin, internal, derivative)

Use this for admin pages, dashboards, settings screens, or any new page
within an existing product. The design system is already settled; what's
being explored is composition.

1. **Three layouts** — three deliberately different layouts, all using the **same** existing design tokens (colours, fonts, accent, spacing, nav style). Vary composition: single-pane vs split, list-first vs editor-first, density, where actions live.
2. **User picks one** (A / B / C).
3. **Three detail variations** of the picked layout (e.g. save button placement, inline vs modal editing, tab order, empty states).
4. **Iterate** until happy.
5. **Port to Jaspr** and delete throwaway mockups.

### Picking a track

- Public-facing brand surface → **Track 1**
- Admin / internal / settings / dashboard → **Track 2**
- Unsure → **ask before spawning the three mockups.** Picking the wrong track wastes a round.

---

## Mockups directory hygiene

- One folder per exploration: `mockups/<feature-name>/`
- Inside: `a.html`, `b.html`, `c.html` for direction phase; `a-1.html`, `a-2.html`, `a-3.html` for refinement phase
- After porting to Jaspr: **delete the mockup folder.** It served its purpose; keeping it bloats `mockups/` and confuses future passes.
- See `mockups/AGENTS.md` for the full convention.

---

## When to embed a Flutter web app

Jaspr is the right tool for everything content-shaped (pages, articles,
lists). It is **not** the right tool for genuinely app-shaped experiences
(interactive data viz, drawing tools, simulations, games, dashboards with
heavy state). For those, embed a Flutter web app inside one Jaspr page
as an escape hatch.

### Pattern

1. Build the Flutter app as a separate package (e.g. `apps/<name>/`, sibling to `website-jaspr/`).
2. `flutter build web --release` → static output.
3. Copy/symlink the build output into `website-jaspr/web/app/<name>/` so it ships with the static bundle.
4. Mount it from a Jaspr page either via `iframe` (simplest, isolates runtime) or by injecting `flutter_bootstrap.js` into a `div` (heavier integration, shared origin).

### Trade-offs to flag before going down this road

- Bundle is multi-MB even for small Flutter apps — slow first paint
- That page is **not** crawlable; exclude its route from `sitemap.xml`
- Two Dart runtimes on the page (Jaspr-pre-rendered + Flutter at runtime)
- No code sharing without extracting shared logic into a plain Dart package consumed by both — design that boundary up front

### Quick rule of thumb for the boundary

- **Inputs and submit?** (forms, contact, multi-step wizards, file upload, conditional fields, validation) → **Jaspr.** The web platform handles this natively — autofill, password managers, mobile keyboards, screen readers, native validation. Flutter web makes forms worse, not better.
- **Custom canvas-style interaction?** (drawing, drag-and-drop builder, real-time collab editor, simulation, signature pad) → **Flutter embed.**

If it's "fields + submit," even a long fancy one, it's Jaspr.

**Default answer: do it in Jaspr.** Reach for Flutter embed only when the
interaction model genuinely requires it.

---

## Adding a new public route — checklist

When you add a new page (e.g. `/library`, `/lab`, `/colophon`), do this in order:

1. **Decide the data source.** Is the copy in yaml? In `content/blog/<id>/`? Computed from existing data? If new, add to `content/_data/<thing>.yaml` first.
2. **Add a loader** in `lib/data/<thing>_data.dart` if the source is yaml.
3. **Build the page** in `lib/pages/<name>.dart`. Use existing components (Nav, footer, section-head) for consistency.
4. **Register the Route** in `lib/app.dart`.
5. **Add CSS** in `web/styles.css` (use existing tokens: `--bg`, `--ink`, `--accent`, etc.).
6. **Update sitemap generator** (`tool/generate_sitemap.dart`) to include the new route. If it's templated (one route per X), enumerate at build time.
7. **Test via** `dart run tool/build.dart` — confirm the route appears in build output and in `web/sitemap.xml`.
8. **Apply the SEO/AEO checklist** in RULES.md §5.

---

## Adding admin editor for a new content type — checklist

1. **Define the yaml schema** (in `content/_data/<thing>.yaml`).
2. **Add `GET /api/<thing>` and `POST /api/<thing>`** to `tool/save_server.dart`. Use `yaml_edit` to preserve formatting/comments on writes.
3. **Build the editor** in `lib/pages/admin/<thing>.dart`. Use the existing admin shell (`admin_shell.dart`) and rail (`rail.dart`).
4. **Register** in `app.dart` under `/admin/<thing>`.
5. **Wire save → reload** so the public page reflects the change after a save.
6. **Don't deploy admin to production** — passcode is cosmetic. See RULES.md §9.

---

## When to commit / when to push

- **Commit freely** — local commits are reversible.
- **Don't push without confirmation.** The remote is public (RULES.md §7); pushed history is harder to undo.
- **Use the `dart run tool/build.dart` workflow before pushing site changes** — guarantees fresh sitemap.

---

## Restarting the dev server cleanly

`tool/dev.dart` spawns `save_server.dart` and `jaspr serve` as children.
Stopping the parent doesn't always reap the children on Windows; orphaned
dart processes will hold ports `:8080`, `:9090`, `:5567`, `:8181` and
prevent restart.

If `dart run tool/dev.dart` fails on restart with "port in use":

```powershell
Get-NetTCPConnection -LocalPort 9090,5567,8080,8181 -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
```

Then restart `dart run tool/dev.dart`.
