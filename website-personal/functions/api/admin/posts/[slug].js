// /api/admin/posts/[slug]
//
// GET    → returns { meta: {fields}, body: markdown }  (legacy shape)
// POST   → accepts { meta, body } OR a flat object
// DELETE → removes the row.

import { SupabaseAdmin, json } from '../../../_lib/supabase.js';
import { triggerRebuild } from '../../../_lib/deploy.js';

const ALLOWED_FIELDS = [
  'slug', 'language', 'status', 'published_at',
  'title_ar', 'title_en',
  'excerpt_ar', 'excerpt_en',
  'meta_title', 'meta_description',
  'og_image', 'canonical_url', 'robots',
  'reading_time', 'tags',
  'sections', 'takeaways',
];

const encSlug = (s) => encodeURIComponent(String(s || ''));

export async function onRequestGet({ params, env }) {
  try {
    const slug = encSlug(params.slug);
    if (!slug) return json(400, { ok: false, error: 'slug missing' });
    const sb = new SupabaseAdmin(env);
    const rows = await sb.select('posts', `select=*&slug=eq.${slug}`);
    if (rows.length === 0) {
      return json(404, { ok: false, error: 'post not found' });
    }
    const { body_md, ...meta } = rows[0];
    return json(200, { id: meta.slug, meta, body: body_md || '' });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}

export async function onRequestPost(context) {
  const { request, params, env } = context;
  try {
    const slug = String(params.slug || '').trim();
    if (!slug) return json(400, { ok: false, error: 'slug missing' });
    const payload = await request.json();

    const meta = payload.meta && typeof payload.meta === 'object'
      ? payload.meta
      : payload;
    const body = typeof payload.body === 'string' ? payload.body : null;

    // Always anchor to the URL slug so a different slug in the meta body
    // can't accidentally rename the post.
    const row = { slug };
    for (const k of ALLOWED_FIELDS) {
      if (meta[k] !== undefined) row[k] = meta[k];
    }
    row.slug = slug;
    if (body !== null) row.body_md = body;

    const sb = new SupabaseAdmin(env);
    const result = await sb.upsert('posts', row, { onConflict: 'slug' });
    triggerRebuild(env, context);
    return json(200, { ok: true, post: result[0] || null });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}

export async function onRequestDelete(context) {
  const { params, env } = context;
  try {
    const slug = encSlug(params.slug);
    if (!slug) return json(400, { ok: false, error: 'slug missing' });
    const sb = new SupabaseAdmin(env);
    await sb.delete('posts', `slug=eq.${slug}`);
    triggerRebuild(env, context);
    return json(200, { ok: true });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}
