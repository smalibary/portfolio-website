# Salem Malibary Design System — Spec

**Date:** 2026-05-07
**Status:** Implemented
**Scope:** Whole-site design tokens + `/admin/styleguide` reference page

---

## Architecture — 3-Layer Token System

```
Layer 1: Scale tokens (primitives)
   Raw pixel values in :root. Never change per theme.
   --space-6: 24px;  --radius-sm: 4px;  --text-base: 14px;
        ↓
Layer 2: Component tokens (semantic)
   Purpose-named tokens composing from scale tokens. Set once in :root.
   --c-card-pad: var(--space-6);  --c-card-radius: var(--radius-sm);
        ↓
Layer 3: Component styles
   CSS rules reference ONLY component tokens, never scale tokens directly.
   .card { padding: var(--c-card-pad); border-radius: var(--c-card-radius); }
```

Theme overrides (dark/light) only change Layer 1 colour values.
Scale tokens (spacing, radius, typography) are identical across themes,
so Layer 2 doesn't need per-theme duplication.

## Design Tokens

### Radius scale (3 steps)

```css
--radius-sharp: 2px;   /* pills, tags, toggles, inputs, badges */
--radius-sm: 4px;      /* cards, buttons, photos, hero images, newsletter */
--radius-md: 8px;      /* modals, dialogs (if ever needed) */
```

### Spacing scale (4px base + half-steps)

```css
--space-0: 0;
--space-0-5: 2px;    /* tight: pill inner padding, badge gaps */
--space-1: 4px;      /* compact: inner component gaps, small margins */
--space-1-5: 6px;    /* small: label gaps, form field gaps */
--space-2: 8px;      /* default: list spacing, sidebar padding */
--space-2-5: 10px;   /* sidebar internal padding, newsletter padding */
--space-3: 12px;     /* comfortable: card internal gaps, nav menu gap */
--space-3-5: 14px;   /* admin input padding, picker padding */
--space-4: 16px;     /* medium: between sections, card padding alternatives */
--space-5: 20px;     /* large section gaps */
--space-5-5: 22px;   /* writing item padding, card head margin */
--space-6: 24px;     /* large: section separation, card padding */
--space-7: 28px;     /* nav gap, section-head margin */
--space-8: 32px;     /* xl: page section top/bottom, post-head margin */
--space-9: 36px;     /* post body h2/h3/hr margins */
--space-12: 48px;    /* 2xl: page edge padding (nav, hero), major spacing */
--space-16: 64px;    /* 3xl: page bottom margin */
```

Note: CSS variable names cannot use dots, so `2.5` becomes `2-5`.

### Typography scale

Existing font sizes mapped to tokens:

```css
--text-xs: 10px;     /* pills, badges, meta labels, monogram */
--text-2xs: 11px;    /* admin labels, meta text, small monospace UI */
--text-sm: 12px;     /* secondary text, inputs, sidebar TOC */
--text-base: 14px;   /* body text, nav items */
--text-md: 16px;     /* card titles, section text */
--text-lg: 18px;     /* writing list primary */
--text-xl: 20px;     /* section headings (h2) */
--text-2xl: 28px;    /* page titles (h1) */
--text-3xl: 34px;    /* hero metric, display */
```

### Border tokens

```css
--border-rule-val: 1px solid var(--rule);           /* standard divider */
--border-accent-val: 2px solid var(--accent);        /* sq-frame */
--border-bar-w: 3px;                                  /* sq-bar, blockquote side width */
```

### Existing tokens (keep as-is)

Colours (`--bg`, `--ink`, `--accent`, etc.) and shadows (`--shadow`) are
already tokenised. No changes needed.

## Component Token Map (Layer 2)

Every public-site component has semantic tokens (`--c-*`) that compose
from scale tokens. Components reference ONLY `--c-*` tokens, never raw
scale tokens directly.

| Component | Token prefix | radius | key spacing | border |
|---|---|---|---|---|
| Nav | `--c-nav-*` | — | `--c-nav-px`, `--c-nav-gap`, `--c-nav-height` | `var(--border-rule-val)` |
| Monogram square | `--c-mono-*` | — | `--c-mono-size` | bg: accent |
| Theme toggle | `--c-toggle-*` | `--c-pill-radius` | `--c-toggle-pad`, `--c-toggle-btn-px/py` | `var(--border-rule-val)` |
| Hero | `--c-hero-*` | — | `--c-hero-gap`, `--c-hero-portrait-max` | `--c-hero-lede-border` |
| Social | `--c-social-*` | — | `--c-social-size`, `--c-social-icon` | — |
| Section head | `--c-section-*` | — | `--c-section-head-mb`, `--c-section-bar-w` | — |
| Card | `--c-card-*` | `--c-card-radius` | `--c-card-pad`, `--c-card-min-h`, `--c-card-head-mb` | `var(--border-rule-val)` |
| Pill | `--c-pill-*` | `--c-pill-radius` | `--c-pill-pad` | `border: 1px solid (colour)` |
| Tag pill | `--c-tag-*` | `--c-tag-radius` | `--c-tag-pad` | `border: 1px solid (colour)` |
| Blockquote | `--c-blockquote-*` | — | `--c-blockquote-pad` | `border-inline-start: var(--border-bar-w)` |
| Writing item | `--c-writing-*` | — | `--c-writing-py`, `--c-writing-col` | `var(--border-rule-val)` |
| Newsletter | `--c-newsletter-*` | `--c-newsletter-radius` | `--c-newsletter-pad` | `var(--border-rule-val)` |
| sq-mark | `--c-sq-mark` | — | width/height: `--c-sq-mark` | bg: accent |
| sq-mark--sm | `--c-sq-mark-sm` | — | width/height: `--c-sq-mark-sm` | bg: accent |
| sq-frame | — | — | — | `var(--border-accent-val)` |
| sq-bar | — | — | — | width: `var(--border-bar-w)` |
| Post layout | `--c-post-*` | — | `--c-post-margin-hr` | — |
| Portrait | `--c-portrait-*` | — | `--c-portrait-bottom` | — |

## Styleguide Page — `/admin/styleguide`

A Jaspr route rendering every token and component for live verification.

### Structure

1. **Token display** — colour swatches, spacing bars at actual size, radius
   examples, typography at each scale level
2. **Components** — every component rendered at actual size, grouped:
   - Navigation (nav bar, monogram, theme toggle)
   - Cards (research card variants)
   - Text (headings, body, blockquote)
   - Forms (input, button, newsletter)
   - Tags & Pills
   - Square motif elements (mark, frame, bar)
3. **Theme toggle** — dark/light switch on the page itself
4. Uses existing admin shell (`admin_shell.dart`)

### Route

Registered in `app.dart` as `/admin/styleguide`. Not deployed to production
(same as all `/admin/*` routes — passcode is cosmetic).

## Files Changed

| File | Change |
|---|---|
| `web/styles.css` | 3-layer tokens in `:root`. Scale + component tokens. Hardcoded values → `var(--token)`. Light theme only overrides colour values. |
| `web/admin.css` | All hardcoded spacing/radius/typography → token references. Added `.card--spaced` and `.flex-1` utility classes. |
| `lib/pages/admin/profile.dart` | Removed `Styles(raw:)` inline styles → CSS class `.card--spaced` |
| `lib/pages/admin/blog.dart` | Removed `Styles(raw:)` inline style → CSS class `.flex-1` |
| `lib/pages/admin/research.dart` | Removed `Styles(raw:)` inline style → CSS class `.flex-1` |

## Component Minimalism Rule

**Don't create new component variants.** The site has a small set of
components (card, pill, tag, button, input, blockquote). Differentiate
them with tokens (radius, spacing, border, accent colour), not new CSS
classes or new Dart components.

Before creating a new component, ask:
1. Can an existing component with different token values do the job?
2. Is the structural difference genuine (different HTML shape) or just
   cosmetic (different size/colour/gap)?
3. If cosmetic → use existing component + adjust tokens.
4. If genuinely new → add it here in the component map first.

**One card. One pill. One tag. One button.** Variants via tokens only.

## What Stays the Same

- Colour values — already tokenised, no changes
- Component structure (Dart markup) — only CSS values change
- Routes, SEO, sitemap — no changes
- Square motif elements — kept, now reference tokens

## Context Updates

Append to `context/identity.md` Visual Identity section:

```
- **Design system:** Token-based (CSS custom properties). 3-step radius
  scale (sharp/sm/md), 4px-base spacing with half-steps, typography scale.
  All components reference tokens — one change ripples everywhere.
  Live reference at `/admin/styleguide`.
```
