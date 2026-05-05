import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'rail.dart';

/// Wraps an admin page in the standard shell: auth gate + rail + body slot.
/// Topbar and main are passed in so each page controls its own structure.
class AdminShell extends StatelessComponent {
  const AdminShell({
    required this.current,
    required this.body,
    super.key,
  });
  final String current;
  final List<Component> body;

  /// Inline guard that runs before any render. If `sessionStorage['admin-auth']`
  /// isn't `ok`, redirect to /admin/login. Hides body until verified to prevent
  /// flash of admin content. The `<style>` reveals body once JS confirms auth.
  static const _authGate = '''
(function(){
  document.documentElement.style.visibility = 'hidden';
  try {
    if (sessionStorage.getItem('admin-auth') !== 'ok') {
      window.location.replace('/admin/login');
      return;
    }
  } catch(e) {
    window.location.replace('/admin/login');
    return;
  }
  document.documentElement.style.visibility = '';
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
