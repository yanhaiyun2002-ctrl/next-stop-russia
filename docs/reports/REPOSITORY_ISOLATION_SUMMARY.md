# 主体 main、学校分支与 Git Worktree 隔离交付

日期：2026-11-04。任务 `REPOSITORY-ISOLATION-20261104`。负责人本轮明确授权：当前项目推送 GitHub、主体为 main、学校及后续新窗口独立分支/任务树、迁移学校模块。本轮据此执行主线整理与学校隔离，不将学校合入 main，不开始新玩法或 ARCH-02 重构。

## 当前版本布局

| 用途 | 分支 | Worktree |
|---|---|---|
| 主体 | `main` | `E:\俄语游戏\NEXT_STOP_RUSSIA` |
| 学校 V0.4 R2 | `feat/school-v04-r2` | `E:\俄语游戏\worktrees\school-v04-r2` |
| 本轮治理与证据 | `codex/repository-isolation-20261104` | `E:\俄语游戏\worktrees\repository-isolation-20261104` |

原主体提交 `3d0e0f7fda640fd72dab3d0e30afb33bcc17441d`；治理规则提交 `112ebd03a7a4fef4c3591548a30afcb4f3187268`；本轮主体基线 **`46e239c1953891911e6a6f4a4b525dcc0ca406da`**；学校运行源码 **`6aaa666e441e4e5ea31f76ab545d80dc79080b4a`**。后续证据/报告提交只追加交付记录，最终分支 HEAD 可由 `git rev-parse main` 和 `git rev-parse feat/school-v04-r2` 查得。

GitHub 目标为原仓库 `https://github.com/yanhaiyun2002-ctrl/next-stop-russia`，默认分支原本已为 main。本轮仅正常推送 main 与学校分支，不强推、不删除旧远程分支、不重写历史。旧本地 master、UI 等历史分支和其他 Worktree 保留。

## 迁移与保护

- 迁移前已对全部 1,393 个修改/未跟踪文件建立安全副本，共 672,986,883 字节，逐文件 SHA-256 核对。
- 1,067 个学校文件已完整复制到学校任务树并再次核对；原目录需移出的 1,377 个原件保存到治理树 `.local-dev/repository-isolation/relocated-from-primary/`，未直接删除。完整初始副本还保存在同目录 `original-files/`，其余无需移出的本地测试数据保留。
- 已迁移学校源码、数据、资源、场景、启动器、测试、报告、来源说明和原始证据；学校的主入口接入、导出预设及资源登记差异只进入学校分支。
- 原学校两个构建目录已移到学校树 `builds/preserved-pre-isolation/`；新 PLAYTEST 在学校树重新导出，独立于旧包。
- 原主体 `.local-dev/player-data/` 的 **13 个玩家数据文件前后哈希一致**，未自动复制到新试玩档、未重置或改 Schema。
- 主目录已正常切换 main 且干净。切换曾因索引统计状态拒绝 README，三文件内容哈希均与 HEAD 相同；仅刷新同内容索引，确认无 staged diff 后普通切换成功，未使用 reset、clean、强制切换或强推。

## 主体修改文件与架构合规

主体只新增/同步治理 AGENTS、原架构标准文件、分支任务树索引、任务卡、README、测试数据忽略规则、新任务树创建入口及历史非学校证据。原架构标准按原文收录，不将其中后续重构计划自动视为实施授权。

`tests/cat_hunt_tests.gd` 只接收既有的全屏地图节点归属断言修正：地图挂在根视觉层后，SafeLayout 应为零个室内节点；该断言匹配已提交 UI 的真实结构，不改猫咪玩法、不删除失败条件。它归主体 UI 回归，而非学校逻辑。

对 `scripts/main.gd`、`scripts/p1/`、`scripts/dormitory/`、`ui/`、`data/`、`scenes/` 从原主体至本轮主体提交比较，**运行文件变化为零**。main 没有 `scripts/school/`、`data/school/`、`assets/school/` 或 `scenes/school_demo.tscn`，学校仍为原技术占位。学校分支保留原有接入差异；本轮未扩大依赖、修改任务 ID、权限、奖励、猫、整理或存档。

精确新增/修改路径和保护审计见 `docs/evidence/repository-isolation-20261104/source_scope_audit.json`。学校路径与独立结果见学校分支 `docs/reports/SCHOOL_WORKTREE_MIGRATION_SUMMARY.md`。

## 实际测试

| 主体测试 | 治理树验证 | 切换 main 后复验 |
|---|---:|---:|
| P1 领域 | 55 / 0 | 55 / 0 |
| Q00～Q03 可玩流程 | 168 / 0 | 168 / 0 |
| DEV / PLAYTEST / RELEASE 与旧档 | 61 / 0 | 61 / 0 |
| 整理 | 53 / 0 | 53 / 0 |
| 找猫 | 540 / 0 | 540 / 0 |
| 导航 | 254 / 0 | 254 / 0 |
| PC 真实渲染 UI | 85 / 0 | 运行文件未改，不重复 UI |
| 手机竖屏真实渲染 UI | 85 / 0 | 运行文件未改，不重复 UI |

main 切换后首个命令因原目录环境脚本签名策略在测试开始前被拦截；未改系统策略，改为直接 Godot 命令及进程级 E 盘 TEMP/独立数据，随后六套回归全部执行通过。无将未执行的首次命令计为通过。

学校独立任务树实际复验：学校领域 57/0、旧三选题兼容 6/0、主档隔离 12/0、素材/保护范围 174/0、学校横竖屏/安全区/合成触摸 43/0、点击/重音字体 9/0；六套主体跨模块回归仍分别为 55/0、168/0、61/0、53/0、540/0、254/0。新 Windows 课堂包手机完整流程 80/0；新整合包 Q00～Q03 14/0 后进入学校 46/0。原始截图、日志和构建清单留在学校任务树，精选证据随分支提交。

新任务树脚本的 PowerShell 语法检查通过；用现有学校目标实测拒绝覆盖，Worktree 列表不变。全部测试是引擎/Windows 自动化及合成输入，不是负责人真人或手机真机验收。

## PLAYTEST 与后续窗口

学校入口：`E:\俄语游戏\worktrees\school-v04-r2\学校竖屏试玩V04.cmd`；整合入口为同树 `试玩学校整合版V04.cmd`。独立 EXE/PCK 在 `builds/school-v04-r2/`，启动器按实际 SHA-256 校验。默认玩家目录为学校树 `.local-dev/player-data/`，不会混用主目录旧档。

后续开发窗口必须先读取 AGENTS 和架构标准，创建自己的分支与任务树，例如：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/new-task-worktree.ps1 -Module new-window -TaskId 20261105-01
```

脚本创建 `feat/<module>-<task-id>` 和 `E:\俄语游戏\worktrees\<module>-<task-id>`，从已确认 main 起步；已有路径/分支会拒绝覆盖。继续未合并学校任务须明确指定其模块基线。每任务仍须白名单、独立测试/PLAYTEST和负责人验收，不能自动合入 main。

## 推送范围与限制

只上传源码、运行资源、治理/开发文档和精选测试证据；工具、缓存、EXE/PCK、玩家档、迁移备份及原始参考输入保留本地。提交前做路径、文件大小和明显私钥/token 模式检查，未发现异常；这不是任意秘密不存在的绝对证明。Git/Python 沿用机器已有运行时，新任务树、备份、构建和测试数据均在 E 盘；没有新下载安装或改系统全局配置。

未执行 Android/iOS/macOS 新构建、真机或真人视觉/教学验收。学校保持独立分支；源码推送不等于学校已验收或合并。远程发布后的实际 SHA 以最终交付中的 GitHub 引用核验为准。完成迁移和正常推送后停止。
