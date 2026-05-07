import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: chrome
/// Header bar for admin pages: section name + subtitle on the left,
/// save state + optional action button on the right.
class AdminTopbar extends StatelessComponent {
  const AdminTopbar({
    required this.sectionAr,
    required this.sectionEn,
    this.subtitle,
    this.actionLabel,
    super.key,
  });
  final String sectionAr;
  final String sectionEn;
  final String? subtitle;
  final String? actionLabel;

  @override
  Component build(BuildContext context) {
    return header(classes: 'topbar', [
      div(classes: 'topbar-l', [
        span(classes: 'section-name', [text(sectionAr)]),
        span(classes: 'section-en', [text('/ $sectionEn')]),
        if (subtitle != null) ...[
          span(classes: 'section-en', [text('/')]),
          span(
            classes: 'section-en',
            attributes: const {'style': 'color: var(--accent);'},
            [text(subtitle!)],
          ),
        ],
      ]),
      div(classes: 'topbar-r', [
        a(
          href: '/',
          classes: 'view-site',
          attributes: const {
            'target': '_blank',
            'rel': 'noopener',
            'title': 'View public site',
            'aria-label': 'View public site',
          },
          [
            raw(
              '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" '
              'stroke="currentColor" stroke-width="1.8" stroke-linecap="round" '
              'stroke-linejoin="round">'
              '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>'
              '<polyline points="15 3 21 3 21 9"/>'
              '<line x1="10" y1="14" x2="21" y2="3"/></svg>',
            ),
            span([text('VIEW SITE')]),
          ],
        ),
        div(classes: 'chip on', [
          span(classes: 'dot', []),
          text('SAVED'),
        ]),
        if (actionLabel != null) button(classes: 'btn', [text(actionLabel!)]),
      ]),
    ]);
  }
}
