import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:markdown/markdown.dart' as md;

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/blog_data.dart';
import '../data/site_data.dart';

/// Public reading view for a single blog post. Body is rendered from
/// markdown to HTML at build time using the `markdown` package.
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
    final html = md.markdownToHtml(
      body,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [md.InlineHtmlSyntax()],
    );

    final isAr = post.language.toLowerCase() == 'ar' || post.titleAr.isNotEmpty;

    final articleJsonLd = _buildArticleSchema(site: site, post: post);
    final faqPairs = _parseFaq(body);
    final faqJsonLd = faqPairs.isEmpty ? null : _buildFaqSchema(faqPairs);

    return Component.fragment([
      Nav(site: site),
      main_(classes: 'post-page', [
        // JSON-LD structured data. Crawlers and AI answer engines parse these
        // regardless of position in the document; placing in body keeps the
        // logic per-route without needing per-route head injection.
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
          header(classes: 'post-head', [
            div(classes: 'post-meta', [
              if (post.date.isNotEmpty) span([text(post.date)]),
              if (post.tags.isNotEmpty) ...[
                span(classes: 'post-meta__sep', [text('·')]),
                span([text(post.tags.join(' · '))]),
              ],
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
          div(classes: 'post-body', [raw(html)]),
          footer(classes: 'post-foot', [
            a(href: '/', classes: 'post-back', [text('← العودة للصفحة الرئيسية · BACK TO HOME')]),
          ]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}

/// Builds a schema.org/Article JSON-LD payload as a JSON string.
String _buildArticleSchema({required SiteData site, required BlogPost post}) {
  final base = site.baseUrl;
  final canonical = post.metaString('canonical_url') ?? '$base/blog/${post.slug}';
  final ogPath = post.metaString('og_image');
  final image = ogPath == null
      ? '$base/images/${post.photoDarkFallback(site)}'
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
  // Normalise CRLF → LF so multiline anchors behave consistently across
  // editors and OS conventions.
  final body = rawBody.replaceAll('\r\n', '\n');

  // Find the FAQ heading line.
  final headingRe = RegExp(
    r'^##\s+(?:أسئلة شائعة|FAQ|Frequently)[^\n]*\n',
    multiLine: true,
  );
  final headingMatch = headingRe.firstMatch(body);
  if (headingMatch == null) return const [];

  // Take everything from after the heading to the next `## ` heading
  // (or end of document if none follows).
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
    // Take the first paragraph only (until blank line) and strip simple markdown.
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

extension on BlogPost {
  /// Fallback OG image when the post has no `og_image` set.
  String photoDarkFallback(SiteData site) => site.photoDark;
}
