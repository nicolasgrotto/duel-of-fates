from pathlib import Path
import re

import numpy as np
from PIL import Image, ImageDraw

from painter import rim

ROOT = Path(__file__).resolve().parents[2]
SIZE = 24


def glyph(power_id):
    image = Image.new("L", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)

    def line(points, width=3):
        draw.line(points, fill=255, width=width, joint="curve")

    def polygon(points):
        draw.polygon(points, fill=255)

    def box(bounds):
        draw.rectangle(bounds, fill=255)

    def arc(bounds, start, end):
        draw.arc(bounds, start, end, fill=255, width=3)

    if power_id == "repulse":
        box((3, 7, 5, 17))
        for x in (8, 14):
            line([(x, 4), (x + 5, 12), (x, 20)])
    elif power_id == "pull":
        line([(20, 6), (15, 4), (9, 7), (8, 11), (17, 10), (19, 15), (15, 19), (7, 18)])
        polygon([(2, 13), (8, 9), (8, 17)])
    elif power_id == "throw":
        arc((2, 3, 21, 20), 145, 330)
        polygon([(20, 2), (22, 9), (15, 6)])
        line([(8, 15), (16, 7)])
        line([(6, 14), (10, 18)])
    elif power_id == "mind_twist":
        arc((3, 3, 16, 16), 45, 345)
        arc((8, 8, 21, 21), 225, 525)
        box((10, 10, 13, 13))
    elif power_id == "supreme_push":
        polygon([(3, 9), (8, 9), (8, 4), (11, 4), (11, 13), (8, 19), (3, 19)])
        for end in [(20, 3), (22, 12), (20, 21)]:
            line([(14, 12), end])
    elif power_id == "fracture":
        polygon([(4, 4), (13, 3), (10, 9), (14, 12), (8, 20), (3, 17)])
        polygon([(17, 4), (21, 8), (20, 19), (12, 21), (18, 12), (14, 9)])
    elif power_id == "barrier":
        line([(3, 5), (12, 2), (21, 5), (20, 14), (12, 21), (4, 14), (3, 5)])
        line([(12, 6), (12, 16)])
    elif power_id == "heal":
        box((10, 5, 13, 18))
        box((5, 10, 18, 13))
        arc((1, 1, 22, 22), 10, 78)
        arc((1, 1, 22, 22), 100, 168)
        arc((1, 1, 22, 22), 190, 258)
        arc((1, 1, 22, 22), 280, 348)
    elif power_id == "focus":
        line([(2, 12), (7, 7), (16, 7), (21, 12), (16, 17), (7, 17), (2, 12)])
        draw.ellipse((9, 9, 14, 14), fill=255)
        line([(12, 1), (12, 4)])
        line([(12, 20), (12, 22)])
    elif power_id == "absorption":
        polygon([(12, 7), (17, 12), (12, 17), (7, 12)])
        for points in [[(2, 4), (6, 8)], [(21, 4), (17, 8)], [(2, 20), (6, 16)], [(21, 20), (17, 16)]]:
            line(points)
        box((10, 2, 13, 4))
        box((10, 20, 13, 22))
    elif power_id == "sanctuary":
        line([(3, 20), (3, 11), (7, 4), (12, 2), (17, 4), (21, 11), (21, 20)])
        line([(7, 20), (7, 12), (12, 8), (17, 12), (17, 20)])
        box((2, 20, 22, 22))
    elif power_id == "mass_telekinesis":
        for x, y in [(2, 3), (10, 1), (18, 3)]:
            box((x, y, x + 4, y + 4))
            line([(x + 2, y + 7), (12, 18)])
        line([(7, 20), (12, 16), (17, 20)])
    elif power_id == "lightning":
        polygon([(12, 2), (20, 2), (14, 9), (20, 9), (5, 22), (9, 14), (4, 14)])
    elif power_id == "choke":
        line([(3, 3), (3, 10), (9, 12), (9, 17), (6, 21)])
        line([(20, 3), (20, 10), (14, 12), (14, 17), (17, 21)])
        box((9, 3, 14, 7))
    elif power_id == "freeze":
        polygon([(12, 1), (17, 9), (15, 19), (12, 23), (7, 16), (6, 8)])
        line([(2, 5), (5, 10)])
        line([(19, 14), (22, 19)])
        line([(2, 19), (5, 16)])
    elif power_id == "storm":
        draw.ellipse((3, 3, 12, 11), fill=255)
        draw.ellipse((9, 1, 19, 12), fill=255)
        box((3, 8, 21, 12))
        polygon([(6, 14), (12, 14), (8, 18), (11, 18), (4, 23)])
        polygon([(16, 14), (21, 14), (18, 18), (20, 18), (14, 23)])
    elif power_id == "wrath":
        polygon([(3, 3), (9, 7), (12, 1), (15, 7), (21, 3), (18, 17), (12, 22), (6, 17)])
        draw.rectangle((9, 11, 14, 14), fill=0)
    elif power_id == "drain":
        polygon([(6, 2), (10, 9), (6, 14), (2, 9)])
        line([(8, 17), (14, 20), (20, 17), (19, 11), (15, 8)])
        polygon([(13, 5), (20, 7), (14, 12)])
    elif power_id == "arsenal":
        for points in [[(5, 17), (2, 6), (6, 8), (9, 19)], [(11, 19), (11, 1), (14, 4), (14, 19)], [(16, 19), (18, 8), (22, 6), (19, 17)]]:
            polygon(points)
        line([(4, 21), (20, 21)])
    elif power_id.startswith("blade_"):
        style = power_id[6:]
        if style == "arc":
            arc((3, 3, 21, 20), 190, 340)
            line([(5, 20), (17, 8)])
        elif style == "dash":
            line([(2, 7), (10, 7)], 3)
            line([(2, 12), (8, 12)], 3)
            polygon([(8, 20), (18, 4), (21, 3), (20, 7), (11, 21)])
        elif style == "throw":
            arc((2, 2, 21, 21), 30, 285)
            polygon([(20, 2), (22, 9), (15, 6)])
            line([(7, 17), (16, 8)])
        elif style in ("thrust", "lunge"):
            polygon([(3, 13), (16, 8), (22, 8), (17, 12), (4, 16)])
            line([(5, 10), (8, 18)], 2)
            if style == "lunge":
                line([(1, 20), (13, 20)], 3)
        elif style == "rising":
            line([(4, 20), (18, 5)])
            polygon([(13, 5), (20, 2), (20, 10)])
            line([(2, 16), (8, 22)], 2)
        elif style == "flurry":
            for y in (2, 9, 16):
                polygon([(2, y + 1), (17, y), (22, y + 2), (17, y + 5), (2, y + 5)])
        elif style == "plunge":
            polygon([(8, 2), (11, 2), (18, 16), (18, 22), (14, 18)])
            line([(5, 7), (13, 3)], 2)
            line([(2, 22), (9, 22)], 2)
        elif style == "wave":
            line([(3, 19), (13, 7)])
            line([(2, 16), (7, 21)], 2)
            arc((8, 2, 22, 21), 275, 85)
        else:
            raise ValueError(style)
    elif power_id.startswith("ability_"):
        kind = power_id[8:]
        if kind == "strike":
            line([(3, 20), (17, 4)])
            for end in [(22, 3), (22, 10), (15, 1)]:
                line([(16, 7), end], 2)
        elif kind == "stance":
            line([(5, 19), (12, 3), (19, 19)])
            line([(4, 20), (20, 20)], 2)
            box((11, 9, 13, 17))
        elif kind == "dash":
            line([(2, 6), (10, 6)], 2)
            line([(2, 12), (9, 12)], 2)
            line([(2, 18), (10, 18)], 2)
            line([(13, 3), (21, 12), (13, 21)])
        elif kind == "charge":
            box((10, 6, 13, 21))
            line([(7, 17), (16, 17)], 2)
            for start in [(3, 4), (12, 1), (21, 4)]:
                line([start, (12, 10)], 2)
        elif kind == "leap":
            arc((3, 3, 21, 22), 185, 335)
            polygon([(17, 1), (22, 7), (14, 7)])
            line([(6, 21), (13, 13)])
        else:
            raise ValueError(kind)
    else:
        raise ValueError(power_id)
    return np.asarray(image) > 0


def blade_icons(palette):
    styles = ["arc", "dash", "throw", "thrust", "rising", "flurry", "lunge", "plunge", "wave"]
    kinds = ["strike", "stance", "dash", "charge", "leap"]
    folder = ROOT / "assets/ui/blade"
    folder.mkdir(parents=True, exist_ok=True)
    for icon_id in ["blade_" + style for style in styles] + ["ability_" + kind for kind in kinds]:
        mask = glyph(icon_id)
        edge = rim(mask.astype(float)) > 0
        pixels = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
        pixels[mask] = (*palette["accent"], 255)
        pixels[edge] = (*palette["background"], 255)
        pixels[mask & ~edge & (np.indices(mask.shape)[0] < 9)] = (*palette["text"], 255)
        Image.fromarray(pixels).save(folder / f"{icon_id}.png", optimize=True)
    for resource in sorted((ROOT / "data/techniques").glob("*.tres")):
        source = resource.read_text(encoding="utf-8")
        style = int(re.search(r'^technique_style = (\d+)', source, re.M)[1])
        resource.write_text(attach_icon(source, "blade_" + styles[style]), encoding="utf-8")
    for resource in sorted((ROOT / "data/characters").glob("*/*.tres")):
        source = resource.read_text(encoding="utf-8")
        script = re.search(r'path="res://data/ability_data.gd" id="([^"]+)"', source)
        if script is None:
            continue
        sections = re.split(r'(?=^\[sub_resource|^\[resource)', source, flags=re.M)
        for index, section in enumerate(sections):
            if f'script = ExtResource("{script[1]}")' not in section:
                continue
            kind = re.search(r'^kind = (\d+)', section, re.M)
            icon_id = "ability_" + kinds[int(kind[1]) if kind else 0]
            if not re.search(r'^icon = ', section, re.M):
                sections[index] = section.replace(f'script = ExtResource("{script[1]}")', f'script = ExtResource("{script[1]}")\nicon = ExtResource("blade_icon")')
            if 'id="blade_icon"' not in sections[0]:
                sections[0] += f'[ext_resource type="Texture2D" path="res://assets/ui/blade/{icon_id}.png" id="blade_icon"]\n\n'
        resource.write_text("".join(sections), encoding="utf-8")


def attach_icon(source, icon_id):
    if 'id="blade_icon"' not in source:
        source = source.replace('[resource]', f'[ext_resource type="Texture2D" path="res://assets/ui/blade/{icon_id}.png" id="blade_icon"]\n\n[resource]')
    if not re.search(r'^icon = ', source, re.M):
        source = source.replace('script = ExtResource("1_script")', 'script = ExtResource("1_script")\nicon = ExtResource("blade_icon")')
    return source


def main():
    palette_source = (ROOT / "ui/ui_palette.gd").read_text(encoding="utf-8")
    palette = {name: tuple(bytes.fromhex(value)) for name, value in re.findall(r'var (\w+): Color = Color\("#([0-9a-fA-F]{6})"\)', palette_source)}
    blade_icons(palette)
    folder = ROOT / "assets/ui/powers"
    folder.mkdir(parents=True, exist_ok=True)
    for resource in sorted((ROOT / "data/powers").glob("*.tres")):
        source = resource.read_text(encoding="utf-8")
        match = re.search(r'^id = &"([\w]+)"', source, re.M)
        if match is None:
            continue
        power_id = match[1]
        path = int(re.search(r'^path = (\d+)', source, re.M)[1])
        mask = glyph(power_id)
        edge = rim(mask.astype(float)) > 0
        pixels = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
        pixels[mask] = (*palette[["accent", "aurora", "eclipse"][path]], 255)
        pixels[edge] = (*palette["background"], 255)
        pixels[mask & ~edge & (np.indices(mask.shape)[0] < 9)] = (*palette["text"], 255)
        Image.fromarray(pixels).save(folder / f"{power_id}.png", optimize=True)


if __name__ == "__main__":
    main()
