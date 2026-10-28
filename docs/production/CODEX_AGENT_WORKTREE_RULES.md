# Godot P1：Codex Manager、子 Agent 与 Git Worktree 最小规则

**目的：** 延续原 V0.3 的角色分工，减少并行冲突、无意义 Token 消耗与 E 盘以外的复制。不是要求现在立刻部署一套 Agent 编排系统。

## 角色

- **制作人＋ChatGPT 主线：** 已确认的产品、故事事件、正式美术风格和最终验收；ChatGPT 输出可执行设计文件，Codex 不替制作人定稿。
- **Codex 主 Agent（Manager）：** 查已有 HEAD、选择最小修改、划分文件权属、集成、测试与提交。
- **Gameplay Worker（需要时）：** 首遇猫状态机、整理教学判题、领域事件或存档；不得改地图、UI 场景或正式文案。
- **Scene/UI Worker（需要时）：** 按已经给定的接口将 TEMP 资产接入现有 `scripts/dormitory/*` 与场景 UI；不得改剧情任务完成条件。
- **QA Worker（可只读并行）：** 读现有测试、补充回归与独立审查；不得私自合并或删测试。

## P1-01 的推荐实际分工

默认 **1 个主 Agent 顺序开发 + 1 个 QA 子 Agent 只读/测试**。只有先冻结了结构化事件和稳定 ID，且两个 Worker 不会触碰同一文件时，才考虑第二个 Worktree。如果平台不支持子 Agent，主 Agent 顺序执行等价工作即可；不为并行专门创建无收益的脚手架。

任务应先完成 **数据与事件合同**（共用），再分别实现首遇猫与整理教程，然后由主 Agent 串接 Q00-Q03；这些共享的 `main`／`dormitory` 场景、存档 schema、输入系统要指定唯一 owner，不能两个 Agent 并行写。

## Worktree 的磁盘与安全规则

1. 工作树根目录用 `E:\俄语游戏\worktrees\` 或当前工程同一非 C 盘；**不得默认建在 `C:\Users\...` 下**。
2. 已有真正的 Git 仓库才允许用 worktree，记录 `baseSHA`, `branchName`, `allowedPaths`, `owner`, `taskId`, `testPlan`。
3. 同一项小修复优先单工作树，不为每个文档、每个素材单开工作树。Godot `.godot/` 和引擎缓存不入 Git；每个新 Worktree 首次导入可能产生完整重复缓存，必须纳入磁盘预算。
4. 建议分支名 `feat/p1-01-cat-first`、`feat/p1-01-organize`；**只能在 owner 路径互不冲突且有真实并行收益时**采用。
5. 主工程当前分支不应假设叫 main/develop；先运行 `git branch --show-current`。已有用户未提交改动时先报告，不擅自 stash/reset/clean。
6. 合并前每个 Worker 提交范围、实际测试和 commit；Manager 检查共享场景、资源 UID、输入、镜头和存档差异，再按实际现有流程集成。只有主 Agent 负责集成；任何代理不得自动 push／建立远程。
7. 只读 QA 可直接审查主工作树或导出的文件快照，不必创建可写 Worktree。Worktree 的存在不等于 QA 数据隔离，PLAYTEST 仍需独立用户数据配置。
8. 可能破坏现有用户数据的动作（重建项目、批量删文件、清理历史、强制迁移存档）全部禁止，除非项目负责人单独批准。

## 策划素材变更回流

`docs/design/DESIGN_HANDOFF_CONTRACT.md` 是主线交接入口。若稿件 `Status` 非 `APPROVED`，能用 TEMP 原型验证，不得把它改写成正式确定的剧情或美术。双方交接保持可替换的 ID／图层／锚点合同。

## 汇报制度

每阶段只向主线输出 1 份 `docs/reports/<阶段>_SUMMARY.md`；证据日志和截图留 E 盘，额外 ZIP 仅在源码独立审查时请求。报告要区分：自动化通过、实际 PC 运行、Android 构建、手机真机、真人试玩和最终制作人确认。
