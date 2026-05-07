# Square Motif Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bold square motif as a recurring visual identity across the entire site — nav monogram, square marks on headings, accent bars on cards, square-cornered tags, and hero frames.

**Architecture:** Pure CSS layer + minimal Dart markup changes. Five visual elements (square monogram, square marks, accent bars, square tags, hero frames) applied as CSS classes to existing components. No data, layout, or routing changes.

**Tech Stack:** CSS (`web/styles.css`), Jaspr Dart components, `context/identity.md` documentation.

---

## Task 1: CSS Foundation — square classes + tag radius

**Files:**
- Modify: `website-jaspr/web/styles.css`

This task adds all new CSS classes and updates the tag/pill border-radius. Every subsequent task depends on these styles.

- [ ] **Step 1: Add square motif utility classes after the existing theme variables section**

Add these new classes after the `body::before` rule block (around line 44) but before the `/* NAV */` section:

```css
/* ── Square motif ── */
.sq-mark {
  display: inline-block;
  width: 10px; height: 10px;
  background: var(--accent);
  flex-shrink: 0;
}
.sq-mark--sm {
  display: inline-block;
  width: 6px; height: 6px;
  background: var(--accent);
  flex-shrink: 0;
}
.sq-frame {
  border: 2px solid var(--accent);
  background: color-mix(in srgb, var(--accent) 4%, var(--bg));
}
.sq-bar {
  position: relative;
}
.sq-bar::before {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 3px;
  height: 100%;
  background: var(--accent);
}
.nav__monogram-square {
  width: 24px; height: 24px;
  background: var(--accent);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--bg);
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
  font-weight: 700;
  line-height: 1;
  flex-shrink: 0;
}
```

- [ ] **Step 2: Update `.pill` border-radius from rounded to square**

In the `.pill` rule, change `border-radius: 100px` to `border-radius: 2px`:

```css
.pill {
  font-family: 'JetBrains Mono', monospace; font-size: 10px;
  text-transform: uppercase; letter-spacing: 0.14em;
  padding: 5px 11px; border-radius: 2px; border: 1px solid;
}
```

- [ ] **Step 3: Update `.tag-pill` border-radius from rounded to square**

In the `.tag-pill` rule, change `border-radius: 100px` to `border-radius: 2px`:

```css
.tag-pill {
  /* ... existing props ... */
  border-radius: 2px;
  /* ... */
}
```

- [ ] **Step 4: Add square accent bar to `.card::before` (change from top bar to right bar)**

Replace the existing `.card::before` rule. Currently it's a 2px top bar that appears on hover. Change it to a 3px right bar (matching `.sq-bar`) that's always visible:

```css
.card::before {
  content: ''; position: absolute; top: 0; right: 0; bottom: 0;
  width: 3px; background: var(--card-accent, var(--accent));
  opacity: 0.5; transition: opacity 0.25s;
}
```

And remove the `.card:hover::before` rule (or simplify it to `opacity: 1`).

- [ ] **Step 5: Add square accent bar to `.writing__item`**

Add a `::before` pseudo-element to `.writing__item` for the right-side accent bar:

```css
.writing__item {
  /* ... existing props ... */
  position: relative;
}
.writing__item::before {
  content: '';
  position: absolute;
  top: 0; right: 0; bottom: 0;
  width: 3px;
  background: var(--accent);
  opacity: 0;
  transition: opacity 0.2s;
}
.writing__item:hover::before {
  opacity: 1;
}
```

- [ ] **Step 6: Add square accent bar to `.post-body blockquote`**

The blockquote currently has `border-inline-start: 3px solid var(--accent)`. Change it to use the square bar style instead — replace the border with a `::before` positioned bar, or simply keep the existing border but ensure it feels like the square motif (it already is a 3px accent bar on the side, which matches). **Keep the existing blockquote style as-is** — it already matches the square accent bar vocabulary.

- [ ] **Step 7: Verify CSS compiles by restarting dev server**

Run:
```bash
powershell.exe -NoProfile -Command "Get-Process dart -ErrorAction SilentlyContinue | Stop-Process -Force"
cd C:/CLI/small-projects/my-cv/website-jaspr && dart run tool/dev.dart
```

Wait for `[jaspr] [SERVER] Serving at http://localhost:8080`. Open the site and verify no visual breakage yet (classes exist but aren't used in markup yet).

- [ ] **Step 8: Commit**

```bash
git add website-jaspr/web/styles.css
git commit -m "feat: add square motif CSS classes and update tag/pill radius"
```

---

## Task 2: Nav — square monogram

**Files:**
- Modify: `website-jaspr/lib/components/nav.dart`

- [ ] **Step 1: Add square monogram element to the nav**

In `nav.dart`, add a `span` with class `nav__monogram-square` inside the monogram link, after the text:

Current:
```dart
a(href: '/', classes: 'nav__monogram', [
  text(first),
  if (rest.isNotEmpty) span([text(rest)]),
]),
```

Change to:
```dart
a(href: '/', classes: 'nav__monogram', [
  text(first),
  if (rest.isNotEmpty) span([text(rest)]),
  span(classes: 'nav__monogram-square', [text('س')]),
]),
```

- [ ] **Step 2: Verify in browser**

Open `http://localhost:8080` — the teal square with "س" should appear at the right side of the nav bar (RTL), next to "salem.malibary".

- [ ] **Step 3: Commit**

```bash
git add website-jaspr/lib/components/nav.dart
git commit -m "feat: add square monogram to nav bar"
```

---

## Task 3: Home page hero — square frame

**Files:**
- Modify: `website-jaspr/lib/components/hero.dart`

- [ ] **Step 1: Wrap the hero left column in a square frame**

In `hero.dart`, wrap the `hero__left` div with a `sq-frame` class. Change:

```dart
div(classes: 'hero__left', [
```

To:

```dart
div(classes: 'hero__left sq-frame', [
```

Also add a `sq-mark` before the status line, and before each meta item label.

Inside the status-line div, add a square mark before the status-dot:
```dart
if (site.statusLine.isNotEmpty)
  div(classes: 'status-line', [
    span(classes: 'sq-mark--sm', []),
    span(classes: 'status-dot', []),
    span([text(site.statusLine)]),
  ]),
```

- [ ] **Step 2: Verify in browser**

Open `http://localhost:8080` — the hero section should have a teal border frame. The status line should have a small square mark before the dot.

- [ ] **Step 3: Commit**

```bash
git add website-jaspr/lib/components/hero.dart
git commit -m "feat: add square frame to home page hero"
```

---

## Task 4: Blog post — square marks + frame + bars

**Files:**
- Modify: `website-jaspr/lib/pages/blog_post.dart`

This is the largest task. Apply all five square elements to the blog post page.

- [ ] **Step 1: Add `sq-frame` to the post head section**

Change:
```dart
header(classes: 'post-head', [
```
To:
```dart
header(classes: 'post-head sq-frame', [
```

- [ ] **Step 2: Add `sq-mark` before the post meta line**

Change:
```dart
div(classes: 'post-meta', [
```
To:
```dart
div(classes: 'post-meta', [
  span(classes: 'sq-mark--sm', []),
```

This adds a small teal square before the date/category/language line.

- [ ] **Step 3: Add `sq-mark` before the TOC title in sidebar**

Change:
```dart
div(classes: 'toc__title', [text('المحتويات · Contents')]),
```
To:
```dart
div(classes: 'toc__title', [
  span(classes: 'sq-mark--sm', []),
  text(' المحتويات · Contents'),
]),
```

- [ ] **Step 4: Add `sq-bar` to the newsletter card**

Change:
```dart
div(classes: 'newsletter', attributes: {'data-newsletter-card': ''}, [
```
To:
```dart
div(classes: 'newsletter sq-bar', attributes: {'data-newsletter-card': ''}, [
```

- [ ] **Step 5: Add `sq-mark` before pinned section titles and takeaway badge**

In `_renderPinnedRow`, change:
```dart
span(classes: 'post-pinned-section__title', [text(chunk.title)]),
```
To:
```dart
span(classes: 'post-pinned-section__title', [
  span(classes: 'sq-mark--sm', []),
  text(chunk.title),
]),
```

In the pinned badge:
```dart
span(classes: 'pinned-badge', [text('★ مثبتة')]),
```
To:
```dart
span(classes: 'pinned-badge', [
  span(classes: 'sq-mark--sm', []),
  text(' مثبتة'),
]),
```

In the takeaway badge:
```dart
span(classes: 'post-takeaways__badge', [text('● خلاصة المقال · KEY TAKEAWAYS')]),
```
To:
```dart
span(classes: 'post-takeaways__badge', [
  span(classes: 'sq-mark', []),
  text(' خلاصة المقال · KEY TAKEAWAYS'),
]),
```

- [ ] **Step 6: Add `sq-mark` before section headings in `_renderSection`**

Change:
```dart
h2(classes: 'post-section__title', [text(chunk.title)]),
```
To:
```dart
h2(classes: 'post-section__title', [
  span(classes: 'sq-mark', []),
  text(chunk.title),
]),
```

- [ ] **Step 7: Verify in browser**

Open `http://localhost:8080/blog/formatting-test` and `http://localhost:8080/blog/procrastination-not-laziness`:
- Post head should have teal frame border
- Meta line should have small square mark before date
- Each H2 heading in the body should have a square mark before the title
- TOC title should have small square mark
- Newsletter card should have accent bar on right edge
- Tags should have square corners (not rounded)

- [ ] **Step 8: Commit**

```bash
git add website-jaspr/lib/pages/blog_post.dart
git commit -m "feat: apply square motif to blog post page"
```

---

## Task 5: Writing list — square accent bar

**Files:**
- Modify: `website-jaspr/lib/components/writing_list.dart`

- [ ] **Step 1: Add `sq-bar` class to writing items**

Change:
```dart
a(href: p.href, classes: 'writing__item', [
```
To:
```dart
a(href: p.href, classes: 'writing__item sq-bar', [
```

- [ ] **Step 2: Verify in browser**

Open `http://localhost:8080/writing` — each post row should have a teal accent bar on the right edge that appears on hover.

- [ ] **Step 3: Commit**

```bash
git add website-jaspr/lib/components/writing_list.dart
git commit -m "feat: add square accent bar to writing list items"
```

---

## Task 6: Research grid — square accent bar

**Files:**
- Modify: `website-jaspr/lib/components/research_grid.dart`

- [ ] **Step 1: No Dart change needed — CSS `.card::before` already adds the bar**

The research cards use the `.card` class, and Task 1 updated `.card::before` to render as a 3px right-side bar. Verify this works:

- [ ] **Step 2: Verify in browser**

Open `http://localhost:8080` (home page) — the research paper cards should show a teal accent bar on the right edge.

- [ ] **Step 3: Commit (if any changes were needed)**

Only commit if adjustments were required.

---

## Task 7: Context update — identity.md

**Files:**
- Modify: `context/identity.md`

- [ ] **Step 1: Update the Visual Identity section**

In `context/identity.md`, append to the "Visual Identity" section:

After the existing `**Design feel:** Premium, clean, Apple-level simplicity` line, add:

```markdown
- **Signature motif:** Square — recurring geometric shape used as marks,
  accent bars, hero frames, and tag corners throughout the site.
  Represents structural thinking, blueprint precision, and the built
  environment DNA. Applied boldly and consistently across all pages.
  See `docs/superpowers/specs/2026-05-07-square-motif-design.md` for the
  full vocabulary.
```

- [ ] **Step 2: Commit**

```bash
git add context/identity.md
git commit -m "docs: document square motif in brand identity"
```

---

## Task 8: Visual QA — browser-based verification

**Files:**
- None (verification only)

- [ ] **Step 1: Kill orphaned processes and restart dev server**

```bash
powershell.exe -NoProfile -Command "Get-Process dart -ErrorAction SilentlyContinue | Stop-Process -Force"
cd C:/CLI/small-projects/my-cv/website-jaspr && dart run tool/dev.dart
```

- [ ] **Step 2: Screenshot all key pages**

Use `agent-browser` to screenshot each page:
- `http://localhost:8080` (home — hero frame, card bars, nav monogram)
- `http://localhost:8080/writing` (writing list — item bars)
- `http://localhost:8080/blog/formatting-test` (blog post — all elements)
- `http://localhost:8080/blog/procrastination-not-laziness` (blog post with hero image)

Verify in each screenshot:
- [ ] Square monogram "س" appears in nav
- [ ] Hero has teal frame border
- [ ] Cards have accent bar on right edge
- [ ] H2 headings have square mark before text
- [ ] Tags have square corners (not rounded)
- [ ] No visual breakage or overlap
- [ ] Both dark and light themes look correct

- [ ] **Step 3: Fix any issues found, commit fixes**

- [ ] **Step 4: Delete any debug screenshots from inbox**

```bash
rm -f C:/CLI/small-projects/my-cv/inbox/mockup-*.png
```

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "fix: square motif visual QA fixes"
```
