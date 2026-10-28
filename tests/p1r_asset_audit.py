"""Audit actual P1R PNGs/registry and unchanged P1 story/save contracts."""
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = "0dd8274b2860596b1912a5c6f0e9dd3f04146940"


def baseline(path):
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT)


def run():
    registry = json.loads((ROOT / "assets/art_registry.json").read_text(encoding="utf-8-sig"))
    ids = [entry["assetId"] for entry in registry["assets"]]
    assert len(ids) == len(set(ids)), "duplicate assetId"
    keys = [a["rendererKey"] for a in registry["assets"] if a.get("rendererKey")]
    assert len(keys) == 15 and len(set(keys)) == 15
    measured = []
    for asset in registry["assets"]:
        assert asset["sourceType"] in registry["sourceTypes"]
        assert asset["retentionStatus"] in registry["retentionStatuses"]
        assert asset["permanentApproval"] is False
        if not asset.get("rendererKey"):
            continue
        path = ROOT / asset["path"]
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            size = list(image.size)
            alpha = list(image.getchannel("A").getextrema()) if "A" in image.getbands() else None
            if asset["rendererKey"] in ["cat", "story.anna", "story.admin"] or asset["rendererKey"].startswith("org."):
                assert alpha and alpha[0] == 0 and alpha[1] > 200
        assert asset["dimensions"]["pixels"] == size
        assert asset["usedInGame"] and asset["retentionStatus"] == "RETAIN_CANDIDATE"
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        measured.append({"assetId": asset["assetId"], "path": asset["path"], "pixels": size, "alpha": alpha, "sha256": digest})
    current = json.loads((ROOT / "data/p1/content.json").read_text(encoding="utf-8-sig"))
    old = json.loads(baseline("data/p1/content.json"))
    for now, before in zip(current["spots"], old["spots"]):
        now["labelOffset"] = before["labelOffset"]
    assert current == old, "story/content changed beyond furniture label anchors"
    for path in ["data/p1/organization_tutorial.json", "scripts/p1/session.gd", "scripts/p1/save_store.gd"]:
        assert (ROOT / path).read_bytes().replace(b"\r\n", b"\n") == baseline(path).replace(b"\r\n", b"\n"), path
    output = ROOT / "docs/evidence/p1-01r/asset_audit.json"
    output.write_text(json.dumps({"status": "PASS", "assets": measured, "checks": ["unique IDs/renderer keys", "PNG decode/real alpha", "actual dimensions", "AI retention/use flags", "story unchanged except label offsets", "session/save/tutorial unchanged"], "notChecked": ["final producer art approval", "full commercial rights review"]}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"P1R_ASSET_AUDIT PASS: {len(measured)} PNGs, story/save/tutorial contracts unchanged")


if __name__ == "__main__":
    run()
