# P1-01｜Q00～Q03 连续可玩切片交付

日期：2026-10-29。状态：**程序切片已实现并通过下列自动化/Windows 渲染验证，等待负责人试玩验收**。本轮止于 Q03；没有实施 Q04/Q05、日常轮换池、换装、经济或正式美术。

## 1. 工程与 Git

- 唯一主工程仍为 `E:\俄语游戏\NEXT_STOP_RUSSIA`；Godot **4.7.2.stable.official.ed1daf0bf**、GDScript、2D Compatibility。未重建工程，未重复 P1-00，未下载工具、创建远程或推送。
- 起点 SHA：`906dfd707be6f8e64a50c098eb7ce20c61f8ae4a`，原分支 `master`；实现分支 `codex/p1-01-first-playable`。
- 实现提交 SHA：`7d211a79ada8f38ead5c82b4e518870d7b877974`（`feat: implement P1-01 first playable Q00-Q03`）。此 SHA 指实际交付代码；本汇总随后单独提交，避免自指 SHA。
- 开工时启动包 `docs/design/`、`docs/production/`、`P1-00_ALIGNMENT_SUMMARY.md`、P1 任务书与 `scripts/dev/` 尚未跟踪。保留原文，随本轮纳入版本管理；没有用启动包覆盖原 AGENTS。AGENTS 仅更新阶段授权与依据索引。
- 主 Agent 唯一负责实现与集成；owner=`main`，allowedPaths=`scripts/main.gd`、`scripts/p1/`、宿舍必要接口、`ui/p1_world_label.gd`、`data/p1/`、TEMP 清单、测试与运行配置。QA 子 Agent 只读检查合同/实现/证据，未改文件、未与主进程争用测试窗口。两者 baseSHA 均为上述起点；没有新建 worktree 或第二套工程。
- 交付工作区：源码与启动包已提交；`docs/evidence/p1-01/` 原始证据留 E 盘本地，不作为游戏资源或另行打包交付。构建、便携工具和 `.local-dev/` 已忽略。具体最终状态见末节交付核对。

## 2. 实际可玩内容

| 阶段 | 实现与完成条件 |
|---|---|
| Q00 初来 | 安娜与管理员五段俄语主台词和同步中文字幕；收钥匙后用钥匙入原宿舍。对白/钥匙/入室均保存。文本来自启动包源稿，标 `TEMP_TEXT / REVIEW_PENDING`。 |
| Q01 猫首遇 | 几何猫先可见，连续跑入床/窗/衣柜/书桌之一。藏点绑定物件 ID、世界偏移、标签锚点、前景遮挡与退出路径。首次俄中标签，正确标签同次交互判断；错选不罚、不换位。猫探出并连续走到可摸处，点猫触发抚摸反应。 |
| 首遇奖励及命名 | **抚摸反应完成后**将首遇贴纸/徽章纪念键与 `namePending` 同事务保存。纪念当前是文字/账本记录，没有伪装成已交付正式贴纸图。命名必须输入/选择后确认；未确认不能进 Q02。退出重启恢复命名，不重领奖；返回、Escape、系统返回均不能绕过。 |
| Q02 首次整理 | 宿舍右侧独立「整理」入口，使用原 `org_tutorial_01`。选择物品→点击区域，显示占用容量；支持撤销、重置、确认与退出保留。校验全部放置、仓位、容量、fixedBin、allowedBins、forbiddenTogether。源教程本身仅一解；验证器另用两解 fixture 证明没有匹配写死的 exampleSolution。 |
| Q03 安娜消息 | Q01/Q02 完成后显示安娜两条俄语消息及中文字幕，读完才保存 `cityUnlocked`。给出首段完成反馈；开放原技术地图，宿舍/学校可往返，商店仍锁定。没有大学领资料事件或正式六入口地图。 |
| 后续自由找猫 | 继续四标签→走出→抚摸循环，无关卡/星级/体力，相邻藏点不重复。已命名不再强制取名、不重复发首遇奖。一次测试累计完成 20 次抚摸，其中 11 次由正常「再找」按钮随机重玩；与首次命名状态分离。P0 三点轻互动完整保留在技术模式。 |

没有交付俄语音频；每次标签尝试明确显示“暂无俄语音频 · 文字回退”，未宣称已朗读。重玩以俄语标签为主，「释义」可查中文。NPC 中文字幕与地图语言无关闭联动。本轮未新增地图语言设置。

## 3. 试玩入口与操作

**可直接运行的独立包：** `E:\俄语游戏\NEXT_STOP_RUSSIA\builds\p1-01\NextStopRussia-P1-01.exe`，同目录 `.pck` 必须保留；无需编辑器。受控试玩，标题明确 `ART_PENDING`，不代表正式发行或正式美术验收。

**源码快捷入口：** 双击根目录 `试玩P1.cmd`；或 Godot 打开 `project.godot` 按 F5。常规使用「开始/继续旅程」。在宿舍左右拖动画布；点击实际家具旁的俄语标签；猫走近后点画面中的猫；确认名字后点右侧「整理」；最后读完消息。收纳界面可向下滚动查看确认/撤销/返回按钮。

```powershell
# 正常试玩；只在这个子进程绕过脚本签名策略
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-p1.ps1
# 新独立目录开始，不覆盖旧档
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-p1.ps1 -Fresh
# 仅 DEV 复现；不出现在正常试玩 UI
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-p1.ps1 -Dev -CatSpot by_window
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-p1.ps1 -Dev -Fresh -NamePending
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-p1.ps1 -Dev -TechnicalMap
```

`-CatSpot` 可选 `under_bed/by_window/by_wardrobe/under_desk`。DEV 正常对白完成后可复现指定藏点；`-NamePending` 是明确 DEV fixture，按领域事件造待命名档，不能据此冒充正常连续游玩证据。

## 4. 状态、保存与恢复边界

- schema **1**：Quest Q00～Q03、钥匙/入室/城市、猫品种 ID/名字/首次抚摸/待命名/当前藏点/轮次、整理摆放/撤销历史/教程纪念日期、幂等奖励键。`roundId/petRoundId` 阻止同轮抚摸事件重复结算。
- 原 P0 没有玩家长期存档，故本轮是首个玩家 schema；不虚构旧版本迁移。未来 schema 高于 1 时拒绝覆盖，保留原文件等待对应版本；未知旧 schema 走显式异常/备份路径，后续 schema 必须增加正式迁移函数与 fixture。
- 写临时文件、flush、回读验证后替换主文件；保留上一份有效 `.bak`。坏主档可隔离为 `.corrupt-*` 并恢复有效备份、显示提示；没有有效备份则保留原档、阻止继续，不静默新建覆盖。备份恢复可能退回一个保存事务，不宣称零进度损失或断电级耐久保证。
- 校验结构类型、有限非负整数索引、钥匙/消息/城市与任务状态、空白名字、奖励一致性；写失败回滚内存状态并可见反馈。
- 默认源码数据：`.local-dev/player-data/PLAYTEST/` 与 `DEV/`。独立 EXE：同目录 `player-data/PLAYTEST/`；`NSR_DATA_ROOT` 可指定进程级根目录。所有自动化使用证据目录下隔离数据，不污染默认试玩档。关闭游戏可继续；摸猫前退出重演该轮，摸猫后未命名退出优先恢复命名。
- 不承诺同时运行两个实例写同一个档、云同步、旧版回滚兼容或完整存档迁移系统。

## 5. 宿舍空间参考与 TEMP 资产

参考图已在本地 `docs/references/dorm_layout_camera_reference.jfif`，实际为 **JPEG/JFIF、1280×720、158989 bytes**，文件头 `FFD8FFE000104A464946`；SHA256：`786EF299A2FC2EB913E2CED2C5DF7C1073B4832AD71E48BC2C375E41EDA80446`。按实际格式查看，未仅改扩展名，也未转换/描摹/提取素材。它只用于观察空间层次、略高视点、床桌侧面和前中后关系；已从游戏打包排除，并保留本地参考。

本轮仍使用 P0-03R 横向房间、有限平移、原投影和家具遮挡。没有推翻 P0、重新定稿角度/配色/家具位置；未来可按正式交付调整镜头和物件位置。窗是固定构件，新增窗台几何用于第四藏点，不伪装成第四个 P0 家具节点。

登记在 `assets/temp/p1_manifest.json`：逐项保留 assetId、source、licenseNote、targetSlot、尺寸/锚点/图层、`TEMP_REPLACE_REQUIRED`、`permanentApproval=false`；代码绘制的房间、床桌柜窗、猫、两 NPC 文字身份、对话/命名/整理/反馈、物品与纪念记录均为可替换占位。原创形状与现有 P0 几何，没有下载或生成外部美术；系统字体为本机回退，未打包未经授权的字体文件。

**需要外部提供：** 按 `bed/desk/wardrobe/window` 稳定槽位交付独立背景/家具图层及前景遮挡、世界锚点和点击区；猫耳/头/身/尾的正式素材与跑/探头/走出/抚摸规格；安娜/管理员角色图（当前只有文字身份）；整理物品/仓位图、首遇贴纸徽章、字体/俄语音频及使用授权。最终像素尺寸、画风、镜头和配色由批准的美术规格确定，当前世界尺寸/控件尺寸只是技术交接基准。

## 6. 实测结果与命令

环境：Windows，OpenGL 3.3.0 NVIDIA 610.88 / RTX 3070 Laptop GPU。以下手机画面全部为 Windows 模拟竖屏，触摸全部为 Godot 管线的合成输入。P1 流程测试以 `Engine.time_scale=3` 加速等待动画，不跳领域状态；独立包验证按正常速度。计数按各套断言分别列出，不混算成真人体验通过率。

以下路径统一相对 `docs/evidence/p1-01/`：

| 实际执行 | 结果 | 原始证据 |
|---|---|---|
| P1 领域最终版 | **59/0** | `domain-final-02/domain_results.json`；`rendered-portrait-final/domain_results.json`、`headless-final/domain_results.json` |
| P1 PC 新档连续 Q00→Q03、四点横竖屏与随机重玩（首轮渲染版） | **163/0** | `rendered-01/playable_results.json` 与 PNG |
| P1 模拟竖屏新档完整 Q00→Q03、滚动命名/收纳、四点横竖屏与重玩（最终版） | **172/0** | `rendered-portrait-final/playable_results.json` 与 17 张 PNG |
| P1 最终版 Headless 完整流程 | **155/0** | `headless-final/playable_results.json`；不含渲染断言 |
| P0 导航 Windows Rendered | **268/0** | `p0-regression-01/run/rendered_results.json` |
| P0 家具空间/遮挡 Windows Rendered | **252/0** | `p0-regression-01/dormitory/spatial_results.json` |
| P0 V 构图 Windows Rendered | **684/0** | `p0-regression-01/composition/composition_results.json` |
| P0 R 首轮普通窗口 | **437/6，失败保留** | `p0-regression-01/ribbon/ribbon_results.json` |
| P0 R 无边框同尺寸受控矩阵（增加尺寸/输入记录与 5 个尺寸断言） | **448/0** | `p0-ribbon-controlled-01/ribbon_results.json`、`window_input_trace.json` |
| P0 三点自由找猫 Windows Rendered | **633/0** | `p0-cat-rendered-01/cat_hunt_results.json` |
| Windows P1 独立 EXE 完整 Q00→Q03、资源隔离与真实渲染 | 最终包 **11/0**，初包亦 **11/0** | `windows-package-final/package_results.json`、`artifacts.json`、三张 PNG；初包在 `windows-package-01/`。隐藏测试窗口、引擎合成点击 |
| 实际 DEV `--name-pending` 启动 | 待命名、Q01 active、奖键一次，PLAYTEST 文件不存在 | `dev-fixture/result.json` |

核心复测命令（EvidenceDir 必须换新目录，脚本拒绝覆盖）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/p1.ps1 -Rendered -FullPortrait -EvidenceDir docs/evidence/新目录
powershell -NoProfile -ExecutionPolicy Bypass -File tests/p1.ps1 -EvidenceDir docs/evidence/另一新目录
# 实际已顺序执行原 run/dormitory/composition/ribbon 的 -Rendered；R 失败后另行继续 cat_hunt
powershell -NoProfile -ExecutionPolicy Bypass -File tests/cat_hunt.ps1 -Rendered -EvidenceDir docs/evidence/新P0猫目录
# 受控 R：仅这个进程的测试 fixture 无边框，生产输入逻辑未改
$env:P1_BORDERLESS_MATRIX='1'
powershell -NoProfile -ExecutionPolicy Bypass -File tests/ribbon.ps1 -Rendered -EvidenceDir docs/evidence/新R目录
# 现有同版本模板导出受控包，再实际运行
powershell -NoProfile -ExecutionPolicy Bypass -File tests/verify_p1_windows.ps1 -Build -EvidenceDir docs/evidence/新包目录
```

新增覆盖包括：奖励前退出、奖励后未命名恢复、空名/超长名、名字混合俄中保存、重复事件幂等、三路返回门禁、非法收纳/撤销/重入、多解判题 fixture、坏 JSON/畸形 schema/小数索引/未来版本、无备份坏档保留、写失败不推进、DEV/PLAYTEST 隔离、标签拖动不误选、四处真实可见线索及物件坐标一致、随机重玩与地图重入。P0 原独立射线/像素遮挡断言保留；没有声称 P1 补间路径已另做物理碰撞/独立几何 oracle。

**真实失败与修正：**

- `import-01/`、`headless-01/`：初版脚本类型推断/测试 PackedStringArray API 解析问题，已修正；不是可用通过记录。
- `headless-02/`：测试把 ScreenTouch 直接推入 viewport，没有经过项目的 touch→mouse 转换；改用已有 P0 的 `Input.parse_input_event` 与物理坐标变换。流程失败与超时/中止日志保留。
- `headless-03/`：暴露竖屏衣柜标签出界，调整家具**世界标签偏移**；测试另修正拖到夹紧边界时“必须移动”的错误预期，改核对实际夹紧值。未降低原 P0 断言。
- `domain-final/` 虽计数 59/0，畸形 schema 仍出现脚本比较错误，**不算有效通过**。随后先检查数值类型再比较，`domain-final-02/` 及后续完整套件无该脚本错误；测试脚本现会拒绝仅计数为绿但有 SCRIPT ERROR 的轮次。
- QA 发现旧词汇反馈跨轮残留、重进整理沿用旧选择，已清理并增补最终版断言。原 `rendered-01/` 仍保留。
- 领域测试故意使用“文件代替目录”注入写失败，会出现 `Could not create directory ... file_instead_of_directory/PLAYTEST`；这是预期诊断，断言验证未推进进度，不是未处理脚本错误。

## 7. 风险、未测与验收建议

1. **历史偶发触摸风险仍开放。** 本轮普通 R 窗口在首个手势期间由 1920×1080 改为 1920×1026，画布/比例从 1224×481/1.19242 变为 1291×481/1.25769；直接解释两次连续性和三次“不缩放”失败。受控追踪记录屏幕 1920×1080、可用桌面 1920×1032，普通带边框客户区超工作区是合理原因推断。书桌触摸选择失败没有首轮逐事件证据，不能确认同因。无边框矩阵448/0及本轮找猫633/0 **不代表原 P0-04 首轮 9 项已修复**；不改生产输入、不删除失败、不挑绿覆盖。
2. **真人与真机未验收。** Android APK 本轮未重建、没有 Android/iOS 真机；macOS/Apple、手机安全区/系统手势/生命周期、触摸舒适度及性能未测。尝试 computer-use 额外原生操作前，node_repl 即因 `helper_unknown_error: setup refresh had errors` 退出；没有执行该额外操作。实际 PNG 审图和引擎内合成输入不能代替真人试玩；真实键盘 IME 输入未单独测。
3. **视觉与内容仍 TEMP。** 灰盒宽视野容易看见猫；窗口处标签可能挡住部分轮廓，真实发现感、可点击大小、收纳滚动操作和故事节奏待负责人试玩。几何猫不是正式西伯利亚猫造型；逐句俄语未做母语校审，无配音，无正式字体/角色/贴纸图。
4. **存档边界。** 原子替换与备份做了异常 fixture；未模拟突然断电/磁盘满、多实例竞争、外部同步或跨版本真实迁移，不保证这些条件。部署到不可写安装目录会明确提示，需通过可写路径或 `NSR_DATA_ROOT` 配置。
5. **环境限制。** exec/node_repl 普通沙箱初始化失败，实际命令经审批在本工程范围执行；签名策略只对子进程 `ExecutionPolicy Bypass`。复用 E 盘便携工具，缓存/测试/构建/玩家数据优先 E 盘，未改系统注册表/用户目录/全局变量。Windows/Codex/驱动本身可能有必要 C 盘写入，不宣称零占用。

负责人建议先从独立新档体验一遍，再关闭并恢复命名/整理中间状态。需确认正式美术交付规格与资源授权、临时俄语文案、昵称规则（当前临时 1～20 字符）、猫出场节奏、小屏标签与收纳体验。当前教程采用启动包提供的 PROPOSED 唯一解样题，不代表题目已正式定稿、日常整理池已开发或趣味已通过。

## 8. 文件变化与交付核对

| 范围 | 文件 |
|---|---|
| 授权/运行说明 | `AGENTS.md`、`README.md`、`.gitignore`、`试玩P1.cmd` |
| 原导航最小增量 | `scripts/main.gd`、`scripts/building_room.gd` |
| 原宿舍最小接口 | `scripts/dormitory/dormitory.gd`、`room_world.gd`、`room_view.gd`；原 `cat_hunt.gd`/`cat_placeholder.gd` 与三家具场景未重写 |
| P1 状态/内容/UI | `scripts/p1/content.gd`、`session.gd`、`save_store.gd`、`organization.gd`、`cat_encounter.gd`、`home_controller.gd`、`flow.gd`、`ui/p1_world_label.gd` 及 `.uid` |
| 内容与资源清单 | `data/p1/content.json`、`organization_tutorial.json`、`assets/temp/p1_manifest.json` |
| 工具/导出 | `scripts/dev/play-p1.ps1`、复用的 `use-e-drive.ps1`、`project.godot`、`export_presets.cfg`、显式包验证 `scripts/p1/package_check.gd` |
| 新测试 | `tests/p1.ps1`、`p1_domain_tests.gd`、`p1_playable_tests.gd`、`p1_window_trace.gd`、`verify_p1_windows.ps1` 及 `.uid` |
| 原测试入口 | run/dormitory/composition/ribbon/cat_hunt/cat_touch_probe 在实例化前显式选 P0 technical_mode；package_entry 仅验证参数下选技术模式。原断言保留；R 额外可选无边框/记录与 5 个尺寸断言。 |
| 原样纳入的启动资料 | `docs/design/`、`docs/production/`、`docs/tasks/P1-01_FIRST_PLAYABLE_TASK.md`、`docs/reports/P1-00_ALIGNMENT_SUMMARY.md`；后者仍明确为主线提供的历史对齐材料，不是本轮重新审计。 |
| 唯一阶段汇总 | 本文件 `docs/reports/P1-01_SUMMARY.md`；原始日志/截图在 E 盘证据目录，不另交多份报告。 |

最终包核对（`windows-package-final/artifacts.json`）：

- `NextStopRussia-P1-01.exe`：109268480 bytes；SHA256 `D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562`。
- `NextStopRussia-P1-01.pck`：124456 bytes；SHA256 `1500010AF5E077C3F86412A47D49B4325B6577C9579384BABF8F74882766966D`。
- 最终包已重新导出以包含逐项 source/licenseNote/status 的完整 TEMP 登记，并实际运行 11/0；不包含参考图/策划文档/测试目录/工具密钥。
- 实现提交后 `git status --short` 仅为本汇总和 `docs/evidence/p1-01/` 未跟踪；汇总单独提交后，预期只留下本地原始证据目录。没有待提交的生产代码修改，也没有推送。最终 Git/产物快照留 `docs/evidence/p1-01/delivery_snapshot.json`。

**本轮完成后停止在 P1-01，等待项目负责人试玩与主线验收，不自动开始 P1-02。**
