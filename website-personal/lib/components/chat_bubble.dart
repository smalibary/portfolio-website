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
                raw('<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M11 2L11 14L3 8Z"/></svg>'),
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

          // Success overlay — shown after a successful send. Covers feed +
          // input so the conversation "closes out" cleanly. Centered.
          div(
            id: 'chat-success',
            classes: 'chat-success',
            attributes: const {'hidden': '', 'aria-live': 'polite'},
            [
              div(classes: 'chat-success__check', [
                raw('<svg width="48" height="48" viewBox="0 0 48 48" fill="none"><circle cx="24" cy="24" r="22" stroke="currentColor" stroke-width="2.5" stroke-dasharray="138" stroke-dashoffset="138" class="chat-success__circle"/><path d="M14 24l7 7 14-14" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" fill="none" stroke-dasharray="36" stroke-dashoffset="36" class="chat-success__tick"/></svg>'),
              ]),
              div(classes: 'chat-success__title', [
                span(classes: 'chat-success__title-ar', [text('وصلتني رسالتك')]),
                span(classes: 'chat-success__title-en', attributes: const {'dir': 'ltr'}, [text('Got it')]),
              ]),
              p(classes: 'chat-success__sub', [
                span(classes: 'chat-success__sub-ar', [text('سأتواصل معك قريباً')]),
                span(classes: 'chat-success__sub-en', attributes: const {'dir': 'ltr'}, [text("I'll get back to you soon")]),
              ]),
              button(
                id: 'chat-restart',
                classes: 'chat-success__restart',
                attributes: const {'type': 'button'},
                [text('محادثة جديدة · New chat')],
              ),
            ],
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

  var feed       = document.getElementById('chat-feed');
  var inputBar   = document.getElementById('chat-input');
  var inputEl    = document.getElementById('chat-input-el');
  var sendBtn    = document.getElementById('chat-send');
  var skipBtn    = document.getElementById('chat-skip');
  var closeBtn   = document.getElementById('chat-close');
  var cc         = document.getElementById('chat-cc');
  var ccBtn      = document.getElementById('chat-cc-btn');
  var ccMenu     = document.getElementById('chat-cc-menu');
  var ccFlag     = document.getElementById('chat-cc-flag');
  var ccCode     = document.getElementById('chat-cc-code');
  var hp         = document.getElementById('chat-hp');
  var success    = document.getElementById('chat-success');
  var restartBtn = document.getElementById('chat-restart');

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
    first_name: '', family_name: '',
    email: '', phone: '', phone_cc: '+966', message: '',
  };
  var step = null;

  // Keyboard handling — visualViewport.height vs window.innerHeight tells
  // us how much of the screen the soft keyboard is consuming. Expose it
  // as --chat-keyboard-h so the panel's padding-bottom can lift the
  // input bar above the keyboard.
  function updateViewportHeight(){
    var kbH = 0;
    if (window.visualViewport) {
      kbH = Math.max(0, window.innerHeight - window.visualViewport.height - window.visualViewport.offsetTop);
    }
    panel.style.setProperty('--chat-keyboard-h', kbH + 'px');
    panel.style.setProperty('--chat-vh',
      (window.visualViewport ? window.visualViewport.height : window.innerHeight) + 'px');
  }
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', updateViewportHeight);
    window.visualViewport.addEventListener('scroll', updateViewportHeight);
  }
  window.addEventListener('resize', updateViewportHeight);
  updateViewportHeight();

  // Body-scroll lock — needed so the page beneath doesn't scroll, doesn't
  // bounce, and doesn't make iOS Safari/Chrome animate their URL bar
  // (which was making the chat header/input appear to disappear while
  // the user scrolled inside the feed).
  var savedScrollY = 0;
  function lockBody(){
    savedScrollY = window.scrollY || window.pageYOffset || 0;
    document.body.style.position = 'fixed';
    document.body.style.top = -savedScrollY + 'px';
    document.body.style.left = '0';
    document.body.style.right = '0';
    document.body.style.width = '100%';
    document.body.style.overflow = 'hidden';
    // Lock <html> too — without this, Chrome / Firefox on mobile still
    // hide the URL bar on touch-scroll inside the chat, which resizes
    // the viewport and makes the input bar visibly jump around.
    document.documentElement.classList.add('chat-locked');
  }
  function unlockBody(){
    document.body.style.position = '';
    document.body.style.top = '';
    document.body.style.left = '';
    document.body.style.right = '';
    document.body.style.width = '';
    document.body.style.overflow = '';
    document.documentElement.classList.remove('chat-locked');
    window.scrollTo(0, savedScrollY);
  }

  function resetConversation(){
    feed.innerHTML = '';
    success.setAttribute('hidden', '');
    data = {
      reason:'', reason_other:'',
      first_name:'', family_name:'',
      email:'', phone:'', phone_cc:'+966', message:''
    };
    step = null;
    inputEl.value = '';
    setInputKind('hidden');
  }

  function openPanel(){
    panel.classList.add('open');
    bubble.classList.add('open');
    bubble.setAttribute('aria-expanded','true');
    panel.setAttribute('aria-hidden','false');
    lockBody();
    updateViewportHeight();
    // Always start fresh — no resumed conversations.
    resetConversation();
    start();
  }
  function closePanel(){
    panel.classList.remove('open');
    bubble.classList.remove('open');
    bubble.setAttribute('aria-expanded','false');
    panel.setAttribute('aria-hidden','true');
    unlockBody();
  }
  bubble.addEventListener('click', function(){
    panel.classList.contains('open') ? closePanel() : openPanel();
  });
  closeBtn.addEventListener('click', closePanel);
  document.addEventListener('keydown', function(e){
    if (e.key === 'Escape' && panel.classList.contains('open')) closePanel();
  });

  // Scroll the feed to the bottom after the bubble layout settles. Two
  // rAFs gives the new child a chance to mount + the animation to start
  // its frame before we measure scrollHeight.
  function scrollDown(){
    requestAnimationFrame(function(){
      requestAnimationFrame(function(){
        feed.scrollTop = feed.scrollHeight;
        var last = feed.lastElementChild;
        if (last && last.scrollIntoView) {
          try { last.scrollIntoView({ block: 'end', behavior: 'smooth' }); } catch (_) {}
        }
      });
    });
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
  function setInputKind(kind, customPlaceholder){
    // kind: 'text' | 'email' | 'tel' | 'textarea' | 'hidden'
    if (kind === 'hidden') { inputBar.setAttribute('hidden',''); return; }
    inputBar.removeAttribute('hidden');
    inputEl.value = '';
    inputEl.removeAttribute('type');
    inputEl.rows = (kind === 'textarea') ? 3 : 1;
    inputEl.style.height = 'auto';
    inputEl.classList.toggle('chat-input__field--multiline', kind === 'textarea');

    if (kind === 'tel') {
      cc.removeAttribute('hidden');
      inputEl.setAttribute('inputmode', 'tel');
      inputEl.setAttribute('placeholder', customPlaceholder || '5XX XXX XXX');
    } else {
      cc.setAttribute('hidden','');
      inputEl.removeAttribute('inputmode');
      if (kind === 'email') {
        inputEl.setAttribute('inputmode', 'email');
        inputEl.setAttribute('placeholder', customPlaceholder || 'you@example.com');
      } else if (kind === 'textarea') {
        inputEl.setAttribute('placeholder', customPlaceholder || 'اكتب رسالتك…');
      } else {
        inputEl.setAttribute('placeholder', customPlaceholder || 'اكتب هنا…');
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

  // Forward finger-drags on the input bar to the chat feed — same
  // pattern Claude Code itself uses. If the textarea has overflowing
  // text the user is trying to scroll, let the textarea handle it;
  // otherwise the drag becomes a feed scroll. Stops touches on the
  // input area from escaping into the page underneath.
  var lastTouchY = 0;
  inputBar.addEventListener('touchstart', function(e){
    lastTouchY = e.touches[0].clientY;
  }, { passive: true });
  inputBar.addEventListener('touchmove', function(e){
    var taCanScroll = inputEl.scrollHeight > inputEl.clientHeight + 1;
    // If the user is dragging on a textarea that has its own scrollable
    // content, let the textarea consume the scroll natively.
    if (e.target === inputEl && taCanScroll) {
      lastTouchY = e.touches[0].clientY;
      return;
    }
    var currentY = e.touches[0].clientY;
    var deltaY = lastTouchY - currentY;
    lastTouchY = currentY;
    feed.scrollTop += deltaY;
    e.preventDefault();
  }, { passive: false });

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
    if (step === 'first_name') {
      if (!v) { return botError('ممكن اسمك الأول؟','What is your first name?'); }
      data.first_name = v; addUser(v); askFamilyName();
    } else if (step === 'family_name') {
      if (!v) { return botError('وماذا عن اسم العائلة؟','And your family name?'); }
      data.family_name = v; addUser(v); showChoices();
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
      data.reason_other = v; addUser(v); goEmail();
    }
  }

  function botError(ar, en){
    addBot(ar, en, true);
  }

  // Step transitions — names first (filters out non-serious visitors),
  // then the 5 reason chips, then email/phone/message.
  function start(){
    addBot(
      'مرحباً 👋 شكراً لمرورك. خلنا نبدأ — وش اسمك الأول؟',
      "Hi! Thanks for stopping by. Let's start — what's your first name?",
      true,
      function(){
        step = 'first_name';
        setInputKind('text', 'الاسم الأول · First name');
        showSkip(false);
      }
    );
  }

  function askFamilyName(){
    step = 'family_name';
    addBot('وماذا عن اسم العائلة؟', 'And your family name?', true, function(){
      setInputKind('text', 'اسم العائلة · Family name');
      showSkip(false);
    });
  }

  function showChoices(){
    addBot('شرفنا ' + data.first_name + ' 🤝 وش الذي جابك اليوم؟',
           'Nice to meet you, ' + data.first_name + ' — what brings you here?',
           true,
           function(){
             setInputKind('hidden');
             addChips([
               {value:'project',  ar:'بدء مشروع',         en:'Start a project'},
               {value:'hire',     ar:'توظيف / تعاون',     en:'Hire / collaborate'},
               {value:'press',    ar:'صحافة أو محاضرات', en:'Press or speaking'},
               {value:'question', ar:'سؤال عام',          en:'General question'},
               {value:'feedback', ar:'ملاحظة أو اقتراح',  en:'Feedback or suggestion'},
               {value:'other',    ar:'شيء آخر…',         en:'Something else…'}
             ], pickReason);
           });
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
      goEmail();
    }
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
      first_name: data.first_name,
      family_name: data.family_name,
      email: data.email,
      phone: data.phone,
      message: data.message,
      website: hp.value || '',
      source: 'chat',
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
      success.removeAttribute('hidden');
      setInputKind('hidden');
      // Restart the SVG checkmark animation on every show.
      success.querySelectorAll('.chat-success__circle, .chat-success__tick').forEach(function(n){
        n.style.animation = 'none';
        // force reflow
        void n.offsetWidth;
        n.style.animation = '';
      });
      fireConfetti();
    } else {
      step = 'message';
      addBot('حدث خطأ. ' + (errMsg||'حاول مرة أخرى.'), 'Something went wrong. ' + (errMsg ? '' : 'Please try again.'), false);
      setInputKind('textarea'); showSkip(false);
      inputEl.value = data.message;
    }
  }

  // Confetti — vanilla, no library. ~60 colorful pieces fall through the
  // panel for ~2.5s on success, then clean themselves up.
  function fireConfetti(){
    var colors = ['#22c55e', '#3b82f6', '#f59e0b', '#ec4899', '#8b5cf6', '#06b6d4'];
    for (var i = 0; i < 70; i++) {
      var d = document.createElement('div');
      d.className = 'chat-confetti';
      d.style.left = (Math.random() * 100) + '%';
      d.style.background = colors[i % colors.length];
      d.style.animationDelay = (Math.random() * 0.4) + 's';
      d.style.animationDuration = (1.6 + Math.random() * 1.4) + 's';
      d.style.setProperty('--drift', ((Math.random() - 0.5) * 200) + 'px');
      panel.appendChild(d);
      (function(el){ setTimeout(function(){ el.remove(); }, 3200); })(d);
    }
  }

  // Reset everything for "New chat" — clear feed, reset state, restart.
  restartBtn.addEventListener('click', function(){
    resetConversation();
    start();
  });
})();
''';
}
