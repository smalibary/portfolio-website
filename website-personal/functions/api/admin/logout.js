// POST /api/admin/logout — clears the session cookie. The token itself
// stays valid (HMAC sessions are stateless) until expiry, but the browser
// won't send it anymore.

import { clearCookie } from '../../_lib/auth.js';

export async function onRequestPost() {
  return new Response(JSON.stringify({ ok: true }), {
    headers: {
      'Content-Type': 'application/json',
      'Set-Cookie': clearCookie(),
    },
  });
}
