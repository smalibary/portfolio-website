import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/blog_data.dart';

/// Role: section
/// Section listing recent blog posts; used on home and /writing.
class WritingList extends StatelessComponent {
  const WritingList({required this.posts, super.key});
  final List<BlogPost> posts;

  @override
  Component build(BuildContext context) {
    return section(classes: 'writing', [
      div(classes: 'section-head', [
        h2([text('أحدث الكتابات')]),
        div(classes: 'section-head__count', [
          text('${posts.length.toString().padLeft(2, '0')} entries'),
        ]),
      ]),
      if (posts.isEmpty)
        div(classes: 'writing__empty', [ // intentionally unstyled empty state
          text('لا يوجد مقالات بعد · No posts yet'),
        ])
      else
        div(classes: 'writing__list', [
          for (final p in posts)
            a(href: p.href, classes: 'writing__item sq-bar', [
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
      if (posts.isNotEmpty)
        div(classes: 'writing__more', [
          a(href: '/writing', classes: 'writing__more-link', [
            text('كل الكتابات · ALL WRITING →'),
          ]),
        ]),
    ]);
  }
}
