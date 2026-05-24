/// The entrypoint for the **server** environment.
///
/// The [main] method runs only on the server during pre-rendering.
///
/// Fetches all content from Supabase before handing the loaded data to the
/// App. Pre-loading here (rather than inside build()) keeps the Jaspr
/// component contract synchronous.
library;

import 'dart:io';

import 'package:jaspr/server.dart';

import 'app.dart';
import 'data/blog_data.dart';
import 'data/paper_data.dart';
import 'data/site_data.dart';
import 'main.server.options.dart';

Future<void> main() async {
  Jaspr.initializeApp(options: defaultServerOptions);

  final site = await SiteData.load();
  final posts = await BlogPost.loadAll();
  final papers = await Paper.loadAll();

  runApp(App(
    site: site,
    posts: posts,
    papers: papers,
    buildLabel: _buildLabel(),
  ));
}

/// Build stamp shown in the corner of every page so you can tell which deploy
/// is live. Cloudflare Pages sets CF_PAGES_COMMIT_SHA + CF_PAGES_BRANCH during
/// CI, so this changes automatically on every preview/production deploy.
/// Locally these are unset, so it shows "local@dev".
String _buildLabel() {
  String two(int n) => n.toString().padLeft(2, '0');
  final sha = Platform.environment['CF_PAGES_COMMIT_SHA'] ?? '';
  final branch = Platform.environment['CF_PAGES_BRANCH'] ?? 'local';
  final shortSha = sha.isNotEmpty
      ? (sha.length >= 7 ? sha.substring(0, 7) : sha)
      : 'dev';
  final ts = DateTime.now().toUtc();
  final stamp =
      '${ts.year}-${two(ts.month)}-${two(ts.day)} ${two(ts.hour)}:${two(ts.minute)}';
  return '$branch@$shortSha · $stamp UTC';
}
