// Supabase-Auth-based admin gate.
//
// The browser authenticates with supabase-js (email/password, OAuth, magic
// link — all produce the same session). It sends the session's access_token
// as `Authorization: Bearer <jwt>` on every /api/admin/* request.
//
// We validate that token by asking Supabase's auth server who it belongs to
// (GET /auth/v1/user). This works regardless of the project's JWT signing
// scheme (HS256 shared-secret or asymmetric JWKS) — no local key needed.
//
// Authorization (is this user an ADMIN?) is a separate check: the verified
// email must be in the ADMIN_EMAILS allowlist. When public user accounts
// arrive later, they'll authenticate the same way but won't be on the
// allowlist, so they can't touch /api/admin/*.

export function extractBearer(request) {
  const h = request.headers.get('Authorization') || '';
  const m = h.match(/^Bearer\s+(.+)$/i);
  return m ? m[1].trim() : null;
}

// Returns the Supabase user object if the token is valid, else null.
export async function getUserFromToken(token, env) {
  if (!token) return null;
  try {
    const r = await fetch(`${env.SUPABASE_URL.replace(/\/+$/, '')}/auth/v1/user`, {
      headers: {
        apikey: env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${token}`,
      },
    });
    if (!r.ok) return null;
    return await r.json();
  } catch {
    return null;
  }
}

export function isAdminEmail(email, env) {
  if (!email) return false;
  const allow = (env.ADMIN_EMAILS || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  return allow.includes(email.toLowerCase());
}

// One-stop check used by the middleware. Returns { ok, user } or { ok:false }.
export async function requireAdmin(request, env) {
  const token = extractBearer(request);
  const user = await getUserFromToken(token, env);
  if (!user || !user.email) return { ok: false, reason: 'unauthenticated' };
  if (!isAdminEmail(user.email, env)) return { ok: false, reason: 'forbidden' };
  return { ok: true, user };
}
