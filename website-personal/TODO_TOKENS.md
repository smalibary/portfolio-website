# Token Semantics TODO

Tracked issues found during the alias migration (Phase 3 Step 3.c).
These are not bugs — the mechanical rename preserved byte-equivalence —
but the semantic intent at these sites is "text on accent surface", not
"page background colour".

## color-on-accent mismatch (7 sites)

`--color-surface-page` is used as **text colour on an accent background**.
The correct semantic token is `--color-interactive-primary-text`, which
already exists in `web/tokens/semantic.css`.

| # | File | Line | Current token | Proposed token | Context |
|---|---|---|---|---|---|
| 1 | `web/admin.css` | 22 | `--color-surface-page` | `--color-interactive-primary-text` | `.adm .toggle button.active` — text on accent toggle |
| 2 | `web/admin.css` | 40 | `--color-surface-page` | `--color-interactive-primary-text` | `.adm .btn` — text on accent button |
| 3 | `web/styles.css` | 53 | `--color-surface-page` | `--color-interactive-primary-text` | `.mono` — text on accent monogram square |
| 4 | `web/styles.css` | 97 | `--color-surface-page` | `--color-interactive-primary-text` | `.theme-toggle button.active` — text on accent pill |
| 5 | `web/styles.css` | 198 | `--color-surface-page` | `--color-interactive-primary-text` | `.social:hover` — text on accent social icon |
| 6 | `web/styles.css` | 635 | `--color-surface-page` | `--color-interactive-primary-text` | `.pinned-badge` — text on accent badge |
| 7 | `lib/pages/admin/styleguide.dart` | 630 | `--color-surface-page` | `--color-interactive-primary-text` | `.adm .sg-main .theme-toggle button.active` — styleguide copy of #4 |

**Reason:** Each site sets `background: var(--accent)` (or inherits it from
`.mono`'s accent background) and uses the page-surface colour as text for
contrast. This works because the page surface and interactive-primary-text
resolve to the same primitive (`--black` in dark, `--cream-50` in light),
but the *intent* is "text on interactive-primary surface", which is exactly
what `--color-interactive-primary-text` expresses.

**When to fix:** After Commit 11 (`--accent` migration), when we revisit
all accent consumers. The Comment 6 rename will naturally intersect with
these sites.

**Risk:** If the page background and on-accent text ever diverge (e.g.
brand changes surface-page to a warm off-white but on-accent needs pure
white), these 7 sites would silently break. Low probability but nonzero.

---

## Responsive type clamps (10 values, 5 sites)

These `clamp(min, vw, max)` endpoints don't fit the static `--text-*`
scale. A future fluid-typography token system would tokenise these.

**Decision deferred** until fluid typography is needed elsewhere or a
redesign forces the question.

| File:Line | Selector | Clamp values |
|---|---|---|
| `web/styles.css:126` | `.hero__name-ar` | `clamp(40px, 5vw, 60px)` |
| `web/styles.css:137` | `.hero__name-en` | `clamp(15px, 1.3vw, 18px)` |
| `web/styles.css:144` | `.hero__lede-ar` | `clamp(18px, 1.65vw, 22px)` |
| `web/styles.css:153` | `.hero__lede-en` | `clamp(13px, 1.05vw, 15px)` |
| `web/styles.css:297` | `.card__metric` | `clamp(26px, 3vw, 34px)` |

These 10 values are the only remaining findings reported by
`audit_hardcoded_values.dart`. They serve as a visible reminder that
fluid typography is a someday-list item.

---

## Media query breakpoint values (6 sites)

CSS custom properties cannot be used inside `@media` queries — this is a
CSS language limitation, not a design system gap. Tokenising these
would require adopting a build-time preprocessor (PostCSS/Sass), which
is a larger architectural decision than adding tokens.

Lines are also annotated inline (commit `eea429f`) for in-context
reference.

| File:Line | Breakpoint | Purpose |
|---|---|---|
| `web/styles.css:495` | `1200px` | tablet/laptop |
| `web/styles.css:498` | `768px` | mobile |
| `web/styles.css:906` | `980px` | tablet (RESPONSIVE block start) |
| `web/admin.css:37` | `700px` | admin row collapse |
| `web/admin.css:126` | `700px` | admin photos collapse |
| `web/admin.css:142` | `900px` | admin md-split collapse |
