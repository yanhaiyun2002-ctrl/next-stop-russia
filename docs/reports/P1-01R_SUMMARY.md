# P1-01R 首个可玩版本视觉与交互整改汇总

日期：2026-10-29。状态：可试玩候选已交付，等待负责人实际试玩及视觉验收。授权范围仍为 Q00～Q03；未进入 Q04／Q05。

## 实现结果与可玩流程

本轮在唯一正式主工程增量整改，保留 Godot 4.7.2 Stable／GDScript／Compatibility。没有重建项目，没有改变正式台词、整理题目、主线完成条件或存档结构。机器审计确认 `session.gd`、`save_store.gd`、`organization_tutorial.json` 与基线相同；`content.json` 只有家具标签的空间偏移发生语义变化。

每次启动先进入城市地图；继续按钮按已有存档明确指向抵达引导、找猫、必做命名、首次整理或安娜消息。启动本身不推进任务或清空存档。学校和其他地点仍执行原门禁，命名和教程不能通过地图跳过。Q03 解锁后，学校仍是原技术场景；未制作正式六入口地图和大学任务。

| 主线 | 本轮结果 |
| --- | --- |
| Q00 抵达、安娜、管理员领钥匙 | 独立背景与人物覆盖场景，俄语主对白＋中文字幕；按负责人新参考采用底部暖色俄语框和浅蓝中文框，继续键独立；手机人物居中避免脸部裁切。领钥匙后清晰进入宿舍。 |
| Q01 首遇猫、摸猫、命名 | 保留原四藏点、逃跑／探头／走出路径、摸猫反馈和奖励去重。猫图像接入现有深度排序；透明区域不抢家具点击。首次命名和自由重玩继续区分。 |
| Q02 首次整理 | 四物品独立 PNG，皮箱区域 A／B／C、容量 2／2／1 和虚线格位；PC 左托盘、右侧箱子，手机箱子上下排、托盘 2×2。鼠标和合成触摸拖动有跟随图像、合法预览／吸附、非法保留原位；已放物品可再拖，支持撤销、重置、确认和点选替代。退出保留合法摆放。 |
| Q03 安娜消息、城市解锁 | 沿用原两条俄中消息、阅读进度、解锁事件和保存；对白也使用统一双层框。 |

整理仍使用 `org_tutorial_01` 的容量、合法仓位和逻辑约束判题，不比较图片或唯一答案数组；本题原数据确有一组解，未擅自扩为每日题库、自由旋转拼图或新增奖励系统。

## 最新三图反馈的落实

负责人补充要求“整理玩法、页面 UI 和对话框像图中这样”。已将原表单式绿色矩形区域改为三个独立皮箱图层，暖纸托盘、金色选择边框、虚线槽、半透明拖动图像和圆角操作按钮；将小型剧情卡改为大场景＋人物＋底部俄中双框。宿舍正常玩家 UI 增加左右浏览箭头和同系按钮，原技术测试控件继续保留在 P0／DEV。

原图上的 `CANDIDATE / TEMP_REPLACE_REQUIRED` 是历史概念拼板文字，没有烘焙进工程 UI，也不覆盖负责人最新双维度保留规则。整理附件与早期 v02 拼板是不同文件，已单独保留为布局参考；另外两附件与已有剧情／宿舍概念哈希相同，未重复拷贝。参考仅指导操作和构图，不据其中环境改写剧情发生地。

## 宿舍空间与摄像机

`docs/references/dorm_layout_camera_reference.jfif` 继续仅作空间与镜头参考，不作为游戏贴图。采用原已验证房间坐标、投影、横向浏览和家具遮挡；没有重写猫咪移动、导航或空间系统。床、桌、衣柜、窗的标签锚在家具表面空间位置，跟随镜头与屏幕变化，首次俄中同显，重玩俄语为主并可查释义。

背景、木纹、织物和猫图像已接入；床、桌、衣柜及窗台仍使用部分旧几何外形。**当前宿舍没有达到概念图完整家具造型与装饰密度**，不能把材质贴上几何盒体描述为正式家具美术已完成。这部分明确列为 MUST_REPLACE／后续视觉工作，玩法和遮挡保持可回归。

## 实际测试与证据

| 验证 | 结果 | 原始证据目录（工程内） |
| --- | --- | --- |
| P1 领域、保存失败回滚等 | 59／0 | `docs/evidence/p1-01r/reference-final-pc-05/domain_results.json` |
| 新参考布局后 PC 全流程与真实渲染合成输入 | 194／0 | `docs/evidence/p1-01r/reference-final-pc-05/` |
| 新参考布局后模拟手机竖屏全流程 | 194／0 | `docs/evidence/p1-01r/reference-final-phone-06/` |
| 整理独立交互与最终皮箱布局（Headless） | 86／0 | `docs/evidence/p1-01r/organization-luggage-layout-final/` |
| P0 导航与横竖屏渲染 | 268／0 | `docs/evidence/p1-01r/p0-navigation-01/` |
| P0 宿舍空间、遮挡与输入渲染 | 252／0 | `docs/evidence/p1-01r/p0-dormitory-01/` |
| P0 构图渲染 | 684／0 | `docs/evidence/p1-01r/p0-composition-01/` |
| P0 横向浏览渲染 | 443／0 | `docs/evidence/p1-01r/p0-ribbon-01/` |
| P0 自由找猫渲染 | 633／0 | `docs/evidence/p1-01r/p0-cat-01/` |
| Windows Release 独立 EXE 实际运行 | 12／0 | `docs/evidence/p1-01r/windows-reference-final-02/` |
| 15 PNG 真实解码／alpha／尺寸、登记、剧情和存档合同审计 | PASS | `docs/evidence/p1-01r/asset_audit.json`、`asset_measurements.json` |

主流程新增验证真实剧情 ScrollContainer 内鼠标拖放、触摸拖放、撤销、重置、空格位点选、已放物品重拖非法目标和滚动取消；继续覆盖四藏点横竖屏、标签横拖、20 次摸猫、随机重玩、命名前／摸猫前重启、奖励去重、城市门禁和返回。

QA 曾发现“只能点击箱标题”和“滚动后拖放状态悬挂”两问题，已分别补齐箱体空白输入及全局几何／ScrollContainer 滚动变化取消。独立测试也使用真实滚轮事件和祖先位移验证。首轮 `organization-independent-01` 的 63／2、后续两轮新增测试解析错误等失败证据全部保留；没有挑选通过结果覆盖失败。领域日志中 `file_instead_of_directory` 的 ERROR 是原有写入失败注入用例，59／0 包含对应回滚断言。

修改前的 `integrated-*`、`final-pc-03`、`final-phone-04`、`windows-final-01` 保留为历史证据，不能冒充最新界面截图。`reference-layout-preview-*` 是显式视觉 fixture；它们不属于保存／剧情验收，首个预览启动曾因日志目录尚未建立而无法写日志，后续预览已正确建目录。最终展示取自上述完整流程渲染。

真实人工试玩、本轮 Android 真机、Android 导出和 Apple 平台测试未执行。PC 自动化与 Windows 独立程序运行均不等同真人或手机验收。P0 偶发合成触摸风险仍开放；本轮通过没有证明根因已修复，也没有以更改测试环境宣称修复。

## 美术资源来源与保留清单

统一权威登记为 `assets/art_registry.json`，运行时由 rendererKey 查询路径；旧 `assets/temp/p1_manifest.json` 与 `docs/art-prep/p1-01r/candidate_manifest.json` 保留有用信息并引用权威登记，未建立另一套矛盾加载表。共 37 条：15 MUST_REPLACE、18 RETAIN_CANDIDATE（15 AI＋3 原创 UI）、4 REVIEW_REQUIRED，0 FINAL_APPROVED。全部 `permanentApproval=false`。

生成工具为官方内置 `image_gen.imagegen`；完整提示词、原始输出路径及参考关系保存在 `docs/production/p1r_generation_records.json` 和统一登记中。15 个工程 PNG 与原生成文件哈希一致，未从概念拼板粗切冒充独立透明素材。A／C 箱体仅参考本轮独立生成的 B 箱体。透明物品、人物、猫和容器实际有 alpha；背景与材质允许 RGB 不透明。字幕、容量、格位和按钮均由代码绘制。

下表路径均相对项目根目录。详细尺寸、锚点、图层、使用范围、alpha、哈希和待改问题见登记表。

### 1. 仍使用的必须替换占位（含技术模式／缺图回退）

| assetId | 文件路径 | 状态／使用范围 |
| --- | --- | --- |
| `temp.home.room_bg` | `scripts/dormitory/room_view.gd` | MUST_REPLACE；DEV_TECHNICAL、MISSING_ART_FALLBACK |
| `temp.home.bed` | `scenes/dormitory/bed.tscn` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |
| `temp.home.desk` | `scenes/dormitory/desk.tscn` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |
| `temp.home.wardrobe` | `scenes/dormitory/wardrobe.tscn` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |
| `temp.home.window` | `scripts/dormitory/room_view.gd` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |
| `temp.cat.siberian_placeholder` | `scripts/dormitory/cat_placeholder.gd` | MUST_REPLACE；DEV_TECHNICAL、MISSING_ART_FALLBACK |
| `temp.reward.first_meeting` | `scripts/p1/flow.gd` | MUST_REPLACE；PLAYTEST_P1R、DEV_P1R |
| `placeholder.map.city` | `scripts/map.gd` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |
| `placeholder.app_icon` | `assets/p0_icon.svg` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |
| `placeholder.debug.marker` | `scripts/dormitory/room_view.gd` | MUST_REPLACE；DEV_TECHNICAL |
| `placeholder.school.tech_room` | `scripts/building_room.gd` | MUST_REPLACE；DEV_TECHNICAL、PLAYTEST_P1R |

### 2. 已接入、可长期保留的 AI 生成候选

| assetId | 文件路径 | 状态／使用范围 |
| --- | --- | --- |
| `p1r.organization.textbook` | `assets/p1r/organization/textbook.png` | AI_GENERATED / RETAIN_CANDIDATE；1536×1024 |
| `p1r.organization.passport` | `assets/p1r/organization/passport.png` | AI_GENERATED / RETAIN_CANDIDATE；1236×1273 |
| `p1r.organization.scarf` | `assets/p1r/organization/scarf.png` | AI_GENERATED / RETAIN_CANDIDATE；1312×1199 |
| `p1r.organization.washbag` | `assets/p1r/organization/washbag.png` | AI_GENERATED / RETAIN_CANDIDATE；1536×1024 |
| `p1r.story.arrival` | `assets/p1r/story/arrival.png` | AI_GENERATED / RETAIN_CANDIDATE；1672×941 |
| `p1r.story.reception` | `assets/p1r/story/reception.png` | AI_GENERATED / RETAIN_CANDIDATE；1672×941 |
| `p1r.story.anna` | `assets/p1r/story/anna.png` | AI_GENERATED / RETAIN_CANDIDATE；1213×1296 |
| `p1r.story.admin` | `assets/p1r/story/admin.png` | AI_GENERATED / RETAIN_CANDIDATE；1145×1374 |
| `p1r.home.background` | `assets/p1r/home/background.png` | AI_GENERATED / RETAIN_CANDIDATE；2135×736 |
| `p1r.home.wood` | `assets/p1r/home/wood.png` | AI_GENERATED / RETAIN_CANDIDATE；1254×1254 |
| `p1r.home.fabric` | `assets/p1r/home/fabric.png` | AI_GENERATED / RETAIN_CANDIDATE；1254×1254 |
| `p1r.cat` | `assets/p1r/home/cat.png` | AI_GENERATED / RETAIN_CANDIDATE；1586×992 |
| `p1r.organization.caseA` | `assets/p1r/organization/caseA.png` | AI_GENERATED / RETAIN_CANDIDATE；1774×887 |
| `p1r.organization.caseB` | `assets/p1r/organization/caseB.png` | AI_GENERATED / RETAIN_CANDIDATE；1774×887 |
| `p1r.organization.caseC` | `assets/p1r/organization/caseC.png` | AI_GENERATED / RETAIN_CANDIDATE；1774×887 |

### 3. 已接入的程序原创 UI

| assetId | 文件路径 | 状态／使用范围 |
| --- | --- | --- |
| `p1r.ui.organization_board` | `scripts/p1/organization_board.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE；响应式、文字分离、可独立调色和替换，故不强制换成位图 |
| `p1r.ui.dialogue_frame` | `scripts/p1/flow.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE；响应式、文字分离、可独立调色和替换，故不强制换成位图 |
| `p1r.ui.world_labels` | `ui/p1_world_label.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE；响应式、文字分离、可独立调色和替换，故不强制换成位图 |

### 4. 第三方授权素材

本轮没有下载或接入第三方美术文件；Kenney／OpenGameArt／itch.io 仍仅是之前候选调研，没有把候选授权当成已接入清单。系统字体采用运行时回退，未分发字体二进制，发布前仍需检查具体目标平台与字体策略。

### 5. 概念、布局参考及未用于当前游戏的资源

| assetId | 文件路径 | 状态／使用范围 |
| --- | --- | --- |
| `temp.npc.anna` | `scripts/p1/flow.gd` | MUST_REPLACE；未入游戏；历史纯占位呈现已由新资源取代，玩法和数据保留 |
| `temp.npc.admin` | `scripts/p1/flow.gd` | MUST_REPLACE；未入游戏；历史纯占位呈现已由新资源取代，玩法和数据保留 |
| `temp.ui.first_playable` | `scripts/p1/flow.gd` | MUST_REPLACE；未入游戏；历史纯占位呈现已由新资源取代，玩法和数据保留 |
| `temp.org.item_set` | `scripts/p1/flow.gd` | MUST_REPLACE；未入游戏；历史纯占位呈现已由新资源取代，玩法和数据保留 |
| `candidate.p1r.organization` | `docs/art-prep/p1-01r/candidate_organization_v02.png` | REVIEW_REQUIRED；未入游戏；方向／布局参考已确认，非生产成品 |
| `candidate.p1r.story` | `docs/art-prep/p1-01r/candidate_story_v01.png` | REVIEW_REQUIRED；未入游戏；方向／布局参考已确认，非生产成品 |
| `candidate.p1r.dormitory` | `docs/art-prep/p1-01r/candidate_dormitory_v02.png` | REVIEW_REQUIRED；未入游戏；方向／布局参考已确认，非生产成品 |
| `reference.p1r.organization_layout` | `docs/art-prep/p1-01r/owner_organization_layout_reference.png` | REVIEW_REQUIRED；未入游戏；方向／布局参考已确认，非生产成品 |

### 6. 后续仍需制作或决定

几何家具及窗台的最终独立图层、统一近正视微俯视与接地点、前景装饰、正式纪念贴纸／徽章、正式地图／应用图标／学校美术仍缺。猫咪当前单张主体＋探头层能服务现有流程，未来如需更多表情／动作应另行制作。人物细节、箱体比例（PC 当前适配较宽）、描边、色板与字幕框细节仍待负责人实际画面验收。

AI_GENERATED / RETAIN_CANDIDATE 允许当前使用、未来无需强制替换；这不等于 CC0、排他版权或已经完成全部商业授权审查。没有资产被自行升级为 FINAL_APPROVED。最终视觉批准、适用条款和使用风险检查仍待完成。

## 文件变更与工程交接

- 入口／流程：`scripts/main.gd`、`scripts/p1/flow.gd`；新增 `story_stage.gd`、`art.gd`。Q00 UI、地图继续入口、原状态逻辑的呈现整合。
- 整理：新增 `organization_board.gd`、`ui/organization_item.gd`；`organization.gd` 增加放置前反馈，完整判题不变。
- 宿舍：`room_view.gd`、`home_controller.gd`、`ui/p1_world_label.gd`、`cat_encounter.gd`；新增 `cat_visual.gd`，仅表现接入，原移动时序保留。`dormitory.gd` 仅正常模式提示调整。
- 资源／规范：`assets/p1r/` 的 15 PNG 与导入设置、统一登记、旧清单、生成记录、TEMP_ART_GUIDE、项目美术 Skill 和必要 AGENTS 阶段索引。没有覆盖原安全、架构与测试规则。
- 验证：`tests/p1_playable_tests.gd`、`p1r_organization_tests.gd`、`p1r_asset_audit.py`、`p1r_layout_preview.gd`、`p1r_visual_review.py`、`verify_p1_windows.ps1`、`package_check.gd`；P0 关键测试断言保留。
- 导出／说明：`project.godot`、`export_presets.cfg`、`README.md`；新增 Windows P1R 导出预设，保留旧预设和旧构建目录。

独立程序：`builds/p1-01r/NextStopRussia-P1-01R.exe` 与同目录 PCK。构建哈希／大小见 `windows-reference-final-02/artifacts.json`。源工程试玩继续用根目录 `试玩P1.cmd`，沿用 `.local-dev/player-data/PLAYTEST`。直接双击独立 EXE 默认使用其旁 player-data；如需续用源工程的同一进度，先在启动进程中将 NSR_DATA_ROOT 指向项目 `.local-dev/player-data`，不自动迁移或改写用户存档结构。测试数据独立存于证据目录，未触碰玩家实际保存目录。

所有工程引用的选中素材、构建、截图、测试数据和原始日志都在 E 盘。内置生成的原输出先写入 CODEX_HOME 的 C 盘生成目录，已复制选中输出到 E 盘并保留原件；没有搬迁认证／全局配置、安装新工具、配置新密钥或购买服务，不声称完全零 C 盘写入。

## 真实画面对照

`docs/reports/P1-01R_VISUAL_REVIEW.png` 为真实 Godot PC 1280×720 与模拟手机 360×780 截图的等比缩放拼版，展示开场、家具标签和整理完成画面；没有以概念图冒充实际效果。来源逐项在 `docs/evidence/p1-01r/visual_review_sources.json`，中途拖放画面见两份最终流程目录的 `06_drag_*` 文件。

## Git、风险与验收边界

分支：`codex/p1-01r-visual-interaction`。基线：`0dd8274b2860596b1912a5c6f0e9dd3f04146940`。实现提交：`294f24596dff53b188560570ace0e5e6803d6cc4`。本报告、展示图及本轮原始证据随后单独归档提交；可用 `git log -2 --oneline` 查到交付记录，避免在报告中伪造自引用哈希。

待负责人确认：新版整理的箱体／物品比例和交互手感，手机字幕与人物大小，宿舍后续完整家具造型及整体画风；当前均未被标为最终美术。宿舍几何外形、单帧猫表现、人工／真机未测、历史触摸风险和最终使用条款审查均为开放项。

交付后停止，等待主线试玩及验收；不自动进入 Q04／Q05 或下一阶段，不推送远程。旧 `docs/evidence/p1-01/` 未跟踪资料按原样保留，不纳入本轮提交；没有清理、重置或覆盖用户证据。

归档后工作区状态：本轮实现、报告、展示图及 P1-01R 证据均已提交；原有未跟踪的 `docs/evidence/p1-01/` 继续保留，因此不宣称整个工作区完全干净。
