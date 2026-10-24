"""Writes the scenes and ArenaData of the arenas drawn by arenas/common/scenery_layer.gd.

Each arena is a list of scenery layers (sky, discs, silhouettes, structures, floor) with the base
palette of content/ARENAS.md, plus weather particles. Sky-like layers are fixed to the screen
vertically; everything that stands on the ground scrolls with it.

Usage (from the project root): python tools/art/make_arenas.py
"""
import os

os.chdir(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

KINDS = {k: i for i, k in enumerate(["SKY", "DISC", "RIDGE", "TOWERS", "COLUMNS", "TRUNKS", "CRYSTALS", "CEILING", "CLOUDS", "SHIP", "MONASTERY", "BRUTALIST", "RING", "FLOOR", "MIRAGE"])}
DISCS = {"MOON": 0, "SUN": 1, "PLANET": 2, "ECLIPSE": 3}
FLOORS = {k: i for i, k in enumerate(["STONE", "WATER", "ROOF", "METAL", "MOSS", "SALT", "DECK", "SNOW", "POLISHED"])}


def color(hex_value, alpha=1.0):
    h = hex_value.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.4f}, {g:.4f}, {b:.4f}, {alpha})"


def particles(name, p):
    lines = [f'[node name="{name}" type="CPUParticles2D" parent="."]']
    lines.append(f'position = Vector2({p.get("x", 0)}, {p["y"]})')
    lines.append(f'amount = {p["amount"]}')
    lines.append(f'lifetime = {p["life"]}')
    lines.append(f'preprocess = {p["life"]}')
    if p.get("streak"):
        lines.append('texture = SubResource("streak")')
    lines.append('emission_shape = 3')
    lines.append(f'emission_rect_extents = Vector2({p.get("w", 1100)}, {p.get("h", 10)})')
    lines.append(f'direction = Vector2({p["dir"][0]}, {p["dir"][1]})')
    lines.append(f'spread = {p.get("spread", 10)}')
    lines.append(f'gravity = Vector2({p.get("gravity", (0, 0))[0]}, {p.get("gravity", (0, 0))[1]})')
    lines.append(f'initial_velocity_min = {p["speed"][0]}')
    lines.append(f'initial_velocity_max = {p["speed"][1]}')
    if p.get("streak"):
        lines.append('particle_flag_align_y = true')
    lines.append(f'scale_amount_min = {p.get("scale", (2, 3))[0]}')
    lines.append(f'scale_amount_max = {p.get("scale", (2, 3))[1]}')
    lines.append(f'color = {color(p["color"], p.get("alpha", 0.3))}')
    return "\n".join(lines)


def layer(index, spec):
    parallax = spec.get("parallax")
    out = []
    parent = "."
    name = f"L{index}_{spec['kind'].lower()}"
    if parallax is not None:
        screen_fixed = spec["kind"] in ("SKY", "DISC", "RING", "CLOUDS")
        out.append(f'[node name="{name}" type="Parallax2D" parent="."]')
        out.append(f'scroll_scale = Vector2({parallax[0]}, {0.0 if screen_fixed else 1.0})')
        out.append("")
        parent = name
        name = "Layer"
    out.append(f'[node name="{name}" type="Node2D" parent="{parent}"]')
    out.append('script = ExtResource("1_layer")')
    out.append(f'kind = {KINDS[spec["kind"]]}')
    for key in ("base", "detail", "accent"):
        if key in spec:
            value = spec[key]
            out.append(f'{key}_color = {color(value[0], value[1]) if isinstance(value, tuple) else color(value)}')
    for key in ("span", "level", "height", "spacing", "element_width", "bands", "radius", "arena_width", "drift", "seed_value"):
        if key in spec:
            out.append(f"{key} = {spec[key]}")
    if "disc" in spec:
        out.append(f'disc = {DISCS[spec["disc"]]}')
    if "floor" in spec:
        out.append(f'floor_style = {FLOORS[spec["floor"]]}')
    if spec.get("stars"):
        out.append("stars = true")
    if spec.get("unlit"):
        out.append("lit_by_blades = false")
    return "\n".join(out)


ARENAS = {
    "flooded_sanctuary": dict(name="FloodedSanctuary", ambient=(0.5, 0.55, 0.66), reflective=True, mirror=0.45, ripples=True, ambience="sanctuary", layers=[
        dict(kind="SKY", base="#04070d", detail="#1a2436", accent="#9fb7d9", level=160, height=520, bands=6, stars=True, parallax=(0.0, 0.05), unlit=True),
        dict(kind="DISC", disc="MOON", base="#9fb7d9", detail="#8399bd", level=-120, radius=80, parallax=(0.04, 0.1), unlit=True),
        dict(kind="COLUMNS", base="#141a24", detail="#1a2130", level=-40, height=420, spacing=300, element_width=60, seed_value=4, parallax=(0.3, 0.45), unlit=True),
        dict(kind="COLUMNS", base="#1d2430", detail="#273041", level=0, height=520, spacing=360, element_width=80, seed_value=9, parallax=(0.6, 0.75)),
        dict(kind="FLOOR", floor="WATER", base="#0a1622", detail="#2b4058", accent="#5f7898", height=200),
    ], particles=[dict(y=-500, amount=30, life=9.0, dir=(0.2, 1), speed=(8, 16), color="#9fb7d9", alpha=0.25, w=900, h=200)]),
    "crystal_mine": dict(name="CrystalMine", ambient=(0.45, 0.42, 0.55), reflective=False, ambience="mine", layers=[
        dict(kind="CEILING", base="#0b0910", detail="#16121e", level=-250, height=110, spacing=120, element_width=70, parallax=(0.2, 0.4), unlit=True),
        dict(kind="RIDGE", base="#0e0b14", detail="#151020", level=0, height=320, spacing=200, seed_value=6, parallax=(0.25, 0.4), unlit=True),
        dict(kind="CRYSTALS", base="#2a2140", detail="#1c1630", accent="#4d3d70", level=-10, height=260, spacing=340, element_width=70, seed_value=2, parallax=(0.45, 0.6)),
        dict(kind="CRYSTALS", base="#33285a", detail="#221a3a", accent="#6a56a0", level=0, height=150, spacing=520, element_width=50, seed_value=8, parallax=(0.8, 0.9)),
        dict(kind="FLOOR", floor="STONE", base="#110d16", detail="#1d1726", accent="#3a2e52", height=200),
    ], particles=[dict(y=-200, amount=24, life=6.0, dir=(0, -1), speed=(4, 10), color="#b9a6ff", alpha=0.35, w=900, h=220, scale=(1, 2))]),
    "neon_rooftop": dict(name="NeonRooftop", ambient=(0.48, 0.52, 0.62), reflective=True, mirror=0.25, steam=True, ambience="rooftop", layers=[
        dict(kind="SKY", base="#05070d", detail="#2e3a58", level=160, height=520, bands=5, parallax=(0.0, 0.05), unlit=True),
        dict(kind="TOWERS", base="#0a0e18", detail="#2a3448", accent=("#5fd4e6", 0.5), level=40, height=1300, spacing=160, element_width=140, seed_value=3, parallax=(0.2, 0.35), unlit=True),
        dict(kind="TOWERS", base="#070a12", detail="#34405a", accent=("#5fd4e6", 0.8), level=60, height=800, spacing=260, element_width=220, seed_value=12, parallax=(0.5, 0.65), unlit=True),
        dict(kind="FLOOR", floor="ROOF", base="#10141f", detail="#1a2030", accent="#3a8a98", height=220),
    ], particles=[dict(y=-700, amount=160, life=1.2, dir=(0.35, 1), spread=2, speed=(700, 820), streak=True, color="#9fb4d9", alpha=0.3, w=1400, h=20, scale=(1, 1))]),
    "orbital_ring": dict(name="OrbitalRing", ambient=(0.55, 0.58, 0.68), reflective=True, ambience="ring", layers=[
        dict(kind="SKY", base="#000000", detail="#03050a", accent="#e8ecf5", level=200, height=500, bands=3, stars=True, parallax=(0.0, 0.03), unlit=True),
        dict(kind="DISC", disc="PLANET", base="#1c2c48", detail="#0d1626", accent="#4f7fb8", level=1560, radius=1500, parallax=(0.03, 0.06), unlit=True),
        dict(kind="RING", base="#2a3448", detail="#3a4660", accent="#8fb6e6", level=-200, radius=2800, parallax=(0.08, 0.12), unlit=True),
        dict(kind="FLOOR", floor="METAL", base="#151a24", detail="#222a38", accent="#b8c8e0", height=200),
    ], particles=[dict(y=-300, amount=18, life=12.0, dir=(1, 0), speed=(2, 5), color="#cfd8e6", alpha=0.25, w=900, h=280, scale=(1, 2))]),
    "luminous_forest": dict(name="LuminousForest", ambient=(0.42, 0.5, 0.46), reflective=False, ambience="forest", layers=[
        dict(kind="SKY", base="#030605", detail="#0c1810", level=160, height=520, bands=4, parallax=(0.0, 0.05), unlit=True),
        dict(kind="TRUNKS", base="#0a120e", detail="#0e1712", accent="#1f3a30", level=0, height=760, spacing=220, element_width=60, seed_value=5, parallax=(0.3, 0.45)),
        dict(kind="TRUNKS", base="#0c1410", detail="#142019", accent="#2f6a52", level=0, height=900, spacing=420, element_width=96, seed_value=14, parallax=(0.65, 0.8)),
        dict(kind="FLOOR", floor="MOSS", base="#0f1a14", detail="#16261c", accent="#22382b", height=200),
    ], particles=[dict(y=0, amount=34, life=8.0, dir=(0, -1), speed=(8, 18), color="#6fe0b0", alpha=0.3, w=1000, h=10, scale=(1, 2))]),
    "glass_salt_flats": dict(name="GlassSaltFlats", ambient=(0.62, 0.52, 0.52), reflective=True, mirror=0.16, salt_dust=True, ambience="salt", layers=[
        dict(kind="SKY", base="#1e1220", detail="#8a4a3c", level=110, height=420, bands=8, parallax=(0.0, 0.05), unlit=True),
        dict(kind="DISC", disc="SUN", base="#e89a5c", detail="#5a3030", level=40, radius=110, parallax=(0.03, 0.08), unlit=True),
        dict(kind="RIDGE", base="#2a1c22", detail="#3a2830", level=0, height=110, spacing=300, seed_value=7, parallax=(0.15, 0.25), unlit=True),
        dict(kind="MIRAGE", accent=("#f0c8a8", 0.5), level=-4, height=70, bands=16, element_width=70, span=1400, parallax=(0.4, 1.0), unlit=True),
        dict(kind="FLOOR", floor="SALT", base="#24212a", detail="#3a3440", accent="#6a5a60", height=200),
    ], particles=[dict(y=-20, amount=40, life=5.0, dir=(1, -0.05), speed=(60, 110), color="#d8c8c0", alpha=0.2, w=1100, h=60, scale=(1, 2))]),
    "skyborne_deck": dict(name="SkyborneDeck", ambient=(0.5, 0.55, 0.66), reflective=False, ambience="deck", wind=1.0, layers=[
        dict(kind="SKY", base="#03060d", detail="#16213a", accent="#cfd8e6", level=160, height=520, bands=5, stars=True, parallax=(0.0, 0.05), unlit=True),
        dict(kind="CLOUDS", base="#1c263c", detail="#33415c", level=160, height=90, spacing=200, element_width=220, drift=-40.0, seed_value=3, parallax=(0.1, 0.2), unlit=True),
        dict(kind="CLOUDS", base="#26324c", detail="#43526e", level=230, height=80, spacing=260, element_width=260, drift=-180.0, seed_value=9, parallax=(0.5, 0.6), unlit=True),
        dict(kind="SHIP", base="#0e131e", detail="#1a2232", accent="#5fd4e6", level=0, height=260, parallax=(0.85, 0.9)),
        dict(kind="FLOOR", floor="DECK", base="#141922", detail="#1f2633", accent="#8ea4c2", height=200),
    ], particles=[dict(y=-300, amount=40, life=0.9, dir=(-1, 0), spread=1, speed=(1300, 1600), streak=True, color="#cfd8e6", alpha=0.18, w=200, h=400, x=1300, scale=(1, 1))]),
    "snowbound_peak": dict(name="SnowboundPeak", ambient=(0.62, 0.66, 0.72), reflective=False, footprints=True, ambience="peak", layers=[
        dict(kind="SKY", base="#2e3644", detail="#6e7888", level=160, height=520, bands=6, parallax=(0.0, 0.05), unlit=True),
        dict(kind="RIDGE", base="#56606f", detail="#9aa5b6", level=0, height=420, spacing=420, seed_value=2, parallax=(0.08, 0.15), unlit=True),
        dict(kind="RIDGE", base="#2c3442", detail="#c8d2de", level=0, height=260, spacing=320, seed_value=11, parallax=(0.25, 0.35), unlit=True),
        dict(kind="MONASTERY", base="#1a2029", detail="#252d39", accent="#e0c890", level=0, parallax=(0.65, 0.75)),
        dict(kind="FLOOR", floor="SNOW", base="#3a4250", detail="#566070", accent="#8a96a8", height=200),
    ], particles=[
        dict(y=-600, amount=140, life=2.2, dir=(1, 0.35), spread=8, speed=(420, 560), color="#e8ecf5", alpha=0.45, w=300, h=600, x=-900, scale=(1, 1)),
        dict(y=-500, amount=20, life=6.0, dir=(1, 0.4), spread=10, speed=(120, 200), color="#e8ecf5", alpha=0.6, w=300, h=500, x=-900, scale=(2, 3)),
    ]),
    "eclipse_citadel": dict(name="EclipseCitadel", ambient=(0.3, 0.3, 0.34), reflective=True, mirror=0.2, ambience="citadel", layers=[
        dict(kind="SKY", base="#020203", detail="#0a090c", level=160, height=520, bands=3, parallax=(0.0, 0.04), unlit=True),
        dict(kind="DISC", disc="ECLIPSE", base="#000000", accent="#f2dcae", level=-210, radius=110, parallax=(0.04, 0.08), unlit=True),
        dict(kind="BRUTALIST", base="#121214", detail="#1c1c20", level=0, height=560, radius=240, spacing=180, element_width=120, parallax=(0.45, 0.6)),
        dict(kind="FLOOR", floor="POLISHED", base="#141416", detail="#202024", accent="#4a4232", height=220),
    ], particles=[dict(y=-300, amount=20, life=10.0, dir=(0.3, 1), speed=(4, 8), color="#f2dcae", alpha=0.2, w=900, h=300, scale=(1, 2))]),
}


def write_scene(arena_id, spec):
    folder = f"arenas/{arena_id}"
    os.makedirs(folder, exist_ok=True)
    out = ['[gd_scene format=3]', '', '[ext_resource type="Script" path="res://arenas/common/scenery_layer.gd" id="1_layer"]', '']
    if any(p.get("streak") for p in spec["particles"]):
        out += ['[sub_resource type="Gradient" id="streak_gradient"]', 'offsets = PackedFloat32Array(0, 1)', 'colors = PackedColorArray(1, 1, 1, 1, 1, 1, 1, 1)', '',
                '[sub_resource type="GradientTexture2D" id="streak"]', 'gradient = SubResource("streak_gradient")', 'width = 2', 'height = 10', '']
    out += [f'[node name="{spec["name"]}" type="Node2D"]', 'z_index = -10', '']
    for i, layer_spec in enumerate(spec["layers"]):
        out.append(layer(i, layer_spec))
        out.append("")
        if i == 0:
            out += ['[node name="SkyAnchor" type="Node2D" parent="."]', '']
    for i, p in enumerate(spec["particles"]):
        out.append(particles(f"Weather{i}", p))
        out.append("")
    with open(f"{folder}/{arena_id}.tscn", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out))


def write_data(arena_id, spec):
    key = arena_id.upper()
    lines = ['[gd_resource type="Resource" script_class="ArenaData" format=3]', '',
             '[ext_resource type="Script" path="res://data/arena_data.gd" id="1_script"]',
             '[ext_resource type="Resource" path="res://data/audio/duel_music.tres" id="3_music"]',
             '[ext_resource type="AudioStream" path="res://assets/audio/ambience/refinery.wav" id="4_ambience"]',
             f'[ext_resource type="PackedScene" path="res://arenas/{arena_id}/{arena_id}.tscn" id="2_scene"]', '', '[resource]',
             'script = ExtResource("1_script")', f'id = &"{arena_id}"', f'name_key = "ARENA_{key}"', f'phrase_key = "ARENA_PHRASE_{key}"',
             'scene = ExtResource("2_scene")', 'ambient = Color(%s, %s, %s, 1)' % spec["ambient"],
             f'reflective_floor = {"true" if spec["reflective"] else "false"}', f'wind = {spec.get("wind", 0.0)}',
             f'fighter_reflection = {spec.get("mirror", 0.0)}',
             f'knockback_dust = {"true" if spec.get("salt_dust") else "false"}',
             f'footprints = {"true" if spec.get("footprints") else "false"}',
             f'ripples = {"true" if spec.get("ripples") else "false"}',
             f'rain_steam = {"true" if spec.get("steam") else "false"}',
             'music = ExtResource("3_music")', 'ambience = ExtResource("4_ambience")']
    with open(f"data/arenas/{arena_id}.tres", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


for arena_id, spec in ARENAS.items():
    write_scene(arena_id, spec)
    write_data(arena_id, spec)
print("arenas:", len(ARENAS))
