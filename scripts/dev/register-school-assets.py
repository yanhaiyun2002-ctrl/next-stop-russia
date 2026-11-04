"""Register this user-provided handoff without changing existing asset entries."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "assets/art_registry.json"
registry = json.loads(REGISTRY.read_text(encoding="utf-8-sig"))
items = []
for path in sorted((ROOT / "assets/school").glob("*")):
    if path.suffix not in {".png", ".svg"}:
        continue
    raster = path.suffix == ".png"
    used = path.name.startswith("teacher_") or path.name in {
        "blackboard_empty_from_sheet.png", "blackboard_empty_scalable.svg", "classroom_backplate.svg"
    }
    if not used:
        continue
    pixels = None
    alpha = None
    if raster:
        with Image.open(path) as image:
            image.load()
            pixels = list(image.size)
            alpha = list(image.getchannel("A").getextrema()) if "A" in image.getbands() else None
    items.append({
        "assetId": "school.v04." + path.stem,
        "path": path.relative_to(ROOT).as_posix(),
        "sourceType": "AI_GENERATED" if raster else "PROJECT_ORIGINAL",
        "retentionStatus": "RETAIN_CANDIDATE",
        "status": "RETAIN_CANDIDATE",
        "replaceStatus": "OPTIONAL_REPLACEMENT",
        "permanentApproval": False,
        "replacementRequired": False,
        "visualApproval": "APPROVED_FOR_V04_IMPLEMENTATION_NOT_FINAL",
        "usedInGame": True,
        "activeProfiles": ["SCHOOL_V04", "DEV", "PLAYTEST"],
        "module": "school",
        "targetSlot": "SchoolThemePresenter/" + path.stem,
        "sourceRecord": {
            "type": "user_provided_school_zip",
            "sourcePath": "E:/俄语游戏/新/学校.zip",
            "handoffManifest": "docs/reference/school_vocab_blackboard_v04/art/ASSETS_MANIFEST.json",
            "author": "User handoff; individual source author not specified",
            "sourceDescription": "AI atlas crop" if raster else "Hand-authored vector fallback supplied with handoff",
            "modification": "Engine atlas region / common transparent canvas only; no bitmap pixels changed" if raster else (
                "Replaced unsupported SVG book pattern with explicit vector books for Godot import" if path.stem == "classroom_backplate" else "Unmodified"
            ),
        },
        "licenseNote": "User authorized implementation and controlled playtest; no claim of CC0, exclusivity or final commercial approval.",
        "commercialUseReview": "PENDING_FINAL_REVIEW",
        "dimensions": {"pixels": pixels, "measurementStatus": "PNG_DECODED" if raster else "ENGINE_SVG_IMPORT"},
        "transparency": {"alphaRange": alpha, "verified": raster},
        "anchorNormalized": [0.5, 0.0],
        "layers": ["teacher" if path.stem.startswith("teacher_") else "background"],
        "perspective": "flat_classroom_ui",
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "checkedOn": "2026-11-04",
        "issues": ["Not final producer/rights approval"] + (
            ["Contaminated alpha above frame is excluded by runtime AtlasTexture region [18,75,990,570]; source unchanged"]
            if path.stem == "blackboard_empty_from_sheet" else []
        ),
    })

existing = {item["assetId"]: item for item in registry["assets"]}
for item in items:
    existing[item["assetId"]] = item
registry["assets"] = list(existing.values())
REGISTRY.write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Registered {len(items)} school assets; previous asset entries preserved")
