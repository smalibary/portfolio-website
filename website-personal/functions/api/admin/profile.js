// GET/POST /api/admin/profile
//
// GET  → returns the singleton profile row (portfolio.profile id=1).
// POST → upserts the row. Body shape mirrors the columns: name_ar,
//        name_en, tagline_ar, tagline_en, bio_ar, bio_en, base_url,
//        photo_dark, photo_light, status_line, lede_ar, lede_en,
//        socials (object), hero_meta (array of {label,value}).

import { SupabaseAdmin, json } from '../../_lib/supabase.js';

const ALLOWED_FIELDS = [
  'name_ar', 'name_en',
  'tagline_ar', 'tagline_en',
  'bio_ar', 'bio_en',
  'base_url',
  'photo_dark', 'photo_light',
  'status_line',
  'lede_ar', 'lede_en',
  'socials',
  'hero_meta',
];

export async function onRequestGet({ env }) {
  try {
    const sb = new SupabaseAdmin(env);
    const rows = await sb.select('profile', 'select=*&id=eq.1');
    return json(200, rows[0] || {});
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}

export async function onRequestPost({ request, env }) {
  try {
    const body = await request.json();
    const row = { id: 1 };
    for (const k of ALLOWED_FIELDS) {
      if (body[k] !== undefined) row[k] = body[k];
    }
    const sb = new SupabaseAdmin(env);
    const result = await sb.upsert('profile', row);
    return json(200, { ok: true, profile: result[0] || null });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}
