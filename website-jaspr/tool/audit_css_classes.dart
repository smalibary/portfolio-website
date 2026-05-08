// Cross-references CSS class names used in Dart (classes: '...') against
// rules defined in web/*.css. Reports unreferenced and orphan classes.
//
// Run: dart run tool/audit_css_classes.dart

import 'dart:io';

/// Classes used as DOM hooks without their own CSS rule.
/// Styled by a co-class on the same element — not a bug.
const _styledByCoclass = {
  'hero__left', // styled by sibling sq-frame
  'portrait-img', // styled by portrait-img--dark/light variants
  'sg-motif-bar', // styled by sibling sg-motif-item
};

/// Classes that are semantic wrappers or empty-state markers, deliberately
/// unstyled. Children get their own classes; the parent is just a label.
const _intentionallyPlain = {
  'research__empty', // empty-state text, deliberately unstyled
  'writing__empty', // empty-state text, deliberately unstyled
  'toc', // semantic wrapper, see .toc__link for styling
};

final _classesArgRe = RegExp(r"classes:\s*'([^']+)'");
final _classSelectorRe = RegExp(r'\.([a-zA-Z][a-zA-Z0-9_-]*)');

/// Collect all class names passed to `classes:` in Dart files under lib/.
Set<String> _dartClasses() {
  final out = <String>{};
  for (final dir in [Directory('lib/components'), Directory('lib/pages')]) {
    if (!dir.existsSync()) continue;
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
  }
  return out;
}

/// Collect all class selectors from CSS files.
Set<String> _cssDefined() {
  final out = <String>{};
  final paths = ['web/styles.css', 'web/admin.css'];
  // Also scan the _css string constant in styleguide.dart — it defines
  // rules for sg-* classes that live outside the main CSS files.
  final sg = File('lib/pages/admin/styleguide.dart');
  if (sg.existsSync()) paths.add(sg.path);
  for (final path in paths) {
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

  final undefined = dartClasses
      .difference(cssClasses)
      .difference(_styledByCoclass)
      .difference(_intentionallyPlain)
      .toList()
    ..sort();
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
