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


def main():
    folder = Path(__file__).resolve().parents[2] / "assets/blaster_ops"
    folder.mkdir(parents=True, exist_ok=True)
    colors = palette()
    cover_atlas(colors).save(folder / "covers.png")
    rusher(colors).save(folder / "rusher.png")


if __name__ == "__main__":
    main()
