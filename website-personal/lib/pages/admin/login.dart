import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../data/supabase_client.dart';

/// Admin login via Supabase Auth (email + password). supabase-js stores the
/// session in localStorage and auto-refreshes it, so a successful login keeps
/// you signed in for weeks. On success → /admin/profile.
///
/// Adding Google OAuth later is a button that calls
/// sb.auth.signInWithOAuth({ provider: 'google' }); magic link is
/// sb.auth.signInWithOtp({ email }). Both reuse this same session model.
class AdminLoginPage extends StatelessComponent {
  const AdminLoginPage({super.key});

  String _moduleScript() => '''
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const sb = createClient('${SupabaseConfig.url}', '${SupabaseConfig.anonKey}');

var emailEl = document.querySelector('.adm [data-email]');
var passEl  = document.querySelector('.adm [data-password]');
var btn     = document.querySelector('.adm .login-btn');
var err     = document.querySelector('.adm .login-error');
var tBtns   = document.querySelectorAll('.adm [data-theme-set]');

function applyTheme(t){
  document.documentElement.setAttribute('data-theme', t);
  localStorage.setItem('salem-theme', t);
  tBtns.forEach(function(b){ b.classList.toggle('active', b.getAttribute('data-theme-set') === t); });
}
applyTheme(localStorage.getItem('salem-theme') || 'dark');
tBtns.forEach(function(b){ b.addEventListener('click', function(){ applyTheme(b.getAttribute('data-theme-set')); }); });

function showError(msg){
  err.classList.add('show');
  err.textContent = msg;
}

// Already signed in? Skip straight to the panel.
sb.auth.getSession().then(function(res){
  if (res.data.session) window.location.replace('/admin/profile');
});

async function submit(){
  var email = (emailEl.value || '').trim();
  var password = passEl.value || '';
  if (!email || !password) { showError('أدخل البريد وكلمة المرور · Enter email and password'); return; }
  btn.disabled = true;
  err.classList.remove('show');
  const { error } = await sb.auth.signInWithPassword({ email: email, password: password });
  if (error) {
    showError('بيانات غير صحيحة · ' + error.message);
    btn.disabled = false;
  } else {
    window.location.href = '/admin/profile';
  }
}

btn.addEventListener('click', function(e){ e.preventDefault(); submit(); });
passEl.addEventListener('keydown', function(e){ if (e.key === 'Enter') { e.preventDefault(); submit(); } });
emailEl.focus();
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
            p(classes: 'sub', [text('SIGN IN TO CONTINUE')]),
            div(classes: 'field', [
              label([text('البريد الإلكتروني · EMAIL')]),
              input(type: InputType.email, attributes: const {
                'data-email': '',
                'autocomplete': 'username',
                'inputmode': 'email',
              }),
            ]),
            div(classes: 'field', [
              label([text('كلمة المرور · PASSWORD')]),
              input(type: InputType.password, attributes: const {
                'data-password': '',
                'autocomplete': 'current-password',
              }),
            ]),
            button(classes: 'btn login-btn', [text('دخول · SIGN IN')]),
            div(classes: 'login-error', []),
            div(classes: 'login-meta', [text('SUPABASE AUTH · SESSION PERSISTS')]),
          ]),
        ]),
      ]),
      script(attributes: const {'type': 'module'}, content: _moduleScript()),
    ]);
  }
}
