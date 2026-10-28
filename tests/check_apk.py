"""Static package inventory only; this does not execute Android code."""
import argparse
import json
import re
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("apk", type=Path)
parser.add_argument("--evidence", type=Path, required=True)
args = parser.parse_args()

with zipfile.ZipFile(args.apk) as archive:
    names = set(archive.namelist())
    required = [
        "assets/project.binary",
        "assets/scenes/main.tscn.remap",
        "assets/scenes/buildings/dormitory.tscn.remap",
        "assets/scenes/buildings/school.tscn.remap",
        "assets/data/buildings/shop.tres.remap",
        "assets/assets/p0_icon.svg.import",
        "lib/arm64-v8a/libgodot_android.so",
        "lib/x86_64/libgodot_android.so",
    ]
    checks = {name: name in names for name in required}
    icon_import = "assets/assets/p0_icon.svg.import"
    icon_target = ""
    if icon_import in names:
        # Imported textures use .import -> .ctex; scenes/resources use .remap.
        metadata = archive.read(icon_import).decode("utf-8")
        match = re.search(r'^path="res://([^"]+)"', metadata, re.MULTILINE)
        if match:
            icon_target = "assets/" + match.group(1)
    checks["icon_import_target_exists"] = bool(icon_target and icon_target in names)
    forbidden = [
        name for name in sorted(names)
        if any(part in name for part in (".tools/", "docs/", "android-debug.keystore"))
    ]
    result = {
        "required": checks,
        "icon_import_target": icon_target,
        "forbidden_paths": forbidden,
        "native_libraries": sorted(name for name in names if name.startswith("lib/") and name.endswith(".so")),
        "scope": "static inventory; not emulator/device execution",
    }

args.evidence.parent.mkdir(parents=True, exist_ok=True)
args.evidence.write_text(json.dumps(result, indent=2), encoding="utf-8")
passed = all(checks.values()) and not forbidden
print(f"APK_INVENTORY passed={passed}")
raise SystemExit(0 if passed else 1)
