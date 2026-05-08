import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/site_data.dart';

/// Public archive of all blog posts with search, filters, and sorting.
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
        a(classes: 'post-back', href: '/', [text('← العودة · BACK TO HOME')]),

        header(classes: 'writing-page__head', [
          h1([text('الكتابة · WRITING')]),
          p(classes: 'writing-page__desc', [
            text('مقالات بالعربية والإنجليزية عن البيئة المبنية، علم النفس البيئي، والإنتاجية.'),
          ]),
          p(classes: 'writing-page__desc-en', [
            text('Articles in Arabic and English on the built environment, environmental psychology, and productivity.'),
          ]),
        ]),

        // Search + filters
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
          div(classes: 'writing-page__filter-row', [
            div(classes: 'writing-page__filter-group', [
              span(classes: 'writing-page__filter-label', [text('التصفية · FILTER')]),
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
            div(classes: 'writing-page__filter-group', [
              span(classes: 'writing-page__filter-label', [text('الطول · LENGTH')]),
              button(
                classes: 'writing-page__filter active',
                attributes: {'data-length': 'all', 'type': 'button'},
                [text('الكل')],
              ),
              button(
                classes: 'writing-page__filter',
                attributes: {'data-length': 'short', 'type': 'button'},
                [text('< 1k')],
              ),
              button(
                classes: 'writing-page__filter',
                attributes: {'data-length': 'medium', 'type': 'button'},
                [text('1k–5k')],
              ),
              button(
                classes: 'writing-page__filter',
                attributes: {'data-length': 'long', 'type': 'button'},
                [text('5k+')],
              ),
            ]),
            div(classes: 'writing-page__filter-group', [
              span(classes: 'writing-page__filter-label', [text('ترتيب · SORT')]),
              button(
                classes: 'writing-page__filter active',
                attributes: {'data-sort': 'newest', 'type': 'button'},
                [text('أحدث · Newest')],
              ),
              button(
                classes: 'writing-page__filter',
                attributes: {'data-sort': 'oldest', 'type': 'button'},
                [text('أقدم · Oldest')],
              ),
              button(
                classes: 'writing-page__filter',
                attributes: {'data-sort': 'longest', 'type': 'button'},
                [text('أطول · Longest')],
              ),
              button(
                classes: 'writing-page__filter',
                attributes: {'data-sort': 'shortest', 'type': 'button'},
                [text('أقصر · Shortest')],
              ),
            ]),
          ]),
        ]),

        div(classes: 'writing-page__count', [
          text('${posts.length} مقالات · ${posts.length} articles'),
        ]),

        div(classes: 'writing-page__list', [
          for (final post in posts)
            article(
              classes: 'writing-card',
              attributes: {
                'data-tags': post.tags.join(','),
                'data-title-ar': post.titleAr,
                'data-title-en': post.titleEn,
                'data-date': post.date,
                'data-words': post.wordCount.toString(),
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
  var cards = Array.from(document.querySelectorAll('.writing-card'));
  var list = document.querySelector('.writing-page__list');
  var filters = document.querySelectorAll('.writing-page__filter[data-filter]');
  var lengthBtns = document.querySelectorAll('.writing-page__filter[data-length]');
  var sortBtns = document.querySelectorAll('.writing-page__filter[data-sort]');
  var search = document.querySelector('[data-search]');
  var count = document.querySelector('.writing-page__count');
  var empty = document.querySelector('[data-empty]');

  var activeTag = 'all';
  var activeLength = 'all';
  var activeSort = 'newest';

  // Read ?tag= from URL
  var params = new URLSearchParams(window.location.search);
  var urlTag = params.get('tag');
  if (urlTag) {
    activeTag = urlTag;
    filters.forEach(function(f){ f.classList.toggle('active', f.getAttribute('data-filter') === urlTag); });
  }

  function apply(){
    var q = search ? search.value.toLowerCase().trim() : '';
    var visible = [];
    cards.forEach(function(c){
      var tags = (c.getAttribute('data-tags') || '').split(',');
      var matchTag = activeTag === 'all' || tags.indexOf(activeTag) >= 0;
      var words = parseInt(c.getAttribute('data-words') || '0', 10);
      var matchLength = true;
      if (activeLength === 'short') matchLength = words < 1000;
      else if (activeLength === 'medium') matchLength = words >= 1000 && words <= 5000;
      else if (activeLength === 'long') matchLength = words > 5000;
      var titleAr = (c.getAttribute('data-title-ar') || '').toLowerCase();
      var titleEn = (c.getAttribute('data-title-en') || '').toLowerCase();
      var matchSearch = !q || titleAr.indexOf(q) >= 0 || titleEn.indexOf(q) >= 0;
      if (matchTag && matchLength && matchSearch) visible.push(c);
      c.style.display = 'none';
    });

    // Sort visible cards
    visible.sort(function(a, b){
      var da = a.getAttribute('data-date') || '';
      var db = b.getAttribute('data-date') || '';
      var wa = parseInt(a.getAttribute('data-words') || '0', 10);
      var wb = parseInt(b.getAttribute('data-words') || '0', 10);
      if (activeSort === 'newest') return db.localeCompare(da);
      if (activeSort === 'oldest') return da.localeCompare(db);
      if (activeSort === 'longest') return wb - wa;
      if (activeSort === 'shortest') return wa - wb;
      return 0;
    });

    // Reorder DOM
    visible.forEach(function(c){
      c.style.display = '';
      list.appendChild(c);
    });

    if (count) count.textContent = visible.length + ' مقالات · ' + visible.length + ' articles';
    if (empty) empty.style.display = visible.length === 0 ? '' : 'none';
  }

  filters.forEach(function(f){
    f.addEventListener('click', function(){
      filters.forEach(function(x){ x.classList.toggle('active', x === f); });
      activeTag = f.getAttribute('data-filter');
      var url = new URL(window.location);
      if (activeTag === 'all') url.searchParams.delete('tag');
      else url.searchParams.set('tag', activeTag);
      history.replaceState(null, '', url);
      apply();
    });
  });

  lengthBtns.forEach(function(b){
    b.addEventListener('click', function(){
      lengthBtns.forEach(function(x){ x.classList.toggle('active', x === b); });
      activeLength = b.getAttribute('data-length');
      apply();
    });
  });

  sortBtns.forEach(function(b){
    b.addEventListener('click', function(){
      sortBtns.forEach(function(x){ x.classList.toggle('active', x === b); });
      activeSort = b.getAttribute('data-sort');
      apply();
    });
  });

  if (search) search.addEventListener('input', apply);
  apply();
})();
''';
}
