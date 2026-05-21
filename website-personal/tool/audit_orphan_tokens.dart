// Finds tokens defined in primitives/semantic/components.css that have
// zero consumers in web/*.css and lib/**/*.dart.
//
// Run: dart run tool/audit_orphan_tokens.dart

import 'dart:io';

final _defRe = RegExp(r'(--[a-zA-Z0-9-]+)\s*:', multiLine: true);
final _refRe = RegExp(r'var\(\s*(--[a-zA-Z0-9-]+)');

Set<String> _definedIn(String path) {
  if (!File(path).existsSync()) return {};
  return _defRe
      .allMatches(File(path).readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();
}

/// Token names preceded by a `/* @future: */` annotation.
/// Scans each line; if a token declaration is preceded (within the same
/// `/* ... */` comment block within ~5 lines above) by `@future:`, the
/// token is treated as deliberately-orphan.
Set<String> _futureAnnotated(List<String> paths) {
  final out = <String>{};
  for (final path in paths) {
    if (!File(path).existsSync()) continue;
    final lines = File(path).readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final m = RegExp(r'^\s*(--[a-zA-Z0-9-]+)\s*:').firstMatch(lines[i]);
      if (m == null) continue;
      // Look backwards up to 5 lines for an @future: marker inside a
      // comment block.
      for (var j = i - 1; j >= 0 && j >= i - 5; j--) {
        if (lines[j].contains('@future:')) {
          out.add(m.group(1)!);
          break;
        }
        // Stop at the start of a new declaration (--name:) — but not
        // a line that merely mentions a token inside a comment.
        if (RegExp(r'^\s*--[a-zA-Z0-9-]+\s*:').hasMatch(lines[j])) break;
      }
    }
  }
  return out;
}

Set<String> _consumers() {
  final refs = <String>{};
  final files = <String>[];

  for (final f in ['web/styles.css', 'web/admin.css']) {
    if (File(f).existsSync()) files.add(f);
  }
  // Also count references from within token files (e.g. --teal-500
  // is consumed by semantic.css, not by a selector).
  for (final f in ['web/tokens/primitives.css',
                    'web/tokens/semantic.css',
                    'web/tokens/components.css']) {
    if (File(f).existsSync()) files.add(f);
  }
  for (final d in ['lib/']) {
    if (Directory(d).existsSync()) {
      files.addAll(Directory(d)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path));
    }
  }
  for (final path in files) {
    for (final m in _refRe.allMatches(File(path).readAsStringSync())) {
      refs.add(m.group(1)!);
    }
  }
  return refs;
}

void main() {
  final tokenFiles = [
    'web/tokens/primitives.css',
    'web/tokens/semantic.css',
    'web/tokens/components.css',
  ];
  final defined = tokenFiles.expand(_definedIn).toSet();
  final futureAnnotated = _futureAnnotated(tokenFiles);
  final consumed = _consumers();

  final orphans = defined
      .difference(consumed)
      .difference(futureAnnotated)
      .toList()
    ..sort();

  print('Defined tokens: ${defined.length}');
  print('Consumed tokens: ${consumed.length}');
  print('@future-annotated (skipped): ${futureAnnotated.length}');
  print('Orphan tokens (0 consumers): ${orphans.length}');

  if (orphans.isEmpty) {
    print('OK: every token has at least one consumer.');
    return;
  }
  print('');
  print('Orphan tokens:');
  for (final t in orphans) print('  $t');
  exit(1);
}
