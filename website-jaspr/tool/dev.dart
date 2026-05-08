/// Dev orchestrator. Runs `jaspr serve` and `tool/save_server.dart` together,
/// streaming both outputs to the same terminal. Ctrl+C kills both.
///
/// Run from website-jaspr/ root: `dart run tool/dev.dart`
library;

import 'dart:async';
import 'dart:io';

void main(List<String> args) async {
  stdout.writeln('dev :: starting jaspr serve + save_server');

  // 0. CSS token sanity check. Catches references like var(--space-4-5)
  //    that have no definition anywhere (the bug class fixed in Phase 2.5).
  //    Non-blocking — just prints a banner if anything is broken so the
  //    next bad reference shows up the next time dev boots.
  await _runAudits();

  // 1. start save_server in background
  final save = await Process.start(
    Platform.executable,
    ['run', 'tool/save_server.dart'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  _pipe(save.stdout, '[save] ');
  _pipe(save.stderr, '[save] ');

  // 2. start jaspr serve. The CLI is `dart pub global activate`-d, so its
  //    binary lives in the pub cache, not on PATH by default. Resolve the
  //    absolute path on Windows; otherwise rely on PATH.
  String jasprCmd;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final candidate = '$localAppData\\Pub\\Cache\\bin\\jaspr.bat';
    jasprCmd = File(candidate).existsSync() ? candidate : 'jaspr.bat';
  } else {
    final home = Platform.environment['HOME'] ?? '';
    final candidate = '$home/.pub-cache/bin/jaspr';
    jasprCmd = File(candidate).existsSync() ? candidate : 'jaspr';
  }
  stdout.writeln('dev :: jaspr cmd = $jasprCmd');
  final jaspr = await Process.start(
    jasprCmd,
    ['serve'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  _pipe(jaspr.stdout, '[jaspr] ');
  _pipe(jaspr.stderr, '[jaspr] ');

  // 3. clean shutdown on ctrl+c
  ProcessSignal.sigint.watch().listen((_) {
    stdout.writeln('\ndev :: shutting down');
    save.kill();
    jaspr.kill();
    exit(0);
  });

  // 4. wait for either to exit
  final firstToExit = await Future.any([
    save.exitCode.then((c) => ('save', c)),
    jaspr.exitCode.then((c) => ('jaspr', c)),
  ]);
  stdout.writeln('dev :: ${firstToExit.$1} exited (code ${firstToExit.$2}); killing the other');
  save.kill();
  jaspr.kill();
}

Future<void> _runAudits() async {
  final r = await Process.run(
    Platform.executable,
    ['run', 'tool/audit_all.dart'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  if (r.exitCode == 0) {
    stdout.writeln('dev :: audits ok');
    return;
  }
  stdout.writeln('');
  stdout.writeln('!! AUDIT SUITE FAILED:');
  stdout.write(r.stdout);
  stdout.write(r.stderr);
  stdout.writeln('!! (non-blocking; fix before committing)');
  stdout.writeln('');
}

void _pipe(Stream<List<int>> from, String prefix) {
  from.listen((bytes) {
    final text = String.fromCharCodes(bytes);
    for (final line in text.split('\n')) {
      if (line.isNotEmpty) stdout.writeln('$prefix$line');
    }
  });
}
