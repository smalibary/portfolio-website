import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Admin login. Cosmetic passcode gate (1379) — see CLAUDE.md for why this is
/// not real auth. On correct submit: sets `sessionStorage['admin-auth'] = 'ok'`
/// and redirects to `/admin/profile`. Other admin pages will check that flag
/// and bounce to here if it's missing.
class AdminLoginPage extends StatelessComponent {
  const AdminLoginPage({super.key});

  static const _script = '''
(function(){
  var pins = document.querySelectorAll('.adm .pin input');
  var btn = document.querySelector('.adm .login-btn');
  var err = document.querySelector('.adm .login-error');
  var tBtns = document.querySelectorAll('.adm [data-theme-set]');

  // theme toggle (matches the public site's localStorage key 'salem-theme')
  function applyTheme(t){
    document.documentElement.setAttribute('data-theme', t);
    localStorage.setItem('salem-theme', t);
    tBtns.forEach(function(b){
      b.classList.toggle('active', b.getAttribute('data-theme-set') === t);
    });
  }
  var current = localStorage.getItem('salem-theme') || 'dark';
  applyTheme(current);
  tBtns.forEach(function(b){
    b.addEventListener('click', function(){ applyTheme(b.getAttribute('data-theme-set')); });
  });

  // pin behaviour
  pins.forEach(function(p, i){
    p.addEventListener('input', function(e){
      var v = e.target.value;
      if (v && !/^[0-9]\$/.test(v)) { e.target.value = ''; return; }
      if (v) {
        e.target.classList.add('filled');
        if (pins[i+1]) pins[i+1].focus();
        else attemptSubmit();
      } else {
        e.target.classList.remove('filled');
      }
    });
    p.addEventListener('keydown', function(e){
      if (e.key === 'Backspace' && !e.target.value && pins[i-1]) pins[i-1].focus();
    });
  });

  function attemptSubmit(){
    var code = Array.from(pins).map(function(p){ return p.value; }).join('');
    if (code.length !== 4) return;
    if (code === '1379') {
      try { sessionStorage.setItem('admin-auth', 'ok'); } catch(e) {}
      window.location.href = '/admin/profile';
    } else {
      err.classList.add('show');
      err.textContent = 'الرقم غير صحيح · WRONG PASSCODE';
      pins.forEach(function(p){ p.classList.remove('filled'); p.classList.add('error'); p.value = ''; });
      setTimeout(function(){ pins.forEach(function(p){ p.classList.remove('error'); }); }, 400);
      pins[0].focus();
    }
  }

  btn.addEventListener('click', function(e){ e.preventDefault(); attemptSubmit(); });
  if (pins[0]) pins[0].focus();
})();
''';

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      div(classes: 'adm login-page', [
        div(classes: 'login-toggle toggle', [
          button(attributes: const {'data-theme-set': 'dark'}, [text('DARK')]),
          button(attributes: const {'data-theme-set': 'light'}, [text('LIGHT')]),
        ]),
        div(classes: 'login-wrap', [
          div(classes: 'login-brand', [
            raw('SALEM<span class="s">/</span>ADMIN <span class="s">·</span> LAB NOTEBOOK'),
          ]),
          div(classes: 'login-card', [
            h1([text('الدخول للوحة التحكم')]),
            p(classes: 'sub', [text('ENTER PASSCODE TO CONTINUE')]),
            form(classes: 'pin', [
              input(type: InputType.text, attributes: const {
                'inputmode': 'numeric',
                'maxlength': '1',
                'autocomplete': 'off',
              }),
              input(type: InputType.text, attributes: const {
                'inputmode': 'numeric',
                'maxlength': '1',
                'autocomplete': 'off',
              }),
              input(type: InputType.text, attributes: const {
                'inputmode': 'numeric',
                'maxlength': '1',
                'autocomplete': 'off',
              }),
              input(type: InputType.text, attributes: const {
                'inputmode': 'numeric',
                'maxlength': '1',
                'autocomplete': 'off',
              }),
            ]),
            button(classes: 'btn login-btn', [text('دخول · ENTER')]),
            div(classes: 'login-error', []),
            div(classes: 'login-meta', [text('LOCAL DEV · NOT FOR PRODUCTION')]),
          ]),
        ]),
      ]),
      script(content: _script),
    ]);
  }
}
