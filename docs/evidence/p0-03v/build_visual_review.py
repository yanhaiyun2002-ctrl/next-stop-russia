"""Assemble existing genuine viewport PNGs only. No crop, retouch or AI imagery."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, PngImagePlugin
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OLD = ROOT / "docs/evidence/p0-03/06_final_spatial_rendered"
NEW = HERE / "10_composition_rendered_delivery"
OUTPUT = HERE / "P0-03V_VISUAL_REVIEW.png"
result = json.loads((NEW / "composition_results.json").read_text(encoding="utf-8-sig"))
assert result["failed"] == 0 and result["display_server"] == "Windows"
manifest = json.loads((HERE / "original_manifest.json").read_text(encoding="utf-8-sig"))
for item in manifest["files"]:
    assert hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest() == item["sha256"], item["path"]
assert not OUTPUT.exists(), "Preserve previous deliverable; do not silently overwrite."

canvas = Image.new("RGB", (4080, 7520), "white")
draw = ImageDraw.Draw(canvas)
font_dir = Path("C:/Windows/Fonts")
sources = []
regions = []

def text(x, y, value, size=30, bold=False, width=3960):
    font = ImageFont.truetype(str(font_dir / ("msyhbd.ttc" if bold else "msyh.ttc")), size)
    assert draw.textlength(value, font=font) <= width, value
    draw.text((x, y), value, font=font, fill="#111111", anchor="lt")

def wrapped(x, y, value, width, size=29):
    font = ImageFont.truetype(str(font_dir / "msyh.ttc"), size)
    line = ""
    for ch in value:
        if draw.textlength(line + ch, font=font) > width and line:
            text(x, y, line, size, width=width)
            y += 40
            line = ""
        line += ch
    if line:
        text(x, y, line, size, width=width)
    return y + 40

def panel(directory, name, x, y, title, mode, note, old=False):
    phone = name.startswith("phone_") or "1080x1920" in name
    w, h = (960, 1900) if phone else (1960, 1390)
    target = (900, 1600) if phone else (1920, 1080)
    source = directory / name
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    picture = Image.open(source).convert("RGB")
    original_size = picture.size
    assert picture.width * target[1] == picture.height * target[0]
    if picture.size != target:
        picture = picture.resize(target, Image.Resampling.LANCZOS)
    draw.rectangle((x, y, x+w, y+h), outline="#999999", width=2)
    text(x+20, y+24, title, 40, True, w-40)
    text(x+20, y+80, mode, 28, width=w-40)
    status = "原版实图对照 / 未修改 / 视觉待验收" if old else "本轮真实渲染 / 自动检查通过 / 视觉待验收"
    text(x+20, y+123, status, 26, width=w-40)
    ix, iy = x+(w-target[0])//2, y+162
    canvas.paste(picture, (ix, iy))
    regions.append((ix, iy, picture))
    foot = y+(1784 if phone else 1264)
    text(x+20, foot, "原图："+name, 25, width=w-40)
    assert wrapped(x+20, foot+43, note, w-40) <= y+h-4
    sources.append({"path":str(source.relative_to(ROOT)).replace("\\", "/"), "sha256":source_hash,
                    "original":original_size, "placed":target, "position":[ix,iy]})

text(60, 45, "P0-03V  正视广角宿舍 · 构图与天花板验收", 70, True)
text(60, 146, "仅整理真实 Godot 截图｜原图比例与完整画面保留｜手机为 Windows 视口模拟，非真机", 33)
draw.line((60, 215, 4020, 215), fill="#999999", width=2)
text(60, 250, "01  PC 原版与比例候选：侧墙、前景和观察高度", 48, True)
panel(OLD, "room_auto_1920x1080.png", 60, 330, "原版 P0-03：无明确天花板", "PC 全景 / 1920×1080 / 眼高 1.55", "原房间 6.8×5.5×3.0；近处空墙与空地较多。", True)
panel(NEW, "pc_1920x1080_balanced_ceiling.png", 2060, 330, "适中候选：保留较多纵深", "PC 全景 / 1920×1080 / 眼高 1.40", "房间 6.4×5.5×2.8，视点距离 8；天花板明确可见。")
text(60, 1790, "02  PC 紧凑候选：明确天花板 / 弱化天花板", 48, True)
panel(NEW, "pc_1920x1080_compact_ceiling.png", 60, 1870, "紧凑 + 明确天花板（推荐候选）", "PC 全景 / 1920×1080 / 眼高 1.30", "房间 6.0×5.4×2.8，距离 12；统一墙顶接缝，减少空前景。")
panel(NEW, "pc_1920x1080_compact_soft.png", 2060, 1870, "同一房间 + 弱化天花板", "PC 全景 / 1920×1080 / 眼高 1.30", "降低上方取景范围与顶面反差；家具保持完整，包围感需负责人判断。")
text(60, 3330, "03  手机全房认知：原版 / A 全景优先 / B 先全景", 48, True)
panel(OLD, "room_overview_1080x1920.png", 60, 3410, "原版：手机全景", "竖屏模拟 / 1080×1920 / 全景", "旧全景偏小，调试区常驻；作为未修改的原始对照。", True)
panel(OLD, "room_auto_1080x1920.png", 1060, 3410, "原版：默认局部聚焦", "竖屏模拟 / 1080×1920 / 聚焦", "旧版进入即聚焦，两侧家具部分裁切。", True)
panel(NEW, "phone_1080x1920_A_ceiling_entry.png", 2060, 3410, "方案 A：全景优先", "竖屏模拟 / 1080×1920 / 明确顶面", "点选只查看，保留全房；需要时明确按聚焦。测试区已折叠。")
panel(NEW, "phone_1080x1920_B_ceiling_entry.png", 3060, 3410, "方案 B：先展示全房", "竖屏模拟 / 1080×1920 / 明确顶面", "进入时与 A 共用完整全景；点家具或名字后聚焦，常驻全景返回。")
text(60, 5380, "04  手机操作与天花板：B 局部聚焦 / A、B 弱化顶面", 48, True)
panel(NEW, "phone_1080x1920_B_focus_bed.png", 60, 5460, "方案 B：床聚焦", "竖屏模拟 / 1080×1920 / 局部", "局部操作有意放大，保留全景按钮；没有改变空间或遮挡数据。")
panel(NEW, "phone_1080x1920_B_focus_desk.png", 1060, 5460, "方案 B：书桌聚焦", "竖屏模拟 / 1080×1920 / 局部", "细桌腿仍不宜作为手指目标；具名按钮至少 48 逻辑单位。")
panel(NEW, "phone_1080x1920_A_soft_entry.png", 2060, 5460, "方案 A：弱化天花板", "竖屏模拟 / 1080×1920 / 全景", "与上方 A 明确顶面纵向对比：天花板仍在，显示比例更小。")
panel(NEW, "phone_1080x1920_B_soft_entry.png", 3060, 5460, "方案 B：弱化天花板", "竖屏模拟 / 1080×1920 / 全景", "与上方 B 明确顶面对比；A/B 的进入全景构图相同，操作策略不同。")
text(60, 7410, f"原始依据：p0-03/06_final_spatial_rendered + p0-03v/10_composition_rendered_delivery；构图测试 {result['passed']} 通过 / 0 失败。", 29)
text(60, 7462, "判读边界：原图完整保留；游戏取景本身允许裁空白边缘。无重绘、美化或 AI 替代图；视觉选择仍待负责人确认。", 29)
info = PngImagePlugin.PngInfo()
info.add_text("Title", "P0-03V_VISUAL_REVIEW")
info.add_text("Sources", json.dumps(sources, ensure_ascii=True))
canvas.save(OUTPUT, pnginfo=info, dpi=(300,300), optimize=True)
verified = Image.open(OUTPUT).convert("RGB")
for x, y, picture in regions:
    assert verified.crop((x,y,x+picture.width,y+picture.height)).tobytes() == picture.tobytes()
for item in sources:
    assert hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest() == item["sha256"]

# Independent exact PNG-color counts supplement sampled engine measurements.
metrics = []
for measurement in result["measurements"]:
    if measurement["framing"] != "overview":
        continue
    name = measurement["scene"]+".png"
    picture = Image.open(NEW / name).convert("RGB")
    color = (184,189,183) if measurement["ceiling_emphasis"] else (209,212,204)
    count = sum(n for n,c in picture.getcolors(picture.width*picture.height) if c == color)
    logical = next(c for c in result["screenshots"] if c["path"] == name)["logical"]
    lw, lh = [float(v.strip()) for v in logical.strip("()").split(",")]
    scale = min(picture.width/lw, picture.height/lh)
    cw, ch = [float(v.strip()) for v in measurement["canvas"].strip("()").split(",")]
    metrics.append({"scene":measurement["scene"],"exact_ceiling_color_pixels":count,
                    "ceiling_fraction_of_canvas":count/(cw*ch*scale*scale),
                    "furniture":measurement["furniture"]})
(HERE / "delivery_metrics.json").write_text(json.dumps({"png":str(OUTPUT.relative_to(ROOT)),"dimensions":canvas.size,
    "source_count":len(sources),"source_files_unchanged":True,"paste_verification":True,
    "exact_color_metrics":metrics,"sources":sources},ensure_ascii=False,indent=2),encoding="utf-8")
preview = canvas.copy()
preview.thumbnail((1632,3008), Image.Resampling.LANCZOS)
preview.save(ROOT / ".tools/p0-03v_review_preview.png")
print(json.dumps({"width":canvas.width,"height":canvas.height,"source_count":len(sources),"bytes":OUTPUT.stat().st_size}))
