import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';
import '../../components/admin/page_header.dart';

/// Research admin — list-first, mirroring the blog admin. Default view is a
/// list of papers with status badges; click a row to edit, "+ New Paper" to
/// create. The whole list is held in memory and POSTed to /api/admin/papers
/// on save (that endpoint replaces the full set), so save/delete sync the
/// in-memory array and push it.
class AdminResearchPage extends StatelessComponent {
  const AdminResearchPage({super.key});

  static const _script = '''
(function(){
  var API = '/api/admin';
  var \$ = function(s, root){ return (root||document).querySelector(s); };
  var \$\$ = function(s, root){ return Array.from((root||document).querySelectorAll(s)); };

  var listView   = \$('.adm [data-view="list"]');
  var editView   = \$('.adm [data-view="edit"]');
  var paperListEl= \$('.adm [data-paper-list]');
  var newBtn     = \$('.adm [data-new]');
  var backBtn    = \$('.adm [data-back]');
  var currentTitle = \$('.adm [data-current-title]');
  var savedChip  = \$('.adm .topbar .chip');
  var saveBtn    = \$('.adm [data-save]');
  var deleteBtn  = \$('.adm [data-delete]');
  var statusPills = \$\$('.adm [data-status-pill]');
  var visibleSwitch = \$('.adm [data-visible]');
  var metricDisplay = \$('.adm [data-metric-display]');
  var metricDisplayLabel = \$('.adm [data-metric-display-label]');

  var papers = [];
  var currentIdx = -1;
  var dirty = false;
  var deleteArmed = false;

  function setSaveState(state, text){
    if (!savedChip) return;
    savedChip.classList.toggle('on', state === 'saved' || state === 'idle');
    savedChip.classList.toggle('warn', state === 'saving' || state === 'error' || state === 'dirty');
    savedChip.innerHTML = '<span class="dot"></span>' + text;
  }
  function markDirty(){ dirty = true; setSaveState('dirty', 'UNSAVED · غير محفوظ'); }
  function markSaved(){ dirty = false; setSaveState('saved', 'SAVED ✓'); }

  window.addEventListener('beforeunload', function(e){ if (dirty) { e.preventDefault(); e.returnValue=''; } });

  // ---------- view switching ----------
  function showList(){
    if (editView) editView.classList.add('hidden');
    if (listView) listView.classList.remove('hidden');
    if (backBtn) backBtn.classList.add('hidden');
    if (currentTitle) currentTitle.textContent = '';
    setSaveState('idle', 'الأبحاث · RESEARCH');
    renderList();
  }
  function showEdit(idx){
    currentIdx = idx;
    if (listView) listView.classList.add('hidden');
    if (editView) editView.classList.remove('hidden');
    if (backBtn) backBtn.classList.remove('hidden');
    fillForm(papers[idx]);
    var t = papers[idx].title_ar || papers[idx].title_en || ('Paper ' + papers[idx].id);
    if (currentTitle) currentTitle.textContent = t;
  }
  if (backBtn) backBtn.addEventListener('click', function(){
    syncFormToCurrent();
    showList();
  });

  // ---------- list ----------
  function renderList(){
    if (!paperListEl) return;
    paperListEl.innerHTML = '';
    if (!papers.length){
      var empty = document.createElement('div');
      empty.className = 'article-empty';
      empty.textContent = 'لا توجد أبحاث بعد · No papers yet — click + NEW PAPER.';
      paperListEl.appendChild(empty);
      return;
    }
    papers.forEach(function(p, idx){
      var status = (p.status || 'design');
      var row = document.createElement('button');
      row.type = 'button';
      row.className = 'article-row';

      var meta = document.createElement('div');
      meta.className = 'article-row__meta';
      var badge = document.createElement('span');
      badge.className = 'article-row__status is-' + status;
      badge.textContent = status.toUpperCase();
      meta.appendChild(badge);
      if (p.visible === false) {
        var hid = document.createElement('span');
        hid.className = 'article-row__date';
        hid.textContent = 'HIDDEN';
        meta.appendChild(hid);
      }
      if (p.metric) {
        var m = document.createElement('span');
        m.className = 'article-row__date';
        m.textContent = p.metric;
        meta.appendChild(m);
      }

      var title = document.createElement('div');
      title.className = 'article-row__title';
      title.textContent = p.title_ar || p.title_en || ('Paper ' + p.id);

      var sub = document.createElement('div');
      sub.className = 'article-row__slug';
      sub.textContent = '/research/' + p.id;

      row.appendChild(meta);
      row.appendChild(title);
      row.appendChild(sub);
      row.addEventListener('click', function(){ showEdit(idx); });
      paperListEl.appendChild(row);
    });
  }

  if (newBtn) newBtn.addEventListener('click', function(){
    // next numeric id, zero-padded
    var maxId = 0;
    papers.forEach(function(p){ var n = parseInt(p.id, 10); if (!isNaN(n) && n > maxId) maxId = n; });
    var newPaper = {
      id: String(maxId + 1).padStart(2, '0'),
      status: 'design', pill_label: 'in design',
      title_ar: '(بحث جديد)', title_en: '(new paper)',
      metric: '', metric_label: '', caption: '', url: '',
      order: papers.length + 1, visible: true, abstract: ''
    };
    papers.push(newPaper);
    markDirty();
    showEdit(papers.length - 1);
  });

  // ---------- editor form ----------
  function fillForm(p){
    \$\$('.adm [data-field]').forEach(function(el){
      var k = el.dataset.field;
      if (el.type === 'checkbox') el.checked = !!p[k];
      else el.value = (p[k] != null) ? p[k] : '';
    });
    setStatus(p.status || 'design');
    if (visibleSwitch) visibleSwitch.checked = p.visible !== false;
    updateMetricDisplay();
    attachDirtyListeners();
  }

  function setStatus(s){
    statusPills.forEach(function(b){ b.classList.toggle('on', b.dataset.statusPill === s); });
  }
  statusPills.forEach(function(b){
    b.addEventListener('click', function(){
      setStatus(b.dataset.statusPill);
      var pillField = \$('.adm [data-field="pill_label"]');
      if (pillField && !pillField.dataset.dirty) {
        pillField.value = ({published:'published', active:'in field', design:'in design'})[b.dataset.statusPill] || b.dataset.statusPill;
      }
      markDirty();
    });
  });

  function updateMetricDisplay(){
    var m = \$('.adm [data-field="metric"]');
    var ml = \$('.adm [data-field="metric_label"]');
    if (metricDisplay && m) metricDisplay.textContent = m.value || '—';
    if (metricDisplayLabel && ml) metricDisplayLabel.textContent = ml.value || '';
  }

  function readForm(){
    var paper = {};
    \$\$('.adm [data-field]').forEach(function(el){
      var k = el.dataset.field;
      if (el.type === 'checkbox') paper[k] = el.checked;
      else if (el.type === 'number') paper[k] = el.value ? Number(el.value) : 0;
      else paper[k] = el.value;
    });
    var on = statusPills.find(function(b){ return b.classList.contains('on'); });
    if (on) paper.status = on.dataset.statusPill;
    if (visibleSwitch) paper.visible = visibleSwitch.checked;
    return paper;
  }

  function syncFormToCurrent(){
    if (currentIdx < 0) return;
    var existing = papers[currentIdx] || {};
    papers[currentIdx] = Object.assign({}, existing, readForm());
  }

  function loadAll(){
    setSaveState('saving', 'LOADING');
    return window.adminFetch(API + '/papers').then(function(r){ return r.json(); }).then(function(data){
      papers = (data && data.papers) || [];
      showList();
    }).catch(function(e){
      setSaveState('error', 'LOAD ERROR');
      console.error('load failed', e);
    });
  }

  function save(){
    syncFormToCurrent();
    setSaveState('saving', 'SAVING...');
    window.adminFetch(API + '/papers', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ papers: papers })
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.ok) {
        if (res.papers) papers = res.papers;
        markSaved();
        if (currentIdx >= 0 && papers[currentIdx] && currentTitle) {
          currentTitle.textContent = papers[currentIdx].title_ar || papers[currentIdx].title_en || ('Paper ' + papers[currentIdx].id);
        }
        showRebuildNote();
      } else {
        setSaveState('error', 'SAVE ERROR'); console.error(res);
      }
    }).catch(function(e){
      setSaveState('error', 'SAVE ERROR'); console.error('save failed', e);
    });
  }

  function showRebuildNote(){
    var note = \$('.adm [data-publish-note]');
    if (!note) return;
    note.innerHTML = '✓ تم الحفظ · Saved. The site is rebuilding — changes will be live at '
      + '<a href="/" target="_blank" rel="noopener">smalibary.me</a> in about 90 seconds. '
      + '<span class="countdown"></span>';
    note.classList.add('show');
    var left = 90;
    var cd = note.querySelector('.countdown');
    if (note._timer) clearInterval(note._timer);
    note._timer = setInterval(function(){
      left -= 1;
      if (cd) cd.textContent = left > 0 ? '(~' + left + 's)' : '(should be live now — refresh)';
      if (left <= 0) clearInterval(note._timer);
    }, 1000);
  }

  function attachDirtyListeners(){
    \$\$('.adm [data-field]').forEach(function(el){
      el.removeEventListener('input', markDirty);
      el.addEventListener('input', function(){ markDirty(); updateMetricDisplay(); });
      if (el.type === 'checkbox') el.addEventListener('change', markDirty);
    });
    if (visibleSwitch) { visibleSwitch.removeEventListener('change', markDirty); visibleSwitch.addEventListener('change', markDirty); }
  }

  if (saveBtn) saveBtn.addEventListener('click', save);

  if (deleteBtn) deleteBtn.addEventListener('click', function(){
    if (currentIdx < 0) return;
    if (!deleteArmed) {
      deleteArmed = true;
      var orig = deleteBtn.textContent;
      deleteBtn.textContent = 'CONFIRM DELETE ⚠';
      deleteBtn.classList.add('armed');
      setTimeout(function(){ deleteArmed = false; deleteBtn.textContent = orig; deleteBtn.classList.remove('armed'); }, 4000);
      return;
    }
    papers.splice(currentIdx, 1);
    currentIdx = -1;
    save();        // persist the deletion (POSTs the trimmed list)
    showList();
  });

  window.__adminReady.then(loadAll);
})();
''';

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'research',
      body: [
        header(classes: 'topbar', [
          div(classes: 'topbar-l', [
            button(
              classes: 'back-btn hidden',
              attributes: const {'data-back': '', 'type': 'button'},
              [text('← الأبحاث · ALL PAPERS')],
            ),
            div(classes: 'section-name', [text('الأبحاث · RESEARCH')]),
            div(classes: 'current-title', attributes: const {'data-current-title': ''}, []),
          ]),
          div(classes: 'topbar-r', [
            a(
              href: '/',
              classes: 'view-site',
              attributes: const {'target': '_blank', 'rel': 'noopener', 'title': 'View public site'},
              [
                raw(
                  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'
                  '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>'
                  '<polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>',
                ),
                span([text('VIEW')]),
              ],
            ),
            div(classes: 'chip on', [span(classes: 'dot', []), text('الأبحاث')]),
          ]),
        ]),

        main_(classes: 'main', [
          // ===== LIST VIEW =====
          div(attributes: const {'data-view': 'list'}, [
            AdminPageHeader(
              eyebrow: 'SECTION · RESEARCH',
              titleAr: 'الأبحاث',
              subtitle: 'PAPERS · click a row to edit',
              action: button(
                classes: 'btn',
                attributes: const {'data-new': '', 'type': 'button'},
                [text('+ بحث جديد · NEW PAPER')],
              ),
            ),
            div(classes: 'article-list', attributes: const {'data-paper-list': ''}, []),
          ]),

          // ===== EDIT VIEW (hidden) =====
          div(classes: 'hidden', attributes: const {'data-view': 'edit'}, [
            div(classes: 'visibility', [
              div(classes: 'visibility-l', [
                b([text('ظاهر ف الصفحة الرئيسية')]),
                span([text('VISIBLE ON HOMEPAGE')]),
              ]),
              label(classes: 'switch', [
                input(type: InputType.checkbox, attributes: const {'data-visible': ''}),
                span([]),
              ]),
            ]),

            div(classes: 'metric-display', [
              b(attributes: const {'data-metric-display': ''}, [text('—')]),
              span(attributes: const {'data-metric-display-label': ''}, []),
            ]),

            div(classes: 'row', [
              _field('العنوان بالعربي', '', 'title_ar', required: true),
              _field('', 'TITLE · ENGLISH', 'title_en', required: true),
            ]),

            div(classes: 'field', [
              label([text('الحالة · STATUS '), span(classes: 'req', [text('*')])]),
              div(classes: 'status-row', [
                _statusPill('published', 'PUBLISHED · منشور'),
                _statusPill('active', 'ACTIVE · قيد العمل'),
                _statusPill('design', 'DESIGN · تصميم'),
              ]),
            ]),

            div(classes: 'row', [
              _field('المقياس · METRIC', '', 'metric', hint: 'Big number on the card'),
              _field('وصف المقياس · METRIC LABEL', '', 'metric_label'),
            ]),
            div(classes: 'row', [
              _field('التسمية · CAPTION', '', 'caption'),
              _field('الترتيب · ORDER', '', 'order', type: InputType.number),
            ]),
            _field('رابط الورقة · URL', '', 'url', type: InputType.url),
            _field('PILL LABEL', '', 'pill_label', hint: 'auto-filled when status changes'),
            _textarea('الملخص · ABSTRACT', '', 'abstract', rows: 6),

            div(classes: 'actions', [
              button(
                classes: 'btn danger',
                attributes: const {'data-delete': '', 'type': 'button'},
                [text('حذف · DELETE')],
              ),
              div(classes: 'flex-1', []),
              button(
                classes: 'btn',
                attributes: const {'data-save': '', 'type': 'button'},
                [text('حفظ · SAVE')],
              ),
            ]),
            div(classes: 'publish-note', attributes: const {'data-publish-note': ''}, []),
          ]),
        ]),

        script(content: _script),
      ],
    );
  }

  Component _statusPill(String value, String label) {
    return button(
      classes: 'status-pill',
      attributes: {'data-status-pill': value, 'type': 'button'},
      [text(label)],
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
        if (required) span(classes: 'req', [text(' *')]),
      ]),
      input(type: type, attributes: {'data-field': fieldName}),
      if (hint != null) div(classes: 'hint', [text(hint)]),
    ]);
  }

  Component _textarea(String labelAr, String labelEn, String fieldName, {int rows = 5}) {
    return div(classes: 'field', [
      label([
        if (labelAr.isNotEmpty) text(labelAr),
        if (labelEn.isNotEmpty) text(labelEn),
      ]),
      textarea(attributes: {'data-field': fieldName, 'rows': rows.toString()}, []),
    ]);
  }
}
