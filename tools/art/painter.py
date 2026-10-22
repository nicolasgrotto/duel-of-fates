"""Procedural painter for fighter parts, drawn on the pixel grid of the world (1 pixel = 2 u).

Shapes are painted at a fine scale and then reduced to the grid with hard edges: coverage becomes
on or off, the shade snaps to four fixed tones and the outer border gets a darker one-pixel rim.
Each part is written as two PNG files:
- <part>.png: material map. R = shade (0.5 is the base tone), G = palette slot / 7,
  B = emission, A = coverage.
- <part>_n.png: normal map (OpenGL convention, Y up).
The game recolors the material map with the costume palette (see
presentation/fighters/fighter_material.gdshader).
"""
import math
import zlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

PIXELS_PER_UNIT = 0.5
SUPERSAMPLE = 8
TONES = np.array([0.3, 0.42, 0.53, 0.68], np.float32)
RIM_TONE = 0.2
COVERAGE_THRESHOLD = 0.5
SLOTS = {"cloak": 0, "body": 1, "trim": 2, "skin": 3, "hair": 4, "metal": 5, "leather": 6, "eyes": 7}
NORMAL_STRENGTH = 0.6
FORM_LIGHT = (0.85, -0.55)


class Part:
    def __init__(self, name, left, top, right, bottom):
        self.name = name
        self.left, self.top, self.right, self.bottom = left, top, right, bottom
        self.scale = PIXELS_PER_UNIT * SUPERSAMPLE
        self.light = FORM_LIGHT
        self.width = int(math.ceil((right - left) * PIXELS_PER_UNIT)) * SUPERSAMPLE
        self.height = int(math.ceil((bottom - top) * PIXELS_PER_UNIT)) * SUPERSAMPLE
        shape = (self.height, self.width)
        self.alpha = np.zeros(shape, np.float32)
        self.shade = np.zeros(shape, np.float32)
        self.slot = np.zeros(shape, np.float32)
        self.emission = np.zeros(shape, np.float32)
        self.heightmap = np.zeros(shape, np.float32)
        ys, xs = np.mgrid[0:self.height, 0:self.width]
        self.ux = xs / self.scale + left
        self.uy = ys / self.scale + top

    def pivot_pixels(self):
        return (-self.left * PIXELS_PER_UNIT, -self.top * PIXELS_PER_UNIT)

    def _px(self, point):
        return ((point[0] - self.left) * self.scale, (point[1] - self.top) * self.scale)

    def _mask(self, draw_fn):
        image = Image.new("L", (self.width, self.height), 0)
        draw_fn(ImageDraw.Draw(image))
        return np.asarray(image, np.float32) / 255.0

    def polygon_mask(self, points):
        pixels = [self._px(p) for p in points]
        return self._mask(lambda d: d.polygon(pixels, fill=255))

    def ellipse_mask(self, center, rx, ry):
        a = self._px((center[0] - rx, center[1] - ry))
        b = self._px((center[0] + rx, center[1] + ry))
        return self._mask(lambda d: d.ellipse([a, b], fill=255))

    def line_mask(self, points, width):
        pixels = [self._px(p) for p in points]
        w = max(int(width * self.scale), 1)
        return self._mask(lambda d: (d.line(pixels, fill=255, width=w, joint="curve"),
                                     [d.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=255) for p in (pixels[0], pixels[-1])]))

    def paint(self, mask, slot, tone=0.5, bevel=3.0, relief=1.0, folds=0.0, fold_axis="y", fold_period=4.0,
              grain=0.04, emission=0.0, top_light=0.12, seed=0, form=0.3, light=None):
        if mask.max() <= 0.0:
            return
        blur_px = max(bevel * self.scale / 4.0, 1.0)
        soft = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur_px)), np.float32) / 255.0
        inner = np.clip(soft * mask * 1.6, 0.0, 1.0)
        rng = np.random.default_rng(seed + zlib.crc32(self.name.encode()) % 10000)
        noise = rng.normal(0.0, 1.0, mask.shape).astype(np.float32)
        noise = np.asarray(Image.fromarray(((noise * 0.2 + 0.5).clip(0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255.0 - 0.5
        coordinate = self.ux if fold_axis == "x" else self.uy
        other = self.uy if fold_axis == "x" else self.ux
        wave = np.sin(other * (2 * math.pi / fold_period) + np.sin(coordinate * 0.21) * 2.2) * (0.6 + 0.4 * np.sin(coordinate * 0.13 + other * 0.07))
        ys = mask.any(axis=1).nonzero()[0]
        if ys.size:
            span = max(ys[-1] - ys[0], 1)
            vertical = (np.arange(mask.shape[0])[:, None] - ys[0]) / span
        else:
            vertical = np.zeros((mask.shape[0], 1))
        gy, gx = np.gradient(soft)
        lx, ly = light if light is not None else self.light
        lit = np.clip(-(gx * lx + gy * ly) * blur_px * 2.2, -1.0, 1.0)
        tone_map = tone * (0.8 + 0.2 * inner) * (1.0 + top_light * (0.5 - vertical)) * (1.0 + form * lit) + folds * 0.025 * wave + grain * noise
        height_map = relief * (0.6 * inner + 0.4) + folds * 0.18 * wave + grain * 0.6 * noise
        a = mask
        self.shade = self.shade * (1 - a) + tone_map * a
        self.heightmap = self.heightmap * (1 - a) + height_map * a
        self.slot = np.where(a > 0.5, SLOTS[slot] / 7.0, self.slot)
        self.emission = self.emission * (1 - a) + emission * a
        self.alpha = np.maximum(self.alpha, a)

    def darken(self, mask, amount):
        self.shade = self.shade * (1 - mask * amount)
        self.heightmap = self.heightmap - mask * amount * 0.8

    def lighten(self, mask, amount):
        self.shade = self.shade * (1 + mask * amount)
        self.heightmap = self.heightmap + mask * amount * 0.5

    def save(self, folder):
        size = (self.width // SUPERSAMPLE, self.height // SUPERSAMPLE)

        def down(array):
            image = Image.fromarray((np.clip(array, 0, 1) * 255).astype(np.uint8))
            return np.asarray(image.resize(size, Image.Resampling.BOX), np.float32) / 255.0

        coverage = down(self.alpha)
        alpha = (coverage >= COVERAGE_THRESHOLD).astype(np.float32)
        shade = down(self.shade * self.alpha) / np.maximum(coverage, 1e-3)
        level = np.abs(shade[..., None] - TONES[None, None, :]).argmin(axis=-1)
        dark_edge, lit_edge = rim_sides(alpha, self.light)
        level = np.where(lit_edge > 0, np.minimum(level + 1, len(TONES) - 1), level)
        shade = np.where(dark_edge > 0, RIM_TONE, TONES[level]) * alpha
        emission = (down(self.emission) >= 0.5).astype(np.float32) * alpha
        slot = np.asarray(Image.fromarray((self.slot * 255).astype(np.uint8)).resize(size, Image.Resampling.NEAREST), np.float32) / 255.0
        height = down(self.heightmap * self.alpha / 2.0) * 2.0
        material = np.stack([shade, slot, emission, alpha], axis=-1)
        Image.fromarray((material * 255).astype(np.uint8), "RGBA").save(f"{folder}/{self.name}.png", optimize=True)
        gy, gx = np.gradient(height)
        nx = -gx * NORMAL_STRENGTH
        ny = gy * NORMAL_STRENGTH
        nz = np.ones_like(nx)
        length = np.sqrt(nx * nx + ny * ny + nz * nz)
        normal = np.stack([nx / length, ny / length, nz / length], axis=-1) * 0.5 + 0.5
        normal_rgba = np.concatenate([normal, alpha[..., None]], axis=-1)
        Image.fromarray((normal_rgba * 255).astype(np.uint8), "RGBA").save(f"{folder}/{self.name}_n.png", optimize=True)
        return size


def rim_sides(alpha, light):
    padded = np.pad(alpha, 1)
    lx, ly = light
    length = max(math.hypot(lx, ly), 1e-3)
    lx, ly = lx / length, ly / length
    solid = alpha > 0
    dark = np.zeros(alpha.shape, bool)
    lit = np.zeros(alpha.shape, bool)
    for dx, dy, neighbour in ((1, 0, padded[1:-1, 2:]), (-1, 0, padded[1:-1, :-2]), (0, 1, padded[2:, 1:-1]), (0, -1, padded[:-2, 1:-1])):
        open_side = solid & (neighbour == 0)
        if dx * lx + dy * ly > 0.35:
            lit |= open_side
        else:
            dark |= open_side
    return dark.astype(np.int64), (lit & ~dark).astype(np.int64)


def rim(alpha):
    padded = np.pad(alpha, 1)
    neighbours = np.minimum.reduce([padded[:-2, 1:-1], padded[2:, 1:-1], padded[1:-1, :-2], padded[1:-1, 2:]])
    return ((alpha > 0) & (neighbours == 0)).astype(np.int64)
