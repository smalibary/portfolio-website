# Salem Malibary Design System — Spec

**Date:** 2026-05-07
**Status:** Approved for implementation
**Scope:** Whole-site design tokens + `/admin/styleguide` reference page

---

## Problem

The site's CSS has ~900 lines of hardcoded values. Changing "all corners"
means hunting through every component. The recent square motif implementation
exposed the lack of a systematic approach — individual radius, spacing, and
border values were changed one by one, creating inconsistencies.

## Decision

Build a design token system (CSS custom properties) that every component
references, plus a live `/admin/styleguide` page that renders every token
and component for visual verification.

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
--space-4: 16px;     /* medium: between sections, card padding alternatives */
--space-5: 20px;     /* large section gaps */
--space-6: 24px;     /* large: section separation, card padding */
--space-8: 32px;     /* xl: page section top/bottom, post-head margin */
--space-12: 48px;    /* 2xl: page edge padding (nav, hero), major spacing */
--space-16: 64px;    /* 3xl: page bottom margin */
```

Note: CSS variable names cannot use dots, so `2.5` becomes `2-5`.

### Typography scale

Existing font sizes mapped to tokens:

```css
--text-xs: 10px;     /* pills, badges, meta labels, monogram */
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
--border-rule: 1px solid var(--rule);           /* standard divider */
--border-accent: 2px solid var(--accent);        /* sq-frame */
--border-accent-bar: 3px solid var(--accent);    /* sq-bar, blockquote side */
```

### Existing tokens (keep as-is)

Colours (`--bg`, `--ink`, `--accent`, etc.) and shadows (`--shadow`) are
already tokenised. No changes needed.

## Component Token Map

Every component references tokens, never hardcoded values.

| Component | radius | key spacing | border |
|---|---|---|---|
| Nav | — | `px: var(--space-12)` h: 64px | `border-bottom: var(--border-rule)` |
| Nav monogram square | — | 24×24px | bg: accent |
| Theme toggle outer | `var(--radius-sharp)` | `p: var(--space-0-5)` | `var(--border-rule)` |
| Theme toggle button | `var(--radius-sharp)` | `px: 10px py: 5px` | — (active bg: accent) |
| Card | `var(--radius-sm)` | `p: var(--space-6)` | `var(--border-rule)` |
| Pill | `var(--radius-sharp)` | `p: 5px 11px` | `border: 1px solid (colour)` |
| Tag pill | `var(--radius-sharp)` | `p: 3px 8px` | `border: 1px solid (colour)` |
| Button | `var(--radius-sm)` | `p: 5px 12px` | `var(--border-rule)` |
| Input | `var(--radius-sharp)` | `p: 8px 12px` | `var(--border-rule)` |
| Blockquote | — | `p: 4px 18px` | `border-inline-start: var(--border-accent-bar)` |
| Hero image | `var(--radius-sm)` | — | — |
| Portrait | `var(--radius-sm)` | — | — |
| Newsletter card | `var(--radius-sm)` | `p: 10px 12px` | `var(--border-rule)` + sq-bar |
| Writing list item | — | `py: 22px` | `border-bottom: var(--border-rule)` |
| Modal/dialog | `var(--radius-md)` | `p: var(--space-4)` | `var(--border-rule)` |
| sq-mark | — | 10×10px | bg: accent |
| sq-mark--sm | — | 6×6px | bg: accent |
| sq-frame | — | — | `var(--border-accent)` |
| sq-bar | — | — | `var(--border-accent-bar)` on right |

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
| `web/styles.css` | Add all design tokens to `:root`. Replace hardcoded values with `var(--token)` throughout. |
| `lib/pages/admin/styleguide.dart` | New file — the styleguide page |
| `lib/app.dart` | Register `/admin/styleguide` route |
| `context/identity.md` | Add design system reference |

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
