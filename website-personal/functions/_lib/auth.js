// HMAC-SHA256 signed session tokens for the admin panel.
//
// Token shape: `{issuedAt}.{expiresAt}.{base64url(hmac)}`
// HMAC is over `{issuedAt}.{expiresAt}` using ADMIN_SESSION_SECRET. Rotating
// the secret invalidates every existing session without touching the
// passcode itself.

const enc = new TextEncoder();
const SESSION_TTL_SECONDS = 7 * 24 * 60 * 60; // 7 days

const b64u = (bytes) =>
  btoa(String.fromCharCode(...new Uint8Array(bytes)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

async function hmacSign(secret, data) {
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  return b64u(sig);
}

// Constant-time-ish compare to dodge timing attacks on the HMAC check.
function safeCompare(a, b) {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

export async function makeSession(env) {
  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + SESSION_TTL_SECONDS;
  const payload = `${issuedAt}.${expiresAt}`;
  const sig = await hmacSign(env.ADMIN_SESSION_SECRET, payload);
  return `${payload}.${sig}`;
}

export async function verifySession(token, env) {
  if (!token || !env.ADMIN_SESSION_SECRET) return false;
  const parts = token.split('.');
  if (parts.length !== 3) return false;
  const [issuedAt, expiresAt, sig] = parts;
  const payload = `${issuedAt}.${expiresAt}`;
  const expected = await hmacSign(env.ADMIN_SESSION_SECRET, payload);
  if (!safeCompare(sig, expected)) return false;
  if (Math.floor(Date.now() / 1000) > Number(expiresAt)) return false;
  return true;
}

// Cookie attributes — HttpOnly so JS can't read it (XSS-resistant), Secure
// so it only travels over HTTPS, SameSite=Strict so it doesn't tag along
// on cross-site requests. Path=/ so every admin endpoint sees it.
export function sessionCookie(token) {
  return `admin_session=${token}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=${SESSION_TTL_SECONDS}`;
}

export function clearCookie() {
  return 'admin_session=; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=0';
}

export function extractSessionToken(request) {
  const cookie = request.headers.get('Cookie') || '';
  const m = cookie.match(/admin_session=([^;]+)/);
  return m ? m[1] : null;
}
