# P1 美术制作、集成与保留指南

## P1-01R 生效的审批与双维度分类

负责人已批准 `candidate_organization_v02.png`、`candidate_story_v01.png`、`candidate_dormitory_v02.png` 作为 P1-01R 的视觉制作方向，可以继续制作并接入必要独立素材。此批准不等于每张概念拼板、每个人物细节或正式画风已永久定稿，不必重复询问已授予的方向许可。

`assets/art_registry.json` 是统一资产状态的权威登记。`assets/temp/p1_manifest.json` 保留 P1 旧字段，`docs/art-prep/p1-01r/candidate_manifest.json` 保留概念测量/哈希；两者按 assetId 引用权威登记，不能各自作出矛盾审批。

| 维度 | 值 | 含义 |
|---|---|---|
| `sourceType` | `EXISTING_PLACEHOLDER` | 既有 P0/P1 几何、测试美术、文字占位。 |
| `sourceType` | `AI_GENERATED` | 内置 imagegen 等实际生成的图；不自动代表 CC0 或排他权利。 |
| `sourceType` | `THIRD_PARTY` | 有具体作者、版本和许可依据的外部资源。 |
| `sourceType` | `PROJECT_ORIGINAL` | 项目自行绘制或程序化制作的美术/UI。 |
| `retentionStatus` | `MUST_REPLACE` | 明确必须替换；兼容 `TEMP_REPLACE_REQUIRED`。 |
| `retentionStatus` | `RETAIN_CANDIDATE` | 质量/方向/规格可接受，可接入且没有强制替换义务；仍可继续修改。 |
| `retentionStatus` | `FINAL_APPROVED` | 负责人最终视觉验收与必要使用条件检查均完成，可正式保留。 |
| `retentionStatus` | `REVIEW_REQUIRED` | 仍待审查，不得冒充最终美术或已完成工程核验。 |

来源与保留状态正交，禁止“AI 生成所以必须替换”或“旧代码中存在所以保留”。只有 FINAL_APPROVED 可设置 `permanentApproval=true`；其余为 false。旧 `status/replaceStatus` 字段继续存在，但只给 MUST_REPLACE 写 TEMP_REPLACE_REQUIRED；RETAIN_CANDIDATE 写 RETAIN_CANDIDATE / OPTIONAL_REPLACEMENT，不引入强制替换义务。

三张概念仍为 `AI_GENERATED + REVIEW_REQUIRED`、`visualApproval=APPROVED_FOR_P1R_DIRECTION`、`usedInGame=false`。后续生产的独立 PNG 通过实际尺寸/alpha/锚点/图层与本轮来源检查后，可标 `AI_GENERATED + RETAIN_CANDIDATE`。禁止把 RGB 拼板粗裁后称作合格透明资源；背景不烘焙对白、俄语标签、容量数字或按钮。

每项记录 assetId、path/paths、sourceType、retentionStatus、visualApproval、usedInGame/activeProfiles、sourceRecord、generationRecord（适用时）、author/licenseReview/commercialUseReview、dimensions、transparency、anchor、layers、module、replacementRequired、issues。未生成/未测的值留 null 并说明，不编造数据。保留期状态变更须同时更新引用兼容视图；登记不取代实际加载验证。

P1-01R 资源目录采用 `assets/p1r/<模块>/`；候选仍在文档 `.gdignore` 下。文件夹名称不表示资源必须替换。旧几何可保留作 DEV/P0 回归 fallback，但其视觉仍标 MUST_REPLACE 并写清使用范围；稳定投影、遮挡、存档与猫移动逻辑不是美术替换对象。

## 本阶段为什么需要 TEMP 美术

P0 的几何灰盒已经证明功能，但还不能评价故事节奏、找猫的“发现感”及整体游戏氛围。P1-01 允许用**少量统一风格、可替换的临时素材**替代一部分几何块，确保实际试玩不像测试控制台。此轮不是正式美术量产，也不得因为临时画得好就把它当作最终美术方向。

## 状态与产权限制

- 所有素材记录 `assetId`、独立 sourceType/retentionStatus、实际来源和使用范围；MUST_REPLACE 占位继续保留 `TEMP_REPLACE_REQUIRED` 兼容标记，不把该标记扩展到可保留生成图。
- 优先**原创的简单形状/切层**，其次是许可明确、适用于当前受控试玩分发方式的免费可用资源；未经制作人选择不要成批下载素材包。不得使用被否决 WorkBuddy 旧界面、代码或美术。
- 参考视频只是审美/交互方向参考，不允许复制画面、图层或其受保护角色形象。
- RELEASE 若仍有 MUST_REPLACE/REVIEW_REQUIRED 或未完成最终使用条件检查，必须阻止或明确标记 ART_PENDING；RETAIN_CANDIDATE 可在受控 PLAYTEST 使用且无强制替换义务，但不能冒充已完成最终发行审查。不使用来路不明的网络图片。
- 技术调试图形允许继续存在于 DEV；PLAYTEST 默认隐藏 QA 按钮和红色测试标记。

## P1-01 历史占位索引（状态以统一登记为准）

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

## 旧字段兼容示例（MUST_REPLACE 占位）

```json
{
  "assetId": "temp.home.bed",
  "revision": "p1-01-a",
  "status": "TEMP_REPLACE_REQUIRED",
  "sourceType": "EXISTING_PLACEHOLDER",
  "retentionStatus": "MUST_REPLACE",
  "visualApproval": "PLACEHOLDER_NOT_APPROVED_AS_FINAL",
  "replacementRequired": true,
  "source": "original_minimal_placeholder",
  "licenseNote": "project-owned placeholder; review before public distribution",
  "sceneBinding": "bed-primary",
  "layers": ["base", "front_occluder"],
  "approvedFor": "DEV",
  "permanentApproval": false
}
```

上述历史索引不意味着启动包已附带插画 PNG。P1-01R 只生产实际使用的小集合；实际图像、元数据和运行截图分别核验，不把计划当成已完成资产或已通过的游戏测试。
