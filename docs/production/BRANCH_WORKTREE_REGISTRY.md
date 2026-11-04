# 主线与模块任务树索引

负责人于 2026-11-04 要求主体固定为 `main`，每个新功能/模块任务或新开发窗口先创建独立分支与 E 盘 Worktree，再实施开发。以根 `AGENTS.md` 的强制规范为准。

| 用途 | 分支 | Worktree | 合并条件 |
|---|---|---|---|
| 已提交主体 | `main` | `E:\俄语游戏\NEXT_STOP_RUSSIA` | 禁止直接开发；仅负责人批准后的集成与回归 |
| 学校 V0.4 R2 | `feat/school-v04-r2` | `E:\俄语游戏\worktrees\school-v04-r2` | 独立 PLAYTEST，等待负责人验收，未合入 main |
| 本次仓库治理 | `codex/repository-isolation-20261104` | `E:\俄语游戏\worktrees\repository-isolation-20261104` | 本轮仅批准主体整理、隔离和推送 |

旧分支及已有治理 Worktree 保留，不重命名、不覆盖。一个 Worktree 只能由对应任务负责写入，其他模块只读。

新任务示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/new-task-worktree.ps1 -Module new-window -TaskId 20261105-01
```

脚本从本地已确认的 `main` 创建 `feat/<module>-<task-id>` 与 `E:\俄语游戏\worktrees\<module>-<task-id>`，目标或分支已存在时拒绝覆盖；不会合并、推送、复制未提交文件或处理玩家档。继续尚未合并的模块须由任务明确指定 `-Base <已批准模块分支>`；不得用此参数绕过架构白名单。每次仍须记录 allowedPaths、owner、基线、测试及停止条件。

GitHub 只存源码、运行资源、文档与精选测试证据。`.tools/` 使用现有 E 盘工具链，构建在各树 `builds/`，试玩数据在各树 `.local-dev/player-data/`。原始参考包、玩家数据和迁移安全副本留本地，不上传或静默删除。
