// Finds raw hex colours and raw px values in CSS rule bodies, outside
// token files and @keyframes, skipping lines tagged with the
// "intentionally literal" comment.
//
// Run: dart run tool/audit_hardcoded_values.dart

import 'dart:io';

final _hexRe = RegExp(r'#[0-9a-fA-F]{3,8}\b');
final _pxRe = RegExp(r'\b\d+px\b');

void main() {
  final files = ['web/styles.css', 'web/admin.css'];
  final findings = <({String file, int line, String value, String context})>[];

  for (final path in files) {
    if (!File(path).existsSync()) continue;
    final lines = File(path).readAsLinesSync();
    var inKeyframes = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Track @keyframes blocks
      if (line.contains('@keyframes')) inKeyframes = true;
      if (inKeyframes && line.trim() == '}') {
        inKeyframes = false;
        continue;
      }
      if (inKeyframes) continue;

      // Skip intentionally-literal lines
      if (line.contains('intentionally literal')) continue;

      // Skip token definitions (lines with --name: outside rule bodies)
      if (line.trimLeft().startsWith('--')) continue;

      // Hex colours
      for (final m in _hexRe.allMatches(line)) {
        findings.add((
          file: path,
          line: i + 1,
          value: m.group(0)!,
          context: line.trim(),
        ));
      }

      // Raw px values
      for (final m in _pxRe.allMatches(line)) {
        findings.add((
          file: path,
          line: i + 1,
          value: m.group(0)!,
          context: line.trim(),
        ));
      }
    }
  }

  print('Files scanned: ${files.length}');
  print('Hardcoded values found: ${findings.length}');
  if (findings.isEmpty) {
    print('OK: no hardcoded hex or px values outside token files.');
    return;
  }
  print('');
  print('Hardcoded values (hex + px in rule bodies):');
  for (final f in findings) {
    print('  ${f.file}:${f.line}  ${f.value}');
  }
  // Exit 0 — this is observational, not a blocking check.
  // The output IS the debt list.
}
