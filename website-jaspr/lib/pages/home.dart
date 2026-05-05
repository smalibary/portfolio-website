import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/footer.dart';
import '../components/hero.dart';
import '../components/nav.dart';
import '../components/research_grid.dart';
import '../components/writing_list.dart';
import '../data/blog_data.dart';
import '../data/paper_data.dart';
import '../data/site_data.dart';

class HomePage extends StatelessComponent {
  const HomePage({
    required this.site,
    required this.posts,
    required this.papers,
    super.key,
  });
  final SiteData site;
  final List<BlogPost> posts;
  final List<Paper> papers;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Nav(site: site),
      main_([
        Hero(site: site),
        ResearchGrid(papers: papers),
        WritingList(posts: posts),
      ]),
      SiteFooter(),
    ]);
  }
}
