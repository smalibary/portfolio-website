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
    ]);
  }
}
