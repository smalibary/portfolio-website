/// Profile + hero copy loaded from Supabase (`portfolio.profile`) at build
/// time.
///
/// The admin (`/admin/profile`) writes the singleton row via Cloudflare
/// Pages Functions; the public site reads it here when pre-rendering.
library;

import 'supabase_client.dart';

class HeroMetaItem {
  const HeroMetaItem({required this.label, required this.value});
  final String label;
  final String value;
}

class SiteData {
  const SiteData({
    required this.baseUrl,
    required this.nameAr,
    required this.nameEn,
    required this.taglineAr,
    required this.taglineEn,
    required this.bioAr,
    required this.bioEn,
    required this.photoDark,
    required this.photoLight,
    required this.statusLine,
    required this.ledeAr,
    required this.ledeEn,
    required this.heroMeta,
    required this.socials,
  });

  /// Canonical site origin (no trailing slash). Used by sitemap generator
  /// and by JSON-LD on blog posts.
  final String baseUrl;

  final String nameAr;
  final String nameEn;
  final String taglineAr;
  final String taglineEn;
  final String bioAr;
  final String bioEn;
  final String photoDark;
  final String photoLight;
  final String statusLine;
  final String ledeAr;
  final String ledeEn;
  final List<HeroMetaItem> heroMeta;

  /// Map of platform name (lowercased) → URL. Components look up by platform;
  /// missing platforms render with `'#'` as the href.
  final Map<String, String> socials;

  String social(String platform) => socials[platform] ?? '#';

  /// Used only if the build cannot reach Supabase or the row is missing.
  /// Production builds should never use this — it's a safety net so a
  /// transient network blip during CI doesn't ship an empty homepage.
  static const SiteData fallback = SiteData(
    baseUrl: 'https://smalibary.me',
    nameAr: 'سالم مليباري',
    nameEn: 'Salem Malibary',
    taglineAr: '',
    taglineEn: '',
    bioAr: '',
    bioEn: '',
    photoDark: 'salem-dark.jpg',
    photoLight: 'salem-light.png',
    statusLine: '',
    ledeAr: '',
    ledeEn: '',
    heroMeta: [],
    socials: {},
  );

  /// Fetch the singleton profile row from Supabase. There's exactly one
  /// (id=1, enforced by a CHECK constraint).
  static Future<SiteData> load() async {
    final rows = await fetchRows(
      'profile',
      query: 'select=*&id=eq.1',
    );
    if (rows.isEmpty) return fallback;
    final r = rows.first;

    final socialsRaw = r['socials'];
    final socials = <String, String>{};
    if (socialsRaw is Map) {
      socialsRaw.forEach((k, v) {
        if (k is String && v is String) socials[k.toLowerCase()] = v;
      });
    }

    final heroMetaRaw = (r['hero_meta'] as List?) ?? const [];
    final heroMeta = <HeroMetaItem>[
      for (final m in heroMetaRaw)
        if (m is Map)
          HeroMetaItem(
            label: (m['label'] as String?) ?? '',
            value: (m['value'] as String?) ?? '',
          ),
    ];

    final rawBase = ((r['base_url'] as String?) ?? fallback.baseUrl).trim();
    final baseUrl = rawBase.replaceAll(RegExp(r'/+$'), '');

    return SiteData(
      baseUrl: baseUrl,
      nameAr: (r['name_ar'] as String?) ?? fallback.nameAr,
      nameEn: (r['name_en'] as String?) ?? fallback.nameEn,
      taglineAr: (r['tagline_ar'] as String?) ?? '',
      taglineEn: (r['tagline_en'] as String?) ?? '',
      bioAr: (r['bio_ar'] as String?)?.trim() ?? '',
      bioEn: (r['bio_en'] as String?)?.trim() ?? '',
      photoDark: (r['photo_dark'] as String?) ?? fallback.photoDark,
      photoLight: (r['photo_light'] as String?) ?? fallback.photoLight,
      statusLine: (r['status_line'] as String?)?.trim() ?? '',
      ledeAr: (r['lede_ar'] as String?)?.trim() ?? '',
      ledeEn: (r['lede_en'] as String?)?.trim() ?? '',
      heroMeta: heroMeta,
      socials: socials,
    );
  }
}
