from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/infiltration"))
from make_missions import Layout, preview_image, cell_point
from PIL import Image

MISSIONS = [
    ("encircled_yard", 0, [[("soldier", (12, 8)), ("rusher", (16, 10))], [("heavy", (17, 7)), ("soldier", (12, 11))], [("rusher", (13, 7)), ("soldier", (17, 11))]]),
    ("breach_line", 1, [[("turret", (12, 8)), ("turret", (21, 8)), ("turret", (30, 8))], [("heavy", (28, 11)), ("rusher", (31, 6))]]),
    ("defense_node", 2, [[("soldier", (16, 8))], [("rusher", (16, 6)), ("soldier", (17, 11))], [("heavy", (18, 8)), ("rusher", (15, 11))]]),
    ("extraction_window", 3, [[("soldier", (14, 8)), ("rusher", (17, 10))], [("heavy", (16, 7)), ("soldier", (18, 11))]]),
    ("ally_corridor", 4, [[("soldier", (13, 8)), ("rusher", (18, 11))], [("soldier", (26, 7)), ("rusher", (30, 10))]]),
    ("retreat_vector", 5, [[("rival_0", (14, 8))], [("rusher", (16, 10))]]),
    ("siege_core", 6, [[("boss_0", (16, 8))], [("soldier", (14, 6)), ("rusher", (17, 11))]]),
]


def resource(path, kind, body, externals=""):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f'[gd_resource type="Resource" script_class="{kind}" format=3]\n\n{externals}\n{body}', encoding="utf-8")


def enemies():
    folder = ROOT / "data/blaster_ops/enemies"
    for name in ["turret", "rival_0", "rival_1", "rival_2", "boss_0", "boss_1", "boss_2"]:
        boss = name.startswith("boss")
        phase = int(name[-1]) if name[-1].isdigit() else 0
        health = 180 if boss else 80 if name.startswith("rival") else 24
        fields = f'id = &"{name}"\nhealth = {health}.0\nspeed = {0 if name == "turret" else 160 if phase == 2 else 80}.0\nvision_range = 850.0\nvision_degrees = 360.0\npreferred_range = {36 if phase == 2 else 300}.0\ncan_raise_alarm = false\nprefers_prisoners = true\ntakedown_immune = true\ntelegraph_seconds = {0.5 if phase == 2 else 0.65}\nfire_interval = 1.8\nsprite = {3 if name.startswith("rival") else 1}\n'
        if phase == 2:
            fields += 'melee_damage = 8.0\nmelee_guard_vigor = 12.0\nmelee_range = 52.0\nmelee_interval = 1.0\nmelee_flinch = 0.15\n'
        else:
            fields += 'bolt = ExtResource("bolt")\n'
        if phase == 1:
            fields += 'shot_angles = PackedFloat32Array(-20, 0, 20)\n'
        if boss:
            fields += 'body_radius = 28.0\ntexture = ExtResource("texture")\n'
        ext = '[ext_resource type="Script" path="res://data/blaster_ops/blaster_ops_enemy_data.gd" id="script"]\n[ext_resource type="Resource" path="res://data/bolts/standard_bolt.tres" id="bolt"]\n'
        if boss:
            ext += '[ext_resource type="Texture2D" path="res://assets/infiltration/walker.png" id="texture"]\n'
        resource(folder / f"{name}.tres", "BlasterOpsEnemyData", '[resource]\nscript = ExtResource("script")\n' + fields, ext)


def mission(identifier, kind, waves):
    layout = Layout(identifier, "OPS_" + identifier.upper(), 40 if kind in [1, 4] else 28, 18)
    layout.carve(1, 1, layout.width - 2, 16)
    layout.strip(2, 8, layout.width - 3, 8)
    layout.spawn = (6, 8)
    layout.exit = (34, 8) if kind in [1, 4] else (6, 8)
    covers = [(10, 5), (10, 11), (19, 5), (19, 11)] if kind in [1, 4] else [(10, 5), (10, 11)]
    for x, y in covers:
        layout.grid[y][x] = "C"
    protected = kind in [2, 4]
    layout.prisoners = [(8, 8)] if protected else [(8, 12)]
    layout.preview_center = (12, 8)
    layout.preview_hero = (layout.spawn, (1, 0))
    layout.preview_guards = [("boss" if enemy.startswith("boss") else "marksman" if enemy.startswith("rival") else "sentry" if enemy == "turret" else enemy if enemy in ["heavy", "rusher"] else "trooper", cell, (-1, 0)) for enemy, cell in waves[0]]
    preview = ROOT / f"assets/blaster_ops/previews/{identifier}.png"
    preview.parent.mkdir(parents=True, exist_ok=True)
    overrides = {"boss": Image.open(ROOT / "assets/infiltration/walker.png").convert("RGBA"), "rusher": Image.open(ROOT / "assets/blaster_ops/rusher.png").convert("RGBA")}
    preview_image(layout, overrides).save(preview, optimize=True)
    ext = ""
    paths = {"mission": ("Script", "data/blaster_ops/blaster_ops_mission_data.gd"), "map": ("Script", "data/blaster_ops/blaster_ops_arena_data.gd"), "wave": ("Script", "data/blaster_ops/blaster_ops_wave_data.gd"), "phase": ("Script", "data/blaster_ops/blaster_ops_phase_data.gd"), "placement": ("Script", "data/infiltration/infiltration_enemy_placement.gd"), "cover": ("Script", "data/blaster_ops/blaster_ops_cover_data.gd"), "tiles": ("Texture2D", "assets/infiltration/training_tiles.png"), "sprites": ("Texture2D", "assets/infiltration/training_sprites.png"), "enemies": ("Texture2D", "assets/infiltration/enemy_sprites.png"), "covers": ("Texture2D", "assets/blaster_ops/covers.png"), "preview": ("Texture2D", f"assets/blaster_ops/previews/{identifier}.png")}
    for enemy in {enemy for wave in waves for enemy, _ in wave} | ({f'{"boss" if kind == 6 else "rival"}_{i}' for i in range(3)} if kind in [5, 6] else set()):
        paths[enemy] = ("Resource", f"data/blaster_ops/enemies/{enemy}.tres")
    for name, (resource_type, path) in sorted(paths.items()):
        ext += f'[ext_resource type="{resource_type}" path="res://{path}" id="{name}"]\n'
    body = ""
    placements = []
    wave_ids = []
    for wi, wave in enumerate(waves):
        indices = []
        for enemy, cell in wave:
            index = len(placements)
            indices.append(index)
            placements.append(f'SubResource("p{index}")')
            point = cell_point(cell)
            body += f'\n[sub_resource type="Resource" id="p{index}"]\nscript = ExtResource("placement")\nenemy = ExtResource("{enemy}")\nposition = Vector2{point}\ndirection = Vector2(-1, 0)\nreinforcement = true\n'
        wave_ids.append(f'SubResource("w{wi}")')
        body += f'\n[sub_resource type="Resource" id="w{wi}"]\nscript = ExtResource("wave")\nindices = PackedInt32Array({", ".join(map(str,indices))})\nfinal_wave = {str(wi == len(waves)-1).lower()}\n'
    for index, cell in enumerate(covers):
        body += f'\n[sub_resource type="Resource" id="c{index}"]\nscript = ExtResource("cover")\ncell = Vector2i{cell}\nhealth = 30.0\n'
    phases = []
    if kind in [5, 6]:
        for index, ratio in enumerate([1.0, 0.65, 0.3]):
            phases.append(f'SubResource("f{index}")')
            enemy = f'{"boss" if kind == 6 else "rival"}_{index}'
            body += f'\n[sub_resource type="Resource" id="f{index}"]\nscript = ExtResource("phase")\nhealth_ratio = {ratio}\ntitle_key = "OPS_PHASE_{index}"\nenemy = ExtResource("{enemy}")\nstrafe = {0.5 if kind == 5 and index < 2 else 0.0}\n'
    rows = ", ".join('"'+"".join(row)+'"' for row in layout.grid)
    body += '\n[sub_resource type="Resource" id="map_data"]\nscript = ExtResource("map")\n'
    body += f'rows = PackedStringArray({rows})\nplayer_spawn = Vector2{cell_point(layout.spawn)}\nenemies = Array[ExtResource("placement")]([{", ".join(placements)}])\ncovers = Array[ExtResource("cover")]([{", ".join(f"SubResource(\"c{i}\")" for i in range(len(covers)))}])\n'
    body += 'tiles = ExtResource("tiles")\nsprites = ExtResource("sprites")\nenemy_sprites = ExtResource("enemies")\ncover_atlas = ExtResource("covers")\nenemies_alerted = false\n'
    body += f'\n[resource]\nscript = ExtResource("mission")\nid = &"{identifier}"\nobjective = 1\nkind = {kind}\ntitle_key = "OPS_{identifier.upper()}"\nbriefing_key = "OPS_{identifier.upper()}_BRIEF"\nmap = SubResource("map_data")\npreview = ExtResource("preview")\nwaves = Array[ExtResource("wave")]([{", ".join(wave_ids)}])\n'
    body += f'prisoner_spawns = PackedVector2Array({", ".join(str(v) for cell in layout.prisoners for v in cell_point(cell))})\nminimum_prisoners = {1 if protected else 0}\nextraction = Vector2{cell_point(layout.exit)}\nbonus_seconds = {120 if kind in [1,4,6] else 90}.0\n'
    if protected:
        body += f'protected_index = 0\nprotected_health = {240 if kind == 2 else 180}.0\n'
    if kind == 1:
        body += 'defense_targets = PackedInt32Array(0, 1, 2)\n'
    if kind == 3:
        body += 'hold_seconds = 45.0\n'
    if phases:
        body += f'phase_target = 0\nphases = Array[ExtResource("phase")]([{", ".join(phases)}])\n'
    resource(ROOT / f"data/blaster_ops/missions/{identifier}.tres", "BlasterOpsMissionData", body, ext)


if __name__ == "__main__":
    enemies()
    for definition in MISSIONS:
        mission(*definition)
