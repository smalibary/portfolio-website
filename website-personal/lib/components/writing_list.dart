import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/blog_data.dart';

/// Role: section
/// Home "أحدث الكتابات" section. V3 layout: the latest post is a featured
/// rounded card (with excerpt), the rest are compact rounded rows.
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
      else ...[
        _featured(posts.first),
        if (posts.length > 1)
          div(classes: 'writing__mini', [
            for (final post in posts.skip(1)) _row(post),
          ]),
      ],
      if (posts.isNotEmpty)
        div(classes: 'writing__more', [
          a(href: '/writing', classes: 'writing__more-link', [
            text('كل الكتابات · ALL WRITING ▼'),
          ]),
        ]),
    ]);
  }

  // Latest post — featured card with the excerpt.
  Component _featured(BlogPost post) {
    final excerpt = post.metaString('excerpt_ar') ?? post.metaString('excerpt_en');
    return a(href: post.href, classes: 'writing__feat', [
      div(classes: 'writing__feat-tags', [
        span(classes: 'writing__feat-pin', [text('الأحدث · LATEST')]),
        span(classes: 'writing__date', [text(post.date)]),
        span(classes: 'writing__lang', [text(post.language.toUpperCase())]),
      ]),
      span(classes: 'writing__feat-title-ar', [
        text(post.titleAr.isNotEmpty ? post.titleAr : post.titleEn),
      ]),
      if (post.titleEn.isNotEmpty && post.titleAr.isNotEmpty)
        span(classes: 'writing__feat-title-en', [text(post.titleEn)]),
      if (excerpt != null)
        p(classes: 'writing__feat-ex', [text(excerpt)]),
    ]);
  }

  // Older posts — compact rounded rows.
  Component _row(BlogPost post) {
    return a(href: post.href, classes: 'writing__row', [
      span(classes: 'writing__row-title', [
        text(post.titleAr.isNotEmpty ? post.titleAr : post.titleEn),
      ]),
      span(classes: 'writing__lang', [text(post.language.toUpperCase())]),
      span(classes: 'writing__date', [text(post.date)]),
    ]);
  }
}
