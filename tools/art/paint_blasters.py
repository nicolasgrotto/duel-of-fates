import os

from fighter_parts import arsenal_parts, blaster_parts


def paint():
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    folder = os.path.join(root, "assets", "blasters")
    os.makedirs(folder, exist_ok=True)
    for long in (False, True):
        for part in blaster_parts(long):
            part.save(folder)
            print(part.name, part.pivot_pixels())
    for part in arsenal_parts():
        part.save(folder)
        print(part.name, part.pivot_pixels())


if __name__ == "__main__":
    paint()
