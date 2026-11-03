from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "data/finishers"
FAMILY_FOLDER = ROOT / "data/families"
KIND_ORDER = "data/finisher.gd"
HEADER = '''[gd_resource type="Resource" script_class="FinisherMotion" format=3]

[ext_resource type="Script" path="res://data/finisher_motion.gd" id="1_script"]
[ext_resource type="Script" path="res://data/pose_key.gd" id="2_key"]
[ext_resource type="Script" path="res://data/finisher_reaction.gd" id="3_reaction"]
[ext_resource type="Script" path="res://data/finisher_effects.gd" id="4_effects"]
[ext_resource type="Script" path="res://data/finisher_cue.gd" id="5_cue"]
'''
WAIST = 2
VERTICAL = 3
DIAGONAL = 4
ORDER = [name.strip() for name in re.search(r"enum Kind \{(.*?)\}", (ROOT / KIND_ORDER).read_text(encoding="utf-8"), re.S).group(1).split(",") if name.strip()]
X_CUT = ORDER.index("X_CUT")
WIND = "swing_light"
HEAVY_WIND = "swing_heavy"
LIGHT_HIT = "hit_light"
HEAVY_HIT = "hit_heavy"
SHOT = "bolt_shot"


def k(time, x, y, angle, off=None, **fields):
    key = dict(time=time, grip=(x, y), blade_angle=angle, **fields)
    if off is not None:
        key["places_off_hand"] = True
        key["off_hand"] = (off[0], off[1])
        key["off_blade_angle"] = off[2]
    return key


def motion(keys, reaction, streaks=(), cues=(), holes=(), shots=(), travel=None, faces_back=True, extinguish=None, both=False):
    return dict(keys=keys, reaction=reaction, streaks=list(streaks), cues=list(cues), holes=list(holes), shots=list(shots), travel=travel, faces_back=faces_back, extinguish=extinguish, both=both)


FAMILIES = {
    "guardian": {
        "GUARDIAN_DISARM": motion([
            k(0.12, 14, -30, -60, crouch=6),
            k(0.34, 30, -20, 35, lean=10, step=6, trail=True, accent=True),
            k(0.56, -8, -22, 2, crouch=8, lean=-4),
            k(0.8, 42, -22, 2, crouch=8, lean=14, step=14, trail=True),
            k(1.25, 42, -22, 2, crouch=6, lean=12, step=14),
            k(1.7, 12, -16, 100, lean=-2, step=4),
        ], dict(front_arm_at=0.32, drops_hilt=True, kneel_at=0.8, fall_at=1.3),
            streaks=[0.32, 0.78], holes=[0.78], extinguish=1.75,
            cues=[(0.15, WIND, -2, 1.1), (0.32, LIGHT_HIT, 0, 1.0), (0.62, WIND, 0, 0.9), (0.78, HEAVY_HIT, 0, 1.0), (1.75, "extinguish", -6, 1.0)]),
        "GUARDIAN_RETURN": motion([
            k(0.15, 24, -10, 10, crouch=12, lean=10),
            k(0.42, 22, -8, 10, twirl=1, crouch=14, turn=1, trail=True, accent=True),
            k(0.82, 10, -30, -120, crouch=2, turn=1),
            k(1.3, 14, -18, 110),
        ], dict(split_at=0.46, split_as=WAIST, fall_at=0.5),
            streaks=[0.44], travel=(0.14, 0.42),
            cues=[(0.2, WIND, 0, 1.2), (0.46, HEAVY_HIT, 0, 1.1)]),
        "GUARDIAN_COUNTER": motion([
            k(0.2, 14, -40, -85, lean=-4),
            k(0.5, 18, -42, -70),
            k(0.7, -6, -50, -130, crouch=4),
            k(0.92, 34, -14, 48, crouch=10, lean=12, step=10, trail=True, accent=True),
            k(1.5, 20, -10, 100),
        ], dict(split_at=0.9, split_as=DIAGONAL, fall_at=0.95),
            streaks=[0.9],
            cues=[(0.4, LIGHT_HIT, -2, 1.3), (0.72, HEAVY_WIND, 0, 1.0), (0.9, HEAVY_HIT, 0, 1.0)]),
        "GUARDIAN_BOW": motion([
            k(0.12, -4, -24, 2, crouch=6),
            k(0.32, 40, -48, -6, lean=12, step=12, trail=True, accent=True),
            k(0.75, 24, -30, -40),
            k(1.2, 8, -44, -92),
            k(1.75, 6, -10, 100, lean=22, head=14),
        ], dict(head_at=0.32, kneel_at=0.5, fall_at=0.8),
            streaks=[0.32], extinguish=1.6,
            cues=[(0.16, WIND, 0, 1.3), (0.32, HEAVY_HIT, 0, 1.2), (1.6, "extinguish", -6, 1.0)]),
    },
    "aggressor": {
        "AGGRESSOR_RISING": motion([
            k(0.15, 12, -4, 130, crouch=14, lean=8),
            k(0.42, 32, -60, -60, crouch=2, lean=-2, step=12, trail=True, accent=True),
            k(0.95, 26, -66, -72),
            k(1.45, 18, -20, 100),
        ], dict(split_at=0.4, split_as=VERTICAL, fall_at=0.45),
            streaks=[0.4],
            cues=[(0.2, HEAVY_WIND, 0, 1.2), (0.4, HEAVY_HIT, 0, 0.95)]),
        "AGGRESSOR_THREE": motion([
            k(0.08, 8, -50, -120, lean=-2),
            k(0.24, 30, -14, 50, lean=10, step=6, trail=True),
            k(0.4, -2, -12, 150, crouch=6),
            k(0.56, 30, -44, -40, lean=8, step=8, trail=True),
            k(0.7, -4, -52, -150, lean=-4),
            k(0.88, 38, -50, 8, lean=14, step=12, trail=True, accent=True),
            k(1.4, 18, -18, 110),
        ], dict(front_arm_at=0.22, drops_hilt=True, back_arm_at=0.54, head_at=0.86, kneel_at=1.0, fall_at=1.0),
            streaks=[0.22, 0.54, 0.86],
            cues=[(0.1, WIND, 0, 1.3), (0.22, LIGHT_HIT, 0, 1.1), (0.42, WIND, 0, 1.4), (0.54, LIGHT_HIT, 0, 1.0), (0.72, WIND, 0, 1.2), (0.86, HEAVY_HIT, 0, 1.1)]),
        "AGGRESSOR_THROAT": motion([
            k(0.2, 30, -46, 4, step=10),
            k(0.9, 32, -48, 2, step=10, head=4),
            k(1.12, 40, -50, -8, lean=10, step=14, trail=True, accent=True),
            k(1.7, 16, -18, 110),
        ], dict(kneel_at=0.2, head_at=1.1, fall_at=1.4),
            streaks=[1.1],
            cues=[(0.2, "step", 0, 1.0), (1.0, WIND, -2, 0.8), (1.1, HEAVY_HIT, 0, 1.1)]),
    },
    "colossus": {
        "COLOSSUS_CRUSH": motion([
            k(0.3, 6, -76, -92, crouch=2, lean=-6),
            k(0.62, 30, -24, 30, crouch=12, lean=14, step=8, trail=True, accent=True),
            k(0.95, 6, -78, -92, lean=-6, step=4),
            k(1.3, 34, -46, 10, crouch=6, lean=14, step=12, trail=True),
            k(1.9, 22, -12, 100),
        ], dict(front_arm_at=0.6, drops_hilt=True, kneel_at=0.65, head_at=1.28, fall_at=1.6),
            streaks=[0.6, 1.28],
            cues=[(0.3, HEAVY_WIND, 0, 0.8), (0.6, HEAVY_HIT, 0, 0.8), (1.0, HEAVY_WIND, 0, 0.75), (1.28, HEAVY_HIT, 0, 0.85)]),
        "COLOSSUS_CLEAVE": motion([
            k(0.4, 4, -80, -95, lean=-8),
            k(0.72, 30, -6, 62, crouch=16, lean=18, step=12, trail=True, accent=True),
            k(1.4, 28, -4, 70, crouch=12, lean=12, step=12),
            k(1.9, 16, -18, 105),
        ], dict(split_at=0.7, split_as=DIAGONAL, fall_at=0.75),
            streaks=[0.7],
            cues=[(0.42, HEAVY_WIND, 0, 0.75), (0.7, HEAVY_HIT, 0, 0.75)]),
        "COLOSSUS_LEG": motion([
            k(0.25, -10, -10, 170, crouch=14, lean=4),
            k(0.52, 32, 4, 18, crouch=22, lean=14, step=8, trail=True, accent=True),
            k(0.85, 6, -74, -92, crouch=2, lean=-6),
            k(1.15, 30, -40, 20, crouch=8, lean=12, step=10, trail=True),
            k(1.7, 20, -12, 100),
        ], dict(front_leg_at=0.5, kneel_at=0.55, head_at=1.12, fall_at=1.2),
            streaks=[0.5, 1.12],
            cues=[(0.28, HEAVY_WIND, 0, 0.85), (0.5, HEAVY_HIT, 0, 0.85), (0.9, HEAVY_WIND, 0, 0.8), (1.12, HEAVY_HIT, 0, 0.9)]),
    },
    "wasp": {
        "WASP_REVERSE": motion([
            k(0.12, -6, -44, -150, off=(-14, -2, 150), crouch=2),
            k(0.4, 30, -20, 30, off=(30, -24, -30), crouch=8, lean=12, step=10, trail=True, off_trail=True, accent=True),
            k(0.9, 34, -22, 10, off=(34, -26, -10), crouch=6, lean=8, step=10),
            k(1.4, 16, -16, 110, off=(-6, -4, 120)),
        ], dict(split_at=0.38, split_as=WAIST, fall_at=0.42),
            streaks=[0.38], both=True,
            cues=[(0.16, WIND, 0, 1.3), (0.38, HEAVY_HIT, 0, 1.15)]),
        "WASP_SWARM": motion([
            k(0.08, 4, -44, -110, off=(-10, -8, 140)),
            k(0.22, 32, -20, 40, off=(-8, -6, 150), lean=8, trail=True),
            k(0.36, -2, -44, -130, off=(24, -20, -20), off_trail=True),
            k(0.5, 34, -26, 10, off=(-6, -12, 150), lean=8, trail=True),
            k(0.64, -4, -22, 0, off=(40, -24, 2), lean=10, step=6, off_trail=True),
            k(0.8, 42, -24, 2, off=(-4, -20, 2), lean=12, step=8, trail=True),
            k(1.3, 16, -16, 110, off=(-6, -4, 120)),
        ], dict(front_arm_at=0.22, drops_hilt=True, back_arm_at=0.5, kneel_at=0.85, fall_at=0.95),
            streaks=[0.22, 0.36, 0.5, 0.64, 0.8], holes=[0.64, 0.8],
            cues=[(0.1, WIND, 0, 1.5), (0.22, LIGHT_HIT, 0, 1.2), (0.36, WIND, 0, 1.6), (0.5, LIGHT_HIT, 0, 1.3), (0.64, LIGHT_HIT, 0, 1.4), (0.8, HEAVY_HIT, 0, 1.2)]),
        "WASP_CROSS": motion([
            k(0.2, -2, -56, -130, off=(8, -58, -60), lean=-4),
            k(0.58, 32, -12, 50, off=(34, -16, 30), crouch=10, lean=14, step=12, trail=True, off_trail=True, accent=True),
            k(1.3, 20, -10, 100, off=(-6, -6, 120)),
        ], dict(split_at=0.56, split_as=DIAGONAL, fall_at=0.6),
            streaks=[0.56], both=True,
            cues=[(0.24, HEAVY_WIND, 0, 1.3), (0.56, HEAVY_HIT, 0, 1.15)]),
        "WASP_SPIRAL": motion([
            k(0.15, 18, -24, -20, off=(-12, -6, 150), crouch=6),
            k(0.45, 20, -30, 0, off=(-14, -8, 150), twirl=1, off_twirl=1, turn=1, trail=True),
            k(0.8, 36, -48, 6, off=(34, -44, -6), turn=1, lean=10, step=10, trail=True, off_trail=True, accent=True),
            k(1.35, 16, -16, 110, off=(-6, -4, 120)),
        ], dict(head_at=0.78, kneel_at=0.95, fall_at=1.1),
            streaks=[0.45, 0.78], both=True,
            cues=[(0.2, WIND, 0, 1.4), (0.5, WIND, 0, 1.5), (0.78, HEAVY_HIT, 0, 1.2)]),
    },
    "fencer": {
        "FENCER_SALUTE": motion([
            k(0.2, 8, -50, -90, lean=-4, head=-2),
            k(0.55, 6, -44, -88),
            k(0.72, -8, -22, 2, crouch=6),
            k(0.95, 44, -22, 2, crouch=8, lean=18, step=18, trail=True, accent=True),
            k(1.5, 44, -22, 2, crouch=6, lean=14, step=18),
            k(2.0, 8, -46, -90),
        ], dict(fall_at=1.2, fall_backward=True),
            streaks=[0.93], holes=[0.93],
            cues=[(0.72, WIND, 0, 1.1), (0.93, HEAVY_HIT, 0, 1.2)]),
        "FENCER_TRIPLE": motion([
            k(0.14, -6, -24, 2, crouch=4),
            k(0.3, 40, -30, -2, lean=10, step=8, trail=True),
            k(0.42, -6, -22, 2, crouch=4),
            k(0.55, 42, -22, 2, lean=12, step=10, trail=True),
            k(0.67, -6, -16, 2, crouch=6),
            k(0.8, 42, -14, 4, crouch=8, lean=14, step=12, trail=True, accent=True),
            k(1.4, 14, -18, 100),
        ], dict(kneel_at=0.95, fall_at=1.2),
            streaks=[0.3, 0.55, 0.8], holes=[0.3, 0.55, 0.8],
            cues=[(0.16, WIND, 0, 1.4), (0.3, LIGHT_HIT, 0, 1.3), (0.44, WIND, 0, 1.5), (0.55, LIGHT_HIT, 0, 1.4), (0.68, WIND, 0, 1.6), (0.8, HEAVY_HIT, 0, 1.3)]),
        "FENCER_LINE": motion([
            k(0.12, -8, -22, 2, crouch=6),
            k(0.4, 34, -24, 2, crouch=10, lean=14, trail=True, accent=True),
            k(0.8, 26, -24, 4, crouch=4, lean=6),
            k(1.3, 10, -48, -90),
        ], dict(split_at=0.42, split_as=WAIST, fall_at=0.46),
            streaks=[0.4], travel=(0.15, 0.42),
            cues=[(0.18, WIND, 0, 1.3), (0.42, HEAVY_HIT, 0, 1.2)]),
        "FENCER_HEART": motion([
            k(0.3, -8, -30, 0, crouch=2),
            k(0.6, 44, -30, 0, crouch=6, lean=14, step=12, trail=True, accent=True),
            k(1.2, 44, -30, 0, crouch=4, lean=12, step=12, head=2),
            k(1.55, 14, -24, 40, step=4),
            k(2.0, 8, -46, -90),
        ], dict(kneel_at=1.2, fall_at=1.35),
            streaks=[0.58], holes=[0.58],
            cues=[(0.38, WIND, -2, 1.0), (0.58, HEAVY_HIT, 0, 1.3), (1.3, WIND, -6, 0.8)]),
    },
    "striker": {
        "STRIKER_FEINT": motion([
            k(0.15, 6, -66, -100, lean=-4),
            k(0.3, 10, -60, -85),
            k(0.5, 30, 2, 14, crouch=20, lean=12, step=8, trail=True, accent=True),
            k(0.85, -6, -50, -140, crouch=4),
            k(1.08, 38, -50, 6, lean=12, step=10, trail=True),
            k(1.6, 18, -16, 110),
        ], dict(front_leg_at=0.48, kneel_at=0.55, head_at=1.06, fall_at=1.2),
            streaks=[0.48, 1.06],
            cues=[(0.18, WIND, -2, 1.2), (0.36, WIND, 0, 1.4), (0.48, LIGHT_HIT, 0, 1.0), (0.88, WIND, 0, 1.2), (1.06, HEAVY_HIT, 0, 1.1)]),
        "STRIKER_ANSWER": motion([
            k(0.18, 14, -40, -85),
            k(0.32, 16, -42, -80),
            k(0.5, 34, -12, 50, crouch=8, lean=12, step=10, trail=True, accent=True),
            k(1.2, 18, -12, 105),
        ], dict(split_at=0.48, split_as=DIAGONAL, fall_at=0.52),
            streaks=[0.48],
            cues=[(0.2, LIGHT_HIT, -2, 1.4), (0.34, WIND, 0, 1.4), (0.48, HEAVY_HIT, 0, 1.2)]),
        "STRIKER_BEHIND": motion([
            k(0.4, -4, -26, 2, crouch=4),
            k(0.72, 40, -26, 2, crouch=8, lean=12, step=10, trail=True, accent=True),
            k(1.3, 40, -26, 2, crouch=6, lean=10, step=10),
            k(1.7, 16, -18, 105),
        ], dict(kneel_at=1.0, fall_at=1.2),
            streaks=[0.7], holes=[0.7], travel=(0.12, 0.4),
            cues=[(0.14, "step", 0, 1.2), (0.5, WIND, 0, 1.2), (0.7, HEAVY_HIT, 0, 1.1)]),
        "STRIKER_DOUBLE": motion([
            k(0.12, 2, -44, -130),
            k(0.3, 30, -16, 45, lean=8, step=6, trail=True),
            k(0.45, -4, -20, 160, crouch=4),
            k(0.68, 38, -52, -12, lean=12, step=10, trail=True, accent=True),
            k(1.3, 18, -16, 110),
        ], dict(front_arm_at=0.28, drops_hilt=True, head_at=0.66, kneel_at=0.8, fall_at=0.95),
            streaks=[0.28, 0.66],
            cues=[(0.14, WIND, 0, 1.3), (0.28, LIGHT_HIT, 0, 1.1), (0.48, WIND, 0, 1.2), (0.66, HEAVY_HIT, 0, 1.1)]),
    },
    "dancer": {
        "DANCER_LEAP": motion([
            k(0.12, 10, -10, 60, crouch=16),
            k(0.4, 8, -70, -100, crouch=-14, twirl=1, turn=1, trail=True),
            k(0.62, 26, -40, 30, crouch=6, lean=8, turn=1, trail=True, accent=True),
            k(1.2, 12, -20, 110, crouch=10),
        ], dict(head_at=0.6, kneel_at=0.8, fall_at=0.95),
            streaks=[0.4, 0.6], travel=(0.1, 0.55),
            cues=[(0.16, WIND, 0, 1.3), (0.42, WIND, 0, 1.5), (0.6, HEAVY_HIT, 0, 1.2)]),
        "DANCER_LOW": motion([
            k(0.2, -6, -8, 150, crouch=12, lean=-6),
            k(0.34, -8, 0, 165, crouch=24, lean=-2),
            k(0.66, 32, 8, 12, twirl=1, crouch=28, lean=10, turn=1, trail=True, accent=True),
            k(0.86, -8, 4, 170, crouch=28, lean=-2),
            k(1.12, 36, 8, 6, crouch=28, lean=14, step=10, trail=True),
            k(1.34, 34, 6, 8, crouch=24, lean=10, step=10),
            k(1.85, 14, -18, 110, crouch=4),
        ], dict(front_leg_at=0.64, back_leg_at=1.1, fall_at=1.14),
            streaks=[0.64, 1.1],
            cues=[(0.36, WIND, 0, 1.2), (0.64, LIGHT_HIT, 0, 1.0), (0.9, WIND, 0, 1.3), (1.1, HEAVY_HIT, 0, 1.15)]),
        "DANCER_DESCENT": motion([
            k(0.18, 10, -14, 40, crouch=14, lean=4),
            k(0.5, -10, -74, -150, crouch=-18, lean=-8),
            k(0.72, -8, -78, -145, crouch=-20, lean=-8),
            k(0.92, 12, -74, -70, crouch=-10, lean=-2, trail=True),
            k(1.08, 30, -46, -12, crouch=4, lean=10, step=8, trail=True, accent=True),
            k(1.22, 30, -14, 44, crouch=16, lean=16, step=12, trail=True),
            k(1.38, 26, -2, 76, crouch=22, lean=16, step=12),
            k(1.95, 16, -14, 105, crouch=4),
        ], dict(split_at=1.14, split_as=VERTICAL, fall_at=1.18),
            streaks=[1.14],
            cues=[(0.2, WIND, -2, 1.0), (0.86, HEAVY_WIND, 0, 1.15), (1.14, HEAVY_HIT, 0, 1.1)]),
    },
    "reaper": {
        "REAPER_WHEEL": motion([
            k(0.15, 18, -30, -60),
            k(0.45, 20, -30, 0, twirl=1, trail=True),
            k(0.8, 34, -24, 10, twirl=1, step=10, lean=10, trail=True, accent=True),
            k(1.4, 14, -20, 100),
        ], dict(split_at=0.78, split_as=WAIST, fall_at=0.82),
            streaks=[0.45, 0.78], both=True,
            cues=[(0.2, HEAVY_WIND, 0, 1.2), (0.5, HEAVY_WIND, 0, 1.3), (0.78, HEAVY_HIT, 0, 1.0)]),
        "REAPER_HOOK": motion([
            k(0.2, 30, -44, 40, step=8),
            k(0.45, 18, -30, 30, lean=-12, step=-2),
            k(0.85, 36, -52, -6, lean=12, step=6, trail=True, accent=True),
            k(1.4, 14, -20, 100),
        ], dict(push_back=-22, push_at=0.25, push_time=0.2, kneel_at=0.5, head_at=0.83, fall_at=1.1),
            streaks=[0.2, 0.83],
            cues=[(0.2, LIGHT_HIT, 0, 0.9), (0.6, HEAVY_WIND, 0, 1.2), (0.83, HEAVY_HIT, 0, 1.0)]),
        "REAPER_X": motion([
            k(0.12, 0, -56, -135),
            k(0.36, 32, -14, 50, lean=10, step=8, trail=True),
            k(0.52, 0, -14, 135, crouch=4),
            k(0.76, 32, -56, -50, lean=10, step=10, trail=True, accent=True),
            k(1.4, 14, -20, 100),
        ], dict(split_at=0.74, split_as=X_CUT, fall_at=0.78),
            streaks=[0.34, 0.74], both=True,
            cues=[(0.14, WIND, 0, 1.2), (0.34, LIGHT_HIT, 0, 1.0), (0.54, WIND, 0, 1.3), (0.74, HEAVY_HIT, 0, 1.05)]),
        "REAPER_CHEST": motion([
            k(0.14, -8, -24, 2, crouch=4),
            k(0.46, 42, -24, 2, lean=14, step=12, trail=True),
            k(0.62, -6, -24, 2, crouch=4),
            k(0.86, 44, -20, 4, crouch=6, lean=16, step=14, trail=True, accent=True),
            k(1.45, 44, -20, 4, crouch=4, lean=12, step=14),
            k(1.85, 14, -20, 100),
        ], dict(fall_at=1.15, fall_backward=True),
            streaks=[0.44, 0.84], holes=[0.44, 0.84], both=True,
            cues=[(0.2, WIND, 0, 1.1), (0.44, HEAVY_HIT, -2, 1.2), (0.66, WIND, 0, 1.2), (0.84, HEAVY_HIT, 0, 1.0)]),
    },
    "versatile": {
        "VERSATILE_SHOT_CUT": motion([
            k(0.12, 6, -8, 35, off=(20, -26, 120), sidearm=0.4, crouch=2),
            k(0.26, 4, -6, 35, off=(38, -38, 120), sidearm=1.0, lean=-2),
            k(0.46, 4, -6, 35, off=(35, -37, 120), sidearm=1.0, lean=-4),
            k(0.64, -4, -52, -140, off=(6, 4, 120), lean=-4),
            k(0.92, 38, -50, 6, off=(6, 4, 120), lean=12, step=10, trail=True, accent=True),
            k(1.45, 18, -16, 110, off=(6, 4, 120)),
        ], dict(head_at=0.9, kneel_at=0.38, fall_at=1.05),
            streaks=[0.9], shots=[0.32],
            cues=[(0.32, SHOT, 0, 1.0), (0.32, "bolt_hit", 0, 1.0), (0.68, WIND, 0, 1.2), (0.9, HEAVY_HIT, 0, 1.1)]),
        "VERSATILE_TWO_SHOTS": motion([
            k(0.12, 6, -8, 35, off=(20, -26, 120), sidearm=0.4),
            k(0.26, 4, -6, 35, off=(38, -38, 120), sidearm=1.0),
            k(0.56, 4, -6, 35, off=(35, -37, 120), sidearm=1.0, lean=-3),
            k(0.74, -8, -22, 2, off=(6, 4, 120), crouch=6),
            k(0.98, 44, -22, 2, off=(6, 4, 120), crouch=8, lean=16, step=16, trail=True, accent=True),
            k(1.55, 44, -22, 2, off=(6, 4, 120), crouch=6, lean=12, step=16),
            k(1.95, 14, -18, 105, off=(6, 4, 120)),
        ], dict(kneel_at=1.1, fall_at=1.35),
            streaks=[0.96], shots=[0.32, 0.5], holes=[0.96],
            cues=[(0.32, SHOT, 0, 1.0), (0.5, SHOT, 0, 1.05), (0.76, WIND, 0, 1.1), (0.96, HEAVY_HIT, 0, 1.1)]),
        "VERSATILE_POINT_BLANK": motion([
            k(0.12, 6, -8, 35, off=(20, -26, 120), sidearm=0.4, step=8),
            k(0.26, 4, -6, 35, off=(32, -36, 120), sidearm=1.0, step=14),
            k(0.8, 4, -6, 35, off=(29, -35, 120), sidearm=1.0, step=14, lean=-4),
            k(1.3, 4, -6, 35, off=(29, -34, 120), sidearm=1.0, step=12),
            k(1.7, 14, -18, 105, off=(6, 4, 120), step=6),
        ], dict(fall_at=0.95, fall_backward=True),
            shots=[0.32, 0.44, 0.56, 0.68], holes=[0.32, 0.56, 0.68],
            cues=[(0.32, SHOT, 0, 1.0), (0.44, SHOT, 0, 1.05), (0.56, SHOT, 0, 1.1), (0.68, SHOT, 0, 0.9), (0.68, "bolt_hit", 0, 0.9)]),
    },
}
NEVER_FIELDS = ("front_arm_at", "back_arm_at", "front_leg_at", "back_leg_at", "kneel_at", "head_at", "split_at", "turn_at")
BEHIND = {name for family in FAMILIES.values() for name, data in family.items() if data["travel"] is not None}


def number(value):
    if isinstance(value, float):
        return repr(value)
    return str(value)


def key_text(index, key):
    lines = [f'[sub_resource type="Resource" id="key_{index}"]', 'script = ExtResource("2_key")']
    for field, value in key.items():
        if isinstance(value, tuple):
            lines.append(f"{field} = Vector2({value[0]}, {value[1]})")
        elif isinstance(value, bool):
            lines.append(f"{field} = {'true' if value else 'false'}")
        else:
            lines.append(f"{field} = {number(value)}")
    return "\n".join(lines)


def floats(values):
    return "PackedFloat32Array(" + ", ".join(repr(float(value)) for value in values) + ")"


def validate(name, data):
    reaction = data["reaction"]
    split = reaction.get("split_at", -1) >= 0
    cut = any(reaction.get(field, -1) >= 0 for field in ("front_arm_at", "back_arm_at", "front_leg_at", "back_leg_at", "head_at"))
    assert not (split and cut), f"{name}: a split rebuilds the rig and would restore lost limbs"
    keys = data["keys"]
    assert all(keys[i]["time"] < keys[i + 1]["time"] for i in range(len(keys) - 1)), name
    assert "fall_at" in reaction, name


def motion_text(data):
    parts = [HEADER]
    keys = data["keys"]
    for index, key in enumerate(keys):
        parts.append(key_text(index, key))
    reaction = ['[sub_resource type="Resource" id="reaction"]', 'script = ExtResource("3_reaction")']
    for field, value in data["reaction"].items():
        reaction.append(f"{field} = {'true' if value is True else number(value)}")
    parts.append("\n".join(reaction))
    effects = ['[sub_resource type="Resource" id="effects"]', 'script = ExtResource("4_effects")']
    if data["streaks"]:
        effects.append(f"streaks = {floats(data['streaks'])}")
    if data["both"]:
        effects.append("streaks_both = true")
    if data["holes"]:
        effects.append("hole = true")
        effects.append(f"hole_at = {float(data['holes'][0])!r}")
        if len(data["holes"]) > 1:
            effects.append(f"extra_holes = {floats(data['holes'][1:])}")
    if data["shots"]:
        effects.append(f"shots = {floats(data['shots'])}")
    parts.append("\n".join(effects))
    for index, (time, sound, volume, pitch) in enumerate(data["cues"]):
        parts.append("\n".join([f'[sub_resource type="Resource" id="cue_{index}"]', 'script = ExtResource("5_cue")', f"time = {float(time)!r}", f'sound = &"{sound}"', f"volume_db = {float(volume)!r}", f"pitch = {float(pitch)!r}"]))
    main = ["[resource]", 'script = ExtResource("1_script")']
    main.append('keys = Array[ExtResource("2_key")]([' + ", ".join(f'SubResource("key_{i}")' for i in range(len(keys))) + "])")
    main.append("lead_in = true")
    if data["travel"] is not None:
        main.append(f"travel_from = {float(data['travel'][0])!r}")
        main.append(f"travel_to = {float(data['travel'][1])!r}")
        if not data["faces_back"]:
            main.append("travel_faces_back = false")
    if data["extinguish"] is not None:
        main.append(f"extinguish_at = {float(data['extinguish'])!r}")
    main.append('reaction = SubResource("reaction")')
    main.append('effects = SubResource("effects")')
    main.append('cues = Array[ExtResource("5_cue")]([' + ", ".join(f'SubResource("cue_{i}")' for i in range(len(data["cues"]))) + "])")
    parts.append("\n".join(main))
    return "\n\n".join(parts) + "\n"


def set_pool(family, names, order):
    path = FAMILY_FOLDER / f"{family}.tres"
    text = path.read_text(encoding="utf-8")
    values = ", ".join(str(order.index(name)) for name in names)
    line = f"finisher_pool = PackedInt32Array({values})"
    text = re.sub(r"^finisher_pool = .*$\n", "", text, flags=re.M)
    head, marker, tail = text.partition("[resource]\n")
    lines = tail.split("\n")
    lines.insert(1, line)
    path.write_text(head + marker + "\n".join(lines), encoding="utf-8", newline="\n")


def main():
    order = ORDER
    for family, finishers in FAMILIES.items():
        for name, data in finishers.items():
            validate(name, data)
            (FOLDER / f"{name.lower()}.tres").write_text(motion_text(data), encoding="utf-8", newline="\n")
        set_pool(family, list(finishers), order)
    print(sum(len(f) for f in FAMILIES.values()), "finishers")
    print("BEHIND", sorted(BEHIND))


if __name__ == "__main__":
    main()
