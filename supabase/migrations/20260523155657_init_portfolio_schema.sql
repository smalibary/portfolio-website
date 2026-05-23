-- Phase 1 — portfolio schema (blog posts, research papers, profile).
--
-- One Supabase project will hold multiple apps; each app gets its own schema
-- so the namespace is clean ("portfolio.posts" vs future "housing.listings").
-- The "public" schema stays empty for shared utilities only.

create schema if not exists portfolio;

-- Shared trigger function: bumps updated_at on every UPDATE.
create or replace function portfolio.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

------------------------------------------------------------------
-- Blog posts
------------------------------------------------------------------
create table portfolio.posts (
  id            bigint generated always as identity primary key,
  slug          text unique not null,
  language      text not null default 'ar' check (language in ('ar', 'en')),
  status        text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  published_at  timestamptz,

  -- Bilingual headline fields
  title_ar    text not null,
  title_en    text not null,
  excerpt_ar  text,
  excerpt_en  text,

  -- Body content lives as markdown (the current final.md files)
  body_md     text,

  -- SEO
  meta_title        text,
  meta_description  text,
  og_image          text,
  canonical_url     text,
  robots            text default 'index, follow',

  -- Reading metadata
  reading_time int,
  tags         text[] not null default '{}',

  -- Structured rich content kept as JSONB — the per-post shape varies and
  -- creating side tables for sections/takeaways adds joins for no benefit
  -- while you're the only author. Easy to normalise later if needed.
  sections    jsonb not null default '[]'::jsonb,
  takeaways   jsonb not null default '[]'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index posts_status_published_idx on portfolio.posts (status, published_at desc);
create index posts_tags_gin_idx          on portfolio.posts using gin (tags);

create trigger posts_set_updated_at
  before update on portfolio.posts
  for each row execute function portfolio.set_updated_at();

------------------------------------------------------------------
-- Research papers (homepage cards, not full articles)
------------------------------------------------------------------
create table portfolio.research_papers (
  id            text primary key,
  status        text not null,
  pill_label    text,
  title_ar      text not null,
  title_en      text not null,
  metric        text,
  metric_label  text,
  caption       text,
  url           text,
  abstract      text,
  display_order int not null default 0,
  visible       boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index research_papers_display_idx
  on portfolio.research_papers (display_order)
  where visible = true;

create trigger research_papers_set_updated_at
  before update on portfolio.research_papers
  for each row execute function portfolio.set_updated_at();

------------------------------------------------------------------
-- Profile / site config — singleton row
------------------------------------------------------------------
create table portfolio.profile (
  id           int primary key default 1 check (id = 1),
  name_ar      text,
  name_en      text,
  tagline_ar   text,
  tagline_en   text,
  bio_ar       text,
  bio_en       text,
  base_url     text,
  socials      jsonb not null default '{}'::jsonb,
  updated_at   timestamptz not null default now()
);

create trigger profile_set_updated_at
  before update on portfolio.profile
  for each row execute function portfolio.set_updated_at();

------------------------------------------------------------------
-- Row Level Security
--
-- Public site (anon role) reads published posts + visible research +
-- profile. Admin writes happen via the service_role key from inside
-- Cloudflare Pages Functions, which bypass RLS entirely — so admin
-- traffic doesn't need a policy.
------------------------------------------------------------------
alter table portfolio.posts            enable row level security;
alter table portfolio.research_papers  enable row level security;
alter table portfolio.profile          enable row level security;

create policy "anon can read published posts"
  on portfolio.posts
  for select
  to anon, authenticated
  using (status = 'published');

create policy "anon can read visible research"
  on portfolio.research_papers
  for select
  to anon, authenticated
  using (visible = true);

create policy "anon can read profile"
  on portfolio.profile
  for select
  to anon, authenticated
  using (true);

------------------------------------------------------------------
-- Expose portfolio schema to PostgREST so the JS/Dart clients can
-- query portfolio.* tables (not just public.*).
------------------------------------------------------------------
grant usage on schema portfolio to anon, authenticated, service_role;
grant select on all tables in schema portfolio to anon, authenticated;
grant all    on all tables in schema portfolio to service_role;

alter default privileges in schema portfolio
  grant select on tables to anon, authenticated;
alter default privileges in schema portfolio
  grant all    on tables to service_role;
