# 《下一站，俄罗斯！》P0-03R

当前横向空间验证见 [P0-03R_SUMMARY.md](docs/reports/P0-03R_SUMMARY.md)；P0-03/V 的 Git 基线、截图和测试完整保留，较早报告为历史记录。

Godot **4.7.2 Stable 标准版** + GDScript + Compatibility 的主工程。启动即进入第一层级地图；宿舍进入正视广角 2D 空间灰盒，学校保留临时交互，商店锁定并显示反馈。建筑均为技术样例。

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

其他机器从 [官方 4.7.2 归档](https://godotengine.org/download/archive/4.7.2-stable/) 取得标准版，使用相应可执行文件即可。运行工程无需导出模板；构建需要同版本模板与平台工具链。P0-02 已验证当时的 Windows 独立测试包与 Android 调试 APK 构建，设备/Apple 平台边界见阶段汇总；新增宿舍尚未做包构建验证。

## 操作和布局

- 鼠标点击或单指触摸建筑，选择宿舍/学校进入；商店显示未开放提示。
- 建筑内点击交互按钮查看文字反馈，点击“返回地图”或按 Escape 返回。系统返回通知在室内也会返回地图；移动端仅作合成通知验证。
- 默认宿舍为横向连续灰盒：PC 看较宽区域，手机先看中部局部，左右拖动浏览；点击只显示名称，不跳镜头。移动超过 10 逻辑单位且水平为主时判为拖动，竖向移动取消点击；无惯性或缩放。
- “床/书桌/衣柜”平移至对应区域，“复位”返回默认取景，“测试”展开标记/换位/横移/顶面和构图选项。五个常驻按钮至少 48 逻辑单位，调试默认收起。相机有界，窗口或取景变化会取消旧按下。
- 展开可回放原版/适中/紧凑的 V 预设，手机 A/B 只在这些旧预设中启用；旧“全景/聚焦”也随之恢复。不同方向、预设与浏览均复用当前三家具实例；预设切换重置样例位置，不是家具编辑或存档。
- “标记换点”循环六个测试位置，“标记前后”以 0.35m 步长往返测试深度；“书桌换位”切换两个不相交槽位。橙色标记是遮挡测试工具。家具实体相交和越界移动被拒绝；当前不提供任意拖放、旋转或存档。
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

P0-03 空间测试：`./tests/dormitory.ps1 -EvidenceDir docs/evidence/自选未存在目录`，加入 `-Rendered` 保存真实窗口截图并比对可见面像素。独立射线与物理盒相交用于核对遮挡拾取，覆盖五种尺寸、家具换位、标记深度、鼠标/合成触摸和导航回归。模拟视口、安全区与合成触摸不等于手机验收。脚本不覆盖已有同名证据目录，空间测试有 120 秒超时保护。

P0-03V 构图与天花板比较：`./tests/composition.ps1 -Rendered -EvidenceDir docs/evidence/自选未存在目录`；不加 `-Rendered` 为无窗口逻辑检查。180 秒超时。原有控件测试现在先点开折叠面板再交互；空间射线使用实际眼高/距离/焦距，换位采样点随较低眼高改为标记头部上缘，全部遮挡/错误导航/输入保障保留。

P0-03R：`./tests/ribbon.ps1 -Rendered -EvidenceDir docs/evidence/自选未存在目录`，不加 `-Rendered` 为 Headless。覆盖默认入口、五尺寸、鼠标/合成触摸拖动及端点、逐步连续性、点击冲突、移动热点、新位置遮挡、安全区和重入。V 的两套坐标专用测试先显式选择保留的紧凑预设，不删除旧断言；默认 R 由新套件和导航回归覆盖。触摸采样等待引擎分发帧，不能把注入队列里的旧相机坐标当成实际运动。

视频 `docs/references/dorm_visual_reference.mp4` 和派生参考帧仅留本地分析，已忽略且在 `docs/.gdignore` 范围，不作为游戏资源或最终拼图素材。Windows 自带 MediaComposition 取帧脚本见 `docs/evidence/p0-03r/extract_reference.ps1`。没有复制参考美术/动画。

## 最小结构

| 路径 | 职责 |
|---|---|
| `project.godot` / `scenes/main.tscn` | 唯一主入口、渲染与输入配置 |
| `scripts/main.gd` | ID/开放状态/场景验证、转换锁、独立场景进出 |
| `scenes/map.tscn` / `scripts/map.gd` | 第一层级地图 UI，发出 ID 请求 |
| `data/building_definition.gd` / `data/buildings/*.tres` | 稳定 ID、名称、归一化位置、目的场景、开放状态 |
| `scenes/buildings/*.tscn` / `scripts/building_room.gd` | 独立建筑与公共返回/交互合同 |
| `scenes/dormitory/` / `scripts/dormitory/` | 三件独立几何家具、共享空间状态、CanvasItem 透视/切片/拾取、宿舍 UI |
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

本次无正式房间、美术、学习、NPC、找猫、整理、经济、存档或联网系统。宿舍只验证三件轴对齐家具和固定镜头；不保证任意旋转、相交模型、软体或透明材质的排序。DEMO/正式版共用主工程，未来按构建配置及显式资源清单隔离正式资产，不复制代码库。

本地 Git 已建立经授权的稳定基线，无远程、无推送。`.tools/`、`.godot/`、构建输出和凭据已忽略；脚本 `.uid` 应随源码保留。`docs/.gdignore` 避免报告和截图被引擎当作游戏资源导入。测试导出预设并不表示正式发行、DEMO/正式资产隔离或商店发布已验收。

## 测试构建

`export_presets.cfg` 的模板路径为 `.tools/export_templates/`。从官方同版本模板 ZIP 提取 `windows_release_x86_64.exe`、`windows_debug_x86_64.exe`、`android_debug.apk`、`android_release.apk`、`version.txt` 到该目录；模板不加入 Git。实际模板指纹见阶段汇总引用的 JSON。

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Test'
./tests/verify_windows.ps1 -EvidenceDir docs/evidence/自选未存在目录
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-debug 'Android Debug'
```

Windows 产物为 `builds/windows/NextStopRussia.exe` 与同目录 `.pck`，可脱离编辑器运行。`Windows Test` 默认显示真实地图，只有显式用户参数 `-- --verify-package` 才执行包内验证并退出；验证脚本还检查实际二进制不是编辑器。测试包保留必要测试脚本，不作为正式发行包裁剪方案。

Android 产物为 `builds/android/NextStopRussia-debug.apk`。须在 Godot 编辑器设置填写本机 JDK/SDK 和调试签名路径；本机用 `.tools/godot-4.7.2/_sc_` 与 `editor_data/editor_settings-4.7.tres` 隔离这些设置。使用 JDK 17、Platform/Build-Tools 36、Platform-Tools，当前预设使用官方预编译 APK，不启用 Gradle。正式 Gradle/原生插件工作需要另核 NDK/CMake。调试私钥只存 `.tools/`，不可提交或当作正式发行身份。

本次 `adb devices -l` 为空，无模拟器，APK 仅验证构建/签名/包内资源，未验证手机运行。

上述独立 EXE/APK 构建证据属于 P0-02；P0-03 本轮验证源工程与 Windows 渲染，未重新构建平台包。

**本次止于 P0-03R，等待负责人依据真实对照图确认横向空间及手机浏览方式，不自动开始 P0-04。**
