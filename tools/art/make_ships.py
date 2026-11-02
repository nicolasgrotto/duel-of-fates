from pathlib import Path
import re
import math

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]


def palette():
    source = (ROOT / "ui/ui_palette.gd").read_text(encoding="utf-8")
    return {name: tuple(bytes.fromhex(value)) for name, value in re.findall(r'var (\w+): Color = Color\("#([0-9a-fA-F]{6})"\)', source)}


def shade(color, amount):
    return tuple(max(0, min(255, round(value * amount))) for value in color)


def player(colors):
    image = Image.new("RGBA", (40, 40))
    draw = ImageDraw.Draw(image)
    dark = colors["infiltration_seam"]
    metal = colors["prosthetic_metal"]
    edge = colors["accent"]
    draw.polygon(((17, 3), (23, 3), (29, 12), (31, 29), (24, 35), (13, 34), (9, 25), (11, 12)), fill=dark)
    draw.polygon(((17, 4), (22, 4), (27, 12), (29, 28), (23, 32), (14, 31), (11, 24), (13, 12)), fill=shade(metal, .65))
    draw.polygon(((17, 5), (22, 5), (25, 13), (24, 28), (18, 30), (13, 22), (15, 12)), fill=metal)
    draw.line((17, 5, 21, 5, 25, 13, 24, 27), fill=shade(metal, 1.18))
    draw.polygon(((17, 10), (21, 10), (23, 17), (21, 23), (17, 23), (15, 17)), fill=dark)
    draw.polygon(((18, 11), (20, 11), (21, 17), (20, 20), (17, 18)), fill=shade(colors["menu_blade_a"], .65))
    draw.line((18, 12, 19, 12, 20, 16), fill=colors["menu_blade_a"])
    draw.rectangle((6, 20, 33, 24), fill=dark)
    draw.rectangle((7, 20, 32, 22), fill=edge)
    draw.rectangle((3, 18, 9, 34), fill=dark)
    draw.rectangle((4, 19, 8, 32), fill=shade(metal, .65))
    draw.line((4, 19, 8, 19), fill=edge)
    draw.rectangle((30, 14, 36, 30), fill=dark)
    draw.rectangle((31, 15, 35, 28), fill=shade(metal, .8))
    draw.line((31, 15, 34, 15), fill=edge)
    for x, y in ((5, 24), (32, 21), (16, 27), (23, 28)):
        draw.point((x, y), fill=shade(metal, 1.18))
    draw.line((5, 33, 7, 33), fill=colors["menu_blade_b"])
    draw.line((32, 29, 34, 29), fill=colors["menu_blade_b"])
    draw.rectangle((18, 31, 22, 35), fill=dark)
    draw.line((19, 35, 21, 35), fill=colors["menu_blade_b"])
    return image


def drone(colors):
    image = Image.new("RGBA", (32, 32))
    draw = ImageDraw.Draw(image)
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_wall"]
    edge = colors["infiltration_edge"]
    draw.polygon(((9, 8), (22, 8), (28, 13), (28, 22), (22, 27), (8, 27), (3, 22), (3, 13)), fill=dark)
    draw.polygon(((10, 9), (21, 9), (26, 14), (26, 21), (21, 25), (9, 25), (5, 21), (5, 14)), fill=metal)
    draw.line((10, 9, 21, 9, 26, 14), fill=edge)
    draw.rectangle((9, 13, 21, 21), fill=dark, outline=edge)
    draw.line((12, 16, 18, 16), fill=colors["potential"], width=2)
    draw.rectangle((21, 3, 25, 15), fill=dark)
    draw.line((22, 4, 22, 14), fill=edge)
    draw.line((22, 2, 24, 2), fill=colors["bolt"])
    draw.line((9, 23, 13, 23), fill=shade(edge, .7))
    draw.point((24, 20), fill=colors["danger"])
    return image


def main():
    colors = palette()
    folder = ROOT / "assets/space"
    folder.mkdir(parents=True, exist_ok=True)
    player(colors).save(folder / "training_ship.png", optimize=True)
    drone(colors).save(folder / "target_drone.png", optimize=True)
    nebula(colors).save(folder / "nebula.png", optimize=True)


def nebula(colors):
    image = Image.new("RGBA", (256, 128))
    draw = ImageDraw.Draw(image)
    for y in range(0, 128, 2):
        for x in range(0, 256, 2):
            u, v = x / 256 * math.tau, y / 128 * math.tau
            field = .5 + .23 * math.sin(u + math.sin(v)) + .18 * math.cos(2 * u - v + .8) + .11 * math.sin(3 * v + u)
            ridge = max(0, 1 - abs(field - .48) / .16)
            alpha = round(ridge * 4) * 18
            if alpha:
                draw.rectangle((x, y, x + 1, y + 1), fill=(*colors["storm_cloud"], alpha))
    return image


if __name__ == "__main__":
    main()
