/// Section model + markdown body splitter for the live-document feature
/// (ROADMAP #101).
///
/// A blog post body is treated as: optional preamble (everything before the
/// first `## ` heading) followed by a list of H2-anchored sections. Each
/// section has its own `last_modified` and `pinned` flag stored in
/// `post.json` under `sections: [...]`, matched to the body by `anchor`
/// (slug of the heading text).
library;

/// Parsed section metadata for `post.json`.
class Section {
  const Section({
    required this.anchor,
    required this.title,
    required this.lastModified,
    required this.pinned,
    this.subtopic = '',
  });

  /// Slug of the heading title, used to match metadata to body chunks.
  /// If the heading is renamed substantially, `last_modified` resets.
  final String anchor;

  /// Raw heading text (Arabic or English).
  final String title;

  /// ISO date (`YYYY-MM-DD`). Auto-updated by save_server when the section
  /// text changes between saves.
  final String lastModified;

  /// Admin-toggled. Pinned sections render first, in original document order.
  final bool pinned;

  /// Optional small label rendered under the heading. Visible metadata only —
  /// no routing, no tag pages. See RULES.md §5.5.
  final String subtopic;

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        anchor: (j['anchor'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        lastModified: (j['last_modified'] as String?) ?? '',
        pinned: (j['pinned'] as bool?) ?? false,
        subtopic: (j['subtopic'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'anchor': anchor,
        'title': title,
        'last_modified': lastModified,
        'pinned': pinned,
        if (subtopic.isNotEmpty) 'subtopic': subtopic,
      };
}

/// One parsed chunk of the markdown body. The `## heading` line stays at
/// the start of `markdown` so re-rendering produces the heading + body.
class SectionChunk {
  const SectionChunk({
    required this.anchor,
    required this.title,
    required this.markdown,
    required this.position,
  });

  final String anchor;
  final String title;
  final String markdown;

  /// 0-indexed position in the original document order. Used for the
  /// "pinned sections render in original order" rule.
  final int position;
}

/// Result of parsing a body: optional `preamble` (before first `## `) and
/// the list of sections in source order.
class ParsedBody {
  const ParsedBody({required this.preamble, required this.sections});
  final String preamble;
  final List<SectionChunk> sections;
}

/// Split a markdown body into preamble + H2-anchored sections.
///
/// CRLF is normalised to LF first so the regex anchors behave consistently
/// across editors and OS conventions.
ParsedBody parseBody(String rawBody) {
  final body = rawBody.replaceAll('\r\n', '\n');
  final lines = body.split('\n');
  final h2Re = RegExp(r'^##\s+(.+?)\s*$');

  final preamble = StringBuffer();
  final sections = <SectionChunk>[];
  var current = StringBuffer();
  String? currentTitle;
  var inSection = false;
  var pos = 0;

  void flush() {
    if (currentTitle != null) {
      sections.add(SectionChunk(
        anchor: slugify(currentTitle!),
        title: currentTitle!,
        markdown: current.toString().trimRight(),
        position: pos++,
      ));
    }
    current = StringBuffer();
    currentTitle = null;
  }

  for (final line in lines) {
    final m = h2Re.firstMatch(line);
    if (m != null) {
      flush();
      currentTitle = m.group(1)!.trim();
      current.writeln(line);
      inSection = true;
    } else if (inSection) {
      current.writeln(line);
    } else {
      preamble.writeln(line);
    }
  }
  flush();
  return ParsedBody(preamble: preamble.toString().trimRight(), sections: sections);
}

/// Lowercase, hyphenated slug. Keeps Latin word characters (A-Za-z0-9_),
/// the Arabic block (U+0600..U+06FF), and hyphens; collapses whitespace
/// and punctuation. Used as the section identity for matching metadata to
/// body chunks across saves.
String slugify(String input) {
  var s = input.trim().toLowerCase();
  // Whitespace + non-breaking space → single hyphen.
  s = s.replaceAll(RegExp(r'[\s ]+'), '-');
  // Strip anything that's not Latin word char, Arabic, hyphen, or digit.
  s = s.replaceAll(RegExp(r'[^\w؀-ۿ\-]'), '');
  // Collapse repeats and trim leading/trailing hyphens.
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  return s;
}
