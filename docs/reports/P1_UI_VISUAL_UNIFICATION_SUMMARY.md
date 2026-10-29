# P1-UI-01｜全屏场景、城市地图交互与游戏 UI 统一整改

日期：2026-10-29。状态：**已完成本轮整改并生成 Windows PLAYTEST，等待负责人视觉验收。** 本轮依据负责人粘贴的任务书执行，原文保存在 `docs/tasks/P1_UI_01_TASK.md`。没有进入 Q04/Q05，没有新增地点、剧情、整理规则或存档 schema。

## 直接运行

双击根目录 **`试玩整合版PLAYTEST.cmd`**。该兼容入口现已运行本轮 UI 版本：

`E:\俄语游戏\NEXT_STOP_RUSSIA\builds\modes\playtest\NextStopRussia-PLAYTEST.exe`

需要从开场体验时，在地图点“试玩档”→“新建独立试玩档 · 从 Q00 开始”，或使用 `试玩整合版PLAYTEST.cmd -Fresh`。已完成旧档继续有效，不会被强制重置。默认仍复用工程 `.local-dev/player-data/PLAYTEST/`；已设置的进程 `NSR_DATA_ROOT` 优先。直接运行 EXE、未设置该变量时，数据仍在 EXE 旁 `player-data/PLAYTEST/`，不自动迁移。

## 黑边的实际根因和修正

| 问题 | 开工检查结论 | 本轮修正 |
| --- | --- | --- |
| 视口 letterboxing | 原 `project.godot` 已为 `canvas_items + expand`，不是固定比例锁定产生的主要黑边 | 保留窗口伸缩机制；检查真实有效视口和五种比例，不以拉伸图片修复 |
| 地图 contain 留边 | PC 的 `base_scale=min(...)` 以及 VBox 头尾挤占，使地图只剩中间小窗，两侧露底 | 地图背景独立覆盖整个视口，两端都按 cover 等比缩放，保留有界平移、缩放和定位 |
| 场景外层深色底板 | SafeLayout 给整个场景加 28/16 的外边距；清屏色和默认按钮主题较深 | 普通模式背景与 HUD 安全区分开；地图、宿舍画布全屏，操作控件保留安全边距；共享浅纸张 Theme 替换默认 UI |
| 宿舍像被装进窗口 | 房间画布被标题、右侧栏、浏览条和反馈挤在 VBox/HBox 中 | 既有房间画布移至根视觉层，随房间隐藏/释放；HUD 单独布局。投影、镜头边界、遮挡排序和猫移动算法保留 |
| 背景缩放 | 宿舍旧背景直接填投影矩形，可能改变图片宽高比 | 在原房间投影区域内等比 cover 裁切；不改负责人图片或家具投影。剧情原有独立 cover 背景继续复用 |

清屏色也改为暖色以减少切换闪色，但铺屏整改依靠真实场景画布和缩放，不是仅替换黑色。Q00、宿舍、地图、Q02 和 Q03 均有实际 Godot 截图；Q02 保留原布垫和全屏功能背景。

## 共享 UI 视觉规范

具体规范见 `docs/design/ui/P1_UI_01_VISUAL_SPEC.md`，共享实现为 `ui/game_ui.gd`，没有建立新 UI 框架。

- 米白纸张 `#FFF4DF`、深蓝灰文字 `#344953`、浅棕/浅金边框 `#BD9E70 / #B79151`。
- 按钮正常为纸白，悬停浅金，按下低饱和绿，禁用柔灰；圆角、细边和轻棕阴影统一。键盘焦点与地点选中分开表达。
- 面板、按钮五状态、输入框、工具提示和弹出菜单由共享 Theme / StyleBoxFlat 管理。主要按钮至少 48 逻辑单位高。
- 地图标牌 132×56，俄语主名、中文辅助名；锁图标、引导线和小型光晕由代码绘制，没有把地点名和状态画进地图。
- Q00 保留俄语主对白＋中文字幕，采用暖纸俄语框、浅色中文框、说话人标签和统一继续按钮。Q03 使用同一消息卡样式及全屏宿舍背景。
- 宿舍功能入口改为上部紧凑工具条，浏览按钮缩至左右两侧，避开家具标签和猫主体；家具标签保留世界坐标与原识词行为。
- Q02 只更换按钮/文字样式及安全区布局，保留物品、布垫、拖放、90° 转向、吸附、撤销、重来、判定、音效和保存机制。

命名、档位和 DEV 菜单使用同一原生纸张卡片。所有动态文本、按钮和任务状态继续由 Godot 控件及现有数据渲染。

## imagegen、Kenney 与字体的实际使用

### 内置图像生成

已读取项目 `game-art-pipeline` 与官方 `imagegen` Skill，并实际成功调用官方内置 `image_gen.imagegen` **一次**，没有使用外部付费 API、申请密钥或安装新服务。

生成了一张独立空白纸张面板，实测 **1774×887、RGBA，alpha 范围 0～255**。完整提示词、透明背景参数、原始输出和候选路径保存在 `docs/production/ui01_generation_records.json`。

真实手机命名界面中，候选的弧形边缘在纵向九宫格拉伸后变形，不符合轻量统一要求。已按任务书允许的回退方案使用原生 Theme。**该生成图未接入最终游戏、未打包，没有把一张效果图冒充可交互控件。** 保留的失败画面是 `phone-15/05_name_required.png`；最终原生样式是 `phone-full-final-23/05_name_required.png`。

原始生成文件仍在默认 C 盘 `CODEX_HOME/generated_images/.../exec-8cfa12b3-2164-4e6e-b1b2-352e4a14e2a8.png`，项目候选按原字节保存在 E 盘文档目录。没有搬迁认证或全局 Codex 配置，不声称全部临时数据都在 E 盘。

### 第三方资源和字体

[Kenney UI Pack 官方页面](https://kenney.nl/assets/ui-pack) 标注 430 文件、CC0。本轮没有下载或集成该包，也没有宣称完成包内格式、九宫格或授权文件的实际验收。最终运行 UI 为项目原创原生 Theme，没有新增第三方美术或署名义务。

继续使用已有系统字体栈 Microsoft YaHei / Noto Sans CJK SC / PingFang SC / Arial，没有拷贝或分发 TTF/TTC/OTF。当前 Windows 的西里尔和中文字形已用 Godot `has_char` 与实际混排截图检查。微软说明 Windows 应用可使用已安装系统字体绘制屏幕，而字体文件的游戏内嵌/再分发是另一项权限；本轮采取运行时系统字体方式。[微软字体使用与再分发 FAQ](https://learn.microsoft.com/en-us/typography/fonts/font-faq)

Android、Apple 及缺少这些系统字体的机器未验收；以后如需打包字体，应另选有明确分发许可且覆盖中俄字符的文件。

## 地图标签、选中和浏览

保留负责人原图与运行图，均未修改；两者 SHA-256 仍为：

`87d6b549d76bca53738df9bdb0c22bb3b7dbbfcd7ba0a2e3bfbba2ecf4f90eaa`

`data/city_map.json` 仅增加标签文案，原锚点、多边形和三个稳定 ID 不变：

| ID | 默认标签 | 门禁 |
| --- | --- | --- |
| `dormitory` | Общежитие / 宿舍 | 复用抵达引导、钥匙和宿舍入口 |
| `school` | Университет / 大学 | Q03 前显示剧情锁，仍由原导航判断 |
| `shop` | Магазин / 商店 | 继续锁定，没有新增商店系统 |

三个标牌无需点击即可见。手机 cover 视窗不能同时包含三个建筑，因此离屏地点采用带方向的边缘标牌；它们由纹理锚点投影和 HUD 避让计算产生，不是新的固定屏幕业务坐标。点击标牌、建筑及可展开的地点列表均走原导航意图。保留任务定位、滚轮/按钮缩放与受控拖动。

原黄色轮廓来自 `MapBoard` 对点击多边形的直接描边。本轮已移除该美术表现，改为标牌金边与建筑锚点轻光晕；没有把不精确热区冒充建筑轮廓。按下宿舍标牌有自然反馈，释放后照常进入原场景/引导；锁定地点保留选中与锁定说明。空白点击、拖动和地图退出清除选中，切换地点同步更新。

标牌支持键盘确认；收起地点列表时，返回地图也能恢复地点焦点。地图拖动与点击继续区分，窗口变化仍取消跨尺寸手势。

## 资产来源与保留清单

统一权威为 `assets/art_registry.json`。本轮没有资源升级为 FINAL_APPROVED，全部 `permanentApproval=false`。

| assetId | 文件路径 | 来源／保留状态 | 使用及工程规格 |
| --- | --- | --- | --- |
| `ui01.shared_theme` | `ui/game_ui.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE | 三模式使用；响应式 Theme、原生 alpha、纸张/按钮/提示框状态；非 PNG，九宫格不适用 |
| `ui01.map_plaques` | `ui/map_plaque.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE | 三模式使用；132×56、文字分离、锁图标及焦点样式 |
| `ui01.map_selection` | `ui/map_board.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE | 三模式使用；纹理锚点投影、小型暖金光晕及引导线，不使用热区边框 |
| `ui01.paper_panel` | `docs/art-prep/p1-ui-01/paper_panel_candidate.png` | AI_GENERATED / REVIEW_REQUIRED | 未入游戏/未打包；1774×887 RGBA；来源、提示词、失败问题均登记 |
| `p1r.ui.dialogue_frame`、`p1r.ui.world_labels` | 原 `scripts/p1/flow.gd`、`ui/p1_world_label.gd` 样式绑定 | 原来源和保留状态保留，旧样式退役 | 控件行为仍使用这些文件；旧视觉由 `ui01.shared_theme` 接管，不将历史样式算成当前接入资源 |

生成候选试验的 sourceRegion `[32,123,1710,640]`、纹理九宫格 `[70,48,70,48]`、内容边距 `[18,14,18,14]` 保留作失败规格记录；最终运行不使用该切片。原始 alpha 未被擦除或伪造。

负责人地图维持 PROJECT_ORIGINAL / RETAIN_CANDIDATE；旧宿舍几何家具等 MUST_REPLACE 状态保留，本轮没有重做家具。其他既有 AI 场景/人物/猫资源沿用原保留分类，没有统一加 TEMP_REPLACE_REQUIRED，也没有宣称 CC0、排他版权或完成全部发行使用审查。

## 实际测试与构建

下表证据均在 `docs/evidence/p1-ui-01/`，测试使用独立 E 盘目录。

| 验证 | 实际结果 | 证据子目录 |
| --- | --- | --- |
| 领域、备份/坏档恢复、未来 schema 拒写、保存失败回滚 | 55／0 | `pc-14/`、`phone-full-final-23/domain_results.json` |
| PC 完整 Q00→Q03、四藏点、20 次摸猫、家具标签横拖、命名与导航 | 186／0 | `pc-14/playable_results.json` |
| 最终手机新档完整流程、原生命名卡、合成触摸与退出恢复 | 187／0 | `phone-full-final-23/playable_results.json` |
| 最终 UI：铺屏、三标牌、锁定/选中/空白、焦点、中俄字形、宿舍全屏、Q02模拟安全区真实拖放与Q03 | PC 85／0；手机 85／0 | `ui-pc-handoff-27/`、`ui-phone-handoff-26/ui_results.json` |
| DEV 五个模块重复预览、隔离命名空间与返回 | 89／0 | `dev-phone-18/modes_results.json` |
| PLAYTEST 原完成档、新建独立档、切回旧档与权限检查 | 62／0 | `playtest-profiles-24/modes_results.json` |
| 共享整理控件：多解、吸附、旋转、撤销、重来、越界、方向取消、暂停/恢复与触摸 | 57／0 | `organization-controls-25/prototype_results.json` |
| P0 导航、重复往返、焦点、五比例、跨尺寸取消、模拟安全区 | 268／0 | `p0-navigation-20/rendered_results.json` |
| 核心源码逐函数保护、原图哈希、位置数据和真实 alpha | 106／0 | `scope-final-28/scope_results.json` |
| 三模式实际 Windows 导出/运行、PCK 边界、调试参数拒绝、常规存档哈希 | 三模式 PASS | `windows-modes-29/windows_modes_results.json`、`pack-*.json`、`artifacts-*.json` 与原始日志 |
| 最终 Windows PLAYTEST 独立程序完整 Q00～Q03 和真实空间整理 | 14／0 | `windows-full-30/package_results.json`、实际截图与日志 |

实际入口包括 `tests/p1.ps1 -Rendered`、`tests/ui_visual.ps1 [-Portrait]`、`tests/modes.ps1`、`tests/luggage_prototype.ps1`、`tests/run.ps1 -Rendered`、`tests/ui_scope_audit.py`、两个 Windows 验证脚本；每轮 EvidenceDir 独立。RELEASE 的包和实际启动已测；独立包完整剧情测试在 PLAYTEST 执行。

包审计确认三个包包含共享 UI、地图和正式整理；PLAYTEST/RELEASE 没有 DEV 菜单与 fixture 注入，RELEASE 没有包内验收器；候选纸张、测试数据、原画标注、工具和玩家数据不入运行包。正常退出测试使用实际退出码，三个常规命名空间存档哈希保持不变。

### 发生过的回归和修正

首轮失败日志保留，没有覆盖为通过记录：

- `pc-01`：地图避让数组的类型绑定错误；随后改为正确的运行时数组接口。
- `pc-01/02`：初版 top-level 背景在输入层级上抢先命中，导致继续按钮无响应。改为普通根视觉层和独立 HUD，诊断 `diagnostic-03` 确认真实按钮进入 Q00。
- `pc-04`：透明布局容器截住家具点击，改为仅让纯布局容器透传，按钮和可交互对象保留输入。
- `pc-05/06`、`phone-07`：全屏布局暴露家具标签坐标转发问题及工具条遮挡猫/标签。`dorm-diagnostic-10/11` 捕获首次合成按下事件 global_position 为零，改用 GUI 本地坐标经变换转发；保留原镜头算法。工具条移至上部，浏览按钮收紧至两侧。
- 移动中的家具标签和地图标牌不再被当作全局 UI 重排；它们使用各自拥有者的版本/拖动取消规则，窗口尺寸仍在全局签名中，跨尺寸按下/释放保护未删除。
- `ui-pc-08/ui-phone-09` 是新测试脚本的类型推断错误，不当作游戏测试通过；已修正并实际重跑。
- 生成纸张的手机九宫格变形已回退，最终包使用原生样式。失败图和生成原图都保留。
- 领域日志的 `file_instead_of_directory` ERROR 是原有失败注入用例，用于确认保存失败不推进状态。

本轮输入修正不等于 P0 历史偶发合成触摸根因已彻底消除。测试没有通过改变输入模拟环境来声称修复。只读 QA 复核未发现阻断项，未将其审查描述为实际运行。

## 真实 Godot 对比与重点画面

### 地图整改前后

| 视口 | 整改前 | 本轮 |
| --- | --- | --- |
| PC | ![PC之前](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/gameplay-map-integration/integration-pc-final-21/01_map_initial.png) | ![PC本轮](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-pc-handoff-27/01_map_fullscreen.png) |
| 模拟手机 | ![手机之前](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/gameplay-map-integration/portrait-final-25/01_map_initial.png) | ![手机本轮](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-phone-handoff-26/01_map_fullscreen.png) |

真实按下宿舍标牌的金色反馈：

![宿舍选中](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-pc-handoff-27/04_dormitory_selected.png)

手机大学锁定提示：

![大学锁定](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-phone-handoff-26/02_school_locked.png)

Q00 俄中对白：

![手机Q00](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-phone-handoff-26/05_q00_dialogue.png)

宿舍正常游玩：

![手机宿舍](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-phone-handoff-26/07_home_fullscreen.png)

正式 Q02（含模拟安全区）：

![手机Q02](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-phone-handoff-26/08_q02_complete.png)

Q03 消息：

![PC Q03](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/p1-ui-01/ui-pc-handoff-27/09_q03_message.png)

这些均是实际 Godot 渲染；目录中还保存商店锁定、PC Q00、模拟安全区、命名与档位菜单截图，没有用生成候选冒充游戏画面。

## Git、文件与剩余限制

分支 `codex/p1-ui-visual-unification`，从前轮整合交付 `a91f819` 继续；源码提交：

**`a6b5fa27b46c8f349497c57fe2bd4a406551feb7`**

实际修改集中于 `ui/game_ui.gd`、`ui/map_plaque.gd`、`ui/map_board.gd`、`ui/p1_world_label.gd`、`ui/adaptive_layout.gd`，地图场景/脚本，主入口的视觉层所有权，P1 对话/宿舍/整理视图的样式和安全区，房间背景的一处等比绘制调用，以及必要的测试、资源登记、README、任务/视觉规范和阶段授权。新增 UID 保留。生成候选和提示词已在项目文档中保留。

`session.gd`、`save_store.gd`、整理 `model.gd`、猫移动/奖励/任务逻辑、三模式权限/档位实现及 `data/p1/content.json` 逐字未改。源图哈希、原地点锚点/热区未改。主 Agent 独占实现，只读 QA 辅助审查，没有新 Worktree 或第二套工程，没有远程推送。

本报告与本轮原始证据另作归档提交，可用 `git log -2 --oneline` 查看。源码提交后仅增加本报告和本轮证据；历史未跟踪 `docs/evidence/p1-01/`、`docs/evidence/tidy-desk-prototype/` 保留不动。工具、构建、缓存及测试数据继续优先 E 盘。

待负责人视觉确认：纸张配色/圆角/字号、手机边缘标牌与长引导线的舒适度、金色反馈强度、宿舍 HUD 和人物对白构图。离屏标牌可提示方向，但其建筑需通过地图浏览观察；这是横图在竖屏 cover 下的明确取舍。宿舍旧几何家具仍较粗糙，本轮没有借 UI 整改重画。

真人本轮视觉验收、Android 真机、Apple 平台及其他机器字体回退未执行；RELEASE 构建不等于正式发行美术/授权审核完成。当前没有已知阻断本轮 Windows 试玩的问题。

**本轮完成后停止，等待负责人视觉验收。不进入 Q04/Q05，不扩展地点、剧情或整理玩法。**
