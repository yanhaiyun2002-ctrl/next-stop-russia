"""Boundary audit for the approved DEV-only experiment, not a fun/retention test."""
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
base = "eede196"
protected = ["scripts/main.gd", "scripts/p1", "data", "project.godot", "scenes", "ui", "assets/p1r"]
subprocess.run(["git", "diff", "--exit-code", base, "--", *protected], cwd=root, check=True)
old = json.loads(subprocess.check_output(["git", "show", f"{base}:assets/art_registry.json"], cwd=root))
current = json.loads((root / "assets/art_registry.json").read_text(encoding="utf-8-sig"))
by_id = {item["assetId"]: item for item in current["assets"]}
assert len(by_id) == len(current["assets"])
assert all(by_id[item["assetId"]] == item for item in old["assets"])
new = [item for item in current["assets"] if item["assetId"].startswith("prototype.arrival_luggage.")]
assert len(new) == 6
assert all(item["sourceType"] == "PROJECT_ORIGINAL" and item["retentionStatus"] == "REVIEW_REQUIRED" and not item.get("permanentApproval") and not item.get("rendererKey") and item["activeProfiles"] == ["DEV_LUGGAGE_EXPERIMENT"] for item in new)
for name in ["model.gd", "view.gd"]:
    text = (root / "scripts/dev_tools/luggage_tidy" / name).read_text(encoding="utf-8")
    for token in ["P1Session", "P1SaveStore", "FileAccess", "DirAccess", "complete_organization", "advance_message"]:
        assert token not in text, f"unexpected production/save dependency: {name}/{token}"
output = root / "docs/evidence/arrival-luggage-prototype/scope-audit-12/scope_audit.json"
assert not output.exists(), "Keep earlier evidence"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({"status": "PASS", "baseline": base, "protectedPathsUnchanged": protected, "originalRegistryEntriesUnchanged": len(old["assets"]), "newDevReviewEntries": [item["assetId"] for item in new], "prototypeHasNoProductionOrFileAPIs": True, "note": "static boundary audit plus separate runtime hash checks; no owner gameplay acceptance"}, ensure_ascii=False, indent=2), encoding="utf-8")
print("LUGGAGE_SCOPE PASS: official Q02/quests/saves/scenes/data unchanged; 37 existing assets retained; 6 DEV review entries")
