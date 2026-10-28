# 《下一站，俄罗斯！》P0-02

当前阶段汇总见 [P0-02_SUMMARY.md](docs/reports/P0-02_SUMMARY.md)；P0-01 报告为历史记录。

Godot **4.7.2 Stable 标准版** + GDScript + Compatibility 的最小主工程。启动即进入第一层级地图；宿舍、学校可进入独立临时场景并交互/返回；商店锁定并显示反馈。建筑均为技术样例。

## 运行

用 Godot 4.7.2 导入根目录 `project.godot`，按 **F5** 运行整个工程。不要用 F6 单独运行建筑来验收导航；返回信号由主入口连接。

本机已取得便携版（不纳入 Git）：

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --editor
```

直接运行：

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path .
```

其他机器从 [官方 4.7.2 归档](https://godotengine.org/download/archive/4.7.2-stable/) 取得标准版，使用相应可执行文件即可。运行工程无需导出模板；生成发行包需要同版本模板与平台工具链，本次没有验证发行包。

## 操作和布局

- 鼠标点击或单指触摸建筑，选择宿舍/学校进入；商店显示未开放提示。
- 建筑内点击交互按钮查看文字反馈，点击“返回地图”或按 Escape 返回。系统返回通知在室内也会返回地图；移动端仅作合成通知验证。
- 可以调整 PC 窗口比例。横屏以 1280×720 为基准，竖屏以 360×780 为基准，重排建筑坐标并等比缩放 UI，采用安全区边距。移动导出默认竖屏。
- 地图保留实例、当前建筑选择和焦点；无平移/缩放，也不保存到磁盘。交互计数是当前室内实例的临时状态，重新进入会重置。

## 复测

在根目录运行 PowerShell：

```powershell
./tests/run.ps1
./tests/run.ps1 -Rendered
```

自定义引擎路径：

```powershell
./tests/run.ps1 -Godot 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' -Rendered
```

脚本先检查版本并导入，再执行真实 Godot 集成测试。`-Rendered` 会打开测试窗口、改变窗口大小并生成实际渲染截图；默认 headless 不验证画面。需要完整 Windows 图形会话；测试有 90 秒超时退出保护。用 `-EvidenceDir docs/evidence/自选目录` 保存独立轮次，避免覆盖证据。测试使用合成输入，不等于真机触摸测试。

连续稳定性验收：`./tests/stability.ps1 -Rounds 5 -EvidenceRoot docs/evidence/自选未存在目录`。任一轮失败停止，保留全部结果；不以多次重试挑选通过轮次。

## 最小结构

| 路径 | 职责 |
|---|---|
| `project.godot` / `scenes/main.tscn` | 唯一主入口、渲染与输入配置 |
| `scripts/main.gd` | ID/开放状态/场景验证、转换锁、独立场景进出 |
| `scenes/map.tscn` / `scripts/map.gd` | 第一层级地图 UI，发出 ID 请求 |
| `data/building_definition.gd` / `data/buildings/*.tres` | 稳定 ID、名称、归一化位置、目的场景、开放状态 |
| `scenes/buildings/*.tscn` / `scripts/building_room.gd` | 两个独立临时建筑与本地交互 |
| `ui/adaptive_layout.gd` / `ui/map_board.gd` | 横竖屏基准、安全区转换、地图投影 |
| `ui/theme.tres` | 系统字体回退与基础主题；字体未内嵌 |
| `tests/` | 引擎内导航、布局、合成输入集成测试与错误场景样本 |
| `docs/` | 审查、风险、ADR、中文交付报告、测试原始证据 |

新增技术建筑需增加 `.tres` 并加入 `scripts/main.gd` 的 CATALOG；当前没有目录扫描或通用内容注册框架。ID 必须唯一，不以显示名称作导航键。

## 交付与边界

- [版本基线收尾记录：渲染复测失败，暂未提交](docs/P0-01_BASELINE_CLOSURE.md)
- [中文开发报告](docs/P0-01_DEV_REPORT.md)
- [技术可行性审查](docs/TECH_FEASIBILITY.md)、[风险登记表](docs/RISK_REGISTER.md)、[架构决策](docs/adr/0001-p0-map-boundaries.md)
- [实际测试结果与命令](docs/TEST_REPORT.md)

本次无正式房间、美术、学习、NPC、找猫、整理、经济、存档或联网系统。DEMO/正式版共用主工程，未来按构建配置及显式资源清单隔离正式资产，不复制代码库。

本地 Git 已初始化，无远程、无自动提交或推送。`.tools/`、`.godot/`、构建输出和凭据已忽略；脚本 `.uid` 应随源码保留。`docs/.gdignore` 避免报告和截图被引擎当作游戏资源导入。没有生成发行预设，也没有声称 DEMO/正式资产隔离已构建验证。

**本次止于 P0-02，不自动开始 P0-03。**
