# 05 · Codex Manager / 专业 Agent / Worktree 安全协作规范

## 1. 工作原则

用户是产品决策与试玩验收负责人；Codex Manager 是工程集成负责人。策划、美术、场景与交互视觉由 ChatGPT、Figma、其他专业工具或用户自行完成后以文件交接，Codex 执行而不重新发明产品。每个 Agent 仅获得自身任务必要文档与最小范围，减少上下文与 Token 消耗。

## 2. 角色与文件所有权

| 角色（逻辑职责，不代表必须同时开代理） | 负责 | 禁止擅自修改 |
|---|---|---|
| Manager | 分解卡片、审计仓库、版本与接口审批、集成、提交试玩版 | 用户已确认的玩法/剧情/视觉；用户未允许的部署 |
| Core | TypeScript 事件/Schema/Save/Reward/Host/SceneBridge | 已批准的剧情文本、房间图、NPC 设定 |
| Gameplay | 猫/整理状态机、日常题验证、玩法单测 | 全局存档 Schema（未经 Core + Manager 讨论） |
| Scene Integration | 将**用户提供**的 Home/City 设计接入、Camera、遮挡、动画 | 自行设定 HUD/地图构图；修改奖励规则 |
| UI | 用户已提供的 HUD 设计、俄中对白、换装手账界面 | 领域事件含义、场景锚点与任务完成条件 |
| QA | 独立编写并执行测试、截图/录屏、失败复现、用户试玩指南 | 自述代替实测；未经授权合并/修改 main |

建议初期真实并发 Agent 控制在 1–2 个：Core 为先，QA 可独立准备测试；共享接口稳定后再让 Gameplay 和 Scene 并行。Agent 名称不是固定产品功能。

## 3. Worktree 分支纪律

- `main` 稳定，`develop` 集成（**前提是实际 Git 仓库存在这些分支；R0 必须查证**），各任务 `feat/Rn-short-name` 在独立 worktree 中开发。
- 开始任务记录 `baseSHA`, `branchName`, `owner`, `allowedPaths`, `dependencies`, `taskId`；不要假设其它 Agent 未提交的改动会自动出现。
- 只有 Manager 可以在经过验证后合并到集成分支；任何 Agent 不得擅自提交到生产 `main` 或推送公网。
- 共享合同如事件目录、存档 Schema、资源清单由指定 owner 串行修改。必须变更时先写 ADR 与升级兼容计划，等待 Manager 协调。
- Worktree 是代码改动隔离；**不是**数据或浏览器存档隔离，PLAYTEST 存档仍要独立域/前缀与 profile。

## 4. R0 只读审计（不凭空假设仓库）

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch -avv
git worktree list
git log --oneline --decorate --all -20
git remote -v
```

再检查真实 `package.json`, `src/`, `tests/`, `public/`, 已存在 assets、package lock、工具版本、未提交文件。不存在 Git 或无源码，必须如实标记 `NOT_PRESENT` 并征得授权后才创建；不要自行 `git init` 覆盖原有开发目录。

严禁：`git reset --hard`、`git clean -fd`、未获批准的 `git stash`/丢弃本地修改、强推、替换历史分支为假定的全新项目。

## 5. 任务卡与合并步骤

1. Manager 用 `templates/TASK_CARD_TEMPLATE.md` 定义目标、输入版本/路径、允许修改文件、依赖、验收及未授权事项。
2. Worker 核验当前工作树 SHA 并读取仅相关的 GDD 与接口，写测试再实现；每个提交单一目标。
3. Worker 报告具体 commit SHA、文件/行为变化、通过与失败测试，不自己声称用户验收。
4. Manager 检查接口、向后兼容、异步清理及是否碰到别的 Agent 的文件；逐项合并至真实集成分支。
5. 每次合并运行 build、单元、集成、关键 Playwright 场景并保存记录；有失败或功能回退就停止继续合并。
6. QA 在桌面与移动视口独立检查实际行为；提供 PLAYTEST 运行方式，邀请用户试玩，用户确认后标记阶段通过。

## 6. 设计变更回流

- 用户完成某项 Figma/场景/剧情设计后，按 `templates/DESIGN_HANDOFF_TEMPLATE.md` 导出。
- Manager 先判断修改只是内容/美术替换还是破坏了接口；前者尽量直接换配置，后者创建 ADR 和专门迁移任务。
- 若设计交接不全，Agent 只报告缺失（例如没有猫咪出口路径/遮挡层），**不私自补画并认定终稿**。
- 设计变更只有在用户明确批准后，才更新 `docs/08_DECISION_REGISTER.md`，避免多个聊天分支造成矛盾。

## 7. 付费/敏感操作

禁用自动购买、付费 API、收费素材、付费订阅或新增外部账号连接；除非用户逐项明确同意。禁止把源码、私有设计或用户文件无授权上传公共仓库或网盘。临时视觉素材使用 `TEMP_REPLACE_REQUIRED`，正式发布构建必须检查，不在本地开发环节安排逐张许可证审查。
