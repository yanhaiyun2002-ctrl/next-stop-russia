# 学校专用分支与任务树迁移报告

日期：2026-11-04。依据负责人最新授权，将已有学校 V0.4 R2 隔离并推送学校分支；不表示学校视觉或教学内容已经验收，不授权合入 main 或开发新玩法。

## 版本与边界

- Worktree：`E:\俄语游戏\worktrees\school-v04-r2`。
- 分支：`feat/school-v04-r2`。
- 主体基线：`46e239c1953891911e6a6f4a4b525dcc0ca406da`；原主体运行基线 `3d0e0f7fda640fd72dab3d0e30afb33bcc17441d`。
- 学校运行源码提交：`6aaa666e441e4e5ea31f76ab545d80dc79080b4a`。后续迁移报告提交只补充测试和记录，PLAYTEST 清单绑定该源码提交。
- 迁入 1,067 个学校文件，原文件与目的副本逐一核对 SHA-256；没有重写学校规则、题库、四选题、SRS、字体布局或存档 Schema。
- 既有 `scripts/main.gd` 学校接入、学校场景、project/export 配置、资源登记、入口和 README 差异只存在于学校分支；main 仍保留原学校技术占位。

架构合规：学校共享文件接入差异属于本轮已授权迁移白名单，未扩大原有依赖；主体 session/save_store、主线 Q00～Q03、猫咪、地图与整理运行文件按基线逐字检查未变。历史耦合未被本轮消除，也不构成后续跨模块修改授权。既有猫咪测试的全屏节点归属修正已归入主体基线，不修改猫咪运行逻辑。

## 独立 PLAYTEST

推荐双击本任务树根目录 `学校竖屏试玩V04.cmd`；整合入口为 `试玩学校整合版V04.cmd`，加 `-Portrait` 可用手机比例。

重新在本树导出：

- `builds/school-v04-r2/NextStopRussia-School-V04-R2.exe` + 同名 PCK。
- `builds/school-v04-r2/NextStopRussia-Integrated-V04-R2.exe` + 同名 PCK。
- `builds/school-v04-r2/build_manifest.json` 包含源码提交、分支、Worktree 和四个产物 SHA-256；两个启动器均实际执行 VerifyOnly 通过。

使用同一 E 盘 Godot 4.7.2 及模板（本树 `.tools` 为仅工具链目录联接，无重复下载）。数据默认本树 `.local-dev/player-data/`，与主体物理隔离；本轮测试各用自己的 evidence/player-data，不自动迁移或重置玩家旧档。原主体的 13 个玩家数据文件前后哈希一致。旧学校 EXE/PCK 已保存在本树 `builds/preserved-pre-isolation/`，不会覆盖新包。二进制、缓存、真实玩家档和迁移安全副本不上传 GitHub。

## 本轮实际测试

以下均在学校任务树重跑，不能用旧主目录的历史通过代替：

| 测试 | 通过 / 失败 |
|---|---:|
| 学校领域 | 57 / 0 |
| 旧三选题兼容 | 6 / 0 |
| 主档位与学校侧档隔离 | 12 / 0 |
| 资源和保护范围 | 174 / 0 |
| 学校横竖屏/模拟安全区/合成触摸 | 43 / 0 |
| 重音字体与按下/松开稳定性 | 9 / 0 |
| 主线领域、完整可玩流程、三模式 | 55 / 0；168 / 0；61 / 0 |
| 整理、找猫、导航 | 53 / 0；540 / 0；254 / 0 |
| 本树新导出课堂包：手机五词＋剩余一词、错误与两次强化 | 80 / 0 |
| 本树新整合包：真实 Q00～Q03 后进入学校 | 主线 14 / 0；学校 46 / 0 |

实际 Godot Windows 渲染截图已检查，输出与新包清单绑定。首个 GUI 包由 PowerShell 直接调用时命令提前返回，旧 `$LASTEXITCODE` 导致外层报告异常；实际进程仍运行，等待其完成后结果为 80/0。后续整合包用管道显式等待，退出码 0。未将该调用等待问题当作玩法失败，也未覆盖首次证据；见 package-phone/runner_note.json。

完整机器结果为 `docs/evidence/school-isolation-20261104/test_summary.json`，具体变更及受保护路径为同目录 `source_scope_audit.json`。旧原始证据和参考输入留在本树；Git 仅提交代码、运行资源、来源记录与精选证据，测试玩家数据被排除。

## 文件变更与停止条件

迁移既有 `scripts/school/`、`data/school/`、`assets/school/`、学校场景/启动器/测试、学校资源登记和导出配置，以及原学校报告和来源记录。精确文件列表记录于 source_scope_audit；本次新增本报告和 school-isolation-20261104 测试证据。没有新剧情、课程内容、宠物或整理玩法。

Android/iOS/macOS、手机真机、真人试玩、教学/视觉最终验收未执行。学校保持独立分支，等待负责人明确验收与合并批准，完成迁移和推送后停止。
