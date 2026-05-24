import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: chrome
/// Floating navigation column for admin pages — a squared, glassy card pinned
/// bottom-right (replaces the old full-height left rail). `current` picks the
/// active item (profile / blog / research / styleguide). Icons spin on hover;
/// the active item plays a one-shot 360° spin on load, then holds (no hover
/// tilt) until the pointer leaves and returns. Embeds the rotate theme toggle
/// and logout inline JS.
class AdminRail extends StatelessComponent {
  const AdminRail({required this.current, super.key});
  final String current;

  static const _moonSvg =
      '<svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';
  static const _sunSvg =
      '<svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="4.5"/><line x1="12" y1="19.5" x2="12" y2="22"/><line x1="4.2" y1="4.2" x2="6" y2="6"/><line x1="18" y1="18" x2="19.8" y2="19.8"/><line x1="2" y1="12" x2="4.5" y2="12"/><line x1="19.5" y1="12" x2="22" y2="12"/><line x1="4.2" y1="19.8" x2="6" y2="18"/><line x1="18" y1="6" x2="19.8" y2="4.2"/></svg>';

  static const _script = '''
(function(){
  var root = document.documentElement;

  // ---- theme (shared key with the public site) ----
  function applyTheme(t){ root.setAttribute('data-theme', t); localStorage.setItem('salem-theme', t); }
  applyTheme(localStorage.getItem('salem-theme') || 'dark');
  var tt = document.querySelector('.adm .rail [data-theme-toggle]');
  if (tt) tt.addEventListener('click', function(){
    applyTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
  });

  // ---- logout ----
  var out = document.querySelector('.adm .rail [data-logout]');
  if (out) out.addEventListener('click', function(){
    var done = function(){ window.location.href = '/admin/login'; };
    if (window.sb && window.sb.auth) window.sb.auth.signOut().finally(done); else done();
  });

  // ---- active item: spin once on load, hold (suppress hover) until leave ----
  var act = document.querySelector('.adm .rail .rail-item.active');
  if (act){
    act.classList.add('held', 'spin');
    act.addEventListener('animationend', function(){ act.classList.remove('spin'); });
    act.addEventListener('mouseleave', function(){ act.classList.remove('held'); }, { once: true });
  }
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
          item(
            '/admin/styleguide',
            'STYLE',
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>',
            current == 'styleguide',
          ),
        ]),
        div(classes: 'rail-sep', []),
        // rotate sun/moon theme toggle (icon = current theme)
        button(
          classes: 'rail-item rail-theme',
          attributes: const {'data-theme-toggle': '', 'aria-label': 'Toggle theme'},
          [
            span(classes: 'ic moon', [raw(_moonSvg)]),
            span(classes: 'ic sun', [raw(_sunSvg)]),
          ],
        ),
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
      script(content: _script),
    ]);
  }
}
