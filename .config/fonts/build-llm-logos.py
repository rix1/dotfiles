"""Build a tiny OTF with LLM logos at private-use codepoints, sized for the
cells of iA Writer Mono V. Icons: Simple Icons (CC0).

  U+F8001..3  single-cell logos (cap-height sized)         claude, openai, anthropic
  U+F8011..3  LEFT half of a two-cell logo  (~2x size)     print as "<left><right>"
  U+F8021..3  RIGHT half of the same two-cell logo

Each half is clipped to its own cell so no glyph overflows its advance.
Usage: build.py OUT.otf SVG_DIR
"""
import sys, os
from fontTools.ttLib import TTFont
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.svgLib import SVGPath
from pathops import Path, PathOp, op, simplify

BASE = os.path.expanduser("~/Library/Fonts/iAWriterMonoV.ttf")
OUT, LOGOS = sys.argv[1], sys.argv[2]
ICONS = [("claude", "claude.svg"), ("openai", "openai.svg"), ("anthropic", "anthropic.svg")]

base = TTFont(BASE)
upm = base["head"].unitsPerEm
adv = base["hmtx"]["a"][0]
cap = base["OS/2"].sCapHeight or int(upm * 0.7)
xh = base["OS/2"].sxHeight or int(upm * 0.5)
asc, desc = base["hhea"].ascent, base["hhea"].descent
cell_h = asc - desc
print(f"base: upm={upm} advance={adv} cap={cap} ascent={asc} descent={desc} cell_h={cell_h}")

def svg_path(svg, side, tx, ty):
    """Simple Icons 24x24 box -> font units, box bottom-left at (tx, ty)."""
    p = Path(); pen = p.getPen()
    SVGPath(os.path.join(LOGOS, svg)).draw(TransformPen(pen, (side/24, 0, 0, -side/24, tx, ty + side)))
    return simplify(p, fix_winding=True)

def rect(x0, y0, x1, y1):
    r = Path(); r.moveTo(x0, y0); r.lineTo(x1, y0); r.lineTo(x1, y1); r.lineTo(x0, y1); r.close(); return r

def charstring(path, dx=0):
    pen = T2CharStringPen(adv, None)
    path.draw(TransformPen(pen, (1, 0, 0, 1, dx, 0)))
    bp = BoundsPen(None); path.draw(TransformPen(bp, (1, 0, 0, 1, dx, 0)))
    return pen.getCharString(), bp.bounds

names, charstrings, metrics, cmap = [".notdef"], {}, {}, {}
charstrings[".notdef"] = T2CharStringPen(adv, None).getCharString(); metrics[".notdef"] = (adv, 0)

# 1) single-cell: box centred on cap height
side1 = min(adv * 0.92, cap * 1.08)
# 2) two-cell: box centred in the full cell (ascent..descent), spanning two advances
side2 = min(2 * adv - 2 * 40, cell_h - 2 * 60)
print(f"single-cell side={side1:.0f}  two-cell side={side2:.0f} ({side2/side1:.2f}x)")
margin_y2 = (cell_h - side2) / 2
print(f"two-cell box: x {(2*adv-side2)/2:.0f}..{(2*adv+side2)/2:.0f}, y {desc + margin_y2:.0f}..{desc + margin_y2 + side2:.0f}")

for i, (name, svg) in enumerate(ICONS, start=1):
    # single
    p1 = svg_path(svg, side1, (adv - side1) / 2, (cap - side1) / 2)
    cs, b = charstring(p1); names.append(name); charstrings[name] = cs; metrics[name] = (adv, int(b[0])); cmap[0xF8000 + i] = name
    print(f"  {name:10} U+{0xF8000+i:X} bounds={tuple(int(v) for v in b)}")
    # two-cell halves
    p2 = svg_path(svg, side2, (2 * adv - side2) / 2, desc + margin_y2)
    left = op(p2, rect(0, desc - 50, adv, asc + 50), PathOp.INTERSECTION)
    right = op(p2, rect(adv, desc - 50, 2 * adv, asc + 50), PathOp.INTERSECTION)
    for suffix, path, dx, cp in (("_l", left, 0, 0xF8010 + i), ("_r", right, -adv, 0xF8020 + i)):
        gname = name + suffix
        cs, b = charstring(path, dx); names.append(gname); charstrings[gname] = cs
        metrics[gname] = (adv, int(b[0]) if b else 0); cmap[cp] = gname
        print(f"  {gname:10} U+{cp:X} bounds={tuple(int(v) for v in b) if b else None}")

fb = FontBuilder(upm, isTTF=False)
fb.setupGlyphOrder(names); fb.setupCharacterMap(cmap)
fb.setupCFF("LLMLogos-Regular", {"FullName": "LLM Logos", "FamilyName": "LLM Logos"}, charstrings, {})
fb.setupHorizontalMetrics(metrics); fb.setupHorizontalHeader(ascent=asc, descent=desc)
fb.setupNameTable({"familyName": "LLM Logos", "styleName": "Regular", "fullName": "LLM Logos",
                   "psName": "LLMLogos-Regular", "uniqueFontIdentifier": "LLMLogos-1.1", "version": "Version 1.1",
                   "description": "Claude, OpenAI and Anthropic logos (Simple Icons, CC0) for terminal prompts; single- and two-cell variants"})
fb.setupOS2(sTypoAscender=asc, sTypoDescender=desc, usWinAscent=asc, usWinDescent=-desc, sCapHeight=cap, sxHeight=xh, fsType=0)
fb.setupPost(); fb.save(OUT); print("wrote", OUT, os.path.getsize(OUT), "bytes")
