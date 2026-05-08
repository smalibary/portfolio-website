// Finds raw hex colours and raw px values in CSS rule bodies, outside
// token files and @keyframes, skipping lines tagged with the
// "intentionally literal" comment.
//
// Run: dart run tool/audit_hardcoded_values.dart

import 'dart:io';

final _hexRe = RegExp(r'#[0-9a-fA-F]{3,8}\b');
// Negative lookbehind: don't match digit-after-dot (e.g. don't match `5px`
// inside `1.5px`).
final _pxRe = RegExp(r'(?<![\d.])\d+px\b');

/// Strip /* ... */ comment ranges from a line, given an `inComment` state
/// on entry. Returns (stripped, newInCommentState).
(String, bool) _stripComments(String line, bool inComment) {
  final buf = StringBuffer();
  var i = 0;
  var depth = inComment ? 1 : 0;
  while (i < line.length) {
    if (depth == 0 && i + 1 < line.length && line[i] == '/' && line[i + 1] == '*') {
      depth = 1;
      i += 2;
      continue;
    }
    if (depth > 0 && i + 1 < line.length && line[i] == '*' && line[i + 1] == '/') {
      depth = 0;
      i += 2;
      continue;
    }
    if (depth == 0) buf.write(line[i]);
    i++;
  }
  return (buf.toString(), depth > 0);
}

void main() {
  final files = ['web/styles.css', 'web/admin.css'];
  final findings = <({String file, int line, String value, String context})>[];

  for (final path in files) {
    if (!File(path).existsSync()) continue;
    final lines = File(path).readAsLinesSync();
    var inKeyframes = false;
    var inComment = false;

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final (stripped, nextInComment) = _stripComments(rawLine, inComment);
      inComment = nextInComment;

      // Track @keyframes blocks (use stripped line so commented-out
      // @keyframes don't trip the tracker).
      if (stripped.contains('@keyframes')) inKeyframes = true;
      if (inKeyframes && stripped.trim() == '}') {
        inKeyframes = false;
        continue;
      }
      if (inKeyframes) continue;

      // Skip intentionally-literal lines (check raw line; comment is the marker)
      if (rawLine.contains('intentionally literal')) continue;

      // Skip token definitions (lines with --name: outside rule bodies)
      if (stripped.trimLeft().startsWith('--')) continue;

      // Hex colours — match against stripped (no comments)
      for (final m in _hexRe.allMatches(stripped)) {
        findings.add((
          file: path,
          line: i + 1,
          value: m.group(0)!,
          context: rawLine.trim(),
        ));
      }

      // Raw px values — match against stripped (no comments)
      for (final m in _pxRe.allMatches(stripped)) {
        findings.add((
          file: path,
          line: i + 1,
          value: m.group(0)!,
          context: rawLine.trim(),
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
