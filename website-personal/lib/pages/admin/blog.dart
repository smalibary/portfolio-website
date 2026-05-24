import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';

/// Blog admin — list-first. Default view is a list of all articles with
/// DRAFT/PUBLISHED badges; click a row to open the editor, or "New Post" to
/// create. The editor (tabs for content / metadata / sections / SEO) slides
/// in over the same page; a back button returns to the list.
class AdminBlogPage extends StatelessComponent {
  const AdminBlogPage({super.key});

  static const _script = '''
(function(){
  var API = '/api/admin';
  var \$ = function(s, root){ return (root||document).querySelector(s); };
  var \$\$ = function(s, root){ return Array.from((root||document).querySelectorAll(s)); };

  var listView      = \$('.adm [data-view="list"]');
  var editView      = \$('.adm [data-view="edit"]');
  var articleListEl = \$('.adm [data-article-list]');
  var newBtn        = \$('.adm [data-new]');
  var backBtn       = \$('.adm [data-back]');
  var currentTitle  = \$('.adm [data-current-title]');
  var savedChip     = \$('.adm .topbar .chip');
  var publishBtn    = \$('.adm [data-publish]');
  var saveBtn       = \$('.adm [data-save]');
  var deleteBtn     = \$('.adm [data-delete]');
  var tagsTarget    = \$('.adm [data-tags]');
  var tagInputEl    = null;

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

  // ---------- view switching ----------
  function showList(){
    if (editView) editView.classList.add('hidden');
    if (listView) listView.classList.remove('hidden');
    if (backBtn) backBtn.classList.add('hidden');
    if (currentTitle) currentTitle.textContent = '';
    setSaveState('idle', 'المقالات · ARTICLES');
    renderList();
  }
  function showEdit(slug){
    if (dirty && !confirm('Discard unsaved changes?')) return;
    if (listView) listView.classList.add('hidden');
    if (editView) editView.classList.remove('hidden');
    if (backBtn) backBtn.classList.remove('hidden');
    // default to the first tab
    \$\$('.adm .tabs button').forEach(function(x, i){ x.classList.toggle('active', i === 0); });
    \$\$('.adm .tab-panel').forEach(function(p){ p.classList.toggle('active', p.dataset.tab === 'content'); });
    selectPost(slug);
  }
  if (backBtn) backBtn.addEventListener('click', function(){
    if (dirty && !confirm('Discard unsaved changes?')) return;
    dirty = false;
    loadList().then(showList);
  });

  // ---------- article list ----------
  function loadList(){
    return window.adminFetch(API + '/posts').then(function(r){ return r.json(); }).then(function(data){
      posts = Array.isArray(data) ? data : [];
    });
  }

  function renderList(){
    if (!articleListEl) return;
    articleListEl.innerHTML = '';
    if (!posts.length){
      var empty = document.createElement('div');
      empty.className = 'article-empty';
      empty.textContent = 'لا توجد مقالات بعد · No articles yet — click + NEW POST.';
      articleListEl.appendChild(empty);
      return;
    }
    posts.forEach(function(p){
      var status = (p.status || 'draft');
      var row = document.createElement('button');
      row.type = 'button';
      row.className = 'article-row';

      var meta = document.createElement('div');
      meta.className = 'article-row__meta';
      var badge = document.createElement('span');
      badge.className = 'article-row__status ' + (status === 'published' ? 'is-published' : 'is-draft');
      badge.textContent = status.toUpperCase();
      var date = document.createElement('span');
      date.className = 'article-row__date';
      date.textContent = p.date || '—';
      meta.appendChild(badge); meta.appendChild(date);

      var title = document.createElement('div');
      title.className = 'article-row__title';
      title.textContent = p.title_ar || p.title_en || p.slug;

      var slug = document.createElement('div');
      slug.className = 'article-row__slug';
      slug.textContent = '/blog/' + p.slug;

      row.appendChild(meta);
      row.appendChild(title);
      row.appendChild(slug);
      row.addEventListener('click', function(){ showEdit(p.slug); });
      articleListEl.appendChild(row);
    });
  }

  if (newBtn) newBtn.addEventListener('click', function(){
    var raw = prompt('slug for the new post (e.g. my-new-post)');
    if (!raw) return;
    var slug = raw.trim().toLowerCase()
      .replace(/\\s+/g, '-')
      .replace(/[^a-z0-9\\-]/g, '')
      .replace(/-+/g, '-')
      .replace(/^-+|-+\$/g, '');
    if (!slug) { alert('Slug must contain letters or numbers.'); return; }
    window.adminFetch(API + '/posts', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ slug: slug, language: 'ar', status: 'draft', title_ar: '(عنوان جديد)', title_en: '(new title)' })
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.id || res.slug) {
        loadList().then(function(){ showEdit(res.slug || res.id); });
      } else {
        alert('Create failed: ' + (res.error || 'unknown'));
      }
    });
  });

  // ---------- select / load a single post ----------
  function selectPost(slug){
    currentId = slug;
    setSaveState('saving', 'LOADING');
    window.adminFetch(API + '/posts/' + slug).then(function(r){ return r.json(); }).then(function(data){
      fillForm(data);
      markSaved();
      attachDirtyListeners();
      var t = (data.meta && (data.meta.title_ar || data.meta.title_en)) || slug;
      if (currentTitle) currentTitle.textContent = t;
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
    setStatusLabel(meta.status || 'draft');
  }

  // ---------- sections (live-document feature, #101) ----------
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

    var savedByAnchor = {};
    (savedSections || []).forEach(function(s){
      if (s && s.anchor) savedByAnchor[s.anchor] = s;
    });

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

      var pinLabel = document.createElement('label');
      pinLabel.className = 'section-row__pin';
      var pin = document.createElement('input');
      pin.type = 'checkbox';
      pin.checked = r.pinned;
      pin.dataset.role = 'pin';
      pin.addEventListener('change', function(){ markDirty(); validatePinCount(); });
      pinLabel.appendChild(pin);
      pinLabel.appendChild(document.createTextNode(' PIN'));

      var dateLabel = document.createElement('label');
      dateLabel.className = 'section-row__date';
      dateLabel.appendChild(document.createTextNode('Updated '));
      var dateInput = document.createElement('input');
      dateInput.type = 'date';
      dateInput.value = r.last_modified;
      dateInput.dataset.role = 'date';
      dateInput.addEventListener('input', markDirty);
      dateLabel.appendChild(dateInput);

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

  document.addEventListener('input', function(e){
    if (e.target && e.target.dataset && e.target.dataset.field === 'body') {
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

  // statusOverride: 'published' from Publish, undefined for a plain Save
  // (server keeps the existing status).
  function save(statusOverride){
    if (!currentId) return;
    setSaveState('saving', 'SAVING...');
    var payload = readForm();
    if (statusOverride) payload.meta.status = statusOverride;
    window.adminFetch(API + '/posts/' + currentId, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(payload)
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.ok) {
        markSaved();
        if (res.post && res.post.status) setStatusLabel(res.post.status);
        if (currentTitle) currentTitle.textContent = payload.meta.title_ar || payload.meta.title_en || currentId;
        loadList(); // keep the list fresh for when we go back
        if (statusOverride === 'published') showRebuildNote();
      } else {
        setSaveState('error', 'SAVE ERROR');
        console.error(res);
      }
    }).catch(function(e){
      setSaveState('error', 'SAVE ERROR');
      console.error('save failed', e);
    });
  }

  // The site is statically built. Publishing updates Supabase instantly, then
  // a rebuild (~90s) regenerates the pages. Tell the user to wait instead of
  // wondering why the post isn't live the instant they click Publish.
  function showRebuildNote(){
    var note = \$('.adm [data-publish-note]');
    if (!note) return;
    note.innerHTML = '✓ تم النشر · Published. The site is rebuilding — your post will be live at '
      + '<a href="/writing" target="_blank" rel="noopener">smalibary.me/writing</a> in about 90 seconds. '
      + '<span class="countdown"></span>';
    note.classList.add('show');
    var left = 90;
    var cd = note.querySelector('.countdown');
    if (note._timer) clearInterval(note._timer);
    note._timer = setInterval(function(){
      left -= 1;
      if (cd) cd.textContent = left > 0 ? '(~' + left + 's)' : '(should be live now — refresh /writing)';
      if (left <= 0) clearInterval(note._timer);
    }, 1000);
  }

  function setStatusLabel(status){
    var el = \$('.adm [data-status-label]');
    if (!el) return;
    status = status || 'draft';
    el.textContent = status.toUpperCase();
    el.className = 'status-pill is-' + status;
  }

  function attachDirtyListeners(){
    \$\$('.adm [data-field]').forEach(function(el){
      el.removeEventListener('input', markDirty);
      el.addEventListener('input', markDirty);
    });
  }

  if (saveBtn)    saveBtn.addEventListener('click', function(){ save(); });
  if (publishBtn) publishBtn.addEventListener('click', function(){ save('published'); });

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
    window.adminFetch(API + '/posts/' + currentId, { method: 'DELETE' })
      .then(function(r){ return r.json(); })
      .then(function(){
        dirty = false;
        currentId = null;
        loadList().then(showList);
      });
  });

  // initial — list view once the session is confirmed by admin_shell.
  window.__adminReady.then(function(){
    loadList().then(showList);
  });
})();
''';

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'blog',
      body: [
        header(classes: 'topbar', [
          div(classes: 'topbar-l', [
            button(
              classes: 'back-btn hidden',
              attributes: const {'data-back': '', 'type': 'button'},
              [text('← المقالات · ALL ARTICLES')],
            ),
            div(classes: 'section-name', [text('المدونة · BLOG')]),
            div(classes: 'current-title', attributes: const {'data-current-title': ''}, []),
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
                span([text('VIEW')]),
              ],
            ),
            div(classes: 'chip on', [span(classes: 'dot', []), text('المقالات')]),
            span(classes: 'status-pill is-draft', attributes: const {'data-status-label': ''}, [text('—')]),
          ]),
        ]),

        main_(classes: 'main', [
          // ===== LIST VIEW =====
          div(attributes: const {'data-view': 'list'}, [
            div(classes: 'list-head', [
              div([
                h1([text('المقالات')]),
                div(classes: 'en', [text('ARTICLES · click a row to edit')]),
              ]),
              button(
                classes: 'btn',
                attributes: const {'data-new': '', 'type': 'button'},
                [text('+ مقال جديد · NEW POST')],
              ),
            ]),
            div(classes: 'article-list', attributes: const {'data-article-list': ''}, []),
          ]),

          // ===== EDIT VIEW (hidden until a row/new is clicked) =====
          div(classes: 'hidden', attributes: const {'data-view': 'edit'}, [
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
              _field('المعرّف · SLUG', '', 'slug', required: true, hint: 'smalibary.me/blog/<slug>'),
              div(classes: 'row', [
                _textarea('المقتطف بالعربي', '', 'excerpt_ar', rows: 3),
                _textarea('', 'EXCERPT · ENGLISH', 'excerpt_en', rows: 3),
              ]),
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

            // SECTIONS tab
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
                attributes: const {'data-save': '', 'type': 'button'},
                [text('حفظ كمسودة · SAVE DRAFT')],
              ),
              button(
                classes: 'btn',
                attributes: const {'data-publish': '', 'type': 'button'},
                [text('نشر · PUBLISH')],
              ),
            ]),
            div(classes: 'publish-note', attributes: const {'data-publish-note': ''}, []),
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
