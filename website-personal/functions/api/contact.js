// Cloudflare Pages Function — POST /api/contact
//
// Receives chat-bubble submissions, validates them, and forwards via Resend
// to CONTACT_EMAIL. Sender is fixed to onboarding@resend.dev for now (no
// domain verification required); swap to a verified `From` once DNS for
// australia-gpa.com (or another owned domain) is added in the Resend
// dashboard.
//
// Required environment variables (set in Cloudflare dashboard → Pages →
// Project → Settings → Variables and Secrets):
//   RESEND_API_KEY  — Resend API key (secret)
//   CONTACT_EMAIL   — recipient email (e.g. salimmalibari@gmail.com)
//
// Optional:
//   FROM_EMAIL      — override the "From:" address. Defaults to
//                     "Salem Portfolio <onboarding@resend.dev>".

const REASON_LABELS = {
  project:  'Start a project',
  hire:     'Hire / collaborate',
  press:    'Press or speaking',
  question: 'General question',
  feedback: 'Feedback or suggestion',
  other:    'Something else',
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

const jsonResponse = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

const escapeHtml = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));

const clean = (s, max) => String(s || '').trim().slice(0, max);

// Best-effort per-IP rate limit using the Cloudflare Cache API. Free,
// no KV/Durable Object setup. Caveat: Cache is per-data-center, so a
// determined attacker rotating regions could exceed it — but for a
// portfolio contact form, this stops 99% of real-world spam.
const MAX_PER_DAY = 3;
async function checkAndIncrementRateLimit(ip) {
  if (!ip || ip === 'unknown') return { allowed: true, count: 0 };
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD UTC
  const key = `https://ratelimit.local/contact/${ip}/${today}`;
  const cache = caches.default;
  let count = 0;
  try {
    const cached = await cache.match(key);
    if (cached) count = parseInt(await cached.text(), 10) || 0;
  } catch { /* cache miss */ }
  if (count >= MAX_PER_DAY) return { allowed: false, count };
  const next = count + 1;
  // Cache until end of UTC day.
  const now = new Date();
  const eod = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1) / 1000;
  const ttl = Math.max(60, eod - Math.floor(Date.now() / 1000));
  try {
    await cache.put(key, new Response(String(next), {
      headers: { 'Cache-Control': `public, max-age=${ttl}` },
    }));
  } catch { /* best effort */ }
  return { allowed: true, count: next };
}

export async function onRequestPost({ request, env }) {
  if (!env.RESEND_API_KEY || !env.CONTACT_EMAIL) {
    return jsonResponse(500, {
      ok: false,
      error: 'Server is missing RESEND_API_KEY or CONTACT_EMAIL.',
    });
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse(400, { ok: false, error: 'Invalid JSON body.' });
  }

  // Honeypot — silent success so bots think it worked.
  if (payload.website) {
    return jsonResponse(200, { ok: true });
  }

  // Rate-limit by IP — max 3 messages per day per IP.
  const ipForLimit = request.headers.get('cf-connecting-ip') || 'unknown';
  const rl = await checkAndIncrementRateLimit(ipForLimit);
  if (!rl.allowed) {
    return jsonResponse(429, {
      ok: false,
      error: 'لقد أرسلت رسائل كثيرة اليوم. حاول غداً. · You have sent the maximum messages for today — please try again tomorrow.',
    });
  }

  const name    = clean(payload.name, 80);
  const email   = clean(payload.email, 120);
  const phone   = clean(payload.phone, 40);
  const message = clean(payload.message, 2000);
  const reason  = clean(payload.reason, 30);
  const reasonOther = clean(payload.reason_other, 120);
  const page    = clean(payload.page, 200);
  // Source — distinguishes chat-bubble vs the /contact form. Surfaced in
  // the email subject so Gmail filters can route or label them.
  const sourceRaw = clean(payload.source, 16).toLowerCase();
  const source = (sourceRaw === 'chat' || sourceRaw === 'form') ? sourceRaw : 'unknown';

  if (!name)    return jsonResponse(400, { ok: false, error: 'Name is required.' });
  if (!email || !EMAIL_RE.test(email)) {
    return jsonResponse(400, { ok: false, error: 'A valid email is required.' });
  }
  if (message.length < 2) {
    return jsonResponse(400, { ok: false, error: 'Message is required.' });
  }

  const reasonLabel = reason === 'other' && reasonOther
    ? reasonOther
    : (REASON_LABELS[reason] || 'New message');

  const ip = request.headers.get('cf-connecting-ip') || 'unknown';
  const country = request.headers.get('cf-ipcountry') || '';
  const fromEmail = env.FROM_EMAIL || 'Salem Portfolio <onboarding@resend.dev>';

  // Subject is prefixed with [CHAT] or [FORM] so Gmail filters can route
  // them. Example: "[CHAT] [Hire / collaborate] John Doe"
  const sourceTag = source === 'chat' ? '[CHAT]' : source === 'form' ? '[FORM]' : '[WEB]';
  const subject = `${sourceTag} [${reasonLabel}] ${name}`;

  const lines = [
    `Source:  ${source}`,
    `Reason:  ${reasonLabel}`,
    `Name:    ${name}`,
    `Email:   ${email}`,
    phone ? `Phone:   ${phone}` : null,
    '',
    'Message:',
    message,
    '',
    '— meta —',
    page ? `Page:    ${page}` : null,
    `IP:      ${ip}${country ? ` (${country})` : ''}`,
    `When:    ${new Date().toISOString()}`,
  ].filter(Boolean);

  const textBody = lines.join('\n');

  const htmlBody = `
    <div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;line-height:1.55;color:#111;">
      <div style="font-size:11px;color:#888;letter-spacing:.05em;text-transform:uppercase;margin-bottom:6px;">
        via ${escapeHtml(source)}
      </div>
      <h2 style="margin:0 0 12px;font-size:16px;">${escapeHtml(reasonLabel)}</h2>
      <table style="font-size:14px;border-collapse:collapse;">
        <tr><td style="padding:2px 12px 2px 0;color:#666;">Name</td><td>${escapeHtml(name)}</td></tr>
        <tr><td style="padding:2px 12px 2px 0;color:#666;">Email</td><td><a href="mailto:${escapeHtml(email)}">${escapeHtml(email)}</a></td></tr>
        ${phone ? `<tr><td style="padding:2px 12px 2px 0;color:#666;">Phone</td><td>${escapeHtml(phone)}</td></tr>` : ''}
      </table>
      <hr style="border:none;border-top:1px solid #eee;margin:16px 0;" />
      <div style="white-space:pre-wrap;font-size:14px;">${escapeHtml(message)}</div>
      <hr style="border:none;border-top:1px solid #eee;margin:16px 0;" />
      <div style="font-size:12px;color:#888;">
        ${page ? `Page: ${escapeHtml(page)}<br/>` : ''}
        IP: ${escapeHtml(ip)}${country ? ` (${escapeHtml(country)})` : ''}<br/>
        Sent: ${new Date().toISOString()}
      </div>
    </div>`;

  const resendBody = {
    from: fromEmail,
    to: [env.CONTACT_EMAIL],
    reply_to: email,
    subject,
    text: textBody,
    html: htmlBody,
  };

  let resendRes;
  try {
    resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(resendBody),
    });
  } catch (err) {
    return jsonResponse(502, { ok: false, error: 'Could not reach mail provider.' });
  }

  if (!resendRes.ok) {
    let detail = '';
    try { detail = (await resendRes.text()).slice(0, 200); } catch {}
    return jsonResponse(502, {
      ok: false,
      error: 'Mail provider rejected the request.',
      detail,
    });
  }

  return jsonResponse(200, { ok: true });
}

// Reject other methods explicitly.
export async function onRequest({ request }) {
  if (request.method === 'POST') return; // handled by onRequestPost
  return new Response('Method Not Allowed', {
    status: 405,
    headers: { 'Allow': 'POST' },
  });
}
