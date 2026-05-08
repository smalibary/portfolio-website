import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/site_data.dart';

/// Public archive of all blog posts with filters and search.
class WritingPage extends StatelessComponent {
  const WritingPage({required this.site, required this.posts, super.key});

  final SiteData site;
  final List<BlogPost> posts;

  @override
  Component build(BuildContext context) {
    final allTags = BlogPost.uniqueTags(posts);

    return Component.fragment([
      Nav(site: site),
      main_(classes: 'writing-page', [
        // Back link
        a(classes: 'post-back', href: '/', [text('← العودة · BACK TO HOME')]),

        // Header
        header(classes: 'writing-page__head', [
          h1([text('الكتابة · WRITING')]),
          p(classes: 'writing-page__desc', [
            text('مقالات بالعربية والإنجليزية عن البيئة المبنية، علم النفس البيئي، والإنتاجية.'),
          ]),
          p(classes: 'writing-page__desc-en', [
            text('Articles in Arabic and English on the built environment, environmental psychology, and productivity.'),
          ]),
        ]),

        // Search + filters bar
        div(classes: 'writing-page__toolbar', [
          div(classes: 'writing-page__search', [
            raw('<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>'),
            input(
              type: InputType.text,
              attributes: const {
                'data-search': '',
                'placeholder': 'ابحث في المقالات... · search articles...',
                'spellcheck': 'false',
              },
            ),
          ]),
          div(classes: 'writing-page__filters', [
            button(
              classes: 'writing-page__filter active',
              attributes: const {'data-filter': 'all', 'type': 'button'},
              [text('الكل · ALL')],
            ),
            for (final tag in allTags)
              button(
                classes: 'writing-page__filter',
                attributes: {'data-filter': tag, 'type': 'button'},
                [text('#$tag')],
              ),
          ]),
        ]),

        // Results count
        div(classes: 'writing-page__count', [
          text('${posts.length} مقالات · ${posts.length} articles'),
        ]),

        // Post list
        div(classes: 'writing-page__list', [
          for (final post in posts)
            article(
              classes: 'writing-card',
              attributes: {
                'data-tags': post.tags.join(','),
                'data-title-ar': post.titleAr,
                'data-title-en': post.titleEn,
              },
              [
                a(href: post.href, classes: 'writing-card__link', [
                  div(classes: 'writing-card__top', [
                    span(classes: 'writing-card__date', [text(post.date)]),
                    span(classes: 'writing-card__lang', [text(post.langLabel)]),
                  ]),
                  div(classes: 'writing-card__body', [
                    if (post.titleAr.isNotEmpty)
                      h2(classes: 'writing-card__title', [text(post.titleAr)]),
                    if (post.titleEn.isNotEmpty)
                      p(classes: 'writing-card__title-en', [text(post.titleEn)]),
                  ]),
                  if (post.tags.isNotEmpty)
                    div(classes: 'writing-card__tags', [
                      for (final tag in post.tags)
                        span(classes: 'writing-card__tag', [text('#$tag')]),
                    ]),
                ]),
              ],
            ),
        ]),

        // No results message
        div(classes: 'writing-page__empty', attributes: {'data-empty': '', 'style': 'display:none;'}, [
          text('لا نتائج · No results found'),
        ]),
      ]),
      SiteFooter(),
      script(content: _filterScript),
    ]);
  }

  static const _filterScript = r'''
(function(){
  var cards = document.querySelectorAll('.writing-card');
  var filters = document.querySelectorAll('.writing-page__filter');
  var search = document.querySelector('[data-search]');
  var count = document.querySelector('.writing-page__count');
  var empty = document.querySelector('[data-empty]');
  var activeTag = 'all';

  function apply(){
    var q = search ? search.value.toLowerCase().trim() : '';
    var visible = 0;
    cards.forEach(function(c){
      var tags = (c.getAttribute('data-tags') || '').split(',');
      var matchTag = activeTag === 'all' || tags.indexOf(activeTag) >= 0;
      var titleAr = (c.getAttribute('data-title-ar') || '').toLowerCase();
      var titleEn = (c.getAttribute('data-title-en') || '').toLowerCase();
      var matchSearch = !q || titleAr.indexOf(q) >= 0 || titleEn.indexOf(q) >= 0;
      var show = matchTag && matchSearch;
      c.style.display = show ? '' : 'none';
      if (show) visible++;
    });
    if (count) count.textContent = visible + ' مقالات · ' + visible + ' articles';
    if (empty) empty.style.display = visible === 0 ? '' : 'none';
  }

  filters.forEach(function(f){
    f.addEventListener('click', function(){
      filters.forEach(function(x){ x.classList.toggle('active', x === f); });
      activeTag = f.getAttribute('data-filter');
      apply();
    });
  });

  if (search) search.addEventListener('input', apply);
})();
''';
}
