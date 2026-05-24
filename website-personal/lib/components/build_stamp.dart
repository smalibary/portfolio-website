import 'dart:io';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Self-contained build stamp — a tiny fixed corner badge showing which
/// deploy is live (branch@sha · time UTC). Everything it needs (the value
/// and the styling) lives in this one file.
///
/// To show it: drop `const BuildStamp()` into the server-rendered tree
/// (it's used once in app.dart).
/// To remove it entirely: delete this file and that one line. Nothing else
/// references it — no CSS in styles.css, no plumbing in main.server.dart.
///
/// Values come from Cloudflare Pages env at build time
/// (CF_PAGES_COMMIT_SHA, CF_PAGES_BRANCH), so it changes every deploy.
/// Locally those are unset, so it reads "local@dev".
class BuildStamp extends StatelessComponent {
  const BuildStamp({super.key});

  static String _label() {
    String two(int n) => n.toString().padLeft(2, '0');
    final sha = Platform.environment['CF_PAGES_COMMIT_SHA'] ?? '';
    final branch = Platform.environment['CF_PAGES_BRANCH'] ?? 'local';
    final shortSha =
        sha.isNotEmpty ? (sha.length >= 7 ? sha.substring(0, 7) : sha) : 'dev';
    final ts = DateTime.now().toUtc();
    final stamp =
        '${ts.year}-${two(ts.month)}-${two(ts.day)} ${two(ts.hour)}:${two(ts.minute)}';
    return '$branch@$shortSha · $stamp UTC';
  }

  // Inline style keeps the component fully self-contained — no styles.css
  // entry to clean up when this is deleted. position:fixed pins it to the
  // viewport (floats as you scroll); bottom-left corner. left/bottom are
  // explicit (not inset-inline-*) so it stays bottom-left regardless of RTL.
  static const _style =
      'position:fixed;bottom:8px;left:8px;z-index:9999;'
      'font-family:"JetBrains Mono",monospace;font-size:11px;letter-spacing:.02em;'
      'color:var(--color-text-faint);'
      'background:color-mix(in srgb,var(--color-surface-card) 88%,transparent);'
      'border:1px solid var(--color-border-default);border-radius:6px;'
      'padding:2px 8px;opacity:.5;'
      'pointer-events:none;';

  @override
  Component build(BuildContext context) {
    return div(
      attributes: const {'style': _style, 'title': 'current deploy'},
      [text(_label())],
    );
  }
}
