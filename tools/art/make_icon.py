from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/boot_splash_clean.png"
TARGET = ROOT / "assets/icon.png"
CROP = (170, 370, 1010, 550)
SKY = (3, 6, 15, 255)
CANVAS = 768
SIZE = 256
ANGLE = 45


def main():
    art = Image.open(SOURCE).convert("RGBA").crop(CROP)
    turned = art.rotate(ANGLE, resample=Image.NEAREST, expand=True)
    mask = Image.new("L", art.size, 255).rotate(ANGLE, resample=Image.NEAREST, expand=True)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), SKY)
    canvas.paste(turned, ((CANVAS - turned.width) // 2, (CANVAS - turned.height) // 2), mask)
    canvas.resize((SIZE, SIZE), Image.NEAREST).save(TARGET, optimize=True)


if __name__ == "__main__":
    main()
