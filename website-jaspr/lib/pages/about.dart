import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/nav.dart';
import '../components/footer.dart';
import '../data/site_data.dart';

/// About / السيرة page — placeholder until content is ready.
class AboutPage extends StatelessComponent {
  const AboutPage({required this.site, super.key});
  final SiteData site;

  @override
  Component build(BuildContext context) {
    return div([
      Nav(site: site),
      main_(classes: 'placeholder-page', [
        div(classes: 'placeholder-page__inner', [
          h1([text('السيرة · ABOUT')]),
          p([text('This page is under construction. Content coming soon.')]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}
