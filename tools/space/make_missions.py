from pathlib import Path

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


def weapons():
    for name, fields in {
        "fighter": dict(damage="4.0", speed="460.0", interval="1.4", windup="0.45"),
        "spread": dict(damage="4.0", speed="420.0", interval="2.0", windup="0.65", count="3", spread_degrees="32.0"),
        "fan": dict(damage="4.0", speed="420.0", interval="1.6", windup="0.75", count="5", spread_degrees="60.0"),
        "missile": dict(kind="1", damage="12.0", speed="300.0", radius="6.0", projectile_hull="2.0", turn_degrees="65.0", interval="2.8", windup="0.8", max_range="2100.0"),
        "pilot_missile": dict(kind="1", damage="20.0", speed="500.0", radius="6.0", projectile_hull="2.0", turn_degrees="100.0", interval="3.5", press_only="true", max_range="1800.0"),
    }.items():
        Resource("space_weapon_data").save(f"weapons/{name}.tres", **fields)


def ships():
    r = Resource("space_ship_data")
    r.save("ships/mission_ship.tres", id='&"pilot"', name_key='"SPACE_PLAYER"', primary=r.ext("data/space/weapons/training_primary.tres"), secondary=r.ext("data/space/weapons/pilot_missile.tres"), sprite=r.ext("assets/space/training_ship.png", "Texture2D"))
    for name, hull, speed, radius, archetype, weapon in (
        ("fighter", 24, 150, 24, 1, "fighter"), ("interceptor", 20, 230, 22, 2, "fighter"),
        ("gunship", 50, 100, 36, 3, "spread"), ("launcher", 40, 0, 26, 4, "missile"),
        ("turret", 40, 0, 26, 5, "fighter"), ("capital", 180, 0, 75, 6, None),
        ("boss", 240, 0, 80, 7, "spread"), ("generator", 50, 0, 26, 8, None),
        ("engine", 60, 0, 26, 8, None), ("weakpoint", 80, 0, 26, 8, None),
    ):
        r = Resource("space_ship_data")
        fields = dict(id=f'&"{name}"', name_key=f'"SPACE_{name.upper()}"', hull=f"{hull}.0", shield="70.0" if name == "capital" else "0.0", shield_regeneration="3.0" if name == "capital" else "0.0", speed=f"{speed}.0", acceleration="300.0", radius=f"{radius}.0", archetype=str(archetype), rotation_degrees="100.0" if speed else "45.0", immobile="false" if speed else "true", can_boost="false", sprite=r.ext(f"assets/space/{name}.png", "Texture2D"))
        if weapon:
            fields["primary"] = r.ext(f"data/space/weapons/{weapon}.tres")
        r.save(f"ships/{name}.tres", **fields)


def mission(identifier, number, par):
    r = Resource("space_mission_data")

    def place(ship, x, y, team=1, **fields):
        return r.sub("space_ship_placement", ship=r.ext(f"data/space/ships/{ship}.tres"), position=f"Vector2({x}, {y})", team=str(team), angle="3.1415927" if team else "0.0", **fields)

    def wave(ship, x, y, offsets, target=-1, delay=1):
        formation = r.sub("space_formation_data", ship=r.ext(f"data/space/ships/{ship}.tres"), origin=f"Vector2({x}, {y})", offsets="Array[Vector2]([" + ", ".join(f"Vector2({a}, {b})" for a, b in offsets) + "])", target=str(target))
        return r.sub("space_wave_data", delay=f"{delay}.0", formations=r.array("space_formation_data", [formation]))

    placements = [place("mission_ship", 500, 900, 0)]
    waves = []
    phases = []
    extra = {}
    if number == 1:
        waves = [wave("fighter", 1750, 900, [(0, 0), (-110, -130), (-110, 130)]), wave("interceptor", 2000, 900, [(0, -150), (0, 150)], delay=2)]
    elif number == 2:
        waves = [wave("launcher", 1700, 900, [(0, -260), (0, 260)]), wave("gunship", 2000, 900, [(0, 0)]), wave("fighter", 1900, 900, [(0, -140), (0, 140)])]
    elif number in (3, 4):
        team = 0 if number == 3 else 1
        x = 1000 if number == 3 else 2000
        placements += [place("capital", x, 900, team, role="1", required="false" if team == 0 else "true"), place("generator", x, 740, team, role="2", parent="1", required="false" if team == 0 else "true"), place("engine", x, 1060, team, role="3", parent="1", required="false" if team == 0 else "true"), place("turret", x - 150, 900, team, role="4", parent="1", required="false"), place("turret", x + 150, 900, team, role="4", parent="1", required="false")]
        waves = [wave("fighter", 2100 if team == 0 else 1600, 500, [(0, 0), (-120, -140)], target=1 if team == 0 else 0), wave("gunship", 2200, 1300, [(0, 0)], target=1 if team == 0 else 0, delay=3)]
        if number == 3:
            extra["protected_ship"] = "1"
    else:
        placements += [place("boss", 2000, 900, role="1"), place("weakpoint", 2000, 744, role="5", parent="1", required="false"), place("weakpoint", 2000, 1056, role="5", parent="1", required="false")]
        for index, threshold, weakpoint, weapon in ((0, 1, 2, "spread"), (1, .67, 3, "missile"), (2, .34, 1, "fan")):
            phases.append(r.sub("space_boss_phase", title_key=f'"SPACE_PHASE_{index + 1}"', threshold=str(float(threshold)), weakpoint=str(weakpoint), primary=r.ext(f"data/space/weapons/{weapon}.tres")))
        extra["boss"] = "1"
    obstacles = []
    for x, y, radius in ((1150, 400, 54), (1350, 1400, 68), (650, 1350, 42)):
        obstacles.append(r.sub("space_obstacle_data", position=f"Vector2({x}, {y})", radius=f"{radius}.0", sprite=r.ext("assets/space/debris.png", "Texture2D")))
    arena = r.sub("space_arena_data", title_key=f'"SPACE_M{number}_TITLE"', size="Vector2(2800, 1800)", ships=r.array("space_ship_placement", placements), obstacles=r.array("space_obstacle_data", obstacles))
    r.save(f"missions/{identifier}.tres", id=f'&"{identifier}"', title_key=f'"SPACE_M{number}_TITLE"', briefing_key=f'"SPACE_M{number}_BRIEF"', objective_key=f'"SPACE_M{number}_OBJECTIVE"', arena=arena, waves=r.array("space_wave_data", waves), phases=r.array("space_boss_phase", phases), par_seconds=f"{par}.0", **extra)


def main():
    weapons()
    ships()
    for number, (identifier, par) in enumerate((("open_corridor", 60), ("ash_trail", 75), ("last_escort", 90), ("cut_network", 90), ("tide_iron", 105)), 1):
        mission(identifier, number, par)


if __name__ == "__main__":
    main()
