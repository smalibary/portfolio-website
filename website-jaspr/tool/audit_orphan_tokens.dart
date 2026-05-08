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
  final consumed = _consumers();

  final orphans = defined.difference(consumed).toList()..sort();

  print('Defined tokens: ${defined.length}');
  print('Consumed tokens: ${consumed.length}');
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
