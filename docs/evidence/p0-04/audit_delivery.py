"""Read-only source/baseline audit; save actual results for this milestone."""
from pathlib import Path
import hashlib
import json
import subprocess
import re

ROOT = Path(__file__).resolve().parents[3]
GIT = r"C:\Users\yyy\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe"
OUT = Path(__file__).parent
BASE = "130e8cade8a50ea876dcebb3e69adce68a83fe5a"

def git(*args):
    return subprocess.check_output([GIT, "-C", str(ROOT), *args])

def sha(data):
    return hashlib.sha256(data).hexdigest()

manifest = json.loads((OUT / "original_manifest.json").read_text(encoding="utf-8-sig"))
original = [{"path": r["path"], "unchanged": sha((ROOT / r["path"]).read_bytes()) == r["sha256"]} for r in manifest["files"]]
stable = ["project.godot", "scripts/main.gd", "scripts/map.gd", "scripts/building_room.gd", "ui/adaptive_layout.gd", "ui/map_board.gd", "ui/theme.tres", "scenes/main.tscn", "scenes/map.tscn", "tests/run_tests.gd", "tests/composition_tests.gd"]
stable += [str(p.relative_to(ROOT)).replace("\\", "/") for folder in ["data", "scenes/buildings", "scenes/dormitory"] for p in (ROOT / folder).rglob("*") if p.is_file()]
unchanged = [{"path": p, "unchanged": git("show", f"{BASE}:{p}") == (ROOT / p).read_bytes().replace(b"\r\n", b"\n")} for p in stable]
assert all(r["unchanged"] for r in original + unchanged)
old_assertions = []
for path in ["tests/dormitory_tests.gd", "tests/composition_tests.gd", "tests/ribbon_tests.gd", "tests/run_tests.gd"]:
    before = [s.strip() for s in git("show", f"{BASE}:{path}").decode("utf-8").splitlines() if "_check(" in s]
    after = [s.strip() for s in (ROOT / path).read_text(encoding="utf-8").splitlines() if "_check(" in s]
    old_assertions.append({"path": path, "assertion_lines": len(before), "all_assertions_unchanged": before == after})
assert all(r["all_assertions_unchanged"] for r in old_assertions)
probes = [".tools/probe.zip", ".godot/probe.cache", "builds/probe.exe", ".env", "export_credentials.cfg", "private.pem", "private.keystore", "docs/references/dorm_visual_reference.mp4"]
ignored = []
for path in probes:
    result = subprocess.run([GIT, "-C", str(ROOT), "check-ignore", "-q", path])
    ignored.append({"probe": path, "ignored": result.returncode == 0})
assert all(r["ignored"] for r in ignored)
tracked = git("ls-files", "-z").decode("utf-8").split("\0")
forbidden = [p for p in tracked if re.search(r"(^|/)(\.tools|\.godot|builds|\.aws|\.ssh)/|(^|/)\.env($|\.)|\.(pem|key|p12|pfx|jks|keystore)$|export_credentials\.cfg$", p)]
assert not forbidden
suspect = []
for folder in ["scripts", "ui", "data", "scenes", "tests"]:
    for path in (ROOT / folder).rglob("*"):
        if path.is_file() and path.suffix in [".gd", ".tscn", ".tres", ".ps1"]:
            content = path.read_text(encoding="utf-8-sig")
            if re.search(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|(?:ghp_|github_pat_)[A-Za-z0-9_]{25,}|AKIA[0-9A-Z]{16}", content):
                suspect.append(str(path.relative_to(ROOT)))
assert not suspect
suites = []
for path in sorted(OUT.rglob("*results.json")):
    report = json.loads(path.read_text(encoding="utf-8-sig"))
    if isinstance(report, dict):
        suites.append({"path": str(path.relative_to(ROOT)), "passed": report.get("passed"), "failed": report.get("failed"), "display": report.get("display_server")})
report = {"baseline": BASE, "original_R_evidence": original, "unchanged_core": unchanged, "old_assertions": old_assertions,
          "ignored_probes": ignored, "tracked_forbidden_paths": forbidden, "credential_pattern_findings": suspect,
          "remotes": git("remote", "-v").decode("utf-8"), "suites": suites,
          "scope": "No credential-pattern findings does not prove absence of every possible secret; no remote or copied legacy prototype used."}
(OUT / "final_source_audit.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"original_R_unchanged": len(original), "core_unchanged": len(unchanged), "old_assertion_suites": len(old_assertions), "ignored_probes": len(ignored), "secret_findings": len(suspect), "remotes": report["remotes"]}, ensure_ascii=False))
