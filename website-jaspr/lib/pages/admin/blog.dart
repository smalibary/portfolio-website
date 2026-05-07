import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';

/// Blog editor. Picker in the topbar (V3 style — ⌘K to open). Editor below
/// with tabs for content, metadata, and SEO. Inline JS handles all the
/// dynamic bits — list fetch, picker filter, post load, save, delete.
class AdminBlogPage extends StatelessComponent {
  const AdminBlogPage({super.key});

  static const _api = 'http://localhost:9090';

  static const _script = '''
(function(){
  var API = '$_api';
  var \$ = function(s, root){ return (root||document).querySelector(s); };
  var \$\$ = function(s, root){ return Array.from((root||document).querySelectorAll(s)); };

  var pickerBtn   = \$('.adm [data-picker-btn]');
  var pickerSearch= \$('.adm [data-picker-search]');
  var pickerList  = \$('.adm [data-picker-list]');
  var pickerNew   = \$('.adm [data-picker-new]');
  var pickerTitle = \$('.adm .picker-title');
  var savedChip   = \$('.adm .topbar .chip');
  var publishBtn  = \$('.adm [data-publish]');
  var saveBtn     = \$('.adm [data-save]');
  var deleteBtn   = \$('.adm [data-delete]');
  var tagsTarget  = \$('.adm [data-tags]');
  var tagInputEl  = null;

  var posts = [];
  var currentId = null;
  var dirty = false;
  var deleteArmed = false;

  // ---------- tabs ----------
  \$\$('.adm .tabs button').forEach(function(b){
    b.addEventListener('click', function(){
      \$\$('.adm .tabs button').forEach(function(x){ x.classList.toggle('active', x === b); });
      \$\$('.adm .tab-panel').forEach(function(p){ p.classList.toggle('active', p.dataset.tab === b.dataset.tab); });
    });
  });

  // ---------- save state chip ----------
  function setSaveState(state, text){
    if (!savedChip) return;
    savedChip.classList.toggle('on', state === 'saved' || state === 'idle');
    savedChip.classList.toggle('warn', state === 'saving' || state === 'error' || state === 'dirty');
    savedChip.innerHTML = '<span class="dot"></span>' + text;
  }
  function markDirty(){ dirty = true; setSaveState('dirty', 'UNSAVED · غير محفوظ'); }
  function markSaved(){ dirty = false; setSaveState('saved', 'SAVED ✓'); }

  window.addEventListener('beforeunload', function(e){
    if (dirty) { e.preventDefault(); e.returnValue = ''; }
  });

  // ---------- picker ----------
  if (pickerBtn) pickerBtn.addEventListener('click', function(e){
    e.stopPropagation();
    pickerBtn.classList.toggle('open');
    if (pickerBtn.classList.contains('open') && pickerSearch) pickerSearch.focus();
  });
  document.addEventListener('click', function(e){
    if (pickerBtn && !pickerBtn.parentElement.contains(e.target)) pickerBtn.classList.remove('open');
  });
  document.addEventListener('keydown', function(e){
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
      e.preventDefault();
      pickerBtn.classList.toggle('open');
      if (pickerBtn.classList.contains('open') && pickerSearch) pickerSearch.focus();
    }
    if (e.key === 'Escape') pickerBtn.classList.remove('open');
  });

  if (pickerSearch) pickerSearch.addEventListener('input', renderPicker);

  if (pickerNew) pickerNew.addEventListener('click', function(){
    var slug = prompt('slug for the new post (e.g. \\'my-new-post\\')');
    if (!slug) return;
    fetch(API + '/api/posts', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ slug: slug, title_ar: '(عنوان جديد)', title_en: '(new title)' })
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.id) {
        loadList().then(function(){ selectPost(res.id); });
      }
    });
  });

  function renderPicker(){
    if (!pickerList) return;
    var q = (pickerSearch && pickerSearch.value || '').toLowerCase();
    pickerList.innerHTML = '';
    var filtered = posts.filter(function(p){
      if (!q) return true;
      return ((p.title_ar||'') + ' ' + (p.title_en||'') + ' ' + (p.slug||'')).toLowerCase().indexOf(q) !== -1;
    });
    if (filtered.length === 0) {
      var empty = document.createElement('div');
      empty.style.padding = '20px'; empty.style.textAlign = 'center'; empty.style.color = 'var(--color-text-faint)';
      empty.style.fontFamily = 'JetBrains Mono, monospace'; empty.style.fontSize = '12px';
      empty.textContent = 'NO POSTS MATCH';
      pickerList.appendChild(empty);
      return;
    }
    filtered.forEach(function(p){
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'pick-item' + (p.id === currentId ? ' active' : '');
      var meta = document.createElement('div'); meta.className = 'pick-meta';
      meta.textContent = (p.date || '') + ' · ' + ((p.word_count||0).toLocaleString()) + ' words';
      var title = document.createElement('div'); title.className = 'pick-title';
      title.textContent = p.title_ar || p.title_en || p.id;
      var body = document.createElement('div'); body.className = 'pick-body';
      body.appendChild(meta); body.appendChild(title);
      btn.appendChild(body);
      btn.addEventListener('click', function(){
        if (dirty && p.id !== currentId && !confirm('Discard unsaved changes to current post?')) return;
        selectPost(p.id);
      });
      pickerList.appendChild(btn);
    });
  }

  // ---------- list / select / save / delete ----------
  function loadList(){
    return fetch(API + '/api/posts').then(function(r){ return r.json(); }).then(function(data){
      posts = data;
      renderPicker();
    });
  }

  function selectPost(id){
    currentId = id;
    pickerBtn.classList.remove('open');
    setSaveState('saving', 'LOADING');
    fetch(API + '/api/posts/' + id).then(function(r){ return r.json(); }).then(function(data){
      fillForm(data);
      markSaved();
      attachDirtyListeners();
      if (pickerTitle) pickerTitle.textContent = (data.meta && (data.meta.title_ar || data.meta.title_en)) || id;
    }).catch(function(e){
      setSaveState('error', 'LOAD ERROR');
      console.error('load failed', e);
    });
  }

  function fillForm(data){
    var meta = data.meta || {};
    \$\$('.adm [data-field]').forEach(function(el){
      var k = el.dataset.field;
      if (k === 'body') el.value = data.body || '';
      else if (k === 'takeaways') { var ta = Array.isArray(meta[k]) ? meta[k] : []; el.value = ta.join('\\n'); }
      else if (meta[k] !== undefined && meta[k] !== null) el.value = meta[k];
      else el.value = '';
    });
    renderTags(meta.tags || []);
    renderPreview();
    renderSections(meta.sections || []);
  }

  // ---------- sections (live-document feature, #101) ----------
  // Slugifier mirrors lib/data/sections.dart::slugify so anchors stay
  // consistent between admin parsing and save_server merging.
  function slugifySection(s){
    s = (s || '').trim().toLowerCase();
    s = s.replace(/[\s ]+/g, '-');
    s = s.replace(/[^\\w\\u0600-\\u06FF\\-]/g, '');
    s = s.replace(/-+/g, '-');
    s = s.replace(/^-+|-+\$/g, '');
    return s;
  }

  function parseBodySections(body){
    var lines = (body || '').replace(/\\r\\n/g, '\\n').split('\\n');
    var out = [];
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^##\\s+(.+?)\\s*\$/);
      if (m) {
        var title = m[1].trim();
        out.push({ anchor: slugifySection(title), title: title });
      }
    }
    return out;
  }

  function renderSections(savedSections){
    var target = \$('.adm [data-sections]');
    if (!target) return;
    var bodyEl = \$('.adm [data-field="body"]');
    var bodySections = parseBodySections(bodyEl ? bodyEl.value : '');

    // Build a lookup of saved metadata by anchor.
    var savedByAnchor = {};
    (savedSections || []).forEach(function(s){
      if (s && s.anchor) savedByAnchor[s.anchor] = s;
    });

    // For each section in the current body, merge in saved metadata.
    var rows = bodySections.map(function(bs){
      var saved = savedByAnchor[bs.anchor] || {};
      return {
        anchor: bs.anchor,
        title: bs.title,
        last_modified: saved.last_modified || '',
        pinned: !!saved.pinned,
        subtopic: saved.subtopic || ''
      };
    });

    target.innerHTML = '';
    if (rows.length === 0) {
      var empty = document.createElement('div');
      empty.className = 'sections-empty';
      empty.textContent = 'No ## sections in body yet — add H2 headings to the markdown to manage them here.';
      target.appendChild(empty);
      return;
    }

    rows.forEach(function(r, i){
      var row = document.createElement('div');
      row.className = 'section-row';
      row.dataset.anchor = r.anchor;

      var head = document.createElement('div');
      head.className = 'section-row__head';
      var idx = document.createElement('span');
      idx.className = 'section-row__idx';
      idx.textContent = String(i + 1).padStart(2, '0');
      var title = document.createElement('div');
      title.className = 'section-row__title';
      title.textContent = r.title;
      head.appendChild(idx); head.appendChild(title);

      var controls = document.createElement('div');
      controls.className = 'section-row__controls';

      // Pin checkbox
      var pinLabel = document.createElement('label');
      pinLabel.className = 'section-row__pin';
      var pin = document.createElement('input');
      pin.type = 'checkbox';
      pin.checked = r.pinned;
      pin.dataset.role = 'pin';
      pin.addEventListener('change', function(){ markDirty(); validatePinCount(); });
      pinLabel.appendChild(pin);
      pinLabel.appendChild(document.createTextNode(' PIN'));

      // Date input
      var dateLabel = document.createElement('label');
      dateLabel.className = 'section-row__date';
      dateLabel.appendChild(document.createTextNode('Updated '));
      var dateInput = document.createElement('input');
      dateInput.type = 'date';
      dateInput.value = r.last_modified;
      dateInput.dataset.role = 'date';
      dateInput.addEventListener('input', markDirty);
      dateLabel.appendChild(dateInput);

      // Subtopic
      var subLabel = document.createElement('label');
      subLabel.className = 'section-row__sub';
      subLabel.appendChild(document.createTextNode('Subtopic '));
      var subInput = document.createElement('input');
      subInput.type = 'text';
      subInput.placeholder = 'optional label';
      subInput.value = r.subtopic;
      subInput.dataset.role = 'subtopic';
      subInput.addEventListener('input', markDirty);
      subLabel.appendChild(subInput);

      controls.appendChild(pinLabel);
      controls.appendChild(dateLabel);
      controls.appendChild(subLabel);

      row.appendChild(head);
      row.appendChild(controls);
      target.appendChild(row);
    });

    validatePinCount();
  }

  function validatePinCount(){
    var pinned = \$\$('.adm [data-sections] input[data-role="pin"]').filter(function(el){ return el.checked; }).length;
    var warn = \$('.adm [data-sections-warn]');
    if (warn) {
      if (pinned > 3) {
        warn.textContent = '⚠ ' + pinned + ' sections pinned — pinning too many defeats the "promoted to top" signal. Consider keeping it ≤ 3.';
        warn.style.display = 'block';
      } else {
        warn.style.display = 'none';
      }
    }
  }

  function readSections(){
    var rows = \$\$('.adm [data-sections] .section-row');
    return rows.map(function(row){
      var pin = row.querySelector('input[data-role="pin"]');
      var date = row.querySelector('input[data-role="date"]');
      var sub = row.querySelector('input[data-role="subtopic"]');
      return {
        anchor: row.dataset.anchor,
        title: row.querySelector('.section-row__title').textContent,
        last_modified: date ? date.value : '',
        pinned: pin ? !!pin.checked : false,
        subtopic: sub ? sub.value : ''
      };
    });
  }

  // Re-render the sections list when the body markdown changes (so newly
  // added/removed ## headings appear immediately, not only after save).
  document.addEventListener('input', function(e){
    if (e.target && e.target.dataset && e.target.dataset.field === 'body') {
      // Preserve current pin/date/subtopic state from existing rows.
      renderSections(readSections());
    }
  });

  // markdown live preview (marked.js loads via <script> at the bottom)
  function renderPreview(){
    var bodyEl = \$('.adm [data-field="body"]');
    var previewEl = \$('.adm [data-md-preview]');
    if (!bodyEl || !previewEl || typeof marked === 'undefined') return;
    try {
      previewEl.innerHTML = marked.parse(bodyEl.value || '', {breaks: true});
    } catch (e) {
      previewEl.textContent = '(preview error)';
    }
  }
  // Listen on the live body textarea (it stays the same DOM node across post switches).
  document.addEventListener('input', function(e){
    if (e.target && e.target.dataset && e.target.dataset.field === 'body') renderPreview();
  });

  function renderTags(list){
    if (!tagsTarget) return;
    tagsTarget.innerHTML = '';
    list.forEach(function(t){ tagsTarget.appendChild(buildTag(t)); });
    tagInputEl = document.createElement('input');
    tagInputEl.placeholder = 'add tag, ⏎';
    tagInputEl.addEventListener('keydown', function(e){
      if (e.key === 'Enter' && tagInputEl.value.trim()) {
        e.preventDefault();
        tagsTarget.insertBefore(buildTag(tagInputEl.value.trim()), tagInputEl);
        tagInputEl.value = '';
        markDirty();
      }
    });
    tagsTarget.appendChild(tagInputEl);
  }

  function buildTag(t){
    var span = document.createElement('span');
    span.className = 'tag'; span.dataset.tag = t;
    span.appendChild(document.createTextNode(t + ' '));
    var x = document.createElement('button'); x.type = 'button'; x.textContent = '×';
    x.addEventListener('click', function(){ span.remove(); markDirty(); });
    span.appendChild(x);
    return span;
  }

  function readTags(){
    return \$\$('.tag', tagsTarget).map(function(t){ return t.dataset.tag; });
  }

  function readForm(){
    var meta = {};
    \$\$('.adm [data-field]').forEach(function(el){
      var k = el.dataset.field;
      if (k === 'body') return;
      var v = el.value;
      if (el.type === 'number') v = v ? Number(v) : 0;
      meta[k] = v;
    });
    meta.tags = readTags();
    meta.sections = readSections();
    var taEl = \$('.adm [data-field="takeaways"]');
    if (taEl) meta.takeaways = taEl.value.split('\\n').map(function(l){return l.trim();}).filter(Boolean);
    var bodyEl = \$('.adm [data-field="body"]');
    return { meta: meta, body: bodyEl ? bodyEl.value : '' };
  }

  function save(){
    if (!currentId) return;
    setSaveState('saving', 'SAVING...');
    var payload = readForm();
    fetch(API + '/api/posts/' + currentId, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(payload)
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.ok) {
        markSaved();
        loadList(); // refresh — title may have changed
        if (pickerTitle) pickerTitle.textContent = payload.meta.title_ar || payload.meta.title_en || currentId;
      } else {
        setSaveState('error', 'SAVE ERROR');
        console.error(res);
      }
    }).catch(function(e){
      setSaveState('error', 'SAVE ERROR');
      console.error('save failed', e);
    });
  }

  function attachDirtyListeners(){
    \$\$('.adm [data-field]').forEach(function(el){
      el.removeEventListener('input', markDirty);
      el.addEventListener('input', markDirty);
    });
  }

  if (saveBtn)    saveBtn.addEventListener('click', save);
  if (publishBtn) publishBtn.addEventListener('click', save);

  // delete: 2-click pattern. First click arms, second confirms (within 4s).
  if (deleteBtn) deleteBtn.addEventListener('click', function(){
    if (!currentId) return;
    if (!deleteArmed) {
      deleteArmed = true;
      var orig = deleteBtn.textContent;
      deleteBtn.textContent = 'CONFIRM DELETE ⚠';
      deleteBtn.classList.add('armed');
      setTimeout(function(){ deleteArmed = false; deleteBtn.textContent = orig; deleteBtn.classList.remove('armed'); }, 4000);
      return;
    }
    fetch(API + '/api/posts/' + currentId, { method: 'DELETE' })
      .then(function(r){ return r.json(); })
      .then(function(){
        currentId = null;
        loadList().then(function(){
          if (posts.length) selectPost(posts[0].id);
          else { fillForm({meta:{}, body:''}); if (pickerTitle) pickerTitle.textContent = '(no posts)'; markSaved(); }
        });
      });
  });

  // initial load
  loadList().then(function(){
    if (posts.length) selectPost(posts[0].id);
    else { fillForm({meta:{}, body:''}); if (pickerTitle) pickerTitle.textContent = '(no posts — click + NEW)'; markSaved(); }
  });
})();
''';

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'blog',
      body: [
        // custom topbar with picker (replacing AdminTopbar's static label)
        header(classes: 'topbar', [
          div(classes: 'topbar-l', [
            div(classes: 'picker', [
              button(
                classes: 'picker-btn',
                attributes: const {'data-picker-btn': '', 'type': 'button'},
                [
                  div(classes: 'picker-icon', [
                    raw(
                      '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" '
                      'stroke="currentColor" stroke-width="1.8">'
                      '<path d="M4 4h12a4 4 0 0 1 4 4v12H8a4 4 0 0 1-4-4V4z"/>'
                      '<path d="M8 9h8M8 13h6"/></svg>',
                    ),
                  ]),
                  div(classes: 'picker-meta', [
                    div(classes: 'picker-section', [text('BLOG · POST')]),
                    div(classes: 'picker-title', [text('loading…')]),
                  ]),
                  span(classes: 'picker-chev', [text('▾')]),
                  span(classes: 'picker-kbd', [text('⌘K')]),
                ],
              ),
              div(classes: 'picker-panel', [
                div(classes: 'picker-search', [
                  raw(
                    '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'
                    '<circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>',
                  ),
                  input(
                    type: InputType.text,
                    attributes: const {
                      'data-picker-search': '',
                      'placeholder': 'ابحث ف المقالات... · search posts...',
                    },
                  ),
                ]),
                div(classes: 'picker-list', attributes: const {'data-picker-list': ''}, []),
                div(classes: 'picker-foot', [
                  button(
                    classes: 'picker-new',
                    attributes: const {'data-picker-new': '', 'type': 'button'},
                    [text('+ مقال جديد · NEW POST')],
                  ),
                  span(classes: 'picker-hint', [
                    raw('<kbd>↑↓</kbd> navigate <kbd>↵</kbd> open <kbd>esc</kbd> close'),
                  ]),
                ]),
              ]),
            ]),
          ]),
          div(classes: 'topbar-r', [
            a(
              href: '/',
              classes: 'view-site',
              attributes: const {
                'target': '_blank',
                'rel': 'noopener',
                'title': 'View public site',
                'aria-label': 'View public site',
              },
              [
                raw(
                  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" '
                  'stroke="currentColor" stroke-width="1.8" stroke-linecap="round" '
                  'stroke-linejoin="round">'
                  '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>'
                  '<polyline points="15 3 21 3 21 9"/>'
                  '<line x1="10" y1="14" x2="21" y2="3"/></svg>',
                ),
                span([text('VIEW SITE')]),
              ],
            ),
            div(classes: 'chip on', [span(classes: 'dot', []), text('SAVED')]),
            button(
              classes: 'btn',
              attributes: const {'data-publish': '', 'type': 'button'},
              [text('حفظ و نشر · PUBLISH')],
            ),
          ]),
        ]),

        main_(classes: 'main', [
          div(classes: 'tabs', [
            button(
              classes: 'active',
              attributes: const {'data-tab': 'content', 'type': 'button'},
              [text('المحتوى · CONTENT')],
            ),
            button(
              attributes: const {'data-tab': 'metadata', 'type': 'button'},
              [text('البيانات الوصفية · METADATA')],
            ),
            button(
              attributes: const {'data-tab': 'sections', 'type': 'button'},
              [text('الأقسام · SECTIONS')],
            ),
            button(
              attributes: const {'data-tab': 'seo', 'type': 'button'},
              [text('SEO · AEO')],
            ),
          ]),

          // CONTENT tab
          div(classes: 'tab-panel active', attributes: const {'data-tab': 'content'}, [
            div(classes: 'row', [
              _field('العنوان بالعربي', '', 'title_ar', required: true),
              _field('', 'TITLE · ENGLISH', 'title_en', required: true),
            ]),
            _field('المعرّف · SLUG', '', 'slug', required: true, hint: 'salemmalibary.com/blog/<slug>'),
            div(classes: 'row', [
              _textarea('المقتطف بالعربي', '', 'excerpt_ar', rows: 3),
              _textarea('', 'EXCERPT · ENGLISH', 'excerpt_en', rows: 3),
            ]),
            // Body editor — split view with live markdown preview.
            div(classes: 'field', [
              label([
                text('محتوى المقال · MARKDOWN BODY'),
                span(classes: 'req', [text(' *')]),
              ]),
              div(classes: 'md-split-header', [
                span([text('SOURCE · MARKDOWN')]),
                span([text('PREVIEW')]),
              ]),
              div(classes: 'md-split', [
                textarea(
                  attributes: const {
                    'data-field': 'body',
                    'spellcheck': 'false',
                  },
                  [],
                ),
                div(classes: 'md-preview', attributes: const {'data-md-preview': ''}, []),
              ]),
              div(classes: 'hint', [
                text('Live preview powered by marked.js · auto-saves with the rest of the form'),
              ]),
            ]),
          ]),

          // METADATA tab
          div(classes: 'tab-panel', attributes: const {'data-tab': 'metadata'}, [
            div(classes: 'row', [
              _field('التاريخ · DATE', '', 'date', type: InputType.date, required: true),
              _field('التصنيف · CATEGORY', '', 'category'),
            ]),
            div(classes: 'field', [
              label([text('الوسوم · TAGS')]),
              div(classes: 'tag-input', attributes: const {'data-tags': ''}, []),
            ]),
            div(classes: 'row', [
              _field('وقت القراءة · READING TIME (min)', '', 'reading_time', type: InputType.number),
              _field('اللغة · LANGUAGE', '', 'language', hint: 'ar / en'),
            ]),
            _textarea('خلاصة المقال · KEY TAKEAWAYS', '', 'takeaways', rows: 6),
            div(classes: 'hint', [text('One line per takeaway. Supports **bold** and [links](url).')]),
          ]),

          // SECTIONS tab — live-document section management (#101)
          div(classes: 'tab-panel', attributes: const {'data-tab': 'sections'}, [
            div(classes: 'sections-intro', [
              p([text(
                'Each H2 (## ) heading in the body is a live-document section. '
                'Pin to promote a section to the top (in original order). '
                'Dates auto-update on save when section text changes — set manually here to override.',
              )]),
              div(classes: 'sections-warn', attributes: const {'data-sections-warn': '', 'style': 'display:none;'}, []),
            ]),
            div(classes: 'sections-list', attributes: const {'data-sections': ''}, []),
          ]),

          // SEO tab
          div(classes: 'tab-panel', attributes: const {'data-tab': 'seo'}, [
            _field('META TITLE', '', 'meta_title'),
            _textarea('META DESCRIPTION', '', 'meta_description', rows: 3),
            div(classes: 'row', [
              _field('OG IMAGE', '', 'og_image', hint: 'relative to /images/'),
              _field('CANONICAL URL', '', 'canonical_url', type: InputType.url),
            ]),
            _field('ROBOTS', '', 'robots', hint: 'e.g. "index, follow"'),
          ]),

          // actions
          div(classes: 'actions', [
            button(
              classes: 'btn danger',
              attributes: const {'data-delete': '', 'type': 'button'},
              [text('حذف · DELETE')],
            ),
            div(classes: 'flex-1', []),
            button(
              classes: 'btn ghost',
              attributes: const {'type': 'button'},
              [text('معاينة · PREVIEW')],
            ),
            button(
              classes: 'btn',
              attributes: const {'data-save': '', 'type': 'button'},
              [text('حفظ · SAVE')],
            ),
          ]),
        ]),
        // Load marked.js BEFORE the inline script that uses it.
        script(src: 'https://cdn.jsdelivr.net/npm/marked/marked.min.js'),
        script(content: _script),
      ],
    );
  }

  Component _field(
    String labelAr,
    String labelEn,
    String fieldName, {
    bool required = false,
    InputType type = InputType.text,
    String? hint,
  }) {
    return div(classes: 'field', [
      label([
        if (labelAr.isNotEmpty) text(labelAr),
        if (labelEn.isNotEmpty) text(labelEn),
        if (required) span(classes: 'req', [text('*')]),
      ]),
      input(type: type, attributes: {'data-field': fieldName}),
      if (hint != null) div(classes: 'hint', [text(hint)]),
    ]);
  }

  Component _textarea(
    String labelAr,
    String labelEn,
    String fieldName, {
    int rows = 5,
    bool monospace = false,
    bool required = false,
  }) {
    return div(classes: 'field', [
      label([
        if (labelAr.isNotEmpty) text(labelAr),
        if (labelEn.isNotEmpty) text(labelEn),
        if (required) span(classes: 'req', [text('*')]),
      ]),
      textarea(
        classes: monospace ? 'large' : null,
        attributes: {
          'data-field': fieldName,
          'rows': rows.toString(),
          if (monospace)
            'style':
                'font-family:JetBrains Mono,monospace;font-size:13px;min-height:400px;',
        },
        [],
      ),
    ]);
  }
}
