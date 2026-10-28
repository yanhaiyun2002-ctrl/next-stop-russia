# P0-01 实际测试报告

> 版本基线收尾复测更新：headless 154/0；两轮 Windows 渲染分别为 145/14、151/11（通过/失败），因此未创建基线提交。详见 [P0-01_BASELINE_CLOSURE.md](P0-01_BASELINE_CLOSURE.md)。以下保留首次交付时的历史测试记录；当前日志/截图已被本次复跑更新，不能再据下文历史摘要宣称本次全通过。

日期：2026-10-28（Asia/Shanghai）。最终结果：**headless 154 项断言通过、0 失败；Windows Compatibility 实际渲染 168 项断言通过、0 失败。** 两组包含重复覆盖，不是 322 个独立功能。只有本报告明确执行的条件可称为通过。

## 环境与证据

| 项目 | 实际记录 |
|---|---|
| 系统 | Microsoft Windows NT 10.0.26200.0，PowerShell 7.6.5 |
| 引擎 | `4.7.2.stable.official.ed1daf0bf`，官方标准版 Windows x64 便携包 |
| 渲染 | `OpenGL API 3.3.0 NVIDIA 610.88 - Compatibility` |
| GPU | NVIDIA GeForce RTX 3070 Laptop GPU（由实际 Godot 启动输出获得） |
| Git | 2.53.0.windows.3；根目录初始无仓库，现有本地初始化，remote 为空 |
| SDK/模板 | java、adb 不在 PATH；常见 Android SDK 路径不存在；Roaming/Local 两处同版本标准模板目录不存在。没有配置平台导出预设。 |

原始记录：[environment.json](evidence/environment.json)、[import.log](evidence/import.log)、[main_startup.log](evidence/main_startup.log)、[headless.log](evidence/headless.log)、[rendered.log](evidence/rendered.log)。逐条断言及热点矩形：[headless_results.json](evidence/headless_results.json)、[rendered_results.json](evidence/rendered_results.json)。

下载包 SHA256：`731980F9608D61333E5BAF54A2EF17210ACC7A538446C0CB9969F002ACA1E953`。这是本地文件指纹记录，未额外比对发布者校验清单；下载来自官方归档链接指向的镜像，TLS 服务器证书验证保留。

## 实际执行命令

以下以项目根目录 `E:\俄语游戏\NEXT_STOP_RUSSIA` 为工作目录；`.tools` 不进入 Git。

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --version
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --log-file 'docs/evidence/import.log'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd --log-file 'docs/evidence/headless.log'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/run_tests.gd --log-file 'docs/evidence/rendered.log'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --quit-after 120 --log-file 'docs/evidence/main_startup.log'
```

交付测试入口也已实际执行：

```powershell
./tests/run.ps1
./tests/run.ps1 -Rendered
```

版本核对、导入、主入口启动、最终两组测试进程均退出码 0。主入口命令由 `project.godot` 的 `run/main_scene` 启动，未通过测试脚本替代入口。120 帧后自动退出，只证明短时启动，不是稳定性/性能长测。

最终测试摘要输出：

```text
P0_TEST_RESULT passed=154 failed=0 display=headless
P0_TEST_RESULT passed=168 failed=0 display=Windows
```

## 实际验证内容

| 验证项 | 结果与方法 |
|---|---|
| 导入/脚本/资源 | Godot 实际导入和测试加载。主场景、三资源、两独立建筑场景均实际加载，无最终解析错误。 |
| 地图入口 | 测试确认地图初始可见且无室内实例；另直接启动真实入口。 |
| 宿舍→交互→返回 | 实际加载宿舍场景；GUI 鼠标事件点击交互与返回，检查反馈与状态。 |
| 学校→交互→返回 | 同上，独立学校场景。 |
| 锁定商店 | 保持按钮可交互，通过 GUI 点击和直接导航请求验证 `locked` 反馈及留在地图。 |
| 错误 ID/场景 | 未知 ID、空路径、不存在路径、场景存在但缺少 BuildingRoom 接口，均拒绝并保留地图。 |
| 重复操作 | 同帧两次进入/返回、额外 20 轮交替往返；检查地图实例不变、室内节点无残留。没有执行长时间内存泄漏测试。 |
| 导航状态 | 返回保留建筑选择、地图实例及对应按钮焦点；当前地图没有平移/缩放，无相机位置恢复需求。 |
| 五种尺寸 | 逐一改变实际 Window 大小，等待容器布局；检查按钮在视口和地图内、互不重叠、≥48 逻辑单位；每种尺寸实际通过 GUI 点击两栋楼、交互、返回和商店反馈。 |
| 安全区 | 注入 1170×2532 上的 `Rect2(0,150,1170,2280)`，即顶部 150、底部 102 物理像素，转换后确认三热点与室内返回在安全区内。属于模拟，不是读取手机刘海实测。 |
| 鼠标/触摸 | 鼠标事件经 `Viewport.push_input`；合成 ScreenTouch 经 `Input.parse_input_event` 与引擎 touch→mouse 模拟，仅进入一次；按下拖出热点再释放不进入。非真人/真机操作。 |
| 系统返回/Escape | 关闭默认 `quit_on_go_back`；合成系统返回通知与键盘 Escape 输入都从室内返回地图。未执行 Android 系统手势真机验证。 |
| 方向切换 | 室内由竖转横后返回按钮仍可访问，随后可回地图。 |
| 真实渲染 | Windows GPU Compatibility 运行，保存五种地图、四张室内和一张模拟安全区 PNG；地图 PNG 尺寸逐项断言。 |

## 布局证据（均为桌面模拟视口）

| 请求/实际窗口像素 | 实际逻辑视口 | 构图 | 截图 |
|---|---|---|---|
| 1920×1080 | 1280×720 | 横向街区 | [横屏 16:9](evidence/map_1920x1080.png) |
| 1280×800 | 1280×800 | 横向街区 | [横屏 16:10](evidence/map_1280x800.png) |
| 1080×1920 | 438×780 | 纵向街区，等比扩展可用宽度 | [竖屏 9:16](evidence/map_1080x1920.png) |
| 1170×2532 | 360×780 | 纵向街区 | [长竖屏](evidence/map_1170x2532.png) |
| 360×780 | 360×780 | 纵向街区、小尺寸文字检查 | [小屏基准](evidence/map_360x780.png) |

已实际查看五张地图截图与模拟安全区截图；标题、建筑、反馈可见，横屏为横向排列、竖屏为纵向排列，未使用非等比整图拉伸。已查看 [宿舍竖屏](evidence/dormitory_360x780.png) 与 [学校横屏](evidence/school_1280x800.png)，中俄占位文字可见，交互/返回可见；另保存 [宿舍横屏](evidence/dormitory_1280x800.png)、[学校竖屏](evidence/school_360x780.png)。这些短句的表现不代表字体全部字符或完整教学排版已验证。

安全区截图：[模拟安全区](evidence/map_safe_area.png)。安全区外背景仍正常填满，内容缩入边距。

## 曾发生的失败与处理

1. `git status --short` 初始返回“not a git repository”；后使用本机已有 Git 初始化本地仓库，无远程。
2. 初始 PowerShell 下载因沙箱套接字限制失败；获准网络执行后遇 TLS EOF；curl 默认撤销查询报告 `CRYPT_E_REVOCATION_OFFLINE`。改用官方镜像、`--ssl-revoke-best-effort`（保留服务器证书验证）后下载成功，执行版本与官方发布 commit 对应。
3. 沙箱进程启动曾报辅助进程 `setup refresh had errors`，不能据此断言项目失败；获准直接运行后导入与测试正常。
4. 第一轮测试脚本解析失败：动态类型属性无法推断 `map_instance`，退出码 1；改为显式 `int` 后重跑通过。该失败发生于测试代码；最终日志为覆盖写入的最终成功轮次，此处保留失败事实。
5. 审查发现引擎默认 `quit_on_go_back=true` 会破坏 Android 返回预期，已关闭并增加合成通知断言。这是静态审查发现并修复的问题，不描述为已发生的手机故障。

## 明确未执行

- **Windows 发行包构建/运行**：未安装同版本导出模板，未建立发行预设；编辑器运行成功不等于导出成功。
- **macOS 构建/运行**：无 macOS 主机与签名环境。
- **Android 构建/真机运行**：未配置 JDK、SDK、签名、目标设备；没有 APK/AAB、模拟器或手机测试。
- **iOS 构建/真机运行**：当前为 Windows，无 macOS/Xcode/签名与测试设备。
- 手机真实 DPI、刘海、安全区返回值、系统手势、多指、旋转与后台恢复、低端机性能/发热/音频路由；本次仅覆盖桌面注入的布局与输入。
- 家具遮挡、拖放玩法、完整中俄字符集/字体许可、音频播放、语音服务、存档迁移、正式内容和 DEMO 包内隔离；都不在此次实现与通过结论内。

因此 P0-01 的地图主工程和模拟布局验收有实测证据；跨平台发布没有被验收。后续风险与最小实验见 [RISK_REGISTER.md](RISK_REGISTER.md)。
