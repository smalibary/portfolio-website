/// Blog posts loaded from `content/blog/*` at build time.
///
/// Each post lives in `content/blog/<id>/` with `post.json` (metadata) and
/// `final.md` (body). The admin (`/admin/blog`) writes those files; this
/// loader reads them so the homepage's writing list reflects what's saved.
library;

import 'dart:convert';
import 'dart:io';

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
}
