# P0-02 阶段汇总报告

日期：2026-10-28（Asia/Shanghai）。范围见 `docs/tasks/P0-02_TASK.md`。本阶段唯一主线汇总；日志和 JSON 留在证据目录。

## 当前状态

**阶段性完成，设备与 Apple 平台验收仍未完成。** A/B 稳定性修复通过，C 已建立本地基线，D Windows 独立程序已构建并实际验证，E Android 调试 APK 已构建并校验签名/资源，F 已记录 Apple 平台条件。没有 Android 设备或可用模拟器，因此不宣称移动运行通过；macOS/iOS 未构建或运行。未实现正式玩法或进入 P0-03。

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
| 基线前 Headless | 254 通过、0 失败，退出码 0 | `docs/evidence/p0-02/09_headless/` |
| 基线前 Rendered | 连续 5 轮各 268 通过、0 失败、干净日志 | `docs/evidence/p0-02/10_stability/results.json` 和 `round_1` 至 `round_5` |
| 增加测试包入口后复测 | Headless 254/0，Rendered 连续五轮各 268/0 | `docs/evidence/p0-02/14_final_headless/`、`15_final_stability/` |
| Android 导出配置后复测 | Headless 254/0，Rendered 连续五轮各 268/0 | `docs/evidence/p0-02/17_headless/`、`18_stability/` |
| 最终图标/资源版本验收 | Headless 254/0，Rendered 连续五轮各 268/0；每轮退出码 0 | `docs/evidence/p0-02/20_headless/`、`21_stability/results.json` 和五轮原始结果 |
| 额外回归 | 每轮 10 次横竖屏切换、过期按下取消、按钮复位、进入/交互/返回/锁定；原 20 次往返及五种尺寸保留 | 同上逐项 JSON |
| 可视化操作工具 | node_repl 与备用通道均因 Windows sandbox `setup refresh had errors` 无法启动；不声称完成真人鼠标检查 | `docs/evidence/p0-02/11_visual/` |

现有测试命令保留，增加独立证据路径：`./tests/run.ps1 -EvidenceDir <目录>`、`./tests/run.ps1 -Rendered -EvidenceDir <目录>`。连续验收：`./tests/stability.ps1 -Rounds 5 -EvidenceRoot docs/evidence/p0-02/10_stability`。脚本拒绝覆盖已存在的稳定性目录，任一失败立即结束。

五种实际模拟窗口仍为 1920×1080、1280×800、1080×1920、1170×2532、360×780；均使用桌面 GPU，不等于手机真机。

## 文件变更

生产脚本修改仅 `ui/adaptive_layout.gd`、`scripts/map.gd`，未改建筑 Resource、ID、室内场景与正式玩法。

| 文件 | 变更目的 |
|---|---|
| `project.godot` | 保留真实主入口；仅测试导出特征 `p0_test` 选择包验证入口；启用 Android 导出要求的 ETC2/ASTC 导入 |
| `assets/p0_icon.svg` | 修复导出日志缺少工程图标的错误；纯几何技术占位，不是正式美术/品牌决定 |
| `export_presets.cfg` | Windows Test / Android Debug，官方同版本自定义模板、本地构建输出；无签名秘密 |
| `tests/run_tests.gd`、`run.ps1` | 保留原断言，增加时序/取消回归、一致快照、状态等待和独立证据目录 |
| `tests/stability.ps1` | 连续五轮验收，失败即停，拒绝覆盖已有目录 |
| `tests/diagnose.gd`、`resize_probe.gd` | 原流程被动跟踪、确定性旧热点实验 |
| `tests/package_entry.gd/.tscn`、`verify_windows.ps1` | 仅测试导出包的原生程序身份、GUI、资源和退出验证；默认仍显示真实地图 |
| `tests/check_apk.py` | 标准库静态核查 APK 的必要场景、ABI、图标完整导入链及禁止路径；不模拟设备运行 |
| `AGENTS.md`、`README.md`、`.gitattributes` | 对齐本次授权、复测/构建说明；源码 LF，原始证据保留字节与行尾 |
| `docs/tasks/P0-02_TASK.md`、ADR 0002、风险表、本报告、`docs/evidence/p0-02/` | 保存用户任务、决策及修复前后证据 |

新增 `.gd.uid` 随源码保留。`.tools/` 中下载、SDK/JDK、模板、独立编辑器配置和调试私钥不提交；`builds/` 产物不提交。未继承 WorkBuddy 代码或资产，没有建立通用玩法框架。

## Git

稳定性通过后使用已授权的 `yanhaiyun2002` / 用户提供的邮箱，仅本仓库配置。**稳定基线完整 ID：`de6e08d9eaed506c2cf80a3dda43b3da58818ceb`**，提交说明 `P0-02: fix layout input stability and establish baseline`。该提交发生在任何平台构建之前，保留稳定修复与证据。

**本阶段最终实现与构建验证提交完整 ID：`d9503390fe109cb24f3b60adfa925e82b1cce8b5`**，说明为 `P0-02: verify standalone Windows and Android debug builds`。包含本阶段全部实现、构建配置与测试证据。本报告和审计随后仅作提交 ID 登记，不改变代码或产物；最新文档登记提交的完整 ID 在主线交付消息提供，项目内可用 `git log -1 --format=%H` 核对。

无远程、不推送；原始日志为必要证据，不是游戏资产。基线门检查见 `docs/evidence/p0-02/baseline_gate.json`，最终检查为同目录 `final_audit.json`。

## Windows 独立包

同版本官方模板已取得并核对 `version.txt=4.7.2.stable`，提取条目经过 ZIP CRC 检查，指纹见 `docs/evidence/p0-02/12_windows/templates.json`。官方模板大包传输中断后，以已核对的 HTTP 206 区间续传并组装；工具包留在 `.tools/`。

实际执行：

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Test' --log-file docs/evidence/p0-02/19_windows_final/export.log
./tests/verify_windows.ps1 -EvidenceDir docs/evidence/p0-02/19_windows_final
```

构建和独立启动均退出码 0。从 `builds/windows/` 运行 EXE，未传工程路径，结果明确记录 `editor_feature=false`、`template_feature=true`。包内 17 项验证通过：真实地图、宿舍/学校场景存在、GUI 进入/交互/返回、商店反馈、错误 ID、工具/文档未打包、实际渲染截图。默认启动显示地图；显式 `-- --verify-package` 才运行验证并退出。另以 `--quit-after 120` 检查短时启动及自动退出；窗口关闭按钮未作人工操作测试。

| 产物 | 体积 |
|---|---|
| `builds/windows/NextStopRussia.exe` | 109,268,480 字节 |
| `builds/windows/NextStopRussia.pck` | 55,656 字节，须与 EXE 同目录 |

最终证据：`docs/evidence/p0-02/19_windows_final/` 中的 `export.log`、`export_console.txt`、`run_status.json`、`package_results.json`、`artifacts.json` 与 `map.png/dormitory.png/school.png`。此前已实际查看独立程序地图/学校截图和回归中的竖屏宿舍截图，未发现这些已查看截图的控件裁切或占位文字缺字；图标补齐后的截图也保存在最终目录。

最初尝试对官方发行模板使用 `--script` 覆盖入口，但该模板不支持路径覆盖，未执行测试且被超时终止；没有将该尝试算作通过。之后使用测试特征选择的显式包验证入口，验证的是实际发行模板与包内资源。证据在 `12_windows/unsupported_script_attempt.log` 和本节说明；发行版本日志可能为空，以显式写出的验证 JSON 和进程退出码共同验收。测试包包含验证脚本，不能称为已完成正式发行资产裁剪。

## Android 工具链、APK 与设备

初始无 JDK/SDK/adb。当前已在项目 `.tools/` 内准备官方工具，不改全局环境：Zulu OpenJDK 17.0.21、Google Command-line Tools 22.0（下载版号 15859902）、Platform-Tools 37.0.1、Build-Tools 35.0.1/36.0.0、Platform 35/36；最终使用与模板相符的 Build-Tools 36.0.0。组件来源/校验见 `docs/evidence/p0-02/13_android/sdk_components.json`、`sdk36_components.json`、`java_version.txt`、`sdkmanager_version.txt`、`adb_version.txt`、`toolchain_final.json`。

Godot 使用 `.tools/godot-4.7.2/_sc_` 的独立编辑器配置，SDK/JDK/调试私钥路径仅存在 `.tools/.../editor_settings-4.7.tres`。调试 RSA 私钥位于 `.tools/android-debug.keystore`，不提交，不用于正式发行。使用官方预编译 APK，不启用 Gradle或编译原生插件；没有安装 NDK/CMake，后续需要 Gradle/原生插件时另行补齐并验收。

实际执行：

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-debug 'Android Debug' --log-file docs/evidence/p0-02/13_android/export.log
```

APK 已成功构建，退出码 0；`apksigner verify --verbose --print-certs` 通过，v2/v3 签名有效。`aapt dump badging` 读取到包名 `org.nextstoprussia.p0test`、minSdk 24、target/compile SDK 36、`arm64-v8a` 与 `x86_64`，并声明竖屏特征。平台 35 是文档核查时的依赖列表，实际同版本模板目标为 36，以产物元数据为准；首次构建使用 35.0.1 工具回退成功，最终已用匹配的 36.0.0 重新构建及验签，回退警告消除。

产物：`builds/android/NextStopRussia-debug.apk`，57,049,255 字节（约 54.4 MiB），另有调试签名伴随文件 `.apk.idsig`。准确体积和 SHA-256 在 `docs/evidence/p0-02/13_android/artifacts.json`。必要场景/Resource 和禁止路径静态检查见 `apk_inventory.json`；实际签名和 Manifest 输出为 `signature_verification.txt`、`apk_badging.txt`。可复测 `python tests/check_apk.py builds/android/NextStopRussia-debug.apk --evidence <新的JSON路径>`，仅使用 Python 标准库。

**构建通过；模拟器未验证；真机未验证。** `adb devices -l` 实际返回空列表，SDK 内无 emulator 可执行文件，PATH 也无可用模拟器，见 `devices.txt`。没有设备系统版本、屏幕参数、FPS/内存、启动/加载/崩溃数据；这些字段为未测，不填估计值。触摸坐标、Android 系统返回、安全区域/导航栏、后台恢复和真机字体都未测，必须阻断 Android 发布验收，不能用桌面竖屏截图替代。

保留的构建失败：首轮非 Gradle 预设设置了仅 Gradle 可覆盖的 SDK 字段，且缺少 ETC2/ASTC 导入选项；修正后成功，原始失败见 `export_attempt1.log`。SDK Manager 首轮下载 Build-Tools 超时，改从 Google 官方仓库清单取得精确链接并校验后补齐；不是使用第三方镜像。JDK 最初两处官方二进制连接失败，最终从 Azul 官方 CDN 取得。

最终日志审计另发现“未指定项目图标”，即使导出退出码 0 也没有忽略；补充纯几何 SVG 后重新导出，最终日志无该错误，原日志为 `export_sdk36_missing_icon.log`。静态核查最初误以为 SVG 也采用场景的 `.remap`，实际是 `.svg.import` 指向 `.ctex`；按真实导入链修正检查并保留旧结果 `apk_inventory_wrong_icon_assumption.json`，最终要求导入元数据和指向纹理都存在。包内正常编译/导入资源会位于 `.godot/` 虚拟路径，这些是运行所需资源；源工程本地缓存目录仍不提交。

## macOS / iOS 可行性与必要条件

生产 GDScript 未引入 Win32、绝对 Windows 文件路径、第三方原生插件或 Windows 专有运行依赖；`res://` 场景/资源可复用。SystemFont 使用系统回退而未内嵌字体，各平台完整中俄字符仍需真机验证。

| 平台 | 必要环境与验证门槛 | 本次状态 |
|---|---|---|
| macOS | Godot 同版本 Universal 2 模板、Bundle ID；Mac 上实际启动、字体/布局/输入检查；发行前按 Apple 渠道完成代码签名/公证。Windows 可生成某些 ZIP 包，但不能验证 Mac 运行。 | 无 Mac，未导出、未运行、未签名/公证。 |
| iOS | macOS、支持目标 iOS SDK 的正式 Xcode、同版本模板、Team ID/Bundle ID、开发证书与描述文件、测试设备；Mac/Xcode 导出后单独检查真机触摸/安全区/后台恢复。 | 无 macOS/Xcode/Apple 签名或设备，未构建、未运行。 |

没有为了缺少 Apple 环境建立远程构建服务、购买开发者服务或宣称支持文档等于通过。发布前须锁定目标系统及 Xcode 版本，并复核对应 Apple 要求。

资料：[Godot 4.7 Android](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)、[Windows](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html)、[macOS](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html)、[iOS](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html)、[官方模板](https://godotengine.org/download/archive/4.7.2-stable/)、[Google SDK 工具](https://developer.android.com/studio#command-line-tools-only)。平台结论以本报告实际测试为限。

## 风险与后续建议

已解决：过期热点接受输入、取消后按下残留、跨时刻布局快照误导、固定帧数等待不足、Windows 独立包资源验证和 Android 调试构建。

未解决：移动真机/模拟器、安全区/后台恢复、低端设备性能、Apple 构建与签名、系统字体完整性。新增限制：原生 UI 操作工具被沙箱初始化错误阻断，已执行的 GUI 合成输入不等于真人操作；正式发布前需人工复核。模板/SDK 下载曾不稳定，复现构建需要按记录准备官方工具；私钥不得进入 Git。

下一阶段建议只做宿舍空间灰盒：一房间、三件几何家具、前后分层/替换/遮挡，先验证正面空间与手机可读性，再决定是否需要局部 3D；不接入找猫、整理、学习或成长。本阶段未实施这些建议。

负责人待决事项：提供可调试 Android 真机或安排标准模拟器验收；安排 Mac/Xcode/Apple 签名与测试设备；确认正式应用 ID、字体授权和目标设备性能预算。上述条件未完成前不能签署对应平台发布通过。是否启动下一阶段仍由负责人另行确认。
