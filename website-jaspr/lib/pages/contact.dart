import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/nav.dart';
import '../components/footer.dart';
import '../data/site_data.dart';

/// Contact / تواصل page — placeholder until content is ready.
class ContactPage extends StatelessComponent {
  const ContactPage({required this.site, super.key});
  final SiteData site;

  @override
  Component build(BuildContext context) {
    return div([
      Nav(site: site),
      main_(classes: 'placeholder-page', [
        div(classes: 'placeholder-page__inner', [
          h1([text('تواصل · CONTACT')]),
          p([text('This page is under construction. Content coming soon.')]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}
