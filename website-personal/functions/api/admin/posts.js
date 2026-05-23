// /api/admin/posts
//
// GET  → list every post. Each entry uses `id: slug` so the admin picker
//        can route to /api/admin/posts/<id>. Admin sees drafts too
//        (service_role bypasses RLS).
// POST → create a new post. Body shape mirrors the legacy admin payload —
//        either a flat object or { meta, body } — the function accepts
//        both for forward compatibility.

import { SupabaseAdmin, json } from '../../_lib/supabase.js';
import { triggerRebuild } from '../../_lib/deploy.js';

const ALLOWED_FIELDS = [
  'slug', 'language', 'status', 'published_at',
  'title_ar', 'title_en',
  'excerpt_ar', 'excerpt_en',
  'meta_title', 'meta_description',
  'og_image', 'canonical_url', 'robots',
  'reading_time', 'tags',
  'sections', 'takeaways',
];

const dateOnly = (iso) =>
  typeof iso === 'string' && iso.length >= 10 ? iso.slice(0, 10) : '';

export async function onRequestGet({ env }) {
  try {
    const sb = new SupabaseAdmin(env);
    const cols =
      'slug,language,status,published_at,title_ar,title_en,' +
      'excerpt_ar,excerpt_en,tags,reading_time,updated_at';
    const rows = await sb.select(
      'posts',
      `select=${cols}&order=published_at.desc.nullslast`,
    );
    const shaped = rows.map((r) => ({
      id: r.slug, // picker uses `id` as the routing key
      slug: r.slug,
      date: dateOnly(r.published_at),
      status: r.status,
      language: r.language,
      title_ar: r.title_ar,
      title_en: r.title_en,
      excerpt_ar: r.excerpt_ar,
      excerpt_en: r.excerpt_en,
      tags: r.tags,
      reading_time: r.reading_time,
      updated_at: r.updated_at,
    }));
    return json(200, shaped);
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}

export async function onRequestPost(context) {
  const { request, env } = context;
  try {
    const payload = await request.json();
    // Accept either { ...flat } or { meta: {...}, body: "..." }
    const meta = payload.meta && typeof payload.meta === 'object'
      ? payload.meta
      : payload;
    const body = typeof payload.body === 'string' ? payload.body : null;

    const slug = String(meta.slug || '').trim();
    if (!slug) return json(400, { ok: false, error: 'slug is required' });

    const row = { slug };
    for (const k of ALLOWED_FIELDS) {
      if (meta[k] !== undefined) row[k] = meta[k];
    }
    if (body !== null) row.body_md = body;

    // Sensible defaults for brand-new posts.
    if (!row.status) row.status = 'draft';
    if (!row.language) row.language = 'ar';
    if (!row.title_ar) row.title_ar = '';
    if (!row.title_en) row.title_en = '';
    if (!row.tags) row.tags = [];
    if (!row.sections) row.sections = [];
    if (!row.takeaways) row.takeaways = [];

    const sb = new SupabaseAdmin(env);
    const result = await sb.upsert('posts', row, { onConflict: 'slug' });
    const created = result[0] || {};
    triggerRebuild(env, context);
    return json(200, {
      ok: true,
      id: created.slug, // legacy field — JS uses res.id to route
      slug: created.slug,
      post: created,
    });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}
