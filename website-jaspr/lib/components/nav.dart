import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/site_data.dart';

/// Role: chrome
/// Top navigation bar with split-monogram brand mark and nav dropdown.
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
        div(classes: 'nav__dropdown', [
          button(classes: 'nav__dropdown-btn', attributes: {
            'type': 'button',
            'aria-haspopup': 'true',
            'aria-expanded': 'false',
          }, [
            text('استكشف · EXPLORE'),
            span(classes: 'nav__dropdown-arrow', [text('▾')]),
          ]),
          div(classes: 'nav__dropdown-menu', [
            a(href: '/#research', [text('الأبحاث · RESEARCH')]),
            a(href: '/writing', [text('الكتابة · WRITING')]),
            a(href: '/about', [text('السيرة · ABOUT')]),
            a(href: '/contact', [text('تواصل · CONTACT')]),
          ]),
        ]),
      ]),
    ]);
  }
}
