// Audits every `var(--name)` reference in web/styles.css and web/admin.css
// against the names defined in web/tokens/{primitives,semantic,components}.css.
// Prints any unresolved references and exits non-zero if found.
//
// Run: dart run tool/audit_css_tokens.dart

import 'dart:io';

final _defRe = RegExp(r'(?:^|[\s{;])(--[a-zA-Z0-9-]+)\s*:', multiLine: true);
final _refRe = RegExp(r'var\(\s*(--[a-zA-Z0-9-]+)');

Set<String> _definedNames(List<String> paths) {
  final out = <String>{};
  for (final p in paths) {
    final text = File(p).readAsStringSync();
    for (final m in _defRe.allMatches(text)) {
      out.add(m.group(1)!);
    }
  }
  return out;
}

List<({String file, int line, String name})> _refs(String path) {
  final out = <({String file, int line, String name})>[];
  final lines = File(path).readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    for (final m in _refRe.allMatches(lines[i])) {
      out.add((file: path, line: i + 1, name: m.group(1)!));
    }
  }
  return out;
}

void main() {
  final tokenFiles = [
    'web/tokens/primitives.css',
    'web/tokens/semantic.css',
    'web/tokens/components.css',
  ];
  final consumerFiles = [
    'web/styles.css',
    'web/admin.css',
  ];
  // CSS custom properties may be defined anywhere (including per-modifier
  // overrides like .card--published { --card-accent: ... }), so scan every
  // CSS file for definitions.
  final defined = _definedNames([...tokenFiles, ...consumerFiles]);
  final refs = [
    ...consumerFiles.expand(_refs),
    ...tokenFiles.expand(_refs),
  ];
  final unresolved = refs.where((r) => !defined.contains(r.name)).toList();

  print('Defined token names: ${defined.length}');
  print('Total var(--*) references: ${refs.length}');
  print('Unresolved references: ${unresolved.length}');
  if (unresolved.isEmpty) {
    print('OK: every var(--*) resolves to a defined token.');
    return;
  }
  print('');
  print('Unresolved:');
  for (final r in unresolved) {
    print('  ${r.file}:${r.line}  ${r.name}');
  }
  exit(1);
}
