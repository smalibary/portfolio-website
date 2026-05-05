/// One-off migration: add `sections: [...]` to existing post.json files
/// that don't have it yet. Walks `content/blog/*/post.json` + `final.md`
/// and stamps every section's `last_modified` from the post's `date`.
///
/// Idempotent — running again on a post that already has sections leaves
/// it alone.
///
/// Run from website-jaspr/ root: `dart run tool/migrate_sections.dart`
library;

import 'dart:convert';
import 'dart:io';

import 'package:website_jaspr/data/sections.dart';

void main() {
  final blogDir = Directory('content/blog');
  if (!blogDir.existsSync()) {
    stderr.writeln('migrate_sections: content/blog not found.');
    stderr.writeln('  cwd: ${Directory.current.path}');
    stderr.writeln('  run from website-jaspr/ root.');
    exit(1);
  }

  var migrated = 0;
  var skipped = 0;
  for (final entry in blogDir.listSync()) {
    if (entry is! Directory) continue;
    final id = entry.path.split(RegExp(r'[\\/]')).last;
    final metaFile = File('${entry.path}/post.json');
    final bodyFile = File('${entry.path}/final.md');
    if (!metaFile.existsSync() || !bodyFile.existsSync()) {
      stderr.writeln('  skip $id (missing post.json or final.md)');
      continue;
    }

    final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
    if (meta['sections'] is List && (meta['sections'] as List).isNotEmpty) {
      stdout.writeln('  skip $id (already has ${(meta['sections'] as List).length} sections)');
      skipped++;
      continue;
    }

    final body = bodyFile.readAsStringSync();
    final parsed = parseBody(body);
    final fallbackDate = (meta['last_modified'] as String?) ?? (meta['date'] as String?) ?? '';

    meta['sections'] = [
      for (final chunk in parsed.sections)
        {
          'anchor': chunk.anchor,
          'title': chunk.title,
          'last_modified': fallbackDate,
          'pinned': false,
        },
    ];

    metaFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(meta));
    stdout.writeln('  $id → wrote ${parsed.sections.length} sections (date=$fallbackDate)');
    migrated++;
  }

  stdout.writeln('\nDone. migrated=$migrated, skipped=$skipped');
}
