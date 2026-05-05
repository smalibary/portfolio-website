/// Research papers loaded from `content/_data/papers.yaml` at build time.
///
/// The admin (`/admin/research`) writes the whole list back as a single yaml
/// document; this loader reads it for the homepage research grid.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';

class Paper {
  const Paper({
    required this.id,
    required this.status,
    required this.pillLabel,
    required this.titleAr,
    required this.titleEn,
    required this.metric,
    required this.metricLabel,
    required this.caption,
    required this.url,
    required this.order,
    required this.visible,
    required this.abstractText,
  });

  final String id;
  final String status; // 'published' | 'active' | 'design'
  final String pillLabel;
  final String titleAr;
  final String titleEn;
  final String metric;
  final String metricLabel;
  final String caption;
  final String url;
  final int order;
  final bool visible;
  final String abstractText;

  String get displayIndex => 'paper_${id.padLeft(2, '0')}';

  static List<Paper> loadAll() {
    final file = File('content/_data/papers.yaml');
    if (!file.existsSync()) return const [];
    try {
      final yaml = loadYaml(file.readAsStringSync()) as YamlMap?;
      final list = (yaml?['papers'] as YamlList?) ?? const <dynamic>[];
      final papers = <Paper>[];
      for (final p in list) {
        if (p is! YamlMap) continue;
        papers.add(Paper(
          id: (p['id'] as String?) ?? '',
          status: (p['status'] as String?) ?? 'design',
          pillLabel: (p['pill_label'] as String?) ?? (p['status'] as String?) ?? '',
          titleAr: (p['title_ar'] as String?) ?? '',
          titleEn: (p['title_en'] as String?) ?? '',
          metric: (p['metric'] as String?) ?? '',
          metricLabel: (p['metric_label'] as String?) ?? '',
          caption: (p['caption'] as String?) ?? '',
          url: (p['url'] as String?) ?? '',
          order: (p['order'] as int?) ?? 999,
          visible: (p['visible'] as bool?) ?? true,
          abstractText: (p['abstract'] as String?)?.trim() ?? '',
        ));
      }
      papers.sort((a, b) => a.order.compareTo(b.order));
      return papers;
    } catch (e) {
      stderr.writeln('paper_data: failed to parse papers.yaml: $e');
      return const [];
    }
  }
}
