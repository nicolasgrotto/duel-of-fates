from pathlib import Path
import re

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
TILE = 32
SPRITE = (24, 28)


def palette():
    source = (ROOT / "ui/ui_palette.gd").read_text(encoding="utf-8")
    return {name: tuple(bytes.fromhex(value)) for name, value in re.findall(r'var (\w+): Color = Color\("#([0-9a-fA-F]{6})"\)', source)}


def shade(color, scale):
    return tuple(max(0, min(255, round(component * scale))) for component in color)


def tileset(colors):
    atlas = Image.new("RGBA", (TILE * 4, TILE))
    floor = colors["infiltration_floor"]
    seam = colors["infiltration_seam"]
    wall = colors["infiltration_wall"]
    edge = colors["infiltration_edge"]
    crate = colors["infiltration_crate"]
    for kind in range(4):
        tile = Image.new("RGBA", (TILE, TILE), (*floor, 255))
        draw = ImageDraw.Draw(tile)
        draw.rectangle((0, 0, 31, 31), outline=seam)
        draw.line((1, 1, 30, 1), fill=shade(floor, 1.4))
        for x, y in ((3, 3), (28, 3), (3, 28), (28, 28)):
            draw.point((x, y), fill=shade(floor, 1.8))
        if kind == 0:
            draw.line((8, 15, 23, 15), fill=shade(floor, 1.12))
            draw.line((23, 16, 23, 19), fill=seam)
        elif kind == 1:
            draw.rectangle((1, 1, 30, 30), fill=wall, outline=seam)
            draw.rectangle((3, 3, 28, 26), fill=shade(wall, 1.15), outline=edge)
            draw.rectangle((6, 6, 25, 23), fill=wall)
            draw.line((3, 27, 28, 27), fill=shade(wall, .65), width=3)
            draw.line((7, 9, 24, 9), fill=shade(wall, 1.3))
        elif kind == 2:
            draw.rectangle((1, 1, 30, 30), fill=shade(crate, .5), outline=seam)
            draw.rectangle((3, 3, 28, 28), fill=crate, outline=shade(crate, 1.5))
            draw.rectangle((7, 6, 24, 24), fill=shade(crate, .8), outline=shade(crate, .55))
            draw.line((8, 8, 23, 23), fill=shade(crate, 1.15), width=2)
            draw.line((23, 8, 8, 23), fill=shade(crate, 1.15), width=2)
            for x, y in ((4, 4), (26, 4), (4, 26), (26, 26)):
                draw.rectangle((x, y, x + 1, y + 1), fill=edge)
        else:
            for x in (5, 26):
                draw.line((x, 1, x, 30), fill=shade(colors["potential"], .45))
            draw.line((13, 15, 18, 15), fill=shade(floor, 1.7))
        atlas.paste(tile, (kind * TILE, 0))
    return atlas


def sprites(colors):
    atlas = Image.new("RGBA", (SPRITE[0] * 3, SPRITE[1]))
    dark = colors["infiltration_seam"]
    cloth = colors["infiltration_cloth"]
    skin = colors["infiltration_skin"]
    edge = colors["infiltration_edge"]
    hero = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(hero)
    draw.ellipse((4, 20, 20, 26), fill=(*dark, 160))
    draw.rectangle((6, 18, 10, 25), fill=shade(cloth, .55), outline=dark)
    draw.rectangle((14, 18, 18, 25), fill=shade(cloth, .55), outline=dark)
    draw.polygon(((7, 10), (16, 10), (19, 21), (14, 23), (5, 21)), fill=cloth, outline=dark)
    draw.line((9, 13, 8, 21), fill=shade(cloth, 1.4))
    draw.line((15, 14, 16, 21), fill=shade(cloth, .65))
    draw.rectangle((5, 9, 18, 13), fill=shade(cloth, 1.3), outline=dark)
    draw.rectangle((5, 14, 18, 15), fill=colors["menu_hilt"])
    draw.rectangle((3, 10, 6, 17), fill=cloth, outline=dark)
    draw.rectangle((17, 10, 20, 17), fill=cloth, outline=dark)
    draw.rectangle((3, 8, 5, 10), fill=skin)
    draw.rectangle((18, 7, 20, 10), fill=skin)
    draw.ellipse((8, 3, 15, 11), fill=shade(skin, .8), outline=dark)
    draw.arc((8, 3, 15, 11), 170, 350, fill=skin, width=2)
    draw.rectangle((10, 3, 14, 5), fill=shade(cloth, .6))
    draw.point((13, 6), fill=shade(skin, 1.2))
    atlas.paste(hero, (0, 0))
    dummy = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(dummy)
    draw.ellipse((2, 5, 21, 25), fill=dark, outline=edge)
    draw.ellipse((4, 7, 19, 23), fill=colors["infiltration_crate"])
    draw.line((12, 10, 12, 20), fill=edge, width=2)
    draw.line((7, 15, 17, 15), fill=edge, width=2)
    draw.rectangle((9, 2, 15, 7), fill=colors["menu_hilt"], outline=dark)
    atlas.paste(dummy, (24, 0))
    emitter = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(emitter)
    draw.ellipse((3, 7, 21, 26), fill=dark, outline=edge)
    draw.rectangle((7, 8, 17, 21), fill=colors["infiltration_wall"], outline=edge)
    draw.rectangle((9, 2, 15, 15), fill=colors["menu_hilt"], outline=dark)
    draw.rectangle((10, 1, 14, 3), fill=colors["bolt"])
    draw.line((8, 19, 16, 19), fill=colors["potential"])
    atlas.paste(emitter, (48, 0))
    return atlas


ROSTER_SOURCE = "data/character_roster.gd"
BROAD_BUILDS = ("bastion", "forge")
SLIM_BUILDS = ("wasp", "heron", "reaper", "echo", "ember")
SLOT_CLOAK, SLOT_BODY, SLOT_TRIM, SLOT_SKIN, SLOT_HAIR, SLOT_METAL, SLOT_LEATHER, SLOT_EYES = range(8)


def encoded(slot, light=.5, glow=0.0, alpha=255):
    return (round(light * 255), round(slot * 255 / 7), round(glow * 255), alpha)


def default_parts(character):
    source = (ROOT / f"assets/characters/{character}/art.tres").read_text(encoding="utf-8")
    match = re.search(r'default_parts = PackedStringArray\(([^)]*)\)', source)
    return re.findall(r'"(\w+)"', match.group(1)) if match else []


def hero_sprite(character):
    parts = default_parts(character)
    inset = -1 if character in BROAD_BUILDS else 1 if character in SLIM_BUILDS else 0
    image = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(image)
    dark = encoded(SLOT_BODY, .12)
    draw.ellipse((4, 20, 20, 26), fill=encoded(SLOT_BODY, .08, 0.0, 160))
    if "cape" in parts:
        draw.polygon(((6, 11), (18, 11), (21, 25), (12, 27), (3, 25)), fill=encoded(SLOT_CLOAK), outline=encoded(SLOT_CLOAK, .26))
        draw.line((12, 14, 12, 26), fill=encoded(SLOT_CLOAK, .38))
    else:
        draw.rectangle((6, 18, 10, 25), fill=encoded(SLOT_LEATHER), outline=dark)
        draw.rectangle((14, 18, 18, 25), fill=encoded(SLOT_LEATHER), outline=dark)
    if "skirt" in parts:
        draw.polygon(((6, 18), (17, 18), (19, 23), (5, 23)), fill=encoded(SLOT_BODY, .42), outline=dark)
    draw.polygon(((7, 10), (16, 10), (19 - inset, 21), (14, 23), (5 + inset, 21)), fill=encoded(SLOT_BODY), outline=dark)
    draw.line((9, 13, 8, 21), fill=encoded(SLOT_BODY, .68))
    draw.line((15, 14, 16, 21), fill=encoded(SLOT_BODY, .34))
    left, right = 5 + inset, 18 - inset
    draw.rectangle((left, 9, right, 13), fill=encoded(SLOT_CLOAK, .62), outline=dark)
    if "pad" in parts:
        draw.rectangle((left - 1, 8, left + 3, 13), fill=encoded(SLOT_METAL), outline=dark)
        draw.rectangle((right - 3, 8, right + 1, 13), fill=encoded(SLOT_METAL), outline=dark)
    draw.rectangle((left, 14, right, 15), fill=encoded(SLOT_TRIM))
    if "sash" in parts:
        draw.line((left + 2, 10, right - 2, 18), fill=encoded(SLOT_TRIM, .68), width=2)
    draw.rectangle((left - 2, 10, left + 1, 17), fill=encoded(SLOT_BODY, .46), outline=dark)
    draw.rectangle((right - 1, 10, right + 2, 17), fill=encoded(SLOT_BODY, .46), outline=dark)
    draw.rectangle((left - 2, 8, left, 10), fill=encoded(SLOT_SKIN))
    draw.rectangle((right, 7, right + 2, 10), fill=encoded(SLOT_SKIN))
    if "scarf" in parts:
        draw.rectangle((8, 10, 15, 12), fill=encoded(SLOT_TRIM, .62))
        draw.line((15, 12, 18, 20), fill=encoded(SLOT_TRIM, .5), width=2)
    if "hood" in parts:
        draw.ellipse((7, 3, 16, 12), fill=encoded(SLOT_CLOAK, .52), outline=dark)
        draw.arc((7, 3, 16, 12), 180, 360, fill=encoded(SLOT_CLOAK, .72))
        draw.rectangle((10, 3, 13, 5), fill=encoded(SLOT_METAL, .5) if "mask" in parts else encoded(SLOT_SKIN, .3))
    else:
        draw.ellipse((8, 3, 15, 11), fill=encoded(SLOT_SKIN, .42), outline=dark)
        draw.arc((8, 3, 15, 11), 170, 350, fill=encoded(SLOT_SKIN, .56))
        if "hair" in parts:
            draw.ellipse((8, 4, 15, 11), fill=encoded(SLOT_HAIR), outline=dark)
            draw.line((10, 6, 13, 6), fill=encoded(SLOT_HAIR, .68))
        if "beard" in parts:
            draw.line((10, 3, 13, 3), fill=encoded(SLOT_HAIR, .62))
    return image


def heroes():
    folder = ROOT / "assets/infiltration/heroes"
    folder.mkdir(parents=True, exist_ok=True)
    roster = re.search(r"const IDS.*?= \[(.*?)\]", (ROOT / ROSTER_SOURCE).read_text(encoding="utf-8"), re.S).group(1)
    for character in re.findall(r'&"(\w+)"', roster):
        hero_sprite(character).save(folder / f"{character}.png", optimize=True)


def main():
    colors = palette()
    folder = ROOT / "assets/infiltration"
    folder.mkdir(parents=True, exist_ok=True)
    tileset(colors).save(folder / "training_tiles.png", optimize=True)
    sprites(colors).save(folder / "training_sprites.png", optimize=True)
    enemy_sprites(colors).save(folder / "enemy_sprites.png", optimize=True)
    walker_sprite(colors).save(folder / "walker.png", optimize=True)
    prisoner_colors = dict(colors)
    prisoner_colors["infiltration_cloth"] = colors["secondary"]
    sprites(prisoner_colors).crop((0, 0, *SPRITE)).save(folder / "prisoner.png", optimize=True)
    heroes()


def walker_sprite(colors):
    image = Image.new("RGBA", (48, 56))
    draw = ImageDraw.Draw(image)
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_wall"]
    edge = colors["infiltration_edge"]
    draw.ellipse((4, 34, 44, 54), fill=(*dark, 150))
    for x in (2, 36):
        draw.rectangle((x, 26, x + 9, 48), fill=shade(metal, .6), outline=dark)
        draw.rectangle((x + 1, 44, x + 8, 50), fill=shade(metal, 1.2), outline=edge)
        draw.line((x + 2, 30, x + 7, 30), fill=edge)
    draw.polygon(((14, 8), (34, 8), (42, 20), (42, 36), (34, 44), (14, 44), (6, 36), (6, 20)), fill=metal, outline=edge)
    draw.polygon(((17, 13), (31, 13), (36, 22), (36, 33), (30, 39), (18, 39), (12, 33), (12, 22)), fill=shade(metal, 1.3), outline=dark)
    draw.rectangle((16, 18, 32, 22), fill=dark)
    draw.line((18, 20, 30, 20), fill=colors["potential"])
    for y in (28, 33):
        draw.line((17, y, 31, y), fill=shade(metal, .7))
    for x in (15, 29):
        draw.rectangle((x, 1, x + 4, 15), fill=colors["menu_hilt"], outline=dark)
        draw.rectangle((x + 1, 0, x + 3, 2), fill=colors["bolt"])
    return image


def enemy_sprites(colors):
    atlas = Image.new("RGBA", (SPRITE[0] * 6, SPRITE[1]))
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_wall"]
    edge = colors["infiltration_edge"]
    for kind in range(3):
        body = Image.new("RGBA", SPRITE)
        draw = ImageDraw.Draw(body)
        draw.ellipse((2, 20, 22, 27), fill=(*dark, 160))
        if kind == 1:
            draw.polygon(((4, 10), (19, 10), (22, 22), (17, 25), (5, 25), (1, 22)), fill=metal, outline=edge)
            draw.rectangle((6, 12, 17, 20), fill=shade(metal, .7), outline=dark)
            draw.rectangle((9, 2, 14, 16), fill=colors["menu_hilt"], outline=edge)
            draw.rectangle((10, 1, 13, 3), fill=colors["bolt"])
            draw.line((7, 21, 16, 21), fill=colors["potential"])
        else:
            shoulders = (1, 9, 22, 15) if kind == 2 else (4, 10, 19, 14)
            draw.rectangle((6, 18, 10, 25), fill=shade(metal, .6), outline=dark)
            draw.rectangle((14, 18, 18, 25), fill=shade(metal, .6), outline=dark)
            draw.rectangle((5, 11, 18, 21), fill=metal, outline=dark)
            draw.rectangle(shoulders, fill=shade(metal, 1.3), outline=edge)
            draw.line((8, 15, 8, 19), fill=edge, width=2)
            draw.rectangle((5, 20, 18, 21), fill=dark)
            draw.rectangle((9, 4, 15, 11), fill=shade(metal, 1.5), outline=dark)
            draw.rectangle((10, 5, 14, 6), fill=colors["potential"])
            draw.rectangle((18, 3, 21, 16), fill=colors["menu_hilt"], outline=dark)
            draw.line((19, 3, 20, 3), fill=colors["bolt"])
            if kind == 2:
                draw.rectangle((2, 10, 5, 14), fill=shade(metal, .7))
                draw.rectangle((18, 10, 21, 14), fill=shade(metal, .7))
        atlas.paste(body, (kind * SPRITE[0], 0))
    marksman = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(marksman)
    draw.ellipse((3, 20, 21, 27), fill=(*dark, 160))
    draw.rectangle((7, 18, 10, 25), fill=shade(metal, .6), outline=dark)
    draw.rectangle((14, 18, 17, 25), fill=shade(metal, .6), outline=dark)
    draw.rectangle((7, 11, 17, 20), fill=shade(metal, .8), outline=dark)
    draw.rectangle((5, 10, 8, 16), fill=metal, outline=dark)
    draw.rectangle((16, 10, 19, 16), fill=metal, outline=dark)
    draw.rectangle((9, 5, 15, 11), fill=shade(metal, 1.4), outline=dark)
    draw.line((10, 7, 14, 7), fill=colors["danger"])
    draw.rectangle((17, 0, 19, 13), fill=colors["menu_hilt"], outline=dark)
    draw.point((18, 0), fill=colors["danger"])
    atlas.paste(marksman, (3 * SPRITE[0], 0))
    drone = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(drone)
    draw.ellipse((5, 19, 19, 25), fill=(*dark, 120))
    draw.polygon(((12, 3), (20, 10), (20, 17), (12, 22), (4, 17), (4, 10)), fill=shade(metal, 1.1), outline=edge)
    draw.ellipse((8, 8, 16, 16), fill=dark, outline=edge)
    draw.ellipse((10, 10, 14, 14), fill=colors["danger"])
    draw.line((1, 12, 4, 12), fill=edge, width=2)
    draw.line((20, 12, 23, 12), fill=edge, width=2)
    draw.line((10, 3, 14, 3), fill=colors["potential"])
    atlas.paste(drone, (4 * SPRITE[0], 0))
    shielded = Image.new("RGBA", SPRITE)
    draw = ImageDraw.Draw(shielded)
    draw.ellipse((2, 20, 22, 27), fill=(*dark, 160))
    draw.rectangle((6, 18, 10, 25), fill=shade(metal, .6), outline=dark)
    draw.rectangle((14, 18, 18, 25), fill=shade(metal, .6), outline=dark)
    draw.rectangle((5, 11, 18, 21), fill=metal, outline=dark)
    draw.rectangle((9, 6, 15, 12), fill=shade(metal, 1.5), outline=dark)
    draw.rectangle((10, 8, 14, 9), fill=colors["potential"])
    draw.polygon(((2, 6), (6, 1), (18, 1), (22, 6), (22, 8), (2, 8)), fill=shade(edge, .9), outline=dark)
    draw.line((6, 3, 18, 3), fill=shade(edge, 1.3))
    atlas.paste(shielded, (5 * SPRITE[0], 0))
    return atlas


if __name__ == "__main__":
    main()
