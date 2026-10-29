# 《下一站，俄罗斯！》工程协作规则

- 开工前阅读 `docs/TECH_BASELINE.md`、`docs/FEATURE_FEASIBILITY.md` 和 `docs/tasks/P0-01_TASK.md`。
- 当前任务为负责人已选择机制一的独立 DEV 原型实施：按 `docs/design/prototypes/ARRIVAL_LUGGAGE_TIDY_PROPOSAL.md` 制作“初到俄罗斯，整理行李”的长短成序＋共边对齐，限四件物品、一块摆放面、一个初始局面。机制二未选，不接正式 Q02、不写玩家存档、不提前删除旧玩法；交付后由负责人真人试玩决定保留／最多一轮针对性调整／删除，不自动追加内容或宣布合格。不进入 Q04/Q05 或 P1-02。
- P1 依据索引：`docs/design/PRODUCT_DECISIONS_V03_P1.md`、`P0_TO_V03_GAP_MATRIX.md`、`P1_CONTENT_AND_QUEST_BASELINE.md`、`TEMP_ART_GUIDE.md`；协作和存储遵守 `docs/production/CODEX_AGENT_WORKTREE_RULES.md`、`E_DRIVE_STORAGE_POLICY.md`。三组视觉方向已获本轮批准，资产以 `assets/art_registry.json` 分别记录 sourceType 与 retentionStatus；AI_GENERATED 可为 RETAIN_CANDIDATE，不一律要求替换，FINAL_APPROVED 仍须负责人最终验收与必要使用检查。
- 宿舍视觉暂定近正视、允许未来轻微俯视；当前固定投影是本轮实现，不是永久规范。藏点以家具 ID 和房间空间坐标定位，不绑定屏幕像素。
- 不能将未来设想视为已确认开发需求；不擅自更换引擎、发布代码、购买服务或扩展任务范围。
- 游戏 DEMO 与正式版共用一个主代码库，正式内容按构建配置与资源清单隔离。
- 代码、输入、地图导航与屏幕布局相互解耦；优先可运行的最小方案，避免预先制造万能框架。
- 每次交付说明实际测试、未测试条件、风险和文件变更。不允许宣称未执行的测试通过。
- 当前 PC 横屏优先、手机竖屏优先。不得把两种画面仅通过拉伸处理。
