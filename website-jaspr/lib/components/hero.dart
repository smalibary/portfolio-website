import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/site_data.dart';
import 'social_icons.dart';

/// Role: section
/// Home-page hero with bilingual name, status line, and lede paragraph.
class Hero extends StatelessComponent {
  const Hero({required this.site, super.key});
  final SiteData site;

  @override
  Component build(BuildContext context) {
    return section(classes: 'hero', [
      div(classes: 'hero__left', [
        // Status line (from yaml; renders only if non-empty)
        if (site.statusLine.isNotEmpty)
          div(classes: 'status-line', [
            span(classes: 'status-dot', []),
            span([text(site.statusLine)]),
          ]),

        // Name (Arabic primary, English secondary) — from yaml
        h1(classes: 'hero__name-ar', [
          text(site.nameAr),
        ]),
        div(classes: 'hero__name-en', [text(site.nameEn)]),

        // Lede paragraphs with *emphasis* support
        if (site.ledeAr.isNotEmpty)
          p(classes: 'hero__lede-ar', _renderEmphasis(site.ledeAr)),
        if (site.ledeEn.isNotEmpty)
          p(classes: 'hero__lede-en', _renderEmphasis(site.ledeEn)),

        // Meta items (PhD / teaching / specialty etc.)
        if (site.heroMeta.isNotEmpty)
          div(classes: 'hero__meta', [
            for (final m in site.heroMeta)
              div(classes: 'hero__meta-item', [
                span(classes: 'label', [text(m.label)]),
                div([text(m.value)]),
              ]),
          ]),

        // Socials — URLs from yaml
        SocialIcons(socials: site.socials),
      ]),

      // Portrait — light/dark variants from yaml. CSS hides the wrong one.
      div(classes: 'hero__portrait', [
        img(
          src: '/images/${site.photoDark}',
          classes: 'portrait-img portrait-img--dark', // portrait-img--* provides styling
          alt: site.nameEn,
        ),
        if (site.photoLight.isNotEmpty && site.photoLight != site.photoDark)
          img(
            src: '/images/${site.photoLight}',
            classes: 'portrait-img portrait-img--light', // portrait-img--* provides styling
            alt: site.nameEn,
          ),
        div(classes: 'portrait-meta', [
          span([text('Sydney · 2026')]),
          span([text('SM')]),
        ]),
      ]),
    ]);
  }

  /// Render a string with `*phrase*` segments as `<em>phrase</em>`. Plain
  /// text outside the asterisks renders as text. Lone asterisks pass through.
  static List<Component> _renderEmphasis(String input) {
    final parts = <Component>[];
    final pattern = RegExp(r'\*([^*]+)\*');
    var cursor = 0;
    for (final m in pattern.allMatches(input)) {
      if (m.start > cursor) {
        parts.add(text(input.substring(cursor, m.start)));
      }
      parts.add(em([text(m.group(1)!)]));
      cursor = m.end;
    }
    if (cursor < input.length) {
      parts.add(text(input.substring(cursor)));
    }
    return parts;
  }
}
