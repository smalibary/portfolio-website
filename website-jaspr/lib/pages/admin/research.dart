import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';

/// Research editor. Single-file API (`/api/papers`) — the editor holds the
/// whole paper list in memory and POSTs it back on save. UX mirrors the blog
/// editor: picker, dirty chip, save/delete.
class AdminResearchPage extends StatelessComponent {
  const AdminResearchPage({super.key});

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
  var saveBtn     = \$('.adm [data-save]');
  var publishBtn  = \$('.adm [data-publish]');
  var deleteBtn   = \$('.adm [data-delete]');
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

  // picker open/close
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
      e.preventDefault(); pickerBtn.classList.toggle('open');
      if (pickerBtn.classList.contains('open') && pickerSearch) pickerSearch.focus();
    }
    if (e.key === 'Escape') pickerBtn.classList.remove('open');
  });

  if (pickerSearch) pickerSearch.addEventListener('input', renderPicker);
  if (pickerNew) pickerNew.addEventListener('click', function(){
    var newPaper = {
      id: String(papers.length + 1).padStart(2, '0'),
      status: 'design', pill_label: 'in design',
      title_ar: '(بحث جديد)', title_en: '(new paper)',
      metric: '', metric_label: '', caption: '', url: '',
      order: papers.length + 1, visible: true, abstract: ''
    };
    papers.push(newPaper);
    currentIdx = papers.length - 1;
    pickerBtn.classList.remove('open');
    fillForm(newPaper);
    markDirty();
    renderPicker();
  });

  function renderPicker(){
    if (!pickerList) return;
    var q = (pickerSearch && pickerSearch.value || '').toLowerCase();
    pickerList.innerHTML = '';
    var filtered = papers.map(function(p, i){ return {p:p, i:i}; }).filter(function(o){
      if (!q) return true;
      return ((o.p.title_ar||'') + ' ' + (o.p.title_en||'') + ' ' + (o.p.id||'')).toLowerCase().indexOf(q) !== -1;
    });
    if (filtered.length === 0) {
      var empty = document.createElement('div');
      empty.style.padding = '20px'; empty.style.textAlign = 'center'; empty.style.color = 'var(--color-text-faint)';
      empty.style.fontFamily = 'JetBrains Mono, monospace'; empty.style.fontSize = '12px';
      empty.textContent = 'NO PAPERS MATCH';
      pickerList.appendChild(empty);
      return;
    }
    filtered.forEach(function(o){
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'pick-item' + (o.i === currentIdx ? ' active' : '');
      var meta = document.createElement('div'); meta.className = 'pick-meta';
      meta.textContent = (o.p.status||'').toUpperCase() + ' · ORDER ' + (o.p.order||'?') + (o.p.visible === false ? ' · HIDDEN' : '');
      var title = document.createElement('div'); title.className = 'pick-title';
      title.textContent = o.p.title_ar || o.p.title_en || ('Paper ' + o.p.id);
      var body = document.createElement('div'); body.className = 'pick-body';
      body.appendChild(meta); body.appendChild(title);
      btn.appendChild(body);
      btn.addEventListener('click', function(){
        if (dirty && o.i !== currentIdx) {
          syncFormToCurrent(); // preserve unsaved edit in memory
        }
        currentIdx = o.i;
        pickerBtn.classList.remove('open');
        fillForm(papers[o.i]);
        renderPicker();
        if (pickerTitle) pickerTitle.textContent = papers[o.i].title_ar || papers[o.i].title_en || ('Paper ' + papers[o.i].id);
      });
      pickerList.appendChild(btn);
    });
  }

  function fillForm(p){
    \$\$('.adm [data-field]').forEach(function(el){
      var k = el.dataset.field;
      if (el.type === 'checkbox') el.checked = !!p[k];
      else el.value = (p[k] != null) ? p[k] : '';
    });
    setStatus(p.status || 'design');
    if (visibleSwitch) visibleSwitch.checked = p.visible !== false;
    updateMetricDisplay();
  }

  function setStatus(s){
    statusPills.forEach(function(b){ b.classList.toggle('on', b.dataset.statusPill === s); });
  }
  statusPills.forEach(function(b){
    b.addEventListener('click', function(){
      setStatus(b.dataset.statusPill);
      // also auto-set pill_label based on status
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
    return fetch(API + '/api/papers').then(function(r){ return r.json(); }).then(function(data){
      papers = (data && data.papers) || [];
      if (papers.length > 0) {
        currentIdx = 0;
        fillForm(papers[0]);
        if (pickerTitle) pickerTitle.textContent = papers[0].title_ar || papers[0].title_en || ('Paper ' + papers[0].id);
      } else {
        currentIdx = -1;
        if (pickerTitle) pickerTitle.textContent = '(no papers — click + NEW)';
      }
      renderPicker();
      attachDirtyListeners();
      markSaved();
    }).catch(function(e){
      setSaveState('error', 'LOAD ERROR');
      console.error('load failed', e);
    });
  }

  function save(){
    syncFormToCurrent();
    setSaveState('saving', 'SAVING...');
    fetch(API + '/api/papers', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ papers: papers })
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.ok) {
        markSaved();
        renderPicker();
        if (currentIdx >= 0 && pickerTitle) {
          pickerTitle.textContent = papers[currentIdx].title_ar || papers[currentIdx].title_en || ('Paper ' + papers[currentIdx].id);
        }
      } else {
        setSaveState('error', 'SAVE ERROR'); console.error(res);
      }
    }).catch(function(e){
      setSaveState('error', 'SAVE ERROR'); console.error('save failed', e);
    });
  }

  function attachDirtyListeners(){
    \$\$('.adm [data-field]').forEach(function(el){
      el.removeEventListener('input', markDirty);
      el.removeEventListener('change', markDirty);
      el.addEventListener('input', function(){ markDirty(); updateMetricDisplay(); });
      if (el.type === 'checkbox') el.addEventListener('change', markDirty);
    });
    if (visibleSwitch) visibleSwitch.addEventListener('change', markDirty);
  }

  if (saveBtn) saveBtn.addEventListener('click', save);
  if (publishBtn) publishBtn.addEventListener('click', save);

  if (deleteBtn) deleteBtn.addEventListener('click', function(){
    if (currentIdx < 0) return;
    if (!deleteArmed) {
      deleteArmed = true;
      var orig = deleteBtn.textContent;
      deleteBtn.textContent = 'CONFIRM DELETE ⚠';
      setTimeout(function(){ deleteArmed = false; deleteBtn.textContent = orig; }, 4000);
      return;
    }
    papers.splice(currentIdx, 1);
    currentIdx = papers.length > 0 ? 0 : -1;
    if (currentIdx >= 0) fillForm(papers[currentIdx]);
    renderPicker();
    save();
  });

  loadAll();
})();
''';

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'research',
      body: [
        // Custom topbar with picker
        header(classes: 'topbar', [
          div(classes: 'topbar-l', [
            div(classes: 'picker', [
              button(
                classes: 'picker-btn',
                attributes: const {'data-picker-btn': '', 'type': 'button'},
                [
                  div(classes: 'picker-icon', [
                    raw(
                      '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">'
                      '<path d="M9 3v6l-5 9a3 3 0 0 0 3 4h10a3 3 0 0 0 3-4l-5-9V3"/><path d="M8 3h8"/></svg>',
                    ),
                  ]),
                  div(classes: 'picker-meta', [
                    div(classes: 'picker-section', [text('RESEARCH · PAPER')]),
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
                    attributes: const {'data-picker-search': '', 'placeholder': 'ابحث ف الأبحاث...'},
                  ),
                ]),
                div(classes: 'picker-list', attributes: const {'data-picker-list': ''}, []),
                div(classes: 'picker-foot', [
                  button(
                    classes: 'picker-new',
                    attributes: const {'data-picker-new': '', 'type': 'button'},
                    [text('+ بحث جديد · NEW PAPER')],
                  ),
                  span(classes: 'picker-hint', [
                    raw('<kbd>↑↓</kbd> nav <kbd>↵</kbd> open <kbd>esc</kbd> close'),
                  ]),
                ]),
              ]),
            ]),
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
                span([text('VIEW SITE')]),
              ],
            ),
            div(classes: 'chip on', [span(classes: 'dot', []), text('SAVED')]),
            button(
              classes: 'btn',
              attributes: const {'data-publish': '', 'type': 'button'},
              [text('حفظ · SAVE')],
            ),
          ]),
        ]),

        main_(classes: 'main', [
          // Visibility row
          div(classes: 'visibility', [
            div(classes: 'visibility-l', [
              b([text('ظاهر ف الصفحة الرئيسية')]),
              span([text('VISIBLE ON HOMEPAGE')]),
            ]),
            label(classes: 'switch', [
              input(
                type: InputType.checkbox,
                attributes: const {'data-visible': ''},
              ),
              span([]),
            ]),
          ]),

          // Live metric preview
          div(classes: 'metric-display', [
            b(attributes: const {'data-metric-display': ''}, [text('—')]),
            span(attributes: const {'data-metric-display-label': ''}, []),
          ]),

          // Form
          div(classes: 'row', [
            _field('العنوان بالعربي', '', 'title_ar', required: true),
            _field('', 'TITLE · ENGLISH', 'title_en', required: true),
          ]),

          // Status
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

          // Actions
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
              [text('حفظ التغييرات · SAVE')],
            ),
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
