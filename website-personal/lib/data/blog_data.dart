/// Blog posts loaded from Supabase (`portfolio.posts`) at build time.
///
/// The admin (`/admin/blog`) writes rows via Cloudflare Pages Functions; this
/// loader reads them so the homepage's writing list reflects what's saved.
library;

import 'sections.dart';
import 'supabase_client.dart';

class BlogPost {
  const BlogPost({
    required this.id,
    required this.slug,
    required this.titleAr,
    required this.titleEn,
    required this.date,
    required this.language,
    required this.wordCount,
    required this.tags,
    required this.body,
    this.sections = const [],
    this.takeaways = const [],
    this.meta = const {},
  });

  /// Stable identifier — kept for backwards compatibility with templates
  /// that referenced the old directory-name id (`01-procrastination`). Now
  /// derived from the slug since rows in Supabase have a numeric primary key
  /// that isn't meaningful to URLs.
  final String id;

  /// Public URL slug (e.g. `procrastination-not-laziness`).
  final String slug;

  final String titleAr;
  final String titleEn;
  final String date;
  final String language;
  final int wordCount;
  final List<String> tags;

  /// Section metadata. Empty list means the page should render the body
  /// as one block.
  final List<Section> sections;

  /// Key takeaway bullet points. Empty list means no takeaways box.
  final List<String> takeaways;

  /// Markdown body. Loaded eagerly because Supabase returns it on the same
  /// SELECT as the metadata — no need for a second fetch like the old
  /// file-based loadBody().
  final String body;

  Section? sectionByAnchor(String anchor) {
    for (final s in sections) {
      if (s.anchor == anchor) return s;
    }
    return null;
  }

  /// Raw post row — read fields like `excerpt_ar`, `og_image`, `canonical_url`
  /// via `metaString(...)` rather than promoting every field to a typed property.
  final Map<String, dynamic> meta;

  String? metaString(String key) {
    final v = meta[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  String get href => '/blog/$slug';

  /// Short label like "AR · 5.2k words" used in the homepage list.
  String get langLabel {
    final lang = language.toUpperCase();
    if (wordCount >= 1000) {
      final k = (wordCount / 1000).toStringAsFixed(1);
      return '$lang · ${k}k words';
    }
    if (wordCount > 0) return '$lang · ${wordCount}w words';
    return lang;
  }

  /// Keep the old name for any caller that still uses it — body is already
  /// loaded so this just returns it.
  String loadBody() => body;

  /// Fetch all published posts from Supabase, ordered newest first.
  ///
  /// RLS on portfolio.posts restricts anon role to status='published', so
  /// the build can't accidentally publish drafts.
  static Future<List<BlogPost>> loadAll() async {
    const columns =
        'slug,language,published_at,title_ar,title_en,excerpt_ar,excerpt_en,'
        'body_md,meta_title,meta_description,og_image,canonical_url,robots,'
        'reading_time,tags,sections,takeaways';
    final rows = await fetchRows(
      'posts',
      query: 'select=$columns&status=eq.published&order=published_at.desc',
    );

    final posts = <BlogPost>[];
    for (final row in rows) {
      final slug = (row['slug'] as String?) ?? '';
      if (slug.isEmpty) continue;

      final body = (row['body_md'] as String?) ?? '';
      // Treat the slug as the stable id (used for legacy callsites that
      // referenced post.id). Numeric primary keys don't help URL routing.
      final id = slug;

      // Word count derived from body — was previously computed by counting
      // whitespace-separated tokens in final.md.
      final words = body
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .length;

      // Date field — was previously `date` in post.json. Use published_at
      // (ISO timestamp) and slice to YYYY-MM-DD for display.
      final publishedAt = row['published_at'] as String?;
      final date = (publishedAt != null && publishedAt.length >= 10)
          ? publishedAt.substring(0, 10)
          : '';

      // sections and takeaways are JSONB — already decoded by http into
      // List<dynamic> by jsonDecode upstream.
      final rawSections = (row['sections'] as List?) ?? const [];
      final rawTakeaways = (row['takeaways'] as List?) ?? const [];

      // Build a "meta" map that mirrors the old post.json shape so
      // existing metaString(...) callers don't break.
      final meta = <String, dynamic>{
        'slug': slug,
        'title_ar': row['title_ar'] ?? '',
        'title_en': row['title_en'] ?? '',
        'excerpt_ar': row['excerpt_ar'] ?? '',
        'excerpt_en': row['excerpt_en'] ?? '',
        'date': date,
        'language': row['language'] ?? 'ar',
        'meta_title': row['meta_title'] ?? '',
        'meta_description': row['meta_description'] ?? '',
        'og_image': row['og_image'] ?? '',
        'canonical_url': row['canonical_url'] ?? '',
        'robots': row['robots'] ?? 'index, follow',
        'reading_time': row['reading_time'],
      };

      posts.add(BlogPost(
        id: id,
        slug: slug,
        titleAr: (row['title_ar'] as String?) ?? '',
        titleEn: (row['title_en'] as String?) ?? '',
        date: date,
        language: (row['language'] as String?) ?? 'ar',
        wordCount: words,
        tags: ((row['tags'] as List?) ?? const []).cast<String>(),
        sections: [
          for (final s in rawSections)
            if (s is Map) Section.fromJson(Map<String, dynamic>.from(s)),
        ],
        takeaways: [for (final t in rawTakeaways) if (t is String) t],
        body: body,
        meta: meta,
      ));
    }
    return posts;
  }

  /// Sorted unique tags across the given posts. Used to generate the
  /// `/tag/<slug>` routes at build time.
  static List<String> uniqueTags(List<BlogPost> posts) {
    final set = <String>{};
    for (final p in posts) {
      for (final t in p.tags) {
        final trimmed = t.trim();
        if (trimmed.isNotEmpty) set.add(trimmed);
      }
    }
    final list = set.toList()..sort();
    return list;
  }
}
