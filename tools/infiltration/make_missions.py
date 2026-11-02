from collections import deque
from pathlib import Path
import math
import re
import sys

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
TILE_UNITS = 64
TILE_PIXELS = 32
WALK_SPEED = 240.0
PREVIEW_SIZE = (480, 170)
SPRITE = (24, 28)
ENEMY_SPRITE = {"trooper": 0, "sentry": 1, "heavy": 2, "marksman": 3, "drone": 4, "shield": 5}
BOLTS = {
    "trooper_bolt": dict(damage="7.0", guard_vigor="11.0"),
    "heavy_burst": dict(damage="6.0", guard_vigor="9.0", count="3"),
    "marksman_bolt": dict(damage="18.0", guard_vigor="26.0", speed="1500.0", max_range="1500.0", flinch="0.25"),
    "walker_cannon": dict(damage="12.0", guard_vigor="18.0", speed="760.0", max_range="1300.0", size="9.0", flinch="0.2", count="2", interval="0.18"),
}
ENEMIES = {
    "patrol_trooper": dict(id='&"patrol_trooper"', health="20.0", bolt="trooper_bolt", fire_interval="1.2"),
    "sentry": dict(id='&"sentry"', archetype="1", speed="0.0", vision_range="440.0", vision_degrees="100.0", sprite="1", health="16.0", bolt="trooper_bolt", fire_interval="1.0"),
    "heavy": dict(id='&"heavy"', archetype="2", speed="75.0", vision_range="360.0", vision_degrees="75.0", sprite="2", health="36.0", bolt="heavy_burst", fire_interval="1.6"),
    "marksman": dict(id='&"marksman"', archetype="3", speed="0.0", vision_range="680.0", vision_degrees="46.0", rotation_degrees="22.0", sprite="3", health="14.0", bolt="marksman_bolt", fire_interval="2.4", prefers_prisoners="true", aim_line="true", can_raise_alarm="false"),
    "drone": dict(id='&"drone"', archetype="4", speed="170.0", alarm_speed_ratio="1.0", vision_range="320.0", vision_degrees="150.0", preferred_range="24.0", sprite="4", health="12.0", prefers_prisoners="true", can_raise_alarm="false", melee_damage="8.0", melee_guard_vigor="14.0", melee_range="34.0", melee_interval="0.7", melee_flinch="0.15"),
    "shield": dict(id='&"shield"', archetype="5", speed="90.0", vision_range="360.0", vision_degrees="90.0", preferred_range="160.0", sprite="5", health="30.0", bolt="trooper_bolt", fire_interval="2.0", turn_degrees="120.0", front_damage_ratio="0.0", front_degrees="110.0", can_raise_alarm="false"),
    "walker": dict(id='&"walker"', archetype="6", speed="60.0", vision_range="520.0", vision_degrees="80.0", preferred_range="320.0", health="160.0", bolt="walker_cannon", fire_interval="2.6", turn_degrees="60.0", body_radius="30.0", front_damage_ratio="0.25", front_degrees="150.0", takedown_immune="true", can_raise_alarm="false", texture="walker"),
}
PREVIEW_CONE_REACH = 110
PREVIEW_CONE_DEGREES = 80


def cell_point(cell):
    return (cell[0] * TILE_UNITS + TILE_UNITS // 2, cell[1] * TILE_UNITS + TILE_UNITS // 2)


def vector(cell):
    x, y = cell_point(cell)
    return f"Vector2({x}, {y})"


def packed(cells):
    return "PackedVector2Array(" + ", ".join(str(value) for cell in cells for value in cell_point(cell)) + ")"


class Layout:
    def __init__(self, identifier, title_key, width, height):
        self.id = identifier
        self.title_key = title_key
        self.width = width
        self.height = height
        self.grid = [["#"] * width for _ in range(height)]
        self.enemies = []
        self.panels = []
        self.terminals = []
        self.prisoners = []
        self.spawn = (0, 0)
        self.exit = (0, 0)
        self.bonus = 0
        self.disable_alarms = False
        self.panels_unlock_prisoners = False
        self.route_order = []
        self.minimum_seconds = 0
        self.preview_center = (0, 0)
        self.preview_hero = ((0, 0), (1, 0))
        self.preview_guards = []
        self.minimum_prisoners = 0

    def carve(self, x0, y0, x1, y1, tile="."):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.grid[y][x] = tile

    def crates(self, x0, y0, x1, y1):
        self.carve(x0, y0, x1, y1, "C")

    def strip(self, x0, y0, x1, y1):
        self.carve(x0, y0, x1, y1, "=")

    def sentry(self, cell, direction=(-1, 0), kind="sentry"):
        self.enemies.append((kind, cell, direction, [], False))

    def patrol(self, kind, corners):
        first, second = corners[0], corners[1]
        direction = (max(-1, min(1, second[0] - first[0])), max(-1, min(1, second[1] - first[1])))
        self.enemies.append((kind, first, direction, list(corners), False))

    def reserve(self, cell, direction=(0, 1)):
        self.enemies.append(("heavy", cell, direction, [], True))

    def is_free(self, cell):
        x, y = cell
        return 0 <= y < self.height and 0 <= x < self.width and self.grid[y][x] not in "#C"

    def path_tiles(self, start, goal):
        queue = deque([start])
        seen = {start: 0}
        while queue:
            cell = queue.popleft()
            if cell == goal:
                return seen[cell]
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                next_cell = (cell[0] + dx, cell[1] + dy)
                if self.is_free(next_cell) and next_cell not in seen:
                    seen[next_cell] = seen[cell] + 1
                    queue.append(next_cell)
        raise ValueError(f"{self.id}: {goal} unreachable from {start}")

    def route_seconds(self):
        points = [self.spawn] + self.route_order + [self.exit]
        tiles = sum(self.path_tiles(points[i], points[i + 1]) for i in range(len(points) - 1))
        return tiles, tiles * TILE_UNITS / WALK_SPEED

    def validate(self):
        points = [self.spawn, self.exit] + self.panels + self.terminals + self.prisoners
        for kind, cell, direction, route, reserve in self.enemies:
            points.append(cell)
            points.extend(route)
        for point in points:
            assert self.is_free(point), f"{self.id}: {point} is solid"
            self.path_tiles(self.spawn, point)
        tiles, seconds = self.route_seconds()
        assert seconds >= self.minimum_seconds, f"{self.id}: route {seconds:.0f}s below {self.minimum_seconds}s"

    def rows(self):
        return ["".join(row) for row in self.grid]


def first_access():
    m = Layout("first_access", "INF_FIRST", 66, 36)
    m.carve(2, 2, 20, 15)
    m.carve(24, 2, 40, 15)
    m.carve(44, 2, 63, 15)
    m.strip(21, 8, 23, 10)
    m.strip(41, 8, 43, 10)
    m.strip(57, 16, 60, 19)
    m.carve(44, 20, 63, 33)
    m.carve(24, 20, 40, 33)
    m.carve(2, 20, 20, 33)
    m.strip(41, 26, 43, 28)
    m.strip(21, 26, 23, 28)
    m.crates(30, 6, 34, 7)
    m.crates(30, 11, 34, 12)
    m.crates(50, 6, 51, 11)
    m.crates(56, 25, 57, 30)
    m.crates(30, 24, 31, 29)
    m.crates(8, 24, 13, 25)
    m.sentry((32, 9), (1, 0))
    m.patrol("trooper", [(46, 4), (61, 4), (61, 13), (46, 13)])
    m.sentry((47, 31), (0, -1))
    m.patrol("trooper", [(26, 22), (38, 22), (38, 31), (26, 31)])
    m.patrol("drone", [(4, 22), (18, 22), (18, 31), (4, 31)])
    m.reserve((61, 31), (-1, 0))
    m.spawn = (5, 6)
    m.panels = [(46, 22)]
    m.prisoners = [(61, 22)]
    m.exit = (5, 30)
    m.bonus = 180
    m.route_order = [(61, 22)]
    m.minimum_seconds = 36
    m.preview_center = (55, 23)
    m.preview_hero = ((50, 24), (1, -0.3))
    m.preview_guards = [("trooper", (60, 24), (-1, 0))]
    return m


def silent_network():
    m = Layout("silent_network", "INF_NETWORK", 84, 56)
    m.carve(2, 2, 24, 16)
    m.carve(29, 2, 53, 16)
    m.carve(58, 2, 81, 16)
    m.strip(25, 8, 28, 10)
    m.strip(54, 8, 57, 10)
    m.strip(72, 17, 75, 21)
    m.carve(58, 22, 81, 34)
    m.carve(29, 22, 53, 34)
    m.carve(2, 22, 24, 34)
    m.strip(54, 27, 57, 29)
    m.strip(25, 27, 28, 29)
    m.strip(8, 35, 11, 39)
    m.carve(2, 40, 24, 53)
    m.carve(29, 40, 53, 53)
    m.carve(58, 40, 81, 53)
    m.strip(25, 46, 28, 48)
    m.strip(54, 46, 57, 48)
    m.strip(40, 17, 43, 21)
    m.crates(38, 6, 43, 7)
    m.crates(38, 11, 43, 12)
    m.crates(66, 6, 67, 12)
    m.crates(64, 26, 75, 27)
    m.crates(38, 26, 39, 31)
    m.crates(44, 26, 45, 31)
    m.crates(12, 27, 17, 28)
    m.crates(36, 44, 37, 50)
    m.crates(44, 44, 45, 50)
    m.crates(66, 44, 67, 50)
    m.sentry((41, 9), (1, 0))
    m.patrol("trooper", [(31, 4), (51, 4), (51, 14), (31, 14)])
    m.patrol("trooper", [(60, 4), (79, 4), (79, 14), (60, 14)])
    m.sentry((70, 24), (0, 1))
    m.patrol("trooper", [(60, 30), (79, 30), (79, 33), (60, 33)])
    m.patrol("shield", [(31, 24), (51, 24), (51, 32), (31, 32)])
    m.sentry((6, 31), (1, 0), "marksman")
    m.patrol("trooper", [(4, 24), (22, 24), (22, 32), (4, 32)])
    m.sentry((41, 47), (1, 0))
    m.patrol("drone", [(31, 42), (51, 42), (51, 51), (31, 51)])
    m.patrol("heavy", [(60, 42), (79, 42), (79, 51), (60, 51)])
    m.reserve((22, 42))
    m.reserve((79, 24), (-1, 0))
    m.spawn = (5, 6)
    m.panels = [(78, 7), (4, 25), (78, 48)]
    m.exit = (5, 50)
    m.prisoners = [(41, 44), (60, 44)]
    m.minimum_prisoners = 1
    m.disable_alarms = True
    m.panels_unlock_prisoners = True
    m.bonus = 360
    m.route_order = [(78, 7), (4, 25), (78, 48), (41, 44), (60, 44)]
    m.minimum_seconds = 90
    m.preview_center = (41, 45)
    m.preview_hero = ((34, 43), (1, 0.2))
    m.preview_guards = [("sentry", (41, 47), (0, -1))]
    return m


def cold_archive():
    m = Layout("cold_archive", "INF_ARCHIVE", 84, 56)
    m.carve(2, 2, 17, 53)
    m.carve(22, 2, 37, 53)
    m.carve(42, 2, 57, 53)
    m.carve(62, 2, 81, 53)
    m.strip(18, 48, 21, 51)
    m.strip(38, 4, 41, 7)
    m.strip(58, 48, 61, 51)
    for x in (6, 12):
        for y0 in (6, 18, 30, 42):
            m.crates(x, y0, x, y0 + 7)
    for x in (26, 32):
        for y0 in (10, 24, 38):
            m.crates(x, y0, x, y0 + 8)
    for x in (46, 52):
        for y0 in (6, 18, 30, 42):
            m.crates(x, y0, x, y0 + 7)
    for y in (10, 22, 34, 44):
        m.crates(68, y, 75, y)
    m.sentry((9, 22), (0, 1))
    m.patrol("trooper", [(4, 4), (15, 4), (15, 51), (4, 51)])
    m.sentry((29, 16), (1, 0), "marksman")
    m.patrol("trooper", [(24, 4), (35, 4), (35, 51), (24, 51)])
    m.patrol("drone", [(29, 4), (29, 8), (24, 8), (24, 4)])
    m.sentry((49, 26), (0, -1))
    m.patrol("shield", [(44, 4), (55, 4), (55, 51), (44, 51)])
    m.sentry((49, 50), (0, -1))
    m.patrol("trooper", [(64, 4), (79, 4), (79, 51), (64, 51)])
    m.sentry((72, 16), (-1, 0))
    m.patrol("heavy", [(64, 28), (79, 28), (79, 40), (64, 40)])
    m.sentry((72, 48), (1, 0), "marksman")
    m.reserve((35, 49))
    m.reserve((79, 6), (-1, 0))
    m.spawn = (4, 5)
    m.panels = [(55, 28), (9, 40)]
    m.terminals = [(29, 50), (78, 6)]
    m.prisoners = [(72, 40), (64, 20)]
    m.minimum_prisoners = 1
    m.exit = (64, 51)
    m.bonus = 390
    m.route_order = [(29, 50), (78, 6), (72, 40), (64, 20)]
    m.minimum_seconds = 75
    m.preview_center = (72, 39)
    m.preview_hero = ((66, 39), (1, 0))
    m.preview_guards = [("heavy", (77, 38), (-1, 0.2))]
    return m


def way_back():
    m = Layout("way_back", "INF_RESCUE", 84, 56)
    m.carve(2, 2, 24, 14)
    m.carve(29, 2, 53, 14)
    m.carve(58, 2, 81, 14)
    m.strip(25, 7, 28, 9)
    m.strip(54, 7, 57, 9)
    m.strip(74, 15, 77, 20)
    m.carve(58, 21, 81, 34)
    m.carve(29, 21, 53, 34)
    m.carve(2, 21, 24, 34)
    m.strip(54, 27, 57, 29)
    m.strip(25, 27, 28, 29)
    m.strip(5, 35, 8, 40)
    m.carve(2, 41, 40, 53)
    m.carve(45, 41, 81, 53)
    m.strip(41, 46, 44, 48)
    m.crates(38, 5, 39, 11)
    m.crates(44, 5, 45, 11)
    m.crates(64, 5, 69, 6)
    m.crates(64, 10, 69, 11)
    m.crates(66, 25, 72, 26)
    m.crates(66, 30, 72, 31)
    m.crates(40, 25, 42, 30)
    m.crates(12, 25, 17, 26)
    m.crates(12, 30, 17, 31)
    for x in (14, 24, 34):
        m.crates(x, 45, x, 49)
    for x in (54, 64, 74):
        m.crates(x, 43, x, 45)
        m.crates(x, 49, x, 51)
    m.sentry((41, 8), (1, 0))
    m.patrol("trooper", [(31, 4), (51, 4), (51, 12), (31, 12)])
    m.patrol("trooper", [(60, 3), (79, 3), (79, 13), (60, 13)])
    m.sentry((69, 28), (-1, 0))
    m.patrol("trooper", [(60, 23), (79, 23), (79, 33), (60, 33)])
    m.patrol("shield", [(31, 23), (51, 23), (51, 32), (31, 32)])
    m.sentry((35, 28), (1, 0))
    m.patrol("trooper", [(4, 23), (22, 23), (22, 32), (4, 32)])
    m.sentry((19, 47), (1, 0))
    m.patrol("drone", [(4, 43), (38, 43), (38, 51), (4, 51)])
    m.patrol("walker", [(47, 47), (71, 47)])
    m.sentry((62, 52), (0, -1), "marksman")
    m.reserve((22, 3), (0, 1))
    m.reserve((48, 52), (0, -1))
    m.spawn = (5, 5)
    m.panels = [(51, 23), (22, 51)]
    m.prisoners = [(79, 47), (20, 33)]
    m.minimum_prisoners = 1
    m.exit = (22, 5)
    m.bonus = 480
    m.route_order = [(79, 47), (20, 33)]
    m.minimum_seconds = 120
    m.preview_center = (73, 47)
    m.preview_hero = ((67, 47), (1, 0))
    m.preview_guards = [("sentry", (72, 47), (-1, 0)), ("trooper", (76, 45), (1, 0.6))]
    return m


def cell_block():
    m = Layout("cell_block", "INF_CELLS", 84, 56)
    m.carve(2, 26, 81, 29)
    for x in (13, 33, 53, 73):
        m.carve(x - 7, 6, x + 7, 22)
        m.carve(x - 7, 33, x + 7, 52)
        m.strip(x - 1, 23, x + 1, 25)
        m.strip(x - 1, 30, x + 1, 32)
        m.crates(x - 4, 13, x + 4, 13)
        m.crates(x - 4, 42, x + 4, 42)
    m.crates(23, 26, 23, 27)
    m.crates(43, 28, 43, 29)
    m.crates(63, 26, 63, 27)
    m.patrol("shield", [(4, 26), (79, 26), (79, 29), (4, 29)])
    m.sentry((13, 17), (0, 1))
    m.patrol("trooper", [(28, 8), (38, 8), (38, 20), (28, 20)])
    m.sentry((53, 17), (1, 0), "marksman")
    m.patrol("trooper", [(48, 8), (58, 8), (58, 20), (48, 20)])
    m.patrol("walker", [(68, 8), (78, 8), (78, 20), (68, 20)])
    m.patrol("drone", [(8, 35), (18, 35), (18, 40), (8, 40)])
    m.sentry((33, 38), (0, -1))
    m.patrol("trooper", [(28, 35), (38, 35), (38, 40), (28, 40)])
    m.patrol("trooper", [(48, 35), (58, 35), (58, 50), (48, 50)])
    m.sentry((73, 38), (0, 1))
    m.patrol("trooper", [(68, 35), (78, 35), (78, 50), (68, 50)])
    m.reserve((27, 21), (0, 1))
    m.reserve((67, 34), (0, 1))
    m.spawn = (4, 27)
    m.panels = [(13, 8), (33, 50)]
    m.prisoners = [(33, 8), (53, 50), (73, 8), (73, 50)]
    m.minimum_prisoners = 2
    m.exit = (13, 50)
    m.bonus = 480
    m.route_order = [(33, 8), (53, 50), (73, 8), (73, 50)]
    m.minimum_seconds = 75
    m.preview_center = (33, 9)
    m.preview_hero = ((27, 9), (1, 0))
    m.preview_guards = [("trooper", (38, 11), (-1, -0.4))]
    return m


def core_breach():
    m = Layout("core_breach", "INF_CORE", 96, 64)
    m.carve(2, 2, 22, 18)
    m.carve(27, 2, 66, 18)
    m.carve(71, 2, 93, 18)
    m.strip(23, 9, 26, 11)
    m.strip(67, 9, 70, 11)
    m.strip(82, 19, 85, 23)
    m.carve(71, 24, 93, 40)
    m.carve(27, 24, 66, 40)
    m.carve(2, 24, 22, 40)
    m.strip(67, 31, 70, 33)
    m.strip(23, 31, 26, 33)
    m.strip(10, 41, 13, 45)
    m.carve(2, 46, 30, 61)
    m.carve(35, 46, 62, 61)
    m.carve(67, 46, 93, 61)
    m.strip(31, 52, 34, 54)
    m.strip(63, 52, 66, 54)
    m.strip(45, 19, 48, 23)
    for x in (34, 44, 54):
        m.crates(x, 6, x + 1, 14)
    m.crates(78, 7, 86, 8)
    m.crates(78, 12, 86, 13)
    m.crates(78, 29, 86, 30)
    m.crates(78, 34, 86, 35)
    m.crates(40, 28, 53, 29)
    m.crates(40, 35, 53, 36)
    m.crates(8, 29, 15, 30)
    m.crates(8, 35, 15, 36)
    for x in (10, 20):
        m.crates(x, 50, x, 57)
    for x in (42, 50, 56):
        m.crates(x, 50, x, 57)
    for x in (74, 84):
        m.crates(x, 49, x, 58)
    m.sentry((39, 10), (1, 0), "marksman")
    m.patrol("shield", [(29, 4), (64, 4), (64, 16), (29, 16)])
    m.sentry((49, 10), (-1, 0))
    m.patrol("trooper", [(73, 4), (91, 4), (91, 16), (73, 16)])
    m.sentry((82, 10), (0, 1), "marksman")
    m.patrol("walker", [(73, 26), (91, 26), (91, 38), (73, 38)])
    m.sentry((82, 32), (-1, 0))
    m.patrol("trooper", [(29, 26), (64, 26), (64, 38), (29, 38)])
    m.sentry((46, 32), (1, 0))
    m.patrol("trooper", [(4, 26), (20, 26), (20, 38), (4, 38)])
    m.sentry((12, 32), (0, 1), "marksman")
    m.patrol("drone", [(4, 48), (28, 48), (28, 59), (4, 59)])
    m.patrol("walker", [(37, 48), (60, 48), (60, 59), (37, 59)])
    m.sentry((46, 53), (1, 0))
    m.patrol("drone", [(69, 48), (91, 48), (91, 59), (69, 59)])
    m.sentry((79, 54), (-1, 0))
    m.reserve((64, 3), (0, 1))
    m.reserve((28, 60), (0, -1))
    m.reserve((91, 60), (-1, 0))
    m.spawn = (5, 6)
    m.panels = [(91, 7), (4, 39), (64, 39)]
    m.terminals = [(91, 39)]
    m.prisoners = [(91, 53), (60, 53), (25, 53)]
    m.minimum_prisoners = 2
    m.exit = (5, 53)
    m.disable_alarms = True
    m.panels_unlock_prisoners = True
    m.bonus = 660
    m.route_order = [(91, 7), (4, 39), (64, 39), (91, 39), (91, 53), (60, 53), (25, 53)]
    m.minimum_seconds = 120
    m.preview_center = (88, 53)
    m.preview_hero = ((82, 52), (1, 0.1))
    m.preview_guards = [("trooper", (90, 51), (-1, 0.4))]
    return m


MISSIONS = [first_access, silent_network, cold_archive, way_back, cell_block, core_breach]
EXTERNALS = [
    ("Script", "data/infiltration/infiltration_mission_data.gd", "mission"),
    ("Script", "data/infiltration/infiltration_map_data.gd", "map"),
    ("Script", "data/infiltration/infiltration_enemy_placement.gd", "placement"),
    ("Script", "data/infiltration/infiltration_panel_data.gd", "panel"),
    ("Resource", "data/infiltration/enemies/sentry.tres", "sentry"),
    ("Resource", "data/infiltration/enemies/patrol_trooper.tres", "trooper"),
    ("Resource", "data/infiltration/enemies/heavy.tres", "heavy"),
    ("Resource", "data/infiltration/enemies/marksman.tres", "marksman"),
    ("Resource", "data/infiltration/enemies/drone.tres", "drone"),
    ("Resource", "data/infiltration/enemies/shield.tres", "shield"),
    ("Resource", "data/infiltration/enemies/walker.tres", "walker"),
    ("Texture2D", "assets/infiltration/training_tiles.png", "tiles"),
    ("Texture2D", "assets/infiltration/training_sprites.png", "sprites"),
    ("Texture2D", "assets/infiltration/enemy_sprites.png", "enemies"),
]


def resource_text(m):
    text = '[gd_resource type="Resource" script_class="InfiltrationMissionData" format=3]\n\n'
    for kind, path, rid in EXTERNALS:
        text += f'[ext_resource type="{kind}" path="res://{path}" id="{rid}"]\n'
    text += f'[ext_resource type="Texture2D" path="res://assets/infiltration/previews/{m.id}.png" id="preview"]\n'
    for index, cell in enumerate(m.panels):
        text += f'\n[sub_resource type="Resource" id="panel_{index}"]\nscript = ExtResource("panel")\nposition = {vector(cell)}\n'
    enemy_refs = []
    for index, (kind, cell, direction, route, reserve) in enumerate(m.enemies):
        enemy_refs.append(f'SubResource("enemy_{index}")')
        text += f'\n[sub_resource type="Resource" id="enemy_{index}"]\nscript = ExtResource("placement")\nenemy = ExtResource("{kind}")\nposition = {vector(cell)}\ndirection = Vector2({direction[0]}, {direction[1]})\n'
        if route:
            text += f"route = {packed(route)}\n"
        if reserve:
            text += "reinforcement = true\n"
    rows = ", ".join(f'"{row}"' for row in m.rows())
    panels = ", ".join(f'SubResource("panel_{index}")' for index in range(len(m.panels)))
    text += f'\n[sub_resource type="Resource" id="layout"]\nscript = ExtResource("map")\nid = &"{m.id}"\ntitle_key = "{m.title_key}"\nplayer_spawn = {vector(m.spawn)}\nrows = PackedStringArray({rows})\nenemies = Array[ExtResource("placement")]([{", ".join(enemy_refs)}])\npanels = Array[ExtResource("panel")]([{panels}])\nenemy_sprites = ExtResource("enemies")\ntiles = ExtResource("tiles")\nsprites = ExtResource("sprites")\n'
    text += f'\n[resource]\nscript = ExtResource("mission")\nid = &"{m.id}"\ntitle_key = "{m.title_key}"\nbriefing_key = "{m.title_key}_BRIEF"\nmap = SubResource("layout")\ndisable_alarms = {str(m.disable_alarms).lower()}\npanels_unlock_prisoners = {str(m.panels_unlock_prisoners).lower()}\n'
    if m.terminals:
        text += f"terminals = {packed(m.terminals)}\n"
    if m.prisoners:
        text += f"prisoner_spawns = {packed(m.prisoners)}\nminimum_prisoners = {m.minimum_prisoners}\n"
    text += f'extraction = {vector(m.exit)}\nbonus_seconds = {m.bonus}.0\npreview = ExtResource("preview")\n'
    return text


def tile_column(symbol):
    return {"#": 1, "C": 2, "=": 3}.get(symbol, 0)


def palette():
    source = (ROOT / "ui/ui_palette.gd").read_text(encoding="utf-8")
    return {name: tuple(bytes.fromhex(value)) for name, value in re.findall(r'var (\w+): Color = Color\("#([0-9a-fA-F]{6})"\)', source)}


def preview_image(m):
    colors = palette()
    tiles = Image.open(ROOT / "assets/infiltration/training_tiles.png").convert("RGBA")
    enemies = Image.open(ROOT / "assets/infiltration/enemy_sprites.png").convert("RGBA")
    hero = Image.open(ROOT / "assets/infiltration/training_sprites.png").convert("RGBA").crop((0, 0, *SPRITE))
    prisoner = Image.open(ROOT / "assets/infiltration/prisoner.png").convert("RGBA")
    image = Image.new("RGBA", PREVIEW_SIZE, (*colors["background"], 255))
    origin = (m.preview_center[0] * TILE_PIXELS + TILE_PIXELS // 2 - PREVIEW_SIZE[0] // 2, m.preview_center[1] * TILE_PIXELS + TILE_PIXELS // 2 - PREVIEW_SIZE[1] // 2)
    for y, row in enumerate(m.rows()):
        for x, symbol in enumerate(row):
            px, py = x * TILE_PIXELS - origin[0], y * TILE_PIXELS - origin[1]
            if -TILE_PIXELS < px < PREVIEW_SIZE[0] and -TILE_PIXELS < py < PREVIEW_SIZE[1]:
                column = tile_column(symbol)
                image.paste(tiles.crop((column * TILE_PIXELS, 0, (column + 1) * TILE_PIXELS, TILE_PIXELS)), (px, py))

    def center(cell):
        return (cell[0] * TILE_PIXELS + TILE_PIXELS // 2 - origin[0], cell[1] * TILE_PIXELS + TILE_PIXELS // 2 - origin[1])

    def place(sprite, cell, facing=(0, -1)):
        x, y = center(cell)
        angle = math.degrees(math.atan2(facing[0], -facing[1]))
        turned = sprite.rotate(-angle, resample=Image.NEAREST, expand=True)
        layer = Image.new("RGBA", PREVIEW_SIZE)
        layer.paste(turned, (x - turned.width // 2, y - turned.height // 2))
        image.alpha_composite(layer)

    def cone(cell, facing, color, reach=PREVIEW_CONE_REACH, degrees=PREVIEW_CONE_DEGREES):
        x, y = center(cell)
        base = math.atan2(facing[1], facing[0])
        half = math.radians(degrees) / 2
        points = [(x, y)]
        for step in range(13):
            angle = base - half + 2 * half * step / 12
            points.append((x + math.cos(angle) * reach, y + math.sin(angle) * reach))
        layer = Image.new("RGBA", PREVIEW_SIZE)
        ImageDraw.Draw(layer).polygon(points, fill=(*color, 34), outline=(*color, 120))
        image.alpha_composite(layer)

    def marker(cell, color):
        x, y = center(cell)
        draw = ImageDraw.Draw(image)
        draw.rectangle((x - 10, y - 8, x + 10, y + 8), fill=(*colors["infiltration_wall"], 255), outline=(*color, 255))
        draw.rectangle((x - 6, y - 4, x + 6, y + 1), fill=(*color, 255))

    for cell in m.panels:
        marker(cell, colors["accent"])
    for cell in m.terminals:
        marker(cell, colors["text"])
    for cell in m.prisoners:
        place(prisoner, cell)
    for kind, cell, facing in m.preview_guards:
        cone(cell, facing, colors["danger"])
    for kind, cell, facing in m.preview_guards:
        place(enemies.crop((ENEMY_SPRITE[kind] * SPRITE[0], 0, (ENEMY_SPRITE[kind] + 1) * SPRITE[0], SPRITE[1])), cell, facing)
    place(hero, m.preview_hero[0], m.preview_hero[1])
    x, y = center(m.preview_hero[0])
    dx, dy = m.preview_hero[1]
    length = math.hypot(dx, dy)
    dx, dy = dx / length, dy / length
    grip = (x + dx * 8 - dy * 7, y + dy * 8 + dx * 7)
    tip = (grip[0] + dx * 34, grip[1] + dy * 34)
    glow = Image.new("RGBA", PREVIEW_SIZE)
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.line((grip, tip), fill=(*colors["menu_blade_a"], 50), width=6)
    glow_draw.line((grip, tip), fill=(*colors["menu_blade_a"], 255), width=2)
    image.alpha_composite(glow)
    return image


def write_enemies():
    bolts = ROOT / "data/infiltration/bolts"
    bolts.mkdir(parents=True, exist_ok=True)
    base = dict(speed="900.0", max_range="1100.0", size="6.0", flinch="0.12", muzzle_height="100.0", muzzle_forward="30.0", count="1", interval="0.1", perfect_reflect_speed="1.25")
    for name, fields in BOLTS.items():
        values = {**base, **fields}
        text = '[gd_resource type="Resource" script_class="BoltData" format=3]\n\n[ext_resource type="Script" path="res://data/bolt_data.gd" id="1"]\n\n[resource]\nscript = ExtResource("1")\n'
        text += f'id = &"{name}"\n' + "".join(f"{key} = {value}\n" for key, value in values.items())
        (bolts / f"{name}.tres").write_text(text, encoding="utf-8", newline="\n")
    folder = ROOT / "data/infiltration/enemies"
    for name, fields in ENEMIES.items():
        values = dict(fields)
        text = '[gd_resource type="Resource" script_class="InfiltrationEnemyData" format=3]\n\n[ext_resource type="Script" path="res://data/infiltration/infiltration_enemy_data.gd" id="enemy"]\n'
        bolt = values.pop("bolt", None)
        texture = values.pop("texture", None)
        if bolt:
            text += f'[ext_resource type="Resource" path="res://data/infiltration/bolts/{bolt}.tres" id="bolt"]\n'
        if texture:
            text += f'[ext_resource type="Texture2D" path="res://assets/infiltration/{texture}.png" id="texture"]\n'
        text += '\n[resource]\nscript = ExtResource("enemy")\nkind = 1\nrespawn_seconds = 0.0\n'
        text += "".join(f"{key} = {value}\n" for key, value in values.items())
        if bolt:
            text += 'bolt = ExtResource("bolt")\n'
        if texture:
            text += 'texture = ExtResource("texture")\n'
        (folder / f"{name}.tres").write_text(text, encoding="utf-8", newline="\n")


def main():
    write_enemies()
    folder = ROOT / "data/infiltration/missions"
    previews = ROOT / "assets/infiltration/previews"
    previews.mkdir(parents=True, exist_ok=True)
    for factory in MISSIONS:
        m = factory()
        m.validate()
        tiles, seconds = m.route_seconds()
        print(f"{m.id}: {m.width}x{m.height} guards={sum(1 for e in m.enemies if not e[4])}+{sum(1 for e in m.enemies if e[4])} route={tiles} tiles {seconds:.0f}s bonus={m.bonus}")
        if "--ascii" in sys.argv:
            print("\n".join(m.rows()))
        preview_image(m).save(previews / f"{m.id}.png", optimize=True)
        (folder / f"{m.id}.tres").write_text(resource_text(m), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
