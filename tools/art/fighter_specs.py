"""Paint specs: the source of every fighter's parts (the equivalent of a layered painting).

Colors are not painted here: parts carry palette slots and the costumes in
data/characters/<id>/ choose the colors. Proportions are in world units (u).
"""


def skirt(length, top=20.0, bottom=26.0, hem="straight", slot="cloak", stiffness=0.75, trim=False):
    return dict(name="skirt", anchor="waist", layer="front", length=length, texture_width=24.0, top_width=top,
                bottom_width=bottom, hem=hem, slot=slot, stiffness=stiffness, segments=5, trim_band=trim)


def cape(length, top=22.0, bottom=36.0, hem="straight", stiffness=0.35, slot="cloak"):
    return dict(name="cape", anchor="shoulders", layer="back", length=length, texture_width=30.0, top_width=top,
                bottom_width=bottom, hem=hem, slot=slot, stiffness=stiffness, segments=7, trim_band=False)


def scarf(length):
    return dict(name="scarf", anchor="neck", layer="back", length=length, texture_width=7.0, top_width=6.0,
                bottom_width=5.0, hem="straight", slot="trim", stiffness=0.12, segments=8, folds=0.5, trim_band=False)


def sash(length):
    return dict(name="sash", anchor="waist_back", layer="back", length=length, texture_width=8.0, top_width=6.0,
                bottom_width=7.0, hem="tails", slot="trim", stiffness=0.25, segments=5, trim_band=False)


SPECS = {
    "guardian": dict(
        torso=dict(tunic="wrap", belt="wide"),
        head=dict(hair="short", styles=True),
        arms=dict(bracer=True, sleeve_slot="cloak"),
        legs=dict(boot="mid"),
        cloth=[skirt(32.0)],
    ),
    "shadow": dict(
        build=dict(shoulder_half=11.0, hunch=0.12),
        torso=dict(tunic="wrap", belt="plain", buckle=False),
        head=dict(hair="short", hood="pointed", eclipse_eyes=True, styles=True),
        arms=dict(bracer=False),
        legs=dict(boot="high"),
        cloth=[skirt(40.0, bottom=30.0), cape(112.0, hem="torn")],
    ),
    "bastion": dict(
        build=dict(shoulder_half=15.5, waist_half=11.0, hip_half=9.5, arm_width=8.5, leg_width=13.0, scale=1.06),
        torso=dict(tunic="armor", belt="plain", buckle=False, plates=True),
        head=dict(hair=None),
        arms=dict(bracer=True),
        legs=dict(boot="mid", greave=True),
        cloth=[skirt(30.0, top=24.0, bottom=30.0, stiffness=0.85)],
        pads=True,
    ),
    "wasp": dict(
        build=dict(shoulder_half=10.5, waist_half=8.0, scale=0.97),
        torso=dict(tunic="wrap", belt="plain"),
        head=dict(hair="ponytail"),
        arms=dict(wraps=True),
        legs=dict(boot="mid"),
        cloth=[skirt(22.0, top=18.0, bottom=22.0)],
    ),
    "mirror": dict(
        torso=dict(tunic="robe", belt=None, high_collar=True),
        head=dict(hair=None, hood="plain", mask=dict(slot="trim", tone=0.7)),
        arms=dict(sleeve="wide", sleeve_slot="cloak"),
        legs=dict(boot="low"),
        cloth=[skirt(70.0, top=22.0, bottom=34.0, stiffness=0.7), cape(104.0, top=24.0, bottom=34.0, stiffness=0.45)],
    ),
    "lance": dict(
        torso=dict(tunic="wrap", belt="plain", belt_slot="trim"),
        head=dict(hair="short"),
        arms=dict(bracer=True),
        legs=dict(boot="mid"),
        cloth=[skirt(30.0)],
    ),
    "ember": dict(
        build=dict(shoulder_half=11.0),
        torso=dict(tunic="wrap", belt=None),
        head=dict(hair="short", hood="plain", eclipse_eyes=True),
        arms=dict(wraps=True, wraps_slot="trim"),
        legs=dict(boot="mid"),
        cloth=[skirt(22.0, top=18.0, bottom=22.0), sash(26.0)],
    ),
    "forge": dict(
        build=dict(shoulder_half=15.0, waist_half=11.0, hip_half=9.0, arm_width=8.5, leg_width=12.5, head=1.12, scale=1.04),
        torso=dict(tunic="wrap", belt="wide", apron=True),
        head=dict(hair="short", beard="short"),
        arms=dict(bracer=True),
        legs=dict(boot="mid"),
        cloth=[skirt(28.0, top=24.0, bottom=28.0)],
    ),
    "heron": dict(
        build=dict(shoulder_half=10.5, waist_half=8.0, scale=0.98),
        torso=dict(tunic="wrap", belt="plain"),
        head=dict(hair="bun", styles=True),
        arms=dict(),
        legs=dict(boot="high"),
        cloth=[skirt(22.0, top=18.0, bottom=22.0), scarf(64.0)],
    ),
    "reaper": dict(
        build=dict(shoulder_half=10.0, waist_half=7.8, hunch=0.1),
        torso=dict(tunic="wrap", belt="plain", belt_slot="trim", buckle=False, neck_sash=True),
        head=dict(hair=None, eclipse_eyes=True),
        arms=dict(bracer=True, bracer_slot="trim"),
        legs=dict(boot="mid"),
        cloth=[skirt(24.0, top=18.0, bottom=22.0), sash(30.0)],
    ),
    "echo": dict(
        build=dict(shoulder_half=11.0, hunch=0.1),
        torso=dict(tunic="wrap", belt="plain", buckle=False),
        head=dict(hair=None, hood="plain", mask=dict(slot="metal", tone=0.55)),
        arms=dict(torn_front=True),
        legs=dict(boot="mid"),
        cloth=[skirt(24.0, top=18.0, bottom=22.0)],
    ),
    "corsair": dict(
        build=dict(shoulder_half=11.0, waist_half=8.5),
        torso=dict(tunic="wrap", belt="wide", neck_sash=True),
        head=dict(hair="ponytail"),
        arms=dict(bracer=True, bracer_slot="leather", sleeve_slot="cloak"),
        legs=dict(boot="high"),
        cloth=[skirt(30.0, top=20.0, bottom=28.0, hem="tails", stiffness=0.6)],
    ),
    "lynx": dict(
        build=dict(shoulder_half=10.5, waist_half=8.0, scale=0.99),
        torso=dict(tunic="wrap", belt="plain", buckle=False, high_collar=True),
        head=dict(hair="short"),
        arms=dict(sleeve_slot="cloak"),
        legs=dict(boot="high"),
        cloth=[skirt(58.0, top=20.0, bottom=30.0, stiffness=0.7)],
    ),
    "awakened_shadow": dict(
        build=dict(shoulder_half=14.0, waist_half=10.0, hunch=0.1, scale=1.05),
        torso=dict(tunic="wrap", belt="plain", buckle=False, plates=True),
        head=dict(hair="short", hood="pointed", eclipse_eyes=True),
        arms=dict(bracer=True, bracer_slot="metal"),
        legs=dict(boot="high"),
        cloth=[skirt(40.0, bottom=30.0), cape(116.0, top=28.0, bottom=42.0, hem="torn")],
        pads=True,
    ),
    "sovereign": dict(
        build=dict(shoulder_half=10.5, waist_half=9.0, hunch=0.22),
        torso=dict(tunic="robe", belt=None, high_collar=True),
        head=dict(hair=None, hood="deep", eclipse_eyes=True),
        arms=dict(sleeve="wide", sleeve_slot="cloak"),
        legs=dict(boot="low"),
        cloth=[skirt(72.0, top=22.0, bottom=36.0, stiffness=0.7), cape(110.0, top=24.0, bottom=36.0)],
    ),
    "elder": dict(
        build=dict(shoulder_half=10.5, hunch=0.12),
        torso=dict(tunic="robe", belt="plain", belt_slot="trim", buckle=False),
        head=dict(hair="long", beard="long"),
        arms=dict(sleeve="wide", sleeve_slot="cloak"),
        legs=dict(boot="low"),
        cloth=[skirt(68.0, top=22.0, bottom=32.0, stiffness=0.7)],
    ),
    "foretold": dict(
        torso=dict(tunic="wrap", belt="wide"),
        head=dict(hair="wavy"),
        arms=dict(bracer=True, sleeve_slot="cloak"),
        legs=dict(boot="mid"),
        cloth=[skirt(30.0)],
    ),
    "foretold_eclipse": dict(
        torso=dict(tunic="wrap", belt="wide"),
        head=dict(hair="wavy", eclipse_eyes=True),
        arms=dict(bracer=True),
        legs=dict(boot="mid"),
        cloth=[skirt(30.0)],
    ),
}

COSTUME_CLOTH = {
    "hooded_cape": cape(100.0, top=22.0, bottom=32.0),
}
