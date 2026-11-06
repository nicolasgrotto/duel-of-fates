from pathlib import Path

from PIL import Image, ImageDraw

from make_infiltration_tiles import palette, shade, tileset


def cover_atlas(colors):
    crate = tileset(colors).crop((64, 0, 96, 32))
    atlas = Image.new("RGBA", (128, 32))
    for stage in range(4):
        frame = crate.copy()
        draw = ImageDraw.Draw(frame)
        if stage >= 1:
            draw.line(((8, 4), (13, 12), (10, 18), (18, 26)), fill=colors["infiltration_seam"], width=2)
            draw.line(((9, 4), (14, 12)), fill=colors["infiltration_edge"])
        if stage >= 2:
            draw.line(((26, 5), (21, 13), (25, 21), (18, 26)), fill=colors["infiltration_seam"], width=2)
            draw.rectangle((11, 11, 20, 19), fill=shade(colors["infiltration_crate"], .4))
        if stage == 3:
            frame = Image.new("RGBA", (32, 32))
            draw = ImageDraw.Draw(frame)
            draw.polygon(((4, 22), (10, 18), (18, 21), (26, 19), (28, 26), (13, 28), (3, 26)), fill=shade(colors["infiltration_crate"], .6), outline=colors["infiltration_seam"])
            draw.line((8, 23, 21, 24), fill=colors["infiltration_edge"])
        atlas.paste(frame, (stage * 32, 0))
    return atlas


def rusher(colors):
    frame = Image.new("RGBA", (24, 28))
    draw = ImageDraw.Draw(frame)
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_wall"]
    edge = colors["infiltration_edge"]
    draw.ellipse((3, 21, 21, 27), fill=(*dark, 150))
    draw.rectangle((6, 18, 10, 25), fill=shade(metal, .7), outline=dark)
    draw.rectangle((14, 17, 18, 24), fill=shade(metal, .7), outline=dark)
    draw.polygon(((7, 10), (17, 10), (19, 21), (5, 21)), fill=metal, outline=dark)
    draw.rectangle((3, 10, 7, 15), fill=shade(metal, 1.3), outline=dark)
    draw.rectangle((17, 8, 21, 13), fill=shade(metal, 1.3), outline=dark)
    draw.rectangle((9, 5, 15, 11), fill=shade(metal, 1.5), outline=dark)
    draw.line((10, 7, 14, 7), fill=colors["potential"])
    draw.line((18, 4, 20, 18), fill=dark, width=3)
    draw.line((18, 4, 20, 16), fill=edge)
    draw.rectangle((7, 18, 17, 20), fill=dark)
    return frame


def warden(colors):
    frame = Image.new("RGBA", (28, 32))
    draw = ImageDraw.Draw(frame)
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_wall"]
    glow = colors["aurora"]
    draw.ellipse((4, 25, 24, 31), fill=(*dark, 150))
    draw.polygon(((6, 11), (22, 11), (24, 25), (4, 25)), fill=metal, outline=dark)
    draw.rectangle((2, 11, 7, 18), fill=shade(metal, 1.3), outline=dark)
    draw.rectangle((21, 11, 26, 18), fill=shade(metal, 1.3), outline=dark)
    draw.rectangle((10, 5, 18, 12), fill=shade(metal, 1.5), outline=dark)
    draw.line((11, 8, 17, 8), fill=glow)
    draw.rectangle((11, 15, 17, 21), fill=shade(glow, .55), outline=glow)
    draw.line((14, 1, 14, 5), fill=glow)
    return frame


def sapper(colors):
    frame = Image.new("RGBA", (24, 28))
    draw = ImageDraw.Draw(frame)
    dark = colors["infiltration_seam"]
    cloth = colors["infiltration_cloth"]
    charge = colors["danger"]
    draw.ellipse((4, 22, 20, 27), fill=(*dark, 150))
    draw.rectangle((7, 18, 10, 25), fill=shade(cloth, .7), outline=dark)
    draw.rectangle((14, 18, 17, 25), fill=shade(cloth, .7), outline=dark)
    draw.polygon(((7, 9), (17, 9), (18, 20), (6, 20)), fill=cloth, outline=dark)
    draw.rectangle((9, 4, 15, 10), fill=shade(cloth, 1.4), outline=dark)
    draw.rectangle((6, 12, 18, 18), fill=shade(charge, .55), outline=dark)
    draw.rectangle((9, 13, 11, 17), fill=charge)
    draw.rectangle((13, 13, 15, 17), fill=charge)
    draw.line((12, 4, 12, 1), fill=charge)
    return frame


def repairer(colors):
    frame = Image.new("RGBA", (24, 28))
    draw = ImageDraw.Draw(frame)
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_edge"]
    light = colors["text"]
    draw.ellipse((3, 21, 21, 27), fill=(*dark, 150))
    draw.rectangle((6, 18, 10, 25), fill=shade(metal, .6), outline=dark)
    draw.rectangle((14, 18, 18, 25), fill=shade(metal, .6), outline=dark)
    draw.polygon(((7, 10), (17, 10), (18, 21), (6, 21)), fill=shade(metal, .8), outline=dark)
    draw.rectangle((9, 5, 15, 11), fill=metal, outline=dark)
    draw.rectangle((5, 12, 19, 20), fill=shade(metal, 1.1), outline=dark)
    draw.line((12, 13, 12, 19), fill=light, width=2)
    draw.line((9, 16, 15, 16), fill=light, width=2)
    draw.line((19, 4, 22, 14), fill=dark, width=2)
    draw.point((19, 3), fill=light)
    return frame


def ironstride(colors):
    frame = Image.new("RGBA", (64, 72))
    draw = ImageDraw.Draw(frame)
    dark = colors["infiltration_seam"]
    metal = colors["infiltration_wall"]
    edge = colors["infiltration_edge"]
    hot = colors["danger"]
    draw.ellipse((6, 50, 58, 70), fill=(*dark, 120))
    draw.polygon(((16, 26), (24, 18), (40, 18), (48, 26), (50, 46), (42, 56), (22, 56), (14, 46)), fill=metal, outline=dark)
    draw.polygon(((22, 28), (28, 23), (36, 23), (42, 28), (43, 42), (38, 49), (26, 49), (21, 42)), fill=shade(metal, 1.35), outline=dark)
    draw.rectangle((9, 30, 15, 44), fill=shade(metal, .75), outline=dark)
    draw.rectangle((49, 30, 55, 44), fill=shade(metal, .75), outline=dark)
    draw.rectangle((35, 2, 41, 30), fill=shade(metal, .9), outline=dark)
    draw.rectangle((36, 0, 40, 4), fill=dark)
    draw.line((37, 6, 37, 26), fill=edge)
    draw.rectangle((29, 26, 44, 36), fill=shade(metal, 1.6), outline=dark)
    draw.rectangle((23, 34, 28, 40), fill=hot, outline=dark)
    draw.line((26, 44, 38, 44), fill=edge)
    draw.line((26, 47, 38, 47), fill=dark)
    return frame


def main():
    folder = Path(__file__).resolve().parents[2] / "assets/blaster_ops"
    folder.mkdir(parents=True, exist_ok=True)
    colors = palette()
    cover_atlas(colors).save(folder / "covers.png")
    rusher(colors).save(folder / "rusher.png")
    warden(colors).save(folder / "warden.png")
    sapper(colors).save(folder / "sapper.png")
    repairer(colors).save(folder / "repairer.png")
    ironstride(colors).save(folder / "ironstride.png")


if __name__ == "__main__":
    main()
