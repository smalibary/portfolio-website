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
  final (cmd, cmdArgs) = _resolveJasprCmd();
  stdout.writeln('build :: jaspr cmd = $cmd ${cmdArgs.join(' ')}');
  stdout.writeln('build :: running `$cmd ${[...cmdArgs, 'build', ...args].join(' ')}`');
  final proc = await Process.start(
    cmd,
    [...cmdArgs, 'build', ...args],
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

/// Resolves the path to the jaspr CLI.
///
/// Tries, in order:
/// 1. Known pub-cache locations (Windows, macOS/Linux, PUB_CACHE override).
/// 2. Falls back to `dart run jaspr_cli:jaspr` which works from dev
///    dependencies without needing `dart pub global activate`.
///
/// Returns a record of (executable, [args...]) so callers can handle
/// multi-word commands like `dart run jaspr_cli:jaspr`.
(String, List<String>) _resolveJasprCmd() {
  // Candidate paths to check.
  final candidates = <String>[];

  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    candidates.add('$localAppData\\Pub\\Cache\\bin\\jaspr.bat');
  } else {
    final home = Platform.environment['HOME'] ?? '';
    final pubCache = Platform.environment['PUB_CACHE'] ?? '';
    if (pubCache.isNotEmpty) candidates.add('$pubCache/bin/jaspr');
    candidates.add('$home/.pub-cache/bin/jaspr');
  }

  for (final c in candidates) {
    if (File(c).existsSync()) return (c, []);
  }

  // Last resort: run jaspr_cli from the project's pub cache via dart run.
  // This avoids needing `dart pub global activate` entirely.
  stdout.writeln('build :: jaspr binary not found at $candidates');
  stdout.writeln('build :: falling back to dart run jaspr_cli:jaspr');
  return ('dart', ['run', 'jaspr_cli:jaspr']);
}
