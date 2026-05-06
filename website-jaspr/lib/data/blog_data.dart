/// Blog posts loaded from `content/blog/*` at build time.
///
/// Each post lives in `content/blog/<id>/` with `post.json` (metadata) and
/// `final.md` (body). The admin (`/admin/blog`) writes those files; this
/// loader reads them so the homepage's writing list reflects what's saved.
library;

import 'dart:convert';
import 'dart:io';

import 'sections.dart';

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
    this.category = '',
    this.sections = const [],
    this.takeaways = const [],
    this.meta = const {},
  });

  /// Directory name (e.g. `01-procrastination`).
  final String id;

  /// Public URL slug (e.g. `procrastination-not-laziness`).
  final String slug;

  final String titleAr;
  final String titleEn;
  final String date;
  final String language;
  final int wordCount;
  final List<String> tags;

  /// Single category from `post.json`. Used by `/category/<slug>` routes.
  /// Empty string means uncategorised.
  final String category;

  /// Section metadata from `post.json` (`sections: [...]`). Powers the
  /// live-document feature (#101): per-section last_modified dates and
  /// admin pinning. Empty list means the post hasn't been migrated yet —
  /// the page should fall back to rendering the body as one block.
  final List<Section> sections;

  /// Key takeaway bullet points from `post.json` (`takeaways: [...]`).
  /// Rendered in a highlighted box after pinned sections. Empty list means
  /// no takeaways box.
  final List<String> takeaways;

  /// Lookup section metadata by anchor (slug). Returns null if a heading
  /// in the body has no matching entry (e.g. brand-new section between
  /// saves).
  Section? sectionByAnchor(String anchor) {
    for (final s in sections) {
      if (s.anchor == anchor) return s;
    }
    return null;
  }

  /// Raw `post.json` contents. Read fields like `excerpt_ar`, `og_image`,
  /// `last_modified`, `summary`, `canonical_url` via `metaString(...)` rather
  /// than promoting every field to a typed property.
  final Map<String, dynamic> meta;

  String? metaString(String key) {
    final v = meta[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  String get href => '/blog/$slug';

  /// Short label like "AR · 5.2k" used in the homepage list.
  String get langLabel {
    final lang = language.toUpperCase();
    if (wordCount >= 1000) {
      final k = (wordCount / 1000).toStringAsFixed(1);
      return '$lang · ${k}k';
    }
    if (wordCount > 0) return '$lang · ${wordCount}w';
    return lang;
  }

  static List<BlogPost> loadAll() {
    final dir = Directory('content/blog');
    if (!dir.existsSync()) return const [];
    final posts = <BlogPost>[];
    for (final entry in dir.listSync()) {
      if (entry is! Directory) continue;
      final id = entry.path.split(RegExp(r'[\\/]')).last;
      final metaFile = File('${entry.path}/post.json');
      if (!metaFile.existsSync()) continue;
      try {
        final json = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
        final bodyFile = File('${entry.path}/final.md');
        var words = 0;
        if (bodyFile.existsSync()) {
          words = bodyFile.readAsStringSync().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
        }
        posts.add(BlogPost(
          id: id,
          slug: (json['slug'] as String?) ?? id,
          titleAr: (json['title_ar'] as String?) ?? '',
          titleEn: (json['title_en'] as String?) ?? '',
          date: (json['date'] as String?) ?? '',
          language: (json['language'] as String?) ?? 'ar',
          wordCount: words,
          tags: ((json['tags'] as List?) ?? const []).cast<String>(),
          category: ((json['category'] as String?) ?? '').trim(),
          sections: [
            for (final s in (json['sections'] as List? ?? const []))
              if (s is Map) Section.fromJson(Map<String, dynamic>.from(s)),
          ],
          takeaways: ((json['takeaways'] as List?) ?? const []).cast<String>(),
          meta: json,
        ));
      } catch (e) {
        stderr.writeln('blog_data: failed to parse $id: $e');
      }
    }
    // Newest first.
    posts.sort((a, b) => b.date.compareTo(a.date));
    return posts;
  }

  /// Read the markdown body for this post. Used by the /blog/<slug> page.
  String loadBody() {
    final f = File('content/blog/$id/final.md');
    return f.existsSync() ? f.readAsStringSync() : '';
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

  /// Sorted unique categories across the given posts.
  static List<String> uniqueCategories(List<BlogPost> posts) {
    final set = <String>{};
    for (final p in posts) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final list = set.toList()..sort();
    return list;
  }
}
