/// Research papers loaded from Supabase (`portfolio.research_papers`) at
/// build time.
///
/// The admin (`/admin/research`) writes rows via Cloudflare Pages Functions;
/// this loader reads them for the homepage research grid.
library;

import 'supabase_client.dart';

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

  /// Fetch all visible papers from Supabase, ordered by display_order.
  ///
  /// RLS restricts anon role to visible=true, so the build can't include
  /// hidden papers.
  static Future<List<Paper>> loadAll() async {
    final rows = await fetchRows(
      'research_papers',
      query: 'select=*&order=display_order.asc',
    );

    return [
      for (final p in rows)
        Paper(
          id: (p['id'] as String?) ?? '',
          status: (p['status'] as String?) ?? 'design',
          pillLabel: (p['pill_label'] as String?) ??
              (p['status'] as String?) ??
              '',
          titleAr: (p['title_ar'] as String?) ?? '',
          titleEn: (p['title_en'] as String?) ?? '',
          metric: (p['metric'] as String?) ?? '',
          metricLabel: (p['metric_label'] as String?) ?? '',
          caption: (p['caption'] as String?) ?? '',
          url: (p['url'] as String?) ?? '',
          order: (p['display_order'] as int?) ?? 999,
          visible: (p['visible'] as bool?) ?? true,
          abstractText: (p['abstract'] as String?)?.trim() ?? '',
        ),
    ];
  }
}
