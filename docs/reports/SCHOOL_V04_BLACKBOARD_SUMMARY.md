# 学校俄语学习系统 V0.4 · 黑板课堂交付

> 历史 R1 报告。当前启动方式、四选题、竖屏页面及修复结果以 [R2 交付报告](SCHOOL_V04_R2_FIX_REPORT.md) 为准；本文件保留上一轮记录。

日期：2026-11-04。状态：**可运行的受控试玩版本；工程自动化与 Windows 导出验证完成，等待负责人视觉、教学内容和真人试玩验收。** 本轮依据用户最新学校开发授权及输入包 BLACKBOARD_UI_SPEC.md 实施；未进入 Q04/Q05 或其他玩法开发。

## 试玩入口

1. 双击工程根目录 `学校黑板课堂V04.cmd`：直接打开课堂，不修改主线进度。
2. 双击 `试玩学校整合版V04.cmd`：打开新整合包，从现有地图和 Q00～Q03 流程进入学校。已有完成主线的试玩档可直接选择学校；新档仍需完成既有宿舍引导。
3. 可直接运行 `builds/school-v04/NextStopRussia-School-V04.exe` 或 `NextStopRussia-Integrated-V04.exe`。同名 `.pck` 必须与 `.exe` 放在一起。构建大小与 SHA-256 见 `docs/evidence/school-v04/delivery_builds.json`。

推荐路径：字母学习（33 张卡片和大小写辨形，可重学）→ 学习中心选 1/2/5/6 新词 → 逐张预习（可前后翻页）→ 开始测验 → 故意答错 → 点击继续 → 间隔后累计独立答对两次 → 所有目标词通过 → 结算 → 俄语记事本。字母与词卡列表需要时可滚动。

鼠标/触控点选，键盘可通过原生控件焦点操作；整合版 Escape 沿用返回地图并保存。底部可暂停保存，或返回校园。中文选俄语题的目标词音频在作答前不开放；当前实际没有录音，所有发音入口均明确禁用。

源码启动：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-school.ps1 -Source
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/play-school.ps1 -Source -Integrated
```

脚本优先使用本轮新 EXE，`-Source` 才使用现有 Godot 便携引擎。没有新包时自动回退源码。旧 `试玩整合版PLAYTEST.cmd` 仍指向旧构建，未覆盖该历史产物。

## 基线和实际实现范围

沿用 Godot **4.7.2.stable.official.ed1daf0bf**、GDScript、2D Compatibility、唯一主工程；没有新增 Web/Unity 工程或下载引擎。P0 检查记录见 `SCHOOL_V04_P0_INSPECTION.md`。

| 阶段 | 本轮实际实现 |
|---|---|
| P0 | 检查学校占位场景、BuildingRoom 导航、P1 模式/档位/存档、系统字体与横竖屏安全区；阅读输入包功能/UI/验收/美术要求；保留其他玩法 |
| P1 | 内容索引与校验；33 字母独立状态；词卡预习；三题型工厂及音频资源门槛；词级强化状态机；间隔调度；持久化题目、反馈、队列、种子和计数；复习与来源/解锁接口 |
| P2 | 木框绿色黑板、独立老师四姿态、动态题面和答案；真实分段进度、正确/错误/强化/辅助反馈；预习、暂停、设置、记事本和结算；横屏三选项一行、四选项 2×2，竖屏纵向重排并可滚动 |
| P3 | 替换真实学校占位场景，保持 BuildingRoom 返回合同与原有剧情门禁；学习侧档按现有模式/档位隔离；增加同一场景的课堂快捷试玩入口；剧情例句、主题包、小游戏解锁提供可测适配接口 |
| P4 | Godot 内核、真实渲染/合成鼠标与触摸、主工程档位集成、受保护文件/素材审计、旧测试回归；实际生成并运行学校及整合 Windows 包。真人与移动真机验收仍未执行 |

实际可见内容只有输入包的 **6 个示例词和 33 字母**。没有复制词条凑数；10/20 新词不足时禁用。自动测试中使用 24 个明确标识 `test.fixture.* / TEST_* / 测试夹具_*` 的内存数据覆盖 10/20 词场景，它们不会进入运行词库或导出包。

## 学习规则、存档与集成

- 未错过的词首次独立正确即可本轮通过。首次错误或辅助作答进入剩余正确 2 次；强化正确减 1，再次错误保持剩余次数，不增长要求，也不清空已正确次数。不同词通过数单调增加，全部目标词通过才结算。
- 默认优先穿插至少 2 个不同目标词；题型方向和正确选项位置在重测时变化。目标词不足或其他词均通过时，展示明确“分轮强化”，等待 5 秒后继续。不会用重复问题伪装更多新词，不会饿死待强化词。
- 题目 ID 防止重复提交；先原子保存，再展示反馈。错误说明和强化反馈均由玩家主动继续。提示标记 assisted；未答题时打开记事本同样标记辅助并暂停，不能通过查词绕过独立正确要求。
- 每张已显示词卡立即记录 introduced；字母浏览/辨形、discovered、introduced、firstLearned、到期复习分别保存。预习或发现不会冒充首学完成。
- 独立学校 schema v1，临时写入、校验、备份、原子替换；失败不提交内存状态。损坏主文件可恢复有效备份并保留异常原件；无备份、未知未来版本或缺失内容引用时停止写入并显示原因。含可测学校 schema 0 的增量迁移；不把主游戏存档当学校数据读取。
- 整合学校侧档：`<现有 NSR_DATA_ROOT>/<DEV|PLAYTEST|RELEASE>/[profiles/<档位>/]school_v04.json`。原 `save.json` 的结构、内容与字节不会因学校学习被改写。
- 两个新启动脚本默认使用工程 E 盘 `.local-dev/player-data`。快捷课堂保存于 `PLAYTEST/school-demo/school_v04.json`，与主线档位隔离；源码和新 EXE 经脚本启动可共享此快捷课堂档。直接双击 EXE 且未配置 NSR_DATA_ROOT 时，沿用现有存储规则，保存到 EXE 旁的 `player-data`。测试全部使用 `docs/evidence/school-v04/*/player-data` 等独立 E 盘目录，没有读取或重置玩家旧档。
- 复习采用可注入时钟的 1/3/7/14/30 天简单间隔。出错后缩为 1 天并记录 lapse；支持到期与自由复习。当前项目没有独立教学游戏日历，默认使用时间戳计算间隔，没有连续登录奖励或生活系统门禁。
- `discover(wordId, occurrence)` 仅接收标记已核对的来源，按词条及 sourceId/exampleId 去重。`story_event`、持久化 events 和 learning_event 信号提供词包可用、首次学完和永久解锁接口。咖啡店词包属于接口测试数据；没有新增咖啡店玩法，也未编造或注入主线对白。

## 真实测试结果

以下各项均实际执行；日志和 JSON 保留在 `docs/evidence/school-v04/`。

| 测试 | 通过 / 失败 | 证据 |
|---|---:|---|
| 学校内核、真实 E 盘保存、注入跨天时钟、10/20 词夹具 | 57 / 0 | `final-02/domain_results.json` |
| 实际 Windows 渲染、鼠标、竖屏合成原生触摸、长文本、安全区、恢复、提示和设置 | 43 / 0 | `ui-delivery/ui_results.json`、`runtime.log` 和 PNG |
| 主工程真实学校导航、档位切换、原主线文件哈希保护、Escape、门禁 | 12 / 0 | `final-02/integration_results.json` |
| 素材解码/尺寸/alpha/来源哈希、既有资产登记和玩法文件保护 | 97 / 0 | `asset-scope-final/asset_scope_results.json` |
| 学校导出 EXE：资源加载→预习→错误→保存读回→两次独立强化→全部结算 | 6 / 0 | `package-delivery/package_results.json` 和截图 |
| 新整合导出 EXE：原 Q00～Q03 实际 UI、找猫、命名、整理与结算 | 14 / 0 | `integrated-package/package_results.json` 和截图 |
| 原 P1 领域 | 55 / 0 | `regression-01/p1_domain_tests/test.log` |
| 原首段可玩流程 | 168 / 0 | `regression-01/p1_playable_tests/test.log` |
| 原模式/档位隔离 | 61 / 0 | `regression-01/p1_modes_tests/test.log` |
| 原行李原型 DEV | 53 / 0 | `regression-02/luggage_prototype_tests/test.log` |
| 原找猫 | 540 / 0 | `regression-04/cat_hunt_tests/test.log` |
| 原地图/宿舍/学校导航、缩放方向与输入 | 254 / 0 | `regression-04/run_tests/test.log` |

UI 自动化覆盖 1280×720、1920×1080、1280×800、360×780、1080×1920、1170×2532，以及模拟顶部/底部安全区。运行显卡为 RTX 3070 Laptop / OpenGL 3.3 Compatibility。截图是实际 Godot 渲染，不是静态参考图或网页稿。

验收对应：Q01～Q19、Q23～Q26 的内核条件有自动化；Q20～Q22 由主题/老师/泄题约束检查及 UI 流程覆盖。UI01～UI19 有相关自动检查与状态截图，其中高缩放和触摸属于桌面模拟；UI20 只做参考图与实际截图人工视觉检查，**最终相似度、审美与教学可用性由负责人验收**。有效俄语语音播放、真人听辨和移动真机不在通过声明之内。

保留的失败记录：首次 UI 布局高度异常和主页字母入口低于可点区域已修复；初次导出中校验脚本的类型推断错误已修复重建。旧找猫测试有 5 个断言仍假定地图位于 SafeLayout 内，但当前 HEAD 的全屏地图早已挂根节点；将该断言更新为“根节点地图保持、安全区无残留”，未修改找猫行为。回归脚本首次漏传行李原型的 `--dev`，更正后 53 项通过。历史失败日志未覆盖。

环境限制：沙箱下 Godot 的默认 `user://` 编辑器快照目录、OpenGL shader cache 无法创建，日志有对应错误；实际渲染、JSON 保存和 Windows 执行均成功。P1 领域旧测试故意使用文件代替目录，产生预期写入失败日志并验证回滚。不能把这些日志描述为“无任何警告”。没有声称 Windows/Codex 全部零 C 盘写入。

复测命令（每次选择未存在的 EvidenceDir，保护历史证据）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/school.ps1 -Rendered -EvidenceDir docs/evidence/school-v04/recheck-01
powershell -NoProfile -ExecutionPolicy Bypass -File tests/school_regression.ps1 -EvidenceDir docs/evidence/school-v04/regression-recheck-01
```

构建：使用既有 `.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Windows School V04" builds/school-v04/NextStopRussia-School-V04.exe`；整合包使用既有 `Windows PLAYTEST` preset 和新的输出路径。导出日志分别在 `build-delivery/export.log` 与 `build-integrated/export.log`；两者已检查无脚本解析/编译错误。构建产物被原 `.gitignore` 忽略，不会伪装成已提交文件。

## 界面与素材

主参考是输入包 `approved_classroom_blackboard.png`。保留中央木框绿黑板、顶部真实分段进度、右侧独立老师、暖木课堂、书架和桌面装饰层级。题面、重音、选项、正误、强化次数和结算均为运行时控件，参考图没有被用作交互背景。

实际截图：`ui-delivery/02_ready.png`、`03_wrong.png`、`04_correct.png`、`04_strengthen_1.png`、`05_completed.png`、`layout_360x780.png`、`layout_long_text.png`、`layout_safe_area.png`。独立 EXE 证据见 `package-delivery/package_ready.png` 等。

| 实际资源 | 来源分类 / 保留状态 | 本轮处理和剩余事项 |
|---|---|---|
| `assets/school/blackboard_empty_from_sheet.png` | AI_GENERATED / RETAIN_CANDIDATE | 原像素不改；引擎 AtlasTexture 采用 [18,75,990,570]，跳过上方杂散透明像素；徽章上部被裁去，等待视觉验收 |
| `teacher_idle/explain/correct/hint.png` | AI_GENERATED / RETAIN_CANDIDATE | 真 RGBA 透明；运行时共用 657×433 透明画布和头部位置，使姿态切换稳定；原素材底部截断及民俗服饰仍待最终美术决定 |
| `blackboard_empty_scalable.svg` | PROJECT_ORIGINAL / RETAIN_CANDIDATE | 用户包提供的无字矢量，保留为缺图回退 |
| `classroom_backplate.svg` | PROJECT_ORIGINAL / RETAIN_CANDIDATE | 用户包矢量；将 Godot 不显示的书籍 pattern 展开为明确矢量书籍和木架；桌面书杯/植物装饰由 presenter 绘制 |

共 7 件运行资源已加入 `assets/art_registry.json`，保留此前所有登记条目。没有新增网络第三方素材或打包系统字体。位图与输入包逐字节一致；SVG 支持引擎导入，未伪称 PNG。手写矢量来自用户交接；独立作者与最终商业使用审查仍未完整提供。所有资源 `permanentApproval=false`，不能冒充 FINAL_APPROVED，也没有因为 AI 来源而统一要求替换。

与参考图的差异：背景、桌面和按钮细节明显更简洁，未复制参考图的全部灯具/套娃/茶具；黑板为静态空板加动态控件，没有整张原画的光照质感；竖屏是独立纵排，反馈和超长内容通过板内滚动阅读。没有音效素材，不播放虚构音效。中文/俄语/组合重音采用本机 Segoe UI→Arial→中文系统回退，本机已实际渲染；未分发字体，也未验证其他操作系统上的字形覆盖。

主题接口位于 `scripts/school/theme_presenter.gd`：会话开始、出题、答案反馈、词通过、会话完成、暂停事件；该层不判题或保存学习状态。`data/school/theme.json` 提供当前黑板 ID 和反馈时长；设置可切换同一黑板的经典/柔和色板以验证状态独立。火车、幻灯机、磁吸均仅保留后续 presenter 替换位置，本轮没有实现第二套玩法或视觉系统。

## 文件变更

- 新增 `scripts/school/{content,progress_store,study_service,theme_presenter,school_view,demo,package_check}.gd` 及 Godot UID。
- 新增 `data/school/{vocabulary,alphabet,decks,theme}.json`，以及上述 7 件 `assets/school` 资源和导入描述。
- 修改 `scenes/buildings/school.tscn`；新增 `scenes/school_demo.tscn`。`scripts/main.gd` 仅增加学校侧档目录注入。
- 修改 `project.godot` 增加学校专用构建入口；`export_presets.cfg` 为各包补上学校 JSON 清单并增加 Windows School V04 preset。未更改原主场景默认入口或原模式规则。
- 新增 `学校黑板课堂V04.cmd`、`试玩学校整合版V04.cmd`、`scripts/dev/play-school.ps1`、素材登记脚本 `scripts/dev/register-school-assets.py`。
- 新增 `tests/school_domain_tests.gd`、`school_ui_tests.gd`、`school_integration_tests.gd`、`school.ps1`、`school_regression.ps1`、`school_asset_audit.py`；旧 `tests/cat_hunt_tests.gd` 只更新一条已过时的节点归属断言。
- 扩充资产登记，更新 README；保留完整输入包于 `docs/reference/school_vocab_blackboard_v04/`，新增 P0 检查、本报告及 E 盘测试证据。

`data/city_map.json`、负责人地图 PNG、Q00～Q03 内容、猫、宿舍空间、整理规则/输入/存档、原模式和档位服务保持原字节；审计结果可查。没有发布、购买服务、创建远程仓库、提交或推送。开工前已有的未跟踪 `docs/architecture/`、`docs/evidence/p1-01/`、`docs/evidence/tidy-desk-prototype/` 未触碰。

## 未测试和剩余问题

- 尚未进行负责人真人试玩、最终视觉验收、教学审校；只提供 6 个开发示例词。33 字母已完成辨形闭环，完整发音讲解、字母音频和入门听辨仍缺经审校内容。
- 没有真实俄语录音，所以实际课堂只有中文选俄语和俄语选中文；听音工厂按资源门槛拒绝缺音题。有效录音的真人试听、音量与设备音频链路未验证。
- Android/iOS/macOS 构建、触摸真机、系统高 DPI/无本机字体环境、后台强杀和硬件断电未测试；桌面模拟的触摸/方向/安全区及原子保存故障测试不能代替这些验证。
- 咖啡店、全局对白词语点击、旅游手册、考试室/排行榜/校园商店没有新增功能；记事本和词包适配器已测试，真实来源事件需后续明确授权后接入。
- 复习是简单工程默认调度，未声明教学效果最优；长时间运行、多进程同时写同一学习档没有验证。请关闭一个试玩实例后再用另一个入口打开同一快捷课堂档。
- 本轮以可玩性与规则准确为交付，当前位图、教师服饰、裁切和背景细节需要视觉验收；无素材被标记为正式最终批准。

本轮开发停止于学校 V0.4 交付，等待学校视觉与内容验收，不继续扩展剧情或其他游戏系统。
