// Thin wrapper around Supabase's PostgREST endpoint, used by the admin
// Pages Functions. Uses the service_role key — bypasses RLS so the admin
// can read/write drafts and hidden rows that anon visitors can't see.
//
// Why not @supabase/supabase-js?
//  - It pulls in realtime + auth + gotrue, none of which we need here.
//  - Cloudflare Workers have a 1MB bundle limit; staying lean keeps cold
//    starts fast.

export class SupabaseAdmin {
  constructor(env) {
    if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set.');
    }
    this.url = env.SUPABASE_URL.replace(/\/+$/, '');
    this.key = env.SUPABASE_SERVICE_ROLE_KEY;
  }

  _baseHeaders(extra = {}) {
    return {
      apikey: this.key,
      Authorization: `Bearer ${this.key}`,
      // Default to the portfolio schema so callers don't have to repeat
      // it. Override per-call by passing a different Accept-Profile.
      'Accept-Profile': 'portfolio',
      'Content-Profile': 'portfolio',
      ...extra,
    };
  }

  // Returns the parsed JSON. Throws on non-2xx.
  async select(table, query = 'select=*') {
    const r = await fetch(`${this.url}/rest/v1/${table}?${query}`, {
      headers: this._baseHeaders(),
    });
    if (!r.ok) {
      throw new Error(`Supabase select ${table}: ${r.status} ${await r.text()}`);
    }
    return r.json();
  }

  // Upsert one row or many. Returns the inserted/updated rows.
  // onConflict: column name to dedupe by (usually 'slug' or 'id').
  async upsert(table, body, { onConflict } = {}) {
    const url = new URL(`${this.url}/rest/v1/${table}`);
    if (onConflict) url.searchParams.set('on_conflict', onConflict);
    const r = await fetch(url, {
      method: 'POST',
      headers: this._baseHeaders({
        'Content-Type': 'application/json',
        Prefer: 'resolution=merge-duplicates,return=representation',
      }),
      body: JSON.stringify(Array.isArray(body) ? body : [body]),
    });
    if (!r.ok) {
      throw new Error(`Supabase upsert ${table}: ${r.status} ${await r.text()}`);
    }
    return r.json();
  }

  // PATCH (partial update) by some filter.
  async update(table, query, patch) {
    const r = await fetch(`${this.url}/rest/v1/${table}?${query}`, {
      method: 'PATCH',
      headers: this._baseHeaders({
        'Content-Type': 'application/json',
        Prefer: 'return=representation',
      }),
      body: JSON.stringify(patch),
    });
    if (!r.ok) {
      throw new Error(`Supabase update ${table}: ${r.status} ${await r.text()}`);
    }
    return r.json();
  }

  async delete(table, query) {
    const r = await fetch(`${this.url}/rest/v1/${table}?${query}`, {
      method: 'DELETE',
      headers: this._baseHeaders(),
    });
    if (!r.ok) {
      throw new Error(`Supabase delete ${table}: ${r.status} ${await r.text()}`);
    }
    return true;
  }
}

export const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
