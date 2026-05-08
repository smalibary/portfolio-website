# Blog Pinned Sections & Reading Experience — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign pinned sections block, add takeaways box, add dimmed in-place repeats, and improve article typography (justified text, bold/links in accent color, citation styling).

**Architecture:** Modify the existing SSG-rendered blog post page. Expand/collapse is client-side JS injected via `<script>`. New `takeaways` field flows from `post.json` → `BlogPost` model → render. CSS changes are additive (replace old pinned styles, add new takeaways/dimmed styles).

**Tech Stack:** Jaspr (Dart), markdown package, CSS custom properties, vanilla JS for toggle.

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `website-jaspr/lib/data/blog_data.dart` | Modify | Parse `takeaways` from `post.json` into `BlogPost` model |
| `website-jaspr/lib/pages/blog_post.dart` | Modify | Render pinned block (new design), takeaways box, dimmed in-place repeats, inject expand/collapse JS |
| `website-jaspr/web/styles.css` | Modify | Replace pinned block CSS, add takeaways/dimmed styles, update bold/link/sup colors, add justify |
| `website-jaspr/tool/save_server.dart` | Modify | Preserve `takeaways` array through save cycles |
| `website-jaspr/lib/pages/admin/blog.dart` | Modify | Add takeaways textarea in metadata tab |

---

### Task 1: Add `takeaways` field to `BlogPost` model

**Files:**
- Modify: `website-jaspr/lib/data/blog_data.dart`

- [ ] **Step 1: Add `takeaways` field to the `BlogPost` class**

In `blog_data.dart`, add a `takeaways` field after the `sections` field:

In the constructor (after `this.sections = const [],`), add:
```dart
this.takeaways = const [],
```

After the `sections` field declaration, add:
```dart
/// Key takeaway bullet points from `post.json` (`takeaways: [...]`).
/// Rendered in a highlighted box after pinned sections. Empty list means
/// no takeaways box.
final List<String> takeaways;
```

- [ ] **Step 2: Parse `takeaways` from `post.json` in `loadAll()`**

In the `loadAll()` method, inside the `posts.add(BlogPost(...))` call, add after the `sections:` parameter:

```dart
takeaways: ((json['takeaways'] as List?) ?? const []).cast<String>(),
```

- [ ] **Step 3: Commit**

```bash
git add website-jaspr/lib/data/blog_data.dart
git commit -m "feat: add takeaways field to BlogPost model"
```

---

### Task 2: Update CSS — pinned block redesign, takeaways, dimmed repeats, typography

**Files:**
- Modify: `website-jaspr/web/styles.css`

- [ ] **Step 1: Replace the entire pinned block + section CSS block**

Replace everything from the comment `/* LIVE-DOCUMENT SECTIONS (#101)` through the `.post-preamble` rules (lines ~384–460) with the following. This covers: `.post-section`, pinned block redesign, section body typography updates, and preamble rules.

```css
/* LIVE-DOCUMENT SECTIONS (#101)
   Rendered when post.json has a `sections` array. Pinned sections appear
   first inside .post-pinned-block with teal border all sides, title-only
   rows with expand/collapse. Dimmed repeats appear in-place. */
.post-section { margin: 0 0 12px; padding-block: 4px; }
.post-section__title {
  font-size: 26px; font-weight: 600; margin: 36px 0 4px;
  letter-spacing: -.01em; line-height: 1.4;
  scroll-margin-top: 24px;
}
.post-section__meta {
  display: flex; flex-wrap: wrap; gap: 10px; align-items: center;
  font-family: 'JetBrains Mono', monospace; font-size: 11px;
  color: var(--ink-muted); letter-spacing: .06em; text-transform: uppercase;
  margin: 0 0 18px;
}
.section-subtopic {
  display: inline-block;
  padding: 2px 8px;
  border: 1px solid var(--rule);
  border-radius: 4px;
  color: var(--ink);
  text-transform: none;
  letter-spacing: 0;
}
.section-date { color: var(--ink-faint); }

/* ── Pinned block (redesigned) ── */
.post-pinned-block {
  margin: 24px 0 0;
  border: 2px solid var(--accent);
  border-radius: 8px;
  background: color-mix(in srgb, var(--accent) 5%, transparent);
  overflow: hidden;
}
.post-pinned-block__header {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 18px;
  border-bottom: 1px solid color-mix(in srgb, var(--accent) 20%, var(--rule));
}
.pinned-badge {
  background: var(--accent); color: var(--bg);
  padding: 3px 12px; border-radius: 4px;
  font-size: 11px; font-weight: 600; letter-spacing: .08em;
}
.pinned-expand-all {
  margin-inline-start: auto;
  color: var(--accent); font-size: 11px;
  cursor: pointer; opacity: .7;
  background: none; border: none; font-family: inherit;
}
.pinned-expand-all:hover { opacity: 1; text-decoration: underline; }

/* Pinned section row (title + date + arrow) */
.post-pinned-section {
  padding: 12px 18px;
  border-bottom: 1px solid color-mix(in srgb, var(--accent) 12%, transparent);
  cursor: pointer;
}
.post-pinned-section:last-child { border-bottom: none; }
.post-pinned-section:hover {
  background: color-mix(in srgb, var(--accent) 4%, transparent);
}
.post-pinned-section__row {
  display: flex; align-items: baseline; justify-content: space-between; gap: 10px;
}
.post-pinned-section__title {
  font-size: 15px; font-weight: 600; color: var(--ink);
  margin: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.post-pinned-section__meta {
  display: flex; align-items: baseline; gap: 8px; white-space: nowrap; flex-shrink: 0;
}
.post-pinned-section__date {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px; color: var(--ink-faint);
}
.post-pinned-section__arrow {
  color: var(--accent); font-size: 12px;
  transition: transform .15s ease;
}
.post-pinned-section__arrow.open { transform: rotate(180deg); }

/* Expanded pinned section body */
.post-pinned-section__body {
  display: none; /* toggled via JS */
  margin-top: 12px; padding-top: 12px;
  border-top: 1px solid color-mix(in srgb, var(--accent) 10%, transparent);
  font-size: 16px; line-height: 1.85; color: var(--ink);
  text-align: justify; hyphens: auto;
}
.post-pinned-section__body.open { display: block; }
.post-pinned-section__body strong,
.post-pinned-section__body b { color: var(--accent); font-weight: 600; }
.post-pinned-section__body a { color: var(--accent); text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 3px; }
.post-pinned-section__body sup { font-size: 11px; color: var(--accent); font-weight: 500; }
.post-pinned-section__body sup a { text-decoration: none; font-weight: 600; }
.post-pinned-section__body blockquote { border-inline-start: 3px solid var(--accent); padding: 4px 18px; margin: 24px 0; color: var(--ink-muted); }
.post-pinned-section__body p { margin: 0 0 18px; }

/* ── Dimmed in-place repeat of pinned sections ── */
.dimmed-pinned-repeat {
  border: 1px dashed color-mix(in srgb, var(--accent) 20%, var(--rule));
  border-radius: 6px;
  padding: 10px 16px;
  background: color-mix(in srgb, var(--accent) 2%, transparent);
  opacity: .5;
  margin: 20px 0;
  display: flex; align-items: baseline; justify-content: space-between; gap: 10px;
}
.dimmed-pinned-repeat__note {
  display: flex; align-items: center; gap: 6px;
  font-size: 10px; color: var(--accent);
  margin-bottom: 4px;
}
.dimmed-pinned-repeat__note-sep { color: var(--ink-faint); }
.dimmed-pinned-repeat__title {
  font-size: 13px; color: var(--ink-muted); margin: 0; font-weight: 500;
}
.dimmed-pinned-repeat__date {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px; color: var(--ink-faint); white-space: nowrap; flex-shrink: 0;
}

/* ── Takeaways box ── */
.post-takeaways {
  border: 1px solid color-mix(in srgb, var(--accent) 35%, var(--rule));
  border-radius: 8px;
  background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 8%, transparent), color-mix(in srgb, var(--accent) 3%, transparent));
  padding: 20px;
  margin-top: 16px;
}
.post-takeaways__badge {
  display: block;
  color: var(--accent); font-size: 12px; font-weight: 600;
  letter-spacing: .06em; margin-bottom: 14px;
}
.post-takeaways ul {
  list-style: none; padding: 0; margin: 0;
}
.post-takeaways li {
  padding: 8px 0;
  border-bottom: 1px solid color-mix(in srgb, var(--accent) 10%, transparent);
  font-size: 14px; line-height: 1.8; color: var(--ink);
  display: flex; gap: 10px; align-items: flex-start;
  text-align: justify; hyphens: auto;
}
.post-takeaways li:last-child { border-bottom: none; padding-bottom: 0; }
.post-takeaways li::before {
  content: "●"; color: var(--accent); font-size: 8px;
  margin-top: 8px; flex-shrink: 0;
}
.post-takeaways li strong { color: var(--accent); font-weight: 600; }
.post-takeaways li a { color: var(--accent); text-decoration: underline; text-underline-offset: 2px; }

/* Section body typography — bold in accent, justified */
.post-section__body { font-size: 17px; line-height: 1.85; color: var(--ink); text-align: justify; hyphens: auto; }
.post-section__body h3 { font-size: 21px; font-weight: 600; margin: 36px 0 12px; }
.post-section__body p { margin: 0 0 18px; }
.post-section__body strong, .post-section__body b { color: var(--accent); font-weight: 600; }
.post-section__body em { color: var(--accent); font-style: normal; font-weight: 500; }
.post-section__body a { color: var(--accent); text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 3px; }
.post-section__body sup { font-size: 11px; color: var(--accent); font-weight: 500; }
.post-section__body sup a { text-decoration: none; font-weight: 600; }
.post-section__body blockquote { border-inline-start: 3px solid var(--accent); padding: 4px 18px; margin: 24px 0; color: var(--ink-muted); }
.post-section__body code { font-family: 'JetBrains Mono', monospace; font-size: .92em; background: var(--bg-elev); padding: 2px 6px; border-radius: 4px; }
.post-section__body ul, .post-section__body ol { padding-inline-start: 24px; margin: 0 0 18px; }
.post-section__body li { margin: 0 0 8px; }
.post-section__body hr { border: none; border-top: 1px solid var(--rule); margin: 36px 0; }
.post-section__body img { max-width: 100%; border-radius: 8px; margin: 24px 0; }

.post-preamble { font-size: 17px; line-height: 1.85; color: var(--ink); text-align: justify; hyphens: auto; }
.post-preamble p { margin: 0 0 18px; }
.post-preamble hr { border: none; border-top: 1px solid var(--rule); margin: 36px 0; }
```

Key changes from the old CSS:
- Removed `.section-pin-pill`, `.post-section--pinned` (old left-rail design)
- Removed old `.post-pinned-block` and `.post-pinned-block__label`
- Added `.pinned-badge`, `.pinned-expand-all`, `.post-pinned-section` row styles
- Added `.post-pinned-section__body` (hidden by default, `.open` toggles)
- Added `.dimmed-pinned-repeat` styles
- Added `.post-takeaways` box styles
- Changed `.post-section__body strong/b` from `var(--ink)` to `var(--accent)`
- Added `sup` styling for citation markers
- Added `text-align: justify; hyphens: auto` to `.post-section__body`, `.post-preamble`, takeaways

- [ ] **Step 2: Commit**

```bash
git add website-jaspr/web/styles.css
git commit -m "feat: redesign pinned block, add takeaways/dimmed repeat/typography CSS"
```

---

### Task 3: Rewrite `_renderBody` and `_renderSection` in `blog_post.dart`

**Files:**
- Modify: `website-jaspr/lib/pages/blog_post.dart`

- [ ] **Step 1: Replace `_renderBody` function**

Replace the entire `_renderBody` function with:

```dart
/// Renders the post body. If `post.sections` is non-empty, splits the body
/// into preamble + sections and reorders pinned sections to the top
/// (in original document order). Otherwise falls back to the legacy
/// whole-body markdown render.
Component _renderBody({required BlogPost post, required String body}) {
  if (post.sections.isEmpty) {
    final html = md.markdownToHtml(
      body,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [md.InlineHtmlSyntax()],
    );
    return div(classes: 'post-body', [raw(html)]);
  }

  final parsed = parseBody(body);
  final pinnedChunks = <SectionChunk>[];
  final restChunks = <SectionChunk>[];
  final pinnedAnchors = <String>{};
  for (final s in parsed.sections) {
    final meta = post.sectionByAnchor(s.anchor);
    if (meta != null && meta.pinned) {
      pinnedChunks.add(s);
      pinnedAnchors.add(s.anchor);
    } else {
      restChunks.add(s);
    }
  }

  return div(classes: 'post-body', [
    // Preamble (everything before the first H2) renders as one block.
    if (parsed.preamble.isNotEmpty)
      div(classes: 'post-preamble', [
        raw(md.markdownToHtml(
          parsed.preamble,
          extensionSet: md.ExtensionSet.gitHubWeb,
          inlineSyntaxes: [md.InlineHtmlSyntax()],
        )),
      ]),

    // Pinned sections — title-only rows in a teal-bordered block.
    if (pinnedChunks.isNotEmpty)
      div(classes: 'post-pinned-block', [
        div(classes: 'post-pinned-block__header', [
          span(classes: 'pinned-badge', [text('★ مثبتة')]),
          button(
            classes: 'pinned-expand-all',
            attributes: {'type': 'button', 'data-pin-expand-all': ''},
            [text('توسيع الكل · Expand all')],
          ),
        ]),
        for (final chunk in pinnedChunks)
          _renderPinnedRow(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor)),
      ]),

    // Takeaways box — rendered after pinned block, before article body.
    if (post.takeaways.isNotEmpty)
      div(classes: 'post-takeaways', [
        span(classes: 'post-takeaways__badge', [text('● خلاصة المقال · KEY TAKEAWAYS')]),
        ul([
          for (final t in post.takeaways)
            li([raw(md.markdownToHtml(
              t,
              extensionSet: md.ExtensionSet.gitHubWeb,
              inlineSyntaxes: [md.InlineHtmlSyntax()],
            ))]),
        ]),
      ]),

    // All sections in original document order. Pinned sections that were
    // promoted to the top block also appear here as dimmed repeats.
    for (final chunk in parsed.sections)
      if (pinnedAnchors.contains(chunk.anchor))
        _renderDimmedRepeat(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor))
      else
        _renderSection(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor)),

    // Client-side expand/collapse script.
    script(content: _pinToggleScript),
  ]);
}
```

- [ ] **Step 2: Replace `_renderSection` function**

Replace the entire `_renderSection` function with:

```dart
/// Renders one regular (non-pinned) section: heading + meta line + body.
Component _renderSection({
  required SectionChunk chunk,
  required Section? meta,
}) {
  final newlineAt = chunk.markdown.indexOf('\n');
  final bodyAfterHeading = newlineAt < 0 ? '' : chunk.markdown.substring(newlineAt + 1);
  final inner = md.markdownToHtml(
    bodyAfterHeading,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );

  return section(
    classes: 'post-section',
    attributes: {'id': chunk.anchor},
    [
      h2(classes: 'post-section__title', [text(chunk.title)]),
      if (meta != null && (meta.lastModified.isNotEmpty || meta.subtopic.isNotEmpty))
        div(classes: 'post-section__meta', [
          if (meta.subtopic.isNotEmpty)
            span(classes: 'section-subtopic', [text(meta.subtopic)]),
          if (meta.lastModified.isNotEmpty)
            span(classes: 'section-date', [text('updated ${meta.lastModified}')]),
        ]),
      div(classes: 'post-section__body', [raw(inner)]),
    ],
  );
}
```

- [ ] **Step 3: Add `_renderPinnedRow` function**

Add this new function after `_renderSection`:

```dart
/// Renders one pinned section as a title-only row with date + expand arrow.
/// The full body is rendered but hidden; toggled by client-side JS.
Component _renderPinnedRow({
  required SectionChunk chunk,
  required Section? meta,
}) {
  final newlineAt = chunk.markdown.indexOf('\n');
  final bodyAfterHeading = newlineAt < 0 ? '' : chunk.markdown.substring(newlineAt + 1);
  final inner = md.markdownToHtml(
    bodyAfterHeading,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );
  final date = meta?.lastModified ?? '';

  return div(classes: 'post-pinned-section', attributes: {'data-pin-section': ''}, [
    div(classes: 'post-pinned-section__row', [
      span(classes: 'post-pinned-section__title', [text(chunk.title)]),
      div(classes: 'post-pinned-section__meta', [
        if (date.isNotEmpty) span(classes: 'post-pinned-section__date', [text(date)]),
        span(classes: 'post-pinned-section__arrow', [text('▼')]),
      ]),
    ]),
    div(classes: 'post-pinned-section__body', [raw(inner)]),
  ]);
}
```

- [ ] **Step 4: Add `_renderDimmedRepeat` function**

```dart
/// Renders a dimmed in-place repeat of a pinned section at its natural
/// position in the article. Title-only, ghosted, with ★ note.
Component _renderDimmedRepeat({
  required SectionChunk chunk,
  required Section? meta,
}) {
  final date = meta?.lastModified ?? '';
  return div(classes: 'dimmed-pinned-repeat', [
    div([], [
      div(classes: 'dimmed-pinned-repeat__note', [
        text('★ مثبتة'),
        span(classes: 'dimmed-pinned-repeat__note-sep', [text('·')]),
        text('هذا القسم مثبت في الأعلى'),
      ]),
      span(classes: 'dimmed-pinned-repeat__title', [text(chunk.title)]),
    ]),
    if (date.isNotEmpty) span(classes: 'dimmed-pinned-repeat__date', [text(date)]),
  ]);
}
```

- [ ] **Step 5: Add expand/collapse JS script constant**

Add this constant at the bottom of the file (before the `_parseFaq` function is fine — any top-level position works):

```dart
/// Client-side script for pinned section expand/collapse and "expand all".
const _pinToggleScript = r'''
(function(){
  function toggle(el){
    var body = el.querySelector('.post-pinned-section__body');
    var arrow = el.querySelector('.post-pinned-section__arrow');
    if(!body) return;
    var open = body.classList.toggle('open');
    if(arrow) arrow.classList.toggle('open', open);
  }
  document.querySelectorAll('[data-pin-section]').forEach(function(el){
    el.addEventListener('click', function(e){
      if(e.target.closest('.post-pinned-section__body')) return;
      toggle(el);
    });
  });
  document.querySelectorAll('[data-pin-expand-all]').forEach(function(btn){
    btn.addEventListener('click', function(e){
      e.stopPropagation();
      var block = btn.closest('.post-pinned-block');
      if(!block) return;
      var bodies = block.querySelectorAll('.post-pinned-section__body');
      var arrows = block.querySelectorAll('.post-pinned-section__arrow');
      var anyClosed = false;
      bodies.forEach(function(b){ if(!b.classList.contains('open')) anyClosed = true; });
      bodies.forEach(function(b){ b.classList.toggle('open', anyClosed); });
      arrows.forEach(function(a){ a.classList.toggle('open', anyClosed); });
      btn.textContent = anyClosed ? 'توسيع أقل · Collapse all' : 'توسيع الكل · Expand all';
    });
  });
})();
''';
```

- [ ] **Step 6: Commit**

```bash
git add website-jaspr/lib/pages/blog_post.dart
git commit -m "feat: redesign pinned block, add takeaways, dimmed repeats, expand/collapse"
```

---

### Task 4: Preserve `takeaways` in save server

**Files:**
- Modify: `website-jaspr/tool/save_server.dart`

- [ ] **Step 1: Ensure `takeaways` passes through saves**

The save server already preserves arbitrary fields from the incoming `meta` map. Since `takeaways` is a top-level field in `post.json` (like `tags`), it flows through naturally — no special handling needed for read/write.

However, verify this by checking that `_mergeSections` doesn't strip unknown fields. The `_mergeSections` function only modifies the `sections` key. All other keys in `meta` (including `takeaways`) pass through unchanged via `metaFile.writeAsStringSync(_prettyJson(meta))`.

**No code changes needed for this task.** The save server already handles arbitrary JSON fields.

- [ ] **Step 2: Commit (skip if no changes)**

No commit needed.

---

### Task 5: Add takeaways editor in admin blog page

**Files:**
- Modify: `website-jaspr/lib/pages/admin/blog.dart`

- [ ] **Step 1: Add takeaways textarea in the metadata tab**

Find the metadata tab panel in the admin blog page. It contains fields like title, slug, date, etc. Add a takeaways textarea after the existing metadata fields, inside the metadata tab panel.

Look for where `data-tab='metadata'` content is rendered. Add a new field group:

```dart
div(classes: 'field', [
  label(classes: 'field-label', [text('Key Takeaways · خلاصة المقال')]),
  textarea(
    classes: 'field-input',
    attributes: {
      'data-field': 'takeaways',
      'rows': '6',
      'placeholder': 'One takeaway per line...\nالتسويف مش كسل — هو فشل في تنظيم المشاعر\nالقسوة على النفس تزيد المشكلة',
    },
    [],
  ),
  span(classes: 'field-hint', [text('One line per takeaway. Supports **bold** and [links](url).')]),
]),
```

- [ ] **Step 2: Wire takeaways into the save/load JS in the admin page**

Find the admin JS that handles loading post data into fields and collecting field values for save. The pattern will be something like `state.meta.excerpt_ar` → set field value. Add:

In the load function (where `state.meta` fields populate form inputs):
```javascript
// Takeaways: join array into textarea lines
var taField = document.querySelector('[data-field="takeaways"]');
if (taField) {
  var ta = state.meta.takeaways || [];
  taField.value = Array.isArray(ta) ? ta.join('\n') : '';
}
```

In the save function (where form values are collected into `meta`):
```javascript
// Takeaways: split textarea into array
var taField = document.querySelector('[data-field="takeaways"]');
if (taField) {
  meta.takeaways = taField.value.split('\n').map(function(l){return l.trim();}).filter(Boolean);
}
```

- [ ] **Step 3: Commit**

```bash
git add website-jaspr/lib/pages/admin/blog.dart
git commit -m "feat: add takeaways editor in admin blog metadata tab"
```

---

### Task 6: Add test takeaways data and verify

**Files:**
- Modify: `website-jaspr/content/blog/01-procrastination/post.json`

- [ ] **Step 1: Add takeaways array to the procrastination post**

Add a `takeaways` array to `content/blog/01-procrastination/post.json` (at the top level, alongside `sections`):

```json
"takeaways": [
  "التسويف **مش كسل** — هو فشل في تنظيم المشاعر، وليس نقص في الإرادة أو الدافع",
  "المجتمع يحوّل التسويف إلى عيب أخلاقي بالرغم من أن الأبحاث ترفض هذا التفسير",
  "**القسوة على النفس** تزيد المشكلة — التعاطف مع الذات هو نقطة البداية الحقيقية",
  "الحلول العملية تبدأ من فهم السبب العاطفي، مش من فرض جدول صارم"
]
```

- [ ] **Step 2: Build and verify**

```bash
cd website-jaspr && dart run tool/build.dart
```

Expected: Build succeeds. Open the built HTML for the procrastination post and verify:
1. Pinned block renders with teal border, title-only rows, date + ▼
2. Takeaways box appears after pinned block
3. Dimmed repeats appear at natural positions in article
4. Bold text is teal/accent colored
5. Text is justified

- [ ] **Step 3: Commit**

```bash
git add website-jaspr/content/blog/01-procrastination/post.json
git commit -m "test: add takeaways data to procrastination post"
```

---

## Self-Review

**Spec coverage:**
- ✅ Pinned block redesigned (teal border, title-only, expand/collapse) → Task 2 + 3
- ✅ Takeaways box after pinned block → Task 1 + 2 + 3
- ✅ Dimmed in-place repeats → Task 2 + 3
- ✅ Justified text → Task 2
- ✅ Bold/links in accent color → Task 2
- ✅ Citation `<sup>` styling → Task 2
- ✅ Save server handles takeaways → Task 4 (no changes needed)
- ✅ Admin editor for takeaways → Task 5
- ✅ Test data → Task 6

**Placeholder scan:** No TBDs, TODOs, or vague instructions. All code shown inline.

**Type consistency:** `takeaways` is `List<String>` in model, `List` in JSON, split/join in admin JS. `pinned` parameter removed from `_renderSection` since it's only used for non-pinned now. All class names consistent between CSS and Dart.
