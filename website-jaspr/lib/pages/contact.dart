import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/nav.dart';
import '../components/footer.dart';
import '../data/site_data.dart';

/// Contact / تواصل page.
class ContactPage extends StatelessComponent {
  const ContactPage({required this.site, super.key});
  final SiteData site;

  @override
  Component build(BuildContext context) {
    final socials = site.socials;
    final email = socials['email'] ?? '';
    final emailAddr = email.replaceFirst('mailto:', '');

    return div([
      Nav(site: site),
      main_(classes: 'contact-page', [
        // Header
        header(classes: 'contact-header', [
          div(classes: 'section-head', [
            h1([text('تواصل · CONTACT')]),
          ]),
          p(classes: 'contact-lede', [
            text('أسعد بالتواصل حول الأبحاث، التعاون الأكاديمي، الاستشارات، أو أي أسئلة.'),
          ]),
          p(classes: 'contact-lede-en', [
            text('Happy to connect about research, academic collaboration, consulting, or any questions.'),
          ]),
        ]),

        // Email — primary CTA
        section(classes: 'contact-section', [
          h2([text('البريد الإلكتروني · EMAIL')]),
          a(href: email.isNotEmpty ? email : '#', classes: 'contact-email', [
            text(emailAddr.isNotEmpty ? emailAddr : 'salimmalibari@gmail.com'),
          ]),
        ]),

        // Social links
        section(classes: 'contact-section', [
          h2([text('أين تجدني · FIND ME ONLINE')]),
          div(classes: 'contact-links', [
            if (socials.containsKey('linkedin'))
              a(href: socials['linkedin']!, classes: 'contact-link', [
                span(classes: 'contact-link__label', [text('LinkedIn')]),
                span(classes: 'contact-link__desc', [text('الشبكة المهنية · Professional network')]),
              ]),
            if (socials.containsKey('scholar'))
              a(href: socials['scholar']!, classes: 'contact-link', [
                span(classes: 'contact-link__label', [text('Google Scholar')]),
                span(classes: 'contact-link__desc', [text('الأبحاث والاستشهادات · Research & citations')]),
              ]),
            if (socials.containsKey('orcid'))
              a(href: socials['orcid']!, classes: 'contact-link', [
                span(classes: 'contact-link__label', [text('ORCID')]),
                span(classes: 'contact-link__desc', [text('المعرف البحثي · Researcher ID')]),
              ]),
            if (socials.containsKey('github'))
              a(href: socials['github']!, classes: 'contact-link', [
                span(classes: 'contact-link__label', [text('GitHub')]),
                span(classes: 'contact-link__desc', [text('المشاريع البرمجية · Code & projects')]),
              ]),
            if (socials.containsKey('x'))
              a(href: socials['x']!, classes: 'contact-link', [
                span(classes: 'contact-link__label', [text('X (Twitter)')]),
                span(classes: 'contact-link__desc', [text('المحادثات العامة · Public conversations')]),
              ]),
            if (socials.containsKey('youtube'))
              a(href: socials['youtube']!, classes: 'contact-link', [
                span(classes: 'contact-link__label', [text('YouTube')]),
                span(classes: 'contact-link__desc', [text('المحتوى المرئي · Video content')]),
              ]),
          ]),
        ]),

        // Academic affiliations
        section(classes: 'contact-section', [
          h2([text('الانتماءات الأكاديمية · AFFILIATIONS')]),
          div(classes: 'contact-affils', [
            div(classes: 'contact-affil', [
              span(classes: 'contact-affil__role', [text('PhD Candidate')]),
              span(classes: 'contact-affil__org', [text('University of Sydney · Indoor Environments Lab')]),
              span(classes: 'contact-affil__dept', [text('School of Architecture, Design and Planning')]),
            ]),
            div(classes: 'contact-affil', [
              span(classes: 'contact-affil__role', [text('Lecturer')]),
              span(classes: 'contact-affil__org', [text('King Abdulaziz University · جامعة الملك عبدالعزيز')]),
              span(classes: 'contact-affil__dept', [text('Department of Architecture · قسم العمارة')]),
            ]),
          ]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}
