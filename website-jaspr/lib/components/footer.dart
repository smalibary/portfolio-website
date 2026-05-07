import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: chrome
/// Site-wide footer with year, social text-links, and admin-login lock icon.
class SiteFooter extends StatelessComponent {
  const SiteFooter({super.key});

  @override
  Component build(BuildContext context) {
    return footer(classes: 'footer', [
      div(classes: 'footer__year', [text('© 2026 — built with jaspr')]),
      div(classes: 'footer__links', [
        a(href: '#', [text('scholar')]),
        a(href: '#', [text('researchgate')]),
        a(href: '#', [text('linkedin')]),
        a(
          href: '/admin/login',
          classes: 'footer__lock',
          attributes: const {'title': 'admin', 'aria-label': 'admin'},
          [
            raw(
              '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" '
              'stroke="currentColor" stroke-width="2" stroke-linecap="round" '
              'stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/>'
              '<path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>',
            ),
          ],
        ),
      ]),
    ]);
  }
}
