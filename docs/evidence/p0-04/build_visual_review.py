"""Arrange real Godot captures only; no crop, retouch or generated imagery."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "docs/evidence/p0-04/05_cat_independent_rendered"
OUTPUT = Path(__file__).parent / "P0-04_VISUAL_REVIEW.png"
FONT = "C:/Windows/Fonts/msyh.ttc"
BOLD = "C:/Windows/Fonts/msyhbd.ttc"

def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

canvas = Image.new("RGB", (3960, 4590), "#f5f6f7")
draw = ImageDraw.Draw(canvas)
draw.text((40, 28), "《下一站，俄罗斯！》P0-04 找猫与情境俄语 · 视觉验收", font=font(54, True), fill="#18232d")
draw.text((40, 108), "真实 Godot 4.7.2 / Compatibility 画面｜三藏点、可见遮挡、找到反馈｜2026-10-29", font=font(30), fill="#36434d")
draw.text((40, 158), "PC 保留原始 1920×1080；竖屏 1080×1920 等比至 900×1600。全部完整画面，无裁切、重绘或美化。", font=font(28), fill="#36434d")
records = []

def panel(name, x, y, size, title, status):
    path = SOURCE / (name + ".png")
    original = Image.open(path).convert("RGB")
    state = next(s for s in results["cat_states"] if s["scene"] == name)
    assert original.width * size[1] == original.height * size[0], "aspect ratio must match"
    image = original if original.size == size else original.resize(size, Image.Resampling.LANCZOS)
    draw.text((x, y), title, font=font(32, True), fill="#18232d")
    draw.text((x, y + 46), status, font=font(25), fill="#3d4b55")
    at = (x, y + 90)
    canvas.paste(image, at)
    # Verify the assembled content exactly equals the intended whole-frame copy.
    box = (at[0], at[1], at[0] + size[0], at[1] + size[1])
    assert canvas.crop(box).tobytes() == image.tobytes()
    records.append({"source": str(path.relative_to(ROOT)), "sha256": sha(path),
                    "source_size": original.size, "placed_size": size, "placed_at": at,
                    "whole_frame": True, "aspect_ratio_preserved": True,
                    "pixel_copy_verified": True, "state": state})

results = json.loads((SOURCE / "cat_hunt_results.json").read_text(encoding="utf-8"))
assert results["failed"] == 0 and results["display_server"] == "Windows"
panel("pc_1920x1080_under_bed_hint", 40, 230, (1920, 1080),
      "PC 横屏｜床下藏点 · 提示后，尚未找到", "测试通过：床遮住部分猫身，露出猫头可点；点床不穿透。")
panel("pc_1920x1080_under_desk_hint", 2000, 230, (1920, 1080),
      "PC 横屏｜书桌下藏点 · 提示后，尚未找到", "测试通过：桌腿与猫同一空间深度；俄语对应桌下位置。")
panel("pc_1920x1080_by_wardrobe_hint", 40, 1450, (1920, 1080),
      "PC 横屏｜衣柜旁藏点 · 提示后，尚未找到", "测试通过：第三处有效藏点；同一房间数据与有界浏览。")
panel("pc_1920x1080_by_wardrobe_found", 2000, 1450, (1920, 1080),
      "PC 横屏｜衣柜旁 · 找到后", "测试通过：Вот кот! 与位置对应；再找一次排除上一藏点。")
draw.text((40, 2660), "手机竖屏取景 · 同一空间、同一遮挡逻辑，提示位于房间画布外", font=font(38, True), fill="#18232d")
phone_panels = [
    ("under_bed_hint", "左侧｜床下 · 提示", "通过：露出猫头可触摸"),
    ("under_desk_hint", "中部｜桌下 · 提示", "通过：横拖不误判找到"),
    ("by_wardrobe_hint", "右侧｜柜旁 · 提示", "通过：藏点与俄语一致"),
    ("under_desk_found", "中部｜桌下 · 找到", "通过：明确反馈与再找入口"),
]
for i, (suffix, title, status) in enumerate(phone_panels):
    panel("phone_1080x1920_" + suffix, 40 + i * 980, 2730, (900, 1600), title, status)
draw.text((40, 4470), "测试说明：Windows 真实渲染 + 合成鼠标/触摸；非 Android 真机、非真人试玩结论。", font=font(29), fill="#36434d")
draw.text((40, 4520), "独立复测 633/0；首轮 9 项合成触摸失败及未定位原因详见汇总报告。原始截图与日志保留于项目。", font=font(27), fill="#36434d")
for record in records:
    content = Image.open(ROOT / record["source"]).convert("RGB")
    size = tuple(record["placed_size"])
    if content.size != size:
        content = content.resize(size, Image.Resampling.LANCZOS)
    x, y = record["placed_at"]
    assert canvas.crop((x, y, x + size[0], y + size[1])).tobytes() == content.tobytes(), "labels must never cover screenshot pixels"
canvas.save(OUTPUT)
manifest = {"output": OUTPUT.name, "size": canvas.size, "sha256": sha(OUTPUT), "source_suite_passed": results["passed"],
            "source_suite_failed": results["failed"], "panels": records,
            "method": "Pillow whole-frame paste / proportional downscale only; labels outside captures"}
(Path(__file__).parent / "visual_review_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
preview = ROOT / ".tools/p0-04_visual_preview.jpg"
canvas.resize((1320, 1530), Image.Resampling.LANCZOS).save(preview, quality=94)
print(json.dumps({"output": str(OUTPUT), "size": canvas.size, "bytes": OUTPUT.stat().st_size, "panels": len(records)}, ensure_ascii=False))
