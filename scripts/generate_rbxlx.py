#!/usr/bin/env python3
"""
generate_rbxlx.py
Reads the Rojo project layout from default.project.json and source files
under src/, then writes a CityLife.rbxlx that Roblox Studio can open directly.

Usage:
    python3 scripts/generate_rbxlx.py
Output:
    CityLife.rbxlx
"""

import json
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT        = Path(__file__).resolve().parent.parent
SRC         = ROOT / "src"
OUTPUT      = ROOT / "CityLife.rbxlx"
PROJECT     = ROOT / "default.project.json"

# ── Referent counter ──────────────────────────────────────────────────────────
_ref_counter = 0

def new_ref():
    global _ref_counter
    _ref_counter += 1
    return f"RBX{_ref_counter:08d}"

# ── XML helpers ───────────────────────────────────────────────────────────────
def item(parent, class_name):
    """Create an <Item> element and automatically attach an empty <Properties> child."""
    el = ET.SubElement(parent, "Item")
    el.set("class", class_name)
    el.set("referent", new_ref())
    ET.SubElement(el, "Properties")   # always present
    return el

def props(item_el):
    """Return the <Properties> child of an item element."""
    return item_el.find("Properties")

def prop_string(props_el, name, value):
    el = ET.SubElement(props_el, "string")
    el.set("name", name)
    el.text = str(value)
    return el

def prop_bool(props_el, name, value):
    el = ET.SubElement(props_el, "bool")
    el.set("name", name)
    el.text = "true" if value else "false"
    return el

def prop_int(props_el, name, value):
    el = ET.SubElement(props_el, "int")
    el.set("name", name)
    el.text = str(int(value))
    return el

def prop_protected_string(props_el, name, value):
    el = ET.SubElement(props_el, "ProtectedString")
    el.set("name", name)
    el.text = value
    return el

def prop_token(props_el, name, value):
    el = ET.SubElement(props_el, "token")
    el.set("name", name)
    el.text = str(value)
    return el

def prop_float(props_el, name, value):
    el = ET.SubElement(props_el, "float")
    el.set("name", name)
    el.text = str(float(value))
    return el

def prop_vector3(props_el, name, x, y, z):
    """Serialise a Vector3 property as used in Roblox RBXLX v4."""
    el = ET.SubElement(props_el, "Vector3")
    el.set("name", name)
    ET.SubElement(el, "X").text = str(float(x))
    ET.SubElement(el, "Y").text = str(float(y))
    ET.SubElement(el, "Z").text = str(float(z))
    return el

def prop_cframe(props_el, name, x, y, z):
    """Serialise an identity-rotation CoordinateFrame at (x, y, z)."""
    el = ET.SubElement(props_el, "CoordinateFrame")
    el.set("name", name)
    ET.SubElement(el, "X").text   = str(float(x))
    ET.SubElement(el, "Y").text   = str(float(y))
    ET.SubElement(el, "Z").text   = str(float(z))
    # Identity rotation matrix
    for tag, val in [("R00","1"),("R01","0"),("R02","0"),
                     ("R10","0"),("R11","1"),("R12","0"),
                     ("R20","0"),("R21","0"),("R22","1")]:
        ET.SubElement(el, tag).text = val
    return el

def prop_brickcolor(props_el, name, color_id):
    """BrickColor by numeric Roblox palette ID."""
    el = ET.SubElement(props_el, "BrickColor")
    el.set("name", name)
    el.text = str(int(color_id))
    return el

# ── Static geometry helpers ───────────────────────────────────────────────────
def make_static_part(parent_el, name, sx, sy, sz, cx, cy, cz,
                     brickcolor_id=37, material_token=1280,
                     transparency=0.0):
    """Add an Anchored, CanCollide Part with full geometry to the RBXLX.

    Default BrickColor 37 = Bright green; Material token 1280 = Grass.
    """
    it = item(parent_el, "Part")
    p  = props(it)
    prop_string(p,     "Name",        name)
    prop_bool(p,       "Anchored",    True)
    prop_bool(p,       "CanCollide",  True)
    prop_bool(p,       "CastShadow",  True)
    prop_vector3(p,    "Size",        sx, sy, sz)
    prop_cframe(p,     "CFrame",      cx, cy, cz)
    prop_brickcolor(p, "BrickColor",  brickcolor_id)
    prop_token(p,      "Material",    material_token)
    if transparency > 0:
        prop_float(p,  "Transparency", transparency)
    return it

def make_static_spawn(parent_el, cx=0, cy=1, cz=0):
    """Add a neutral SpawnLocation to the RBXLX so players always have
    somewhere to spawn regardless of whether CityBuilder has finished."""
    it = item(parent_el, "SpawnLocation")
    p  = props(it)
    prop_string(p,     "Name",                  "Spawn")
    prop_bool(p,       "Anchored",               True)
    prop_bool(p,       "CanCollide",             True)
    prop_bool(p,       "Neutral",                True)
    prop_int(p,        "Duration",               0)
    prop_bool(p,       "AllowTeamChangeOnTouch", False)
    prop_vector3(p,    "Size",                   20, 1, 20)
    prop_cframe(p,     "CFrame",                 cx, cy, cz)
    prop_brickcolor(p, "BrickColor",             37)   # Bright green
    prop_token(p,      "Material",               256)  # Plastic
    return it

# ── Read a Lua source file ────────────────────────────────────────────────────
def read_lua(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"  WARNING: Could not read {path}: {e}", file=sys.stderr)
        return f"-- Failed to read: {path}\n"

# ── Build a Script / LocalScript / ModuleScript item ─────────────────────────
def make_script(parent_el, name, source, script_type="Script", disabled=False):
    it = item(parent_el, script_type)
    p  = props(it)
    prop_string(p,           "Name",     name)
    prop_protected_string(p, "Source",   source)
    prop_bool(p,             "Disabled", disabled)
    # RunContext token: 0 = Legacy (default)
    if script_type == "Script":
        prop_token(p, "RunContext", 0)
    return it

# ── Build a Folder ────────────────────────────────────────────────────────────
def make_folder(parent_el, name):
    it = item(parent_el, "Folder")
    p  = props(it)
    prop_string(p, "Name", name)
    return it

# ── Recursively add scripts from a directory ──────────────────────────────────
def add_scripts_from_dir(parent_el, directory: Path, default_type="Script"):
    if not directory.exists():
        return
    for child in sorted(directory.iterdir()):
        if child.is_file():
            stem = child.stem
            suffix = child.suffix
            if suffix != ".lua":
                continue
            # Determine script type from filename suffix
            if stem.endswith(".server"):
                stype = "Script"
                name  = stem[:-len(".server")]
            elif stem.endswith(".client"):
                stype = "LocalScript"
                name  = stem[:-len(".client")]
            else:
                stype = "ModuleScript"
                name  = stem
            source = read_lua(child)
            make_script(parent_el, name, source, stype)
        elif child.is_dir():
            folder_el = make_folder(parent_el, child.name)
            add_scripts_from_dir(folder_el, child, default_type)

# ── Build the Roblox XML tree ─────────────────────────────────────────────────
def build_tree():
    root = ET.Element("roblox")
    root.set("xmlns:xmime", "http://www.w3.org/2005/05/xmlmime")
    root.set("xmlns:xsi",   "http://www.w3.org/2001/XMLSchema-instance")
    root.set("xsi:noNamespaceSchemaLocation", "http://www.roblox.com/roblox.xsd")
    root.set("version", "4")

    ET.SubElement(root, "Meta").set("name", "ExplicitAutoJoints")
    ET.SubElement(root, "External").text = "null"
    ET.SubElement(root, "External").text = "nil"

    dm = item(root, "DataModel")
    p  = props(dm)
    prop_string(p, "Name", "CityLife")

    # ── Workspace ──────────────────────────────────────────────────────────────
    ws = item(dm, "Workspace")
    pw = props(ws)
    prop_string(pw, "Name", "Workspace")
    prop_bool(pw,   "FilteringEnabled", True)
    prop_bool(pw,   "StreamingEnabled", False)
    # Keep fallen parts well below ground so the baseplate is never destroyed.
    prop_float(pw,  "FallenPartsDestroyHeight", -500.0)

    # ── Static baseplate – must exist BEFORE CityBuilder runs so players
    #    never fall through when they first join the game.
    #    BrickColor 37 = Bright green, Material 1280 = Grass.
    make_static_part(ws, "Baseplate",
                     sx=2048, sy=4,  sz=2048,
                     cx=0,    cy=-2, cz=0,
                     brickcolor_id=37, material_token=1280)

    # ── Static SpawnLocation – always present at map centre (0, 1, 0).
    #    CityBuilder will attach the welcome BillboardGui to it at runtime.
    make_static_spawn(ws, cx=0, cy=1, cz=0)

    # ── ServerScriptService ───────────────────────────────────────────────────
    sss = item(dm, "ServerScriptService")
    sss_props_el = props(sss)
    prop_string(sss_props_el, "Name", "ServerScriptService")

    sss_dir = SRC / "ServerScriptService"
    add_scripts_from_dir(sss, sss_dir, "Script")

    # ── ReplicatedStorage ─────────────────────────────────────────────────────
    rs_el = item(dm, "ReplicatedStorage")
    rs_props = rs_el.find("Properties")
    prop_string(rs_props, "Name", "ReplicatedStorage")

    rs_dir = SRC / "ReplicatedStorage"
    add_scripts_from_dir(rs_el, rs_dir, "ModuleScript")

    # ── StarterGui ────────────────────────────────────────────────────────────
    sg_el = item(dm, "StarterGui")
    sg_props = sg_el.find("Properties")
    prop_string(sg_props, "Name", "StarterGui")

    sg_dir = SRC / "StarterGui"
    add_scripts_from_dir(sg_el, sg_dir, "LocalScript")

    # ── StarterPlayer / StarterPlayerScripts ──────────────────────────────────
    sp_el = item(dm, "StarterPlayer")
    sp_props = sp_el.find("Properties")
    prop_string(sp_props, "Name", "StarterPlayer")

    sps_el = item(sp_el, "StarterPlayerScripts")
    sps_props = sps_el.find("Properties")
    prop_string(sps_props, "Name", "StarterPlayerScripts")

    sps_dir = SRC / "StarterPlayer" / "StarterPlayerScripts"
    add_scripts_from_dir(sps_el, sps_dir, "LocalScript")

    # ── Teams ─────────────────────────────────────────────────────────────────
    teams_el = item(dm, "Teams")
    te_props = teams_el.find("Properties")
    prop_string(te_props, "Name", "Teams")

    # ── Lighting ──────────────────────────────────────────────────────────────
    lt_el = item(dm, "Lighting")
    lt_props = lt_el.find("Properties")
    prop_string(lt_props,  "Name",          "Lighting")
    prop_bool(lt_props,    "GlobalShadows", True)
    prop_int(lt_props,     "ClockTime",     10)

    # Atmosphere
    atm = item(lt_el, "Atmosphere")
    atm_p = atm.find("Properties")
    prop_string(atm_p, "Name", "Atmosphere")

    return root

# ── Entry point ───────────────────────────────────────────────────────────────
# NOTE: requires Python 3.9+ for ET.indent().
def main():
    print(f"Generating {OUTPUT} ...")
    tree_root = build_tree()
    tree_obj = ET.ElementTree(tree_root)
    ET.indent(tree_obj, space="  ")  # Python 3.9+

    xml_bytes = ET.tostring(tree_root, encoding="unicode", xml_declaration=False)
    output_str = '<?xml version="1.0" encoding="utf-8"?>\n' + xml_bytes

    OUTPUT.write_text(output_str, encoding="utf-8")
    print(f"Done! Written to {OUTPUT}")
    print(f"Open CityLife.rbxlx in Roblox Studio to play.")

if __name__ == "__main__":
    main()
