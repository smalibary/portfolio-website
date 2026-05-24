import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../data/supabase_client.dart';
import 'rail.dart';

/// Role: layout
/// Layout shell for /admin/* pages — runs the Supabase-session auth gate,
/// mounts the rail, and slots the page-specific body.
///
/// Auth model: the browser authenticates with supabase-js (session lives in
/// localStorage, auto-refreshed). This shell loads supabase-js, exposes:
///   - window.sb           — the Supabase client
///   - window.adminFetch   — fetch wrapper that injects the Bearer token
///   - window.__adminReady — Promise that resolves once a session is confirmed
/// Pages await window.__adminReady before loading data, and call
/// window.adminFetch instead of fetch so every /api/admin/* call is signed.
class AdminShell extends StatelessComponent {
  const AdminShell({
    required this.current,
    required this.body,
    super.key,
  });
  final String current;
  final List<Component> body;

  // Runs immediately during parse (regular script): hide the page and create
  // the readiness promise BEFORE any page script registers its .then().
  static const _bootstrap = '''
document.documentElement.style.visibility = 'hidden';
window.__adminReady = new Promise(function(resolve){ window.__adminReadyResolve = resolve; });
''';

  // Client-side router: admin pages are separate static documents, but the
  // Supabase session + auth gate live OUTSIDE `.adm.shell`, while each page's
  // rail/topbar/editor + scripts live INSIDE it. So we navigate by fetching the
  // target page and swapping only `.adm.shell`'s innerHTML, then re-executing
  // the scripts that came with it (innerHTML-injected <script>s don't run).
  // The session and `__adminReady` (already resolved) are untouched, so no
  // reload and no auth flash. Wrapped in a View Transition for a crossfade.
  static const _router = '''
(function(){
  if (window.__adminRouter) return;
  window.__adminRouter = true;

  function runScripts(container){
    container.querySelectorAll('script').forEach(function(old){
      var s = document.createElement('script');
      for (var i = 0; i < old.attributes.length; i++){
        s.setAttribute(old.attributes[i].name, old.attributes[i].value);
      }
      s.textContent = old.textContent;
      old.parentNode.replaceChild(s, old);
    });
  }
  function doSwap(html){
    var shell = document.querySelector('.adm.shell');
    var parsed = new DOMParser().parseFromString(html, 'text/html');
    var fresh = parsed.querySelector('.adm.shell');
    if (!shell || !fresh){ window.location.reload(); return; }
    if (parsed.title) document.title = parsed.title;
    shell.innerHTML = fresh.innerHTML;
    runScripts(shell);
    window.scrollTo(0, 0);
  }
  function navigate(href, push){
    fetch(href, { credentials: 'same-origin' })
      .then(function(r){ return r.text(); })
      .then(function(html){
        if (push) history.pushState({ adm: true }, '', href);
        if (document.startViewTransition) document.startViewTransition(function(){ doSwap(html); });
        else doSwap(html);
      })
      .catch(function(){ window.location.href = href; });
  }
  document.addEventListener('click', function(e){
    if (!e.target || !e.target.closest) return;
    var a = e.target.closest('.adm .rail a[href^="/admin/"]');
    if (!a) return;
    if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    e.preventDefault();
    var href = a.getAttribute('href');
    if (href === window.location.pathname) return;
    // Preserve the editors' unsaved guard: they all flag UNSAVED in the chip.
    var chip = document.querySelector('.adm .topbar .chip');
    if (chip && /UNSAVED/i.test(chip.textContent || '') &&
        !window.confirm('لديك تغييرات غير محفوظة — تتجاهلها؟ · Discard unsaved changes?')) return;
    navigate(href, true);
  });
  window.addEventListener('popstate', function(){ navigate(window.location.pathname, false); });
})();
''';

  // Deferred module: sets up supabase-js, the authed fetch helper, and the
  // session gate. SUPABASE_URL + anon key are public, safe to embed.
  String _moduleScript() => '''
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const sb = createClient('${SupabaseConfig.url}', '${SupabaseConfig.anonKey}');
window.sb = sb;
window.adminFetch = async function(path, opts){
  opts = opts || {};
  const { data } = await sb.auth.getSession();
  const token = data.session ? data.session.access_token : '';
  opts.headers = Object.assign({}, opts.headers || {}, { 'Authorization': 'Bearer ' + token });
  return fetch(path, opts);
};
const { data } = await sb.auth.getSession();
if (!data.session) {
  window.location.replace('/admin/login');
} else {
  document.documentElement.style.visibility = '';
  if (window.__adminReadyResolve) window.__adminReadyResolve(true);
}
''';

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      script(content: _bootstrap),
      script(
        attributes: const {'type': 'module'},
        content: _moduleScript(),
      ),
      div(classes: 'adm shell', [
        AdminRail(current: current),
        ...body,
      ]),
      // Persistent sibling outside `.adm.shell` — runs once, survives swaps.
      script(content: _router),
    ]);
  }
}
