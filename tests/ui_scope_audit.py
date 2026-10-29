"""P1-UI-01 scope guard: visual integration must not alter gameplay contracts."""
from pathlib import Path
import json,hashlib,re,subprocess,sys
from PIL import Image
root=Path(__file__).resolve().parents[1];base='a91f819'
out=root/sys.argv[1];out.mkdir(parents=True,exist_ok=False)
checks=[]
def old(path):return subprocess.check_output(['git','show',f'{base}:{path}'],cwd=root).decode('utf-8-sig').replace('\r\n','\n')
def now(path):return (root/path).read_text(encoding='utf-8-sig').replace('\r\n','\n')
def check(ok,name):checks.append({'name':name,'passed':bool(ok)})
def funcs(s):return {x.group(1):x.group(0) for x in re.finditer(r'^func (\w+)\([^\n]*\n.*?(?=^func |\Z)',s,re.M|re.S)}
for path in ['scripts/p1/session.gd','scripts/p1/save_store.gd','scripts/p1/luggage_tidy/model.gd','scripts/p1/cat_encounter.gd','scripts/p1/cat_visual.gd','scripts/p1/profile_catalog.gd','scripts/p1/runtime_mode.gd','scripts/dev_tools/module_preview.gd','scripts/dormitory/room_world.gd','scripts/dormitory/cat_hunt.gd','data/p1/content.json']:
 check(old(path)==now(path),'unchanged protected file '+path)
for path,allowed in [('scripts/p1/luggage_tidy/view.gd',{'setup','_label','_button','_layout'}),('scripts/dormitory/room_view.gd',{'_draw'}),('scripts/main.gd',{'_ready'}),('scripts/p1/home_controller.gd',{'setup','_side_button','_refresh'}),('scripts/p1/flow.gd',{'setup','refresh_map_entry','_screen','_layout_modal','_text','style_button','_dialogue_text','show_message'})]:
 a,b=funcs(old(path)),funcs(now(path))
 for name,body in a.items():
  if name not in allowed:check(b.get(name)==body,'unchanged behavior '+path+'::'+name)
 if path.endswith('room_view.gd'):check(a['_draw'][a['_draw'].index('\tfor command in commands:'):]==b['_draw'][b['_draw'].index('\tfor command in commands:'):],'occlusion/cat draw ordering unchanged')
 if path.endswith('home_controller.gd'):check(a['_refresh'].replace('右侧「整理」','点击「整理」')==b['_refresh'],'home refresh changes only placement hint text')
 if path.endswith('flow.gd'):check(a['show_message']==b['show_message'].replace('\t_add_stage("home.background", "")\n',''),'Q03 adds only visual backdrop')
 if path.endswith('luggage_tidy/view.gd'):
  check(b['_draw']==a['_draw'] and b['_draw_item']==a['_draw_item'],'Q02 objects/surface/feedback art and mechanics retained')
old_map=json.loads(old('data/city_map.json'));new_map=json.loads(now('data/city_map.json'))
check(old_map['locations'].keys()==new_map['locations'].keys(),'no added map location')
for key in old_map['locations']:
 item=dict(new_map['locations'][key]);item.pop('label',None);check(item==old_map['locations'][key],'original owner anchor/region '+key)
for path in ['docs/art-source/city_map/city_map.png','assets/city_map/st_petersburg.png']:
 check(hashlib.sha256((root/path).read_bytes()).hexdigest()=='87d6b549d76bca53738df9bdb0c22bb3b7dbbfcd7ba0a2e3bfbba2ecf4f90eaa','owner map immutable '+path)
candidate=root/'docs/art-prep/p1-ui-01/paper_panel_candidate.png';im=Image.open(candidate);im.load()
check(im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255),'generated candidate has real alpha, not fake checkerboard')
r=json.loads(now('assets/art_registry.json'));entries={e['assetId']:e for e in r['assets']}
check(not entries['ui01.paper_panel']['usedInGame'] and entries['ui01.paper_panel']['retentionStatus']=='REVIEW_REQUIRED','failed nine-slice candidate not presented as shipping art')
for aid in ['ui01.shared_theme','ui01.map_plaques','ui01.map_selection']:
 e=entries[aid];check(e['sourceType']=='PROJECT_ORIGINAL' and e['retentionStatus']=='RETAIN_CANDIDATE' and not e['permanentApproval'],'current UI approval '+aid)
check(not list((root/'assets').rglob('*.ttf')) and not list((root/'assets').rglob('*.ttc')) and not list((root/'assets').rglob('*.otf')),'no system font binary copied into assets')
failed=sum(not x['passed'] for x in checks)
result={'base':base,'passed':len(checks)-failed,'failed':failed,'checks':checks,'candidate':{'size':list(im.size),'mode':im.mode,'alphaRange':list(im.getchannel('A').getextrema())}}
(out/'scope_results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'UI_SCOPE passed={len(checks)-failed} failed={failed}')
sys.exit(bool(failed))
