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
