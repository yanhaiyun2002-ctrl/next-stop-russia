---
name: game-art-pipeline
description: 为《下一站，俄罗斯！》准备、筛选和交接可替换临时美术，核验素材授权、相机一致性与 Godot 资源规格；用于美术候选、视觉提案和经批准的素材接入，不修改玩法、剧情或存档合同。
---

# 项目临时美术流程

先读取根目录 AGENTS.md 与本轮用户授权，按需读 `docs/design/TEMP_ART_GUIDE.md`、`docs/design/DESIGN_HANDOFF_CONTRACT.md`、`docs/production/E_DRIVE_STORAGE_POLICY.md`。本轮候选记录见 `docs/reports/P1_ART_PREP_SUMMARY.md`，它不是正式画风规范。

## 选择与确认

- 从当前模块的实际物品/家具/NPC ID 出发，不为适配素材改变规则或新增剧情。整理沿用 `org_tutorial_01`、四物品及 2/2/1 容量；图形占用提示不增加新的旋转或格坐标存档。
- 先交少量视觉候选/布局，分别表现 PC 1280×720 与手机 360×780 的构图意图；生成的概念拼板不能冒充像素精确布局或实际 Godot 截图。
- 宿舍参考 JFIF 只用于空间与相机方向，先按真实格式查看。保留近正视、轻微俯视、家具纵深与横拖；不把俯视/等距家具图混入现有投影。家具、猫、遮挡与 UI 分层。
- 状态用 `CANDIDATE / REVIEW_PENDING`；临时美术持续标 `TEMP_REPLACE_REQUIRED`。负责人确认具体布局/候选后，才按该确认生产与接入素材；布局确认不等于正式画风批准。缺少确认时可做独立逻辑/资源接口，不替换场景。

## 取得素材

- 优先作者/官方发布页，分别核对免费档与付费档。记录 sourceUrl、author、license/URL、attribution、modification、commercialUse、format、perspective、module、checkedOn 和本地 license 文件/校验范围。标签与正文冲突、仅写“free”或授权不明时标 `LICENSE_REVIEW_PENDING`，不集成。
- 先看单件/预览，不批量下载图库。优先同风格套件；明确缺哪些物品，不把普通包伪称洗漱包、把武器包伪称现代生活图标全集。
- 需生成栅格插画时，读取当前可用官方 imagegen Skill，优先内置工具。没有工具或调用失败就如实记录；不自行开通付费 API、配置密钥或安装替代服务。
- 将参考角色区分为“空间参考”和“编辑目标”。不上传本项目参考图以复制其角色/家具。保存准确 prompt、调用方式、原始输出路径与缺陷；AI 输出不自动属于 CC0，也不保证独占权。
- 内置生成可能先写 `$CODEX_HOME/generated_images/`。项目引用的选中输出复制到 E 盘项目再交付，保留原件；不迁移认证/全局配置，不声称零 C 盘写入。

## 资源交接

候选先放 `docs/art-prep/<阶段>/`（文档 `.gdignore` 范围）；批准用于工程的独立资源才放 `assets/temp/<阶段>/<模块>/`。不覆盖旧版，文件名带版本，保留作者许可及修改记录。

工程资源以独立 PNG、sRGB、RGBA8 交接：物品/人物/家具/遮挡层真实透明，背景可全不透明；不使用伪透明棋盘格。SVG/PSD/ASE 可留作编辑源，不假称已是游戏 PNG。文字、容量数字、俄中字幕和家具标签由 Godot 控件绘制，不烘焙进最终素材。

每件至少记录以下字段；尺寸和锚点须取自实际文件/批准合同，不直接沿用概念图的任意裁切：

```json
{
  "assetId": "temp.p1r.organize.item.textbook",
  "status": "TEMP_REPLACE_REQUIRED",
  "approval": "REVIEW_PENDING",
  "sourceUrl": "builtin_generation_or_verified_author_url",
  "author": "actual_creator_or_builtin_generation",
  "licenseNote": "actual_terms_and_review_scope",
  "targetSlot": "org_tutorial_01/textbook",
  "pixelSize": [512, 256],
  "alpha": "real_rgba_required",
  "anchorNormalized": [0.5, 0.5],
  "layers": ["icon"],
  "perspective": "flat_inventory_icon",
  "permanentApproval": false
}
```

家具锚点对应稳定对象 ID 和房间坐标；前后遮挡层共用画布、缩放与接地点。猫用地面接触锚点与独立头/身体等图层。UI 用独立状态图或九宫格边框。最终尺寸/描边/配色/视点以负责人批准的交接为准。

## 核验与交付

候选期只核验来源、PNG 解码/实际尺寸/透明度、Skill 有效性及修改范围，不宣称游戏/拖放/平台测试通过。实际接入后再测标签随投影移动、猫线索不被挡、鼠标/触摸拖放与替代点击、横竖屏和既有 P0/P1 回归；记录失败，保留历史触摸风险。

遵守本轮单份汇总约定：报告链接到候选与原始证据，说明已测、未测、授权/审批待办和 Git 状态；不自动进入下一阶段。
