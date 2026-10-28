"""Compose actual Godot evidence; never substitutes concept images for runtime."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

root = Path(__file__).resolve().parents[1]
pc = root / "docs/evidence/p1-01r/reference-final-pc-05"
phone = root / "docs/evidence/p1-01r/reference-final-phone-06"
out = root / "docs/reports/P1-01R_VISUAL_REVIEW.png"
font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 25)
small = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 18)
canvas = Image.new("RGB", (1600, 1970), "#e8e2d8")
draw = ImageDraw.Draw(canvas)
draw.text((30, 14), "P1-01R · 真实 Godot 运行画面 / PC 横屏与模拟手机竖屏", fill="#263b41", font=font)
draw.text((30, 53), "自动化合成输入；不是手机真机或真人试玩验收。生成素材为 RETAIN_CANDIDATE，旧家具几何仍待替换。", fill="#45534d", font=small)
sources = []
for index, (label, filename) in enumerate([
    ("Q00 开场 · 独立背景、人物与俄中对白", "02_arrival_anna.png"),
    ("宿舍 · 世界坐标家具标签与横向浏览", "spot_1280x720_under_bed.png"),
    ("首次整理 · 物品、容量格位与操作反馈", "06_organization.png"),
]):
    top = 108 + index * 615
    draw.text((30, top), label, fill="#263b41", font=font)
    mobile_name = "spot_360x780_under_bed.png" if index == 1 else filename
    for path, box, title in [
        (pc / filename, (30, top+42, 1080, top+604), "PC"),
        (phone / mobile_name, (1170, top+42, 1430, top+604), "模拟竖屏"),
    ]:
        original = Image.open(path).convert("RGB")
        image = ImageOps.contain(original, (box[2]-box[0], box[3]-box[1]), Image.Resampling.LANCZOS)
        canvas.paste(image, (box[0], box[1]))
        draw.text((1440 if title != "PC" else 1090, top+45), title, fill="#45534d", font=small)
        sources.append({"path": str(path.relative_to(root)).replace("\\", "/"), "originalPixels": list(original.size), "panel": label})
canvas.save(out)
(root / "docs/evidence/p1-01r/visual_review_sources.json").write_text(json.dumps({"output": str(out.relative_to(root)), "sources": sources, "operation": "fit/resize only; actual Godot images; no concept compositing"}, ensure_ascii=False, indent=2), encoding="utf-8")
print(out)
