from pathlib import Path
import math
import random
import re

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "data/space"


class Resource:
    def __init__(self, script):
        self.externals = {}
        self.subs = []
        self.script = self.ext(f"data/space/{script}.gd", "Script")

    def ext(self, path, kind="Resource"):
        if path not in self.externals:
            self.externals[path] = (str(len(self.externals) + 1), kind)
        return f'ExtResource("{self.externals[path][0]}")'

    def sub(self, script, **values):
        ref = self.ext(f"data/space/{script}.gd", "Script")
        name = f"Part_{len(self.subs) + 1}"
        self.subs.append((name, ref, values))
        return f'SubResource("{name}")'

    def array(self, script, values):
        ref = self.ext(f"data/space/{script}.gd", "Script")
        return f'Array[{ref}]([{", ".join(values)}])'

    def save(self, path, **values):
        lines = ['[gd_resource type="Resource" format=3]', ""]
        for resource, (index, kind) in self.externals.items():
            lines.append(f'[ext_resource type="{kind}" path="res://{resource}" id="{index}"]')
        for name, script, fields in self.subs:
            lines.extend(["", f'[sub_resource type="Resource" id="{name}"]', f"script = {script}"])
            lines.extend(f"{key} = {value}" for key, value in fields.items())
        lines.extend(["", "[resource]", f"script = {self.script}"])
        lines.extend(f"{key} = {value}" for key, value in values.items())
        target = FOLDER / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(lines) + "\n", encoding="utf-8")


WEAPONS = {
    "fighter": dict(damage="4.0", speed="460.0", interval="1.4", windup="0.45"),
    "spread": dict(damage="4.0", speed="420.0", interval="2.0", windup="0.65", count="3", spread_degrees="32.0"),
    "fan": dict(damage="4.0", speed="420.0", interval="1.6", windup="0.75", count="5", spread_degrees="60.0"),
    "missile": dict(kind="1", damage="12.0", speed="300.0", radius="6.0", projectile_hull="2.0", turn_degrees="65.0", interval="2.8", windup="0.8", max_range="2100.0"),
    "pilot_missile": dict(kind="1", damage="20.0", speed="500.0", radius="6.0", projectile_hull="2.0", turn_degrees="100.0", interval="3.5", press_only="true", max_range="1800.0"),
    "needle_primary": dict(damage="7.0", interval="0.13", muzzle="30.0"),
    "needle_missile": dict(kind="1", damage="14.0", speed="560.0", radius="6.0", projectile_hull="2.0", turn_degrees="130.0", interval="5.0", press_only="true", max_range="1600.0", muzzle="30.0"),
    "anvil_primary": dict(damage="16.0", speed="900.0", radius="4.0", interval="0.3", muzzle="56.0"),
    "anvil_missile": dict(kind="1", damage="30.0", speed="420.0", radius="6.0", projectile_hull="2.0", turn_degrees="80.0", interval="5.0", press_only="true", max_range="1800.0", muzzle="56.0"),
    "spear_primary": dict(damage="14.0", speed="1400.0", max_range="2000.0", interval="0.28"),
    "spear_missile": dict(kind="1", damage="25.0", speed="520.0", radius="6.0", projectile_hull="2.0", turn_degrees="110.0", interval="2.2", press_only="true", max_range="2200.0"),
}
PLAYER_SHIPS = {
    "mission_ship": dict(id='&"pilot"', name_key='"SPACE_PLAYER"', description_key='"SPACE_SHIP_PILOT_DESC"', hull="100.0", shield="28.0", shield_delay="3.0", shield_regeneration="8.0", primary="data/space/weapons/training_primary.tres", secondary="data/space/weapons/pilot_missile.tres", sprite="assets/space/training_ship.png"),
    "needle": dict(id='&"needle"', name_key='"SPACE_SHIP_NEEDLE"', description_key='"SPACE_SHIP_NEEDLE_DESC"', hull="70.0", shield="18.0", shield_delay="2.2", shield_regeneration="10.0", acceleration="800.0", speed="440.0", rotation_degrees="260.0", radius="20.0", contact_ratio="1.5", boost_cooldown_ratio="0.67", primary="data/space/weapons/needle_primary.tres", secondary="data/space/weapons/needle_missile.tres", sprite="assets/space/needle.png"),
    "anvil": dict(id='&"anvil"', name_key='"SPACE_SHIP_ANVIL"', description_key='"SPACE_SHIP_ANVIL_DESC"', hull="150.0", shield="45.0", shield_delay="3.5", shield_regeneration="6.0", acceleration="420.0", speed="270.0", rotation_degrees="150.0", radius="34.0", contact_ratio="0.5", boost_cooldown_ratio="1.67", primary="data/space/weapons/anvil_primary.tres", secondary="data/space/weapons/anvil_missile.tres", sprite="assets/space/anvil.png"),
    "spear": dict(id='&"spear"', name_key='"SPACE_SHIP_SPEAR"', description_key='"SPACE_SHIP_SPEAR_DESC"', hull="85.0", shield="24.0", shield_delay="3.0", shield_regeneration="8.0", speed="330.0", rotation_degrees="170.0", primary="data/space/weapons/spear_primary.tres", secondary="data/space/weapons/spear_missile.tres", sprite="assets/space/spear.png"),
}
ENEMIES = (
    ("fighter", 24, 150, 24, 1, "fighter"), ("interceptor", 20, 230, 22, 2, "fighter"),
    ("gunship", 50, 100, 36, 3, "spread"), ("launcher", 40, 0, 26, 4, "missile"),
    ("turret", 60, 0, 26, 5, "fighter"), ("capital", 600, 0, 75, 6, None),
    ("ally_capital", 420, 0, 75, 6, None), ("boss", 1500, 0, 80, 7, "spread"),
    ("generator", 120, 0, 26, 8, None), ("engine", 140, 0, 26, 8, None), ("weakpoint", 500, 0, 26, 8, None),
)
SPRITE_NAMES = {"ally_capital": "capital"}
NAME_KEYS = {"ally_capital": "SPACE_CAPITAL"}
OBSTACLES = ((1150, 400, 54), (1350, 1400, 68), (650, 1350, 42))
GRAVEYARD_OBSTACLES = (
    (860, 380, 58), (1040, 760, 74), (880, 1260, 66), (1280, 340, 50), (1420, 980, 84), (1300, 1500, 60),
    (1700, 560, 70), (1800, 1240, 76), (2080, 300, 56), (2180, 860, 88), (2100, 1560, 62), (2500, 520, 64),
    (2560, 1180, 72), (640, 620, 44), (620, 1540, 48), (1560, 180, 40),
)
MISSIONS = {
    "open_corridor": dict(number=1, par=180, limit=420),
    "ash_trail": dict(number=2, par=210, limit=480),
    "last_escort": dict(number=3, par=270, limit=540),
    "cut_network": dict(number=4, par=270, limit=540),
    "iron_graveyard": dict(number=6, par=240, limit=540),
    "tide_iron": dict(number=5, par=270, limit=600),
}
PAIR = [(0, -90), (0, 90)]
WEDGE = [(0, 0), (-110, -130), (-110, 130)]
LINE = [(0, -200), (0, 0), (0, 200)]


def weapons():
    for name, fields in WEAPONS.items():
        Resource("space_weapon_data").save(f"weapons/{name}.tres", **fields)


def ships():
    for name, fields in PLAYER_SHIPS.items():
        r = Resource("space_ship_data")
        values = {key: value for key, value in fields.items() if key not in ("primary", "secondary", "sprite")}
        values["primary"] = r.ext(fields["primary"])
        values["secondary"] = r.ext(fields["secondary"])
        values["sprite"] = r.ext(fields["sprite"], "Texture2D")
        r.save(f"ships/{name}.tres", **values)
    for name, hull, speed, radius, archetype, weapon in ENEMIES:
        r = Resource("space_ship_data")
        key = NAME_KEYS.get(name, f"SPACE_{name.upper()}")
        fields = dict(id=f'&"{name}"', name_key=f'"{key}"', hull=f"{hull}.0", shield="40.0" if name == "ally_capital" else "70.0" if name == "capital" else "0.0", shield_regeneration="2.0" if name == "ally_capital" else "3.0" if name == "capital" else "0.0", speed=f"{speed}.0", acceleration="300.0", radius=f"{radius}.0", archetype=str(archetype), rotation_degrees="100.0" if speed else "45.0", immobile="false" if speed else "true", can_boost="false", sprite=r.ext(f"assets/space/{SPRITE_NAMES.get(name, name)}.png", "Texture2D"))
        if weapon:
            fields["primary"] = r.ext(f"data/space/weapons/{weapon}.tres")
        r.save(f"ships/{name}.tres", **fields)


def mission(identifier):
    spec = MISSIONS[identifier]
    number = spec["number"]
    r = Resource("space_mission_data")

    def place(ship, x, y, team=1, **fields):
        return r.sub("space_ship_placement", ship=r.ext(f"data/space/ships/{ship}.tres"), position=f"Vector2({x}, {y})", team=str(team), angle="3.1415927" if team else "0.0", **fields)

    def group(ship, x, y, offsets, target=-1):
        for a, b in offsets:
            spawn_x, spawn_y = x - a, y - b
            for ox, oy, radius in obstacles_source:
                assert math.hypot(spawn_x - ox, spawn_y - oy) > radius + 50, f"{identifier}: {ship} at {spawn_x},{spawn_y} overlaps debris at {ox},{oy}"
        return r.sub("space_formation_data", ship=r.ext(f"data/space/ships/{ship}.tres"), origin=f"Vector2({x}, {y})", offsets="Array[Vector2]([" + ", ".join(f"Vector2({a}, {b})" for a, b in offsets) + "])", target=str(target))

    def wave(delay, *formations):
        return r.sub("space_wave_data", delay=f"{delay}.0", formations=r.array("space_formation_data", list(formations)))

    def timed(delay, *placements):
        return r.sub("space_wave_data", delay=f"{delay}.0", ships=r.array("space_ship_placement", list(placements)))

    placements = [place("mission_ship", 500, 900, 0)]
    waves = []
    phases = []
    extra = {}
    obstacles_source = GRAVEYARD_OBSTACLES if identifier == "iron_graveyard" else OBSTACLES
    if identifier == "open_corridor":
        waves = [
            wave(1, group("fighter", 1750, 900, WEDGE)),
            wave(6, group("interceptor", 2000, 900, [(0, -150), (0, 150)])),
            wave(7, group("fighter", 2000, 420, PAIR), group("fighter", 2000, 1380, PAIR)),
            wave(7, group("interceptor", 2300, 900, LINE), group("fighter", 1700, 200, PAIR)),
            wave(8, group("gunship", 2100, 900, [(0, 0)]), group("fighter", 1900, 1500, PAIR)),
            wave(8, group("gunship", 2200, 500, [(0, 0)]), group("gunship", 2200, 1300, [(0, 0)]), group("interceptor", 2500, 900, LINE)),
            wave(8, group("fighter", 2400, 300, WEDGE), group("fighter", 2400, 1500, WEDGE)),
            wave(9, group("gunship", 2500, 900, [(0, 0)]), group("interceptor", 2300, 300, LINE), group("interceptor", 2300, 1500, LINE)),
        ]
    elif identifier == "ash_trail":
        waves = [
            wave(1, group("launcher", 1700, 900, [(0, -260), (0, 260)])),
            wave(6, group("gunship", 2000, 900, [(0, 0)])),
            wave(6, group("fighter", 1900, 500, PAIR), group("interceptor", 1900, 1300, PAIR)),
            wave(7, group("launcher", 2400, 900, [(0, -520), (0, 520)]), group("fighter", 2100, 900, PAIR)),
            wave(8, group("gunship", 2200, 500, [(0, 0)]), group("gunship", 2200, 1300, [(0, 0)])),
            wave(9, group("launcher", 2500, 900, [(0, -200), (0, 200)]), group("interceptor", 1800, 200, [(0, 0)])),
            wave(8, group("gunship", 2300, 400, [(0, 0)]), group("gunship", 2300, 1400, [(0, 0)]), group("fighter", 2000, 900, WEDGE)),
            wave(10, group("launcher", 1720, 900, [(0, -420), (0, 420)]), group("interceptor", 2500, 900, PAIR)),
            wave(9, group("gunship", 2500, 900, [(0, 0)]), group("fighter", 2200, 300, WEDGE), group("fighter", 2200, 1500, WEDGE)),
        ]
    elif identifier == "last_escort":
        x = 1000
        placements += [place("ally_capital", x, 900, 0, role="1", required="false"), place("generator", x, 740, 0, role="2", parent="1", required="false"), place("engine", x, 1060, 0, role="3", parent="1", required="false"), place("turret", x - 150, 900, 0, role="4", parent="1", required="false"), place("turret", x + 150, 900, 0, role="4", parent="1", required="false")]
        extra["protected_ship"] = "1"
        waves = [
            wave(1, group("fighter", 2100, 500, [(0, 0), (-120, -140)], target=1)),
            wave(7, group("gunship", 2200, 1300, [(0, 0)], target=1)),
            wave(7, group("fighter", 2300, 900, WEDGE, target=1)),
            wave(8, group("interceptor", 2100, 300, PAIR), group("gunship", 2300, 1400, [(0, 0)], target=1)),
            wave(8, group("fighter", 2200, 400, PAIR, target=1), group("fighter", 2200, 1400, PAIR, target=1)),
            wave(9, group("gunship", 2300, 500, [(0, 0)], target=1), group("gunship", 2300, 1300, [(0, 0)], target=1)),
            wave(9, group("interceptor", 2500, 900, LINE), group("fighter", 2000, 200, PAIR, target=1)),
            wave(9, group("gunship", 2400, 900, [(0, 0)], target=1), group("fighter", 2100, 300, PAIR, target=1), group("fighter", 2100, 1500, PAIR, target=1)),
            wave(9, group("interceptor", 2500, 300, LINE), group("interceptor", 2500, 1500, LINE)),
            wave(10, group("gunship", 2500, 500, [(0, 0)], target=1), group("gunship", 2500, 1300, [(0, 0)], target=1), group("fighter", 2200, 900, WEDGE, target=1)),
        ]
    elif identifier == "cut_network":
        x = 2000
        placements += [place("capital", x, 900, 1, role="1", required="true"), place("generator", x, 740, 1, role="2", parent="1", required="true"), place("engine", x, 1060, 1, role="3", parent="1", required="true"), place("turret", x - 150, 900, 1, role="4", parent="1", required="false"), place("turret", x + 150, 900, 1, role="4", parent="1", required="false")]
        waves = [
            wave(1, group("fighter", 1600, 500, [(0, 0), (-120, -140)], target=0)),
            wave(6, group("gunship", 2200, 1300, [(0, 0)], target=0)),
            wave(7, group("interceptor", 2500, 400, LINE)),
            wave(8, group("gunship", 2500, 1400, [(0, 0)], target=0), group("fighter", 1700, 300, PAIR, target=0)),
            wave(8, group("fighter", 1600, 1500, PAIR, target=0), group("interceptor", 2500, 200, PAIR)),
            wave(9, group("gunship", 2500, 300, [(0, 0)], target=0), group("gunship", 2500, 1500, [(0, 0)], target=0)),
            wave(9, group("fighter", 1500, 200, WEDGE, target=0), group("interceptor", 2500, 900, LINE)),
        ]
    elif identifier == "iron_graveyard":
        waves = [
            wave(1, group("fighter", 1500, 620, [(0, 0), (-80, -110)])),
            wave(6, group("interceptor", 1250, 1180, PAIR), group("interceptor", 1250, 120, [(0, -40), (0, 40)])),
            wave(7, group("launcher", 2360, 560, [(0, 0)]), group("launcher", 2360, 1360, [(0, 0)]), group("fighter", 1600, 1500, PAIR)),
            wave(8, group("gunship", 1900, 900, [(0, 0)]), group("interceptor", 780, 160, [(0, -40), (0, 40)])),
            wave(8, group("fighter", 760, 1660, [(0, -40), (-80, -40)]), group("fighter", 2340, 120, [(0, -40), (0, 40)]), group("launcher", 1560, 780, [(0, 0)])),
            wave(9, group("gunship", 2360, 1000, [(0, 0)]), group("gunship", 1600, 1700, [(0, 0)]), group("interceptor", 1100, 1020, [(0, -60), (0, 60)])),
            wave(9, group("gunship", 2640, 860, [(0, 0)]), group("launcher", 2340, 1700, [(0, 0)]), group("fighter", 1900, 1040, WEDGE), group("interceptor", 1540, 1250, PAIR)),
            wave(9, group("launcher", 1180, 1180, [(0, 0)]), group("interceptor", 2680, 240, PAIR), group("interceptor", 2680, 1640, PAIR)),
            wave(10, group("gunship", 1900, 150, [(0, 0)]), group("gunship", 1560, 1000, [(0, 0)]), group("fighter", 2400, 1500, WEDGE), group("fighter", 2340, 300, PAIR)),
        ]
    else:
        placements += [place("boss", 2000, 900, role="1"), place("weakpoint", 2000, 744, role="5", parent="1", required="false"), place("weakpoint", 2000, 1056, role="5", parent="1", required="false")]
        for index, threshold, weakpoint, weapon in ((0, 1, 2, "spread"), (1, .67, 3, "missile"), (2, .34, 1, "fan")):
            phases.append(r.sub("space_boss_phase", title_key=f'"SPACE_PHASE_{index + 1}"', threshold=str(float(threshold)), weakpoint=str(weakpoint), primary=r.ext(f"data/space/weapons/{weapon}.tres")))
        extra["boss"] = "1"
        waves = [timed(25, place("fighter", 2500, y, required="false"), place("fighter", 2500, y + 180, required="false")) for y in (300, 1320, 300, 1320)]
        waves += [timed(30, place("interceptor", 2600, 200, required="false"), place("interceptor", 2600, 1600, required="false"))]
    obstacles = []
    for x, y, radius in obstacles_source:
        obstacles.append(r.sub("space_obstacle_data", position=f"Vector2({x}, {y})", radius=f"{radius}.0", sprite=r.ext("assets/space/debris.png", "Texture2D")))
    arena = r.sub("space_arena_data", title_key=f'"SPACE_M{number}_TITLE"', size="Vector2(2800, 1800)", ships=r.array("space_ship_placement", placements), obstacles=r.array("space_obstacle_data", obstacles))
    r.save(f"missions/{identifier}.tres", id=f'&"{identifier}"', title_key=f'"SPACE_M{number}_TITLE"', briefing_key=f'"SPACE_M{number}_BRIEF"', objective_key=f'"SPACE_M{number}_OBJECTIVE"', arena=arena, waves=r.array("space_wave_data", waves), phases=r.array("space_boss_phase", phases), par_seconds=f'{spec["par"]}.0', limit_seconds=f'{spec["limit"]}.0', preview=r.ext(f"assets/space/previews/{identifier}.png", "Texture2D"), **extra)


PREVIEW_SIZE = (480, 170)
PREVIEW_SCENES = {
    "open_corridor": [("fighter", 340, 85, 180), ("fighter", 300, 45, 180), ("fighter", 300, 125, 180), ("interceptor", 420, 40, 180), ("interceptor", 420, 130, 180)],
    "ash_trail": [("launcher", 330, 45, 180), ("launcher", 330, 125, 180), ("gunship", 400, 85, 180), ("debris", 240, 30, 0), ("debris", 225, 140, 0)],
    "last_escort": [("capital", 210, 85, 0), ("fighter", 370, 45, 180), ("fighter", 350, 120, 180), ("gunship", 430, 85, 180)],
    "cut_network": [("capital", 340, 85, 180), ("turret", 250, 85, 180), ("generator", 340, 22, 180), ("engine", 340, 148, 180), ("fighter", 200, 40, 180)],
    "iron_graveyard": [("debris", 170, 40, 0), ("debris", 250, 120, 0), ("debris", 320, 40, 0), ("debris", 400, 110, 0), ("debris", 110, 140, 0), ("interceptor", 290, 85, 180), ("launcher", 440, 35, 180), ("fighter", 360, 130, 180)],
    "tide_iron": [("boss", 360, 85, 180), ("weakpoint", 360, 30, 180), ("weakpoint", 360, 140, 180), ("fighter", 230, 40, 180), ("fighter", 230, 130, 180)],
}
PILOT_POINT = (70, 85)
STARS = 70


def palette():
    source = (ROOT / "ui/ui_palette.gd").read_text(encoding="utf-8")
    return {name: tuple(bytes.fromhex(value)) for name, value in re.findall(r'var (\w+): Color = Color\("#([0-9a-fA-F]{6})"\)', source)}


def preview(identifier, colors):
    assets = ROOT / "assets/space"
    image = Image.new("RGBA", PREVIEW_SIZE, (*colors["background"], 255))
    nebula = Image.open(assets / "nebula.png").convert("RGBA")
    offset = MISSIONS[identifier]["number"] * 37
    for x in range(-offset, PREVIEW_SIZE[0], nebula.width):
        for y in range(0, PREVIEW_SIZE[1], nebula.height):
            image.alpha_composite(nebula, (max(x, 0), y), (max(-x, 0), 0))
    draw = ImageDraw.Draw(image)
    stars = random.Random(identifier)
    for star in range(STARS):
        draw.point((stars.randrange(PREVIEW_SIZE[0]), stars.randrange(PREVIEW_SIZE[1])), fill=(*colors["secondary"], stars.choice((90, 140, 220))))

    def place(name, x, y, degrees):
        sprite = Image.open(assets / f"{name}.png").convert("RGBA")
        turned = sprite.rotate(-degrees - 90, resample=Image.NEAREST, expand=True) if name != "debris" else sprite
        layer = Image.new("RGBA", PREVIEW_SIZE)
        layer.paste(turned, (x - turned.width // 2, y - turned.height // 2))
        image.alpha_composite(layer)

    for name, x, y, degrees in PREVIEW_SCENES[identifier]:
        place(name, x, y, degrees)
    place("training_ship", PILOT_POINT[0], PILOT_POINT[1], 0)
    for start, end in ((PILOT_POINT[0] + 34, PILOT_POINT[0] + 62), (PILOT_POINT[0] + 76, PILOT_POINT[0] + 104)):
        glow = Image.new("RGBA", PREVIEW_SIZE)
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.line(((start, PILOT_POINT[1]), (end, PILOT_POINT[1])), fill=(*colors["menu_blade_a"], 70), width=5)
        glow_draw.line(((start, PILOT_POINT[1]), (end, PILOT_POINT[1])), fill=(*colors["menu_blade_a"], 255), width=2)
        image.alpha_composite(glow)
    return image


def main():
    weapons()
    ships()
    colors = palette()
    previews = ROOT / "assets/space/previews"
    previews.mkdir(parents=True, exist_ok=True)
    for identifier in MISSIONS:
        mission(identifier)
        preview(identifier, colors).save(previews / f"{identifier}.png", optimize=True)


if __name__ == "__main__":
    main()
