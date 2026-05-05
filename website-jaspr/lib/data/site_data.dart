/// Profile + hero copy loaded from `content/_data/site.yaml` at build time.
///
/// The admin (`/admin/profile`) writes this file via the local save server;
/// the public site reads it here when pre-rendering.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';

class HeroMetaItem {
  const HeroMetaItem({required this.label, required this.value});
  final String label;
  final String value;
}

class SiteData {
  const SiteData({
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

  static const SiteData fallback = SiteData(
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

  static SiteData load() {
    final file = File('content/_data/site.yaml');
    if (!file.existsSync()) return fallback;
    try {
      final yaml = loadYaml(file.readAsStringSync()) as YamlMap?;
      if (yaml == null) return fallback;

      final socialsList = (yaml['socials'] as YamlList?) ?? const <dynamic>[];
      final socials = <String, String>{
        for (final entry in socialsList)
          if (entry is YamlMap && entry['platform'] is String && entry['url'] is String)
            (entry['platform'] as String).toLowerCase(): entry['url'] as String,
      };

      final metaList = (yaml['hero_meta'] as YamlList?) ?? const <dynamic>[];
      final heroMeta = <HeroMetaItem>[
        for (final m in metaList)
          if (m is YamlMap)
            HeroMetaItem(
              label: (m['label'] as String?) ?? '',
              value: (m['value'] as String?) ?? '',
            ),
      ];

      // Support legacy `photo` field as fallback for both variants.
      final legacy = (yaml['photo'] as String?) ?? '';
      return SiteData(
        nameAr: (yaml['name_ar'] as String?) ?? fallback.nameAr,
        nameEn: (yaml['name_en'] as String?) ?? fallback.nameEn,
        taglineAr: (yaml['tagline_ar'] as String?) ?? '',
        taglineEn: (yaml['tagline_en'] as String?) ?? '',
        bioAr: (yaml['bio_ar'] as String?)?.trim() ?? '',
        bioEn: (yaml['bio_en'] as String?)?.trim() ?? '',
        photoDark: (yaml['photo_dark'] as String?) ?? (legacy.isNotEmpty ? legacy : fallback.photoDark),
        photoLight: (yaml['photo_light'] as String?) ?? (legacy.isNotEmpty ? legacy : fallback.photoLight),
        statusLine: (yaml['status_line'] as String?)?.trim() ?? '',
        ledeAr: (yaml['lede_ar'] as String?)?.trim() ?? '',
        ledeEn: (yaml['lede_en'] as String?)?.trim() ?? '',
        heroMeta: heroMeta,
        socials: socials,
      );
    } catch (e) {
      stderr.writeln('site_data: failed to parse site.yaml: $e');
      return fallback;
    }
  }
}
