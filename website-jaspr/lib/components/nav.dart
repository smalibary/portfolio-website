import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/site_data.dart';

/// Role: chrome
/// Top navigation bar with split-monogram brand mark.
class Nav extends StatelessComponent {
  const Nav({required this.site, super.key});
  final SiteData site;

  @override
  Component build(BuildContext context) {
    // Split the English name into "first" + ".rest" for the monogram look.
    // e.g. "Salem Malibary" → "salem" + ".malibary"
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
        div(classes: 'nav__menu', [
          a(href: '#', [text('الأبحاث')]),
          a(href: '#', [text('الكتابة')]),
          a(href: '#', [text('السيرة')]),
          a(href: '#', [text('تواصل')]),
        ]),
      ]),
    ]);
  }
}
