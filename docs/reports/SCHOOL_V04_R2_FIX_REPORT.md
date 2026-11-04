# 学校 V0.4 R2：修复、手机竖屏还原与可试玩交付

日期：2026-11-04。最终版本：**V0.4-R2.3-Portrait / PLAYTEST**。

已完成学习闭环和本轮 Windows 试玩构建；**等待负责人重新进行视觉与教学内容验收**。本报告不把测试通过等同于最终美术验收，也不宣称手机真机已通过。

## 1. 当前入口与运行方法

| 入口 | 行为 |
|---|---|
| 根目录 `学校竖屏试玩V04.cmd` | 推荐。450×800 竖屏独立学校，复用同一学校场景与服务 |
| `学校黑板课堂V04.cmd` | 同样默认竖屏；加 `-Landscape` 为 1280×720 横屏 |
| `试玩学校整合版V04.cmd` | 主游戏横屏入口，沿用原 Q00～Q03 解锁学校的流程 |
| `试玩学校整合版V04.cmd -Portrait` | 主游戏竖屏窗口；进入学校后使用独立竖屏页面 |
| `builds/school-v04-r2/NextStopRussia-School-V04-R2.exe` | 直接运行独立学校，需同目录同名 PCK |
| `builds/school-v04-r2/NextStopRussia-Integrated-V04-R2.exe` | 直接运行主游戏整合包，需同目录同名 PCK |

推荐试玩：选择“学习新词” → 数量 1 或 5 → “开始学习” → 逐张预习 → “开始测验” → 四选一；可故意答错、暂停恢复，观察强化已正确 1/2、再次出错保留该次数，全部目标词通过后进入结算。选择 1 词时会额外预习三个辨认辅助词，辅助词不计入本轮目标。

当前只有 **6 个开发示例词**。准备页常用档位只显示当前可用值，竖屏下拉框可选择 1～实际可学数；不会展示可点的 10/20 假档位。全部首学后明确说明没有可学新词，提供词本和有明确“自由复习”说明的已学词复习。字母入门保留独立入口。

源码运行与构建核对：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-school.ps1 -Source
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-school.ps1 -Source -Integrated -Portrait
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-school.ps1 -VerifyOnly
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-school.ps1 -Integrated -VerifyOnly
```

启动器输出版本、二进制完整路径、入口和存档根目录，并按 `build_manifest.json` 验证 EXE/PCK 的 SHA256。缺失或不匹配时拒绝运行该配对；显式 `-Source` 使用现有 Godot 4.7.2。旧 `builds/school-v04/` 和旧 P1 构建保留，旧 `试玩整合版PLAYTEST.cmd` 增加了非 R2 入口提示。

## 2. P0：经过验证的根因

**主根因是字母硬门禁导致“学习新词”按钮被禁用，而禁用外观又像可点击按钮。** 不是按钮没有连接事件，也不是六词词库为空。

复现使用玩家原学校 sidecar 的副本，原文件未重置。旧 Windows R1 二进制确实出现点击后停在首页；随后在旧源码中通过实际鼠标事件记录了以下状态：

| 检查项 | 修复前 | 修复后同一存档副本 |
|---|---|---|
| 可学新词 | 6 | 6 |
| 请求数量 | 5 | 5 |
| 字母是否完成 | false | false |
| pressed 连接数量 | 1 | 1 |
| 按钮 disabled | true | false |
| 点击位置 | (514.2, 532.0) | (514.2, 532.0) |
| 点击后页面 | home | preview |
| 是否创建学习会话 | false | true |

证据：[修复前](../evidence/school-v04-r2/p0-before/reproduction.json)、[修复后](../evidence/school-v04-r2/p0-after/reproduction.json)，同目录包含截图和日志。按钮矩形命中，事件连接存在，disabled 状态已经足以阻止信号发出；原版本也存在数量超过剩余词时静默禁用的代码路径。未把该次问题归因于老师遮挡、存档损坏或误开旧构建。

修复：当前六词演示的字母学习改为独立引导，不再作为新词的硬门禁；业务不可开始时显示具体说明，保留返回/重新选择入口。模式选中有绿色卡片和对勾，开始按钮单独命名为 StartStudy。日志记录按钮、请求数量、真实可用量、存档路径、持久化结果与页面流转。最新启动器与标题栏使旧构建容易辨认。

实际用户学校档在本轮前后 SHA256 一致：

`8F7DE75BB3F8D9B6475734AF1312DFFBF58005046AD58141EA9C7279C4203630`

## 3. P1：实际实现的学习流程

`学校入口 → STUDY_PREPARATION → WORD_PREVIEW → QUIZ_BLACKBOARD → RESULTS`

- 五种页面容器分别管理。准备、预习和结算使用羊皮纸；只有测验/分轮强化显示黑板。
- 准备页提供新词、复习、直接打开词本；数量、计划与开始说明来自真实状态。没有模式时点击开始会提示先选模式。
- 预习显示重音词形、中文词义、已有词性，支持上一张、下一张、末张开始测验和保存后返回准备。没有审校例句/录音时如实说明。
- 新题为四个互异有效选项。少量目标会先补齐辨认辅助词；预习只写 introduced，不增加目标数量或 firstLearned。
- 首次答错后仍需间隔累计独立答对两次；强化期间再次答错不增加要求、不清零已正确次数。提示/查询词本按原辅助作答规则处理。全部目标词通过才结算。
- 题目、正确/错误标记、通过数、待强化数和词本全部为动态控件和真实数据；没有使用参考整图冒充交互页面。
- 暂停、退出、返回地图重入保留会话与反馈。学校使用原档位目录中的独立 `school_v04.json`；快捷课堂使用独立 school-demo 命名空间，不改原主线 save.json 合同。
- 旧未作答三选题先补预习必要辅助词，再扩为四选题，保留题目 ID、目标、计数和辅助状态；旧已提交三选题反馈逐字段保留，继续后新题使用四选。schemaVersion 保持 1。
- ThemePresenter 继续只接收界面事件，不承担判题和存档。火车/幻灯机仅保留接口，本轮没有实现其他主题或玩法。

## 4. P2：手机竖屏与视觉对照

依据最新用户授权，**手机竖屏优先，横屏保留**。两套页面共享领域服务、词库、存档和题目事件，分别排版。没有改变地图、宿舍或整理的画面规则。

[打开完整参考图/实际截图对照页](../evidence/school-v04-r2/visual-review/index.html)。其中最终 PNG 均为 Windows Godot 导出包原始截图；网页只按比例展示，未重绘、修饰或拼造游戏内容。

| 区域 | 本轮实际还原 | 仍有差异 |
|---|---|---|
| 准备页 | 大幅竖向木框纸张、顶部建筑纹样与莓叶、三张纵向模式卡、数量区、计划、气泡、下方绿色 CTA、老师右下 | 雕花和图标细节不是原画逐像素复制；未增加参考图中的经济系统和假资源数字 |
| 答题页 | 纵向木框绿黑板、粉笔题型和题面、A–D 四行按钮、实际进度条、正确发光/错误标记、右侧老师、底部功能键 | 背景窗景、书架、茶具与原画细节不同；反馈需要额外的动态说明与继续按钮 |
| 老师与输入 | 复用提供的四个独立透明老师素材；答案区避让上半身，下半身在答案下方显示自然轮廓；装饰不接管点击 | 现有立绘姿态和原画裁切不完全一致，最终角色美术验收未定 |
| 中文/俄文 | 中文使用温暖手写方向的系统字体回退；俄文使用已验证的 Times New Roman，重音不额外占位 | 字体未内嵌；其他系统和手机需要再次验证回退效果 |
| 横屏 | 保留宽纸张、横向三模式卡、右侧老师及辅助键；同步四选题为 2×2 | 长反馈和词本可滚动；优先保留已完成的横屏构图，没有强行做成竖屏的横向复制 |

本机 Georgia 的 `кни́га` 在 50px 字号宽 161px，而无重音为 136px；Times New Roman 两者均为 121px。已切换学校俄文字体，并核对五个带重音示例词。仅保留字体名称，不分发 Windows 字体文件。

真实截图入口：[准备已选](../evidence/school-v04-r2/final-portrait/02_preparation_selected.png)、[预习](../evidence/school-v04-r2/final-portrait/03_preview_first.png)、[待答四选题](../evidence/school-v04-r2/final-portrait/05_quiz_ready.png)、[错误](../evidence/school-v04-r2/final-portrait/07_wrong.png)、[强化 1/2](../evidence/school-v04-r2/final-portrait/08_strengthen_1.png)、[强化再次出错](../evidence/school-v04-r2/final-portrait/09_wrong_after_strengthen_1.png)、[结算](../evidence/school-v04-r2/final-portrait/10_results.png)、[无新词](../evidence/school-v04-r2/final-portrait/11_no_new_words.png)。

美术资源：复用原四张老师；新增独立横屏背景/空白框和竖屏背景、纸张、黑板、三图标 atlas，配合原创 SVG 控件。资产以 `assets/art_registry.json` 为权威，sourceType 与 retentionStatus 分开登记，均未自动标 FINAL_APPROVED。生成提示与原始来源分别保留在 `docs/art-prep/school-v04-r2/` 和 `docs/art-prep/school-v04-portrait/`。参考图仅保存在 docs，不进入运行包。

## 5. P3：实际测试、原生窗口操作与证据

机器环境：Windows、Godot 4.7.2 Stable、Compatibility/OpenGL、RTX 3070 Laptop GPU。所有测试数据使用单独的 evidence/player-data；未用作弊完成字母或直接调用 start/submit 替代最终包内玩家流程。

| 测试 | 实际结果 | 证据 |
|---|---:|---|
| 学校领域：背词、强化、SRS、事务回滚、备份/迁移等 | 57 / 0 | `core-final/school_domain_tests/domain_results.json` |
| 旧三选题存档兼容 | 6 / 0 | `core-final/school_fourchoice_compat/compat_results.json` |
| 主档位与学校侧档隔离 | 12 / 0 | `core-final/school_integration_tests/integration_results.json` |
| 最后布局：横竖屏、安全区、长文、触摸单次提交 | 43 / 0 | `ui-release/ui_results.json` |
| 按下/松开跨帧稳定性及俄语重音 | 9 / 0 | `font-input-final/stability_results.json` |
| 素材、六词内容、保护文件审计 | 174 / 0 | `asset-scope-delivery/asset_scope_results.json` |
| 最终独立包竖屏：5 词含强化、暂停恢复，再学剩余 1 词、空词提示和词本 | 80 / 0 | `final-portrait/e2e_results.json` |
| 最终整合包：地图→学校，6 词完整学习 | 46 / 0 | `final-integrated/e2e_results.json` |
| 最终整合包 Q00～Q03：原找猫、命名、空间整理拖放和城市解锁 | 14 / 0 | `final-integrated/p1_package_results.json` |
| 原领域/剧情可玩性/三模式/整理/猫/导航 | 55 + 168 + 61 + 53 + 540 + 254，全为 0 失败 | `protected-regression-02/`（共 1131 项） |

上述路径均相对于 `docs/evidence/school-v04-r2/`。[机器可读汇总](../evidence/school-v04-r2/test_summary.json)；最终两个包的测试目录均保存 `tested_build_manifest.json`，与交付文件哈希一致，避免把旧包测试结果算给新包。

最终包内演练使用实际 Viewport 鼠标按下、等待四帧、松开、页面转移和截图；判题结果只作为只读核对，不直接修改学习状态。覆盖真实 941×1672 竖屏与 1920×1080 横屏。另有 1280×720 原生窗口，以及 1280×800、360×780、1080×1920、1170×2532 和模拟刘海/底部安全区的引擎布局证据。没有把大词量合成夹具称为正式词库。

**原生 Windows 桌面操作另行执行：** R2.2 字体修正前的两个 EXE 均以真实桌面点击完成“准备→四张词卡→四选题→1/1 结算”，整合入口从真实地图标牌进入。截图与逐次点击记录在 `native-windows/`。该目录明确记录 R2.2，未冒充最终 R2.3 包截图；最终 R2.3 标题和默认竖屏窗口也已核对，完整最终包则以上述两个实际 Windows GUI 演练结果和截图为准。

原生整合测试仅把已通过包内 Q00～Q03 的测试主档复制到新构建旁的临时 player-data，没有预置学校学习档。原生控制中数量和结算各出现过需要重新观察后重试的点击，原记录保留；没有将其假称一次点击全部成功。补做的跨帧按下/松开检查未发现布局改变或控件被遮挡。该现象的桌面注入原因未定，保留为后续真人试玩观察项。

构建旁的临时测试数据已归档到 `native-windows/archived-portable-player-data/`，最新 EXE 目录不携带已完成的测试进度；启动器沿用的原玩家目录没有移动或清空。

失败历史保留：早期安全区边界、旧断言、兼容测试数值序列化比较和诊断脚本解析错误均在后续修正；相关失败日志不删除。最终选定测试结果无失败。部分 Godot 日志仍有受限运行环境下 user:// 或 shader cache 写入警告；E 盘独立学习存档与真实渲染均已验证，未声称环境日志零警告。

## 6. 修改文件与保护范围

| 文件/目录 | 实际作用 |
|---|---|
| `scripts/school/school_view.gd`、`portrait_pages.gd` | 独立页面、横竖构图、动态按钮、状态反馈、老师与安全点击区域 |
| `scripts/school/study_service.gd`、`content.gd` | 可开始校验、四选题和辅助预习、旧会话兼容；保留强化与复习合同 |
| `scripts/school/theme_presenter.gd`、`build_info.gd` | 独立主题显示与构建标识 |
| `scripts/school/progress_store.gd`、`data/school/*.json` | 复用上一轮独立侧档和六词/字母内容；未扩充成正式课程 |
| `scripts/school/demo.gd`、`scenes/school_demo.tscn`、`scenes/buildings/school.tscn` | 快捷课堂与同一主游戏学校入口 |
| `scripts/main.gd` | 注入现有档位目录；显式 PLAYTEST 参数下接入验收器 |
| `scripts/school/playthrough_probe.gd`、`integrated_package_check.gd` | 明确开启才运行的隔离 GUI 包内验收 |
| `assets/school/r2/`、`assets/school/portrait/`、`assets/art_registry.json` | 分层美术、原创 UI 状态与来源登记 |
| `export_presets.cfg`、`project.godot` | 学校导出预设、学校构建主场景 feature 覆盖与数据打包 |
| `scripts/dev/play-school.ps1`、三个学校 CMD、旧整合 CMD 提示 | 新构建入口、横竖屏选择、哈希核对 |
| `scripts/dev/build-school-r2-vectors.py`、`register-school-r2-assets.py`、`write-school-r2-manifest.py`、`build-school-review.py` | 可重建资源、登记、构建清单和对照页 |
| `tests/school_*.gd`、`tests/school*.ps1`、`tests/school_asset_audit.py` | 领域、UI、隔离、兼容、输入/字体和保护范围测试 |
| `tests/cat_hunt_tests.gd` | 只修正既有 SafeLayout 子节点归属的过时断言，未修改猫咪运行逻辑 |
| `README.md`、本报告、`docs/evidence/school-v04-r2/`、美术来源记录 | 最新入口、根因、真实证据、失败历史与限制 |

保护审计对原基线 `3d0e0f7fda640fd72dab3d0e30afb33bcc17441d` 核对：地图 PNG/地点配置、Q00～Q03 内容、主线 session/save_store/profile_catalog/runtime_mode/flow、猫咪、宿舍世界和空间整理 model/view 均未改动。既有与本轮无关的未跟踪目录未清理。工作树仍未提交，未推送、未发布到外网，未进入 Q04/Q05 或其他玩法。

## 7. 剩余问题和验收边界

1. **视觉仍须负责人确认。** 页面布局、层次、材质与交互已按参考重建；背景插画细节、雕花、图标和老师姿态不是逐像素复刻。对照页直接显示差异，不给虚构的“还原百分比”。
2. 只有六个示例词和 33 字母，未提供正式课程审校、真实录音和审校例句；听音题不出，发音按钮明确不可用。未编造音频播放。
3. 当前交付 Windows EXE 的竖屏效果与模拟触摸/安全区；**本轮未交付新 Android/iOS 包、未做手机真机、后台恢复和移动 GPU 性能验收**。系统字体回退亦需真机验证。
4. 极长题面使用可滚动区域，长反馈/词本可以滚动；横屏个别反馈需滚动到继续按钮。没有宣称任意未来词库文本都已做人工排版验收。
5. 实际满盘、断电、操作系统级写入权限变化未做破坏性实机实验；已做领域事务回滚、备份恢复与未来 schema 不覆盖测试。
6. 原生桌面注入偶发需重试的现象保留证据，尚未以真人连续触摸复测定性；本轮不把已有历史触摸风险宣布为彻底解决。

交付定位：可实际完成学习流程的黑板课堂 PLAYTEST，手机竖屏为主、横屏保留，等待玩家重新试玩和负责人视觉验收。
