# Blog Pinned Sections & Reading Experience — Design Spec

**Date:** 2026-05-06
**Branch:** test-skill
**Status:** Approved — awaiting spec review

---

## Overview

Enhance the blog post reading experience with four improvements: redesigned pinned sections block, article takeaways box, dimmed in-place pinned repeats, and improved typography/styling for citations, bold, and links.

---

## 1. Pinned sections block — visual redesign

**Current state:** Pinned sections render inside `.post-pinned-block` with a left teal rail, outline pill badge "PINNED", and full body text visible.

**New design:**

- **Teal border on all four sides** (2px solid `--accent`) with light accent background tint (`rgba(accent, 0.05)`)
- **Header row:** Filled teal pill badge "★ مثبتة" + "توسيع الكل · Expand all" link on the opposite side
- **Each pinned section is title-only by default** — one row containing:
  - Section title (left/right per RTL)
  - Date + ▼ arrow (opposite side, same row)
- **Click ▼ expands** the full section body inline (body slides open below the title row). Arrow changes to ▲. Click again to collapse.
- **"Expand all"** in the header expands every pinned section at once; text toggles to "توسيع أقل · Collapse all"
- **Expanded body** renders full markdown content (paragraphs, bold, links, citations) with justified text, same typography as article body
- Sections separated by subtle teal divider (`rgba(accent, 0.12)`)

**Interaction:** Client-side toggle. Since the site is SSG (static), use a small `<script>` to toggle visibility. No server round-trip.

---

## 2. Takeaways box

**New data field:** `takeaways` array in `post.json`:

```json
{
  "takeaways": [
    "التسويف مش كسل — هو فشل في تنظيم المشاعر",
    "المجتمع يحوّل التسويف إلى عيب أخلاقي...",
    "القسوة على النفس تزيد المشكلة...",
    "الحلول العملية تبدأ من فهم السبب العاطفي..."
  ]
}
```

**Rendering:**

- Positioned **immediately after the pinned block**, before regular article sections
- Container: 1px teal border (`rgba(accent, 0.35)`), gradient background, rounded corners
- Header: "● خلاصة المقال · KEY TAKEAWAYS" in accent color
- Each takeaway as a bullet point with teal `●` dot
- `**bold**` within takeaways renders in accent color
- Links render in accent color with underline
- **If `takeaways` array is empty or missing**, the box does not render at all

**Admin panel:** Add a takeaways editor in `/admin/blog` — simple textarea (one line per takeaway) or repeating text fields.

---

## 3. Dimmed in-place repeats

**Current state:** Pinned sections only appear in the top pinned block. Their natural position in the article is skipped.

**New behavior:** Pinned sections appear **twice**:

1. **Full pinned block** at top (as designed above)
2. **Dimmed ghost** at their natural position in the article flow

**Dimmed repeat styling:**

- Dashed teal border (`rgba(accent, 0.2)`)
- Very faint accent background (`rgba(accent, 0.02)`)
- **50% opacity** overall
- One row: ★ pin icon + section title on one side, date on the other
- No body text — title only
- Small note above: "★ مثبتة · هذا القسم مثبت في الأعلى" (first occurrence only, or per-section — TBD, start with per-section for clarity)

---

## 4. Typography & styling improvements

### Justified text

- `text-align: justify` on `.post-section__body`, `.post-preamble`, and expanded pinned section bodies
- `hyphens: auto` for better line breaks

### Bold in accent color

- `strong` and `b` elements inside `.post-section__body` render in `--accent` color with `font-weight: 600`
- Applied everywhere: article body, expanded pinned sections, takeaways box

### Links in accent color

- `a` tags inside `.post-section__body` render in `--accent` with thin underline
- `text-decoration-thickness: 1px`, `text-underline-offset: 3px`

### Citations

- Superscript reference markers (`[1]`, `[2]`) rendered via `<sup>` in accent color
- These come from markdown content — author writes `[^1]` or `<sup>[1]</sup>` in the markdown
- Footnotes section at end of article is just part of the markdown body, styled with existing blockquote/hr rules
- No special footnote infrastructure needed at this stage — author writes them as part of the markdown

---

## Files to modify

| File | Change |
|---|---|
| `website-jaspr/lib/pages/blog_post.dart` | `_renderBody`: add takeaways rendering, dimmed in-place repeats, client-side expand/collapse script |
| `website-jaspr/web/styles.css` | Redesign `.post-pinned-block`, `.post-section--pinned`, add `.post-takeaways`, `.dimmed-repeat`, update `strong`/`a`/`sup` styles, add `text-align: justify` |
| `website-jaspr/lib/data/blog_data.dart` | Parse `takeaways` field from `post.json` |
| `website-jaspr/tool/save_server.dart` | Handle `takeaways` array in POST /api/blog |
| `website-jaspr/lib/pages/admin/blog.dart` | Add takeaways editor UI |

---

## Out of scope

- Full footnote system with auto-numbering (author writes manually in markdown)
- Separate takeaways admin page (inline in existing blog editor)
- Light theme specific tweaks (CSS custom properties handle both themes already)
- Changes to homepage blog listing cards
