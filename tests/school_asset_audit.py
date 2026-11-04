"""Read-only content/scope audit, with report output only in requested evidence."""
import hashlib
import json
import sys
import subprocess
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = "3d0e0f7fda640fd72dab3d0e30afb33bcc17441d"
checks = []

def check(ok, name):
    checks.append({"name": name, "passed": bool(ok)})

def old(path):
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT)

registry = json.loads((ROOT / "assets/art_registry.json").read_text(encoding="utf-8-sig"))
before = json.loads(old("assets/art_registry.json"))
entries = {a["assetId"]: a for a in registry["assets"]}
check(len(entries) == len(registry["assets"]), "unique art IDs")
for item in before["assets"]:
    check(entries[item["assetId"]] == item, "preserved existing asset " + item["assetId"])
for asset in registry["assets"]:
    if not asset["assetId"].startswith("school.v04."):
        continue
    path = ROOT / asset["path"]
    check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == asset["sha256"], "registered source " + path.name)
    check(asset["retentionStatus"] == "RETAIN_CANDIDATE" and not asset["permanentApproval"], "candidate not falsely final " + path.name)
    if path.suffix == ".png":
        with Image.open(path) as image:
            image.load()
            check(list(image.size) == asset["dimensions"]["pixels"], "actual dimensions " + path.name)
            if path.name in ['classroom_environment_v2.png','environment.png']:
                check('A' not in image.getbands() or image.getchannel('A').getextrema() == (255,255), "opaque independent environment " + path.name)
            else:
                check(image.mode == "RGBA" and image.getchannel("A").getextrema() == (0, 255), "real transparent alpha " + path.name)
        original = ROOT / "docs/reference/school_vocab_blackboard_v04/art/runtime" / path.name
        if original.exists():
            check(path.read_bytes() == original.read_bytes(), "user bitmap source unmodified " + path.name)
        else:
            check(asset['sourceType'] == 'AI_GENERATED' and (ROOT / asset['sourceRecord']['record']).is_file(), "generated layer has provenance " + path.name)

protected = ["data/city_map.json", "data/p1/content.json", "data/p1/organization_tutorial.json",
             "scripts/p1/session.gd", "scripts/p1/save_store.gd", "scripts/p1/runtime_mode.gd",
             "scripts/p1/profile_catalog.gd", "scripts/p1/flow.gd", "scripts/p1/cat_encounter.gd",
             "scripts/p1/home_controller.gd", "scripts/p1/luggage_tidy/model.gd",
             "scripts/p1/luggage_tidy/view.gd", "scripts/dormitory/cat_hunt.gd",
             "scripts/dormitory/room_world.gd", "assets/city_map/st_petersburg.png"]
for path in protected:
    check((ROOT/path).read_bytes().replace(b"\r\n", b"\n") == old(path).replace(b"\r\n", b"\n"), "unchanged protected " + path)
check(not list((ROOT/"assets/school").glob("*.tt*")), "no system font binaries distributed")
data = json.loads((ROOT/"data/school/vocabulary.json").read_text(encoding="utf-8-sig"))
check(len(data["lexemes"]) == 6 and all(w["audioRef"] is None for w in data["lexemes"]), "6 real sample words, no fake audio")
out = ROOT / sys.argv[1]
out.mkdir(parents=True, exist_ok=False)
failed = sum(not c["passed"] for c in checks)
(out/"asset_scope_results.json").write_text(json.dumps({"passed":len(checks)-failed,"failed":failed,"checks":checks}, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"SCHOOL_ASSET_SCOPE passed={len(checks)-failed} failed={failed}")
sys.exit(bool(failed))
