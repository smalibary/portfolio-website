import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/site_data.dart';

/// Public archive of all blog posts. Reachable at `/writing`. Posts are
/// grouped by year (newest first) and each entry shows the per-post tag
/// pills as links to `/tag/<name>` so readers can drill into a topic.
class WritingPage extends StatelessComponent {
  const WritingPage({required this.site, required this.posts, super.key});

  final SiteData site;
  final List<BlogPost> posts;

  @override
  Component build(BuildContext context) {
    // Group by year. blog_data.dart already sorts newest first, so the
    // first occurrence of each year sets its position.
    final byYear = <String, List<BlogPost>>{};
    for (final p in posts) {
      final year = p.date.length >= 4 ? p.date.substring(0, 4) : 'unknown';
      byYear.putIfAbsent(year, () => []).add(p);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Component.fragment([
      Nav(site: site),
      main_(classes: 'index-page', [
        section(classes: 'index', [
          a(classes: 'post-back', href: '/', [text('← العودة · BACK TO HOME')]),
          div(classes: 'section-head', [
            h1([text('الكتابة')]),
            div(classes: 'section-head__count', [
              text('${posts.length.toString().padLeft(2, '0')} entries'),
            ]),
          ]),
          if (posts.isEmpty)
            div(classes: 'writing__empty', [ // intentionally unstyled empty state
              text('لا يوجد مقالات بعد · No posts yet'),
            ])
          else
            for (final year in years)
              section(classes: 'index__group', [
                h2(classes: 'index__year', [text(year)]),
                div(classes: 'writing__list', [
                  for (final p in byYear[year]!) _entry(p),
                ]),
              ]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }

  Component _entry(BlogPost p) {
    return div(classes: 'index__entry', [
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
      if (p.tags.isNotEmpty)
        div(classes: 'index__tags', [
          for (final tag in p.tags)
            a(href: '/tag/$tag', classes: 'tag-pill', [text('#$tag')]),
        ]),
    ]);
  }
}
