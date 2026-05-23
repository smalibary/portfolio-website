/// Generates `web/sitemap.xml` from data in Supabase (portfolio.profile,
/// portfolio.posts, portfolio.research_papers).
///
/// Two ways to invoke:
///   1. CLI:   `dart run tool/generate_sitemap.dart` (from website-personal/)
///   2. Lib:   `import 'tool/generate_sitemap.dart'; await writeSitemap();`
///
/// The build script (tool/build.dart) calls writeSitemap() before each
/// jaspr build, so smalibary.me/sitemap.xml always matches what's deployed.
///
/// Routes enumerated:
///   - `/`                            (homepage)
///   - `/writing`                     (blog index)
///   - `/blog/<slug>` for each post   (posts with non-empty slug)
///   - `/research/<id>` for each paper (visible papers)
///
/// Admin routes (`/admin/*`) are deliberately excluded — they require
/// authentication and `web/robots.txt` already disallows them.
library;

import 'dart:io';

import 'package:website_jaspr/data/blog_data.dart';
import 'package:website_jaspr/data/paper_data.dart';
import 'package:website_jaspr/data/site_data.dart';

Future<void> main(List<String> args) async {
  try {
    final count = await writeSitemap();
    stdout.writeln('Wrote web/sitemap.xml ($count URLs).');
  } on _SitemapException catch (e) {
    stderr.writeln('generate_sitemap: ${e.message}');
    exitCode = 1;
  }
}

/// Generates the sitemap and writes it to `web/sitemap.xml`. Returns the
/// number of URLs written. Throws `_SitemapException` on a fatal config
/// problem (e.g. missing base_url).
Future<int> writeSitemap() async {
  final site = await SiteData.load();
  final baseUrl = site.baseUrl;
  if (baseUrl.isEmpty) {
    throw _SitemapException('profile.base_url is empty in Supabase.');
  }

  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final entries = <_UrlEntry>[
    _UrlEntry(loc: '$baseUrl/', lastmod: today, changefreq: 'weekly', priority: '1.0'),
    _UrlEntry(loc: '$baseUrl/writing', lastmod: today, changefreq: 'weekly', priority: '0.9'),
  ];

  final posts = await BlogPost.loadAll();
  for (final post in posts) {
    final slug = post.slug.trim();
    if (slug.isEmpty) continue;
    final lastmod = post.date.isNotEmpty ? post.date : today;
    entries.add(_UrlEntry(
      loc: '$baseUrl/blog/$slug',
      lastmod: lastmod,
      changefreq: 'monthly',
      priority: '0.8',
    ));
  }

  final papers = await Paper.loadAll();
  for (final paper in papers) {
    if (!paper.visible || paper.id.isEmpty) continue;
    entries.add(_UrlEntry(
      loc: '$baseUrl/research/${paper.id}',
      lastmod: today,
      changefreq: 'monthly',
      priority: '0.7',
    ));
  }

  final buf = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
  for (final e in entries) {
    buf
      ..writeln('  <url>')
      ..writeln('    <loc>${_xmlEscape(e.loc)}</loc>')
      ..writeln('    <lastmod>${e.lastmod}</lastmod>')
      ..writeln('    <changefreq>${e.changefreq}</changefreq>')
      ..writeln('    <priority>${e.priority}</priority>')
      ..writeln('  </url>');
  }
  buf.writeln('</urlset>');

  final outFile = File('web/sitemap.xml');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(buf.toString());
  return entries.length;
}

class _UrlEntry {
  _UrlEntry({
    required this.loc,
    required this.lastmod,
    required this.changefreq,
    required this.priority,
  });
  final String loc;
  final String lastmod;
  final String changefreq;
  final String priority;
}

class _SitemapException implements Exception {
  _SitemapException(this.message);
  final String message;
  @override
  String toString() => 'SitemapException: $message';
}

String _xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
