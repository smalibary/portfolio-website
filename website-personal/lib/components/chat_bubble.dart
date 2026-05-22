import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Role: organism (global)
/// Conversational chat bubble. Renders Salem's avatar + name in a header,
/// streams bot/user messages into a feed, and morphs a single bottom input
/// bar based on the current step (choice chips → name → email → phone →
/// message → send). State machine and validation live in inline JS; submit
/// POSTs to /api/contact (a Cloudflare Pages Function backed by Resend).
class ChatBubble extends StatelessComponent {
  const ChatBubble({
    required this.photoUrl,
    required this.nameAr,
    required this.nameEn,
    super.key,
  });

  final String photoUrl;
  final String nameAr;
  final String nameEn;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // Toggle button
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

      // Panel
      div(
        id: 'chat-panel',
        classes: 'chat-panel',
        attributes: const {'role': 'dialog', 'aria-label': 'Chat with Salem', 'aria-hidden': 'true'},
        [
          // Header — avatar (with online dot), name, status, close
          div(classes: 'chat-header', [
            div(classes: 'chat-header__avatar-wrap', [
              img(
                classes: 'chat-header__avatar',
                src: '/images/$photoUrl',
                alt: nameEn,
                attributes: const {'width': '44', 'height': '44'},
              ),
              span(classes: 'chat-header__avatar-dot', attributes: const {'aria-hidden': 'true'}, []),
            ]),
            div(classes: 'chat-header__meta', [
              div(classes: 'chat-header__name', [
                span(classes: 'chat-header__name-ar', [text(nameAr)]),
                span(classes: 'chat-header__name-en', attributes: const {'dir': 'ltr'}, [text(nameEn)]),
              ]),
              div(classes: 'chat-header__status', [
                span(classes: 'chat-header__status-ar', [text('عادة يرد خلال دقائق')]),
                span(classes: 'chat-header__status-en', attributes: const {'dir': 'ltr'}, [text('Usually replies within minutes')]),
              ]),
            ]),
            button(
              id: 'chat-close',
              classes: 'chat-header__close',
              attributes: const {'type': 'button', 'aria-label': 'Close chat'},
              [
                raw('<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>'),
              ],
            ),
          ]),

          // Feed — bot/user bubbles get appended here by JS
          div(id: 'chat-feed', classes: 'chat-feed', []),

          // Bottom input bar — JS toggles visibility and configures kind
          div(id: 'chat-input', classes: 'chat-input', attributes: const {'hidden': ''}, [
            // Country code (shown only for the phone step)
            div(id: 'chat-cc', classes: 'chat-cc', attributes: const {'hidden': ''}, [
              button(
                id: 'chat-cc-btn',
                classes: 'chat-cc__btn',
                attributes: const {'type': 'button', 'aria-haspopup': 'listbox'},
                [
                  span(id: 'chat-cc-flag', classes: 'chat-cc__flag', [text('🇸🇦')]),
                  span(id: 'chat-cc-code', classes: 'chat-cc__code', [text('+966')]),
                ],
              ),
              div(id: 'chat-cc-menu', classes: 'chat-cc__menu', attributes: const {'role': 'listbox'}, _countryOptions()),
            ]),

            // The actual input control (single-line input OR textarea, swapped by JS)
            div(classes: 'chat-input__field', [
              textarea(
                id: 'chat-input-el',
                attributes: const {
                  'rows': '1',
                  'placeholder': 'اكتب رسالتك…',
                  'maxlength': '2000',
                  'autocomplete': 'off',
                  'enterkeyhint': 'send',
                },
                [],
              ),
            ]),

            button(
              id: 'chat-skip',
              classes: 'chat-input__skip',
              attributes: const {'type': 'button', 'hidden': ''},
              [text('تخطى · Skip')],
            ),

            button(
              id: 'chat-send',
              classes: 'chat-input__send',
              attributes: const {'type': 'button', 'aria-label': 'Send'},
              [
                raw('<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/></svg>'),
              ],
            ),
          ]),

          // Honeypot (visually hidden)
          input(
            type: InputType.text,
            id: 'chat-hp',
            classes: 'chat-hp',
            attributes: const {'name': 'website', 'tabindex': '-1', 'autocomplete': 'off', 'aria-hidden': 'true'},
          ),
        ],
      ),

      // Behavior
      script(content: _script),
    ]);
  }

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
      ['🇺🇸', '+1', 'US / Canada'],
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
          classes: 'chat-cc__opt',
          attributes: {'type': 'button', 'role': 'option', 'data-cc': c[1], 'data-flag': c[0]},
          [
            span(classes: 'chat-cc__flag', [text(c[0])]),
            span(classes: 'chat-cc__name', [text(c[2])]),
            span(classes: 'chat-cc__code', [text(c[1])]),
          ],
        ),
    ];
  }

  static const _script = r'''
(function(){
  var bubble = document.getElementById('chat-bubble');
  var panel  = document.getElementById('chat-panel');
  if (!bubble || !panel) return;

  // Hide on admin pages.
  if (location.pathname.indexOf('/admin') === 0) {
    bubble.style.display = 'none';
    panel.style.display  = 'none';
    return;
  }

  var feed     = document.getElementById('chat-feed');
  var inputBar = document.getElementById('chat-input');
  var inputEl  = document.getElementById('chat-input-el');
  var sendBtn  = document.getElementById('chat-send');
  var skipBtn  = document.getElementById('chat-skip');
  var closeBtn = document.getElementById('chat-close');
  var cc       = document.getElementById('chat-cc');
  var ccBtn    = document.getElementById('chat-cc-btn');
  var ccMenu   = document.getElementById('chat-cc-menu');
  var ccFlag   = document.getElementById('chat-cc-flag');
  var ccCode   = document.getElementById('chat-cc-code');
  var hp       = document.getElementById('chat-hp');

  var REASONS = {
    project:  ['بدء مشروع',          'Start a project'],
    hire:     ['توظيف / تعاون',      'Hire / collaborate'],
    press:    ['صحافة أو محاضرات',  'Press or speaking'],
    question: ['سؤال عام',           'General question'],
    feedback: ['ملاحظة أو اقتراح',   'Feedback or suggestion'],
    other:    ['شيء آخر',            'Something else']
  };

  // Conversation state
  var data = {
    reason: '', reason_other: '',
    name: '', email: '', phone: '', phone_cc: '+966', message: '',
  };
  var step = null;
  var started = false;

  // Keyboard handling — use VisualViewport so the panel stays above the
  // soft keyboard on Android/iOS (where 100dvh doesn't shrink reliably).
  function updateViewportHeight(){
    if (window.visualViewport) {
      panel.style.setProperty('--chat-vh', window.visualViewport.height + 'px');
    } else {
      panel.style.setProperty('--chat-vh', window.innerHeight + 'px');
    }
  }
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', updateViewportHeight);
    window.visualViewport.addEventListener('scroll', updateViewportHeight);
  }
  window.addEventListener('resize', updateViewportHeight);
  updateViewportHeight();

  function openPanel(){
    panel.classList.add('open');
    bubble.classList.add('open');
    bubble.setAttribute('aria-expanded','true');
    panel.setAttribute('aria-hidden','false');
    updateViewportHeight();
    if (!started) { started = true; start(); }
  }
  function closePanel(){
    panel.classList.remove('open');
    bubble.classList.remove('open');
    bubble.setAttribute('aria-expanded','false');
    panel.setAttribute('aria-hidden','true');
  }
  bubble.addEventListener('click', function(){
    panel.classList.contains('open') ? closePanel() : openPanel();
  });
  closeBtn.addEventListener('click', closePanel);
  document.addEventListener('keydown', function(e){
    if (e.key === 'Escape' && panel.classList.contains('open')) closePanel();
  });

  function scrollDown(){
    setTimeout(function(){ feed.scrollTop = feed.scrollHeight; }, 30);
  }

  function botBubble(arHtml, enHtml){
    var b = document.createElement('div');
    b.className = 'chat-msg chat-msg--bot';
    var arPart = '<p dir="rtl">'+arHtml+'</p>';
    var enPart = enHtml ? '<p class="chat-msg__en" dir="ltr">'+enHtml+'</p>' : '';
    b.innerHTML = arPart + enPart;
    return b;
  }
  function addBot(arHtml, enHtml, withTyping, done){
    if (withTyping) {
      var typing = document.createElement('div');
      typing.className = 'chat-msg chat-msg--bot chat-typing';
      typing.innerHTML = '<span></span><span></span><span></span>';
      feed.appendChild(typing);
      scrollDown();
      setTimeout(function(){
        feed.removeChild(typing);
        feed.appendChild(botBubble(arHtml, enHtml));
        scrollDown();
        if (done) done();
      }, 550);
    } else {
      feed.appendChild(botBubble(arHtml, enHtml));
      scrollDown();
      if (done) done();
    }
  }

  function addUser(textValue){
    var b = document.createElement('div');
    b.className = 'chat-msg chat-msg--user';
    var p = document.createElement('p');
    p.textContent = textValue;
    p.setAttribute('dir', 'auto'); // auto-detect AR vs EN from user's typing
    b.appendChild(p);
    feed.appendChild(b);
    scrollDown();
  }

  function addChips(choices, onPick){
    var wrap = document.createElement('div');
    wrap.className = 'chat-chips';
    choices.forEach(function(c){
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'chat-chip';
      b.setAttribute('data-value', c.value);
      b.innerHTML = '<span class="chat-chip__ar" dir="rtl">'+c.ar+'</span>'+
                    '<span class="chat-chip__en" dir="ltr">'+c.en+'</span>';
      b.addEventListener('click', function(){
        wrap.classList.add('chat-chips--locked');
        wrap.querySelectorAll('button').forEach(function(x){
          if (x !== b) x.remove();
          x.disabled = true;
        });
        onPick(c);
      });
      wrap.appendChild(b);
    });
    feed.appendChild(wrap);
    scrollDown();
  }

  // Input bar config
  function setInputKind(kind){
    // kind: 'text' | 'email' | 'tel' | 'textarea' | 'hidden'
    if (kind === 'hidden') { inputBar.setAttribute('hidden',''); return; }
    inputBar.removeAttribute('hidden');
    inputEl.value = '';
    // Reset attributes
    inputEl.removeAttribute('type'); // textarea ignores type
    inputEl.rows = (kind === 'textarea') ? 3 : 1;
    inputEl.style.height = 'auto';
    inputEl.classList.toggle('chat-input__field--multiline', kind === 'textarea');

    if (kind === 'tel') {
      cc.removeAttribute('hidden');
      inputEl.setAttribute('inputmode', 'tel');
      inputEl.setAttribute('placeholder', '5XX XXX XXX');
    } else {
      cc.setAttribute('hidden','');
      inputEl.removeAttribute('inputmode');
      if (kind === 'email') {
        inputEl.setAttribute('inputmode', 'email');
        inputEl.setAttribute('placeholder', 'you@example.com');
      } else if (kind === 'textarea') {
        inputEl.setAttribute('placeholder', 'اكتب رسالتك…');
      } else {
        inputEl.setAttribute('placeholder', 'اكتب هنا…');
      }
    }
    setTimeout(function(){ inputEl.focus({preventScroll:true}); }, 350);
  }
  function showSkip(show){ show ? skipBtn.removeAttribute('hidden') : skipBtn.setAttribute('hidden',''); }

  // Auto-resize textarea
  inputEl.addEventListener('input', function(){
    if (inputEl.classList.contains('chat-input__field--multiline')) {
      inputEl.style.height = 'auto';
      inputEl.style.height = Math.min(inputEl.scrollHeight, 120) + 'px';
    }
  });

  // Country code dropdown
  ccBtn.addEventListener('click', function(e){
    e.stopPropagation();
    cc.classList.toggle('open');
  });
  document.addEventListener('click', function(e){
    if (!cc.contains(e.target)) cc.classList.remove('open');
  });
  ccMenu.querySelectorAll('[data-cc]').forEach(function(opt){
    opt.addEventListener('click', function(){
      data.phone_cc = opt.getAttribute('data-cc');
      ccFlag.textContent = opt.getAttribute('data-flag');
      ccCode.textContent = opt.getAttribute('data-cc');
      cc.classList.remove('open');
      inputEl.focus();
    });
  });

  // Send + Skip + Enter handling
  sendBtn.addEventListener('click', submit);
  skipBtn.addEventListener('click', function(){ submit(true); });
  inputEl.addEventListener('keydown', function(e){
    if (e.key === 'Enter' && !e.shiftKey &&
        !inputEl.classList.contains('chat-input__field--multiline')) {
      e.preventDefault(); submit();
    }
  });

  var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

  function submit(viaSkip){
    var v = inputEl.value.trim();
    if (step === 'name') {
      if (!v) { return botError('ممكن اسمك؟','Mind sharing your name?'); }
      data.name = v; addUser(v); goEmail();
    } else if (step === 'email') {
      if (!v || !EMAIL_RE.test(v)) {
        return botError('هذا البريد غير صحيح.','That does not look like a valid email — try again?');
      }
      data.email = v; addUser(v); goPhone();
    } else if (step === 'phone') {
      if (viaSkip || !v) {
        data.phone = '';
        addUser('تخطى · Skipped');
      } else {
        var digits = v.replace(/[^\d]/g,'');
        if (digits.length < 6 || digits.length > 15) {
          return botError('الرقم يبدو غير صحيح. حاول مرة أخرى أو تخطى.','That number looks off — try again or skip.');
        }
        data.phone = data.phone_cc + ' ' + v;
        addUser(data.phone);
      }
      goMessage();
    } else if (step === 'message') {
      if (v.length < 2) { return botError('اكتب لي شيئاً عن سؤالك.','Tell me a bit about what is on your mind.'); }
      data.message = v; addUser(v); send();
    } else if (step === 'other_what') {
      if (!v) { return botError('وضّح لي باختصار.','Just a sentence is fine.'); }
      data.reason_other = v; addUser(v); goName();
    }
  }

  function botError(ar, en){
    addBot(ar, en, true);
  }

  // Step transitions
  function start(){
    addBot(
      'مرحباً 👋 شكراً لمرورك. كيف يمكنني مساعدتك؟',
      'Hi! Thanks for stopping by. What brings you here?',
      true,
      function(){
        addChips([
          {value:'project',  ar:'بدء مشروع',         en:'Start a project'},
          {value:'hire',     ar:'توظيف / تعاون',     en:'Hire / collaborate'},
          {value:'press',    ar:'صحافة أو محاضرات', en:'Press or speaking'},
          {value:'question', ar:'سؤال عام',          en:'General question'},
          {value:'feedback', ar:'ملاحظة أو اقتراح',  en:'Feedback or suggestion'},
          {value:'other',    ar:'شيء آخر…',         en:'Something else…'}
        ], pickReason);
      }
    );
  }

  function pickReason(c){
    data.reason = c.value;
    addUser(c.ar + ' · ' + c.en);
    if (c.value === 'other') {
      step = 'other_what';
      addBot('عظيم. عن ماذا؟','Got it — about what?', true, function(){
        setInputKind('text'); showSkip(false);
      });
    } else {
      goName();
    }
  }
  function goName(){
    step = 'name';
    addBot('وش اسمك؟','And your name?', true, function(){ setInputKind('text'); showSkip(false); });
  }
  function goEmail(){
    step = 'email';
    addBot('وبريدك الإلكتروني؟','Your email?', true, function(){ setInputKind('email'); showSkip(false); });
  }
  function goPhone(){
    step = 'phone';
    addBot('جوالك؟ (اختياري — تقدر تتخطى)','Phone number? (optional — feel free to skip)', true, function(){ setInputKind('tel'); showSkip(true); });
  }
  function goMessage(){
    step = 'message';
    addBot('وأخيراً — وش تحب تخبر سالم؟','Last one — what would you like to tell Salem?', true, function(){ setInputKind('textarea'); showSkip(false); });
  }

  function send(){
    step = 'sending';
    setInputKind('hidden');
    var typing = document.createElement('div');
    typing.className = 'chat-msg chat-msg--bot chat-typing';
    typing.innerHTML = '<span></span><span></span><span></span>';
    feed.appendChild(typing);
    scrollDown();

    if (hp.value) {
      // Honeypot — pretend success
      setTimeout(function(){ feed.removeChild(typing); finished(true); }, 400);
      return;
    }

    var payload = {
      reason: data.reason,
      reason_other: data.reason_other,
      name: data.name,
      email: data.email,
      phone: data.phone,
      message: data.message,
      website: hp.value || '',
      page: location.pathname
    };

    fetch('/api/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
      .then(function(r){ return r.json().then(function(j){ return { ok: r.ok, body: j }; }); })
      .then(function(res){
        feed.removeChild(typing);
        if (res.ok && res.body && res.body.ok) {
          finished(true);
        } else {
          finished(false, (res.body && res.body.error) || '');
        }
      })
      .catch(function(){
        feed.removeChild(typing);
        finished(false, 'تعذر الاتصال. تحقق من الإنترنت. · Connection error — check your network.');
      });
  }

  function finished(ok, errMsg){
    if (ok) {
      step = 'sent';
      addBot('وصلتني رسالتك ✓ سأرد عليك قريباً.','Got it ✓ I will get back to you soon.', false);
    } else {
      step = 'message';
      addBot('حدث خطأ. ' + (errMsg||'حاول مرة أخرى.'), 'Something went wrong. ' + (errMsg ? '' : 'Please try again.'), false);
      setInputKind('textarea'); showSkip(false);
      inputEl.value = data.message;
    }
  }
})();
''';
}
