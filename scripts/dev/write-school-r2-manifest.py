from pathlib import Path
import json, hashlib, re
root=Path(__file__).resolve().parents[2]
folder=root/'builds/school-v04-r2'
version=re.search(r'const VERSION := "([^"]+)"',(root/'scripts/school/build_info.gd').read_text(encoding='utf-8')).group(1)
builds=[]
for file in sorted(folder.glob('*')):
    if file.suffix in ['.exe','.pck']:
        builds.append({'name':file.name,'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
manifest={'version':version,'buildDate':'2026-11-04','kind':'controlled Windows playtest, not final art approval','files':builds}
(folder/'build_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
out=root/'docs/evidence/school-v04-r2'
out.mkdir(parents=True,exist_ok=True)
(out/'build_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(version, 'manifest files:',len(builds))
