"""Part builders: turn a fighter spec into painted parts."""
from painter import Part


def build_dims(spec):
    build = {
        "shoulder_half": 12.0, "waist_half": 9.0, "hip_half": 8.0, "torso_length": 44.0, "neck": 5.0,
        "upper_arm": 23.0, "forearm": 21.0, "thigh": 35.0, "shin": 33.0, "ankle": 4.0, "foot": 13.0,
        "arm_width": 7.5, "leg_width": 11.0, "head": 1.0, "scale": 1.0, "hunch": 0.0,
    }
    build.update(spec.get("build", {}))
    build["head"] *= HEAD_SCALE
    build["neck"] = NECK
    return build


HEAD_SCALE = 1.28
NECK = -2.5
LIMB_LIGHT = (-0.45, -0.9)


def limb(name, length, w0, w1, layers, bevel=2.5):
    part = Part(name, -w0, -w0, length + w1, w0)
    part.light = LIMB_LIGHT
    base = [(0, -w0 / 2), (length, -w1 / 2), (length, w1 / 2), (0, w0 / 2)]
    mask = part.polygon_mask(base)
    mask = (mask + part.ellipse_mask((0, 0), w0 / 2, w0 / 2) + part.ellipse_mask((length, 0), w1 / 2, w1 / 2)).clip(0, 1)
    for layer in layers:
        layer(part, mask, length, w0, w1)
    return part


def fabric(slot, tone=0.5, folds=0.6):
    def apply(part, mask, length, w0, w1):
        part.paint(mask, slot, tone=tone, folds=folds, fold_axis="x", fold_period=3.0, bevel=2.0)
    return apply


def crease(at, amount=0.3):
    def apply(part, mask, length, w0, w1):
        x = at * length
        width = max(w0, w1)
        line = part.line_mask([(x - 1.5, -width * 0.15), (x + 1.0, width * 0.5)], 1.1)
        part.darken(line * mask, amount)
    return apply


def cuff(slot, at, tone=0.6):
    def apply(part, mask, length, w0, w1):
        a = at * length
        width = max(w0, w1) * 0.62
        cuff_mask = part.polygon_mask([(a, -width), (a + 2.6, -width), (a + 2.6, width), (a, width)]) * mask
        part.paint(cuff_mask, slot, tone=tone, relief=1.5, bevel=1.0)
    return apply


def band(slot, start, end, tone=0.55, relief=1.4):
    def apply(part, mask, length, w0, w1):
        a, b = start * length, end * length
        width = max(w0, w1) * 0.62
        band_mask = part.polygon_mask([(a, -width), (b, -width), (b, width), (a, width)]) * mask
        part.paint(band_mask, slot, tone=tone, relief=relief, bevel=1.5)
    return apply


def stripes(slot, start, end, count, tone=0.72):
    def apply(part, mask, length, w0, w1):
        step = (end - start) * length / count
        width = max(w0, w1) * 0.6
        for i in range(count):
            a = start * length + i * step
            stripe = part.polygon_mask([(a, -width), (a + step * 0.55, -width), (a + step * 0.75, width), (a + step * 0.2, width)]) * mask
            part.paint(stripe, slot, tone=tone, relief=1.2, bevel=1.0, seed=i)
    return apply


def bell(slot, length_ratio, flare, tone=0.5):
    def apply(part, mask, length, w0, w1):
        a = length * length_ratio
        sleeve = part.polygon_mask([(0, -w0 / 2 - 0.5), (a, -w0 / 2 - 1), (length + 1, -w1 / 2 - flare), (length + 1, w1 / 2 + flare), (a, w0 / 2 + 1), (0, w0 / 2 + 0.5)])
        part.paint(sleeve, slot, tone=tone, folds=0.9, fold_axis="x", fold_period=2.6, bevel=2.2)
    return apply


def arm_parts(spec, dims):
    arms = spec.get("arms", {})
    upper_layers = [fabric(arms.get("sleeve_slot", "body")), crease(0.55, 0.22)]
    if arms.get("sleeve") == "wide":
        upper_layers = [bell(arms.get("sleeve_slot", "cloak"), 0.0, 1.5)]
    fore_layers = [fabric(arms.get("sleeve_slot", "body")), crease(0.3, 0.2)]
    if not arms.get("bracer") and not arms.get("wraps") and arms.get("sleeve") != "wide":
        fore_layers.append(cuff(arms.get("cuff_slot", "trim"), 0.78))
    if arms.get("sleeve") == "wide":
        fore_layers = [fabric("skin", 0.5, 0.0), bell(arms.get("sleeve_slot", "cloak"), 0.2, 4.0)]
    if arms.get("bracer"):
        fore_layers.append(band(arms.get("bracer_slot", "leather"), 0.45, 0.95, tone=0.5, relief=1.6))
    if arms.get("wraps"):
        fore_layers.append(stripes(arms.get("wraps_slot", "trim"), 0.35, 0.95, 4))
    parts = [
        limb("upper_arm", dims["upper_arm"], dims["arm_width"] * 1.1, dims["arm_width"], upper_layers),
        limb("forearm", dims["forearm"], dims["arm_width"], dims["arm_width"] * 0.85, fore_layers),
    ]
    if arms.get("torn_front"):
        torn = [fabric("skin", 0.5, 0.0), band(arms.get("sleeve_slot", "body"), 0.0, 0.3, tone=0.45), stripes("body", 0.25, 0.4, 2, tone=0.4)]
        parts.append(limb("forearm_front", dims["forearm"], dims["arm_width"] * 0.9, dims["arm_width"] * 0.75, torn))
    parts.append(fist(arms.get("hand_slot", "skin")))
    return parts


def fist(slot):
    hand = Part("hand", -5, -5, 6, 5)
    hand.light = LIMB_LIGHT
    knuckles = [(-2.6, -3.4), (2.4, -3.8), (4.4, -1.8), (4.6, 2.0), (2.6, 3.6), (-2.4, 3.4), (-3.4, 0.0)]
    hand.paint(hand.polygon_mask(knuckles), slot, tone=0.52, bevel=1.2, relief=1.4, form=0.35)
    thumb = hand.line_mask([(-1.0, -3.0), (2.2, -4.4)], 2.0)
    hand.paint(thumb, slot, tone=0.6, bevel=0.8, relief=1.6, form=0.2)
    hand.darken(hand.line_mask([(2.4, -2.6), (2.8, 2.8)], 0.8), 0.3)
    return hand


def leg_parts(spec, dims):
    legs = spec.get("legs", {})
    boot = legs.get("boot", "mid")
    thigh_layers = [fabric("body", 0.48, 0.5), crease(0.82, 0.22)]
    shin_layers = [fabric("body", 0.48, 0.5), crease(0.12, 0.18)]
    boot_start = {"low": 0.85, "mid": 0.55, "high": 0.1}[boot]
    shin_layers.append(band("leather", boot_start, 1.05, tone=0.45, relief=1.3))
    if boot != "low":
        shin_layers.append(cuff("leather", boot_start - 0.02, tone=0.58))
    if legs.get("greave"):
        shin_layers.append(band("metal", 0.0, 0.7, tone=0.6, relief=1.8))
    parts = [
        limb("thigh", dims["thigh"], dims["leg_width"] * 1.15, dims["leg_width"] * 0.9, thigh_layers),
        limb("shin", dims["shin"], dims["leg_width"] * 0.9, dims["leg_width"] * 0.7, shin_layers),
    ]
    foot = Part("boot", -6, -6, dims["foot"] + 2, dims["ankle"] + 1)
    shape = [(-4.5, -5), (3, -5), (6, -1.5), (dims["foot"], 0.5), (dims["foot"], dims["ankle"]), (-5, dims["ankle"])]
    foot.paint(foot.polygon_mask(shape), "leather", tone=0.42, bevel=1.8, relief=1.2)
    toe = foot.polygon_mask([(3, -4), (6, -1.5), (dims["foot"], 0.5), (dims["foot"], 2.0), (4, 1.0)])
    foot.lighten(toe * foot.polygon_mask(shape), 0.3)
    sole = foot.polygon_mask([(-5, dims["ankle"] - 1.6), (dims["foot"], dims["ankle"] - 1.6), (dims["foot"], dims["ankle"]), (-5, dims["ankle"])])
    foot.darken(sole * foot.polygon_mask(shape), 0.45)
    if legs.get("greave"):
        knee = Part("knee", -6, -6, 6, 6)
        knee.paint(knee.ellipse_mask((0, 0), 5.5, 5.0), "metal", tone=0.62, relief=1.8, bevel=2)
        parts.append(knee)
    parts.append(foot)
    return parts


def torso_part(spec, dims):
    torso = spec.get("torso", {})
    s, w, t = dims["shoulder_half"], dims["waist_half"], dims["torso_length"]
    part = Part("torso", -s - 4, -t - 4, s + 4, 6)
    body = [(-w, 2), (w, 2), (s * 0.95, -t + 6), (s * 0.6, -t), (-s * 0.6, -t), (-s, -t + 6)]
    base = part.polygon_mask(body)
    part.paint(base, "body", tone=0.48, folds=0.3, bevel=4, form=0.35)
    style = torso.get("tunic", "wrap")
    if style in ("wrap", "robe", "armor"):
        slot = "cloak"
        tunic = part.polygon_mask([(-w - 0.5, 2), (w + 0.5, 2), (s * 0.95, -t + 6), (s * 0.55, -t + 0.5), (-s * 0.55, -t + 0.5), (-s - 0.5, -t + 6)])
        part.paint(tunic, slot, tone=0.52 if style != "armor" else 0.5, folds=0.7 if style != "armor" else 0.2, fold_period=3.4, bevel=4, relief=1.2, form=0.38)
        if style != "armor":
            opening = part.line_mask([(s * 0.35, -t + 1), (-w * 0.2, -t * 0.35), (-w * 0.4, 0)], 0.9)
            part.darken(opening * base, 0.35)
            inner = part.polygon_mask([(s * 0.35, -t + 1), (s * 0.05, -t + 1), (-w * 0.1, -t * 0.55)])
            part.paint(inner * base, "body", tone=0.42, bevel=1.5)
            lapel = part.line_mask([(s * 0.5, -t + 1.5), (w * 0.1, -t * 0.38), (-w * 0.15, -2)], 1.0)
            part.lighten(lapel * tunic * (1 - opening), 0.32)
            part.darken(part.line_mask([(-s * 0.55, -t * 0.62), (-w * 0.6, -t * 0.25)], 0.9) * tunic, 0.22)
            part.darken(part.line_mask([(s * 0.75, -t * 0.55), (w * 0.55, -t * 0.3)], 0.8) * tunic, 0.18)
    if torso.get("plates"):
        for i, y in enumerate((-t * 0.72, -t * 0.45)):
            plate = part.polygon_mask([(-w * 0.9, y + 6), (w * 0.95, y + 6), (s * 0.8, y - 5), (-s * 0.7, y - 5)])
            part.paint(plate, "metal", tone=0.62, relief=1.9, bevel=2.2, seed=i)
    if torso.get("apron"):
        apron = part.polygon_mask([(-w * 0.4, -t * 0.62), (w + 0.5, -t * 0.62), (w + 1.5, 4), (-w * 0.2, 4)])
        part.paint(apron, "leather", tone=0.42, folds=0.4, bevel=2.5, relief=1.3)
    belt = torso.get("belt", "plain")
    if belt:
        height = 5.5 if belt == "wide" else 3.5
        belt_mask = part.polygon_mask([(-w - 0.8, -height), (w + 0.8, -height), (w + 0.8, 0.5), (-w - 0.8, 0.5)])
        part.paint(belt_mask, torso.get("belt_slot", "leather"), tone=0.45, relief=1.6, bevel=1.4)
        if torso.get("buckle", True):
            buckle = part.polygon_mask([(w * 0.25, -height + 0.6), (w * 0.85, -height + 0.6), (w * 0.85, -0.1), (w * 0.25, -0.1)])
            part.paint(buckle, "metal", tone=0.7, relief=2.0, bevel=1)
        part.darken(part.polygon_mask([(-w - 0.8, -0.8), (w + 0.8, -0.8), (w + 0.8, 0.5), (-w - 0.8, 0.5)]) * belt_mask, 0.3)
        pouch = part.polygon_mask([(-w * 0.85, -height - 0.4), (-w * 0.25, -height - 0.4), (-w * 0.25, 2.6), (-w * 0.85, 2.6)])
        part.paint(pouch, torso.get("belt_slot", "leather"), tone=0.52, relief=1.6, bevel=1.0, form=0.2)
    if torso.get("high_collar"):
        collar = part.polygon_mask([(-s * 0.7, -t - 3.5), (s * 0.75, -t - 2.5), (s * 0.55, -t + 4), (-s * 0.6, -t + 4)])
        part.paint(collar, "cloak", tone=0.55, relief=1.6, bevel=2)
    if torso.get("neck_sash"):
        sash = part.polygon_mask([(-s * 0.6, -t - 1), (s * 0.7, -t - 1), (s * 0.6, -t + 4), (-s * 0.55, -t + 4)])
        part.paint(sash, "trim", tone=0.55, relief=1.4, folds=0.5, bevel=1.5)
    return part


def overlay_parts(spec, dims):
    s, t = dims["shoulder_half"], dims["torso_length"]
    parts = []
    pad = Part("pad", -9, -7, 9, 9)
    pad.paint(pad.ellipse_mask((0, 1), 8, 6.5), "metal", tone=0.6, relief=2.0, bevel=2.5)
    pad.darken(pad.line_mask([(-6, 3), (6, 3)], 0.6), 0.3)
    parts.append(pad)
    kerchief = Part("neckerchief", -10, -6, 10, 10)
    kerchief.paint(kerchief.polygon_mask([(-8, -3), (8, -3), (4, 2), (1.5, 8), (-3, 2)]), "trim", tone=0.55, folds=0.6, bevel=1.5)
    parts.append(kerchief)
    collar = Part("collar", -14, -10, 12, 6)
    collar.paint(collar.polygon_mask([(-12, 4), (-11, -4), (-5, -8), (4, -6), (9, -1), (10, 4)]), "cloak", tone=0.5, folds=0.9, fold_axis="x", fold_period=2.4, bevel=3)
    parts.append(collar)
    return parts


def head_parts(spec, dims):
    head = spec.get("head", {})
    k = dims["head"]
    parts = []
    face = Part("head", -12 * k, -28 * k, 12 * k, 3)
    cx, cy = 1.0 * k, -14.5 * k
    neck = face.polygon_mask([(-3.8 * k, 3), (3.6 * k, 3), (3.2 * k, -7 * k), (-3.6 * k, -7 * k)])
    face.paint(neck, "skin", tone=0.4, bevel=1.5, form=0.15)
    skull = (face.ellipse_mask((cx, cy), 6.8 * k, 8.0 * k) + face.polygon_mask([(cx - 3 * k, cy + 4 * k), (cx + 6.9 * k, cy + 1 * k), (cx + 7.0 * k, cy + 4.2 * k), (cx + 4.6 * k, cy + 7.8 * k), (cx + 0.5 * k, cy + 8.4 * k), (cx - 2.5 * k, cy + 6.5 * k)])).clip(0, 1)
    face.paint(skull, "skin", tone=0.52, bevel=3, relief=1.2, form=0.4)
    nose = face.polygon_mask([(cx + 6.2 * k, cy - 1.4 * k), (cx + 8.6 * k, cy + 2.2 * k), (cx + 6.4 * k, cy + 2.8 * k)])
    face.paint(nose, "skin", tone=0.6, bevel=1, relief=1.4, form=0.1)
    face.darken(face.polygon_mask([(cx - 3.5 * k, cy + 3 * k), (cx + 1.5 * k, cy + 6.2 * k), (cx + 0.5 * k, cy + 8.6 * k), (cx - 3.6 * k, cy + 6.4 * k)]) * skull, 0.22)
    ear = face.ellipse_mask((cx - 1.4 * k, cy + 0.8 * k), 1.5 * k, 2.2 * k)
    face.paint(ear, "skin", tone=0.44, bevel=1, relief=1.3, form=0.0)
    face.darken(face.ellipse_mask((cx - 1.2 * k, cy + 1.0 * k), 0.6 * k, 1.0 * k), 0.35)
    if head.get("eclipse_eyes"):
        face.paint(face.ellipse_mask((cx + 4.6 * k, cy - 0.6 * k), 1.3 * k, 0.9 * k), "eyes", tone=0.6, emission=1.0, bevel=0.5)
    else:
        face.darken(face.ellipse_mask((cx + 4.4 * k, cy - 0.2 * k), 1.6 * k, 1.3 * k), 0.22)
        face.darken(face.ellipse_mask((cx + 4.8 * k, cy - 0.4 * k), 0.95 * k, 0.8 * k), 0.8)
    face.darken(face.line_mask([(cx + 2.6 * k, cy - 2.4 * k), (cx + 6.6 * k, cy - 2.9 * k)], 0.9 * k), 0.5)
    face.darken(face.line_mask([(cx + 4.4 * k, cy + 4.9 * k), (cx + 6.4 * k, cy + 4.6 * k)], 0.6 * k), 0.4)
    parts.append(face)
    hair = head.get("hair")
    if hair:
        part = Part("hair", -12 * k, -28 * k, 12 * k, 8 * k)
        cap = [(cx - 7.4 * k, cy + 3 * k), (cx - 7.6 * k, cy - 4 * k), (cx - 3 * k, cy - 9.2 * k), (cx + 3.5 * k, cy - 9 * k), (cx + 7.6 * k, cy - 4.5 * k), (cx + 5 * k, cy - 5.5 * k), (cx + 0.5 * k, cy - 4.5 * k), (cx - 2.5 * k, cy + 1 * k), (cx - 3 * k, cy + 4.5 * k)]
        if hair == "long":
            cap += [(cx - 4 * k, cy + 12 * k), (cx - 8.5 * k, cy + 13 * k)]
        if hair == "wavy":
            cap += [(cx - 1 * k, cy + 7.5 * k), (cx - 7.6 * k, cy + 8 * k)]
        mask = part.polygon_mask(cap)
        if hair == "ponytail":
            mask = (mask + part.polygon_mask([(cx - 6 * k, cy - 3 * k), (cx - 12 * k, cy + 1 * k), (cx - 11 * k, cy + 9 * k), (cx - 8 * k, cy + 2 * k)])).clip(0, 1)
        if hair == "bun":
            mask = (mask + part.ellipse_mask((cx - 6.5 * k, cy - 6.5 * k), 3.6 * k, 3.4 * k)).clip(0, 1)
        part.paint(mask, "hair", tone=0.5, folds=1.0, fold_axis="y", fold_period=1.6, bevel=2.2, relief=1.3, form=0.35)
        shine = part.line_mask([(cx - 3.5 * k, cy - 7.4 * k), (cx + 1.5 * k, cy - 8.4 * k), (cx + 4.5 * k, cy - 7.0 * k)], 0.9 * k)
        part.lighten(shine * mask, 0.28)
        part.darken(part.line_mask([(cx - 1.5 * k, cy - 5.6 * k), (cx - 3.0 * k, cy + 1.0 * k)], 0.7 * k) * mask, 0.3)
        parts.append(part)
    beard = head.get("beard")
    if beard:
        part = Part("beard", -12 * k, -28 * k, 12 * k, 22 * k)
        if beard == "long":
            shape = [(cx - 1.5 * k, cy + 2 * k), (cx + 7.6 * k, cy + 3 * k), (cx + 6 * k, cy + 14 * k), (cx + 2 * k, cy + 26 * k), (cx - 0.5 * k, cy + 12 * k)]
        else:
            shape = [(cx - 1.5 * k, cy + 2 * k), (cx + 7.6 * k, cy + 3 * k), (cx + 6.4 * k, cy + 8.4 * k), (cx + 1 * k, cy + 9.2 * k), (cx - 2 * k, cy + 5 * k)]
        part.paint(part.polygon_mask(shape), "hair", tone=0.55, folds=1.0, fold_axis="y", fold_period=1.4, bevel=1.8)
        parts.append(part)
    hood = head.get("hood")
    if hood:
        part = Part("hood", -16 * k, -36 * k, 14 * k, 6)
        tip = {"pointed": (cx - 11 * k, cy - 18 * k), "deep": (cx - 6 * k, cy - 12.5 * k), "plain": (cx - 5 * k, cy - 11.5 * k)}[hood]
        reach = 9.2 * k if hood == "deep" else 7.4 * k
        shape = [(cx - 9.5 * k, cy + 15 * k), (cx - 10.5 * k, cy - 2 * k), tip, (cx + 2 * k, cy - 11.5 * k), (cx + reach, cy - 6 * k), (cx + reach - 0.5 * k, cy + 4 * k), (cx + 4 * k, cy + 15 * k)]
        part.paint(part.polygon_mask(shape), "cloak", tone=0.5, folds=0.8, fold_axis="x", fold_period=2.6, bevel=3.2, relief=1.3, form=0.4)
        part.lighten(part.line_mask([(cx + 1.0 * k, cy - 8.6 * k), (cx + reach - 0.4 * k, cy - 5.6 * k), (cx + reach - 0.8 * k, cy + 5 * k)], 0.9 * k) * part.polygon_mask(shape), 0.2)
        part.darken(part.line_mask([tip, (cx - 4 * k, cy + 2 * k), (cx - 7 * k, cy + 13 * k)], 0.8 * k) * part.polygon_mask(shape), 0.3)
        opening = part.polygon_mask([(cx + 1.5 * k, cy - 7.5 * k), (cx + reach - 0.6 * k, cy - 5 * k), (cx + reach - 1.2 * k, cy + 7 * k), (cx + 2 * k, cy + 8 * k)])
        depth = 0.9 if hood == "deep" else 0.55
        part.darken(opening, depth)
        part.alpha = part.alpha * (1 - opening * (1.0 if hood != "deep" else 0.0))
        if head.get("eclipse_eyes") and hood == "deep":
            part.paint(part.ellipse_mask((cx + 5.6 * k, cy - 0.8 * k), 1.2 * k, 0.8 * k), "eyes", tone=0.6, emission=1.0, bevel=0.5)
        parts.append(part)
    mask = head.get("mask")
    if mask:
        part = Part("mask", -12 * k, -28 * k, 12 * k, 4)
        shape = [(cx + 1 * k, cy - 7.5 * k), (cx + 7.2 * k, cy - 3.5 * k), (cx + 8 * k, cy + 2 * k), (cx + 6 * k, cy + 8 * k), (cx + 1.5 * k, cy + 8.2 * k)]
        part.paint(part.polygon_mask(shape), mask.get("slot", "trim"), tone=mask.get("tone", 0.62), relief=1.6, bevel=2.4)
        part.darken(part.line_mask([(cx + 3 * k, cy - 1 * k), (cx + 7.6 * k, cy - 0.6 * k)], 0.8 * k), 0.85)
        parts.append(part)
    return parts


def cloth_part(cloth):
    name, width, length = cloth["name"], cloth["texture_width"], cloth["length"]
    part = Part(name, 0, 0, width, length + 2)
    hem = cloth.get("hem", "straight")
    points = [(0, 0), (width, 0)]
    if hem == "torn":
        teeth = 7
        for i in range(teeth, -1, -1):
            x = width * i / teeth
            y = length - (3.5 if i % 2 else 0.0) - (1.5 if i % 3 == 0 else 0)
            points.append((x, y))
    elif hem == "tails":
        points += [(width, length), (width * 0.62, length * 0.8), (width * 0.45, length), (width * 0.1, length * 0.85), (0, length * 0.7)]
    else:
        points += [(width, length), (0, length)]
    mask = part.polygon_mask(points)
    part.paint(mask, cloth.get("slot", "cloak"), tone=cloth.get("tone", 0.5), folds=cloth.get("folds", 1.0), fold_axis="y", fold_period=cloth.get("fold_period", 3.2), bevel=2.0, relief=1.2)
    edge = part.polygon_mask([(0, 0), (width, 0), (width, 1.6), (0, 1.6)])
    part.darken(edge * mask, 0.25)
    if cloth.get("trim_band"):
        band_mask = part.polygon_mask([(0, length - 3.5), (width, length - 3.5), (width, length), (0, length)]) * mask
        part.paint(band_mask, "trim", tone=0.55, relief=1.3, bevel=1.2)
    return part
