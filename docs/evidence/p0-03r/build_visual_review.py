"""P0-03R: lossless placement / proportional downscale of genuine Godot PNGs."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, PngImagePlugin
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OLD = ROOT / "docs/evidence/p0-03v/10_composition_rendered_delivery"
NEW = HERE / "13_ribbon_rendered_delivery"
OUTPUT = HERE / "P0-03R_VISUAL_REVIEW.png"
result = json.loads((NEW / "ribbon_results.json").read_text(encoding="utf-8-sig"))
assert result["failed"] == 0 and result["display_server"] == "Windows"
manifest = json.loads((HERE / "original_manifest.json").read_text(encoding="utf-8-sig"))
for item in manifest["files"]:
    assert hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest() == item["sha256"], item["path"]
assert not OUTPUT.exists(), "Keep earlier delivery; choose a new output for another review."
captures = {c["path"]: c for c in result["screenshots"]}
for pair in [("occlusion_bed_front.png", "occlusion_bed_back.png"), ("desk_before_move.png", "desk_front_overlap.png")]:
    a,b = [captures[n] for n in pair]
    assert a["focus_x"] == b["focus_x"] and a["scale"] == b["scale"] and a["view_rect"] == b["view_rect"]

canvas = Image.new("RGB", (4080, 7010), "white")
draw = ImageDraw.Draw(canvas)
fonts = Path("C:/Windows/Fonts")
sources = []
regions = []

def text(x, y, value, size=30, bold=False, width=3960):
    f = ImageFont.truetype(str(fonts / ("msyhbd.ttc" if bold else "msyh.ttc")), size)
    assert draw.textlength(value, font=f) <= width, value
    draw.text((x,y), value, font=f, fill="#111111", anchor="lt")

def wrap(x,y,value,width,size=29):
    f = ImageFont.truetype(str(fonts / "msyh.ttc"),size)
    line=""
    for ch in value:
        if draw.textlength(line+ch,font=f)>width and line:
            text(x,y,line,size,width=width)
            y+=40
            line=""
        line+=ch
    if line:
        text(x,y,line,size,width=width)
    return y+40

def panel(directory,name,x,y,title,mode,note,old=False):
    phone = "1080x1920" in name
    w,h = (960,1900) if phone else (1960,1390)
    target = (900,1600) if phone else (1920,1080)
    source = directory / name
    sha = hashlib.sha256(source.read_bytes()).hexdigest()
    picture = Image.open(source).convert("RGB")
    original = picture.size
    assert picture.width*target[1] == picture.height*target[0]
    if picture.size != target:
        picture=picture.resize(target,Image.Resampling.LANCZOS)
    draw.rectangle((x,y,x+w,y+h),outline="#999999",width=2)
    text(x+20,y+24,title,40,True,w-40)
    text(x+20,y+80,mode,28,width=w-40)
    text(x+20,y+123,"V 原始实图 / 未修改 / 视觉对照" if old else "R 实际渲染 / 自动检查通过 / 视觉待验收",26,width=w-40)
    ix,iy=x+(w-target[0])//2,y+162
    canvas.paste(picture,(ix,iy));regions.append((ix,iy,picture))
    foot=y+(1784 if phone else 1264)
    text(x+20,foot,"原图："+name,25,width=w-40)
    assert wrap(x+20,foot+43,note,w-40)<=y+h-4
    sources.append({"path":source.relative_to(ROOT).as_posix(),"sha256":sha,"original":original,"placed":target,"position":[ix,iy]})

text(60,45,"P0-03R  横向连续宿舍 · 空间与手机浏览验收",70,True)
text(60,146,"全部来自真实 Godot 截图｜原比例、完整画面｜无美化、重绘或参考视频素材｜手机为桌面模拟",32)
draw.line((60,215,4020,215),fill="#999999",width=2)
text(60,250,"01  原 P0-03V 与新 R：完整盒子取景 → 横向连续室内",48,True)
panel(OLD,"pc_1920x1080_compact_ceiling.png",60,330,"原 P0-03V：紧凑全景","PC / 1920×1080 / 完整房间优先","V 基线原图；房间边界与侧墙完整纳入构图，作为未修改对照。",True)
panel(NEW,"pc_1920x1080_middle.png",2060,330,"新 R：较宽连续空间","PC / 1920×1080 / 默认取景","窗、墙面分区、顶梁与地面连续展开；床在左前、桌在中部、柜在右后。")
text(60,1790,"02  手机：V 全景对照 / 新 R 左侧、中部（默认）、右侧",48,True)
panel(OLD,"phone_1080x1920_B_ceiling_entry.png",60,1870,"原 V：进入先全景","竖屏模拟 / 1080×1920 / 全景","旧版将整间房缩入手机；作为手机尺度与留白的原始对照。",True)
panel(NEW,"phone_1080x1920_left.png",1060,1870,"新 R：左侧边界","竖屏模拟 / 1080×1920 / 横拖","左端床体完整可读，床前标记可见；到端点停止，不进入空白。")
panel(NEW,"phone_1080x1920_middle.png",2060,1870,"新 R：中部默认取景","竖屏模拟 / 1080×1920 / 横拖","进入即显示足够大的局部；点击只反馈名称，复位返回默认位置。")
panel(NEW,"phone_1080x1920_right.png",3060,1870,"新 R：右侧边界","竖屏模拟 / 1080×1920 / 横拖","同一空间、同一尺度；衣柜完整可读，床前标记留在左侧画外。")
text(60,3840,"03  新构图遮挡：同一 PC 镜头，标记移到床前 / 床后",48,True)
panel(NEW,"occlusion_bed_front.png",60,3920,"床前：标记可见","PC / 1920×1080 / 固定取景","标记位置 (-3.40, 0.85)；与后图保持同一镜头、尺度及家具位置。")
panel(NEW,"occlusion_bed_back.png",2060,3920,"床后：标记被遮住","PC / 1920×1080 / 固定取景","标记位置 (-3.40, 3.60)；床体正确遮挡，拾取不穿透。")
text(60,5380,"04  新构图换位：书桌在中部后槽位 / 左侧前槽位",48,True)
panel(NEW,"desk_before_move.png",60,5460,"换位前：书桌位于中部","PC / 1920×1080 / 固定取景","标记固定 (-2.00, 1.60)，书桌在 (0.00, 3.20)；保留前中后景。")
panel(NEW,"desk_front_overlap.png",2060,5460,"换位后：局部覆盖床与标记","PC / 1920×1080 / 固定取景","书桌移至 (-2.00, 0.25)，标记头部上缘被挡；腿间仍有可见部分。")
text(60,6900,f"测试依据：13_ribbon_rendered_delivery/ribbon_results.json，{result['passed']} 通过 / 0 失败；原始 V 截图哈希保持。",29)
text(60,6952,"判读边界：固定投影画布平移，无惯性或缩放；不是物理相机视差。Android 真机与真人触摸未验证，方案待负责人确认。",29)
info=PngImagePlugin.PngInfo()
info.add_text("Title","P0-03R_VISUAL_REVIEW")
info.add_text("Sources",json.dumps(sources,ensure_ascii=True))
canvas.save(OUTPUT,pnginfo=info,dpi=(300,300),optimize=True)
verified=Image.open(OUTPUT).convert("RGB")
for x,y,picture in regions:
    assert verified.crop((x,y,x+picture.width,y+picture.height)).tobytes()==picture.tobytes()
for item in sources:
    assert hashlib.sha256((ROOT/item["path"]).read_bytes()).hexdigest()==item["sha256"]
(HERE/"visual_review_manifest.json").write_text(json.dumps({"output":OUTPUT.relative_to(ROOT).as_posix(),"dimensions":canvas.size,"source_count":len(sources),"paste_verification":True,"source_files_unchanged":True,"sources":sources},ensure_ascii=False,indent=2),encoding="utf-8")
preview=canvas.copy();preview.thumbnail((1632,2804),Image.Resampling.LANCZOS)
preview.save(ROOT/".tools/p0-03r_review_preview.png")
print(json.dumps({"dimensions":canvas.size,"source_count":len(sources),"bytes":OUTPUT.stat().st_size}))
