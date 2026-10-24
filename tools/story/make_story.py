"""Builds the campaign data and its dialogue texts from content/STORY.md.

STORY.md stays the single source of the story: this tool reads its dialogue tables and endings,
writes data/story/encounters/*.tres, data/story/endings/*.tres and data/story/campaign.tres, and
replaces the encounter and ending rows of localization/strings.csv.

Usage (from the project root): python tools/story/make_story.py
"""
import csv
import io
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.chdir(ROOT)

SPEAKERS = {
    "Narrador": "narrator", "Guardião": "guardian", "Eco": "echo", "Vespa": "wasp", "Brasa": "ember", "Bastião": "bastion",
    "Sombra": "shadow", "Sombra Desperta": "awakened_shadow", "Soberano": "sovereign", "Predestinado": "foretold",
    "Ceifador": "reaper", "Espelho": "mirror", "Garça": "heron", "Ancião": "elder", "Protagonista": "protagonist",
}
PATHS = {"": 0, "Aurora": 1, "Eclipse": 2}

ENCOUNTERS = [
    ("1", "trial", 1, 0, "guardian", "refinery_platform", -1, False, False, True, "", "", []),
    ("2", "echoes", 2, 0, "echo", "luminous_forest", -1, False, False, True, "barrier", "pull", []),
    ("3", "rooftop_wasp", 3, 0, "wasp", "neon_rooftop", 0, False, True, True, "throw", "choke", []),
    ("4", "ember_mine", 4, 0, "ember", "crystal_mine", 0, False, False, True, "heal", "freeze", []),
    ("5A", "sanctuary_wall", 5, 1, "bastion", "flooded_sanctuary", 0, False, False, True, "absorption", "", []),
    ("6A", "shadow", 6, 1, "shadow", "refinery_platform", 0, False, True, True, "focus", "", []),
    ("7A", "shadow_awakens", 7, 1, "awakened_shadow", "crystal_mine", 0, False, False, True, "pull", "", []),
    ("8A", "sovereign", 8, 1, "sovereign", "orbital_ring", 0, False, False, False, "", "", ["character:sovereign"]),
    ("★A", "eclipse_foretold", 9, 1, "foretold_eclipse", "flooded_sanctuary", 0, True, False, False, "", "", ["character:foretold_eclipse"]),
    ("5E", "reaper_test", 5, 2, "reaper", "orbital_ring", 0, False, False, True, "", "wrath", []),
    ("6E", "mirror_temple", 6, 2, "mirror", "flooded_sanctuary", 0, False, True, True, "", "drain", []),
    ("7E", "rooftop_heron", 7, 2, "heron", "neon_rooftop", 0, False, False, True, "", "repulse", []),
    ("8E", "elder", 8, 2, "elder", "luminous_forest", 0, False, False, False, "", "", ["character:elder"]),
    ("★E", "aurora_foretold", 9, 2, "foretold", "flooded_sanctuary", 0, True, False, False, "", "", ["character:foretold"]),
]
ENDINGS = [
    ("O Anel Silencia", "ring_silent", False, ["character:elder", "ending:any"]),
    ("O Herdeiro Volta", "heir_returns", True, ["character:elder", "ending:any", "ending:secret"]),
    ("A Floresta Cede", "forest_yields", False, ["character:sovereign", "ending:any"]),
    ("O Equilíbrio", "balance", True, ["character:sovereign", "ending:any", "ending:secret"]),
]


def table_rows(lines, start):
    rows = []
    i = start
    while i < len(lines) and not lines[i].startswith("|"):
        i += 1
    i += 2
    while i < len(lines) and lines[i].startswith("|"):
        cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
        rows.append(cells)
        i += 1
    return rows


def parse(text):
    lines = text.splitlines()
    encounters = {}
    endings = {}
    current = None
    for index, line in enumerate(lines):
        heading = re.match(r"^#### (\S+)\. (.+?) / (.+)$", line)
        if heading and heading.group(1) in [e[0] for e in ENCOUNTERS]:
            current = heading.group(1)
            encounters[current] = {"pt": heading.group(2), "en": heading.group(3), "before": [], "after": []}
            continue
        ending = re.match(r"^#### (.+?) / (.+?) \((\w+), (\w+)\)$", line)
        if ending:
            current = None
            endings[ending.group(1)] = {"pt": ending.group(1), "en": ending.group(2), "lines": table_rows(lines, index + 1)}
            continue
        if current and line.startswith("**Antes**"):
            encounters[current]["before"] = table_rows(lines, index + 1)
        elif current and line.startswith("**Depois**"):
            encounters[current]["after"] = table_rows(lines, index + 1)
    return encounters, endings


def speaker_of(cell):
    match = re.match(r"^(.+?)(?: \((Aurora|Eclipse)\))?$", cell)
    return SPEAKERS[match.group(1)], PATHS[match.group(2) or ""]


def write_encounter(spec, parsed, strings):
    label, eid, chapter, route, opponent, arena, ai, boss, milestone, points, power_a, power_e, unlocks = spec
    key = f"STORY_{eid.upper()}"
    strings.append((f"{key}_TITLE", parsed["pt"], parsed["en"]))
    out = ['[gd_resource type="Resource" script_class="EncounterData" format=3]', '',
           '[ext_resource type="Script" path="res://data/story/encounter_data.gd" id="1_encounter"]',
           '[ext_resource type="Script" path="res://data/story/dialogue_line.gd" id="2_line"]',
           f'[ext_resource type="Resource" path="res://data/arenas/{arena}.tres" id="3_arena"]', '']
    refs = {"before": [], "after": []}
    for part in ("before", "after"):
        for n, row in enumerate(parsed[part]):
            speaker, path = speaker_of(row[0])
            text_key = f"{key}_{part[0].upper()}{n + 1}"
            strings.append((text_key, row[1], row[2]))
            sub = f"{part}_{n}"
            out += [f'[sub_resource type="Resource" id="{sub}"]', 'script = ExtResource("2_line")', f'speaker = &"{speaker}"',
                    f'text_key = "{text_key}"', f'path = {path}', '']
            refs[part].append(f'SubResource("{sub}")')
    unlock_list = ", ".join(f'"{u}"' for u in unlocks)
    out += ['[resource]', 'script = ExtResource("1_encounter")', f'id = &"{eid}"', f'chapter = {chapter}', f'title_key = "{key}_TITLE"',
            f'route = {route}', f'opponent = &"{opponent}"', 'arena = ExtResource("3_arena")', f'ai_offset = {ai}',
            f'boss_ai = {"true" if boss else "false"}', f'milestone = {"true" if milestone else "false"}',
            f'awards_points = {"true" if points else "false"}', f'power_aurora = &"{power_a}"', f'power_eclipse = &"{power_e}"',
            f'unlocks = PackedStringArray({unlock_list})',
            f'before = Array[ExtResource("2_line")]([{", ".join(refs["before"])}])',
            f'after = Array[ExtResource("2_line")]([{", ".join(refs["after"])}])']
    with open(f"data/story/encounters/{eid}.tres", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")


def write_ending(spec, parsed, strings):
    pt_title, eid, secret, unlocks = spec
    key = f"ENDING_{eid.upper()}"
    strings.append((f"{key}_TITLE", parsed["pt"], parsed["en"]))
    keys = []
    for n, row in enumerate(parsed["lines"]):
        line_key = f"{key}_{n + 1}"
        strings.append((line_key, row[0], row[1]))
        keys.append(f'"{line_key}"')
    out = ['[gd_resource type="Resource" script_class="EndingData" format=3]', '',
           '[ext_resource type="Script" path="res://data/story/ending_data.gd" id="1_ending"]', '', '[resource]',
           'script = ExtResource("1_ending")', f'id = &"{eid}"', f'title_key = "{key}_TITLE"', f'secret = {"true" if secret else "false"}',
           f'lines = PackedStringArray({", ".join(keys)})', f'unlocks = PackedStringArray({", ".join(chr(34) + u + chr(34) for u in unlocks)})']
    with open(f"data/story/endings/{eid}.tres", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")


def write_campaign():
    by_route = {0: [], 1: [], 2: []}
    for spec in ENCOUNTERS:
        if not spec[0].startswith("★"):
            by_route[spec[3]].append(spec[1])
    lines = ['[gd_resource type="Resource" script_class="CampaignData" format=3]', '',
             '[ext_resource type="Script" path="res://data/story/campaign_data.gd" id="1_campaign"]',
             '[ext_resource type="Script" path="res://data/story/encounter_data.gd" id="2_encounter"]']
    ids = [spec[1] for spec in ENCOUNTERS]
    for eid in ids:
        lines.append(f'[ext_resource type="Resource" path="res://data/story/encounters/{eid}.tres" id="e_{eid}"]')
    for spec in ENDINGS:
        lines.append(f'[ext_resource type="Resource" path="res://data/story/endings/{spec[1]}.tres" id="n_{spec[1]}"]')

    def group(route):
        return "Array[ExtResource(\"2_encounter\")]([" + ", ".join(f'ExtResource("e_{e}")' for e in by_route[route]) + "])"

    lines += ['', '[resource]', 'script = ExtResource("1_campaign")', f'common = {group(0)}', f'aurora = {group(1)}', f'eclipse = {group(2)}',
              'aurora_secret = ExtResource("e_eclipse_foretold")', 'eclipse_secret = ExtResource("e_aurora_foretold")',
              'aurora_normal_ending = ExtResource("n_ring_silent")', 'aurora_secret_ending = ExtResource("n_heir_returns")',
              'eclipse_normal_ending = ExtResource("n_forest_yields")', 'eclipse_secret_ending = ExtResource("n_balance")']
    with open("data/story/campaign.tres", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


def generated(key):
    owned = tuple(f"STORY_{spec[1].upper()}_" for spec in ENCOUNTERS)
    return key.startswith("ENDING_") or key.startswith(owned)


def write_strings(strings):
    path = "localization/strings.csv"
    with open(path, encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle))
    kept = [row for row in rows if not (row and generated(row[0]))]
    buffer = io.StringIO()
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerows(kept + [list(s) for s in strings])
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(buffer.getvalue())


def main():
    with open("content/STORY.md", encoding="utf-8") as handle:
        encounters, endings = parse(handle.read())
    os.makedirs("data/story/encounters", exist_ok=True)
    os.makedirs("data/story/endings", exist_ok=True)
    strings = []
    for spec in ENCOUNTERS:
        write_encounter(spec, encounters[spec[0]], strings)
    for spec in ENDINGS:
        write_ending(spec, endings[spec[0]], strings)
    write_campaign()
    write_strings(strings)
    print(f"encounters: {len(ENCOUNTERS)}, endings: {len(ENDINGS)}, texts: {len(strings)}")


if __name__ == "__main__":
    main()
