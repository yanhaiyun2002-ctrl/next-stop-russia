# REPOSITORY-ISOLATION-20261104：主线与学校任务树隔离

负责人 2026-11-04 最新明确授权：把当前项目推送 GitHub，主体为 main，学校及后续新窗口使用独立分支，将学校开发迁入学校专用任务树。本授权允许本轮建立 main、纳入已制定治理规则及迁移所需共享文件；不代表学校玩法或视觉已经验收，不授权将学校模块合入 main。

- owner：当前 Codex 主 Agent，顺序执行，不改玩法。
- 主体治理 Worktree：`E:\俄语游戏\worktrees\repository-isolation-20261104`；分支 `codex/repository-isolation-20261104`。
- 学校 Worktree：`E:\俄语游戏\worktrees\school-v04-r2`；分支 `feat/school-v04-r2`。
- 原主体基线：`3d0e0f7fda640fd72dab3d0e30afb33bcc17441d`；规则基线 `112ebd03a7a4fef4c3591548a30afcb4f3187268`。
- 原工作区：`E:\俄语游戏\NEXT_STOP_RUSSIA`，检出 UI 分支且含学校未提交成果。迁移前对全部修改/未跟踪文件作逐文件备份、哈希核对；禁止 reset/clean/强推，禁止修改原玩家档。

## 文件白名单

主体仅允许：既有治理 AGENTS；原架构标准文件按原字节纳入；`.gitignore` 的本地测试数据隔离；README 的分支/任务树说明；本任务卡、分支索引、迁移报告和证据；`scripts/dev/new-task-worktree.ps1`；既有未提交的 `tests/cat_hunt_tests.gd` 全屏节点归属断言修正；已有非学校历史证据 `docs/evidence/p1-01/` 与 `docs/evidence/tidy-desk-prototype/`（排除玩家数据）。主体运行代码、地图、剧情、猫咪和整理规则不变。

学校只迁移现有内容：`scripts/school/`、`data/school/`、`assets/school/`、学校场景/启动器/测试/来源说明/报告/证据，以及现有学校接入差异 `README.md`、`assets/art_registry.json`、`export_presets.cfg`、`project.godot`、`scenes/buildings/school.tscn`、`scripts/main.gd`、`试玩整合版PLAYTEST.cmd`。这些共享文件是本次隔离迁移的明确白名单，不授权新增内部耦合或新存档 schema。既有参考输入与原始证据完整留本地；提交精选测试结果、代码与运行资源，不上传玩家档、缓存、工具链或 EXE/PCK。

原目录整理仅限已备份并经学校任务树再次核对的学校专属路径；恢复共享文件的已提交主体版本。旧存档、无关未跟踪成果、其他 Worktree、远程历史分支均保护。只允许正常 fast-forward 推送 main 和学校分支，不允许强推、改写历史或合入学校。

## 验证和停止条件

在各自 Worktree 执行真实 Godot 导入、领域/主线/模式/导航/找猫/整理回归，主体与学校横竖屏检查，学校兼容与完整学习 GUI 测试。学校提供本任务树独立 PLAYTEST 和数据目录。主目录切换 main 后再做回归；远程 SHA 与本地对应提交一致，学校路径不在 main，迁移源与目的内容校验完成后交付并停止。任何新增功能、额外接口修改或不明来源文件先停相关工作申请。
