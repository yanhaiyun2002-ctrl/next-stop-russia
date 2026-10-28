# P0-02 阶段汇总报告

日期：2026-10-28（Asia/Shanghai）。范围见 `docs/tasks/P0-02_TASK.md`。本阶段唯一主线汇总；日志和 JSON 留在证据目录。

## 当前状态

A/B 已完成最小稳定性修复：Headless 254/0，Windows Rendered 连续五轮各 268/0。C 正在建立本地基线；D/E/F 在稳定基线之后记录构建结果。未实现正式玩法或进入 P0-03。

## 根因与修复证据

- 生产缺陷：窗口/逻辑视口先变化，容器和热点后重排；过期坐标仍能触发进入。确定性同事件轮次实验修复前 `passed=false`、`active_id=dormitory`，修复后不进入。路径：`docs/evidence/p0-02/03_diagnostic/resize_probe.{json,log}`、`05_rendered_1/resize_probe.{json,log}`（后者同在 `docs/evidence/p0-02/`）。
- 测试缺陷：固定等待帧数没有观测完整几何和导航状态；点击 down/up 之间人为插帧并重新取坐标；三栋楼的数据又在导航往返间分别采样，不能证明同一帧混合布局。现在按布局稳定谓词等待（3 秒超时仍失败），一次点击保持一个坐标，另外保留跨帧按下/松开和尺寸切换回归。
- 最小修复：`ui/adaptive_layout.gd` 在输入时检查几何稳定和按下时的几何，变化则取消；恢复按钮自身按下状态。`scripts/map.gd` 监听视口尺寸与可见性，补齐重排入口。建筑数据、ID、导航与独立场景边界未变。
- 不是只把失败归咎于环境：旧热点误触在未改生产代码时可确定复现；原始命令在本轮首次复跑却为 168/0，说明旧 14/11 个失败的全部事件序列无法从历史日志重放，不能声称每项历史失败都已单独证明同一个根因。
- 修复过程失败保留：吞掉松开导致按下残留（`06_final_headless`，244/10）；尝试改变松开坐标不足以取消 Godot 按钮捕获（`07_fixed_headless`，239/15）；使用按钮取消机制后通过。`08_stability/round_1` 保留同一未完成版本的失败，不能计为最终连续五轮。

## 测试

| 项目 | 结果 | 项目内路径 |
|---|---|---|
| 修复前历史证据归档 | 保留 P0-01 失败及源码副本 | `docs/evidence/p0-02/01_before/` |
| 本轮原命令复跑 | Rendered 168/0 | `docs/evidence/p0-02/02_reproduce/` |
| 被动逐帧诊断 | 记录窗口/视口/方向/热点/输入/焦点/状态；默认与高帧率通过 | `docs/evidence/p0-02/03_diagnostic/` |
| 最终 Headless | 254 通过、0 失败，退出码 0 | `docs/evidence/p0-02/09_headless/` |
| 最终 Rendered | 连续 5 轮各 268 通过、0 失败、干净日志 | `docs/evidence/p0-02/10_stability/results.json` 和 `round_1` 至 `round_5` |
| 额外回归 | 每轮 10 次横竖屏切换、过期按下取消、按钮复位、进入/交互/返回/锁定；原 20 次往返及五种尺寸保留 | 同上逐项 JSON |
| 可视化操作工具 | node_repl 与备用通道均因 Windows sandbox `setup refresh had errors` 无法启动；不声称完成真人鼠标检查 | `docs/evidence/p0-02/11_visual/` |

现有测试命令保留，增加独立证据路径：`./tests/run.ps1 -EvidenceDir <目录>`、`./tests/run.ps1 -Rendered -EvidenceDir <目录>`。连续验收：`./tests/stability.ps1 -Rounds 5 -EvidenceRoot docs/evidence/p0-02/10_stability`。脚本拒绝覆盖已存在的稳定性目录，任一失败立即结束。

五种实际模拟窗口仍为 1920×1080、1280×800、1080×1920、1170×2532、360×780；均使用桌面 GPU，不等于手机真机。

## 文件变更

生产代码仅 `ui/adaptive_layout.gd`、`scripts/map.gd`。测试涉及 `tests/run_tests.gd`、`run.ps1`、新增 `stability.ps1`、`diagnose.gd`、`resize_probe.gd` 及 `.uid`。规则更新 `AGENTS.md` 对齐本次授权；保留 P0-01 规则和历史文档。新增任务书、ADR 0002、本汇总与证据；未继承外部原型代码或资产。

## Git

稳定性通过后使用已授权的 `yanhaiyun2002` / 用户提供的邮箱，仅本仓库配置。本地基线提交 ID：建立后补充。无远程，不推送。`.tools/`、`.godot/`、`builds/`、环境配置与密钥均忽略；原始测试日志是必要证据。

## 平台构建（进行中）

Windows 导出尚未执行；Android 工具链需检查；macOS/iOS 当前无 Apple 主机/Xcode，不会宣称验证成功。对应结果在本报告继续补齐，不另发第二份主线报告。

## 风险与后续建议

已修复过期热点接受输入及取消后按下残留；测试改为一致快照和有界状态等待。连续五轮通过仅是本环境证据，不是绝对稳定保证。触摸真机、安全区、后台恢复、低端机性能、平台包完整性仍需分别验证。详见 `docs/RISK_REGISTER.md`、`docs/adr/0002-layout-input-boundary.md`。

下一阶段可先用三件家具和前后图层验证宿舍灰盒的遮挡与触摸；不在本阶段实施。负责人仍需确认目标手机/Apple 测试环境及正式字体策略；本轮不决定正式玩法。
