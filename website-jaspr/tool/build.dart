/// Production build orchestrator.
///
/// 1. Regenerates `web/sitemap.xml` from current content.
/// 2. Runs `jaspr build` to produce static output in `build/jaspr/`.
///
/// Always use this instead of calling `jaspr build` directly — running
/// `jaspr build` alone leaves a stale `sitemap.xml` whenever a post has
/// been added or had its date changed since the last sitemap run.
///
/// Run from website-jaspr/ root: `dart run tool/build.dart`
library;

import 'dart:async';
import 'dart:io';

import 'generate_sitemap.dart' as sitemap;

Future<void> main(List<String> args) async {
  // Step 1 — sitemap.
  stdout.writeln('build :: regenerating sitemap.xml');
  try {
    final n = await sitemap.writeSitemap();
    stdout.writeln('build :: wrote web/sitemap.xml ($n URLs)');
  } catch (e) {
    stderr.writeln('build :: sitemap generation failed: $e');
    exitCode = 1;
    return;
  }

  // Step 2 — jaspr build.
  final jasprCmd = _resolveJasprCmd();
  stdout.writeln('build :: jaspr cmd = $jasprCmd');
  stdout.writeln('build :: running `$jasprCmd build`');
  final proc = await Process.start(
    jasprCmd,
    ['build', ...args],
    workingDirectory: Directory.current.path,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await proc.exitCode;
  if (code != 0) {
    stderr.writeln('build :: jaspr build exited with code $code');
    exitCode = code;
    return;
  }
  stdout.writeln('build :: done. Static output is in build/jaspr/.');
}

/// Resolves the path to the jaspr CLI. Pub global binaries on Windows
/// live under `%LOCALAPPDATA%\Pub\Cache\bin`, which isn't on PATH by
/// default; on POSIX it's `~/.pub-cache/bin`. Mirrors `tool/dev.dart`.
String _resolveJasprCmd() {
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final candidate = '$localAppData\\Pub\\Cache\\bin\\jaspr.bat';
    return File(candidate).existsSync() ? candidate : 'jaspr.bat';
  }
  final home = Platform.environment['HOME'] ?? '';
  final candidate = '$home/.pub-cache/bin/jaspr';
  return File(candidate).existsSync() ? candidate : 'jaspr';
}
