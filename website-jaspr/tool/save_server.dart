/// Local-only admin save endpoint. Reads/writes content files for the admin
/// editor. Listens on http://localhost:9090.
///
/// Routes:
///   GET  /api/profile  → JSON of site.yaml
///   POST /api/profile  → writes posted JSON back to site.yaml
///
/// CORS is wide open — this is meant to run only on localhost during
/// development. Never expose this server to the public internet.
///
/// Run standalone: `dart run tool/save_server.dart`
/// Or via the orchestrator: `dart run tool/dev.dart` (also starts jaspr serve)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'generate_sitemap.dart' as sitemap;

const int _port = 9090;
final File _siteYaml = File('content/_data/site.yaml');

void main(List<String> args) async {
  if (!_siteYaml.existsSync()) {
    stderr.writeln('save_server: ${_siteYaml.path} not found');
    stderr.writeln('  cwd: ${Directory.current.path}');
    stderr.writeln('  run from website-jaspr/ root, not tool/');
    exit(1);
  }

  final router =
      Router()
        ..get('/api/profile', _getProfile)
        ..post('/api/profile', _postProfile)
        ..get('/api/posts', _listPosts)
        ..get('/api/posts/<id>', _getPost)
        ..post('/api/posts/<id>', _putPost)
        ..post('/api/posts', _newPost)
        ..delete('/api/posts/<id>', _deletePost)
        ..get('/api/papers', _getPapers)
        ..post('/api/papers', _putPapers)
        ..post('/api/upload', _uploadImage)
        ..get('/api/health', (_) => Response.ok('{"ok":true}', headers: _jsonHeaders));

  final handler = const Pipeline().addMiddleware(_cors).addMiddleware(logRequests()).addHandler(router.call);

  final server = await shelf_io.serve(handler, 'localhost', _port);
  stdout.writeln('save_server :: http://${server.address.host}:${server.port}');
  stdout.writeln('  reading/writing ${_siteYaml.path}');
}

const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

/// Wide-open CORS for localhost dev. Never deploy.
Middleware get _cors => (Handler inner) {
  return (Request req) async {
    if (req.method == 'OPTIONS') {
      return Response.ok('', headers: _corsHeaders);
    }
    final res = await inner(req);
    return res.change(headers: {...res.headers, ..._corsHeaders});
  };
};

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

Response _getProfile(Request req) {
  try {
    final text = _siteYaml.readAsStringSync();
    final yaml = loadYaml(text);
    final json = jsonEncode(_yamlToJson(yaml));
    return Response.ok(json, headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'failed to read', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Future<Response> _postProfile(Request req) async {
  try {
    final body = await req.readAsString();
    final incoming = jsonDecode(body) as Map<String, dynamic>;

    // yaml_edit preserves comments and formatting where it can.
    final original = _siteYaml.readAsStringSync();
    final editor = YamlEditor(original);

    void put(String key, dynamic value) {
      try {
        editor.update([key], value);
      } catch (_) {
        // key didn't exist — append at root
        final root = editor.parseAt([]) as YamlMap;
        editor.update([], {...root.cast<String, dynamic>(), key: value});
      }
    }

    for (final k in const [
      'name_ar',
      'name_en',
      'tagline_ar',
      'tagline_en',
      'bio_ar',
      'bio_en',
      'photo',
      'photo_dark',
      'photo_light',
      'status_line',
      'lede_ar',
      'lede_en',
    ]) {
      if (incoming.containsKey(k)) put(k, incoming[k]);
    }

    if (incoming['socials'] is List) {
      put('socials', incoming['socials']);
    }
    if (incoming['hero_meta'] is List) {
      put('hero_meta', incoming['hero_meta']);
    }

    _siteYaml.writeAsStringSync(editor.toString());

    return Response.ok(
      jsonEncode({'ok': true, 'saved_at': DateTime.now().toIso8601String()}),
      headers: _jsonHeaders,
    );
  } catch (e, st) {
    stderr.writeln('save_server post error: $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': 'failed to write', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

/// YAML's typed nodes (YamlMap, YamlList) don't survive jsonEncode cleanly.
/// Walk the tree and convert to plain Dart maps/lists.
dynamic _yamlToJson(dynamic node) {
  if (node is YamlMap) {
    return {for (final e in node.entries) e.key.toString(): _yamlToJson(e.value)};
  }
  if (node is YamlList) {
    return [for (final v in node) _yamlToJson(v)];
  }
  return node;
}

// ============================================================================
//  BLOG POSTS
//  Each post lives in content/blog/<id>/ with two files:
//    post.json — metadata (title_ar, title_en, slug, excerpt, date, etc.)
//    final.md  — markdown body
//  The directory id is what the API uses (e.g. 01-procrastination); the slug
//  inside post.json is the public URL path.
// ============================================================================

final Directory _blogDir = Directory('content/blog');

bool _validId(String id) =>
    id.isNotEmpty && !id.contains('/') && !id.contains('\\') && !id.contains('..');

Response _listPosts(Request req) {
  try {
    if (!_blogDir.existsSync()) {
      return Response.ok('[]', headers: _jsonHeaders);
    }
    final posts = <Map<String, dynamic>>[];
    for (final entry in _blogDir.listSync()) {
      if (entry is! Directory) continue;
      final id = entry.path.split(RegExp(r'[\\/]')).last;
      final metaFile = File('${entry.path}/post.json');
      if (!metaFile.existsSync()) continue;
      try {
        final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
        meta['id'] = id;
        // Word count from final.md if present.
        final bodyFile = File('${entry.path}/final.md');
        if (bodyFile.existsSync()) {
          final words = bodyFile.readAsStringSync().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
          meta['word_count'] = words;
        }
        posts.add(meta);
      } catch (_) {
        // skip unreadable post.json
      }
    }
    posts.sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
    return Response.ok(jsonEncode(posts), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'list failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Response _getPost(Request req, String id) {
  if (!_validId(id)) return Response.badRequest(body: jsonEncode({'error': 'bad id'}), headers: _jsonHeaders);
  try {
    final dir = Directory('${_blogDir.path}/$id');
    if (!dir.existsSync()) return Response.notFound(jsonEncode({'error': 'not found'}), headers: _jsonHeaders);
    final metaFile = File('${dir.path}/post.json');
    final bodyFile = File('${dir.path}/final.md');
    final meta = metaFile.existsSync()
        ? jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>
        : <String, dynamic>{};
    final body = bodyFile.existsSync() ? bodyFile.readAsStringSync() : '';
    return Response.ok(jsonEncode({'id': id, 'meta': meta, 'body': body}), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'read failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Future<Response> _putPost(Request req, String id) async {
  if (!_validId(id)) return Response.badRequest(body: jsonEncode({'error': 'bad id'}), headers: _jsonHeaders);
  try {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final dir = Directory('${_blogDir.path}/$id');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    if (body['meta'] is Map) {
      final meta = Map<String, dynamic>.from(body['meta'] as Map);
      meta.remove('id'); // id is the directory name, not part of post.json
      File('${dir.path}/post.json').writeAsStringSync(_prettyJson(meta));
    }
    if (body['body'] is String) {
      File('${dir.path}/final.md').writeAsStringSync(body['body'] as String);
    }
    await _refreshSitemap('saved post $id');
    return Response.ok(
      jsonEncode({'ok': true, 'saved_at': DateTime.now().toIso8601String()}),
      headers: _jsonHeaders,
    );
  } catch (e, st) {
    stderr.writeln('save_server post error: $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': 'write failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Future<Response> _newPost(Request req) async {
  try {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    if (!_blogDir.existsSync()) _blogDir.createSync(recursive: true);

    // Pick an id: NN-slug, where NN is the next free 2-digit prefix.
    final existing = _blogDir.listSync().whereType<Directory>().map((e) => e.path.split(RegExp(r'[\\/]')).last).toList();
    int max = 0;
    final prefixRe = RegExp(r'^(\d+)-');
    for (final name in existing) {
      final m = prefixRe.firstMatch(name);
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    final n = max + 1;
    final slug = (body['slug'] as String?) ?? 'untitled-${DateTime.now().millisecondsSinceEpoch}';
    final id = '${n.toString().padLeft(2, '0')}-$slug';

    final dir = Directory('${_blogDir.path}/$id');
    dir.createSync(recursive: true);
    final meta = <String, dynamic>{
      'slug': slug,
      'title_ar': body['title_ar'] ?? '',
      'title_en': body['title_en'] ?? '',
      'excerpt_ar': '',
      'excerpt_en': '',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'category': '',
      'tags': <String>[],
      'file': 'final.md',
      'language': 'ar',
    };
    File('${dir.path}/post.json').writeAsStringSync(_prettyJson(meta));
    File('${dir.path}/final.md').writeAsStringSync('# ${meta['title_ar']}\n\n');

    await _refreshSitemap('created post $id');
    return Response.ok(
      jsonEncode({'ok': true, 'id': id}),
      headers: _jsonHeaders,
    );
  } catch (e, st) {
    stderr.writeln('save_server new post error: $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': 'create failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Future<Response> _deletePost(Request req, String id) async {
  if (!_validId(id)) return Response.badRequest(body: jsonEncode({'error': 'bad id'}), headers: _jsonHeaders);
  try {
    final dir = Directory('${_blogDir.path}/$id');
    if (!dir.existsSync()) return Response.notFound(jsonEncode({'error': 'not found'}), headers: _jsonHeaders);
    dir.deleteSync(recursive: true);
    await _refreshSitemap('deleted post $id');
    return Response.ok(jsonEncode({'ok': true}), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'delete failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

String _prettyJson(Object? v) => const JsonEncoder.withIndent('  ').convert(v);

/// Best-effort: regenerate web/sitemap.xml after content changes. Failures
/// are logged but do not break the parent save — a stale sitemap is less
/// bad than rejecting a successful write.
Future<void> _refreshSitemap(String reason) async {
  try {
    final n = await sitemap.writeSitemap();
    stdout.writeln('save_server :: refreshed sitemap ($reason; $n URLs)');
  } catch (e) {
    stderr.writeln('save_server :: sitemap refresh failed ($reason): $e');
  }
}

// ============================================================================
//  RESEARCH PAPERS
//  Single-file API. content/_data/papers.yaml holds the whole list.
// ============================================================================

final File _papersYaml = File('content/_data/papers.yaml');

Response _getPapers(Request req) {
  try {
    if (!_papersYaml.existsSync()) {
      return Response.ok(jsonEncode({'papers': []}), headers: _jsonHeaders);
    }
    final yaml = loadYaml(_papersYaml.readAsStringSync());
    return Response.ok(jsonEncode(_yamlToJson(yaml)), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'read failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

// ============================================================================
//  IMAGE UPLOAD
//  POST /api/upload accepts JSON `{filename, base64}` and writes to web/images/.
//  Filename is sanitised to a basename with safe characters; extensions are
//  restricted to common image types.
// ============================================================================

final Directory _imagesDir = Directory('web/images');
const _allowedExt = <String>{'.jpg', '.jpeg', '.png', '.webp', '.gif', '.svg'};

Future<Response> _uploadImage(Request req) async {
  try {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final rawName = (body['filename'] as String?) ?? '';
    final b64 = (body['base64'] as String?) ?? '';
    if (rawName.isEmpty || b64.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'filename + base64 required'}),
        headers: _jsonHeaders,
      );
    }
    // basename only — strip any directory components
    final base = rawName.split(RegExp(r'[\\/]')).last;
    // sanitise: lowercase, replace whitespace with -, allow alnum + . _ -
    final cleaned = base
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    final dotIndex = cleaned.lastIndexOf('.');
    if (dotIndex < 0) {
      return Response.badRequest(
        body: jsonEncode({'error': 'filename must have an extension'}),
        headers: _jsonHeaders,
      );
    }
    final ext = cleaned.substring(dotIndex);
    if (!_allowedExt.contains(ext)) {
      return Response.badRequest(
        body: jsonEncode({'error': 'extension $ext not allowed', 'allowed': _allowedExt.toList()}),
        headers: _jsonHeaders,
      );
    }
    if (!_imagesDir.existsSync()) _imagesDir.createSync(recursive: true);
    final bytes = base64Decode(b64);
    final dest = File('${_imagesDir.path}/$cleaned');
    dest.writeAsBytesSync(bytes);
    return Response.ok(
      jsonEncode({'ok': true, 'filename': cleaned, 'bytes': bytes.length}),
      headers: _jsonHeaders,
    );
  } catch (e, st) {
    stderr.writeln('upload error: $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': 'upload failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}

Future<Response> _putPapers(Request req) async {
  try {
    final body = await req.readAsString();
    final incoming = jsonDecode(body) as Map<String, dynamic>;
    if (incoming['papers'] is! List) {
      return Response.badRequest(
        body: jsonEncode({'error': 'papers must be a list'}),
        headers: _jsonHeaders,
      );
    }

    if (!_papersYaml.existsSync()) {
      _papersYaml.parent.createSync(recursive: true);
      _papersYaml.writeAsStringSync('papers: []\n');
    }

    final editor = YamlEditor(_papersYaml.readAsStringSync());
    editor.update(['papers'], incoming['papers']);
    _papersYaml.writeAsStringSync(editor.toString());

    return Response.ok(
      jsonEncode({'ok': true, 'saved_at': DateTime.now().toIso8601String()}),
      headers: _jsonHeaders,
    );
  } catch (e, st) {
    stderr.writeln('save_server papers post error: $e\n$st');
    return Response.internalServerError(
      body: jsonEncode({'error': 'write failed', 'detail': e.toString()}),
      headers: _jsonHeaders,
    );
  }
}
