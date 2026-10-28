# P1-01 临时美术制作、集成与替换指南

## 本阶段为什么需要 TEMP 美术

P0 的几何灰盒已经证明功能，但还不能评价故事节奏、找猫的“发现感”及整体游戏氛围。P1-01 允许用**少量统一风格、可替换的临时素材**替代一部分几何块，确保实际试玩不像测试控制台。此轮不是正式美术量产，也不得因为临时画得好就把它当作最终美术方向。

## 状态与产权限制

- 所有新临时素材记录 `TEMP_REPLACE_REQUIRED`、`assetId`、`source`（原创/生成/明确授权）、`licenseNote`、`targetSlot`、`replaceStatus`。
- 优先**原创的简单形状/切层**，其次是许可明确、适用于当前受控试玩分发方式的免费可用资源；未经制作人选择不要成批下载素材包。不得使用被否决 WorkBuddy 旧界面、代码或美术。
- 参考视频只是审美/交互方向参考，不允许复制画面、图层或其受保护角色形象。
- RELEASE 构建若仍有 TEMP 资源，必须阻止或明确标记 ART_PENDING；受控 PLAYTEST 也应核查资产使用许可。不使用来路不明的网络图片。
- 技术调试图形允许继续存在于 DEV；PLAYTEST 默认隐藏 QA 按钮和红色测试标记。

## 最小资产清单：P1-01（只做真正需要的）

| assetId（建议） | 目标 | 形式 / 关键分层 | 验收重点 |
|---|---|---|---|
| `temp.home.room_bg` | 宿舍横向背景 | 墙／顶／地／窗与门可分层，复用现有 RoomWorld 投影 | PC 宽屏、手机平移不露空白 |
| `temp.home.bed` | 床 | 前/后遮挡片或能被现有几何遮挡的临时图形 | 猫床下露头仍可点击 |
| `temp.home.desk` | 书桌 | 台面、腿、前后遮挡语义分离 | 桌下猫可发现且点击不穿透 |
| `temp.home.wardrobe` | 衣柜 | 基本门体/前景遮挡 | 柜旁/柜后标签与热点一致 |
| `temp.home.window` | 窗 | 固定建筑构件；窗旁藏点与遮挡线索 | 第四藏点的真实存在 |
| `temp.cat.siberian_placeholder` | 西伯利亚森林猫的临时轮廓 | 耳/头/身体/尾巴可单独变形或做帧；不要求正式毛发 | 能连续“跑/探头/出场/摸猫反馈” |
| `temp.npc.anna`、`temp.npc.admin` | 两位 NPC | 极简头像或剪影（可完全先用文字代替） | 人物身份区分、不强行定稿形象 |
| `temp.ui.dialogue`、`temp.ui.naming`、`temp.ui.organize` | 首段 UI | 复用统一字体/控件，含俄中混排及小屏安全区 | 真实玩家不用 debug 面板可玩 |
| `temp.org.item_set`、`temp.org.bin_set` | 一道整理教程 | 可区分物品、仓位与容量的简化图标/几何 | 规则可读性高于精美度 |
| `temp.ui.cat_feedback` | 找猫反馈 | 文字＋简单反馈帧/过渡，不做特效系统 | 位置提示与俄语行为对应 |

## 视觉一致性的最低要求（属于 TEMP 候选，不是最终选定风格）

- 维持横向连续室内和近正视/可微俯视的构图弹性；不要在角色/家具临时绘制时硬编码死透视方向。
- 暖而清楚的明度层级、家具与墙地对比明显、猫咪可见线索有足够对比；颜色和笔触以制作人实际试玩后选择为准。
- 场景不是整张无法切开的合成图：必要家具、猫、遮挡层和热点独立存在，替换不改对象/任务 ID。
- 小尺寸竖屏需要实际检查阅读字体及点击区域，禁止用手机截图视觉“差不多”代替交互验证。

## 可替换资产登记字段（可按现有工程结构落地）

```json
{
  "assetId": "temp.home.bed",
  "revision": "p1-01-a",
  "status": "TEMP_REPLACE_REQUIRED",
  "source": "original_minimal_placeholder",
  "licenseNote": "project-owned placeholder; review before public distribution",
  "sceneBinding": "bed-primary",
  "layers": ["base", "front_occluder"],
  "approvedFor": "DEV",
  "permanentApproval": false
}
```

资源清单是**计划和合同**，并非已经随本启动包附带这些插画 PNG。本包不会伪装成已完成的临时美术资产。Codex 在 P1-01 只实现能有效提升试玩可读性的最小集合，不必为表格每一项都绘制完整套图。
