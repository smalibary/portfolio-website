// Regression check that no removed deprecated aliases are reintroduced.
// Hardcodes the list of 13 aliases removed during Phase 3.
// Should always report 0 matches.
//
// Run: dart run tool/audit_deprecated_aliases.dart

import 'dart:io';

const _deprecated = [
  '--bg',
  '--bg-elev',
  '--bg-card',
  '--ink',
  '--ink-muted',
  '--ink-faint',
  '--rule',
  '--accent',
  '--accent-warm',
  '--accent-cool',
  '--shadow',
  '--border-rule-val',
  '--border-accent-val',
];

final _refRe = RegExp(r'var\(\s*(--[a-zA-Z0-9-]+)');

void main() {
  final cssFiles = [
    'web/styles.css',
    'web/admin.css',
    'web/tokens/primitives.css',
    'web/tokens/semantic.css',
    'web/tokens/components.css',
  ];
  final dartDirs = ['lib/'];

  final files = <String>[];
  for (final f in cssFiles) {
    if (File(f).existsSync()) files.add(f);
  }
  for (final dir in dartDirs) {
    if (Directory(dir).existsSync()) {
      files.addAll(Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path));
    }
  }

  final hits = <({String file, int line, String token})>[];
  final deprecatedSet = _deprecated.map((t) => 'var($t)').toSet();

  for (final path in files) {
    final lines = File(path).readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      for (final m in _refRe.allMatches(lines[i])) {
        final ref = 'var(${m.group(1)!})';
        if (deprecatedSet.contains(ref)) {
          hits.add((file: path, line: i + 1, token: m.group(1)!));
        }
      }
    }
  }

  print('Deprecated aliases checked: ${_deprecated.length}');
  print('Files scanned: ${files.length}');
  print('Violations: ${hits.length}');
  if (hits.isEmpty) {
    print('OK: no deprecated aliases in use.');
    return;
  }
  print('');
  print('Deprecated aliases found:');
  for (final h in hits) {
    print('  ${h.file}:${h.line}  var(${h.token})');
  }
  exit(1);
}
