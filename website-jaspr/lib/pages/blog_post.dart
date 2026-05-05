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

    return Component.fragment([
      Nav(site: site),
      main_(classes: 'post-page', [
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
