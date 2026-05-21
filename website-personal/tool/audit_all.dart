// Aggregator: runs all audit checkers in sequence and prints a summary.
// Exit code 0 if all pass, 1 if any fail.
//
// Usage:
//   dart run tool/audit_all.dart           # fast checks only (boot-safe)
//   dart run tool/audit_all.dart --full    # all checks including noisy ones
//
// Run: dart run tool/audit_all.dart

import 'dart:io';

final _fastCheckers = [
  'tool/audit_css_tokens.dart',
  'tool/audit_deprecated_aliases.dart',
  'tool/audit_theme_parity.dart',
  'tool/audit_component_inventory.dart',
];

final _fullCheckers = [
  'tool/audit_orphan_tokens.dart',
  'tool/audit_css_classes.dart',
  'tool/audit_hardcoded_values.dart',
];

void main(List<String> args) async {
  final full = args.contains('--full');
  final checkers = [..._fastCheckers, if (full) ..._fullCheckers];

  print('╌╌╌ audit suite (${full ? "full" : "fast"}) ╌╌╌');
  print('');

  final results = <({String name, int exitCode, String output})>[];
  var anyFail = false;

  for (final checker in checkers) {
    final name = checker.split('/').last.replaceAll('.dart', '');
    final r = await Process.run(
      Platform.executable,
      ['run', checker],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    final output = (r.stdout as String).trim();
    results.add((name: name, exitCode: r.exitCode, output: output));
    if (r.exitCode != 0) anyFail = true;
  }

  // Print per-checker summary
  for (final r in results) {
    final status = r.exitCode == 0 ? 'ok' : 'FAIL';
    print('  ${r.name.padRight(35)} $status');
    // If failed, print the checker's output
    if (r.exitCode != 0 && r.output.isNotEmpty) {
      for (final line in r.output.split('\n')) {
        print('    $line');
      }
      print('');
    }
  }

  print('');
  if (anyFail) {
    print('✗ some checks failed');
    exit(1);
  }
  print('✓ all checks passed');
}
