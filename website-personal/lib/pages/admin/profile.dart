import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';
import '../../components/admin/page_header.dart';

/// Profile editor. Form is empty at SSR time; inline JS fetches the API on
/// load and populates fields. Save button POSTs back to the same endpoint.
class AdminProfilePage extends StatelessComponent {
  const AdminProfilePage({super.key});

  static const _script = '''
(function(){
  var API = '/api/admin/profile';
  // Image upload via Supabase Storage is a v2 feature; for now the photo
  // fields take a plain filename that lives under web/images/.
  var UPLOAD = null;
  var \$ = function(s, root){ return (root||document).querySelector(s); };
  var \$\$ = function(s, root){ return Array.from((root||document).querySelectorAll(s)); };
  var savedChip = \$('.adm .topbar .chip');
  var currentTitle = \$('.adm [data-current-title]');
  var saveBtn = \$('.adm [data-save]');
  var socialsTarget = \$('.adm [data-socials]');
  var addSocialBtn = \$('.adm [data-add-social]');
  var heroMetaTarget = \$('.adm [data-hero-meta]');
  var addHeroMetaBtn = \$('.adm [data-add-hero-meta]');

  function setSaveState(state, text){
    if (!savedChip) return;
    savedChip.classList.toggle('on', state === 'saved' || state === 'idle');
    savedChip.classList.toggle('warn', state === 'saving' || state === 'error' || state === 'dirty');
    savedChip.innerHTML = '<span class="dot"></span>' + text;
  }
  function markDirty(){ setSaveState('dirty', 'UNSAVED · غير محفوظ'); }
  function attachDirtyListeners(){
    \$\$('.adm [data-field]').forEach(function(el){ el.addEventListener('input', markDirty); });
    [socialsTarget, heroMetaTarget].forEach(function(t){
      if (!t) return;
      t.addEventListener('input', markDirty);
      t.addEventListener('click', function(e){
        if (e.target && e.target.classList && e.target.classList.contains('icon-btn')) markDirty();
      });
    });
    [addSocialBtn, addHeroMetaBtn].forEach(function(b){
      if (b) b.addEventListener('click', markDirty);
    });
  }
  window.addEventListener('beforeunload', function(e){
    if (savedChip && savedChip.classList.contains('warn') && savedChip.textContent.indexOf('UNSAVED') !== -1) {
      e.preventDefault(); e.returnValue = '';
    }
  });

  // ---- socials ----
  function buildSocialRow(s){
    var row = document.createElement('div');
    row.className = 'socials';
    var p = document.createElement('div'); p.className = 'platform'; p.textContent = (s.platform||'').toUpperCase();
    var i = document.createElement('input'); i.type = 'url'; i.value = s.url || '';
    var b = document.createElement('button'); b.className = 'icon-btn'; b.type = 'button'; b.textContent = '×';
    b.addEventListener('click', function(){ row.remove(); });
    row.appendChild(p); row.appendChild(i); row.appendChild(b);
    return row;
  }
  // Supabase stores socials as a map { platform -> url }. The editor uses
  // a list of rows for ergonomics; we translate at the boundary.
  function renderSocials(socialsMap){
    if (!socialsTarget) return;
    socialsTarget.innerHTML = '';
    var entries = [];
    if (socialsMap && typeof socialsMap === 'object' && !Array.isArray(socialsMap)) {
      Object.keys(socialsMap).forEach(function(p){
        entries.push({ platform: p, url: socialsMap[p] });
      });
    } else if (Array.isArray(socialsMap)) {
      // Tolerate legacy list shape so old payloads still render.
      entries = socialsMap;
    }
    entries.forEach(function(s){ socialsTarget.appendChild(buildSocialRow(s)); });
  }
  function readSocials(){
    if (!socialsTarget) return {};
    var out = {};
    \$\$('.socials', socialsTarget).forEach(function(row){
      var platform = (\$('.platform', row).textContent || '').trim().toLowerCase();
      var url = \$('input', row).value;
      if (platform) out[platform] = url;
    });
    return out;
  }
  if (addSocialBtn) addSocialBtn.addEventListener('click', function(){
    var p = prompt('platform name (e.g. mastodon)');
    if (!p) return;
    socialsTarget.appendChild(buildSocialRow({platform: p, url: ''}));
  });

  // ---- hero_meta ----
  function buildHeroMetaRow(m){
    var row = document.createElement('div');
    row.className = 'meta-row';
    var l = document.createElement('input'); l.type = 'text'; l.value = m.label || ''; l.placeholder = 'الدكتوراه:'; l.dataset.metaField = 'label';
    var v = document.createElement('input'); v.type = 'text'; v.value = m.value || ''; v.placeholder = 'جامعة سيدني · مختبر البيئة الداخلية'; v.dataset.metaField = 'value';
    var b = document.createElement('button'); b.className = 'icon-btn'; b.type = 'button'; b.textContent = '×';
    b.addEventListener('click', function(){ row.remove(); });
    row.appendChild(l); row.appendChild(v); row.appendChild(b);
    return row;
  }
  function renderHeroMeta(list){
    if (!heroMetaTarget) return;
    heroMetaTarget.innerHTML = '';
    (list || []).forEach(function(m){ heroMetaTarget.appendChild(buildHeroMetaRow(m)); });
  }
  function readHeroMeta(){
    if (!heroMetaTarget) return [];
    return \$\$('.meta-row', heroMetaTarget).map(function(row){
      var inputs = \$\$('input', row);
      return { label: inputs[0].value, value: inputs[1].value };
    });
  }
  if (addHeroMetaBtn) addHeroMetaBtn.addEventListener('click', function(){
    heroMetaTarget.appendChild(buildHeroMetaRow({label: '', value: ''}));
  });

  // ---- photo upload ----
  // Image upload via Supabase Storage is a v2 feature. For now the upload
  // buttons surface a hint to set the filename manually; the photo files
  // continue to live in web/images/ and are served as static assets.
  \$\$('.adm [data-upload]').forEach(function(btn){
    btn.addEventListener('click', function(){
      var slot = btn.dataset.upload;
      var status = \$('.adm [data-upload-status="' + slot + '"]');
      if (status) status.textContent = 'UPLOAD COMING SOON · type filename into the field';
    });
  });

  // ---- load / save ----
  function load(){
    setSaveState('saving', 'LOADING');
    window.adminFetch(API)
      .then(function(r){
        if (r.status === 401) { window.location.replace('/admin/login'); return null; }
        return r.json();
      })
      .then(function(data){
        if (!data) return;
        \$\$('.adm [data-field]').forEach(function(el){
          var key = el.dataset.field;
          if (data[key] != null) el.value = data[key];
        });
        renderSocials(data.socials);
        renderHeroMeta(data.hero_meta);
        if (currentTitle) currentTitle.textContent = data.name_ar || data.name_en || '';
        setSaveState('saved', 'SAVED');
        attachDirtyListeners();
      }).catch(function(e){
        setSaveState('error', 'LOAD ERROR');
        console.error('load failed:', e);
      });
  }

  function save(){
    setSaveState('saving', 'SAVING...');
    var payload = {};
    \$\$('.adm [data-field]').forEach(function(el){ payload[el.dataset.field] = el.value; });
    payload.socials = readSocials();
    payload.hero_meta = readHeroMeta();
    window.adminFetch(API, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(payload)
    }).then(function(r){
      if (r.status === 401) { window.location.replace('/admin/login'); return null; }
      return r.json();
    }).then(function(res){
      if (!res) return;
      if (res.ok) setSaveState('saved', 'SAVED ✓');
      else { setSaveState('error', 'SAVE ERROR'); console.error(res); }
    }).catch(function(e){
      setSaveState('error', 'SAVE ERROR');
      console.error('save failed:', e);
    });
  }

  if (saveBtn) saveBtn.addEventListener('click', save);
  window.__adminReady.then(load);
})();
''';

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'profile',
      body: [
        // Singleton editor — same topbar chrome as blog/research, minus the
        // back button (there's no list to return to).
        header(classes: 'topbar', [
          div(classes: 'topbar-l', [
            div(classes: 'section-name', [text('الملف الشخصي · PROFILE')]),
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
            div(classes: 'chip on', [span(classes: 'dot', []), text('الملف')]),
          ]),
        ]),
        main_(classes: 'main', [
          const AdminPageHeader(
            eyebrow: 'SECTION · IDENTITY',
            titleAr: 'الهوية و الروابط',
            subtitle: 'PROFILE · portfolio.profile',
          ),

          // Identity (name + tagline + photos)
          div(classes: 'card card--spaced', [
            div(classes: 'card-head', [
              h2([text('الهوية')]),
              div(classes: 'en', [text('IDENTITY')]),
            ]),
            div(classes: 'photos', [
              _photoSlot('dark', 'DARK MODE', 'salem-dark.jpg'),
              _photoSlot('light', 'LIGHT MODE', 'salem-light.png'),
            ]),
            div(classes: 'row', [
              _field('الاسم بالعربي', '', 'name_ar', required: true),
              _field('', 'NAME · ENGLISH', 'name_en', required: true),
            ]),
            div(classes: 'row', [
              _field('الوصف المختصر', '', 'tagline_ar'),
              _field('', 'TAGLINE · ENGLISH', 'tagline_en'),
            ]),
          ]),

          // Hero copy
          div(classes: 'card card--spaced', [
            div(classes: 'card-head', [
              h2([text('نص الصفحة الرئيسية')]),
              div(classes: 'en', [text('HERO COPY')]),
            ]),
            _field(
              'سطر الحالة · STATUS LINE',
              '',
              'status_line',
              hint: 'shown above your name on the homepage',
            ),
            _textarea(
              'الوصف بالعربي · LEDE (AR)',
              '',
              'lede_ar',
              hint: 'wrap a phrase in *asterisks* to render it as emphasis',
            ),
            _textarea(
              'الوصف بالإنجليزي · LEDE (EN)',
              '',
              'lede_en',
              hint: 'wrap a phrase in *asterisks* to render it as emphasis',
            ),

            // hero meta items (dynamic list)
            div(classes: 'field', [
              label([text('بيانات إضافية · META ITEMS')]),
              div(classes: 'meta-list', attributes: const {'data-hero-meta': ''}, []),
              button(
                classes: 'add-row',
                attributes: const {'data-add-hero-meta': '', 'type': 'button'},
                [text('+ إضافة عنصر · ADD ITEM')],
              ),
            ]),
          ]),

          // Bio
          div(classes: 'card card--spaced', [
            div(classes: 'card-head', [
              h2([text('النبذة')]),
              div(classes: 'en', [text('BIO')]),
            ]),
            _textarea('النبذة بالعربي', '', 'bio_ar'),
            _textarea('', 'BIO · ENGLISH', 'bio_en'),
          ]),

          // Socials
          div(classes: 'card', [
            div(classes: 'card-head', [
              h2([text('الروابط الاجتماعية')]),
              div(classes: 'en', [text('SOCIAL LINKS')]),
            ]),
            div(attributes: const {'data-socials': ''}, []),
            button(
              classes: 'add-row',
              attributes: const {'data-add-social': '', 'type': 'button'},
              [text('+ إضافة رابط · ADD LINK')],
            ),
          ]),

          // Action bar — top-level, like the blog/research editors.
          div(classes: 'actions', [
            button(classes: 'btn ghost', [text('إلغاء · CANCEL')]),
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

  Component _photoSlot(String slot, String labelEn, String placeholder) {
    return div(classes: 'photo-slot', [
      div(classes: 'avatar avatar--$slot', []),
      div(classes: 'photo-slot-meta', [
        div(classes: 'photo-slot-label', [text(labelEn)]),
        input(
          type: InputType.text,
          attributes: {'data-field': 'photo_$slot', 'placeholder': placeholder},
        ),
        div(
          classes: 'photo-slot-status',
          attributes: {'data-upload-status': slot},
          [],
        ),
      ]),
      button(
        classes: 'btn ghost',
        attributes: {'data-upload': slot, 'type': 'button'},
        [text('رفع · UPLOAD')],
      ),
      input(
        type: InputType.file,
        attributes: {
          'data-upload-input': slot,
          'accept': 'image/*',
          'style': 'display:none;',
        },
      ),
    ]);
  }

  Component _field(
    String labelAr,
    String labelEn,
    String fieldName, {
    bool required = false,
    String? hint,
  }) {
    return div(classes: 'field', [
      label([
        if (labelAr.isNotEmpty) text(labelAr),
        if (labelEn.isNotEmpty) text(labelEn),
        if (required) span(classes: 'req', [text('*')]),
      ]),
      input(
        type: InputType.text,
        attributes: {'data-field': fieldName},
      ),
      if (hint != null) div(classes: 'hint', [text(hint)]),
    ]);
  }

  Component _textarea(
    String labelAr,
    String labelEn,
    String fieldName, {
    String? hint,
  }) {
    return div(classes: 'field', [
      label([
        if (labelAr.isNotEmpty) text(labelAr),
        if (labelEn.isNotEmpty) text(labelEn),
      ]),
      textarea(attributes: {'data-field': fieldName, 'rows': '5'}, []),
      if (hint != null) div(classes: 'hint', [text(hint)]),
    ]);
  }
}
