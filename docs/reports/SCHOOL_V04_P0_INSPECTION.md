# 学校 V0.4 P0 检查与实施边界

日期：2026-11-04。依据本轮用户明确授权，学校学习开发取代根 AGENTS.md 中仅限 P1-UI-01 的历史任务范围；其他系统保护规则继续生效。输入包保存在 `docs/reference/school_vocab_blackboard_v04/`，最新界面依据为其中的 BLACKBOARD_UI_SPEC.md。

- 当前 HEAD：3d0e0f7fda640fd72dab3d0e30afb33bcc17441d；当前分支 codex/p1-ui-visual-unification。开工时已有未跟踪 docs/architecture、docs/evidence/p1-01、docs/evidence/tidy-desk-prototype，不改动。
- 引擎：项目与便携安装均为 Godot 4.7.2 / GDScript / Compatibility。沿用主工程，不新建引擎工程。
- 现有学校：data/buildings/school.tres → scenes/buildings/school.tscn → BuildingRoom 占位。main.gd 强制 BuildingRoom 类型、back_button 和 return_requested 接口；学校仍遵守既有城市解锁条件。
- 复用：BuildingRoom 导航合同、ui/adaptive_layout.gd 横竖屏及安全区、GameUI/系统字体回退、P1SaveStore.storage_root 与档位目录。学校采用当前档位的 school_v04.json 侧档，不改变原 save.json schema 和其他玩法。
- 现有内容没有可复用的全局俄语词典、学校课程、独立语言记事本、教学音频或学习事件服务。新增限于 scripts/school、data/school、assets/school；剧情来源和主题解锁只提供可测适配接口，不伪造咖啡店或实际对白。
- 用户包：6 词、33 字母；无真实音频、无字体。缺音频禁用听音；10/20 新词不足时明确禁用；字母说明沿用待教学审校的数据标记。
- P1：内容校验、独立学习状态机、可注入时钟/种子、原子侧档与备份、复习、来源和解锁接口及测试。
- P2：空黑板/老师分层资产、动态板书/按钮/进度；主页、字母、预习、测验、暂停、记事本和结算；横竖屏重新布局。
- P3：真实学校场景接入及独立学校调试试玩入口；主题 presenter 接口仅实现黑板。
- P4：核心和 UI 自动化、真实渲染截图、现有领域/导航/模式回归、可用 Windows 构建。没有执行的真机和真人验收如实记录。

预计修改：学校场景、main.gd 中学校存档注入点、project.godot 的学校专用构建入口、export_presets.cfg 的数据清单；新增 scripts/school/*、data/school/*、assets/school/*、tests/school*、学校试玩脚本；扩充 assets/art_registry.json；最终单份阶段汇总 SCHOOL_V04_BLACKBOARD_SUMMARY.md。不修改地图、美术投影、剧情、猫或整理规则。
