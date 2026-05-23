// Auth gate for everything under /api/admin/* except login + logout.
// Returns 401 if no valid session cookie. Login itself is what sets that
// cookie, so it has to be exempt or you couldn't ever get in.

import { extractSessionToken, verifySession } from '../../_lib/auth.js';
import { json } from '../../_lib/supabase.js';

const PUBLIC_PATHS = new Set([
  '/api/admin/login',
  '/api/admin/logout',
]);

export async function onRequest(context) {
  const { request, env, next } = context;
  const url = new URL(request.url);
  if (PUBLIC_PATHS.has(url.pathname)) return next();

  const token = extractSessionToken(request);
  if (!token || !(await verifySession(token, env))) {
    return json(401, { ok: false, error: 'unauthorized' });
  }
  return next();
}
