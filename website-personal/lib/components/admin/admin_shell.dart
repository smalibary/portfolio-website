import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'rail.dart';

/// Role: layout
/// Layout shell for /admin/* pages — runs the auth gate, mounts the rail,
/// and slots the page-specific body. Topbar and main are passed in by each page.
class AdminShell extends StatelessComponent {
  const AdminShell({
    required this.current,
    required this.body,
    super.key,
  });
  final String current;
  final List<Component> body;

  /// Auth gate — hides the page until a probe request to /api/admin/profile
  /// confirms the session cookie is valid. 401 → redirect to /admin/login.
  /// The HttpOnly session cookie can't be read from JS directly, so we have
  /// to make a server round-trip; the small flash of hidden content is the
  /// tradeoff for not exposing the token to XSS.
  static const _authGate = '''
(function(){
  document.documentElement.style.visibility = 'hidden';
  fetch('/api/admin/profile', { credentials: 'same-origin' })
    .then(function(r){
      if (r.status === 401) {
        window.location.replace('/admin/login');
        return;
      }
      document.documentElement.style.visibility = '';
    })
    .catch(function(){
      // Network blip — let the page render and let individual API calls
      // surface their own errors.
      document.documentElement.style.visibility = '';
    });
})();
''';

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      script(content: _authGate),
      div(classes: 'adm shell', [
        AdminRail(current: current),
        ...body,
      ]),
    ]);
  }
}
