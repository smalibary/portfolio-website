import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/site_data.dart';

/// Public archive with search, multi-tag filters, length filters, and sorting.
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
        // Minimal header
        header(classes: 'writing-page__head', [
          a(classes: 'post-back', href: '/', [text('▲ HOME')]),
          div(classes: 'section-head', [
            h1([text('كل المقالات · ALL ARTICLES')]),
            div(classes: 'section-head__count', [
              text('${posts.length.toString().padLeft(2, '0')}'),
            ]),
          ]),
        ]),

        // Single-row toolbar: search | filter btn | length | sort
        div(classes: 'wp-toolbar', [
          div(classes: 'wp-search', [
            raw('<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>'),
            input(
              type: InputType.text,
              attributes: const {'data-search': '', 'placeholder': 'بحث... · search...', 'spellcheck': 'false'},
            ),
          ]),
          button(
            classes: 'wp-toolbar-btn',
            attributes: {'data-filter-toggle': '', 'type': 'button'},
            [
              raw('<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>'),
              text('FILTER'),
              span(classes: 'count', attributes: {'data-filter-count': '', 'style': 'display:none;'}, [text('0')]),
            ],
          ),
          select(attributes: {'data-length': '', 'title': 'Length'}, [
            option(value: 'all', [text('Any length')]),
            option(value: 'short', [text('< 1k words')]),
            option(value: 'medium', [text('1k–5k')]),
            option(value: 'long', [text('5k+')]),
          ]),
          select(attributes: {'data-sort': '', 'title': 'Sort'}, [
            option(value: 'newest', [text('Newest')]),
            option(value: 'oldest', [text('Oldest')]),
            option(value: 'longest', [text('Longest')]),
            option(value: 'shortest', [text('Shortest')]),
          ]),
        ]),

        // Expandable tag panel
        div(classes: 'wp-tag-panel', attributes: {'data-tag-panel': ''}, [
          div(classes: 'wp-tag-search', [
            raw('<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>'),
            input(
              type: InputType.text,
              attributes: const {'data-tag-search': '', 'placeholder': 'Search tags...', 'spellcheck': 'false'},
            ),
          ]),
          div(classes: 'wp-tag-list', [
            for (final tag in allTags)
              button(classes: 'wp-tag', attributes: {'data-tag': tag, 'type': 'button'}, [text('#$tag')]),
          ]),
        ]),

        // Selected tag chips
        div(classes: 'wp-chips', attributes: {'data-chips': ''}, []),

        // Count
        div(classes: 'wp-count', [
          text('${posts.length} articles'),
        ]),

        // Card list
        div(classes: 'wp-list', [
          for (final post in posts)
            article(
              classes: 'wp-card',
              attributes: {
                'data-tags': post.tags.join(','),
                'data-title-ar': post.titleAr,
                'data-title-en': post.titleEn,
                'data-date': post.date,
                'data-words': post.wordCount.toString(),
              },
              [
                a(href: post.href, classes: 'wp-card__link', [
                  div(classes: 'wp-card__meta', [
                    span(classes: 'wp-card__date', [text(post.date)]),
                    span(classes: 'wp-card__lang', [text(post.langLabel)]),
                  ]),
                  div(classes: 'wp-card__titles', [
                    span(classes: 'wp-card__title-ar', [
                      text(post.titleAr.isNotEmpty ? post.titleAr : post.titleEn),
                    ]),
                    if (post.titleEn.isNotEmpty && post.titleAr.isNotEmpty)
                      span(classes: 'wp-card__title-en', [text(post.titleEn)]),
                  ]),
                  if (post.tags.isNotEmpty)
                    div(classes: 'wp-card__tags', [
                      for (final tag in post.tags)
                        span(classes: 'wp-card__tag', [text('#$tag')]),
                    ]),
                ]),
              ],
            ),
        ]),

        div(classes: 'wp-empty', attributes: {'data-empty': '', 'style': 'display:none;'}, [
          text('لا نتائج · No results found'),
        ]),
      ]),
      SiteFooter(),
      script(content: _filterScript),
    ]);
  }

  static const _filterScript = r'''
(function(){
  var cards = Array.from(document.querySelectorAll('.wp-card'));
  var list = document.querySelector('.wp-list');
  var tagBtns = document.querySelectorAll('.wp-tag[data-tag]');
  var lengthSel = document.querySelector('[data-length]');
  var sortSel = document.querySelector('[data-sort]');
  var search = document.querySelector('[data-search]');
  var count = document.querySelector('.wp-count');
  var empty = document.querySelector('[data-empty]');
  var filterToggle = document.querySelector('[data-filter-toggle]');
  var tagPanel = document.querySelector('[data-tag-panel]');
  var chips = document.querySelector('[data-chips]');
  var filterCount = document.querySelector('[data-filter-count]');

  var activeTags = [];

  // Read URL params
  var params = new URLSearchParams(window.location.search);
  var urlTags = params.getAll('tag');
  if (urlTags.length) activeTags = urlTags;
  var urlLen = params.get('length');
  if (urlLen && lengthSel) lengthSel.value = urlLen;
  var urlSort = params.get('sort');
  if (urlSort && sortSel) sortSel.value = urlSort;

  function updateURL(){
    var url = new URL(window.location);
    url.searchParams.delete('tag');
    url.searchParams.delete('length');
    url.searchParams.delete('sort');
    activeTags.forEach(function(t){ url.searchParams.append('tag', t); });
    if (lengthSel && lengthSel.value !== 'all') url.searchParams.set('length', lengthSel.value);
    if (sortSel && sortSel.value !== 'newest') url.searchParams.set('sort', sortSel.value);
    history.replaceState(null, '', url);
  }

  function renderChips(){
    if (!chips) return;
    chips.innerHTML = '';
    activeTags.forEach(function(t){
      var c = document.createElement('span');
      c.className = 'wp-chip';
      c.innerHTML = '#' + t + '<button class="wp-chip-x" type="button" aria-label="Remove">×</button>';
      c.querySelector('.wp-chip-x').addEventListener('click', function(){
        activeTags = activeTags.filter(function(x){ return x !== t; });
        syncTagButtons();
        renderChips();
        apply();
      });
      chips.appendChild(c);
    });
    if (filterCount) {
      filterCount.textContent = activeTags.length;
      filterCount.style.display = activeTags.length ? '' : 'none';
    }
    if (filterToggle) filterToggle.classList.toggle('has-selection', activeTags.length > 0);
  }

  function syncTagButtons(){
    tagBtns.forEach(function(b){
      var t = b.getAttribute('data-tag');
      b.classList.toggle('active', activeTags.indexOf(t) >= 0);
    });
  }

  function apply(){
    var q = search ? search.value.toLowerCase().trim() : '';
    var len = lengthSel ? lengthSel.value : 'all';
    var sort = sortSel ? sortSel.value : 'newest';
    var visible = [];

    cards.forEach(function(c){
      var tags = (c.getAttribute('data-tags') || '').split(',');
      var matchTag = !activeTags.length || activeTags.some(function(t){ return tags.indexOf(t) >= 0; });
      var words = parseInt(c.getAttribute('data-words') || '0', 10);
      var matchLen = true;
      if (len === 'short') matchLen = words < 1000;
      else if (len === 'medium') matchLen = words >= 1000 && words <= 5000;
      else if (len === 'long') matchLen = words > 5000;
      var titleAr = (c.getAttribute('data-title-ar') || '').toLowerCase();
      var titleEn = (c.getAttribute('data-title-en') || '').toLowerCase();
      var matchQ = !q || titleAr.indexOf(q) >= 0 || titleEn.indexOf(q) >= 0;
      if (matchTag && matchLen && matchQ) visible.push(c);
      c.style.display = 'none';
    });

    visible.sort(function(a, b){
      var da = a.getAttribute('data-date') || '';
      var db = b.getAttribute('data-date') || '';
      var wa = parseInt(a.getAttribute('data-words') || '0', 10);
      var wb = parseInt(b.getAttribute('data-words') || '0', 10);
      if (sort === 'newest') return db.localeCompare(da);
      if (sort === 'oldest') return da.localeCompare(db);
      if (sort === 'longest') return wb - wa;
      if (sort === 'shortest') return wa - wb;
      return 0;
    });

    visible.forEach(function(c){ c.style.display = ''; list.appendChild(c); });
    if (count) count.textContent = visible.length + ' articles';
    if (empty) empty.style.display = visible.length === 0 ? '' : 'none';
    updateURL();
  }

  if (filterToggle) filterToggle.addEventListener('click', function(){
    tagPanel.classList.toggle('open');
    if(tagPanel.classList.contains('open')) {
      var tagSearch = document.querySelector('[data-tag-search]');
      if(tagSearch) tagSearch.focus();
    }
  });

  // Tag search — filter the tag list as you type
  var tagSearch = document.querySelector('[data-tag-search]');
  if (tagSearch) tagSearch.addEventListener('input', function(){
    var q = tagSearch.value.toLowerCase().trim();
    tagBtns.forEach(function(b){
      var t = (b.getAttribute('data-tag') || '').toLowerCase();
      b.style.display = (!q || t.indexOf(q) >= 0) ? '' : 'none';
    });
  });

  tagBtns.forEach(function(b){
    b.addEventListener('click', function(){
      var t = b.getAttribute('data-tag');
      var idx = activeTags.indexOf(t);
      if (idx >= 0) activeTags.splice(idx, 1);
      else activeTags.push(t);
      syncTagButtons();
      renderChips();
      apply();
    });
  });

  if (lengthSel) lengthSel.addEventListener('change', apply);
  if (sortSel) sortSel.addEventListener('change', apply);
  if (search) search.addEventListener('input', apply);

  syncTagButtons();
  renderChips();
  apply();
})();
''';
}
