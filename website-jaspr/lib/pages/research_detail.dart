import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/nav.dart';
import '../data/paper_data.dart';
import '../data/site_data.dart';

/// Per-paper detail view at `/research/<id>`. Renders the same fields as
/// the homepage card plus the full abstract and a link to the publication
/// (or preprint / OSF / ethics number) when `url` is set.
class ResearchDetailPage extends StatelessComponent {
  const ResearchDetailPage({required this.site, required this.paper, super.key});

  final SiteData site;
  final Paper paper;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Nav(site: site),
      main_(classes: 'research-detail-page', [
        article(classes: 'research-detail', attributes: const {'dir': 'rtl'}, [
          a(classes: 'post-back', href: '/', [text('▲ العودة · HOME')]),
          header(classes: 'research-detail__head', [
            div(classes: 'research-detail__row', [
              span(classes: 'pill pill--${paper.status}', [text(paper.pillLabel)]),
              span(classes: 'card__index', [text(paper.displayIndex)]),
            ]),
            div(classes: 'research-detail__metric', [text(paper.metric)]),
            div(classes: 'research-detail__metric-label', [text(paper.metricLabel)]),
            if (paper.titleAr.isNotEmpty)
              h1(classes: 'research-detail__title-ar', [text(paper.titleAr)]),
            if (paper.titleEn.isNotEmpty)
              p(classes: 'research-detail__title-en', [text(paper.titleEn)]),
            if (paper.caption.isNotEmpty)
              p(classes: 'research-detail__caption', [text(paper.caption)]),
          ]),
          if (paper.abstractText.isNotEmpty)
            section(classes: 'research-detail__body', [
              h2([text('الملخص · Abstract')]),
              for (final para in paper.abstractText.split(RegExp(r'\n\s*\n')))
                if (para.trim().isNotEmpty) p([text(para.trim())]),
            ]),
          if (paper.url.isNotEmpty)
            div(classes: 'research-detail__link', [
              a(
                href: paper.url,
                attributes: const {'target': '_blank', 'rel': 'noopener'},
                classes: 'btn-outline',
                [text('Read the paper · اقرأ البحث ▼')],
              ),
            ]),
          footer(classes: 'post-foot', [
            a(href: '/', classes: 'post-back', [text('▲ العودة · HOME')]),
          ]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}
