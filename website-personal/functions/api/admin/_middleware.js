// Auth gate for /api/admin/*. Requires a valid Supabase session token
// (Authorization: Bearer <jwt>) belonging to an email in ADMIN_EMAILS.
//
// Everything is gated — there's no public login endpoint anymore. The
// browser authenticates directly with Supabase via supabase-js; these
// Functions only verify the resulting token.

import { requireAdmin } from '../../_lib/auth.js';
import { json } from '../../_lib/supabase.js';

export async function onRequest(context) {
  const { request, env, next } = context;

  // Let CORS preflight through without auth.
  if (request.method === 'OPTIONS') return next();

  const result = await requireAdmin(request, env);
  if (!result.ok) {
    const status = result.reason === 'forbidden' ? 403 : 401;
    return json(status, { ok: false, error: result.reason });
  }
  return next();
}
