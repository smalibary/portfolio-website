# Salem Malibary Design System

The design system for this project. Philosophy and architecture live here;
procedural rules are in scoped files loaded when working in those areas:
- `/website-personal/web/tokens/TOKENS.md` — token decision tree
- `/website-personal/lib/components/COMPONENTS.md` — component decision tree

---

## Architecture: 3-tier token system

Three CSS files, each a layer with a strict dependency direction:

```
primitives.css    raw values — colours, spacing, radii, typography
       ↓ referenced by
semantic.css      purpose-named, theme-aware — surfaces, text, borders, brand
       ↓ referenced by
components.css    component-scoped — composes from primitives + semantic
       ↓ consumed by
styles.css / admin.css   CSS selectors — reference semantic + component tokens only
```

Theme overrides (dark/light) live in `semantic.css`. Primitives never
change per theme. Components never reference primitives directly.

Example — a card's padding:

```
primitives.css:   --space-6: 24px;
components.css:   --c-card-pad: var(--space-6);
styles.css:       .card { padding: var(--c-card-pad); }
```

The selector never touches `--space-6`. If card padding changes, one edit
to `--c-card-pad` in `components.css` ripples everywhere.

## The dependency rule (tokens)

Selectors reference semantic or component tokens. Either is fine —
semantic when the selector is one of many consumers of that purpose
(e.g. `--color-text-default` used everywhere), component when the
selector owns a specific dimension (e.g. `--c-card-pad`). The forbidden
case is selectors reaching down to primitives like `--space-6` or
`--gray-100`.

Violation: `.card { padding: var(--space-6); }` — selector reaches past
the component layer to a primitive. Fix: define `--c-card-pad` in
`components.css` and reference that.

## Brand vs interactive: the philosophy

The system distinguishes brand-coloured things from interactive-coloured
things at the **semantic layer**. Today `--color-brand` and
`--color-interactive-primary` resolve to the same teal. They might
diverge in the future. Every place that uses an "accent" colour must
declare which it is.

Rules:

- **Buttons are interactive** — regardless of how decorative they look.
  Primary buttons, outline buttons, "add new" CTAs: all interactive.
- **Hover, focus, and active states** of clickable things are interactive.
  Focus rings, hover colour shifts, active-tab indicators, open-state
  outlines.
- **Decorative emphasis on non-interactive content** is brand. Blockquote
  bars, `em`/`strong` in post bodies, sq-mark backgrounds, section-head
  bars.
- **Status indicators** (badges, required-field markers, published pills,
  status dots) are brand or `--color-status-*`, never interactive.
- **Typographic accents** (`em`, `a`, `blockquote`, `sup` in post bodies)
  are brand.
- **Active state of nav-like clickable elements** (`toc__link.active`,
  `rail-item.active`, `theme-toggle button.active`, `tabs button.active`)
  is interactive — these are "you are here" markers on clickable
  structures.

## Worked examples

Real classifications from the `--accent` migration (Commit 12):

**`.post-pinned-block` border** (`styles.css:622`) → **BRAND**
Question: is the border a click affordance or decorative emphasis?
It frames featured content. The block is not focusable. Decorative → brand.

**`.btn-outline` resting + hover** (`styles.css:867–873`) → **INTERACTIVE**
Question: is it a button? Yes. Buttons are always interactive, even at
rest. Both border and text colour are interactive-primary.

**`.post-body em`** (`styles.css:514`) → **BRAND**
Question: is the emphasis on something clickable? No — it's typographic
emphasis in body text. Decorative emphasis → brand.

**`.theme-toggle button.active`** (`styles.css:96`) → **INTERACTIVE**
Question: active state of a clickable element? Yes — the active pill
shows which theme you're on, but it's still a click target. Same
category as the click affordance itself.

**`.adm .field label .req`** (`admin.css:27`) → **BRAND**
Question: is the asterisk a click affordance? No — it's a status marker
indicating a required field. Status indicator → brand.

## Naming conventions

- Primitives: `--teal-500`, `--space-6`, `--radius-sm`, `--text-base`
- Semantic: `--color-surface-page`, `--color-text-default`,
  `--color-brand`, `--color-interactive-primary`, `--color-status-warm`,
  `--color-status-cool`, `--border-rule`
- Component (public): `--c-card-pad`, `--c-nav-height`
- Component (admin): `--c-adm-rail-w`, `--c-adm-pin-input-h`

Full naming rules and the "when to add a token" decision tree:
`/website-personal/web/tokens/TOKENS.md`.

## Component architecture

Four roles: **atom** (reusable primitive), **section** (content area),
**chrome** (persistent UI), **layout** (wrapper). Dependency flows upward:
atoms are imported by sections and chrome, never the reverse.

Full inventory and the "when to create a component" decision tree:
`/website-personal/lib/components/COMPONENTS.md`.

## Known limitations / tracked debt

- **Color-on-accent semantic mismatch (7 sites):** `--color-surface-page`
  is used as text colour on accent backgrounds instead of the correct
  `--color-interactive-primary-text`. Same primitive value today, so not a
  visual bug, but will silently break if the two tokens diverge.
  `--color-interactive-primary-text` is annotated `@future` in
  `semantic.css` so the orphan checker skips it until the migration lands.
- **Responsive type clamps (10 values, 5 sites):** `clamp(min, vw, max)`
  endpoints in hero/card type don't fit the static `--text-*` scale.
  Decision deferred until fluid typography is needed elsewhere.
- **`@media` breakpoint values (6 sites):** CSS custom properties cannot
  be used inside `@media` queries — language limitation, not a system gap.
  Tokenising would require a build-time preprocessor.
- **Styleguide hardcoded hex values:** `/admin/styleguide` renders some
  token values as hardcoded hex for display swatches. These will silently
  drift if primitives change. See comment at top of `styleguide.dart`.

Full lists with line numbers in `website-personal/TODO_TOKENS.md`.

## Phase 3 migration status

The alias migration is complete: every legacy `--accent`, `--ink*`,
`--bg*`, `--rule`, `--shadow`, `--border-*-val` reference has been
renamed to a canonical semantic token, and the deprecated-alias block in
`semantic.css` has been deleted (commit `d4de428`). The
`audit_deprecated_aliases.dart` checker enforces that no aliases
reappear.

## The audit suite

Seven checkers under `website-personal/tool/`, orchestrated by
`audit_all.dart`. The aggregator runs at dev-server boot via `tool/dev.dart`
(fast mode, non-blocking).

**Fast checkers (boot-safe, must stay green):**

- `audit_css_tokens.dart` — every `var(--*)` reference resolves to a
  defined token.
- `audit_deprecated_aliases.dart` — no legacy aliases (`--accent`,
  `--ink`, `--bg`, etc.) reappear.
- `audit_theme_parity.dart` — every semantic token defined in `:root`
  has a matching `[data-theme="light"]` override (or is an intentional
  inheritance).
- `audit_component_inventory.dart` — every component listed in
  `COMPONENTS.md` exists in `lib/components/`.

**Full checkers (`--full` flag, run on demand):**

- `audit_orphan_tokens.dart` — flags tokens defined but never
  referenced. Skips tokens annotated `@future`.
- `audit_css_classes.dart` — every CSS class used in Dart components
  resolves to a defined selector.
- `audit_hardcoded_values.dart` — flags raw `px`/hex values in CSS that
  should be tokenised. Allowlists `0px`, `1px`, and inline-annotated
  literals (FX, single-use layout, breakpoints).

Run all: `dart run tool/audit_all.dart` (fast) or
`dart run tool/audit_all.dart --full`.
