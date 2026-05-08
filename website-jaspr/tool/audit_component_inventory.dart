// Verifies lib/components/COMPONENTS.md inventory table matches reality.
// Reports files that exist but aren't listed, and rows that point to
// missing files.
//
// Run: dart run tool/audit_component_inventory.dart

import 'dart:io';

final _tableRowRe = RegExp(r'^\|\s*`([^`]+)`\s*\|');

Set<String> _actualFiles() {
  final files = <String>{};
  for (final dir in [Directory('lib/components'), Directory('lib/components/admin')]) {
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync().whereType<File>()) {
      if (f.path.endsWith('.dart')) {
        files.add(f.path.replaceAll('\\', '/').replaceFirst('lib/components/', ''));
      }
    }
  }
  return files;
}

Set<String> _listedFiles() {
  final md = File('lib/components/COMPONENTS.md');
  if (!md.existsSync()) return {};
  final listed = <String>{};
  for (final line in md.readAsLinesSync()) {
    final m = _tableRowRe.firstMatch(line);
    if (m != null) listed.add(m.group(1)!);
  }
  return listed;
}

void main() {
  final actual = _actualFiles();
  final listed = _listedFiles();

  final unlisted = actual.difference(listed).toList()..sort();
  final missing = listed.difference(actual).toList()..sort();

  print('Actual component files: ${actual.length}');
  print('Listed in inventory: ${listed.length}');
  print('Unlisted files: ${unlisted.length}');
  print('Missing files: ${missing.length}');

  if (unlisted.isEmpty && missing.isEmpty) {
    print('OK: inventory matches component files.');
    return;
  }
  print('');
  if (unlisted.isNotEmpty) {
    print('Files not in inventory (forgot to update COMPONENTS.md):');
    for (final f in unlisted) print('  $f');
  }
  if (missing.isNotEmpty) {
    print('Inventory rows with no file (deleted but not removed from table):');
    for (final f in missing) print('  $f');
  }
  exit(1);
}
