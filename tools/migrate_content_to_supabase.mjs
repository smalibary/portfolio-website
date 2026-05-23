// One-shot data migration: reads the existing file-based content
// (website-personal/content/...) and writes rows into the portfolio.* tables
// on Supabase. Idempotent — every operation is an upsert, so re-running is
// safe and lets you fix data and re-run.
//
// Usage:
//   1. Copy .env.example to .env and fill SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
//   2. cd tools && npm install
//   3. node migrate_content_to_supabase.mjs

import fs from 'node:fs/promises';
import path from 'node:path';
import { createClient } from '@supabase/supabase-js';
import yaml from 'js-yaml';
import dotenv from 'dotenv';

// Resolve paths relative to the script — works regardless of cwd.
const ROOT = path.resolve(import.meta.dirname, '..');
const CONTENT_DIR = path.join(ROOT, 'website-personal', 'content');

dotenv.config({ path: path.join(ROOT, '.env') });

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.');
  console.error('Look them up at Supabase → Project Settings → API Keys.');
  process.exit(1);
}

// service_role bypasses RLS; this script is admin tooling, never client-side.
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  db: { schema: 'portfolio' },
  auth: { persistSession: false },
});

// ─────────────────────────────────────────────────────────────────────────
// profile (from content/_data/site.yaml — singleton row, id = 1)
// ─────────────────────────────────────────────────────────────────────────
async function migrateProfile() {
  const text = await fs.readFile(path.join(CONTENT_DIR, '_data', 'site.yaml'), 'utf8');
  const data = yaml.load(text) || {};

  const row = {
    id: 1,
    name_ar: data.name_ar ?? null,
    name_en: data.name_en ?? null,
    tagline_ar: data.tagline_ar ?? null,
    tagline_en: data.tagline_en ?? null,
    bio_ar: data.bio_ar ?? null,
    bio_en: data.bio_en ?? null,
    base_url: data.base_url ?? null,
    socials: data.socials ?? {},
  };

  const { error } = await supabase.from('profile').upsert(row);
  if (error) throw new Error(`profile upsert failed: ${error.message}`);
  console.log('✓ profile (1 row)');
}

// ─────────────────────────────────────────────────────────────────────────
// research_papers (from content/_data/papers.yaml)
// ─────────────────────────────────────────────────────────────────────────
async function migrateResearchPapers() {
  const text = await fs.readFile(path.join(CONTENT_DIR, '_data', 'papers.yaml'), 'utf8');
  const data = yaml.load(text) || {};
  const papers = Array.isArray(data.papers) ? data.papers : [];

  if (papers.length === 0) {
    console.log('⊘ research_papers — none found in papers.yaml');
    return;
  }

  const rows = papers.map((p) => ({
    id: String(p.id),
    status: p.status ?? 'active',
    pill_label: p.pill_label ?? null,
    title_ar: p.title_ar ?? '',
    title_en: p.title_en ?? '',
    metric: p.metric ?? null,
    metric_label: p.metric_label ?? null,
    caption: p.caption ?? null,
    url: p.url || null,
    abstract: p.abstract ?? null,
    display_order: Number.isFinite(p.order) ? p.order : 0,
    visible: p.visible !== false,
  }));

  const { error } = await supabase
    .from('research_papers')
    .upsert(rows, { onConflict: 'id' });
  if (error) throw new Error(`research_papers upsert failed: ${error.message}`);
  console.log(`✓ research_papers (${rows.length} rows)`);
}

// ─────────────────────────────────────────────────────────────────────────
// posts (from content/blog/<dir>/post.json + final.md)
// ─────────────────────────────────────────────────────────────────────────
async function migrateBlogPosts() {
  const blogDir = path.join(CONTENT_DIR, 'blog');
  const entries = await fs.readdir(blogDir, { withFileTypes: true });
  const dirs = entries
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort(); // deterministic order

  let count = 0;
  for (const dir of dirs) {
    const postJsonPath = path.join(blogDir, dir, 'post.json');
    const finalMdPath = path.join(blogDir, dir, 'final.md');

    let postData;
    try {
      postData = JSON.parse(await fs.readFile(postJsonPath, 'utf8'));
    } catch {
      console.log(`⊘ ${dir} — no post.json, skipping`);
      continue;
    }

    let bodyMd = null;
    try {
      bodyMd = await fs.readFile(finalMdPath, 'utf8');
    } catch {
      // body is optional (drafts may have no final.md yet)
    }

    const publishedAt = postData.date
      ? new Date(postData.date).toISOString()
      : null;

    const row = {
      slug: postData.slug,
      language: postData.language ?? 'ar',
      status: 'published', // existing file-based posts are all live
      published_at: publishedAt,
      title_ar: postData.title_ar ?? '',
      title_en: postData.title_en ?? '',
      excerpt_ar: postData.excerpt_ar ?? null,
      excerpt_en: postData.excerpt_en ?? null,
      body_md: bodyMd,
      meta_title: postData.meta_title ?? null,
      meta_description: postData.meta_description ?? null,
      og_image: postData.og_image ?? null,
      canonical_url: postData.canonical_url ?? null,
      robots: postData.robots ?? 'index, follow',
      reading_time: Number.isFinite(postData.reading_time)
        ? postData.reading_time
        : null,
      tags: Array.isArray(postData.tags) ? postData.tags : [],
      sections: Array.isArray(postData.sections) ? postData.sections : [],
      takeaways: Array.isArray(postData.takeaways) ? postData.takeaways : [],
    };

    const { error } = await supabase
      .from('posts')
      .upsert(row, { onConflict: 'slug' });
    if (error) throw new Error(`posts/${dir} upsert failed: ${error.message}`);

    console.log(`✓ posts/${dir} — ${postData.slug}`);
    count++;
  }
  console.log(`Total posts: ${count}`);
}

// ─────────────────────────────────────────────────────────────────────────
async function main() {
  console.log('Migrating file-based content into Supabase (portfolio.*)\n');
  await migrateProfile();
  await migrateResearchPapers();
  await migrateBlogPosts();
  console.log('\nDone. Re-running is safe — every write is an upsert.');
}

main().catch((e) => {
  console.error('\nMigration failed:', e.message);
  process.exit(1);
});
