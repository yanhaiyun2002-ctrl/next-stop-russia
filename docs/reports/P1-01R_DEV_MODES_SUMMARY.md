# P1-01R 开发版本、模块化试玩与存档隔离汇总

日期：2026-10-29。状态：补充任务完成，等待负责人验收。唯一正式工程仍为 `E:\俄语游戏\NEXT_STOP_RUSSIA`；本轮未增加剧情、美术或 Q04／Q05。

## 负责人实际使用方式

**重新体验完整流程：** 双击根目录 `试玩PLAYTEST.cmd`，在城市地图点“试玩档”，选择“新建独立试玩档 · 从 Q00 开始”，再点抵达引导。原来的完成档保留在“继续 · 原默认档”，以后可随时切回。最近选择的档位跨启动保留；每次启动仍先到城市地图。

**单独验收模块：** 双击 `开发DEV.cmd`，点地图动作栏“模块”，选择 Q00、Q01、Q02、Q03 或宿舍自由视觉预览。预览中右上“DEV · 模块”可以重新选择模块或“退出预览 · 返回 DEV 完整流程档”。每次选择生成一个新的独立预览目录，不重置旧档。

| 模式 | 源工程入口 | 已生成的独立 Windows 程序 | 权限 |
| --- | --- | --- | --- |
| DEV | `开发DEV.cmd`；或 `scripts/dev/play-p1.ps1 -Dev` | `builds/modes/dev/NextStopRussia-DEV.exe` | 完整流程、模块菜单、受限白名单预览及旧 DEV 参数兼容 |
| PLAYTEST | `试玩PLAYTEST.cmd`；原 `试玩P1.cmd` 保留 | `builds/modes/playtest/NextStopRussia-PLAYTEST.exe` | 正常流程、继续旧档、新建／选择独立试玩档；没有 DEV 模块工具 |
| RELEASE | 实际运行右侧导出程序 | `builds/modes/release/NextStopRussia-RELEASE.exe` | 正常游戏入口；不开放测试档菜单、模块预览或开发状态注入 |

可用 `开发DEV.cmd -Module q02` 直接进入独立首次整理；`试玩PLAYTEST.cmd -Fresh` 创建新的独立试玩档。两者均不删除唯一存档。启动器尊重已显式设置的进程环境 `NSR_DATA_ROOT`；未设置时沿用项目 `.local-dev/player-data`。未修改系统级环境变量。

三个 EXE 均需要同目录 PCK。独立程序默认使用自身旁边的 `player-data`，因此不会自动去复制源工程或其他构建目录的玩家数据。负责人若要续用源工程的旧进度，优先使用上述源工程 PLAYTEST 启动器；独立 EXE 也可以在启动进程前把 `NSR_DATA_ROOT` 指向原数据根目录。没有自动迁移、清空或改写旧目录。

## 存档隔离与兼容

以下 `R` 表示解析后的存档根目录，源工程启动器默认是 `E:\俄语游戏\NEXT_STOP_RUSSIA\.local-dev\player-data`。

| 数据用途 | 目录 |
| --- | --- |
| 原 DEV 完整流程档 | `R/DEV/save.json` |
| 原 PLAYTEST 默认档 | `R/PLAYTEST/save.json`，路径保持不变 |
| 新建独立试玩档 | `R/PLAYTEST/profiles/slot_<时间>_<随机ID>/save.json` |
| DEV 模块独立预览 | `R/DEV/previews/<q00/q01/q02/q03/home>/run_<时间>_<随机ID>/save.json` |
| RELEASE 玩家档 | `R/RELEASE/save.json` |
| 档位选择记录 | 各模式目录内 `selected_profile.json`，不属于游戏存档 schema |

`schemaVersion=1`、游戏字段及领域校验规则保留。`P1Session`／`P1SaveStore` 只增加可选 profile 路由，旧两参数构造仍落到旧位置。原有原子替换、`.bak`、损坏文件保留与有效备份恢复继续复用，未建立另一套保存逻辑。

新档 ID 经过白名单校验；新目录使用唯一 ID 并先独占建立，不覆盖已有槽位。目录穿越 ID 会被拒绝并阻止底层读写。损坏的档位选择记录回退为旧默认档，不会清空游戏文件。选择不存在的档位被拒绝。菜单显示实际存档目录，地图副标题和 Windows 标题栏显示运行模式；DEV 菜单同时显示当前预览路径。

## DEV 模块入口与合法状态

| 入口 | 通过原领域事件构造的起点 | 复用体验 |
| --- | --- | --- |
| Q00 | 全新有效状态 | 原开场场景、俄中对白与领钥匙 |
| Q01 | 完成五条抵达对白并合法进入宿舍，尚未首遇摸猫 | 原首次找猫、抚摸、纪念与命名 |
| Q02 | 抵达完成，合法选择藏点、摸猫并确认测试名字 | 原首次整理题目、拖放、撤销、重置及确认 |
| Q03 | 前置事件完成，通过题目自身合法摆放数据及领域判题完成整理，消息索引仍为 0 | 原安娜两条消息与城市解锁 |
| 宿舍自由视觉预览 | 通过原事件完成 Q00～Q03 | 原宿舍、自由找猫、家具标签、镜头与正常生活活动 |

工厂依次调用 `advance_arrival`、`enter_home`、`choose_spot`、`pet_reaction_completed`、`confirm_name`、`place_item`、`complete_organization`、`advance_message`；没有直接改写 quest、reward、cat 或 story 字段。整理 fixture 取当前题目已登记的示例摆放，仍交给领域函数验证，不另写一套判题规则。任一步失败即停止构造，原完整流程档不受影响。

预览每次都新建独立运行目录，允许退出后再进；已生成数据保留，不自动清理。旧 `--name-pending`、`--cat-spot` 兼容入口也仅在 DEV 执行，并改用独立预览数据。`--technical-map` 仅在 DEV 可用。正常 PLAYTEST／RELEASE 不通过这些参数写入测试状态。

## 三模式权限边界

`runtime_mode.gd` 根据构建 feature 决定能力，不能仅凭用户命令行把发行版改成 DEV。`nsr_release` 最高优先；未知或冲突构建按 RELEASE 处理。`p1_playtest` 构建始终为 PLAYTEST；`nsr_dev` 为 DEV。源工程默认 PLAYTEST，只有显式 `--dev` 进入 DEV；源工程 `--mode=RELEASE` 采用更严格模式。

DEV 模块工具只在 `can_dev` 成立时动态加载。PLAYTEST 与 RELEASE 的导出预设均物理排除 `scripts/dev_tools/`，RELEASE 还排除原 PLAYTEST 包内验收器；常规脚本没有对 DEV 工具的静态类型／preload 依赖。正常模式的模块会话切换也有权限与目录归属检查，不是仅把按钮藏起来。

最终 RELEASE EXE 同时收到 `--dev`、`--mode=DEV`、`--preview=q02`、`--name-pending`、`--technical-map`、`--cat-spot=under_bed`、`--new-playtest` 和 `--verify-p1-package`，仍记录 `NSR_MODE=RELEASE DEV_CAPABILITY=false`，没有生成预览或新试玩档，三份常规档哈希不变。独立空工程挂载实际 PCK 的审计确认：RELEASE 内无 DEV 工具、无包内验收器；PLAYTEST 内无 DEV 工具。

RELEASE 预设只表示本轮权限隔离构建，不表示 P1-01R 已完成正式发行、美术或平台验收。核心玩法、剧情内容与美术资源共用同一代码和资源。

## 模块结构审查与最小解耦

- **领域与保存：** `session.gd` 保留唯一事件逻辑，`save_store.gd` 保留唯一 schema／校验／备份实现；新增 `profile_catalog.gd` 仅负责档位目录和选择元数据。
- **流程与导航：** `main.gd` 增加受限会话切换，沿用原地图和建筑 ID。旧 Flow 切换时显式注销信号、删除其地图入口并释放旧房间，避免多份菜单和旧会话响应。
- **模块预览：** `scripts/dev_tools/module_preview.gd` 只负责开发菜单与前置事件串联，直接进入原 Flow／HomeController，不复制找猫、整理或消息 UI。
- **可替换表现：** 剧情舞台、猫咪运动、整理 Board、家具世界坐标标签和 `assets/art_registry.json` 资源 ID 保持原边界。本轮没有改动美术 PNG、资产保留状态或正式内容数据。
- **构建：** 新增 `Windows DEV`／`Windows PLAYTEST`／`Windows RELEASE` 预设，保留旧预设和旧构建目录；仍为唯一 Godot 工程，没有三套游戏代码。

审查结论：现有领域／表现分离足以支持首批局部预览，无需大规模重构；需要补的主要是模式授权、档位路由和旧 UI 会话的生命周期清理，均已按上述最小范围完成。

## 实际测试及原始证据

证据均在 `docs/evidence/p1-01r-dev-modes/`，以下为实际结果。

| 验证 | 结果 | 证据目录／文件 |
| --- | --- | --- |
| 模式策略、三命名空间、唯一档位、路径拒绝、备份恢复、预览合法性及旧档保护 | Headless 61／0 | `unit-playtest-01/` |
| DEV 五模块各两次、退出回原档、PC 实际菜单点击 | 87／0 | `dev-pc-05/` |
| 最终 DEV 手机菜单、重复预览及 Q03 原消息 UI 实际解锁 | 89／0 | `dev-phone-11/` |
| PLAYTEST 手机真实新建／切回旧完成档、旧文件哈希保护 | 62／0 | `playtest-phone-09/` |
| 新建独立档完整 Q00～Q03、拖放与点选、命名、重启、自由找猫、地图门禁与返回 | PC 195／0；模拟手机 195／0 | `full-new-pc-07/`、`full-new-phone-10/` |
| 原领域与保存回归 | 59／0（两份完整流程运行均执行） | 上述目录的 `domain_results.json` |
| P0 主入口／导航／安全区／输入／返回渲染回归 | 268／0 | `p0-navigation-14/` |
| 三种最终 Windows EXE 实际启动、拒绝提权、正常退出、原档哈希与 PCK 能力审计 | 三模式 PASS | `windows-graceful-15/windows_modes_results.json`、`runtime-*.log`、`pack-*.json` |
| 最终 Windows 导出日志及构建指纹 | 三包导出完成 | `windows-final-13/`；最终复核运行指纹亦在 `windows-graceful-15/artifacts-*.json` |
| 15 PNG、资源登记、剧情及整理题目内容保持 | PASS | `asset-audit-12/asset_audit.json` |

完整流程回归仍包含四藏点、标签横拖、鼠标与合成触摸整理、非法放置、撤销／重置、ScrollContainer 滚动取消、20 次摸猫、随机重玩、命名前重启、奖励去重和 Q00～Q03 门禁。新增档位经过真实 UI 建立后再跑整段流程，重启仍读该档；旧完成档在另一个真实 UI 用例中切回并核对字节哈希，未使用负责人实际玩家目录做测试写入。

`p1r_asset_audit.py` 原先针对上阶段“session/save 整文件字节未改”的断言，已随本轮授权改为资源／剧情／题目内容审计；新增档位路由不能继续要求源文件逐字节相同。存档行为改由保留的 59 项领域测试及新增模式／档位行为测试验证。审计输出现在要求新证据位置，避免覆盖上阶段记录。

### 已保留的失败与验证限制

- `dev-pc-02/` 首轮浮动 DEV 入口点击未打开菜单，测试随后出现 Dictionary 缺键错误；截图实际为 1920×1009，不能据请求尺寸称为 1280×720。首屏入口已改放现有地图动作栏，增加打开菜单后断言，预览中保留 DEV 返回入口，之后真实 PC／手机测试通过。原生窗口输入时序的根因没有因此被宣称彻底修复。
- `windows-06/` 首轮验证把合法的 PLAYTEST `--new-playtest` 行为误当提权，预期已修正；旧记录保留。
- `windows-08/`、`windows-final-13/` 有包审计／结果 JSON，但归档检查发现保留的 runtime 日志为空。最终改为有限帧正常退出并保留 stdout／stderr，复用同一构建完成 `windows-graceful-15/`，三份 runtime 日志有实际内容且结果通过。以这份正常退出证据作为最终实跑依据。
- 领域日志中的 `file_instead_of_directory` ERROR 是原有故意制造写入失败的回滚测试，不是漏报失败。
- 之前自动审批服务曾因用量限制拒绝执行最后两条命令；负责人要求继续后已成功执行，未把未执行命令计为通过。

本轮为自动化合成鼠标／触摸与真实 Windows 程序验证；真人试玩、Android 真机、Apple 平台未执行，未重新构建 Android 包。P0 偶发合成触摸风险继续开放。PC 原生窗口可能受桌面尺寸限制；原始截图保留实际尺寸，手机截图为模拟竖屏，不是真机。

## 文件、Git 与交付边界

主要新增：`runtime_mode.gd`、`profile_catalog.gd`、DEV 模块工具、`开发DEV.cmd`、`试玩PLAYTEST.cmd`、模式／档位测试、PCK 审计与三包验证脚本。主要修改：`main.gd`、`flow.gd`、`home_controller.gd`、保存构造与根目录解析、原启动器、导出预设、README 和必要 AGENTS 当前阶段索引；原安全、架构与 Git 规则保留。

分支：`codex/p1r-dev-modes`。起点：`0c4af5c2490013d191ce028a670c0fe574e4fb10`。实现提交：`34430529640bbdb816a4aa038c1919a995a971ab`。本报告、证据及 Windows 验证脚本的正常退出优化随后单独归档提交，可由 `git log -2 --oneline` 查验，避免报告自引用提交号。

本轮交付文件与实现均本地提交，不推送远程。旧未跟踪 `docs/evidence/p1-01/` 原样保留，因此不宣称整个工作区完全干净。所有构建、日志、测试档和缓存优先留 E 盘，未下载新工具或改系统设置。

遗留事项：预览运行数据会累积，本轮不自动删除；未设计槽位删除、重命名、云同步或正式存档迁移功能。已有几何家具及其他 P1-01R 美术风险延续，不在本轮重做。请负责人验收新档创建／切回手感与五模块入口；完成后停止，不进入 Q04／Q05。
