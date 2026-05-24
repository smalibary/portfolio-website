/// The entrypoint for the **server** environment.
///
/// The [main] method runs only on the server during pre-rendering.
///
/// Fetches all content from Supabase before handing the loaded data to the
/// App. Pre-loading here (rather than inside build()) keeps the Jaspr
/// component contract synchronous.
library;

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

  runApp(App(site: site, posts: posts, papers: papers));
}
