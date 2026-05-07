import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../data/paper_data.dart';

/// Role: section
/// Home-page grid of visible research papers, sourced from papers.yaml.
class ResearchGrid extends StatelessComponent {
  const ResearchGrid({required this.papers, super.key});
  final List<Paper> papers;

  @override
  Component build(BuildContext context) {
    final visible = papers.where((p) => p.visible).toList();
    return section(classes: 'research', [
      div(classes: 'section-head', [
        h2([text('الأبحاث الجارية')]),
        div(classes: 'section-head__count', [
          text(
            '${visible.length.toString().padLeft(2, '0')} / '
            '${papers.length.toString().padLeft(2, '0')}',
          ),
        ]),
      ]),
      if (visible.isEmpty)
        div(classes: 'research__empty', [
          text('لا يوجد أبحاث ظاهرة · No visible papers'),
        ])
      else
        div(classes: 'research__grid', [
          for (final p in visible)
            a(href: '/research/${p.id}', classes: 'card card--${p.status}', [
              div(classes: 'card__head', [
                span(classes: 'pill pill--${p.status}', [text(p.pillLabel)]),
                span(classes: 'card__index', [text(p.displayIndex)]),
              ]),
              div(classes: 'card__metric', [text(p.metric)]),
              div(classes: 'card__metric-label', [text(p.metricLabel)]),
              div(classes: 'card__title-ar', [text(p.titleAr)]),
              div(classes: 'card__title-en', [text(p.titleEn)]),
              div(classes: 'card__caption', [text(p.caption)]),
            ]),
        ]),
    ]);
  }
}
