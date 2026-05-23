-- Expand portfolio.profile with the fields used by the Jaspr site that
-- weren't captured in the initial migration (photo paths, hero copy,
-- lede paragraphs, hero_meta grid).

alter table portfolio.profile
  add column if not exists photo_dark   text,
  add column if not exists photo_light  text,
  add column if not exists status_line  text,
  add column if not exists lede_ar      text,
  add column if not exists lede_en      text,
  add column if not exists hero_meta    jsonb not null default '[]'::jsonb;

comment on column portfolio.profile.hero_meta is
  'List of {label, value} pairs rendered in the hero grid below the lede.';
comment on column portfolio.profile.socials is
  'Map of platform_name -> url. Stored as a JSON object (not array) so the Dart loader can do socials[platform] lookups directly.';
