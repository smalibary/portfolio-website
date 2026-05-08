// Cross-references CSS class names used in Dart (classes: '...') against
// rules defined in web/*.css. Reports unreferenced and orphan classes.
//
// Run: dart run tool/audit_css_classes.dart

import 'dart:io';

final _classesArgRe = RegExp(r"classes:\s*'([^']+)'");
final _classSelectorRe = RegExp(r'\.([a-zA-Z][a-zA-Z0-9_-]*)');

/// Collect all class names passed to `classes:` in Dart files under lib/.
Set<String> _dartClasses() {
  final out = <String>{};
  final dir = Directory('lib');
  if (!dir.existsSync()) return out;
  for (final f in dir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    for (final m in _classesArgRe.allMatches(f.readAsStringSync())) {
      out.addAll(
        m.group(1)!.split(RegExp(r'\s+')).where(
          (s) => s.isNotEmpty &&
              RegExp(r'^[a-zA-Z]').hasMatch(s) &&
              !s.contains(r'$'),
        ),
      );
    }
  }
  return out;
}

/// Collect all class selectors from CSS files.
Set<String> _cssDefined() {
  final out = <String>{};
  for (final path in ['web/styles.css', 'web/admin.css']) {
    if (!File(path).existsSync()) continue;
    for (final m in _classSelectorRe.allMatches(File(path).readAsStringSync())) {
      out.add(m.group(1)!);
    }
  }
  return out;
}

void main() {
  final dartClasses = _dartClasses();
  final cssClasses = _cssDefined();

  final undefined = dartClasses.difference(cssClasses).toList()..sort();
  final orphan = cssClasses.difference(dartClasses).toList()..sort();

  print('Dart class references: ${dartClasses.length}');
  print('CSS class definitions: ${cssClasses.length}');
  print('Undefined (Dart → no CSS rule): ${undefined.length}');
  print('Orphan (CSS rule → no Dart ref): ${orphan.length}');

  if (undefined.isEmpty && orphan.isEmpty) {
    print('OK: all class references resolve.');
    return;
  }
  print('');
  if (undefined.isNotEmpty) {
    print('Undefined classes (used in Dart, no CSS rule):');
    for (final c in undefined) print('  .$c');
  }
  if (orphan.isNotEmpty) {
    print('Orphan classes (CSS rule exists, not used in Dart):');
    for (final c in orphan) print('  .$c');
  }
  // Don't exit 1 for orphans — CSS classes can be used in HTML templates,
  // markdown rendering, or admin-only flows. Only exit 1 for undefined.
  if (undefined.isNotEmpty) exit(1);
}
