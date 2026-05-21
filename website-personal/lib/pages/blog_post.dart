import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:markdown/markdown.dart' as md;

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/sections.dart';
import '../data/site_data.dart';

/// Public reading view for a single blog post. Body is rendered from
/// markdown to HTML at build time using the `markdown` package.
///
/// When the post has `sections: [...]` metadata, sections render individually
/// with per-section "last updated" stamps and admin-pinned sections promoted
/// to the top in their original document order (live-document feature, #101).
class BlogPostPage extends StatelessComponent {
  const BlogPostPage({
    required this.site,
    required this.post,
    required this.body,
    super.key,
  });

  final SiteData site;
  final BlogPost post;
  final String body;

  @override
  Component build(BuildContext context) {
    final isAr = post.language.toLowerCase() == 'ar' || post.titleAr.isNotEmpty;
    final articleJsonLd = _buildArticleSchema(site: site, post: post);
    final faqPairs = _parseFaq(body);
    final faqJsonLd = faqPairs.isEmpty ? null : _buildFaqSchema(faqPairs);

    final headings = _extractHeadings(body);

    return Component.fragment([
      Nav(site: site),
      main_(classes: 'post-page', [
        // JSON-LD structured data — both Article and (when present) FAQPage.
        script(
          attributes: const {'type': 'application/ld+json'},
          content: articleJsonLd,
        ),
        if (faqJsonLd != null)
          script(
            attributes: const {'type': 'application/ld+json'},
            content: faqJsonLd,
          ),
        // Hero image — full width, outside the 2-column layout
        if (post.metaString('og_image') != null)
          img(
            classes: 'post-hero',
            src: '/images/${post.metaString('og_image')}',
            alt: post.titleAr.isNotEmpty ? post.titleAr : post.titleEn,
            attributes: const {'loading': 'lazy', 'decoding': 'async'},
          ),
        div(classes: 'post-layout', [
          article(classes: 'post', attributes: {'dir': isAr ? 'rtl' : 'ltr'}, [
            header(classes: 'post-head', [
              div(classes: 'post-meta', [
                if (post.date.isNotEmpty) span([text(post.date)]),
                if (post.wordCount > 0) ...[
                  span(classes: 'post-meta__sep', [text('·')]),
                  span([text(post.langLabel)]),
                ],
              ]),

              if (post.titleAr.isNotEmpty)
                h1(classes: 'post-title-ar', [text(post.titleAr)]),
              if (post.titleEn.isNotEmpty)
                p(classes: 'post-title-en', [text(post.titleEn)]),
            ]),
            _renderBody(post: post, body: body),
            footer(classes: 'post-foot', [
              a(href: '/', classes: 'post-back', [text('▲ العودة · HOME')]),
            ]),
          ]),
          // Sticky sidebar: TOC + newsletter
          aside(classes: 'post-sidebar', attributes: {'data-post-sidebar': ''}, [
            if (headings.isNotEmpty) ...[
              nav(classes: 'toc', [ // semantic wrapper, see .toc__link for styling
                div(classes: 'toc__title', [
                  span(classes: 'sq-mark--sm', []),
                  text(' المحتويات · Contents'),
                ]),
                ul(classes: 'toc__list', [
                  for (final h in headings)
                    li(classes: 'toc__item toc__item--${h.level}', [
                      a(href: '#${h.id}', classes: 'toc__link', [text(h.text)]),
                    ]),
                ]),
              ]),
              div(classes: 'sidebar-divider', [text('')]),
            ],
            div(classes: 'newsletter sq-bar', attributes: {'data-newsletter-card': ''}, [
              button(classes: 'newsletter__close', attributes: {'type': 'button', 'aria-label': 'Close', 'data-newsletter-close': ''}, [
                text('✕'),
              ]),
              div(classes: 'newsletter__title', [text('النشرة البريدية · Newsletter')]),
              p(classes: 'newsletter__desc', [text('آخر الأبحاث والمقالات مباشرة لبريدك')]),
              form(classes: 'newsletter__form', attributes: {'data-newsletter': ''}, [
                input(
                  classes: 'newsletter__input',
                  attributes: const {
                    'type': 'email', 'name': 'email',
                    'placeholder': 'email@example.com',
                    'required': '', 'autocomplete': 'email',
                    'aria-label': 'Email address',
                  },
                ),
                button(classes: 'newsletter__btn', attributes: const {'type': 'submit'}, [
                  text('اشترك · Subscribe'),
                ]),
              ]),
              div(classes: 'newsletter__msg', attributes: {'data-newsletter-msg': ''}, [text('')]),
            ]),
            if (post.tags.isNotEmpty)
              div(attributes: {'data-sidebar-tags-block': ''}, [
                div(classes: 'sidebar-divider', [text('')]),
                div(classes: 'sidebar-tags', [
                  for (final tag in post.tags)
                    a(href: '/writing/?tag=$tag', classes: 'tag-pill', [text('#$tag')]),
                ]),
              ]),
          ]),
        ]),
      ]),
      SiteFooter(),
      // Sidebar active-section tracking + newsletter handler
      script(content: _sidebarScript),
    ]);
  }
}

/// Renders the post body. If `post.sections` is non-empty, splits the body
/// into preamble + sections and reorders pinned sections to the top
/// (in original document order). Otherwise falls back to the legacy
/// whole-body markdown render.
Component _renderBody({required BlogPost post, required String body}) {
  if (post.sections.isEmpty) {
    final html = md.markdownToHtml(
      body,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [md.InlineHtmlSyntax()],
    );
    return div(classes: 'post-body', [raw(html), script(content: _footnoteHighlightScript)]);
  }

  final parsed = parseBody(body);
  final pinnedChunks = <SectionChunk>[];
  final pinnedAnchors = <String>{};
  for (final s in parsed.sections) {
    final meta = post.sectionByAnchor(s.anchor);
    if (meta != null && meta.pinned) {
      pinnedChunks.add(s);
      pinnedAnchors.add(s.anchor);
    }
  }

  return div(classes: 'post-body', [
    // Preamble (everything before the first H2) renders as one block.
    if (parsed.preamble.isNotEmpty)
      div(classes: 'post-preamble', [
        raw(md.markdownToHtml(
          parsed.preamble,
          extensionSet: md.ExtensionSet.gitHubWeb,
          inlineSyntaxes: [md.InlineHtmlSyntax()],
        )),
      ]),

    // Pinned sections — title-only rows in a teal-bordered block.
    if (pinnedChunks.isNotEmpty)
      div(classes: 'post-pinned-block', [
        div(classes: 'post-pinned-block__header', [
          span(classes: 'pinned-badge', [
            span(classes: 'sq-mark--sm', []),
            text(' مثبتة'),
          ]),
          button(
            classes: 'pinned-expand-all',
            attributes: {'type': 'button', 'data-pin-expand-all': ''},
            [text('توسيع الكل · Expand all')],
          ),
        ]),
        for (final chunk in pinnedChunks)
          _renderPinnedRow(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor)),
      ]),

    // Takeaways box — rendered after pinned block, before article body.
    if (post.takeaways.isNotEmpty)
      div(classes: 'post-takeaways', [
        span(classes: 'post-takeaways__badge', [
          span(classes: 'sq-mark', []),
          text(' خلاصة المقال · KEY TAKEAWAYS'),
        ]),
        ul([
          for (final t in post.takeaways)
            li([raw(md.markdownToHtml(
              t,
              extensionSet: md.ExtensionSet.gitHubWeb,
              inlineSyntaxes: [md.InlineHtmlSyntax()],
            ))]),
        ]),
      ]),

    // All sections in original document order. Pinned sections that were
    // promoted to the top block also appear here as dimmed repeats.
    for (final chunk in parsed.sections)
      if (pinnedAnchors.contains(chunk.anchor))
        _renderDimmedRepeat(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor))
      else
        _renderSection(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor)),

    // Client-side expand/collapse script.
    script(content: _pinToggleScript),
    script(content: _footnoteHighlightScript),
  ]);
}

/// Renders one regular (non-pinned) section: heading + meta line + body.
Component _renderSection({
  required SectionChunk chunk,
  required Section? meta,
}) {
  final newlineAt = chunk.markdown.indexOf('\n');
  final bodyAfterHeading = newlineAt < 0 ? '' : chunk.markdown.substring(newlineAt + 1);
  final inner = md.markdownToHtml(
    bodyAfterHeading,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );

  return section(
    classes: 'post-section',
    attributes: {'id': chunk.anchor},
    [
      h2(classes: 'post-section__title', [
        span(classes: 'sq-mark', []),
        text(chunk.title),
      ]),
      if (meta != null && (meta.lastModified.isNotEmpty || meta.subtopic.isNotEmpty))
        div(classes: 'post-section__meta', [
          if (meta.subtopic.isNotEmpty)
            span(classes: 'section-subtopic', [text(meta.subtopic)]),
          if (meta.lastModified.isNotEmpty)
            span(classes: 'section-date', [text('updated ${meta.lastModified}')]),
        ]),
      div(classes: 'post-section__body', [raw(inner)]),
    ],
  );
}

/// Renders one pinned section as a title-only row with date + expand arrow.
/// The full body is rendered but hidden; toggled by client-side JS.
Component _renderPinnedRow({
  required SectionChunk chunk,
  required Section? meta,
}) {
  final newlineAt = chunk.markdown.indexOf('\n');
  final bodyAfterHeading = newlineAt < 0 ? '' : chunk.markdown.substring(newlineAt + 1);
  final inner = md.markdownToHtml(
    bodyAfterHeading,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );
  final date = meta?.lastModified ?? '';

  return div(classes: 'post-pinned-section', attributes: {'data-pin-section': ''}, [
    div(classes: 'post-pinned-section__row', [
      span(classes: 'post-pinned-section__title', [
        span(classes: 'sq-mark--sm', []),
        text(chunk.title),
      ]),
      div(classes: 'post-pinned-section__meta', [
        if (date.isNotEmpty) span(classes: 'post-pinned-section__date', [text(date)]),
        span(classes: 'post-pinned-section__arrow', [text('▼')]),
      ]),
    ]),
    div(classes: 'post-pinned-section__body', [raw(inner)]),
  ]);
}

/// Renders a dimmed in-place repeat of a pinned section at its natural
/// position in the article. Full body shown with a subtle dimmed border,
/// plus a ★ pinned note.
Component _renderDimmedRepeat({
  required SectionChunk chunk,
  required Section? meta,
}) {
  final date = meta?.lastModified ?? '';
  final newlineAt = chunk.markdown.indexOf('\n');
  final bodyAfterHeading = newlineAt < 0 ? '' : chunk.markdown.substring(newlineAt + 1);
  final inner = md.markdownToHtml(
    bodyAfterHeading,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );
  return div(classes: 'dimmed-pinned-repeat', attributes: {'id': chunk.anchor}, [
    div(classes: 'dimmed-pinned-repeat__header', [
      div(classes: 'dimmed-pinned-repeat__note', [
        text('★ مثبتة'),
        span(classes: 'dimmed-pinned-repeat__note-sep', [text('·')]),
        text('هذا القسم مثبت في الأعلى'),
      ]),
      span(classes: 'dimmed-pinned-repeat__title', [text(chunk.title)]),
      if (date.isNotEmpty) span(classes: 'dimmed-pinned-repeat__date', [text(date)]),
    ]),
    div(classes: 'dimmed-pinned-repeat__body', [raw(inner)]),
  ]);
}

/// Builds a schema.org/Article JSON-LD payload as a JSON string.
String _buildArticleSchema({required SiteData site, required BlogPost post}) {
  final base = site.baseUrl;
  final canonical = post.metaString('canonical_url') ?? '$base/blog/${post.slug}';
  final ogPath = post.metaString('og_image');
  final image = ogPath == null
      ? '$base/images/${site.photoDark}'
      : (ogPath.startsWith('http') ? ogPath : '$base/images/$ogPath');
  final headline = post.titleAr.isNotEmpty ? post.titleAr : post.titleEn;
  final description = post.metaString('meta_description') ??
      post.metaString('summary') ??
      post.metaString('excerpt_ar') ??
      post.metaString('excerpt_en') ??
      '';
  final author = post.metaString('author') ?? site.nameEn;
  final authorUrl = post.metaString('author_url') ?? base;
  final lastModified = post.metaString('last_modified') ?? post.date;

  final data = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': post.metaString('schema_type') ?? 'Article',
    'headline': headline,
    if (description.isNotEmpty) 'description': description,
    'inLanguage': post.language,
    if (post.date.isNotEmpty) 'datePublished': post.date,
    if (lastModified.isNotEmpty) 'dateModified': lastModified,
    'mainEntityOfPage': {
      '@type': 'WebPage',
      '@id': canonical,
    },
    'image': image,
    'author': {
      '@type': 'Person',
      'name': author,
      'url': authorUrl,
    },
    'publisher': {
      '@type': 'Person',
      'name': site.nameEn,
      'url': base,
    },
    if (post.tags.isNotEmpty) 'keywords': post.tags.join(', '),
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

/// Builds a schema.org/FAQPage JSON-LD payload from extracted Q/A pairs.
String _buildFaqSchema(List<({String q, String a})> pairs) {
  final data = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    'mainEntity': [
      for (final p in pairs)
        {
          '@type': 'Question',
          'name': p.q,
          'acceptedAnswer': {
            '@type': 'Answer',
            'text': p.a,
          },
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

/// Client-side script for pinned section expand/collapse and "expand all".
const _pinToggleScript = r'''
(function(){
  function toggle(el){
    var body = el.querySelector('.post-pinned-section__body');
    var arrow = el.querySelector('.post-pinned-section__arrow');
    if(!body) return;
    var open = body.classList.toggle('open');
    if(arrow) arrow.classList.toggle('open', open);
  }
  document.querySelectorAll('[data-pin-section]').forEach(function(el){
    el.addEventListener('click', function(e){
      if(e.target.closest('.post-pinned-section__body')) return;
      toggle(el);
    });
  });
  document.querySelectorAll('[data-pin-expand-all]').forEach(function(btn){
    btn.addEventListener('click', function(e){
      e.stopPropagation();
      var block = btn.closest('.post-pinned-block');
      if(!block) return;
      var bodies = block.querySelectorAll('.post-pinned-section__body');
      var arrows = block.querySelectorAll('.post-pinned-section__arrow');
      var anyClosed = false;
      bodies.forEach(function(b){ if(!b.classList.contains('open')) anyClosed = true; });
      bodies.forEach(function(b){ b.classList.toggle('open', anyClosed); });
      arrows.forEach(function(a){ a.classList.toggle('open', anyClosed); });
      btn.textContent = anyClosed ? 'توسيع أقل · Collapse all' : 'توسيع الكل · Expand all';
    });
  });
})();
''';

/// Client-side script for footnote/reference highlight on click.
const _footnoteHighlightScript = r'''
(function(){
  function flashRef(id){
    var el = document.getElementById(id);
    if(!el || !el.closest('.ref-list')) return;
    el.classList.remove('ref-flash');
    void el.offsetWidth;
    el.classList.add('ref-flash');
    el.scrollIntoView({behavior:'smooth', block:'center'});
    setTimeout(function(){ el.classList.remove('ref-flash'); }, 5500);
  }
  function flashFn(id){
    var el = document.getElementById(id);
    if(!el) return;
    el.classList.remove('fn-flash');
    void el.offsetWidth;
    el.classList.add('fn-flash');
    el.scrollIntoView({behavior:'smooth', block:'center'});
    setTimeout(function(){ el.classList.remove('fn-flash'); }, 5500);
  }

  // Auto-ID each .fn span and insert back-links in ref list
  var seen = {};
  document.querySelectorAll('.post-body .fn').forEach(function(fn, i){
    var a = fn.querySelector('a');
    if(!a) return;
    var href = a.getAttribute('href') || '';
    if(href.charAt(0) !== '#') return;
    var refId = href.substring(1);
    // Add fn-ID for back-linking (fn-1, fn-1b for duplicates)
    var fnId = 'fn-' + refId.replace('ref-', '');
    if(seen[fnId]) fnId = fnId + 'b';
    seen[fnId] = true;
    fn.id = fnId;
    // Insert back-arrow into the matching ref list item
    var refLi = document.getElementById(refId);
    if(refLi){
      var back = document.createElement('a');
      back.href = '#' + fnId;
      back.className = 'ref-back';
      back.textContent = '↑';
      back.addEventListener('click', function(e){
        e.preventDefault();
        flashFn(fnId);
        history.replaceState(null, '', '#' + fnId);
      });
      refLi.querySelector('.ref-num').appendChild(back);
    }
    // Handle clicks on footnote links
    a.addEventListener('click', function(e){
      e.preventDefault();
      flashRef(refId);
      history.replaceState(null, '', '#' + refId);
    });
  });

  // Make external links in post body open in new tab
  document.querySelectorAll('.post-body a').forEach(function(a){
    var href = a.getAttribute('href') || '';
    if(href.indexOf('://') > -1 || href.indexOf('doi.org') > -1){
      a.setAttribute('target', '_blank');
      a.setAttribute('rel', 'noopener noreferrer');
    }
  });
  // Handle initial page load with hash
  if(location.hash){
    setTimeout(function(){
      var hash = location.hash.substring(1);
      if(hash.indexOf('ref-') === 0) flashRef(hash);
      else flashFn(hash);
    }, 300);
  }
})();
''';

/// Extracts FAQ Q/A pairs from the markdown body. Looks for a section
/// Extracts H2 headings from the markdown body for the TOC sidebar.
List<({String id, String text, int level})> _extractHeadings(String rawBody) {
  final body = rawBody.replaceAll('\r\n', '\n');
  final headings = <({String id, String text, int level})>[];
  final h2Re = RegExp(r'^##\s+(.+?)\s*$', multiLine: true);
  for (final m in h2Re.allMatches(body)) {
    final title = m.group(1)!.trim();
    headings.add((id: slugify(title), text: title, level: 2));
  }
  return headings;
}

/// starting with `## أسئلة شائعة` (or "FAQ"/"Frequently") and collects
/// pairs of `**Question?**\nAnswer` within it.
List<({String q, String a})> _parseFaq(String rawBody) {
  final body = rawBody.replaceAll('\r\n', '\n');

  final headingRe = RegExp(
    r'^##\s+(?:أسئلة شائعة|FAQ|Frequently)[^\n]*\n',
    multiLine: true,
  );
  final headingMatch = headingRe.firstMatch(body);
  if (headingMatch == null) return const [];

  final after = body.substring(headingMatch.end);
  final nextHeading = RegExp(r'^##\s', multiLine: true).firstMatch(after);
  final section = nextHeading == null ? after : after.substring(0, nextHeading.start);

  final pairs = <({String q, String a})>[];
  final qRe = RegExp(r'^\*\*([^*\n]+[?؟])\*\*\s*$', multiLine: true);
  final matches = qRe.allMatches(section).toList();
  for (var i = 0; i < matches.length; i++) {
    final qMatch = matches[i];
    final answerStart = qMatch.end;
    final answerEnd = i + 1 < matches.length ? matches[i + 1].start : section.length;
    final raw = section.substring(answerStart, answerEnd).trim();
    final firstPara = raw.split(RegExp(r'\n\s*\n')).first.trim();
    if (firstPara.isEmpty) continue;
    final cleaned = firstPara
        .replaceAll(RegExp(r'^---\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .trim();
    if (cleaned.isEmpty) continue;
    pairs.add((q: qMatch.group(1)!.trim(), a: cleaned));
  }
  return pairs;
}

/// Client-side script for sidebar active-section tracking + newsletter.
const _sidebarScript = r'''
(function(){
  // Active TOC tracking
  var tocLinks = document.querySelectorAll('.toc__link');
  var sections = [];
  tocLinks.forEach(function(link){
    var id = link.getAttribute('href');
    if(!id || id.charAt(0) !== '#') return;
    var targetId = id.substring(1);
    var el = document.getElementById(targetId);
    if(el) sections.push({el: el, link: link});
    // Prevent base href from hijacking anchor links
    link.addEventListener('click', function(e){
      e.preventDefault();
      if(el){
        el.scrollIntoView({behavior:'smooth', block:'start'});
        history.replaceState(null, '', '#' + targetId);
      }
    });
  });
  if(sections.length){
    var observer = new IntersectionObserver(function(entries){
      entries.forEach(function(entry){
        if(entry.isIntersecting){
          tocLinks.forEach(function(l){ l.classList.remove('active'); });
          var match = sections.find(function(s){ return s.el === entry.target; });
          if(match) match.link.classList.add('active');
        }
      });
    }, {rootMargin: '-20% 0px -70% 0px'});
    sections.forEach(function(s){ observer.observe(s.el); });
  }

  // Sidebar offset — push sidebar below hero image or post header
  var hero = document.querySelector('.post-hero');
  var sidebar = document.querySelector('.post-sidebar');
  var postHead = document.querySelector('.post-head');
  if(sidebar){
    function adjustSidebarTop(){
      var scrollY = window.scrollY;
      var navH = 96;
      // Use hero image bottom if present, otherwise use post header bottom
      var anchorEl = hero || postHead;
      if(anchorEl){
        var anchorBottom = anchorEl.getBoundingClientRect().bottom + scrollY;
        var top = scrollY > anchorBottom - navH ? navH : (anchorBottom - scrollY + 24);
        sidebar.style.top = Math.max(navH, top) + 'px';
      }
    }
    adjustSidebarTop();
    window.addEventListener('scroll', adjustSidebarTop, {passive: true});
    window.addEventListener('resize', adjustSidebarTop, {passive: true});
  }

  // Newsletter close button — also hides divider before tags
  var newsletterCard = document.querySelector('[data-newsletter-card]');
  var closeBtn = document.querySelector('[data-newsletter-close]');
  var tagsBlock = document.querySelector('[data-sidebar-tags-block]');
  if(closeBtn && newsletterCard){
    closeBtn.addEventListener('click', function(){
      newsletterCard.style.display = 'none';
      if(tagsBlock){
        var divider = tagsBlock.querySelector('.sidebar-divider');
        if(divider) divider.style.display = 'none';
      }
    });
  }

  // Newsletter form
  var form = document.querySelector('[data-newsletter]');
  if(form){
    form.addEventListener('submit', function(e){
      e.preventDefault();
      var msg = document.querySelector('[data-newsletter-msg]');
      var email = form.querySelector('input[name=email]');
      if(!email || !email.value) return;
      if(msg){
        msg.textContent = '✓ شكراً! تم التسجيل · Thanks for subscribing!';
        msg.classList.add('success');
      }
      email.value = '';
      form.querySelector('button').disabled = true;
      form.querySelector('button').textContent = 'تم · Done';
    });
  }
})();
''';
