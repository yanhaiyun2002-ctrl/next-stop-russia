"""Current integration scope/asset audit; historical prototype-only audit is superseded."""
from pathlib import Path
import hashlib,json,subprocess,sys
from PIL import Image
root=Path(__file__).resolve().parents[1]
out=root/sys.argv[1]
out.mkdir(parents=True,exist_ok=False)
checks=[]
def check(ok,name):checks.append({'name':name,'passed':bool(ok)})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
source=root/'docs/art-source/city_map/city_map.png'
runtime=root/'assets/city_map/st_petersburg.png'
marked=root/'docs/art-source/city_map/city_map_marked.png'
check(sha(source)=='87d6b549d76bca53738df9bdb0c22bb3b7dbbfcd7ba0a2e3bfbba2ecf4f90eaa','owner source unchanged from opening inspection')
check(sha(source)==sha(runtime),'runtime PNG is byte-identical copy; no original edits')
check(sha(marked)=='20e811df449267c9ebc2ea926bfb3fb4106437125c7e66bf151438ada6624418','owner ABC reference byte-identical copy, not runtime background')
measurements=[]
for p in [source,runtime,marked]:
 im=Image.open(p);im.load();measurements.append({'path':str(p.relative_to(root)),'pixels':list(im.size),'mode':im.mode,'format':im.format,'sha256':sha(p)})
check(measurements[0]['pixels']==[1952,1087] and measurements[0]['mode']=='RGB','actual source dimensions/mode recorded; not misreported RGBA')
reg=json.loads((root/'assets/art_registry.json').read_text(encoding='utf-8'))
check(len({e['assetId'] for e in reg['assets']})==len(reg['assets']),'asset IDs unique')
for e in reg['assets']:
 if e.get('usedInGame'):
  check((root/e['path']).is_file(),'active resource path exists '+e['assetId'])
  check(e.get('retentionStatus')!='FINAL_APPROVED' and not e.get('permanentApproval'),'no automatic final art approval '+e['assetId'])
 if e['assetId'].startswith('prototype.arrival_luggage.'):
  check(e['sourceType']=='PROJECT_ORIGINAL' and set(e['activeProfiles'])=={'DEV','PLAYTEST','RELEASE'} and e['module']=='q02_arrival_luggage_shared_runtime','shared procedural asset classification '+e['assetId'])
map_data=json.loads((root/'data/city_map.json').read_text(encoding='utf-8'))
check(set(map_data['locations'])=={'dormitory','school','shop'},'only existing stable location IDs')
for location in map_data['locations'].values():
 check(all(0<=x<=1952 and 0<=y<=1087 for x,y in location['points']),'texture-space polygon in original bounds')
for revision in ['78a792a','0c4af5c','cbf68e8','d2007bb','6f1f052']:
 check(subprocess.run(['git','merge-base','--is-ancestor',revision,'HEAD'],cwd=root).returncode==0,'retained ancestor '+revision)
for p in ['scripts/main.gd','scripts/p1/cat_encounter.gd','scripts/p1/home_controller.gd','scripts/p1/runtime_mode.gd','scripts/p1/profile_catalog.gd','data/p1/content.json','project.godot']:
 check(not subprocess.check_output(['git','diff','6f1f052','--',p],cwd=root),'unchanged protected logic/content '+p)
check(not (root/'scripts/dev_tools/luggage_tidy/model.gd').exists(),'no second experiment implementation')
failed=sum(not c['passed'] for c in checks)
result={'passed':len(checks)-failed,'failed':failed,'checks':checks,'measurements':measurements,'note':'static scope/PNG audit; actual gameplay and package results are separate evidence'}
(out/'scope_asset_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'INTEGRATION_ASSET_AUDIT passed={len(checks)-failed} failed={failed}')
sys.exit(bool(failed))
