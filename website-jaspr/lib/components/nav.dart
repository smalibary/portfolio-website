import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/site_data.dart';

/// Role: chrome
/// Top navigation bar with split-monogram brand mark and nav links.
class Nav extends StatelessComponent {
  const Nav({required this.site, super.key});
  final SiteData site;

  @override
  Component build(BuildContext context) {
    final lower = site.nameEn.toLowerCase().split(' ');
    final first = lower.isNotEmpty ? lower.first : 'salem';
    final rest = lower.length > 1 ? '.${lower.skip(1).join('.')}' : '';

    return nav(classes: 'nav', [
      a(href: '/', classes: 'nav__monogram', [
        text(first),
        if (rest.isNotEmpty) span([text(rest)]),
        span(classes: 'nav__monogram-square', [text('س')]),
      ]),
      div(classes: 'nav__right', [
        div(classes: 'nav__links', [
          a(href: '/#research', [text('الأبحاث')]),
          a(href: '/writing', [text('الكتابة')]),
          a(href: '/about', [text('السيرة')]),
          a(href: '/contact', [text('تواصل')]),
        ]),
        div(classes: 'nav__split-btn', [
          a(href: '/writing', classes: 'nav__split-main', [text('اقرأ المزيد')]),
          div(classes: 'nav__split-arrow', attributes: {'aria-label': 'More actions'}, [
            span(classes: 'nav__split-arrow-down', [text('▼')]),
            span(classes: 'nav__split-arrow-up', [text('▲')]),
          ]),
          div(classes: 'nav__split-menu', [
            a(href: '/writing', [text('المقالات · BLOG')]),
            a(href: '/#research', [text('الأبحاث · RESEARCH')]),
            a(href: '/about', [text('عن الموقع · ABOUT')]),
            a(href: '/contact', [text('تواصل · CONTACT')]),
          ]),
        ]),
      ]),
      script(content: _navScript),
    ]);
  }

  static const _navScript = r'''
(function(){
  var arrow = document.querySelector('.nav__split-arrow');
  var menu = document.querySelector('.nav__split-menu');
  if (!arrow || !menu) return;
  var timer;
  function show(){ clearTimeout(timer); menu.classList.add('show'); }
  function hide(){ timer = setTimeout(function(){ menu.classList.remove('show'); }, 300); }
  arrow.addEventListener('mouseenter', show);
  arrow.addEventListener('mouseleave', hide);
  menu.addEventListener('mouseenter', show);
  menu.addEventListener('mouseleave', hide);
})();
''';
}
