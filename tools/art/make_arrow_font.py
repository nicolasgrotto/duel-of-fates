"""Builds assets/fonts/arrows/DuelArrows.ttf: the four arrow glyphs the interface hints use.

Oxanium has no arrows, and the web build has no system fonts to fall back on, so the theme
uses this tiny font as Oxanium's fallback. The arrows follow Oxanium's metrics (1000 units
per em, cap height 690) and its straight, angular stroke.

Usage (from the project root): python tools/art/make_arrow_font.py
"""
import os
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UNITS = 1000
ADVANCE = 700
STROKE = 92
MIDDLE = 345
HEAD = 215
TIP = 640
TAIL = 60
NECK = 400

RIGHT = [(TAIL, MIDDLE - STROKE / 2), (NECK, MIDDLE - STROKE / 2), (NECK, MIDDLE - HEAD), (TIP, MIDDLE),
         (NECK, MIDDLE + HEAD), (NECK, MIDDLE + STROKE / 2), (TAIL, MIDDLE + STROKE / 2)]
CENTER = (ADVANCE / 2, MIDDLE)


def rotate(points, quarter_turns):
    result = []
    for x, y in points:
        dx, dy = x - CENTER[0], y - CENTER[1]
        for _ in range(quarter_turns % 4):
            dx, dy = -dy, dx
        result.append((round(CENTER[0] + dx), round(CENTER[1] + dy)))
    return result


def glyph(points):
    pen = TTGlyphPen(None)
    if points:
        pen.moveTo(points[0])
        for point in points[1:]:
            pen.lineTo(point)
        pen.closePath()
    return pen.glyph()


def build(path):
    names = [".notdef", "space", "arrowleft", "arrowup", "arrowright", "arrowdown"]
    shapes = {".notdef": [], "space": [], "arrowright": RIGHT, "arrowup": rotate(RIGHT, 1),
              "arrowleft": rotate(RIGHT, 2), "arrowdown": rotate(RIGHT, 3)}
    builder = FontBuilder(UNITS, isTTF=True)
    builder.setupGlyphOrder(names)
    builder.setupCharacterMap({0x20: "space", 0x2190: "arrowleft", 0x2191: "arrowup", 0x2192: "arrowright", 0x2193: "arrowdown"})
    builder.setupGlyf({name: glyph(shapes[name]) for name in names})
    builder.setupHorizontalMetrics({name: (ADVANCE if name.startswith("arrow") else 300, 0) for name in names})
    builder.setupHorizontalHeader(ascent=790, descent=-210)
    builder.setupNameTable({"familyName": "Duel Arrows", "styleName": "Regular"})
    builder.setupOS2(sTypoAscender=790, sTypoDescender=-210, usWinAscent=790, usWinDescent=210, sCapHeight=690)
    builder.setupPost()
    builder.save(path)


if __name__ == "__main__":
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    folder = os.path.join(root, "assets", "fonts", "arrows")
    os.makedirs(folder, exist_ok=True)
    build(os.path.join(folder, "DuelArrows.ttf"))
    print("assets/fonts/arrows/DuelArrows.ttf")
