/// Generates `web/sitemap.xml` from site.yaml + content/blog/*/post.json.
///
/// Two ways to invoke:
///   1. CLI:   `dart run tool/generate_sitemap.dart` (from website-jaspr/)
///   2. Lib:   `import 'tool/generate_sitemap.dart'; await writeSitemap();`
///
/// The save server (tool/save_server.dart) calls writeSitemap() on every
/// post create/update/delete so the sitemap stays fresh while authoring.
/// The build script (tool/build.dart) calls it before each jaspr build.
///
/// Routes enumerated:
///   - `/`                          (homepage)
///   - `/blog/<slug>` for each post (excludes posts without a slug)
///
/// Admin routes (`/admin/*`) are deliberately excluded — they are local-only
/// and `web/robots.txt` already disallows them as defence-in-depth.
library;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) async {
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
/// problem (e.g. missing `base_url`).
Future<int> writeSitemap() async {
  final siteFile = File('content/_data/site.yaml');
  if (!siteFile.existsSync()) {
    throw _SitemapException(
      'content/_data/site.yaml not found (run from website-jaspr/ root).',
    );
  }

  final siteYaml = loadYaml(siteFile.readAsStringSync()) as YamlMap;
  final rawBase = (siteYaml['base_url'] as String?)?.trim() ?? '';
  if (rawBase.isEmpty) {
    throw _SitemapException('site.yaml is missing `base_url`.');
  }
  final baseUrl = rawBase.replaceAll(RegExp(r'/+$'), '');

  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final entries = <_UrlEntry>[
    _UrlEntry(loc: '$baseUrl/', lastmod: today, changefreq: 'weekly', priority: '1.0'),
    _UrlEntry(loc: '$baseUrl/writing', lastmod: today, changefreq: 'weekly', priority: '0.9'),
  ];

  // Collect tags/categories so we can emit /tag and /category routes too.
  final tagSet = <String>{};
  final categorySet = <String>{};

  final blogDir = Directory('content/blog');
  if (blogDir.existsSync()) {
    final dirs = blogDir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final dir in dirs) {
      final metaFile = File('${dir.path}/post.json');
      if (!metaFile.existsSync()) continue;
      try {
        final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
        final slug = (meta['slug'] as String?)?.trim() ?? '';
        if (slug.isEmpty) continue;
        final lastmod = (meta['last_modified'] as String?) ?? (meta['date'] as String?) ?? today;
        entries.add(_UrlEntry(
          loc: '$baseUrl/blog/$slug',
          lastmod: lastmod,
          changefreq: 'monthly',
          priority: '0.8',
        ));
        for (final t in (meta['tags'] as List? ?? const [])) {
          if (t is String && t.trim().isNotEmpty) tagSet.add(t.trim());
        }
        final cat = (meta['category'] as String?)?.trim() ?? '';
        if (cat.isNotEmpty) categorySet.add(cat);
      } catch (e) {
        stderr.writeln('generate_sitemap: skipping ${dir.path} ($e)');
      }
    }
  }

  // Per-paper detail routes.
  final papersFile = File('content/_data/papers.yaml');
  if (papersFile.existsSync()) {
    try {
      final yaml = loadYaml(papersFile.readAsStringSync()) as YamlMap?;
      final list = (yaml?['papers'] as YamlList?) ?? const <dynamic>[];
      for (final p in list) {
        if (p is! YamlMap) continue;
        final id = (p['id'] as String?)?.trim() ?? '';
        final visible = (p['visible'] as bool?) ?? true;
        if (id.isEmpty || !visible) continue;
        entries.add(_UrlEntry(
          loc: '$baseUrl/research/$id',
          lastmod: today,
          changefreq: 'monthly',
          priority: '0.7',
        ));
      }
    } catch (e) {
      stderr.writeln('generate_sitemap: papers.yaml parse failed ($e)');
    }
  }

  // Tag and category index pages.
  for (final tag in tagSet.toList()..sort()) {
    entries.add(_UrlEntry(
      loc: '$baseUrl/tag/${Uri.encodeComponent(tag)}',
      lastmod: today,
      changefreq: 'weekly',
      priority: '0.5',
    ));
  }
  for (final cat in categorySet.toList()..sort()) {
    entries.add(_UrlEntry(
      loc: '$baseUrl/category/${Uri.encodeComponent(cat)}',
      lastmod: today,
      changefreq: 'weekly',
      priority: '0.5',
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
