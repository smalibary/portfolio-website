import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Vertical rail with section navigation. The `current` arg picks the active
/// item ('profile' / 'blog' / 'research'). Logout JS clears the auth flag and
/// returns to /admin/login.
class AdminRail extends StatelessComponent {
  const AdminRail({required this.current, super.key});
  final String current;

  static const _logoutScript = '''
(function(){
  var btn = document.querySelector('.adm .rail [data-logout]');
  if (!btn) return;
  btn.addEventListener('click', function(){
    try { sessionStorage.removeItem('admin-auth'); } catch(e) {}
    window.location.href = '/admin/login';
  });
  var tBtns = document.querySelectorAll('.adm .rail [data-theme-set]');
  function applyTheme(t){
    document.documentElement.setAttribute('data-theme', t);
    localStorage.setItem('salem-theme', t);
    tBtns.forEach(function(b){ b.classList.toggle('active', b.getAttribute('data-theme-set') === t); });
  }
  var current = localStorage.getItem('salem-theme') || 'dark';
  applyTheme(current);
  tBtns.forEach(function(b){ b.addEventListener('click', function(){ applyTheme(b.getAttribute('data-theme-set')); }); });
})();
''';

  @override
  Component build(BuildContext context) {
    Component item(String href, String tip, String icon, bool active) {
      return a(
        href: href,
        classes: 'rail-item${active ? ' active' : ''}',
        attributes: {'aria-label': tip},
        [
          raw(icon),
          span(classes: 'rail-tip', [text(tip)]),
        ],
      );
    }

    return Component.fragment([
      aside(classes: 'rail', [
        a(href: '/admin/profile', classes: 'rail-brand', [text('S/')]),
        div(classes: 'rail-nav', [
          item(
            '/admin/profile',
            'PROFILE',
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/></svg>',
            current == 'profile',
          ),
          item(
            '/admin/blog',
            'BLOG',
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 4h12a4 4 0 0 1 4 4v12H8a4 4 0 0 1-4-4V4z"/><path d="M8 9h8M8 13h6"/></svg>',
            current == 'blog',
          ),
          item(
            '/admin/research',
            'RESEARCH',
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 3v6l-5 9a3 3 0 0 0 3 4h10a3 3 0 0 0 3-4l-5-9V3"/><path d="M8 3h8"/></svg>',
            current == 'research',
          ),
        ]),
        div(classes: 'rail-nav', [
          item(
            '/admin/styleguide',
            'STYLE',
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>',
            current == 'styleguide',
          ),
        ]),
        div(classes: 'rail-bottom', [
          div(classes: 'toggle', [
            button(attributes: const {'data-theme-set': 'dark'}, [text('DK')]),
            button(attributes: const {'data-theme-set': 'light'}, [text('LT')]),
          ]),
          button(
            classes: 'rail-item',
            attributes: const {'data-logout': '', 'aria-label': 'logout'},
            [
              raw(
                '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>',
              ),
              span(classes: 'rail-tip', [text('LOGOUT')]),
            ],
          ),
        ]),
      ]),
      script(content: _logoutScript),
    ]);
  }
}
