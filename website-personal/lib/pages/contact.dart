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

        // Compact two-column layout: form (left, wider) + alt links (right)
        div(classes: 'contact-grid', [
          // Contact form — mirrors the chat bubble fields so visitors get
          // feature parity whichever path they pick. Submits via fetch to
          // /api/contact with source='form' so the email subject reveals
          // which surface drove the conversion.
          form(id: 'contactForm', classes: 'contact-form', attributes: {'novalidate': ''}, [
            div(classes: 'contact-form__row', [
              div(classes: 'contact-form__field', [
                label([text('الاسم · NAME *')]),
                input(type: InputType.text, attributes: {'name': 'name', 'required': '', 'maxlength': '80', 'placeholder': 'اسمك', 'autocomplete': 'name'}),
              ]),
              div(classes: 'contact-form__field', [
                label([text('البريد · EMAIL *')]),
                input(type: InputType.email, attributes: {'name': 'email', 'required': '', 'maxlength': '120', 'placeholder': 'email@example.com', 'autocomplete': 'email'}),
              ]),
            ]),
            div(classes: 'contact-form__field', [
              label([text('الموضوع · TOPIC *')]),
              div(classes: 'cf-select', [
                input(
                  type: InputType.hidden,
                  attributes: {'name': 'reason', 'data-cf-value': '', 'required': ''},
                ),
                button(
                  classes: 'cf-select__btn',
                  attributes: {'type': 'button', 'data-cf-toggle': '', 'aria-haspopup': 'listbox'},
                  [
                    span(classes: 'cf-select__label', [text('اختر الموضوع · Choose a topic')]),
                    span(classes: 'cf-select__arrow', [
                      span(classes: 'cf-select__arrow-down', [text('▼')]),
                      span(classes: 'cf-select__arrow-up', [text('▲')]),
                    ]),
                  ],
                ),
                div(classes: 'cf-select__menu', attributes: {'role': 'listbox'}, [
                  button(classes: 'cf-select__opt', attributes: {'type': 'button', 'data-cf-opt': 'project'},  [text('بدء مشروع · Start a project')]),
                  button(classes: 'cf-select__opt', attributes: {'type': 'button', 'data-cf-opt': 'hire'},     [text('توظيف / تعاون · Hire / collaborate')]),
                  button(classes: 'cf-select__opt', attributes: {'type': 'button', 'data-cf-opt': 'press'},    [text('صحافة أو محاضرات · Press or speaking')]),
                  button(classes: 'cf-select__opt', attributes: {'type': 'button', 'data-cf-opt': 'question'}, [text('سؤال عام · General question')]),
                  button(classes: 'cf-select__opt', attributes: {'type': 'button', 'data-cf-opt': 'feedback'}, [text('ملاحظة أو اقتراح · Feedback or suggestion')]),
                  button(classes: 'cf-select__opt', attributes: {'type': 'button', 'data-cf-opt': 'other'},    [text('شيء آخر · Something else')]),
                ]),
              ]),
            ]),
            // "Other" reveal — only visible when reason=other.
            div(id: 'reasonOtherWrap', classes: 'contact-form__field', attributes: {'hidden': ''}, [
              label([text('عن ماذا؟ · ABOUT WHAT?')]),
              input(type: InputType.text, attributes: {'name': 'reason_other', 'maxlength': '120', 'placeholder': 'باختصار…'}),
            ]),
            // Phone with country code — optional. Native <select> keeps it
            // "old school" and gives a proper mobile picker for free.
            div(classes: 'contact-form__field', [
              label([text('الجوال (اختياري) · PHONE (optional)')]),
              div(classes: 'contact-form__phone', [
                select(
                  _countryCodeOptions(),
                  name: 'phone_cc',
                  classes: 'contact-form__phone-cc',
                  attributes: {'aria-label': 'Country code'},
                ),
                input(type: InputType.tel, attributes: {'name': 'phone', 'maxlength': '20', 'placeholder': '5XX XXX XXX', 'autocomplete': 'tel-national', 'inputmode': 'tel'}),
              ]),
            ]),
            div(classes: 'contact-form__field', [
              label([text('الرسالة · MESSAGE *')]),
              textarea(attributes: {'name': 'message', 'required': '', 'rows': '4', 'maxlength': '2000', 'placeholder': 'اكتب رسالتك هنا...'}, []),
            ]),
            // Honeypot — visually hidden, bots fill it.
            div(classes: 'contact-form__honeypot', attributes: {'aria-hidden': 'true'}, [
              label([text('Website')]),
              input(type: InputType.text, attributes: {'name': 'website', 'tabindex': '-1', 'autocomplete': 'off'}),
            ]),
            // Hidden tag so we can see in the email whether the form or
            // the chat drove the lead.
            input(type: InputType.hidden, attributes: {'name': 'source', 'value': 'form'}),
            div(classes: 'contact-form__actions', [
              button(type: ButtonType.submit, id: 'contactSubmit', classes: 'contact-form__submit', [
                text('إرسال · SEND'),
              ]),
              span(id: 'contactFormStatus', classes: 'contact-form__status', []),
            ]),
          ]),

          // Alternative ways to reach
          section(classes: 'contact-alt', [
            h2([text('أو تواصل عبر · OR REACH ME VIA')]),
            div(classes: 'contact-alt__grid', [
              if (socials.containsKey('linkedin'))
                a(href: socials['linkedin']!, classes: 'contact-alt__card', attributes: {'target': '_blank', 'rel': 'noopener'}, [
                  raw('<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>'),
                  div(classes: 'contact-alt__card-text', [
                    span(classes: 'contact-alt__label', [text('LINKEDIN')]),
                    span(classes: 'contact-alt__value', [text('Salem Malibary')]),
                  ]),
                  span(classes: 'contact-alt__card-arrow', [text('◀')]),
                ]),
              if (socials.containsKey('scholar'))
                a(href: socials['scholar']!, classes: 'contact-alt__card', attributes: {'target': '_blank', 'rel': 'noopener'}, [
                  raw('<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M5.242 13.769L0 9.5 12 0l12 9.5-5.242 4.269C17.548 11.249 14.978 9.5 12 9.5c-2.977 0-5.548 1.748-6.758 4.269zM12 10a7 7 0 1 0 0 14 7 7 0 0 0 0-14z"/></svg>'),
                  div(classes: 'contact-alt__card-text', [
                    span(classes: 'contact-alt__label', [text('SCHOLAR')]),
                    span(classes: 'contact-alt__value', [text('Research')]),
                  ]),
                  span(classes: 'contact-alt__card-arrow', [text('◀')]),
                ]),
              if (socials.containsKey('github'))
                a(href: socials['github']!, classes: 'contact-alt__card', attributes: {'target': '_blank', 'rel': 'noopener'}, [
                  raw('<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.4 0 0 5.4 0 12c0 5.3 3.4 9.8 8.2 11.4.6.1.8-.3.8-.6v-2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1.1-.7.1-.7.1-.7 1.2.1 1.9 1.2 1.9 1.2 1.1 1.9 2.9 1.4 3.6 1 .1-.8.4-1.4.8-1.7-2.7-.3-5.5-1.3-5.5-5.9 0-1.3.5-2.4 1.2-3.2-.1-.3-.5-1.5.1-3.2 0 0 1-.3 3.3 1.2.9-.3 2-.4 3-.4s2 .1 3 .4c2.3-1.5 3.3-1.2 3.3-1.2.7 1.7.2 2.9.1 3.2.8.8 1.2 1.9 1.2 3.2 0 4.6-2.8 5.6-5.5 5.9.4.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6C20.6 21.8 24 17.3 24 12c0-6.6-5.4-12-12-12z"/></svg>'),
                  div(classes: 'contact-alt__card-text', [
                    span(classes: 'contact-alt__label', [text('GITHUB')]),
                    span(classes: 'contact-alt__value', [text('smalibary')]),
                  ]),
                  span(classes: 'contact-alt__card-arrow', [text('◀')]),
                ]),
            ]),
          ]),
        ]),
      ]),
      SiteFooter(),
      script(content: _selectScript),
    ]);
  }

  // Country code options for the phone <select>. Curated list — GCC at
   // the top, then a few common global codes.
  static List<Component> _countryCodeOptions() {
    const list = <List<String>>[
      ['+966', '🇸🇦 Saudi Arabia · +966'],
      ['+971', '🇦🇪 UAE · +971'],
      ['+965', '🇰🇼 Kuwait · +965'],
      ['+974', '🇶🇦 Qatar · +974'],
      ['+973', '🇧🇭 Bahrain · +973'],
      ['+968', '🇴🇲 Oman · +968'],
      ['+20',  '🇪🇬 Egypt · +20'],
      ['+962', '🇯🇴 Jordan · +962'],
      ['+961', '🇱🇧 Lebanon · +961'],
      ['+90',  '🇹🇷 Türkiye · +90'],
      ['+1',   '🇺🇸 US / Canada · +1'],
      ['+44',  '🇬🇧 United Kingdom · +44'],
      ['+61',  '🇦🇺 Australia · +61'],
      ['+33',  '🇫🇷 France · +33'],
      ['+49',  '🇩🇪 Germany · +49'],
      ['+91',  '🇮🇳 India · +91'],
      ['+92',  '🇵🇰 Pakistan · +92'],
      ['+62',  '🇮🇩 Indonesia · +62'],
      ['+60',  '🇲🇾 Malaysia · +60'],
    ];
    return [
      for (final c in list)
        option([text(c[1])], value: c[0], selected: c[0] == '+966'),
    ];
  }

  static const _selectScript = r'''
(function(){
  document.querySelectorAll('.cf-select').forEach(function(sel){
    var btn = sel.querySelector('[data-cf-toggle]');
    var menu = sel.querySelector('.cf-select__menu');
    var input = sel.querySelector('[data-cf-value]');
    var label = sel.querySelector('.cf-select__label');
    if (!btn || !menu || !input) return;
    btn.addEventListener('click', function(e){
      e.stopPropagation();
      sel.classList.toggle('open');
    });
    document.addEventListener('click', function(e){
      if (!sel.contains(e.target)) sel.classList.remove('open');
    });
    sel.querySelectorAll('[data-cf-opt]').forEach(function(opt){
      opt.addEventListener('click', function(){
        input.value = opt.getAttribute('data-cf-opt');
        if (label) label.textContent = opt.textContent;
        sel.classList.add('has-value');
        sel.classList.remove('open');
        // Reveal "other" sub-field when needed
        var otherWrap = document.getElementById('reasonOtherWrap');
        if (otherWrap && input.getAttribute('name') === 'reason') {
          if (opt.getAttribute('data-cf-opt') === 'other') otherWrap.removeAttribute('hidden');
          else otherWrap.setAttribute('hidden', '');
        }
      });
    });
  });

  // Form submit — fetch POST to /api/contact, no full page reload.
  var formEl = document.getElementById('contactForm');
  if (!formEl) return;
  var submitBtn = document.getElementById('contactSubmit');
  var status    = document.getElementById('contactFormStatus');
  var EMAIL_RE  = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

  function setStatus(kind, msg){
    status.className = 'contact-form__status' + (kind ? ' contact-form__status--' + kind : '');
    status.textContent = msg || '';
  }

  formEl.addEventListener('submit', function(e){
    e.preventDefault();
    setStatus('', '');

    var fd = new FormData(formEl);
    var data = {
      name:         (fd.get('name') || '').toString().trim(),
      email:        (fd.get('email') || '').toString().trim(),
      reason:       (fd.get('reason') || '').toString(),
      reason_other: (fd.get('reason_other') || '').toString().trim(),
      phone_cc:     (fd.get('phone_cc') || '+966').toString(),
      phone_raw:    (fd.get('phone') || '').toString().trim(),
      message:      (fd.get('message') || '').toString().trim(),
      website:      (fd.get('website') || '').toString(),
      source:       'form',
      page:         location.pathname,
    };

    if (!data.name)  return setStatus('err', 'الاسم مطلوب · Name is required.');
    if (!data.email || !EMAIL_RE.test(data.email))
      return setStatus('err', 'البريد غير صحيح · Please enter a valid email.');
    if (!data.reason) return setStatus('err', 'اختر الموضوع · Please pick a topic.');
    if (data.message.length < 2) return setStatus('err', 'الرسالة مطلوبة · Message is required.');
    if (data.phone_raw) {
      var digits = data.phone_raw.replace(/[^\d]/g, '');
      if (digits.length < 6 || digits.length > 15)
        return setStatus('err', 'الرقم غير صحيح · Phone number looks off.');
    }

    var payload = {
      reason:       data.reason,
      reason_other: data.reason_other,
      name:         data.name,
      email:        data.email,
      phone:        data.phone_raw ? (data.phone_cc + ' ' + data.phone_raw) : '',
      message:      data.message,
      website:      data.website,
      source:       'form',
      page:         data.page,
    };

    submitBtn.disabled = true;
    submitBtn.textContent = '...جارٍ الإرسال · Sending';
    setStatus('info', '...');

    fetch('/api/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
      .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, body: j }; }); })
      .then(function(res){
        if (res.ok && res.body && res.body.ok) {
          setStatus('ok', '✓ وصلتك رسالتك · Got it — Salem will reply soon.');
          formEl.reset();
          document.querySelectorAll('.cf-select').forEach(function(s){
            s.classList.remove('has-value');
            var lbl = s.querySelector('.cf-select__label');
            if (lbl) lbl.textContent = 'اختر الموضوع · Choose a topic';
            var hid = s.querySelector('[data-cf-value]');
            if (hid) hid.value = '';
          });
          var otherWrap = document.getElementById('reasonOtherWrap');
          if (otherWrap) otherWrap.setAttribute('hidden', '');
        } else {
          var err = (res.body && res.body.error) || 'حدث خطأ · Something went wrong — try again.';
          setStatus('err', err);
        }
      })
      .catch(function(){
        setStatus('err', 'تعذر الاتصال · Connection error — check your network.');
      })
      .then(function(){
        submitBtn.disabled = false;
        submitBtn.textContent = 'إرسال · SEND';
      });
  });
})();
''';
}
