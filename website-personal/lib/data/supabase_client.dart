/// Minimal build-time Supabase PostgREST wrapper used by the data loaders.
///
/// Why not the official supabase_flutter package?
///  - We only need a few read queries at build time. The full client pulls
///    in realtime, auth, gotrue and more — none of which the static build
///    needs. A small http wrapper is enough.
///
/// Reads SUPABASE_URL + SUPABASE_ANON_KEY from process env. These must be
/// set during `dart run jaspr build` (locally via .env, on Cloudflare Pages
/// via Project → Settings → Variables and Secrets).
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class SupabaseConfig {
  static Map<String, String>? _envCache;

  /// Reads OS env first, then falls back to a `.env` file at one of the
  /// likely locations (repo root or website-personal/). Cached after the
  /// first lookup.
  static String? _read(String key) {
    final os = Platform.environment[key];
    if (os != null && os.isNotEmpty) return os;
    _envCache ??= _loadDotEnv();
    final fromFile = _envCache![key];
    if (fromFile == null || fromFile.isEmpty) return null;
    return fromFile;
  }

  static Map<String, String> _loadDotEnv() {
    // Look for .env in CWD, parent dir, and ../.. — handles invocation
    // from website-personal/ or from repo root.
    final candidates = <String>[
      '.env',
      '../.env',
      '../../.env',
    ];
    for (final p in candidates) {
      final f = File(p);
      if (!f.existsSync()) continue;
      final out = <String, String>{};
      for (var line in f.readAsLinesSync()) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx < 1) continue;
        final k = line.substring(0, idx).trim();
        var v = line.substring(idx + 1).trim();
        // Strip surrounding quotes if present.
        if ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'"))) {
          v = v.substring(1, v.length - 1);
        }
        out[k] = v;
      }
      return out;
    }
    return const {};
  }

  /// Project URL, e.g. `https://abc.supabase.co`. No trailing slash.
  static String get url {
    final v = _read('SUPABASE_URL');
    if (v == null || v.isEmpty) {
      throw StateError(
        'SUPABASE_URL not set. Locally: ensure repo-root .env has it. '
        'CI: set on Cloudflare Pages → Settings → Variables and Secrets.',
      );
    }
    return v.replaceAll(RegExp(r'/+$'), '');
  }

  static String get anonKey {
    final v = _read('SUPABASE_ANON_KEY');
    if (v == null || v.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY not set.');
    }
    return v;
  }
}

/// Hit PostgREST and return the parsed JSON list.
///
/// `table` is just the table name (e.g. `posts`). The portfolio schema is
/// selected via the `Accept-Profile` header so we don't have to qualify
/// every name.
///
/// `query` is the raw PostgREST query string (without the leading `?`),
/// e.g. `select=slug,title_ar&status=eq.published&order=published_at.desc`.
Future<List<Map<String, dynamic>>> fetchRows(
  String table, {
  String query = 'select=*',
}) async {
  final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table?$query');
  final resp = await http.get(
    uri,
    headers: {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      // Tell PostgREST to look in the portfolio schema (default is public).
      'Accept-Profile': 'portfolio',
      'Accept': 'application/json',
    },
  );
  if (resp.statusCode != 200) {
    throw HttpException(
      'Supabase $table fetch failed: HTTP ${resp.statusCode} ${resp.body}',
      uri: uri,
    );
  }
  final decoded = jsonDecode(resp.body);
  if (decoded is! List) {
    throw FormatException('Expected a JSON array from $table, got: $decoded');
  }
  return [for (final r in decoded) Map<String, dynamic>.from(r as Map)];
}
