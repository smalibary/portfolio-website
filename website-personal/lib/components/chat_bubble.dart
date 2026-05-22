import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: organism (global)
/// Floating chat bubble + conversational contact panel. Renders on every
/// page via App. State machine and validation live in the inline script;
/// submit POSTs to /api/contact (a Cloudflare Pages Function backed by
/// Resend). Recipient is configured in the function via CONTACT_EMAIL.
class ChatBubble extends StatelessComponent {
  const ChatBubble({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // Toggle button (always visible, fixed bottom-end)
      button(
        id: 'chat-bubble',
        classes: 'chat-bubble',
        attributes: const {
          'type': 'button',
          'aria-label': 'افتح المحادثة · Open chat',
          'aria-expanded': 'false',
          'aria-controls': 'chat-panel',
        },
        [
          span(classes: 'chat-bubble__icon chat-bubble__icon--open', [
            raw('<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>'),
          ]),
          span(classes: 'chat-bubble__icon chat-bubble__icon--close', [
            raw('<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>'),
          ]),
        ],
      ),

      // Panel (hidden by default; toggled via .open on body wrapper)
      div(
        id: 'chat-panel',
        classes: 'chat-panel',
        attributes: const {'role': 'dialog', 'aria-label': 'Chat with Salem', 'aria-hidden': 'true'},
        [
          // Header
          div(classes: 'chat-panel__header', [
            div(classes: 'chat-panel__title', [
              span(classes: 'chat-panel__dot', []),
              span([text('Salem · سالم')]),
            ]),
            span(classes: 'chat-panel__sub', [text('عادة يرد خلال يوم · usually replies within a day')]),
          ]),

          // Conversation feed
          div(id: 'chat-feed', classes: 'chat-feed', [
            div(classes: 'chat-msg chat-msg--bot', [
              p([text('مرحباً 👋 شكراً لمرورك. كيف يمكنني مساعدتك؟')]),
              p(classes: 'chat-msg__en', [text("Hi! Thanks for stopping by. What brings you here?")]),
            ]),
          ]),

          // Stage 1: choices
          div(id: 'chat-choices', classes: 'chat-choices', [
            _choice('project', 'بدء مشروع', 'Start a project'),
            _choice('hire', 'توظيف / تعاون', 'Hire / collaborate'),
            _choice('press', 'صحافة أو محاضرات', 'Press or speaking'),
            _choice('question', 'سؤال عام', 'General question'),
            _choice('feedback', 'ملاحظة أو اقتراح', 'Feedback or suggestion'),
            _choice('other', 'شيء آخر…', 'Something else…'),
          ]),

          // Stage 2: form (hidden until a choice is made)
          form(
            id: 'chat-form',
            classes: 'chat-form',
            attributes: const {'novalidate': '', 'hidden': ''},
            [
              // Hidden — captures the choice (or free-text from "other")
              input(type: InputType.hidden, attributes: const {'name': 'reason', 'id': 'cb-reason'}),

              // "Other" free-text (hidden unless 'other' was picked)
              div(id: 'cb-other-wrap', classes: 'chat-form__field', attributes: const {'hidden': ''}, [
                label(attributes: const {'for': 'cb-other'}, [text('عن ماذا؟ · ABOUT WHAT?')]),
                input(
                  type: InputType.text,
                  id: 'cb-other',
                  attributes: const {'name': 'reason_other', 'maxlength': '120', 'placeholder': 'باختصار…'},
                ),
              ]),

              div(classes: 'chat-form__field', [
                label(attributes: const {'for': 'cb-name'}, [text('الاسم · NAME *')]),
                input(
                  type: InputType.text,
                  id: 'cb-name',
                  attributes: const {'name': 'name', 'required': '', 'maxlength': '80', 'autocomplete': 'name'},
                ),
                span(classes: 'chat-form__error', attributes: const {'data-error-for': 'cb-name'}, []),
              ]),

              div(classes: 'chat-form__field', [
                label(attributes: const {'for': 'cb-email'}, [text('البريد · EMAIL *')]),
                input(
                  type: InputType.email,
                  id: 'cb-email',
                  attributes: const {'name': 'email', 'required': '', 'maxlength': '120', 'autocomplete': 'email', 'placeholder': 'you@example.com'},
                ),
                span(classes: 'chat-form__error', attributes: const {'data-error-for': 'cb-email'}, []),
              ]),

              div(classes: 'chat-form__field', [
                label(attributes: const {'for': 'cb-phone'}, [text('الجوال (اختياري) · PHONE (optional)')]),
                div(classes: 'chat-phone', [
                  // Country code dropdown
                  div(classes: 'chat-phone__cc', [
                    button(
                      classes: 'chat-phone__cc-btn',
                      attributes: const {'type': 'button', 'aria-haspopup': 'listbox', 'aria-expanded': 'false'},
                      [
                        span(classes: 'chat-phone__cc-flag', [text('🇸🇦')]),
                        span(classes: 'chat-phone__cc-code', [text('+966')]),
                        span(classes: 'chat-phone__cc-caret', [text('▾')]),
                      ],
                    ),
                    input(type: InputType.hidden, attributes: const {'name': 'phone_cc', 'id': 'cb-phone-cc', 'value': '+966'}),
                    div(classes: 'chat-phone__cc-menu', attributes: const {'role': 'listbox'}, _countryOptions()),
                  ]),
                  input(
                    type: InputType.tel,
                    id: 'cb-phone',
                    attributes: const {'name': 'phone', 'maxlength': '20', 'autocomplete': 'tel-national', 'placeholder': '5XX XXX XXX', 'inputmode': 'tel'},
                  ),
                ]),
                span(classes: 'chat-form__error', attributes: const {'data-error-for': 'cb-phone'}, []),
              ]),

              div(classes: 'chat-form__field', [
                label(attributes: const {'for': 'cb-message'}, [text('الرسالة · MESSAGE *')]),
                textarea(
                  id: 'cb-message',
                  attributes: const {'name': 'message', 'required': '', 'rows': '4', 'maxlength': '2000', 'placeholder': 'اكتب رسالتك هنا…'},
                  [],
                ),
                span(classes: 'chat-form__error', attributes: const {'data-error-for': 'cb-message'}, []),
              ]),

              // Honeypot — visually hidden, bots fill it, we drop the submit
              div(classes: 'chat-form__honeypot', attributes: const {'aria-hidden': 'true'}, [
                label(attributes: const {'for': 'cb-website'}, [text('Website')]),
                input(type: InputType.text, id: 'cb-website', attributes: const {'name': 'website', 'tabindex': '-1', 'autocomplete': 'off'}),
              ]),

              div(classes: 'chat-form__actions', [
                button(
                  type: ButtonType.button,
                  classes: 'chat-form__back',
                  attributes: const {'id': 'cb-back'},
                  [text('← رجوع · Back')],
                ),
                button(
                  type: ButtonType.submit,
                  classes: 'chat-form__submit',
                  attributes: const {'id': 'cb-submit'},
                  [text('إرسال · Send')],
                ),
              ]),

              span(id: 'cb-form-error', classes: 'chat-form__error chat-form__error--form', []),
            ],
          ),

          // Stage 3: success
          div(id: 'chat-success', classes: 'chat-success', attributes: const {'hidden': ''}, [
            div(classes: 'chat-success__check', [text('✓')]),
            p([text('وصلتني رسالتك. سأرد عليك قريباً.')]),
            p(classes: 'chat-msg__en', [text('Got it. I will get back to you soon.')]),
            button(
              type: ButtonType.button,
              classes: 'chat-form__back',
              attributes: const {'id': 'cb-restart'},
              [text('محادثة جديدة · New chat')],
            ),
          ]),
        ],
      ),

      // Behavior
      script(content: _script),
    ]);
  }

  static Component _choice(String value, String ar, String en) {
    return button(
      classes: 'chat-choice',
      attributes: {'type': 'button', 'data-choice': value},
      [
        span(classes: 'chat-choice__ar', [text(ar)]),
        span(classes: 'chat-choice__en', [text(en)]),
      ],
    );
  }

  // Curated country code list. Keep this short — GCC + a few global. Users
  // can add more by editing this list.
  static List<Component> _countryOptions() {
    const list = <List<String>>[
      ['🇸🇦', '+966', 'Saudi Arabia'],
      ['🇦🇪', '+971', 'United Arab Emirates'],
      ['🇰🇼', '+965', 'Kuwait'],
      ['🇶🇦', '+974', 'Qatar'],
      ['🇧🇭', '+973', 'Bahrain'],
      ['🇴🇲', '+968', 'Oman'],
      ['🇪🇬', '+20', 'Egypt'],
      ['🇯🇴', '+962', 'Jordan'],
      ['🇱🇧', '+961', 'Lebanon'],
      ['🇹🇷', '+90', 'Türkiye'],
      ['🇺🇸', '+1', 'United States / Canada'],
      ['🇬🇧', '+44', 'United Kingdom'],
      ['🇦🇺', '+61', 'Australia'],
      ['🇫🇷', '+33', 'France'],
      ['🇩🇪', '+49', 'Germany'],
      ['🇮🇳', '+91', 'India'],
      ['🇵🇰', '+92', 'Pakistan'],
      ['🇮🇩', '+62', 'Indonesia'],
      ['🇲🇾', '+60', 'Malaysia'],
    ];
    return [
      for (final c in list)
        button(
          classes: 'chat-phone__cc-opt',
          attributes: {
            'type': 'button',
            'role': 'option',
            'data-cc': c[1],
            'data-flag': c[0],
          },
          [
            span(classes: 'chat-phone__cc-flag', [text(c[0])]),
            span(classes: 'chat-phone__cc-name', [text(c[2])]),
            span(classes: 'chat-phone__cc-code', [text(c[1])]),
          ],
        ),
    ];
  }

  static const _script = r'''
(function(){
  var bubble  = document.getElementById('chat-bubble');
  var panel   = document.getElementById('chat-panel');
  if (!bubble || !panel) return;

  // Hide on admin pages — visitors only.
  if (location.pathname.indexOf('/admin') === 0) {
    bubble.style.display = 'none';
    panel.style.display  = 'none';
    return;
  }

  var choices    = document.getElementById('chat-choices');
  var form       = document.getElementById('chat-form');
  var feed       = document.getElementById('chat-feed');
  var success    = document.getElementById('chat-success');
  var reasonIn   = document.getElementById('cb-reason');
  var otherWrap  = document.getElementById('cb-other-wrap');
  var otherIn    = document.getElementById('cb-other');
  var nameIn     = document.getElementById('cb-name');
  var emailIn    = document.getElementById('cb-email');
  var phoneIn    = document.getElementById('cb-phone');
  var phoneCcIn  = document.getElementById('cb-phone-cc');
  var msgIn      = document.getElementById('cb-message');
  var hpIn       = document.getElementById('cb-website');
  var submitBtn  = document.getElementById('cb-submit');
  var backBtn    = document.getElementById('cb-back');
  var restartBtn = document.getElementById('cb-restart');
  var formErr    = document.getElementById('cb-form-error');

  var REASONS = {
    project:  ['بدء مشروع',          'Start a project'],
    hire:     ['توظيف / تعاون',      'Hire / collaborate'],
    press:    ['صحافة أو محاضرات',  'Press or speaking'],
    question: ['سؤال عام',           'General question'],
    feedback: ['ملاحظة أو اقتراح',   'Feedback or suggestion'],
    other:    ['شيء آخر',            'Something else']
  };

  function openPanel(){
    panel.classList.add('open');
    bubble.classList.add('open');
    bubble.setAttribute('aria-expanded','true');
    panel.setAttribute('aria-hidden','false');
  }
  function closePanel(){
    panel.classList.remove('open');
    bubble.classList.remove('open');
    bubble.setAttribute('aria-expanded','false');
    panel.setAttribute('aria-hidden','true');
  }
  bubble.addEventListener('click', function(){
    if (panel.classList.contains('open')) closePanel(); else openPanel();
  });

  // Choice click → reveal form, hide choices, append messages to feed
  choices.querySelectorAll('[data-choice]').forEach(function(btn){
    btn.addEventListener('click', function(){
      var val = btn.getAttribute('data-choice');
      reasonIn.value = val;
      var labels = REASONS[val] || ['',''];

      var userMsg = document.createElement('div');
      userMsg.className = 'chat-msg chat-msg--user';
      userMsg.innerHTML = '<p>'+labels[0]+'</p>';
      feed.appendChild(userMsg);

      var botReply = document.createElement('div');
      botReply.className = 'chat-msg chat-msg--bot';
      if (val === 'other') {
        botReply.innerHTML = '<p>تمام. شاركني التفاصيل وسأرد عليك.</p>'+
                             '<p class="chat-msg__en">Got it — share the details below and I will reply.</p>';
        otherWrap.removeAttribute('hidden');
      } else {
        botReply.innerHTML = '<p>عظيم. أكمل المعلومات وسأتواصل معك.</p>'+
                             '<p class="chat-msg__en">Great — fill in the details and I will get in touch.</p>';
      }
      feed.appendChild(botReply);

      choices.setAttribute('hidden','');
      form.removeAttribute('hidden');
      feed.scrollTop = feed.scrollHeight;
      setTimeout(function(){ (otherWrap.hasAttribute('hidden') ? nameIn : otherIn).focus(); }, 60);
    });
  });

  backBtn.addEventListener('click', function(){
    form.setAttribute('hidden','');
    choices.removeAttribute('hidden');
    // Remove last 2 chat messages (the user choice + bot reply)
    var bots = feed.querySelectorAll('.chat-msg');
    if (bots.length > 2) {
      feed.removeChild(bots[bots.length - 1]);
      feed.removeChild(bots[bots.length - 2]);
    }
    clearErrors();
  });

  restartBtn.addEventListener('click', function(){
    success.setAttribute('hidden','');
    form.removeAttribute('hidden');
    form.reset();
    choices.removeAttribute('hidden');
    form.setAttribute('hidden','');
    otherWrap.setAttribute('hidden','');
    reasonIn.value = '';
    // Trim feed back to the original greeting
    var msgs = feed.querySelectorAll('.chat-msg');
    for (var i = 1; i < msgs.length; i++) feed.removeChild(msgs[i]);
    clearErrors();
  });

  // Country code dropdown
  var ccWrap = panel.querySelector('.chat-phone__cc');
  if (ccWrap) {
    var ccBtn  = ccWrap.querySelector('.chat-phone__cc-btn');
    var ccMenu = ccWrap.querySelector('.chat-phone__cc-menu');
    var ccFlag = ccBtn.querySelector('.chat-phone__cc-flag');
    var ccCode = ccBtn.querySelector('.chat-phone__cc-code');
    ccBtn.addEventListener('click', function(e){
      e.stopPropagation();
      var open = ccWrap.classList.toggle('open');
      ccBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    document.addEventListener('click', function(e){
      if (!ccWrap.contains(e.target)) {
        ccWrap.classList.remove('open');
        ccBtn.setAttribute('aria-expanded','false');
      }
    });
    ccMenu.querySelectorAll('[data-cc]').forEach(function(opt){
      opt.addEventListener('click', function(){
        phoneCcIn.value = opt.getAttribute('data-cc');
        ccFlag.textContent = opt.getAttribute('data-flag');
        ccCode.textContent = opt.getAttribute('data-cc');
        ccWrap.classList.remove('open');
        ccBtn.setAttribute('aria-expanded','false');
        phoneIn.focus();
      });
    });
  }

  // Validation
  function showError(field, msg){
    var holder = panel.querySelector('[data-error-for="'+field.id+'"]');
    if (holder) holder.textContent = msg || '';
    if (msg) field.classList.add('invalid'); else field.classList.remove('invalid');
  }
  function clearErrors(){
    panel.querySelectorAll('.chat-form__error').forEach(function(e){ e.textContent = ''; });
    panel.querySelectorAll('.invalid').forEach(function(e){ e.classList.remove('invalid'); });
    formErr.textContent = '';
  }
  var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

  function validateEmail(){
    var v = emailIn.value.trim();
    if (!v) { showError(emailIn, 'البريد مطلوب · Email is required'); return false; }
    if (!EMAIL_RE.test(v)) { showError(emailIn, 'البريد غير صحيح · Hmm, that does not look like a valid email.'); return false; }
    showError(emailIn, ''); return true;
  }
  function validatePhone(){
    var v = phoneIn.value.trim();
    if (!v) { showError(phoneIn, ''); return true; } // optional
    var digits = v.replace(/[^\d]/g,'');
    if (digits.length < 6 || digits.length > 15) {
      showError(phoneIn, 'الرقم يبدو غير صحيح · That number looks off — please double-check.');
      return false;
    }
    showError(phoneIn, ''); return true;
  }
  function validateName(){
    var v = nameIn.value.trim();
    if (!v) { showError(nameIn, 'الاسم مطلوب · Name is required'); return false; }
    showError(nameIn, ''); return true;
  }
  function validateMessage(){
    var v = msgIn.value.trim();
    if (v.length < 2) { showError(msgIn, 'الرسالة مطلوبة · Please write a message.'); return false; }
    showError(msgIn, ''); return true;
  }

  emailIn.addEventListener('blur', validateEmail);
  phoneIn.addEventListener('blur', validatePhone);
  nameIn.addEventListener('blur', validateName);
  msgIn.addEventListener('blur', validateMessage);

  form.addEventListener('submit', function(e){
    e.preventDefault();
    formErr.textContent = '';
    // Run all validators
    var ok = [validateName(), validateEmail(), validatePhone(), validateMessage()]
      .every(function(x){ return x; });
    if (!ok) return;

    // Honeypot — silent drop
    if (hpIn.value) { success.removeAttribute('hidden'); form.setAttribute('hidden',''); return; }

    submitBtn.disabled = true;
    submitBtn.textContent = '...جارٍ الإرسال · Sending';

    var payload = {
      reason: reasonIn.value || '',
      reason_other: otherIn.value || '',
      name: nameIn.value.trim(),
      email: emailIn.value.trim(),
      phone: phoneIn.value.trim() ? (phoneCcIn.value + ' ' + phoneIn.value.trim()) : '',
      message: msgIn.value.trim(),
      website: hpIn.value || '',
      page: location.pathname
    };

    fetch('/api/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
      .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, body: j }; }); })
      .then(function(res){
        if (res.ok && res.body && res.body.ok) {
          form.setAttribute('hidden','');
          success.removeAttribute('hidden');
        } else {
          formErr.textContent = (res.body && res.body.error)
            ? res.body.error
            : 'حدث خطأ. حاول مرة أخرى أو راسلني مباشرة. · Something went wrong — please try again.';
        }
      })
      .catch(function(){
        formErr.textContent = 'تعذر الاتصال. تحقق من الإنترنت. · Connection error — check your network and retry.';
      })
      .then(function(){
        submitBtn.disabled = false;
        submitBtn.textContent = 'إرسال · Send';
      });
  });

  // Close on Escape
  document.addEventListener('keydown', function(e){
    if (e.key === 'Escape' && panel.classList.contains('open')) closePanel();
  });
})();
''';
}
