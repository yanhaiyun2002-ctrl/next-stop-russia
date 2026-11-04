"""Build an offline review page from unedited references and actual game captures."""
from pathlib import Path
from html import escape
from urllib.parse import quote
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'docs/evidence/school-v04-r2'
OUT = EVIDENCE / 'visual-review'
OUT.mkdir(parents=True, exist_ok=True)
manifest = json.loads((EVIDENCE / 'build_manifest.json').read_text(encoding='utf-8'))

def url(path):
    import os
    return quote(os.path.relpath(path, OUT).replace('\\', '/'), safe='/')

def picture(path, caption):
    assert path.is_file(), path
    return f'<figure><figcaption>{escape(caption)}</figcaption><a href="{url(path)}" target="_blank"><img loading="lazy" src="{url(path)}" alt="{escape(caption)}"></a></figure>'

comparisons = [
    ('竖屏：学习准备', ROOT/'docs/reference/school_v04_portrait/preparation_reference.png', EVIDENCE/'final-portrait/02_preparation_selected.png',
     '已还原纵向三张模式卡、纸张木框、数量选择、学习计划、下方开始按钮和右下老师。数量来自六词示例的真实剩余量；参考图经济条与 10/20 档位没有伪造进度。图标、雕花和角色裁切仍有差异。'),
    ('竖屏：黑板四选一', ROOT/'docs/reference/school_v04_portrait/quiz_reference.png', EVIDENCE/'final-portrait/05_quiz_ready.png',
     '四行 A–D 为实际题目按钮，顶部进度、题型与提示均由运行状态生成。保留粉笔文字、绿黑板木框、右侧老师和底部三个功能按钮。原独立老师素材与背景道具细节并非参考原画的逐像素复刻。'),
    ('横屏：保留学习准备', ROOT/'docs/reference/school_v04_round2/reference/learning_preparation_reference.png', EVIDENCE/'final-integrated/02_preparation_selected.png',
     '横屏继续使用横向三模式卡、宽纸张框及右侧老师；本轮竖屏单独排版，不拉伸整张横屏界面。'),
    ('横屏：四选一同步', ROOT/'docs/reference/school_v04_round2/reference/blackboard_quiz_reference.png', EVIDENCE/'final-integrated/05_quiz_ready.png',
     '横屏同步四选一，采用 2×2 控件网格；竖屏采用纵向四行。横屏长反馈和词本可滚动。'),
]
sections = []
for title, reference, actual, note in comparisons:
    sections.append(f'<section><h2>{escape(title)}</h2><p>{escape(note)}</p><div class="pair">'+picture(reference,'参考图 · 非运行界面')+picture(actual,manifest['version']+' · 真实 Windows Godot 截图')+'</div></section>')

states = [
    ('01_preparation_unselected.png','准备页未选择'),('02_preparation_selected.png','准备页已选择'),
    ('03_preview_first.png','预习第一张'),('04_preview_last.png','预习末张'),
    ('05_quiz_ready.png','四选题待答'),('06_quiz_correct.png','正确反馈'),
    ('07_wrong.png','错误反馈'),('08_strengthen_1.png','强化已正确 1/2'),
    ('09_wrong_after_strengthen_1.png','强化再次出错，保留已正确次数'),
    ('10_results.png','第一轮 5 词结算'),('partial_10_results.png','剩余 1 词结算'),
    ('11_no_new_words.png','六词全部首学后的明确提示'),('12_notebook.png','实际词本'),
]
gallery = ''.join(picture(EVIDENCE/'final-portrait'/file,label) for file,label in states)
native = ''.join(picture(EVIDENCE/'native-windows'/file,label) for file,label in [
    ('06_quiz_ready.png','原生桌面点击 · 竖屏四选题（R2.2）'),
    ('08_results.png','原生桌面点击 · 竖屏结算（R2.2）'),
    ('integrated_01_map.png','原生桌面点击 · 地图进入学校（R2.2）'),
    ('integrated_09_results.png','原生桌面点击 · 主游戏学校结算（R2.2）'),
])
html = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>学校 V0.4 R2 · 参考与实际截图</title><style>
*{box-sizing:border-box}body{margin:0;background:#241b16;color:#f9edda;font:16px/1.7 system-ui,"Microsoft YaHei",sans-serif}main{max-width:1440px;margin:auto;padding:28px}h1{font-size:30px}h2{color:#efcc89}p{max-width:1100px}a{color:#efd399}section{margin:28px 0;padding:22px;border:1px solid #795b3d;border-radius:14px;background:#32251c}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0;min-width:0;background:#171310;padding:12px;border-radius:8px}figcaption{margin-bottom:12px;color:#e7d5b7}img{display:block;width:100%;height:auto}.pair img{max-height:1000px;object-fit:contain;object-position:top}.gallery{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.gallery figure{align-self:start}summary{cursor:pointer;font-weight:600;color:#efcc89}details{margin:22px 0;padding:16px;border:1px solid #795b3d;border-radius:12px}@media(max-width:760px){main{padding:14px}.pair,.gallery{grid-template-columns:1fr}section{padding:12px}h1{font-size:24px}}</style><main>
'''+f'<h1>学校 V0.4 · 第二轮修复与竖屏还原</h1><p>最终构建：<b>{escape(manifest["version"])}</b>，受控 PLAYTEST，等待负责人视觉验收。参考图只用于对照，未作为整张游戏界面。下面的最终截图直接来自 Windows 导出包；原 PNG 未修饰，网页仅按比例展示，点击可查看原图。</p>'+''.join(sections)+f'<details open><summary>最终构建：完整实际流程截图</summary><div class="gallery">{gallery}</div></details><details><summary>原生 Windows 桌面点击记录：字体修复前 R2.2 的两入口完整流程</summary><p>最终 R2.3 的包内完整鼠标流程另见 final-portrait 与 final-integrated；R2.2 原生记录保留以区分测试版本，不冒充最终包截图。</p><div class="gallery">{native}</div></details><p><a href="../../../reports/SCHOOL_V04_R2_FIX_REPORT.md">完整交付报告</a> · <a href="../test_summary.json">实际测试汇总</a> · <a href="../build_manifest.json">构建与 SHA256</a></p></main></html>'
(OUT/'index.html').write_text(html,encoding='utf-8')

cases = [
    ('学校领域规则','core-final/school_domain_tests/domain_results.json'),
    ('旧三选题存档兼容','core-final/school_fourchoice_compat/compat_results.json'),
    ('学校档位隔离','core-final/school_integration_tests/integration_results.json'),
    ('布局、安全区、触摸','ui-release/ui_results.json'),
    ('重音字体与按下/松开稳定性','font-input-final/stability_results.json'),
    ('素材与保护范围','asset-scope-delivery/asset_scope_results.json'),
    ('最终竖屏包实际 GUI 全流程','final-portrait/e2e_results.json'),
    ('最终整合包实际 GUI 学校流程','final-integrated/e2e_results.json'),
    ('最终整合包 Q00–Q03 实际流程','final-integrated/p1_package_results.json'),
]
rows = []
for label, relative in cases:
    file = EVIDENCE/relative
    data = json.loads(file.read_text(encoding='utf-8'))
    assert data['failed']==0,(label,data['failed'])
    rows.append({'name':label,'passed':data['passed'],'failed':data['failed'],'evidence':relative})
for suite, label, expected in [
    ('p1_domain_tests','原剧情领域',55),('p1_playable_tests','原剧情可玩性',168),
    ('p1_modes_tests','DEV/PLAYTEST/RELEASE',61),('luggage_prototype_tests','空间整理',53),
    ('cat_hunt_tests','猫咪',540),('run_tests','导航与输入',254),
]:
    file=EVIDENCE/'protected-regression-02'/suite/'test.log'
    content=file.read_text(encoding='utf-8')
    assert re.search(rf'passed={expected} failed=0',content),suite
    rows.append({'name':label,'passed':expected,'failed':0,'evidence':file.relative_to(EVIDENCE).as_posix()})
for folder in ['final-portrait','final-integrated']:
    tested=json.loads((EVIDENCE/folder/'tested_build_manifest.json').read_text(encoding='utf-8'))
    assert tested==manifest,'Tested build must match delivered build'
for file in manifest['files']:
    actual=ROOT/'builds/school-v04-r2'/file['name']
    assert hashlib.sha256(actual.read_bytes()).hexdigest()==file['sha256']
summary={'version':manifest['version'],'scope':'Windows GUI / engine tests; no physical Android or iOS acceptance','cases':rows,'visualReview':'visual-review/index.html','buildManifest':'build_manifest.json'}
(EVIDENCE/'test_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print('Review page:',OUT/'index.html','| verified result files:',len(rows))
