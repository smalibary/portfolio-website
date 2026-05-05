"""Generate a 1200x630 Open Graph card for a blog post.

Reads `website-jaspr/content/blog/<id>/post.json`, generates a card in
the brand's research-lab look (dark background, teal accent line, English
meta_title for legibility on social previews), and writes it to
`website-jaspr/web/images/<id>/og.png`.

This is the manual fallback referenced by ROADMAP item #7 and pairs with
item #91 (templated OG generation at build time). Once #91 lands the
output of this script becomes the build-time default.

Usage:
    python tools/generate_og.py 01-procrastination
    python tools/generate_og.py --all
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# Resolve repo paths relative to this file so the script runs from anywhere.
REPO_ROOT = Path(__file__).resolve().parent.parent
BLOG_ROOT = REPO_ROOT / "website-jaspr" / "content" / "blog"
IMAGES_ROOT = REPO_ROOT / "website-jaspr" / "web" / "images"

# Brand tokens (mirrors web/styles.css dark theme).
BG = (10, 12, 14)            # near-black
FG = (235, 238, 241)         # off-white
MUTED = (140, 150, 162)
ACCENT = (43, 191, 174)      # teal
PANEL = (16, 20, 25)

# Card geometry.
W, H = 1200, 630
PAD = 80


def _try_font(candidates: list[str], size: int) -> ImageFont.FreeTypeFont:
    """Return the first font that loads, falling back to the default bitmap font."""
    for name in candidates:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    print(f"  warn: no preferred font found at size {size}; using PIL default", file=sys.stderr)
    return ImageFont.load_default()


def _wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, max_w: int) -> list[str]:
    """Greedy word wrap to a pixel width."""
    words = text.split()
    if not words:
        return []
    lines: list[str] = []
    cur = words[0]
    for w in words[1:]:
        trial = f"{cur} {w}"
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def _strip_site_suffix(meta_title: str) -> str:
    """Drop the trailing ' | Salem Malibary' to keep the headline tight."""
    for sep in (" | ", " — ", " · "):
        if sep in meta_title:
            return meta_title.split(sep)[0].strip()
    return meta_title.strip()


def render(post_id: str) -> Path:
    post_dir = BLOG_ROOT / post_id
    meta_path = post_dir / "post.json"
    if not meta_path.exists():
        raise SystemExit(f"post.json not found: {meta_path}")

    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    headline = _strip_site_suffix(meta.get("meta_title") or meta.get("title_en") or post_id)
    subline = (meta.get("excerpt_en") or meta.get("title_ar") or "").strip()
    # Skip the first clause if it just echoes the headline; the part after the
    # em dash is usually the more informative half.
    if " — " in subline:
        subline = subline.split(" — ", 1)[1].strip()
        if subline:
            subline = subline[0].upper() + subline[1:]
    if len(subline) > 110:
        subline = subline[:107].rstrip(" ,.;:") + "..."

    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Subtle inner panel + teal accent strip on the left edge (LTR card).
    draw.rectangle((0, 0, 12, H), fill=ACCENT)

    # Top label: brand domain + section, monospace look.
    label_font = _try_font(
        ["consola.ttf", "JetBrainsMono-Regular.ttf", "Cascadia.ttf", "cour.ttf"], 22
    )
    draw.text((PAD, PAD - 30), "salemmalibary.com / blog", font=label_font, fill=MUTED)

    # Headline. Sized to fit; wraps to 2-3 lines max.
    headline_font = _try_font(
        ["Inter-Bold.ttf", "arialbd.ttf", "calibrib.ttf", "DejaVuSans-Bold.ttf"], 64
    )
    max_w = W - PAD * 2
    headline_lines = _wrap(draw, headline, headline_font, max_w)
    if len(headline_lines) > 3:
        # Reduce font size if it overflowed.
        headline_font = _try_font(
            ["Inter-Bold.ttf", "arialbd.ttf", "calibrib.ttf", "DejaVuSans-Bold.ttf"], 52
        )
        headline_lines = _wrap(draw, headline, headline_font, max_w)

    line_h = headline_font.size + 12
    y = PAD + 40
    for line in headline_lines:
        draw.text((PAD, y), line, font=headline_font, fill=FG)
        y += line_h

    # Subline.
    if subline:
        sub_font = _try_font(["Inter-Regular.ttf", "arial.ttf", "calibri.ttf", "DejaVuSans.ttf"], 30)
        y += 12
        for line in _wrap(draw, subline, sub_font, max_w)[:2]:
            draw.text((PAD, y), line, font=sub_font, fill=MUTED)
            y += sub_font.size + 8

    # Footer: author + horizontal rule.
    draw.rectangle((PAD, H - PAD - 60, W - PAD, H - PAD - 59), fill=(40, 46, 54))
    foot_font = _try_font(["Inter-SemiBold.ttf", "arialbd.ttf", "calibrib.ttf", "DejaVuSans-Bold.ttf"], 26)
    draw.text((PAD, H - PAD - 40), "Salem Malibary", font=foot_font, fill=FG)
    role_font = _try_font(["Inter-Regular.ttf", "arial.ttf", "calibri.ttf", "DejaVuSans.ttf"], 22)
    role_bbox = draw.textbbox((0, 0), "Salem Malibary", font=foot_font)
    draw.text(
        (PAD + (role_bbox[2] - role_bbox[0]) + 16, H - PAD - 36),
        "PhD candidate, University of Sydney",
        font=role_font,
        fill=MUTED,
    )

    # Output.
    out_dir = IMAGES_ROOT / post_id
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "og.png"
    img.save(out_path, format="PNG", optimize=True)
    return out_path


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("post_id", nargs="?", help="Blog directory id, e.g. 01-procrastination")
    p.add_argument("--all", action="store_true", help="Render OG cards for every post under content/blog/")
    args = p.parse_args()

    if args.all:
        ids = sorted(d.name for d in BLOG_ROOT.iterdir() if d.is_dir())
    elif args.post_id:
        ids = [args.post_id]
    else:
        p.error("provide a post_id or --all")
        return 2

    for pid in ids:
        out = render(pid)
        size = out.stat().st_size
        print(f"  wrote {out.relative_to(REPO_ROOT)}  ({size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
