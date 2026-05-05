#!/usr/bin/env python3
"""
Arabic article word counter — shows total and per-section breakdown.
Usage: python word_count.py [path_to_md_file] [target_word_count]

If no file is given, looks for blog/*/final.md (most recently modified).
If no target is given, reads it from the file's front-matter (target: XXXX)
or defaults to 10,000.

Exit codes: 0 = at or above 95% of target, 1 = below 95%.
"""

import re
import sys
import os
import io
from pathlib import Path

# force UTF-8 output on Windows so Arabic section names print correctly
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


# ── config ────────────────────────────────────────────────────────────────────
BLOG_ROOT      = Path(__file__).parent.parent / "blog"
DEFAULT_TARGET = 10_000
BAR_WIDTH      = 30
STOP_THRESHOLD = 0.95   # stop expanding at 95% of target


def find_latest_final() -> Path | None:
    """Return the most recently modified blog/*/final.md, or None."""
    candidates = list(BLOG_ROOT.glob("*/final.md"))
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def read_target_from_frontmatter(content: str) -> int | None:
    """Look for 'target: XXXX' in the first 10 lines."""
    for line in content.splitlines()[:10]:
        m = re.match(r"target:\s*(\d+)", line.strip())
        if m:
            return int(m.group(1))
    return None


# ── helpers ───────────────────────────────────────────────────────────────────
def strip_markdown(text: str) -> str:
    """Remove markdown syntax, leaving only readable content."""
    # remove code fences
    text = re.sub(r"```.*?```", " ", text, flags=re.DOTALL)
    # remove HTML tags
    text = re.sub(r"<[^>]+>", " ", text)
    # remove markdown table rows (lines starting with |)
    text = re.sub(r"^\|.*\|$", " ", text, flags=re.MULTILINE)
    # remove horizontal rules
    text = re.sub(r"^[-*_]{3,}$", " ", text, flags=re.MULTILINE)
    # remove reference markers like [مرجع: Steel 2007]
    text = re.sub(r"\[مرجع:[^\]]*\]", " ", text)
    # remove image/link syntax but keep link text
    text = re.sub(r"!\[.*?\]\(.*?\)", " ", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    # remove remaining [...] markers
    text = re.sub(r"\[[^\]]*\]", " ", text)
    # remove bold/italic markers
    text = re.sub(r"[*_]{1,3}([^*_]+)[*_]{1,3}", r"\1", text)
    # remove inline code
    text = re.sub(r"`[^`]+`", " ", text)
    # remove heading hashes
    text = re.sub(r"^#{1,6}\s*", "", text, flags=re.MULTILINE)
    # remove blockquote markers
    text = re.sub(r"^>\s*", "", text, flags=re.MULTILINE)
    # remove bullet/numbered list markers
    text = re.sub(r"^[\s]*[-*+]\s+", " ", text, flags=re.MULTILINE)
    text = re.sub(r"^[\s]*\d+\.\s+", " ", text, flags=re.MULTILINE)
    # collapse whitespace
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def count_words(text: str) -> int:
    """Count words — splits on whitespace, skips empty tokens."""
    cleaned = strip_markdown(text)
    # filter out tokens that are purely punctuation / numbers / latin
    tokens = cleaned.split()
    meaningful = [t for t in tokens if re.search(r"[؀-ۿ]", t) or
                  (len(t) > 1 and not re.fullmatch(r"[0-9\W]+", t))]
    return len(meaningful)


def bar(count: int, target: int, width: int = BAR_WIDTH) -> str:
    """ASCII progress bar."""
    ratio = min(count / target, 1.0)
    filled = int(ratio * width)
    return f"[{'#' * filled}{'.' * (width - filled)}] {ratio * 100:.1f}%"


def parse_sections(content: str) -> list[tuple[str, str]]:
    """
    Split markdown into (heading, body) pairs.
    The first item is ('INTRO', text before the first ## heading).
    """
    # split on lines that start with exactly ##  (not ### or deeper)
    pattern = re.compile(r"^(## .+)$", re.MULTILINE)
    parts   = pattern.split(content)

    sections = []
    # parts = [pre-heading text, heading1, body1, heading2, body2, ...]
    intro_text = parts[0]
    if intro_text.strip():
        sections.append(("مقدمة AEO + العنوان", intro_text))

    for i in range(1, len(parts), 2):
        heading = parts[i].lstrip("#").strip()
        body    = parts[i + 1] if i + 1 < len(parts) else ""
        sections.append((heading, body))

    return sections


# ── main ──────────────────────────────────────────────────────────────────────
def main():
    # ── resolve file path ─────────────────────────────────────────────────────
    if len(sys.argv) > 1:
        file_path = Path(sys.argv[1])
    else:
        file_path = find_latest_final()
        if file_path is None:
            print("  [!] No blog/*/final.md found. Pass a file path as argument.")
            sys.exit(1)
        print(f"  [auto] Using: {file_path}")

    if not file_path.exists():
        print(f"  [!] File not found: {file_path}")
        sys.exit(1)

    content = file_path.read_text(encoding="utf-8")

    # ── resolve target ────────────────────────────────────────────────────────
    if len(sys.argv) > 2:
        target = int(sys.argv[2])
    else:
        target = read_target_from_frontmatter(content) or DEFAULT_TARGET

    stop_at = int(target * STOP_THRESHOLD)

    sections = parse_sections(content)

    # ── per-section counts ────────────────────────────────────────────────────
    rows = []
    for heading, body in sections:
        wc = count_words(body)
        rows.append((heading, wc))

    total       = sum(r[1] for r in rows)
    gap         = max(target - total, 0)
    ratio       = total / target
    per_section = gap // max(len(rows), 1)

    # ── output ────────────────────────────────────────────────────────────────
    print()
    print("=" * 70)
    print(f"  FILE   : {file_path}")
    print(f"  TARGET : {target:,} words  (stop zone: {stop_at:,}–{target:,})")
    print(f"  CURRENT: {total:,} words   ({ratio*100:.1f}% of target)")
    print(f"  GAP    : {gap:,} words")
    print(f"  {bar(total, target)}")
    print("=" * 70)
    print()

    # ── 95% stop signal ───────────────────────────────────────────────────────
    if total >= stop_at:
        print("  *** STOP — TARGET ZONE REACHED ***")
        print(f"  Article is at {ratio*100:.1f}% ({total:,} words).")
        print(f"  Stop expanding. Move to polish and Stage 6 feedback.")
        print()

    # ── per-section table ─────────────────────────────────────────────────────
    max_h = max(len(r[0]) for r in rows)
    col_h = max(max_h, 20)

    header = f"  {'Section':<{col_h}}  {'Words':>7}  {'% of total':>10}  {'Add to balance':>14}"
    print(header)
    print("  " + "-" * (col_h + 40))

    for heading, wc in rows:
        pct       = (wc / total * 100) if total else 0
        add_words = 0 if total >= stop_at else max(per_section - wc, 0)
        flag      = " <<< THIN" if wc < 500 else ""
        print(f"  {heading:<{col_h}}  {wc:>7,}  {pct:>9.1f}%  {add_words:>12,}{flag}")

    print("  " + "-" * (col_h + 40))
    print(f"  {'TOTAL':<{col_h}}  {total:>7,}  {'100.0%':>10}  {gap:>12,}")
    print()

    # ── recommendations ───────────────────────────────────────────────────────
    if total >= stop_at:
        print("  [OK] In target zone (95%+). No more expansion needed.")
    elif gap == 0:
        print("  [OK] Target reached exactly.")
    else:
        print(f"  [i] To reach {stop_at:,} words (95%), add ~{(stop_at-total)//max(len(rows),1):,} words per section.")
        thin = [(h, w) for h, w in rows if w < 600 and h != "مقدمة AEO + العنوان"]
        if thin:
            print()
            print("  [!] Sections most in need of expansion (under 600 words):")
            for h, w in sorted(thin, key=lambda x: x[1]):
                print(f"      * {h} ({w:,} words -- needs ~{600 - w:,} more minimum)")
    print()

    # exit 0 if in target zone, 1 if still needs work
    sys.exit(0 if total >= stop_at else 1)


if __name__ == "__main__":
    main()
