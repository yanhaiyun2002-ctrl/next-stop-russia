"""Measure and register selected R2 layers; source and retention are separate."""
from pathlib import Path
import hashlib, json
from PIL import Image
root=Path(__file__).resolve().parents[2]
path=root/'assets/art_registry.json'
registry=json.loads(path.read_text(encoding='utf-8-sig'))
existing={a['assetId']:a for a in registry['assets']}
for file in sorted([*(root/'assets/school/r2').iterdir(),*(root/'assets/school/portrait').iterdir()]):
    if file.suffix not in ['.png','.svg']: continue
    pixels=alpha=None
    if file.suffix=='.png':
        with Image.open(file) as im:
            im.load(); pixels=list(im.size)
            alpha=list(im.getchannel('A').getextrema()) if 'A' in im.getbands() else None
    mobile=file.parent.name=='portrait'
    aid='school.v04.'+('portrait.' if mobile else 'r2.')+file.stem
    existing[aid]={
        'assetId':aid,'path':file.relative_to(root).as_posix(),
        'sourceType':'AI_GENERATED' if file.suffix=='.png' else 'PROJECT_ORIGINAL',
        'retentionStatus':'RETAIN_CANDIDATE','status':'RETAIN_CANDIDATE',
        'replaceStatus':'OPTIONAL_REPLACEMENT','replacementRequired':False,
        'permanentApproval':False,'visualApproval':'APPROVED_R2_DIRECTION_NOT_FINAL',
        'usedInGame':True,'activeProfiles':['SCHOOL_V04_R2','PLAYTEST','DEV'],
        'module':'school','targetSlot':'SchoolStudyView/'+file.stem,
        'dimensions':{'pixels':pixels,'measurementStatus':'PNG_DECODED' if pixels else 'ENGINE_SVG_IMPORT'},
        'transparency':{'alphaRange':alpha,'requirement':'transparent outside frame' if file.stem in ['blackboard_clean_v2','preparation_parchment_v2'] else 'environment opaque / vector as authored'},
        'anchorNormalized':[.5,.5],'layers':['environment' if file.stem=='classroom_environment_v2' else 'independent_ui_frame'],
        'sourceRecord':{'type':'builtin_imagegen' if file.suffix=='.png' else 'project_vector_code',
                        'record':('docs/art-prep/school-v04-portrait/GENERATION_RECORD.json' if mobile else 'docs/art-prep/school-v04-r2/GENERATION_RECORD.json') if file.suffix=='.png' else 'scripts/dev/build-school-r2-vectors.py',
                        'author':'built-in image generation' if file.suffix=='.png' else 'project code',
                        'referenceUse':'empty board is an edit of the user-provided runtime board; other art generated from textual composition, no character uploaded'},
        'licenseNote':'Controlled implementation/playtest authorized; no CC0 or exclusive ownership claim. Final visual/use review pending.',
        'checkedOn':'2026-11-04','sha256':hashlib.sha256(file.read_bytes()).hexdigest(),
        'issues':['Final producer art approval pending; generated edges reviewed in actual composited game']
    }
old=existing.get('school.v04.classroom_backplate')
if old:
    old['usedInGame']=False
    old['activeProfiles']=['LEGACY_V04_R1']
    old['usageScope']='Superseded in current school renderer by R2 painted environment; retained for historical build provenance.'
for aid in ['school.v04.blackboard_empty_from_sheet','school.v04.blackboard_empty_scalable']:
    if aid in existing:
        existing[aid]['usageScope']='Missing-R2 fallback only; current R2 uses independent cleaned blackboard PNG.'
registry['assets']=list(existing.values())
path.write_text(json.dumps(registry,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Registered',sum(a.startswith('school.v04.r2.') for a in existing),'R2 layer assets; no final approval asserted')
