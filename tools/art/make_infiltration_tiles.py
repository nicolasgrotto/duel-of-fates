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


def main():
    colors = palette()
    folder = ROOT / "assets/infiltration"
    folder.mkdir(parents=True, exist_ok=True)
    tileset(colors).save(folder / "training_tiles.png", optimize=True)
    sprites(colors).save(folder / "training_sprites.png", optimize=True)
    enemy_sprites(colors).save(folder / "enemy_sprites.png", optimize=True)


def enemy_sprites(colors):
    atlas = Image.new("RGBA", (SPRITE[0] * 3, SPRITE[1]))
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
    return atlas


if __name__ == "__main__":
    main()
