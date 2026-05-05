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
        article(classes: 'post', attributes: {'dir': isAr ? 'rtl' : 'ltr'}, [
          a(classes: 'post-back', href: '/', [text('← العودة · BACK TO HOME')]),
          if (post.metaString('og_image') != null)
            img(
              classes: 'post-hero',
              src: '/images/${post.metaString('og_image')}',
              alt: post.titleAr.isNotEmpty ? post.titleAr : post.titleEn,
              attributes: const {'loading': 'lazy', 'decoding': 'async'},
            ),
          header(classes: 'post-head', [
            div(classes: 'post-meta', [
              if (post.date.isNotEmpty) span([text(post.date)]),
              if (post.category.isNotEmpty) ...[
                span(classes: 'post-meta__sep', [text('·')]),
                a(href: '/category/${post.category}', classes: 'post-meta__link', [
                  text(post.category),
                ]),
              ],
              if (post.wordCount > 0) ...[
                span(classes: 'post-meta__sep', [text('·')]),
                span([text(post.langLabel)]),
              ],
            ]),
            if (post.tags.isNotEmpty)
              div(classes: 'post-tags', [
                for (final tag in post.tags)
                  a(href: '/tag/$tag', classes: 'tag-pill', [text('#$tag')]),
              ]),
            if (post.titleAr.isNotEmpty)
              h1(classes: 'post-title-ar', [text(post.titleAr)]),
            if (post.titleEn.isNotEmpty)
              p(classes: 'post-title-en', [text(post.titleEn)]),
          ]),
          _renderBody(post: post, body: body),
          footer(classes: 'post-foot', [
            a(href: '/', classes: 'post-back', [text('← العودة للصفحة الرئيسية · BACK TO HOME')]),
          ]),
        ]),
      ]),
      SiteFooter(),
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
    return div(classes: 'post-body', [raw(html)]);
  }

  final parsed = parseBody(body);
  final pinnedFirst = <SectionChunk>[];
  final rest = <SectionChunk>[];
  for (final s in parsed.sections) {
    final meta = post.sectionByAnchor(s.anchor);
    if (meta != null && meta.pinned) {
      pinnedFirst.add(s);
    } else {
      rest.add(s);
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

    // Pinned sections — promoted to top, wrapped in a labelled block so the
    // reader knows these aren't the article's natural flow.
    if (pinnedFirst.isNotEmpty)
      div(classes: 'post-pinned-block', [
        div(classes: 'post-pinned-block__label', [
          raw('★ مثبتة · PINNED BY AUTHOR'),
        ]),
        for (final chunk in pinnedFirst)
          _renderSection(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor), pinned: true),
      ]),

    // Remaining sections in original order.
    for (final chunk in rest)
      _renderSection(chunk: chunk, meta: post.sectionByAnchor(chunk.anchor), pinned: false),
  ]);
}

/// Renders one section: heading (with anchor id) + meta line (date + pin pill
/// + optional subtopic) + body. The H2 line is stripped from the chunk
/// before markdown rendering since we render the heading manually to get
/// the anchor id and meta line in.
Component _renderSection({
  required SectionChunk chunk,
  required Section? meta,
  required bool pinned,
}) {
  // Strip the leading `## heading` line; render the rest via markdown.
  final newlineAt = chunk.markdown.indexOf('\n');
  final bodyAfterHeading = newlineAt < 0 ? '' : chunk.markdown.substring(newlineAt + 1);
  final inner = md.markdownToHtml(
    bodyAfterHeading,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );

  return section(
    classes: 'post-section${pinned ? ' post-section--pinned' : ''}',
    attributes: {'id': chunk.anchor},
    [
      h2(classes: 'post-section__title', [text(chunk.title)]),
      if (meta != null && (meta.lastModified.isNotEmpty || pinned || meta.subtopic.isNotEmpty))
        div(classes: 'post-section__meta', [
          if (pinned) span(classes: 'section-pin-pill', [text('PINNED')]),
          if (meta.subtopic.isNotEmpty)
            span(classes: 'section-subtopic', [text(meta.subtopic)]),
          if (meta.lastModified.isNotEmpty)
            span(classes: 'section-date', [text('updated ${meta.lastModified}')]),
        ]),
      div(classes: 'post-section__body', [raw(inner)]),
    ],
  );
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

/// Extracts FAQ Q/A pairs from the markdown body. Looks for a section
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
