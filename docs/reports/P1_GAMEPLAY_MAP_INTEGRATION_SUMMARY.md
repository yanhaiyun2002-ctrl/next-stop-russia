# P1 正式整理玩法与圣彼得堡主地图整合汇总

日期：2026-10-29。状态：**任务 A、B 已整合，可直接运行 PLAYTEST；等待负责人本轮试玩验收。** 未进入 Q04/Q05，未新增物品、规则、地点、剧情、日常题库或经济系统。

## 直接试玩

双击工程根目录 `试玩整合版PLAYTEST.cmd`，运行本轮实际构建的 Windows PLAYTEST：

`E:\俄语游戏\NEXT_STOP_RUSSIA\builds\modes\playtest\NextStopRussia-PLAYTEST.exe`

启动器默认复用工程 `.local-dev/player-data/PLAYTEST/`，与源码入口 `试玩PLAYTEST.cmd` 相同；若进程已设置 `NSR_DATA_ROOT` 则继续尊重它。**没有迁移、清空或覆盖旧档来实现重玩。** 地图点“试玩档”可继续原档或新建独立试玩档；`试玩整合版PLAYTEST.cmd -Fresh` 也会新建独立档，从 Q00 开始。需要看本轮首次整理时，应选择尚未完成 Q02 的档或新档，已完成旧档不会被强迫重做。

直接双击 EXE 且未设置 `NSR_DATA_ROOT` 时，仍使用 EXE 旁 `player-data/PLAYTEST/`；这与上述启动器目录不同，是保留的现有规则，不会自动复制玩家数据。

## A：新行李整理已正式替换 Q02

负责人已真人试玩并认可机制一。本轮复用其长短成序、共边对齐、拖放、90° 转向、吸附、撤销、重来、轻微落放与完成反馈；没有继续包装旧 A/B/C 容量方案，也没有增加新机制或打磨轮次。

唯一共享实现位于 `scripts/p1/luggage_tidy/model.gd`、`view.gd`。原 DEV-only 实现已经移动，UID 保留；正式 Q02、DEV Q02 模块以及独立重玩入口共用这两个文件。旧三个皮箱 UI 与物品控件已归档到 `docs/archive/legacy-q02/*.txt`，不再作为可执行资源。旧容量题 JSON 和旧整理 PNG 不入当前运行包，旧记录仍可在仓库和历史报告中查阅。

正常流程：Q00 抵达领钥匙 → Q01 找猫、摸猫、确认名字 → 宿舍“整理”进入新空间界面 → 四件物品满足原型空间关系，先显示完成反馈 → 玩家点击 **“整理好了 · 继续”** → 原 Q02 完成事件 → 原安娜俄中消息 → Q03 解锁城市。完成反馈本身不提前结算。正式界面没有 DEV 实验标题、调试数据或 A/B/C 仓位。

模型仍接受不同位置、递增/递减顺序、共同顶边/底边及整体换轴后的合理结果，不按唯一坐标答案判题。鼠标按住拖动，手机单指拖动；选中后点“转向”，PC 也可按 R。撤销、重来与退出保留；物品越出布垫会返回原状态。窗口方向变化取消旧手势。俄语短词随拿起显示并淡出，不插入单词卡。

### 存档与结算

- 存档仍为 schema 1；新增可选 `organization.spatial = {version:1, poses:{物品ID:{x,y,turn}}}`，不把旧仓位字符串解释为空间坐标。读取旧档不自动重写文件。
- 旧 Q02 已完成档保留完成、纪念、手账日期、猫名字和城市进度，不要求重做。重复完成直接成功返回，不增加 revision、不重复发奖励、不重写日期。
- 旧 Q02 中途档的 `placements/history` 原样保留作兼容；若没有 spatial，从已批准原型的同一初始摆放进入，Q01 与主线进度保留。
- 新空间每次有效放置、转向、撤销、重来通过 Session 原子保存；退出/重进恢复已提交摆放。保存失败不提交任务或新坐标，界面恢复上次有效状态并提示。备份、坏档保留/恢复、未来 schema 拒写机制保留。
- 撤销操作栈仍属于当前界面内存，重进恢复坐标后从新的撤销栈开始；不承诺跨启动撤销。正在拖动但尚未松手的位移不算已提交摆放。

## B：负责人圣彼得堡地图已接入

开工时 `docs/art-source/city_map/city_map.png` 实际存在，真实格式为 **1952×1087、RGB PNG**，不是任务描述中的 RGBA；它是合法不透明背景，本轮没有修改或伪造 alpha。原件 SHA-256：

`87d6b549d76bca53738df9bdb0c22bb3b7dbbfcd7ba0a2e3bfbba2ecf4f90eaa`

运行资源 `assets/city_map/st_petersburg.png` 为字节完全相同的独立复制，原件保持不变。地图仅作艺术化城市导航，没有按真实地标增加大学名称或新剧情。

### 地点标注已收到

开工时指定的 `city_map_marked.png` 尚未落盘，但用户附件 `E:\俄语游戏\美术\ABC.png` 可读取，为 **8134×4530、RGB PNG**。已将该原始文件按字节复制保留为 `docs/art-source/city_map/city_map_marked.png`，SHA-256：

`20e811df449267c9ebc2ea926bfb3fb4106437125c7e66bf151438ada6624418`

依据附件封闭轮廓映射 A→`dormitory`、B→`school`、C→`shop`；商店继续锁定。位置不是对城市地标的自行猜测。辅助网格、字母与黑色轮廓只存在于开发参考，**没有显示在运行背景里，也不打包标注图**。

地点锚点与多边形在 `data/city_map.json`，全部使用 1952×1087 纹理坐标。轮廓从附件 2048×1141 阅读预览人工描录，再按 x×1952/2048、y×1087/1141 映射；来源尺寸、变换与待试玩状态均写入数据。它们是负责人指定位置的工程映射，尚不能宣称所有边缘点击舒适度已经由负责人验收。

### 导航与适配

地图画面、地点数据、名称按钮、任务标记和导航状态分离。Board 共用一套缩放/平移变换绘制背景与命中区域；数据接口支持多边形、圆和矩形，本轮三个地点使用轮廓多边形。小型中心触摸目标至少保留 48 逻辑单位直径，底部地点列表各有至少 48 的高度。

PC 横屏等比容纳完整地图，有留边；手机竖屏等比显示可读局部，支持有界横向/纵向拖动、加减缩放与任务定位，未拉伸横图。两端均保留底部地点列表，名称不常驻遮住建筑。当前缩放使用按钮/滚轮，没有新增双指捏合系统。

启动仍先地图，地图上的继续入口按原存档指向开场、找猫、强制命名、整理或安娜消息。点击地点与拖动采用阈值区分，热区跟随同一变换；跨方向手势取消。学校的剧情门禁、商店锁定、返回、重复导航防护及地图实例继续复用原导航层。没有绕过首次找猫、命名、Q02 或 Q03。

## 三模式与 DEV 入口

保留唯一工程、Godot 4.7.2 Stable、GDScript、Compatibility。

| 模式 | 实际入口 | 存档命名空间 |
| --- | --- | --- |
| DEV | `开发DEV.cmd` → 地图“模块” → “Q02 首次整理”；或 `开发DEV.cmd -Module q02` | 常规 `DEV/`；模块 `DEV/previews/q02/run_*/` |
| PLAYTEST | 本轮 `试玩整合版PLAYTEST.cmd`；原 `试玩PLAYTEST.cmd` 继续可用 | `PLAYTEST/save.json` 与 `PLAYTEST/profiles/slot_*/save.json` |
| RELEASE | `builds/modes/release/NextStopRussia-RELEASE.exe`，构建特性锁定 | `RELEASE/` |

路径均相对各自 `NSR_DATA_ROOT` 或原有默认根目录。DEV 全屏整理先点“退出”回宿舍，再打开模块菜单。每次正式 Q02 模块预览由同一领域事件建立独立合法测试会话，不覆盖常规档。旧名 `行李整理原型DEV.cmd` 保留兼容快捷入口，菜单显示“行李整理 · 独立重玩”，共用新运行时但只使用内存摆放；没有第二套玩法逻辑。

三个实际 PCK 均有共享整理和地图。PLAYTEST/RELEASE 物理排除 DEV 菜单、fixture 模块和开发脚本，RELEASE 额外排除包内验收器；不是只隐藏按钮。全部包排除测试/证据/原画标注/工具及玩家数据目录。本轮没有推送远程、安装新引擎或改变系统级环境设置。

## 美术资源来源与保留清单

单一权威仍为 `assets/art_registry.json`，旧 `assets/temp/p1_manifest.json` 同步其当前使用状态。没有新的图像生成、第三方下载或美术量产。

| assetId | 路径 | 当前状态 |
| --- | --- | --- |
| `map.st_petersburg.source` | `docs/art-source/city_map/city_map.png` | PROJECT_ORIGINAL / RETAIN_CANDIDATE；负责人输入，原件，不直接入包 |
| `map.st_petersburg.runtime` | `assets/city_map/st_petersburg.png` | PROJECT_ORIGINAL / RETAIN_CANDIDATE；三模式使用，rendererKey=`city.map` |
| `reference.map.owner_abc` | `docs/art-source/city_map/city_map_marked.png` | PROJECT_ORIGINAL / REVIEW_REQUIRED；仅地点标注资料，不入游戏 |
| `prototype.arrival_luggage.passport` | `scripts/p1/luggage_tidy/view.gd` | PROJECT_ORIGINAL / RETAIN_CANDIDATE；护照程序图形 |
| `prototype.arrival_luggage.washbag` | 同上 | PROJECT_ORIGINAL / RETAIN_CANDIDATE；洗漱包程序图形 |
| `prototype.arrival_luggage.textbook` | 同上 | PROJECT_ORIGINAL / RETAIN_CANDIDATE；书本程序图形 |
| `prototype.arrival_luggage.scarf` | 同上 | PROJECT_ORIGINAL / RETAIN_CANDIDATE；围巾程序图形 |
| `prototype.arrival_luggage.surface` | 同上 | PROJECT_ORIGINAL / RETAIN_CANDIDATE；布垫 |
| `prototype.arrival_luggage.feedback` | 同上 | PROJECT_ORIGINAL / RETAIN_CANDIDATE；抓取/落放/齐边/完成及程序音效 |
| `placeholder.map.city` | 旧 `scripts/map.gd` 历史表现 | EXISTING_PLACEHOLDER / MUST_REPLACE；本轮已停用，不覆盖新图 |
| `p1r.organization.{passport,textbook,scarf,washbag,caseA,caseB,caseC}`、`p1r.ui.organization_board` | `assets/p1r/organization/*.png`、旧 Board 归档 | 原有来源/保留状态保留，当前 usedInGame=false，旧 rendererKey 退为历史信息，不入运行包 |

六个整理 ID 保留原型稳定身份，当前 module/activeProfiles/usageScope 已明确为正式共享 Q02；旧“待决定保留”记录只在 history 字段，不再代表当前决定。程序化资源有真实逻辑尺寸、锚点和图层记录，不冒称独立透明 PNG。地图登记注明负责人提供及本轮使用授权；全部 `permanentApproval=false`，没有自动声明 CC0、排他权利或全部发行授权审查完成。

既有宿舍几何占位与其他 AI 候选的状态仍分别管理，不因这次接入统一改为 TEMP_REPLACE_REQUIRED，也没有永久锁定整体画风。

## 实际测试与原始证据

以下路径均位于工程 `docs/evidence/gameplay-map-integration/`；计数为实际执行结果。

| 验证 | 结果 | 证据子目录 |
| --- | --- | --- |
| 领域、坏档恢复、备份、未来 schema、保存失败 | 55／0 | `pc-03/`、`phone-full-11/` 的 `domain_results.json` |
| PC 正常 Q00→Q01→新版 Q02→Q03、20 次摸猫及四藏点/导航 | 186／0 | `pc-03/playable_results.json` |
| 模拟手机竖屏、新独立试玩档、合成触摸完整流程 | 187／0 | `phone-full-11/playable_results.json` |
| 旧中途/完成档、坐标 JSON、保存失败、地图变换/热区/浏览/任务定位、方向切换、Q02退出恢复 | PC 36／0；手机 37／0 | `integration-pc-final-21/`、`portrait-final-25/` |
| DEV 五模块各重复两次、退出回原档与奖励/命名空间 | 89／0 | `dev-modes-15/modes_results.json` |
| 共享空间模型与真实控件：多解、旋转、吸附、撤销、重来、越界、触摸、方向取消、隔离暂停 | 57／0 | `spatial-controls-16/prototype_results.json` |
| P0 导航、重复往返、无效场景、焦点、五比例、跨尺寸取消、模拟安全区 | 268／0 | `p0-navigation-final-19/rendered_results.json` |
| 原图/参考哈希、PNG 解码、活动资产路径、Git祖先与核心内容未改 | 82／0 | `asset-audit-22/scope_asset_audit.json` |
| 最终已提交版本三模式导出、PCK 审计、Windows EXE 实际运行、调试参数拒绝与常规档哈希 | 三模式 PASS | `windows-handoff-26/windows_modes_results.json`、`pack-*.json`、`artifacts-*.json`、原始日志 |
| 最终 Windows PLAYTEST 实际包内完整流程，包含真实空间拖放和继续 | 14／0 | `windows-handoff-full-27/package_results.json`、真实截图及日志 |

运行命令入口包括 `tests/p1.ps1 -Rendered [-FullPortrait -NewProfile]`、`tests/gameplay_map.ps1 -Rendered [-Portrait]`、`tests/modes.ps1 -Dev -Rendered`、`tests/luggage_prototype.ps1 -Rendered -Portrait`、`tests/run.ps1 -Rendered`、`tests/verify_modes_windows.ps1`、`tests/verify_p1_windows.ps1 -Modes`；每轮使用独立 EvidenceDir。旧容量 validator 的纯规则单测有历史保留，不作为新空间玩法证据。P0 宿舍空间/投影/遮挡/猫移动和 `data/p1/content.json` 源码本轮未改，完整首段仍验证其交互；未机械重跑所有历史性能/构图批次。

### 失败记录与修正范围

全部历史失败保留，没有覆盖为通过结果：

- `import-01`：首轮动态输入变量类型推断错误；`integration-pc-04`、`dev-modes-05`：DEV fixture 局部变量重名。均已修正。
- `pc-02` 领域 44／11：JSON 读回的数值类型导致转向校验误拒绝，现正确接收整数值的 JSON 数字，仍拒绝小数、布尔、非有限数与越界坐标。
- `integration-pc-06` 34／1：测试在完整画面尚未宽于画布时要求横向位移；用例改为真实可浏览的放大范围，未改游戏比例以迎合断言。
- `phone-full-07` 187／1：测试等待了全屏整理主动暂停的下层 SafeLayout；现等待整理自身的稳定几何。`dev-modes-12` 同时暴露旧测试试图穿过全屏界面点下层菜单，已按真实退出按钮关闭后再切模块。
- `p0-navigation-13` 238／30：旧地图固定 156×92 热点断言不适用于新地点列表。替换为列表三等分、至少 48 高、屏内可见及真实点击断言；原导航/跨尺寸取消覆盖保留，最终 268／0。
- `windows-modes-10`：Windows PowerShell 未保留短进程句柄，读不到退出码；保留句柄并严格要求真实退出码，未将 null 当成功。后续三模式日志、哈希及退出均有效。
- 领域日志中的 `file_instead_of_directory` ERROR 是保留的失败注入用例，断言确认状态回滚，不是正常试玩发生的写入错误。

上述测试调整不表示 P0 偶发合成触摸根因已修复。QA 子 Agent 只读审查发现的旧贴图包检查及登记范围矛盾已修正，最终复核未发现阻断项；其审查不冒充实际测试。

## PC 与模拟手机的真实 Godot 画面

以下来自实际 Godot 渲染，不是 AI 概念图或地图标注图。

PC 地图：

![PC 城市地图](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/gameplay-map-integration/integration-pc-final-21/01_map_initial.png)

模拟手机地图：

![手机城市地图](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/gameplay-map-integration/portrait-final-25/01_map_initial.png)

PC 正式 Q02 完成反馈：

![PC 正式整理](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/gameplay-map-integration/integration-pc-final-21/04_q02_complete.png)

模拟手机正式 Q02 初始摆放：

![手机正式整理](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/evidence/gameplay-map-integration/portrait-final-25/03_q02_initial.png)

## Git、修改清单与停止边界

基线为 `6f1f052`，本轮分支 `codex/p1-gameplay-map-integration`；实现提交：

**`cee0979c18d2c7ac19286f36ca91017d087aeba0`**（整合）

**`74e0b28125f8600fb289750f09ec682a54b297e7`**（最终手机完成按钮收起同位置说明，避免轻微叠压；未改变玩法）

祖先检查确认 P1-01 `78a792a`、P1-01R `0c4af5c`、三模式 `cbf68e8`、新原型 `d2007bb` 与交付 `6f1f052` 均已包含，没有遗漏其他分支成果。没有 reset/stash/clean 或远程推送。

主要实际文件：

- 正式运行时：`scripts/p1/luggage_tidy/{model,view}.gd`（及移动 UID）、`scripts/p1/{session,save_store,flow,package_check}.gd`、`scripts/dev_tools/module_preview.gd`。
- 地图：`scripts/map.gd`、`ui/map_board.gd`、`data/city_map.json`、`assets/city_map/st_petersburg.png` 及 `.import`，负责人两份原始输入。
- 资源/构建：`assets/art_registry.json`、`assets/temp/p1_manifest.json`、`export_presets.cfg`；旧 UI/控件与旧专用测试归档 `docs/archive/legacy-q02/`，旧运行 UID 移除。
- 入口/依据：`试玩整合版PLAYTEST.cmd`、`scripts/dev/play-integrated.ps1`、`README.md`、必要 AGENTS 阶段授权及产品决策追加。
- 测试：`tests/gameplay_map{.ps1,_integration_tests.gd,_asset_audit.py}`、`luggage_input.gd`（及 UID）；更新 `p1_domain_tests.gd`、`p1_playable_tests.gd`、`p1_modes_tests.gd`、`luggage_prototype_tests.gd`、旧 `p1r_organization_tests.gd` 兼容入口、`run_tests.gd`、PCK 与两个 Windows 验证脚本。

报告与本轮原始证据另作归档提交，可通过 `git log -2 --oneline` 查看；没有把提交号写成自引用。源码提交后的工作区只增加本报告和本轮证据。原有未跟踪 `docs/evidence/p1-01/`、`docs/evidence/tidy-desk-prototype/` 保留不动；构建、缓存、真实测试档和大型工具继续在 E 盘，不承诺 Windows/Codex 零 C 盘写入。

待负责人确认：新地图宿舍/学校/商店边缘热区是否舒适、PC 全景留边与手机浏览/定位是否合适，以及新 Q02 与 Q03 的继续衔接。没有已知阻断本轮试玩的缺陷；真人本轮整合试玩、Android 真机、Apple 平台和声音舒适度未验收。地图/程序美术与既有资源仍需后续最终视觉及发行使用审查。

**本轮完成后停止，等待负责人试玩验收。不再打磨整理、不自动进入 Q04/Q05，不新增城市地点或正式素材。**
