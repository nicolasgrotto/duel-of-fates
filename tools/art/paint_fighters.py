"""Paints every fighter in fighter_specs.py into assets/characters/<id>/ and writes art.tres.

Usage (from the project root): python tools/art/paint_fighters.py [id ...]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from fighter_parts import arm_parts, build_dims, cloth_part, head_parts, leg_parts, overlay_parts, torso_part
from fighter_specs import SPECS, cape
from painter import PIXELS_PER_UNIT

OPTIONAL_DEFAULTS = {"pad": "pads", "hood": "hood", "mask": "mask"}


def paint(fighter_id, spec, root):
    folder = os.path.join(root, "assets", "characters", fighter_id)
    os.makedirs(folder, exist_ok=True)
    dims = build_dims(spec)
    head_spec = dict(spec.get("head", {}))
    default_parts = []
    if head_spec.get("hood"):
        default_parts.append("hood")
    else:
        head_spec["hood"] = "plain"
    if head_spec.get("mask"):
        default_parts.append("mask")
    else:
        head_spec["mask"] = dict(slot="trim", tone=0.62)
    if spec.get("head", {}).get("hair"):
        default_parts.append("hair")
    if spec.get("head", {}).get("beard"):
        default_parts.append("beard")
    if spec.get("pads"):
        default_parts.append("pad")
    if spec.get("legs", {}).get("greave"):
        default_parts.append("knee")
    painted_spec = dict(spec)
    painted_spec["head"] = head_spec
    parts = [torso_part(painted_spec, dims)]
    parts += head_parts(painted_spec, dims)
    parts += arm_parts(painted_spec, dims)
    parts += leg_parts(painted_spec, dims)
    parts += overlay_parts(painted_spec, dims)
    cloths = [dict(c) for c in spec.get("cloth", [])]
    default_parts += [c["name"] for c in cloths]
    if not any(c["name"] == "cape" for c in cloths):
        cloths.append(cape(100.0, top=22.0, bottom=32.0))
    for cloth in cloths:
        parts.append(cloth_part(cloth))
    pivots = {}
    for part in parts:
        part.save(folder)
        pivots[part.name] = part.pivot_pixels()
    remove_stale(folder, {p.name for p in parts})
    write_art_resource(folder, fighter_id, parts, pivots, dims, cloths, default_parts)
    print(f"{fighter_id}: {len(parts)} parts")


def remove_stale(folder, names):
    for file_name in os.listdir(folder):
        stem = file_name.split(".")[0]
        if file_name.endswith((".png", ".png.import")) and stem.removesuffix("_n") not in names:
            os.remove(os.path.join(folder, file_name))


def vec(value):
    return f"Vector2({value[0]:.2f}, {value[1]:.2f})"


def write_art_resource(folder, fighter_id, parts, pivots, dims, cloths, default_parts):
    lines = ['[gd_resource type="Resource" script_class="FighterArt" format=3]', "",
             '[ext_resource type="Script" path="res://presentation/fighters/fighter_art.gd" id="1_script"]']
    base = f"res://assets/characters/{fighter_id}"
    for part in parts:
        lines.append(f'[ext_resource type="Texture2D" path="{base}/{part.name}.png" id="t_{part.name}"]')
        lines.append(f'[ext_resource type="Texture2D" path="{base}/{part.name}_n.png" id="n_{part.name}"]')
    lines += ["", "[resource]", 'script = ExtResource("1_script")', f"pixels_per_unit = {float(PIXELS_PER_UNIT)}"]
    lines.append("textures = {" + ", ".join(f'"{p.name}": ExtResource("t_{p.name}")' for p in parts) + "}")
    lines.append("normals = {" + ", ".join(f'"{p.name}": ExtResource("n_{p.name}")' for p in parts) + "}")
    lines.append("pivots = {" + ", ".join(f'"{name}": {vec(value)}' for name, value in pivots.items()) + "}")
    lines.append("dims = {" + ", ".join(f'"{k}": {float(v)}' for k, v in dims.items()) + "}")
    cloth_entries = []
    for cloth in cloths:
        fields = ", ".join(f'"{k}": {fmt(v)}' for k, v in cloth.items() if k in CLOTH_FIELDS)
        cloth_entries.append("{" + fields + "}")
    lines.append("cloths = [" + ", ".join(cloth_entries) + "]")
    lines.append("default_parts = PackedStringArray(" + ", ".join(f'"{p}"' for p in default_parts) + ")")
    with open(os.path.join(folder, "art.tres"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


CLOTH_FIELDS = ("name", "anchor", "layer", "length", "top_width", "bottom_width", "stiffness", "segments")


def fmt(value):
    if isinstance(value, str):
        return f'"{value}"'
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    return f"{float(value)}"


if __name__ == "__main__":
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    selected = sys.argv[1:] or list(SPECS)
    for fighter_id in selected:
        paint(fighter_id, SPECS[fighter_id], root)
