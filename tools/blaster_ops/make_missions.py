from collections import deque
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/infiltration"))
from make_missions import Layout, preview_image, cell_point
from PIL import Image

KINDS = {"training_infiltration": 0, "training_incursion": 0, "encircled_yard": 0, "breach_line": 1, "defense_node": 2, "extraction_window": 3, "ally_corridor": 4, "retreat_vector": 5, "siege_core": 6}
SPRITES = {"boss": "assets/infiltration/walker.png", "rusher": "assets/blaster_ops/rusher.png", "crusher": "assets/blaster_ops/crusher.png", "duelist": "assets/blaster_ops/duelist.png", "warden": "assets/blaster_ops/warden.png", "sapper": "assets/blaster_ops/sapper.png", "repairer": "assets/blaster_ops/repairer.png", "ironstride": "assets/blaster_ops/ironstride.png"}
PREVIEW_KIND = {"soldier": "trooper", "turret": "sentry", "heavy": "heavy", "marksman": "marksman", "rusher": "rusher", "crusher": "crusher", "duelist": "duelist", "warden": "warden", "sapper": "sapper", "repairer": "repairer", "ironstride": "ironstride"}
OBJECTIVES = {"clear": 0, "destroy": 1, "hold": 2, "reach": 3, "interact": 4, "escort": 5, "boss": 6, "action": 7}
ACTIONS = {name: index for index, name in enumerate(["move", "run", "sneak", "fire", "cut", "guard", "parry", "dodge", "power", "switch", "deploy", "order", "buy", "takedown", "panel", "recruit"])}
TILE_RADIUS = 64


class Plan(Layout):
    def __init__(self, identifier, width, height):
        super().__init__(identifier, "OPS_" + identifier.upper(), width, height)
        self.kind = KINDS[identifier]
        self.covers = []
        self.waves = []
        self.placements = []
        self.stages = []
        self.roles = []
        self.reserve = []
        self.supply = []
        self.protected = None
        self.protected_health = 180
        self.barriers = 0
        self.heavy = 0
        self.prep_only = False
        self.start_supplies = 0
        self.bonus = 300
        self.damage_bonus = 70
        self.accuracy_bonus = 0.45
        self.phase_target = -1
        self.phase_prefix = ""
        self.preview_cones = False
        self.guards = {}
        self.tutorial = False
        self.objective_value = 1
        self.forced_weapon = ""
        self.damage_scale = 1.0

    def room(self, x0, y0, x1, y1):
        self.carve(x0, y0, x1, y1)

    def crates(self, *cells):
        for cell in cells:
            self.grid[cell[1]][cell[0]] = "C"
            self.covers.append((cell, False))

    def door(self, cells):
        first = len(self.covers)
        for cell in cells:
            self.grid[cell[1]][cell[0]] = "C"
            self.covers.append((cell, True))
        return list(range(first, first + len(cells)))

    def guard(self, name, cell, direction):
        index = len(self.placements)
        self.placements.append((name, cell))
        self.guards[index] = direction
        return index

    def action(self, name, count=1, hints=(), targets=(), first=-1, opens=(), prep=0.5, reward=0, repair=0.0, zone=None, radius=0):
        self.stage("action", first=first, targets=targets, opens=opens, prep=prep, reward=reward, repair=repair, zone=zone, radius=radius)
        self.stages[-1].update({"action": ACTIONS[name], "count": count, "hints": list(hints)})

    def wave(self, *entries):
        indices = []
        for name, cell in entries:
            indices.append(len(self.placements))
            self.placements.append((name, cell))
        self.waves.append(indices)
        return indices

    def stage(self, objective, first=-1, last=-1, gap=0.0, targets=(), terminals=(), opens=(), hold=0.0, zone=None, radius=0, prep=4.0, reward=2, repair=25.0, clear=False):
        self.stages.append({"objective": OBJECTIVES[objective], "first": first, "last": last if last >= 0 else first, "gap": gap, "targets": list(targets), "terminals": list(terminals), "opens": list(opens), "hold": hold, "zone": zone, "radius": radius, "prep": prep, "reward": reward, "repair": repair, "clear": clear})

    def ally(self, cell, role):
        self.prisoners.append(cell)
        self.roles.append(role)


def encircled_yard():
    p = Plan("encircled_yard", 66, 36)
    p.room(2, 11, 19, 25)
    p.room(21, 3, 47, 33)
    p.room(49, 10, 63, 26)
    p.carve(20, 16, 20, 20)
    p.carve(48, 16, 48, 20)
    p.strip(3, 18, 62, 18)
    p.spawn, p.exit = (5, 18), (60, 18)
    p.crates((12, 14), (12, 22), (15, 18), (28, 10), (29, 10), (38, 10), (39, 10), (28, 26), (29, 26), (38, 26), (39, 26), (33, 14), (35, 22), (54, 14), (54, 22))
    west = p.door([(20, y) for y in range(16, 21)])
    east = p.door([(48, y) for y in range(16, 21)])
    p.ally((24, 6), "medic")
    p.ally((44, 30), "rifleman")
    hub = cell_point((34, 18))
    w0 = len(p.waves)
    p.wave(("soldier", (16, 14)), ("soldier", (16, 22)))
    p.wave(("rusher", (18, 18)), ("soldier", (17, 12)), ("marksman", (18, 24)))
    p.stage("clear", w0, w0 + 1, opens=west, prep=6.0)
    w2 = len(p.waves)
    p.wave(("sapper", (30, 8)), ("sapper", (30, 28)), ("soldier", (38, 18)), ("marksman", (45, 6)))
    p.stage("reach", w2, zone=hub, radius=TILE_RADIUS * 3)
    w3 = len(p.waves)
    p.wave(("soldier", (24, 5)), ("rusher", (24, 31)), ("heavy", (44, 18)))
    p.wave(("sapper", (44, 5)), ("sapper", (44, 31)), ("warden", (34, 6)), ("soldier", (34, 30)))
    p.wave(("rusher", (22, 18)), ("rusher", (46, 18)), ("heavy", (34, 31)))
    p.stage("hold", w3, w3 + 2, gap=14.0, hold=45.0, zone=hub, radius=TILE_RADIUS * 3)
    w6 = len(p.waves)
    pylons = p.wave(("turret", (34, 5)), ("turret", (34, 31)), ("repairer", (25, 18)), ("warden", (43, 18)), ("soldier", (40, 8)), ("soldier", (40, 28)))[:2]
    p.stage("destroy", w6, targets=pylons, opens=east)
    w7 = len(p.waves)
    p.wave(("heavy", (58, 14)), ("heavy", (58, 22)), ("marksman", (62, 18)), ("rusher", (52, 12)), ("rusher", (52, 24)), ("repairer", (61, 12)))
    p.stage("clear", w7, reward=0)
    p.bonus, p.damage_bonus = 300, 70
    p.preview_center, p.preview_hero = (26, 18), ((20, 18), (1, 0))
    p.preview_guards = [("soldier", (31, 15), (-1, 0)), ("rusher", (30, 21), (-1, 0)), ("heavy", (33, 19), (-1, 0))]
    return p


def breach_line():
    p = Plan("breach_line", 92, 24)
    p.room(2, 4, 20, 19)
    p.room(22, 4, 40, 19)
    p.room(42, 4, 60, 19)
    p.room(62, 4, 88, 19)
    p.strip(3, 11, 87, 12)
    for x in [21, 41, 61]:
        p.carve(x, 9, x, 14)
    p.spawn, p.exit = (5, 11), (86, 11)
    p.crates((10, 7), (10, 16), (14, 11), (28, 7), (28, 16), (34, 9), (34, 14), (48, 7), (48, 16), (52, 11), (68, 8), (68, 15), (74, 11))
    d1 = p.door([(21, y) for y in range(9, 15)])
    d2 = p.door([(41, y) for y in range(9, 15)])
    d3 = p.door([(61, y) for y in range(9, 15)])
    p.supply = [(5, 6), (44, 6)]
    p.barriers = 2
    p.terminals = [(39, 17)]
    p.ally((7, 17), "rifleman")
    a = len(p.waves)
    towers = p.wave(("turret", (17, 7)), ("turret", (17, 16)), ("soldier", (19, 11)), ("rusher", (18, 6)))[:2]
    p.stage("destroy", a, targets=towers, opens=d1, prep=6.0)
    b = len(p.waves)
    p.wave(("sapper", (31, 6)), ("sapper", (31, 17)), ("soldier", (36, 11)), ("soldier", (38, 7)), ("marksman", (39, 6)))
    p.wave(("heavy", (38, 12)), ("warden", (36, 8)))
    p.stage("clear", b, b + 1)
    c = len(p.waves)
    p.wave(("rusher", (24, 6)), ("rusher", (24, 17)), ("soldier", (26, 11)))
    p.stage("interact", c, terminals=[0], opens=d2)
    entry = len(p.waves)
    p.wave(("marksman", (46, 17)), ("rusher", (50, 6)), ("rusher", (50, 18)), ("soldier", (54, 8)))
    p.wave(("soldier", (54, 15)), ("sapper", (47, 6)), ("sapper", (47, 18)))
    p.stage("clear", entry, entry + 1)
    d = len(p.waves)
    second = p.wave(("turret", (56, 6)), ("turret", (56, 17)), ("turret", (59, 11)), ("heavy", (55, 11)), ("marksman", (59, 5)), ("repairer", (58, 18)))[:3]
    p.wave(("soldier", (44, 5)), ("soldier", (44, 18)), ("warden", (46, 11)))
    p.stage("destroy", d, d + 1, gap=18.0, targets=second, opens=d3)
    e = len(p.waves)
    p.wave(("ironstride", (80, 11)), ("soldier", (76, 7)), ("soldier", (76, 16)))
    p.wave(("sapper", (86, 6)), ("sapper", (86, 17)), ("warden", (84, 11)))
    p.stage("clear", e, e + 1, gap=20.0)
    g = len(p.waves)
    p.wave(("soldier", (64, 6)), ("soldier", (64, 17)), ("rusher", (66, 11)))
    p.wave(("heavy", (64, 11)), ("sapper", (72, 6)), ("sapper", (72, 17)), ("marksman", (63, 5)))
    p.stage("hold", g, g + 1, gap=15.0, hold=30.0, zone=cell_point((84, 11)), radius=TILE_RADIUS * 3, reward=0, prep=5.0)
    p.bonus, p.damage_bonus = 330, 90
    p.preview_center, p.preview_hero = (70, 11), ((62, 11), (1, 0))
    p.preview_guards = [("ironstride", (73, 11), (-1, 0)), ("soldier", (70, 7), (-1, 0)), ("soldier", (70, 15), (-1, 0))]
    return p


def defense_node():
    p = Plan("defense_node", 60, 40)
    p.room(18, 8, 42, 32)
    p.room(3, 14, 14, 26)
    p.room(46, 14, 57, 26)
    p.carve(15, 18, 17, 22)
    p.carve(43, 18, 45, 22)
    p.strip(19, 20, 41, 20)
    p.spawn, p.exit = (26, 20), (30, 25)
    p.protected, p.protected_health = 0, 520
    p.ally((30, 20), None)
    west = p.door([(16, y) for y in range(18, 23)])
    east = p.door([(44, y) for y in range(18, 23)])
    p.crates((23, 13), (37, 13), (23, 27), (37, 27))
    p.supply = [(21, 11)]
    p.barriers = 2
    p.prep_only = True
    p.terminals = [(6, 20), (54, 20)]
    p.reserve = ["rifleman", "gunner"]
    a = len(p.waves)
    p.wave(("soldier", (30, 10)), ("soldier", (30, 30)), ("rusher", (20, 20)))
    p.wave(("heavy", (40, 20)), ("sapper", (30, 10)))
    p.stage("clear", a, a + 1, opens=west + east, prep=9.0)
    b = len(p.waves)
    p.wave(("soldier", (10, 16)), ("marksman", (4, 24)), ("rusher", (30, 10)), ("rusher", (30, 30)))
    p.stage("interact", b, terminals=[0], prep=7.0)
    c = len(p.waves)
    p.wave(("warden", (50, 16)), ("soldier", (50, 24)), ("heavy", (40, 10)), ("sapper", (20, 30)))
    p.stage("interact", c, terminals=[1], prep=7.0)
    d = len(p.waves)
    p.wave(("soldier", (30, 10)), ("soldier", (30, 30)), ("rusher", (20, 12)), ("repairer", (40, 28)))
    p.wave(("sapper", (20, 28)), ("sapper", (40, 12)), ("heavy", (40, 20)), ("warden", (20, 20)))
    p.wave(("ironstride", (30, 10)), ("rusher", (40, 30)), ("rusher", (20, 10)))
    p.stage("hold", d, d + 2, gap=18.0, hold=60.0, prep=8.0, clear=True, reward=0)
    p.bonus, p.damage_bonus = 360, 70
    p.preview_center, p.preview_hero = (30, 20), ((24, 20), (1, 0))
    p.preview_guards = [("soldier", (36, 17), (-1, 0)), ("sapper", (37, 22), (-1, 0)), ("heavy", (34, 23), (-1, 1))]
    return p


def extraction_window():
    p = Plan("extraction_window", 84, 34)
    p.room(2, 10, 22, 24)
    p.room(26, 2, 46, 14)
    p.room(24, 16, 47, 20)
    p.room(50, 8, 80, 30)
    p.carve(23, 16, 23, 20)
    p.carve(34, 15, 38, 15)
    p.carve(48, 16, 49, 20)
    p.strip(3, 18, 79, 18)
    p.spawn, p.exit = (5, 18), (65, 19)
    tower_door = p.door([(x, 15) for x in range(34, 39)])
    field_door = p.door([(49, y) for y in range(16, 21)])
    p.crates((12, 13), (12, 22), (18, 18), (30, 6), (42, 6), (30, 11), (42, 11), (55, 12), (55, 26), (60, 15), (70, 15), (60, 23), (70, 23), (75, 12), (75, 26))
    p.ally((44, 4), "sharpshooter")
    tower, field = cell_point((36, 8)), cell_point((65, 19))
    a = len(p.waves)
    p.wave(("soldier", (17, 13)), ("soldier", (17, 22)), ("rusher", (20, 18)))
    p.wave(("soldier", (30, 18)), ("marksman", (46, 17)), ("rusher", (34, 19)))
    p.stage("clear", a, a + 1, opens=tower_door, prep=6.0)
    b = len(p.waves)
    p.wave(("marksman", (28, 4)), ("soldier", (32, 8)), ("soldier", (40, 8)), ("sapper", (36, 4)))
    p.stage("reach", b, zone=tower, radius=TILE_RADIUS * 2)
    c = len(p.waves)
    p.wave(("rusher", (36, 17)), ("soldier", (30, 18)), ("soldier", (42, 18)))
    p.wave(("heavy", (36, 18)), ("sapper", (28, 17)), ("warden", (44, 19)))
    p.stage("hold", c, c + 1, gap=15.0, hold=45.0, zone=tower, radius=TILE_RADIUS * 3, opens=field_door)
    d = len(p.waves)
    p.wave(("sapper", (55, 19)), ("sapper", (58, 12)), ("soldier", (62, 24)), ("soldier", (72, 12)), ("repairer", (74, 24)))
    p.stage("reach", d, zone=field, radius=TILE_RADIUS * 3)
    sweep = len(p.waves)
    p.wave(("heavy", (72, 16)), ("soldier", (72, 24)), ("rusher", (78, 12)), ("marksman", (79, 28)))
    p.stage("clear", sweep)
    e = len(p.waves)
    p.wave(("soldier", (52, 10)), ("soldier", (52, 28)), ("rusher", (78, 19)))
    p.wave(("heavy", (78, 12)), ("warden", (78, 26)), ("sapper", (65, 9)), ("sapper", (65, 29)))
    p.wave(("ironstride", (79, 19)), ("rusher", (52, 19)))
    p.stage("hold", e, e + 2, gap=14.0, hold=40.0, zone=field, radius=TILE_RADIUS * 6, reward=0)
    p.bonus, p.damage_bonus = 320, 80
    p.preview_center, p.preview_hero = (62, 19), ((55, 19), (1, 0))
    p.preview_guards = [("ironstride", (70, 19), (-1, 0)), ("sapper", (63, 15), (-1, 0)), ("warden", (66, 23), (-1, 0))]
    return p


def ally_corridor():
    p = Plan("ally_corridor", 96, 26)
    for x0, x1 in [(2, 24), (26, 48), (50, 72), (74, 92)]:
        p.room(x0, 4, x1, 21)
    for x in [25, 49, 73]:
        p.carve(x, 10, x, 15)
    p.strip(3, 12, 91, 13)
    p.spawn, p.exit = (4, 12), (90, 12)
    p.protected, p.protected_health = 0, 240
    p.ally((6, 12), None)
    p.ally((20, 20), "medic")
    p.ally((44, 5), "rifleman")
    p.reserve = ["gunner"]
    d1 = p.door([(25, y) for y in range(10, 16)])
    d2 = p.door([(49, y) for y in range(10, 16)])
    d3 = p.door([(73, y) for y in range(10, 16)])
    p.crates((12, 8), (12, 17), (32, 8), (32, 17), (40, 10), (40, 15), (56, 8), (56, 17), (66, 10), (66, 15), (80, 8), (80, 17))
    p.supply = [(23, 5), (51, 5)]
    p.barriers = 1
    p.terminals = [(47, 20)]
    z1, z2, z3, z4 = cell_point((22, 12)), cell_point((46, 12)), cell_point((70, 12)), cell_point((88, 12))
    a = len(p.waves)
    p.wave(("soldier", (18, 8)), ("soldier", (18, 17)), ("rusher", (22, 12)))
    p.stage("escort", a, zone=z1, radius=TILE_RADIUS * 2, opens=d1, prep=6.0, clear=True)
    b = len(p.waves)
    p.wave(("marksman", (47, 5)), ("sapper", (34, 6)), ("sapper", (34, 19)), ("soldier", (44, 12)), ("soldier", (42, 18)))
    p.stage("clear", b)
    c = len(p.waves)
    p.wave(("rusher", (28, 5)), ("rusher", (28, 20)), ("soldier", (46, 8)))
    p.stage("escort", c, zone=z2, radius=TILE_RADIUS * 2, clear=True)
    lock = len(p.waves)
    p.wave(("soldier", (28, 12)), ("rusher", (44, 20)), ("sapper", (30, 6)))
    p.stage("interact", lock, terminals=[0], opens=d2)
    d = len(p.waves)
    towers = p.wave(("turret", (68, 7)), ("turret", (68, 18)), ("warden", (64, 12)), ("repairer", (71, 12)), ("soldier", (60, 7)), ("soldier", (60, 18)))[:2]
    p.stage("destroy", d, targets=towers)
    e = len(p.waves)
    p.wave(("heavy", (70, 12)), ("sapper", (55, 6)), ("sapper", (55, 19)), ("rusher", (70, 6)))
    p.stage("escort", e, zone=z3, radius=TILE_RADIUS * 2, opens=d3, clear=True)
    f = len(p.waves)
    p.wave(("ironstride", (88, 12)), ("soldier", (84, 6)), ("soldier", (84, 19)))
    p.wave(("sapper", (90, 6)), ("sapper", (90, 19)), ("warden", (91, 12)))
    p.stage("escort", f, f + 1, gap=22.0, zone=z4, radius=TILE_RADIUS * 2, clear=True, reward=0)
    p.bonus, p.damage_bonus = 360, 80
    p.preview_center, p.preview_hero = (36, 12), ((30, 12), (1, 0))
    p.preview_guards = [("soldier", (38, 8), (-1, 0)), ("sapper", (37, 17), (-1, 0)), ("marksman", (44, 12), (-1, 0))]
    return p


def retreat_vector():
    p = Plan("retreat_vector", 72, 36)
    p.room(2, 12, 20, 24)
    p.room(24, 4, 48, 32)
    p.room(52, 10, 68, 26)
    p.carve(21, 15, 23, 21)
    p.carve(49, 15, 51, 21)
    p.strip(3, 18, 67, 18)
    p.spawn, p.exit = (5, 18), (66, 18)
    west = p.door([(22, y) for y in range(15, 22)])
    east = p.door([(50, y) for y in range(15, 22)])
    p.crates((12, 15), (12, 21), (30, 10), (42, 10), (30, 26), (42, 26), (36, 14), (36, 22), (28, 18), (44, 18), (58, 14), (58, 22))
    p.ally((27, 30), "blade")
    p.terminals = [(26, 12), (46, 24)]
    a = len(p.waves)
    p.wave(("soldier", (17, 14)), ("soldier", (17, 22)), ("rusher", (19, 18)))
    p.stage("clear", a, opens=west, prep=6.0)
    b = len(p.waves)
    pylons = p.wave(("turret", (27, 6)), ("turret", (45, 30)), ("marksman", (47, 6)), ("sapper", (30, 14)), ("soldier", (38, 28)))[:2]
    p.stage("destroy", b, targets=pylons)
    relay = len(p.waves)
    p.wave(("soldier", (40, 6)), ("rusher", (32, 30)), ("warden", (36, 18)))
    p.wave(("sapper", (26, 26)), ("sapper", (46, 10)), ("heavy", (47, 18)))
    p.stage("interact", relay, relay + 1, gap=16.0, terminals=[0, 1])
    c = len(p.waves)
    p.phase_target = p.wave(("rival_0", (36, 18)))[0]
    p.phase_prefix = "rival"
    p.wave(("rusher", (26, 18)), ("soldier", (46, 8)))
    p.wave(("sapper", (46, 28)), ("warden", (26, 8)))
    p.stage("boss", c, c + 2, gap=28.0, opens=east, prep=6.0)
    d = len(p.waves)
    p.wave(("heavy", (64, 14)), ("warden", (66, 18)), ("soldier", (60, 12)), ("soldier", (60, 24)), ("rusher", (55, 18)), ("repairer", (67, 24)))
    p.stage("clear", d)
    h = len(p.waves)
    p.wave(("soldier", (54, 12)), ("soldier", (54, 24)), ("rusher", (46, 18)))
    p.wave(("sapper", (68, 12)), ("sapper", (68, 24)), ("marksman", (53, 11)))
    p.stage("hold", h, h + 1, gap=14.0, hold=30.0, zone=cell_point((64, 18)), radius=TILE_RADIUS * 3, reward=0, prep=5.0)
    p.bonus, p.damage_bonus = 300, 80
    p.preview_center, p.preview_hero = (36, 18), ((29, 18), (1, 0))
    p.preview_guards = [("marksman", (39, 18), (-1, 0)), ("rusher", (36, 14), (-1, 0)), ("sapper", (37, 22), (-1, 0))]
    return p


def siege_core():
    p = Plan("siege_core", 104, 44)
    p.room(2, 16, 22, 30)
    p.room(24, 18, 46, 28)
    p.room(48, 6, 72, 38)
    p.room(76, 6, 100, 38)
    p.carve(23, 20, 23, 26)
    p.carve(47, 20, 47, 26)
    p.carve(73, 19, 75, 27)
    p.strip(3, 22, 99, 23)
    p.spawn, p.exit = (5, 22), (96, 22)
    gate = p.door([(23, y) for y in range(20, 27)])
    bridge = p.door([(47, y) for y in range(20, 27)])
    core = p.door([(74, y) for y in range(19, 28)])
    p.crates((12, 19), (12, 27), (18, 23), (30, 20), (30, 26), (40, 20), (40, 26), (54, 12), (66, 12), (54, 32), (66, 32), (56, 22), (64, 22), (82, 12), (94, 12), (82, 32), (94, 32), (88, 16), (88, 28))
    p.supply = [(20, 18), (50, 22), (77, 9)]
    p.barriers = 2
    p.start_supplies = 4
    p.terminals = [(60, 8), (60, 36)]
    p.ally((10, 28), "blade")
    p.ally((70, 9), "medic")
    p.reserve = ["rifleman", "gunner", "sharpshooter"]
    reactor = cell_point((60, 22))
    a = len(p.waves)
    p.wave(("soldier", (18, 18)), ("soldier", (18, 28)), ("rusher", (21, 23)))
    p.wave(("marksman", (22, 17)), ("heavy", (20, 23)), ("sapper", (20, 29)))
    p.stage("clear", a, a + 1, opens=gate, prep=7.0)
    b = len(p.waves)
    towers = p.wave(("turret", (43, 19)), ("turret", (43, 27)), ("turret", (45, 23)), ("sapper", (32, 19)), ("sapper", (32, 27)), ("soldier", (38, 23)))[:3]
    p.stage("destroy", b, targets=towers)
    c = len(p.waves)
    p.wave(("ironstride", (44, 23)), ("warden", (42, 19)), ("soldier", (42, 27)))
    p.stage("clear", c, opens=bridge, prep=6.0)
    d = len(p.waves)
    p.wave(("soldier", (56, 8)), ("soldier", (64, 8)), ("marksman", (71, 7)), ("repairer", (52, 10)))
    p.wave(("soldier", (56, 36)), ("heavy", (64, 36)), ("marksman", (71, 37)), ("sapper", (52, 34)))
    p.stage("interact", d, d + 1, gap=25.0, terminals=[0, 1], reward=3)
    e = len(p.waves)
    p.wave(("rusher", (50, 8)), ("rusher", (50, 36)), ("soldier", (70, 22)), ("warden", (70, 10)))
    p.wave(("sapper", (60, 7)), ("sapper", (60, 37)), ("heavy", (70, 36)), ("repairer", (70, 8)))
    p.stage("hold", e, e + 1, gap=14.0, hold=40.0, zone=reactor, radius=TILE_RADIUS * 3, opens=core, reward=3)
    f = len(p.waves)
    p.phase_target = p.wave(("boss_0", (90, 22)))[0]
    p.phase_prefix = "boss"
    p.wave(("sapper", (80, 8)), ("sapper", (80, 36)), ("soldier", (98, 8)))
    p.wave(("warden", (98, 36)), ("rusher", (78, 22)), ("soldier", (98, 22)))
    p.stage("boss", f, f + 2, gap=30.0, prep=8.0, repair=40.0, reward=4)
    g = len(p.waves)
    p.wave(("ironstride", (92, 22)), ("rusher", (80, 10)), ("rusher", (80, 34)), ("repairer", (99, 10)))
    p.stage("clear", g, reward=0, prep=6.0)
    p.bonus, p.damage_bonus = 600, 120
    p.accuracy_bonus = 0.4
    p.preview_center, p.preview_hero = (86, 22), ((79, 22), (1, 0))
    p.preview_guards = [("boss", (92, 22), (-1, 0)), ("sapper", (85, 17), (-1, 0)), ("warden", (86, 27), (-1, 0))]
    return p


def validate(p):
    start = p.spawn
    seen = {start}
    queue = deque([start])
    doors = {cell for cell, door in p.covers if door}
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cell = (x + dx, y + dy)
            if 0 <= cell[0] < p.width and 0 <= cell[1] < p.height and cell not in seen and (p.grid[cell[1]][cell[0]] != "#"):
                if p.grid[cell[1]][cell[0]] == "C" and cell not in doors:
                    continue
                seen.add(cell)
                queue.append(cell)
    needed = [p.exit] + [cell for _, cell in p.placements] + list(p.terminals) + list(p.prisoners) + list(p.supply)
    for cell in needed:
        assert cell in seen, f"{p.id}: unreachable {cell}"
    for name, cell in p.placements:
        assert p.grid[cell[1]][cell[0]] in ".=", f"{p.id}: {name} on {p.grid[cell[1]][cell[0]]} at {cell}"
    for wave in p.waves:
        assert len(wave) <= 24
    combatants = len(p.prisoners) + len(p.reserve) - (1 if p.protected is not None else 0)
    assert combatants <= 6, f"{p.id}: {combatants} allies"


def resource(path, kind, body, externals=""):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f'[gd_resource type="Resource" script_class="{kind}" format=3]\n\n{externals}\n{body}', encoding="utf-8", newline="\n")


def enemies():
    folder = ROOT / "data/blaster_ops/enemies"
    for name in ["turret", "rival_0", "rival_1", "rival_2", "boss_0", "boss_1", "boss_2"]:
        boss = name.startswith("boss")
        phase = int(name[-1]) if name[-1].isdigit() else 0
        health = 420 if boss else 300 if name.startswith("rival") else 40
        fields = f'id = &"{name}"\nhealth = {health}.0\nspeed = {0 if name == "turret" else 160 if phase == 2 else 80}.0\nvision_range = 850.0\nvision_degrees = 360.0\npreferred_range = {36 if phase == 2 else 300}.0\ncan_raise_alarm = false\nprefers_prisoners = true\ntakedown_immune = true\ntelegraph_seconds = {0.5 if phase == 2 else 0.65}\nfire_interval = 1.8\nsprite = {3 if name.startswith("rival") else 1}\n'
        if boss or name.startswith("rival"):
            fields += f"supply_value = {6 if boss else 4}\n"
        if name != "turret" and phase != 2:
            damage = 12 if boss else 8
            fields += f'melee_damage = {damage}.0\nmelee_guard_vigor = 16.0\nmelee_range = {72 if boss else 56}.0\nmelee_interval = 1.4\nmelee_flinch = 0.08\n'
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


def vec_list(cells):
    return ", ".join(str(v) for cell in cells for v in cell_point(cell))


def write_preview(p):
    overrides = {name: Image.open(ROOT / path).convert("RGBA") for name, path in SPRITES.items()}
    p.preview_guards = [(("boss" if kind == "boss" else PREVIEW_KIND[kind]), cell, facing) for kind, cell, facing in p.preview_guards]
    preview = ROOT / f"assets/blaster_ops/previews/{p.id}.png"
    preview.parent.mkdir(parents=True, exist_ok=True)
    prisoners, p.prisoners = p.prisoners, [cell for cell in p.prisoners]
    preview_image(p, overrides).save(preview, optimize=True)
    p.prisoners = prisoners


def write_mission(p):
    validate(p)
    assert p.tutorial or all("action" not in stage for stage in p.stages), f"{p.id}: action stages are tutorial only"
    write_preview(p)
    paths = {"mission": ("Script", "data/blaster_ops/blaster_ops_mission_data.gd"), "map": ("Script", "data/blaster_ops/blaster_ops_arena_data.gd"), "wave": ("Script", "data/blaster_ops/blaster_ops_wave_data.gd"), "phase": ("Script", "data/blaster_ops/blaster_ops_phase_data.gd"), "stage": ("Script", "data/blaster_ops/blaster_ops_stage_data.gd"), "ally": ("Script", "data/blaster_ops/blaster_ops_ally_data.gd"), "placement": ("Script", "data/infiltration/infiltration_enemy_placement.gd"), "cover": ("Script", "data/blaster_ops/blaster_ops_cover_data.gd"), "tiles": ("Texture2D", "assets/infiltration/training_tiles.png"), "sprites": ("Texture2D", "assets/infiltration/training_sprites.png"), "enemies": ("Texture2D", "assets/infiltration/enemy_sprites.png"), "covers": ("Texture2D", "assets/blaster_ops/covers.png"), "preview": ("Texture2D", f"assets/blaster_ops/previews/{p.id}.png")}
    if p.panels:
        paths["panel"] = ("Script", "data/infiltration/infiltration_panel_data.gd")
    names = {name for name, _ in p.placements}
    if p.phase_prefix:
        names |= {f"{p.phase_prefix}_{i}" for i in range(3)}
    for name in names:
        paths[name] = ("Resource", f"data/blaster_ops/enemies/{name}.tres")
    roles = list(p.roles) + list(p.reserve)
    for role in {r for r in roles if r}:
        paths["role_" + role] = ("Resource", f"data/blaster_ops/allies/{role}.tres")
    ext = "".join(f'[ext_resource type="{kind}" path="res://{path}" id="{name}"]\n' for name, (kind, path) in sorted(paths.items()))
    body = ""
    placements = []
    for index, (name, cell) in enumerate(p.placements):
        placements.append(f'SubResource("p{index}")')
        facing = p.guards.get(index)
        body += f'\n[sub_resource type="Resource" id="p{index}"]\nscript = ExtResource("placement")\nenemy = ExtResource("{name}")\nposition = Vector2{cell_point(cell)}\n'
        body += f'direction = Vector2{facing}\nreinforcement = false\n' if facing else 'direction = Vector2(-1, 0)\nreinforcement = true\n'
    wave_ids = []
    for index, wave in enumerate(p.waves):
        wave_ids.append(f'SubResource("w{index}")')
        body += f'\n[sub_resource type="Resource" id="w{index}"]\nscript = ExtResource("wave")\nindices = PackedInt32Array({", ".join(map(str, wave))})\nfinal_wave = {str(index == len(p.waves) - 1).lower()}\n'
    for index, (cell, door) in enumerate(p.covers):
        body += f'\n[sub_resource type="Resource" id="c{index}"]\nscript = ExtResource("cover")\ncell = Vector2i{cell}\nhealth = {"1.0" if door else "30.0"}\ndoor = {str(door).lower()}\n'
    stage_ids = []
    for index, stage in enumerate(p.stages):
        stage_ids.append(f'SubResource("s{index}")')
        action_fields = ""
        if "action" in stage:
            hints = ", ".join(f'"{hint}"' for hint in stage["hints"])
            action_fields = f'action = {stage["action"]}\naction_count = {stage["count"]}\nhint_actions = PackedStringArray({hints})\n'
        zone = f'zone = Vector2{stage["zone"]}\n' if stage["zone"] else ""
        body += f'\n[sub_resource type="Resource" id="s{index}"]\nscript = ExtResource("stage")\nobjective = {stage["objective"]}\ntitle_key = "OPS_ST_{p.id.upper()}_{index + 1}"\nfirst_wave = {stage["first"]}\nlast_wave = {stage["last"]}\nwave_gap_seconds = {stage["gap"]}\ntargets = PackedInt32Array({", ".join(map(str, stage["targets"]))})\nterminals = PackedInt32Array({", ".join(map(str, stage["terminals"]))})\nopens_covers = PackedInt32Array({", ".join(map(str, stage["opens"]))})\nhold_seconds = {stage["hold"]}\n{zone}zone_radius = {float(stage["radius"])}\nprep_seconds = {stage["prep"]}\nsupply_reward = {stage["reward"]}\nrepair_on_complete = {stage["repair"]}\nrequires_clear = {str(stage["clear"]).lower()}\n{action_fields}'
    phases = []
    if p.phase_prefix:
        for index, ratio in enumerate([1.0, 0.65, 0.3]):
            phases.append(f'SubResource("f{index}")')
            body += f'\n[sub_resource type="Resource" id="f{index}"]\nscript = ExtResource("phase")\nhealth_ratio = {ratio}\ntitle_key = "OPS_PHASE_{index}"\nenemy = ExtResource("{p.phase_prefix}_{index}")\nstrafe = {0.5 if p.phase_prefix == "rival" and index < 2 else 0.0}\n'
    panel_ids = []
    for index, cell in enumerate(p.panels):
        panel_ids.append(f'SubResource("n{index}")')
        body += f'\n[sub_resource type="Resource" id="n{index}"]\nscript = ExtResource("panel")\nposition = Vector2{cell_point(cell)}\n'
    rows = ", ".join('"' + "".join(row) + '"' for row in p.grid)
    covers = ", ".join(f'SubResource("c{i}")' for i in range(len(p.covers)))
    body += '\n[sub_resource type="Resource" id="map_data"]\nscript = ExtResource("map")\n'
    body += f'rows = PackedStringArray({rows})\nplayer_spawn = Vector2{cell_point(p.spawn)}\nenemies = Array[ExtResource("placement")]([{", ".join(placements)}])\ncovers = Array[ExtResource("cover")]([{covers}])\n'
    if panel_ids:
        body += f'panels = Array[ExtResource("panel")]([{", ".join(panel_ids)}])\n'
    body += 'tiles = ExtResource("tiles")\nsprites = ExtResource("sprites")\nenemy_sprites = ExtResource("enemies")\ncover_atlas = ExtResource("covers")\nenemies_alerted = false\n'
    body += f'\n[resource]\nscript = ExtResource("mission")\nid = &"{p.id}"\nobjective = {p.objective_value}\nkind = {p.kind}\ntitle_key = "OPS_{p.id.upper()}"\nbriefing_key = "OPS_{p.id.upper()}_BRIEF"\nmap = SubResource("map_data")\npreview = ExtResource("preview")\nwaves = Array[ExtResource("wave")]([{", ".join(wave_ids)}])\nstages = Array[ExtResource("stage")]([{", ".join(stage_ids)}])\n'
    spawns = list(p.prisoners) + [p.spawn for _ in p.reserve]
    body += f'prisoner_spawns = PackedVector2Array({vec_list(spawns)})\nminimum_prisoners = {1 if p.protected is not None else 0}\nextraction = Vector2{cell_point(p.exit)}\nbonus_seconds = {float(p.bonus)}\ndamage_bonus = {float(p.damage_bonus)}\naccuracy_bonus = {p.accuracy_bonus}\nenemy_damage_scale = 0.6\n'
    role_items = ", ".join(f'ExtResource("role_{r}")' if r else "null" for r in roles)
    body += f'ally_roles = Array[ExtResource("ally")]([{role_items}])\n'
    if p.reserve:
        body += f"reserve_start = {len(p.prisoners)}\n"
    if p.terminals:
        body += f"terminals = PackedVector2Array({vec_list(p.terminals)})\n"
    if p.supply:
        body += f"supply_terminals = PackedVector2Array({vec_list(p.supply)})\nstarting_supplies = {p.start_supplies}\nsupply_per_wave = 0\n"
    if p.barriers:
        body += f"barrier_charges = {p.barriers}\n"
    if p.prep_only:
        body += "barrier_prep_only = true\n"
    if p.protected is not None:
        body += f"protected_index = {p.protected}\nprotected_health = {float(p.protected_health)}\n"
    if phases:
        body += f'phase_target = {p.phase_target}\nphases = Array[ExtResource("phase")]([{", ".join(phases)}])\n'
    if p.tutorial:
        body += "tutorial = true\n"
    if p.forced_weapon:
        body += f'forced_weapon = &"{p.forced_weapon}"\n'
    if p.damage_scale != 1.0:
        body += f"enemy_damage_scale = {p.damage_scale}\n"
    resource(ROOT / f"data/blaster_ops/missions/{p.id}.tres", "BlasterOpsMissionData", body, ext)


def training_infiltration():
    p = Plan("training_infiltration", 46, 20)
    p.tutorial = True
    p.objective_value = 0
    p.room(2, 5, 16, 14)
    p.room(18, 5, 30, 14)
    p.room(32, 5, 43, 14)
    p.carve(17, 9, 17, 11)
    p.carve(31, 9, 31, 11)
    p.spawn, p.exit = (4, 10), (41, 12)
    d1 = p.door([(17, y) for y in range(9, 12)])
    d2 = p.door([(31, y) for y in range(9, 12)])
    p.panels = [(14, 6)]
    guard = p.guard("soldier", (27, 10), (1, 0))
    p.ally((38, 8), None)
    p.action("move", 90, ["up", "left", "down", "right"], prep=1.0)
    p.action("run", 60, ["run"])
    p.action("sneak", 60, ["sneak"])
    p.action("panel", 1, ["interact"], opens=d1)
    p.action("takedown", 1, ["sneak", "strike"], targets=[guard], opens=d2)
    p.action("recruit", 1, ["interact"])
    p.bonus = 300
    p.preview_center, p.preview_hero = (18, 10), ((14, 10), (1, 0))
    p.preview_guards = [("soldier", (27, 10), (1, 0))]
    return p


def training_incursion():
    p = Plan("training_incursion", 50, 22)
    p.tutorial = True
    p.forced_weapon = "back_rifle"
    p.damage_scale = 0.35
    p.room(2, 4, 24, 18)
    p.room(26, 4, 46, 18)
    p.carve(25, 9, 25, 13)
    p.spawn, p.exit = (5, 11), (44, 11)
    p.crates((14, 6), (14, 16))
    door = p.door([(25, y) for y in range(9, 14)])
    p.supply = [(8, 5)]
    p.start_supplies = 20
    p.barriers = 2
    p.ally((12, 16), "rifleman")
    turret = p.wave(("turret", (22, 11)))
    soldiers = p.wave(("soldier", (38, 8)), ("soldier", (40, 11)), ("soldier", (38, 14)))
    p.action("move", 60, ["up", "left", "down", "right"], prep=1.0)
    p.action("fire", 6, ["fire"])
    p.action("switch", 1, ["switch_weapon"])
    p.action("cut", 2, ["strike"])
    p.action("guard", 60, ["guard"])
    p.action("dodge", 1, ["dodge"])
    p.action("parry", 2, ["guard"], targets=turret, first=0)
    p.stage("destroy", targets=turret, prep=0.5, reward=0, repair=30.0)
    p.action("power", 1, ["power"])
    p.action("deploy", 1, ["interact"])
    p.action("recruit", 1, ["interact"])
    p.action("order", 1, ["order_allies"])
    p.action("buy", 1, ["interact"], opens=door)
    p.stage("clear", first=1, prep=1.0, reward=0, repair=30.0)
    p.preview_center, p.preview_hero = (20, 11), ((14, 11), (1, 0))
    p.preview_guards = [("turret", (22, 11), (-1, 0))]
    return p


REINFORCEMENTS = {
    "encircled_yard": [(3, "crusher")],
    "breach_line": [(1, "rusher"), (3, "crusher"), (-2, "crusher"), (-1, "duelist")],
    "defense_node": [(0, "rusher"), (1, "crusher"), (-1, "crusher"), (-1, "rusher")],
    "extraction_window": [(1, "crusher"), (2, "rusher")],
    "ally_corridor": [(1, "crusher"), (3, "rusher"), (-1, "duelist")],
    "retreat_vector": [(3, "crusher")],
    "siege_core": [(1, "crusher"), (3, "duelist")],
}


def reinforce(p):
    used = {cell for _, cell in p.placements}
    for wave_index, name in REINFORCEMENTS.get(p.id, []):
        wave = p.waves[wave_index]
        origin = p.placements[wave[0]][1]
        cell = next(c for c in ((origin[0] + dx, origin[1] + dy) for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2), (2, 2), (-2, -2), (2, -2), (-2, 2), (3, 0), (-3, 0), (0, 3), (0, -3))) if 0 <= c[1] < p.height and 0 <= c[0] < p.width and p.grid[c[1]][c[0]] in ".=" and c not in used)
        used.add(cell)
        wave.append(len(p.placements))
        p.placements.append((name, cell))


TUTORIALS = [training_infiltration, training_incursion]
MISSIONS = [encircled_yard, breach_line, defense_node, extraction_window, ally_corridor, retreat_vector, siege_core]

if __name__ == "__main__":
    enemies()
    for build in MISSIONS:
        plan = build()
        reinforce(plan)
        write_mission(plan)
    for build in TUTORIALS:
        write_mission(build())
