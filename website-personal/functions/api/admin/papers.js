// /api/admin/papers
//
// GET  → list every research paper (admin sees hidden ones too).
// POST → replace the entire list with what's in the body. Matches the
//        old save_server behaviour which rewrote papers.yaml as one
//        document on every save.
//
// Body shape: { papers: [ { id, status, ... }, ... ] }

import { SupabaseAdmin, json } from '../../_lib/supabase.js';
import { triggerRebuild } from '../../_lib/deploy.js';

const ALLOWED_FIELDS = [
  'id',
  'status',
  'pill_label',
  'title_ar', 'title_en',
  'metric', 'metric_label',
  'caption',
  'url',
  'abstract',
  'display_order',
  'visible',
];

export async function onRequestGet({ env }) {
  try {
    const sb = new SupabaseAdmin(env);
    const rows = await sb.select(
      'research_papers',
      'select=*&order=display_order.asc',
    );
    // The admin editor uses `order` (matching the old papers.yaml shape).
    // Surface display_order as both for backward compatibility.
    const shaped = rows.map((r) => ({ ...r, order: r.display_order }));
    return json(200, { papers: shaped });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}

export async function onRequestPost(context) {
  const { request, env } = context;
  try {
    const body = await request.json();
    if (!Array.isArray(body.papers)) {
      return json(400, { ok: false, error: 'body.papers must be an array' });
    }

    const sb = new SupabaseAdmin(env);

    // Strategy: upsert all rows by id, then delete rows whose id isn't in
    // the new list. This matches "the saved list is the source of truth"
    // semantics from the old YAML model.
    const rows = body.papers.map((p, idx) => {
      const out = {};
      for (const k of ALLOWED_FIELDS) {
        if (p[k] !== undefined) out[k] = p[k];
      }
      // Editor uses `order` (legacy YAML name); accept it as an alias.
      if (p.order !== undefined && out.display_order === undefined) {
        out.display_order = p.order;
      }
      if (!out.id) {
        throw new Error(`papers[${idx}] is missing id`);
      }
      out.id = String(out.id);
      if (out.display_order === undefined) out.display_order = idx;
      return out;
    });

    if (rows.length > 0) {
      await sb.upsert('research_papers', rows, { onConflict: 'id' });
    }

    // Delete any rows whose id is not in the new list.
    const keepIds = rows.map((r) => `"${r.id.replace(/"/g, '\\"')}"`);
    if (keepIds.length > 0) {
      await sb.delete(
        'research_papers',
        `id=not.in.(${keepIds.join(',')})`,
      );
    } else {
      // Empty list means delete everything.
      await sb.delete('research_papers', 'id=not.is.null');
    }

    const fresh = await sb.select(
      'research_papers',
      'select=*&order=display_order.asc',
    );
    triggerRebuild(env, context);
    return json(200, { ok: true, papers: fresh });
  } catch (e) {
    return json(500, { ok: false, error: String(e.message || e) });
  }
}
