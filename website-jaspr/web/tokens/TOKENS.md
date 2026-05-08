# Token Architecture

This file is loaded as instructions when working in `web/tokens/`.
It codifies the token architecture from `/DESIGN.md` as a procedure
to follow.

## The 3 layers

- **primitives.css** — raw values (colours, spacing, radii, typography).
  No theme awareness. Never referenced by component selectors directly.
- **semantic.css** — purpose-named, theme-aware tokens. The layer
  component selectors consume. `--color-surface-page`, `--color-text-default`,
  `--color-brand`, `--border-rule`.
- **components.css** — component-scoped tokens composed from primitives
  + semantic. `--c-card-pad`, `--c-adm-rail-w`.

## The dependency rule

components.css → references primitives + semantic.
semantic.css → references primitives.
primitives.css → references nothing.

Never skip layers. Never reference a primitive from a component selector.

## Decision tree: before adding a new token

Work through these **in order**. Stop at the first "yes."

1. **Does an existing semantic or component token already express this
   purpose?** → USE IT. Stop.
2. **Does an existing primitive cover this value (or within 1–2px)?**
   - **Exact match** → Reference it directly. Stop.
   - **Within 1–2px, imperceptible at this size** (body text, small UI) →
     Consolidate to the existing primitive. Stop.
   - **Within 1–2px, perceptible** (h1, hero copy, large badges) →
     Skip to step 3 or 4.
3. **Is this value used in 2+ unrelated components?** → Add a primitive
   token in `primitives.css`. Stop.
4. **Is this value scoped to one component?**
   - **Follows an existing scale pattern** (e.g. `--space-4-5: 18px`
     fits the half-step naming) → Add a primitive token. Stop.
   - **True one-off** (used in one place, no scale fit) → Add a
     component token in `components.css` (`--c-*` or `--c-adm-*`).
   - **No meaningful name beyond the literal** (like `5px` for one
     toggle's pad-y) → Keep as inline literal with
     `/* intentionally literal: <reason> */` comment.
   Rule of thumb: if you can't name it, it isn't ready to be a token.
5. **Is this a new purpose-based concept** (a new semantic distinction,
   like brand vs interactive)? → Add a semantic token in `semantic.css`.
   Confirm no existing semantic covers it first.

Default: **PREFER REUSING.** New tokens are added only when questions
1–4 are genuinely "no."

## Naming conventions

- All tokens kebab-case.
- Primitives: `--black`, `--gray-500`, `--teal-500`, `--space-4`,
  `--radius-sm`, `--text-base`, `--width-content`.
- Semantic: `--color-surface-page`, `--color-text-default`,
  `--color-interactive-primary`, `--color-status-warm`, `--shadow-card`,
  `--border-rule`.
- Component (public): `--c-<component>-<property>` (e.g. `--c-card-pad`).
- Component (admin): `--c-adm-<component>-<property>` (e.g. `--c-adm-rail-w`).

## The audit script

`tool/audit_css_tokens.dart` runs at dev-server start (via `tool/dev.dart`)
and fails if any `var(--*)` reference is unresolved. This catches the bug
class where a token is referenced but never defined. Run manually:
`dart run tool/audit_css_tokens.dart`. Do not commit if the script reports
unresolved references.

## Known tracked debt

See `website-jaspr/TODO_TOKENS.md` for 7 sites where `--color-surface-page`
is used as text-on-accent instead of the correct `--color-interactive-primary-text`.
These are not bugs (same primitive value) but a semantic mismatch to fix
when the two tokens diverge.

For the design philosophy and brand-vs-interactive rule, see `/DESIGN.md`.
