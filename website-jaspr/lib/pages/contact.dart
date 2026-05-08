import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../components/nav.dart';
import '../components/footer.dart';
import '../data/site_data.dart';

/// Contact / تواصل page — contact form.
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

        // Contact form
        form(classes: 'contact-form', attributes: {'action': '#', 'method': 'POST'}, [
          div(classes: 'contact-form__row', [
            div(classes: 'contact-form__field', [
              label([text('الاسم · NAME')]),
              input(type: InputType.text, attributes: {'name': 'name', 'required': '', 'placeholder': 'اسمك · Your name'}),
            ]),
            div(classes: 'contact-form__field', [
              label([text('البريد الإلكتروني · EMAIL')]),
              input(type: InputType.email, attributes: {'name': 'email', 'required': '', 'placeholder': 'email@example.com'}),
            ]),
          ]),
          div(classes: 'contact-form__field', [
            label([text('الموضوع · SUBJECT')]),
            select(attributes: {'name': 'subject', 'required': ''}, [
              option(value: '', [text('اختر الموضوع · Choose a topic')]),
              option(value: 'research', [text('بحث/تعاون أكاديمي · Research / Academic collaboration')]),
              option(value: 'consulting', [text('استشارات · Consulting')]),
              option(value: 'speaking', [text('محاضرة/تحدث · Speaking / Talk')]),
              option(value: 'general', [text('سؤال عام · General question')]),
            ]),
          ]),
          div(classes: 'contact-form__field', [
            label([text('الرسالة · MESSAGE')]),
            textarea(attributes: {'name': 'message', 'required': '', 'rows': '6', 'placeholder': 'اكتب رسالتك هنا · Write your message here...'}, []),
          ]),
          button(type: ButtonType.submit, classes: 'contact-form__submit', [
            text('إرسال الرسالة · SEND MESSAGE'),
          ]),
        ]),

        // Alternative ways to reach
        section(classes: 'contact-alt', [
          h2([text('طرق أخرى للتواصل · OTHER WAYS TO REACH ME')]),
          div(classes: 'contact-alt__grid', [
            if (socials.containsKey('linkedin'))
              a(href: socials['linkedin']!, classes: 'contact-alt__card', attributes: {'target': '_blank', 'rel': 'noopener'}, [
                raw('<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>'),
                span(classes: 'contact-alt__label', [text('LINKEDIN')]),
                span(classes: 'contact-alt__value', [text('Salem Malibary')]),
              ]),
            if (socials.containsKey('scholar'))
              a(href: socials['scholar']!, classes: 'contact-alt__card', attributes: {'target': '_blank', 'rel': 'noopener'}, [
                raw('<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M5.242 13.769L0 9.5 12 0l12 9.5-5.242 4.269C17.548 11.249 14.978 9.5 12 9.5c-2.977 0-5.548 1.748-6.758 4.269zM12 10a7 7 0 1 0 0 14 7 7 0 0 0 0-14z"/></svg>'),
                span(classes: 'contact-alt__label', [text('GOOGLE SCHOLAR')]),
                span(classes: 'contact-alt__value', [text('Research & citations')]),
              ]),
            if (socials.containsKey('github'))
              a(href: socials['github']!, classes: 'contact-alt__card', attributes: {'target': '_blank', 'rel': 'noopener'}, [
                raw('<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.4 0 0 5.4 0 12c0 5.3 3.4 9.8 8.2 11.4.6.1.8-.3.8-.6v-2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1.1-.7.1-.7.1-.7 1.2.1 1.9 1.2 1.9 1.2 1.1 1.9 2.9 1.4 3.6 1 .1-.8.4-1.4.8-1.7-2.7-.3-5.5-1.3-5.5-5.9 0-1.3.5-2.4 1.2-3.2-.1-.3-.5-1.5.1-3.2 0 0 1-.3 3.3 1.2.9-.3 2-.4 3-.4s2 .1 3 .4c2.3-1.5 3.3-1.2 3.3-1.2.7 1.7.2 2.9.1 3.2.8.8 1.2 1.9 1.2 3.2 0 4.6-2.8 5.6-5.5 5.9.4.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6C20.6 21.8 24 17.3 24 12c0-6.6-5.4-12-12-12z"/></svg>'),
                span(classes: 'contact-alt__label', [text('GITHUB')]),
                span(classes: 'contact-alt__value', [text('smalibary')]),
              ]),
          ]),
        ]),
      ]),
      SiteFooter(),
    ]);
  }
}
