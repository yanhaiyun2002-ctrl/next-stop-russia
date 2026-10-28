# 设计／美术／剧情 → Codex 最小交接合同

**目的：** 在 ChatGPT、Figma、人工设计、生成工具与 Codex 之间交换明确可实现的材料，不让 Codex 阅读漫长聊天或猜测设计。

单项交接建议放在 `docs/design/handoffs/<area>/<revision>/`，并含 `HANDOFF.md` 与相关资源；无需立刻建立所有空目录。

```text
Handoff ID: HOME-ART-001 / STORY-Q00-001 / CAT-ANIM-001 / UI-ORG-001
Revision: v1
Status: DRAFT | REVIEW | APPROVED | SUPERSEDED
Owner: 制作人/委托设计工具
Target: scene / gameplay / dialogue / art / ui
AppliesTo: 已存在场景/资源/按钮稳定 ID
Source: 链接或本地参考文件（不可凭空编造）
Assets: 相对文件路径 + assetId + 尺寸/图层/格式 + 许可
Bindings: 对象 ID、猫藏点、交互区域、z-order、动画锚点、移动镜头边界
Text: language / zh subtitle / dialogueId / speakerId
AllowedChange: 允许调整的视觉和反馈
LockedBehavior: 不能变的剧情/触发/奖励/数据规则
Acceptance: 可测条件 + PC 横屏／手机竖屏画面
OpenIssues: 待制作人确认的事项
```

**关键规则**：

1. `DRAFT`、`REVIEW` 不可直接宣称最终批准；当仅需试玩占位时必须标 `TEMP`，不阻断功能原型。
2. 设计图只是预览，不等于已拆分可交互图层。若需要遮挡和换家具，必须提供可替换图层/切片与场景锚点；没有就用临时原生几何而非猜造最终图层。
3. 正式文本/图片不可硬编码进渲染脚本；引用稳定 `assetId`、`dialogueId`、`spotId`、`roomObjectId`。
4. 素材参考和素材许可分开：网络图库/参考视频可以指导设计，但不可凭“参考”直接打包到试玩版。
5. Godot 工程的场景、资源、配置与原始设计素材分离；HUD 和手机视口可不同布局但同一业务含义。
6. 与 `docs/design/TEMP_ART_GUIDE.md` 配合使用：P1-01 的临时资产不需要先生成完整正式设计稿。
