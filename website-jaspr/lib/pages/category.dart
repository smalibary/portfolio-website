import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/site_data.dart';

/// `/category/<slug>` — lists every post under `slug`. Routes are
/// generated at build time from the union of post categories.
class CategoryPage extends StatelessComponent {
  const CategoryPage({
    required this.site,
    required this.category,
    required this.posts,
    super.key,
  });

  final SiteData site;
  final String category;
  final List<BlogPost> posts;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Nav(site: site),
      main_(classes: 'index-page', [
        section(classes: 'index', [
          a(classes: 'post-back', href: '/writing', [text('▲ كل الكتابات · ALL WRITING')]),
          div(classes: 'section-head', [
            h1([raw('التصنيف · CATEGORY: <span class="tag-pill tag-pill--header">$category</span>')]),
            div(classes: 'section-head__count', [
              text('${posts.length.toString().padLeft(2, '0')} entries'),
            ]),
          ]),
          if (posts.isEmpty)
            div(classes: 'writing__empty', [ // intentionally unstyled empty state
              text('لا يوجد مقالات في هذا التصنيف · No posts in this category'),
            ])
          else
            div(classes: 'writing__list', [
              for (final p in posts)
                a(href: p.href, classes: 'writing__item', [
                  div(classes: 'writing__date', [text(p.date)]),
                  div(classes: 'bili', [
                    div(classes: 'bili__primary', [
                      text(p.titleAr.isNotEmpty ? p.titleAr : p.titleEn),
                    ]),
                    if (p.titleEn.isNotEmpty && p.titleAr.isNotEmpty)
                      div(classes: 'bili__secondary', [text(p.titleEn)]),
                  ]),
                  div(classes: 'writing__lang', [text(p.langLabel)]),
                ]),
            ]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}
