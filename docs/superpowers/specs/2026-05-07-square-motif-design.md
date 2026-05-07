# Square Motif — Visual Identity Design

**Date:** 2026-05-07
**Status:** Approved for implementation
**Scope:** Whole-site visual identity layer

---

## Problem

The site is clean and well-structured but lacks a recurring visual element
that makes it feel designed rather than templated. Every distinctive site has
a "visual thread" — a shape, pattern, or motif that repeats across pages and
creates subconscious recognition.

## Decision

Adopt a **square motif** as the site's signature visual element. The square
fits the brand DNA: architect's blueprint grid, research-lab precision,
structural thinking about the built environment.

Intensity level: **bold everywhere** — the same square vocabulary applies
consistently across all pages, including inside long-form reading. The
identity doesn't dial back in articles.

## The Square Vocabulary

Five elements that recur across every page:

### 1. Square monogram

A teal filled square (24×24px) containing the Arabic letter "س" in the
monogram font, placed in the nav bar next to "salem.malibary".

- Dark theme: `background: var(--accent)` (`#4dd4ac`), text in `var(--bg)`
- Light theme: `background: var(--accent)` (`#006d5e`), text in `var(--bg)`
- Font: `'JetBrains Mono'`, bold, 12px
- CSS class: `.nav__monogram-square`

### 2. Square mark

A small teal filled square placed before section headings, meta lines
(date/category), and the TOC title in the sidebar.

- Size: 10px for section headings and meta lines, 6px for inline use
  (list bullets, sub-items)
- Always `background: var(--accent)`, no border
- Usage:
  - Before H2 headings in blog post body
  - Before post meta line (date · category · language)
  - Before TOC title in sidebar
  - Before pinned section titles
  - Before takeaway badge
- CSS class: `.sq-mark` (10px), `.sq-mark--sm` (6px)

### 3. Square accent bar

A 3px-wide teal bar running the full height of an element, positioned at
the right edge (RTL) or left edge (LTR) using `position: absolute`.

- Applied to:
  - Blog post cards on the writing page
  - Research paper cards on the research grid
  - Blockquotes inside articles
  - Pinned section blocks
  - Newsletter card in sidebar
- Implementation: `::before` pseudo-element with `width: 3px`,
  `height: 100%`, `background: var(--accent)`, positioned at the
  appropriate edge
- CSS class: `.sq-bar` (adds the pseudo-element)

### 4. Square-cornered tags

All tag pills, category chips, and sidebar tags switch from rounded
(`border-radius: 100px`) to sharp corners (`border-radius: 2px`).

- Same colour treatment as current (accent-coloured border and text),
  only the radius changes
- Applies to: `.tag-pill`, `.pill`, `.sidebar-tags .tag-pill`
- CSS: override `border-radius` from `100px` to `2px`

### 5. Square hero frame

A 2px solid teal border wrapping the hero section (title + meta area) on
blog posts and the home page hero.

- `border: 2px solid var(--accent)`
- `background: color-mix(in srgb, var(--accent) 4%, var(--bg))`
- Applied to: blog post `.post-head` section, home page hero block
- CSS class: `.sq-frame`

---

## Theme Behaviour

Both dark and light themes use the same five elements identically. The only
difference is the accent colour, which already switches via `--accent`
(`#4dd4ac` dark, `#006d5e` light). No additional theme-specific styles needed.

## Files Changed

| File | Change |
|---|---|
| `web/styles.css` | Add `.sq-mark`, `.sq-mark--sm`, `.sq-bar`, `.sq-frame`, `.nav__monogram-square` classes. Update `border-radius` on `.tag-pill` and `.pill` from `100px` to `2px`. Add `.sq-bar` pseudo-element. |
| `lib/components/nav.dart` | Add `.nav__monogram-square` element inside the monogram link |
| `lib/components/hero.dart` | Wrap hero content in `.sq-frame` div |
| `lib/pages/blog_post.dart` | Add `.sq-mark` before H2 headings, post meta line, TOC title, pinned titles, takeaway badge. Add `.sq-bar` to blockquotes and pinned sections. Add `.sq-frame` to `.post-head`. |
| `lib/components/writing_list.dart` | Add `.sq-bar` to post cards |
| `lib/components/research_grid.dart` | Add `.sq-bar` to research cards |
| `context/identity.md` | Update "Visual Identity" section to document the square motif |

## What Stays the Same

- Colour palette — no changes to any colour variables
- Typography — no font or size changes
- Layout structure — no grid, spacing, or max-width changes
- Card `border-radius` — cards keep their 12px radius; the square motif is
  marks, bars, and frames, not removing all roundness
- Content data flow — no yaml or data changes
- Routes, SEO, sitemap — no changes

## Context Updates

Update `context/identity.md` "Visual Identity" section to add:

```
- **Signature motif:** Square — recurring geometric shape used as marks,
  accent bars, hero frames, and tag corners throughout the site.
  Represents structural thinking, blueprint precision, and the built
  environment DNA. Applied boldly and consistently across all pages.
```
