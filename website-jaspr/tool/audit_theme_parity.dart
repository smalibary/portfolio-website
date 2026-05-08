// Verifies every semantic colour token has both light and dark theme values.
// Parses semantic.css for the :root/[data-theme="dark"] block and the
// [data-theme="light"] block, then reports asymmetries.
//
// Run: dart run tool/audit_theme_parity.dart

import 'dart:io';

final _defRe = RegExp(r'(--[a-zA-Z0-9-]+)\s*:', multiLine: true);

/// Extract token names defined inside a block demarcated by [start] / [end].
Set<String> _tokensInBlock(String text, RegExp start, RegExp end) {
  final s = start.firstMatch(text);
  final e = end.firstMatch(text);
  if (s == null || e == null) return {};
  // Find the opening { after the selector and matching closing }
  final blockStart = text.indexOf('{', s.end);
  if (blockStart < 0) return {};
  var depth = 1;
  var pos = blockStart + 1;
  while (depth > 0 && pos < text.length) {
    if (text[pos] == '{') depth++;
    if (text[pos] == '}') depth--;
    pos++;
  }
  final block = text.substring(blockStart, pos);
  return _defRe
      .allMatches(block)
      .map((m) => m.group(1)!)
      .where((t) => !t.startsWith('--color-shadow-rgb')) // skip rgb helper
      .toSet();
}

void main() {
  final path = 'web/tokens/semantic.css';
  final text = File(path).readAsStringSync();

  final dark = _tokensInBlock(
    text,
    RegExp(r':root\s*,\s*\[data-theme="dark"\]'),
    RegExp(r'\[data-theme="light"\]'),
  );
  final light = _tokensInBlock(
    text,
    RegExp(r'\[data-theme="light"\]'),
    RegExp(r'/\* All deprecated'),
  );

  // Tokens intentionally defined only in dark (they inherit in light because
  // their primitives are theme-aware via --color-brand, --color-border-default).
  const intentionalDarkOnly = {
    '--border-accent',
    '--border-rule',
    '--grid-fade',
  };

  final onlyDark = dark.difference(light).difference(intentionalDarkOnly).toList()..sort();
  final onlyLight = light.difference(dark).toList()..sort();

  print('Dark-only tokens: ${dark.length}');
  print('Light-only tokens: ${light.length}');
  print('Missing light override: ${onlyDark.length}');
  print('Missing dark definition: ${onlyLight.length}');

  if (onlyDark.isEmpty && onlyLight.isEmpty) {
    print('OK: semantic tokens have theme parity.');
    return;
  }
  print('');
  if (onlyDark.isNotEmpty) {
    print('In dark but not light (missing override):');
    for (final t in onlyDark) print('  $t');
  }
  if (onlyLight.isNotEmpty) {
    print('In light but not dark (unexpected):');
    for (final t in onlyLight) print('  $t');
  }
  exit(1);
}
