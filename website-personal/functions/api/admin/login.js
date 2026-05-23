// POST /api/admin/login
//
// Body: { passcode: "string" }
// Compares against env.ADMIN_PASSCODE. On match, issues a signed session
// cookie. Wrong passcode → 401.
//
// Set ADMIN_PASSCODE and ADMIN_SESSION_SECRET on Cloudflare Pages →
// Settings → Variables and Secrets. The session secret should be a long
// random string; rotate it to invalidate every existing session.

import { json } from '../../_lib/supabase.js';
import { makeSession, sessionCookie } from '../../_lib/auth.js';

export async function onRequestPost({ request, env }) {
  if (!env.ADMIN_PASSCODE || !env.ADMIN_SESSION_SECRET) {
    return json(500, {
      ok: false,
      error: 'Server is missing ADMIN_PASSCODE or ADMIN_SESSION_SECRET.',
    });
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return json(400, { ok: false, error: 'Invalid JSON body.' });
  }

  const submitted = String(body?.passcode || '');
  if (submitted.length === 0 || submitted !== env.ADMIN_PASSCODE) {
    // Don't reveal whether the passcode was empty or wrong.
    return json(401, { ok: false, error: 'invalid passcode' });
  }

  const token = await makeSession(env);
  return new Response(JSON.stringify({ ok: true }), {
    headers: {
      'Content-Type': 'application/json',
      'Set-Cookie': sessionCookie(token),
    },
  });
}
