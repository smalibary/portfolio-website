/// Generates `web/sitemap.xml` from site.yaml + content/blog/*/post.json.
///
/// Run from the `website-jaspr/` directory before `jaspr build`:
///
///   dart run tool/generate_sitemap.dart
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

void main(List<String> args) {
  final siteFile = File('content/_data/site.yaml');
  if (!siteFile.existsSync()) {
    stderr.writeln('generate_sitemap: content/_data/site.yaml not found.');
    stderr.writeln('Run this script from the website-jaspr/ directory.');
    exitCode = 1;
    return;
  }

  final siteYaml = loadYaml(siteFile.readAsStringSync()) as YamlMap;
  final rawBase = (siteYaml['base_url'] as String?)?.trim() ?? '';
  if (rawBase.isEmpty) {
    stderr.writeln('generate_sitemap: site.yaml is missing `base_url`.');
    exitCode = 1;
    return;
  }
  final baseUrl = rawBase.replaceAll(RegExp(r'/+$'), '');

  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final entries = <_UrlEntry>[
    _UrlEntry(loc: '$baseUrl/', lastmod: today, changefreq: 'weekly', priority: '1.0'),
  ];

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
      } catch (e) {
        stderr.writeln('generate_sitemap: skipping ${dir.path} ($e)');
      }
    }
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
  stdout.writeln('Wrote ${outFile.path} (${entries.length} URLs).');
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

String _xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
