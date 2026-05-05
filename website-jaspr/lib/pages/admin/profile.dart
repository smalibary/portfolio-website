import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../components/admin/admin_shell.dart';
import '../../components/admin/topbar.dart';

/// Profile editor. Form is empty at SSR time; inline JS fetches the API on
/// load and populates fields. Save button POSTs back to the same endpoint.
class AdminProfilePage extends StatelessComponent {
  const AdminProfilePage({super.key});

  static const _api = 'http://localhost:9090';

  static const _script = '''
(function(){
  var API = '$_api/api/profile';
  var UPLOAD = '$_api/api/upload';
  var \$ = function(s, root){ return (root||document).querySelector(s); };
  var \$\$ = function(s, root){ return Array.from((root||document).querySelectorAll(s)); };
  var savedChip = \$('.adm .topbar .chip');
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
  function renderSocials(list){
    if (!socialsTarget) return;
    socialsTarget.innerHTML = '';
    (list || []).forEach(function(s){ socialsTarget.appendChild(buildSocialRow(s)); });
  }
  function readSocials(){
    if (!socialsTarget) return [];
    return \$\$('.socials', socialsTarget).map(function(row){
      return {
        platform: (\$('.platform', row).textContent || '').trim().toLowerCase(),
        url: \$('input', row).value
      };
    });
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
  \$\$('.adm [data-upload]').forEach(function(btn){
    btn.addEventListener('click', function(){
      var slot = btn.dataset.upload; // 'dark' | 'light'
      var fileInput = \$('.adm [data-upload-input="' + slot + '"]');
      if (fileInput) fileInput.click();
    });
  });
  \$\$('.adm [data-upload-input]').forEach(function(input){
    input.addEventListener('change', function(){
      var file = input.files && input.files[0];
      if (!file) return;
      var slot = input.dataset.uploadInput; // 'dark' | 'light'
      var targetField = \$('.adm [data-field="photo_' + slot + '"]');
      var status = \$('.adm [data-upload-status="' + slot + '"]');
      if (status) status.textContent = 'UPLOADING...';
      var reader = new FileReader();
      reader.onload = function(){
        var b64 = reader.result.split(',')[1];
        fetch(UPLOAD, {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({ filename: file.name, base64: b64 })
        }).then(function(r){ return r.json(); }).then(function(res){
          if (res.ok && res.filename) {
            if (targetField) { targetField.value = res.filename; markDirty(); }
            if (status) status.textContent = 'UPLOADED · ' + res.filename;
          } else {
            if (status) status.textContent = 'UPLOAD ERROR';
            console.error(res);
          }
        }).catch(function(e){
          if (status) status.textContent = 'UPLOAD ERROR';
          console.error(e);
        });
      };
      reader.readAsDataURL(file);
    });
  });

  // ---- load / save ----
  function load(){
    setSaveState('saving', 'LOADING');
    fetch(API).then(function(r){ return r.json(); }).then(function(data){
      \$\$('.adm [data-field]').forEach(function(el){
        var key = el.dataset.field;
        if (data[key] != null) el.value = data[key];
      });
      renderSocials(data.socials);
      renderHeroMeta(data.hero_meta);
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
    fetch(API, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(payload)
    }).then(function(r){ return r.json(); }).then(function(res){
      if (res.ok) setSaveState('saved', 'SAVED ✓');
      else { setSaveState('error', 'SAVE ERROR'); console.error(res); }
    }).catch(function(e){
      setSaveState('error', 'SAVE ERROR');
      console.error('save failed:', e);
    });
  }

  if (saveBtn) saveBtn.addEventListener('click', save);
  load();
})();
''';

  @override
  Component build(BuildContext context) {
    return AdminShell(
      current: 'profile',
      body: [
        AdminTopbar(sectionAr: 'الملف الشخصي', sectionEn: 'PROFILE'),
        main_(classes: 'main', [
          header(classes: 'head', [
            div([
              div(classes: 'eyebrow', [text('SECTION · IDENTITY')]),
              h1([text('الهوية و الروابط')]),
              div(classes: 'en', [text('READS/WRITES content/_data/site.yaml')]),
            ]),
          ]),

          // Identity (name + tagline + photos)
          div(classes: 'card', styles: Styles(raw: {'margin-bottom': '20px'}), [
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
          div(classes: 'card', styles: Styles(raw: {'margin-bottom': '20px'}), [
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
          div(classes: 'card', styles: Styles(raw: {'margin-bottom': '20px'}), [
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
            div(classes: 'actions', [
              button(classes: 'btn ghost', [text('إلغاء · CANCEL')]),
              button(
                classes: 'btn',
                attributes: const {'data-save': '', 'type': 'button'},
                [text('حفظ التغييرات · SAVE')],
              ),
            ]),
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
