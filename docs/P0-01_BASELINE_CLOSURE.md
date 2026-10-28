# P0-01 版本基线收尾记录

日期：2026-10-28（Asia/Shanghai）。授权范围仅工作区检查、已有测试复跑、全部通过后创建本地基线提交；不开发 P0-02，不改变游戏功能。

## 当前决定

**未创建基线提交，暂无 commit ID。** 本次 headless 通过，但带渲染的两轮原样复跑均失败，未满足“如果测试通过，创建提交”的条件。未执行 `git add`、`git commit`、创建远程或推送。未修改工程配置、游戏脚本、场景、建筑资源或测试逻辑。

## 工作区与忽略规则检查

初始待提交集合为 54 个文件，约 1 MB，类别为 GDScript/UID、Godot 场景与资源、PowerShell 测试入口、Markdown 文档、JSON/日志和 10 张 Godot 测试截图。未发现待提交的引擎下载、缓存、可执行文件或发行包。

对候选文本逐文件扫描私钥头、常见访问令牌、密钥/密码赋值及带凭据 URL，未命中；文件名与类别检查未发现凭据文件。此为本地静态检查，不声称能证明任意格式的秘密绝对不存在。PNG 为已有游戏视口截图。

`.tools/` 的引擎下载和 `.godot/` 缓存保留在本机并被忽略，不属于基线候选。保留 `docs/evidence/` 下的日志、JSON 和截图作为必要验收证据，不将其视为发行构建产物。

本次增强 `.gitignore`：增加 `/build/`、`/dist/`、`.env`、`.env.*`、`.aws/`、`.ssh/` 以及常见私钥/签名文件后缀；已有 `.tools/`、`.godot/`、`builds/`、`export_credentials.cfg` 继续生效。使用 `git check-ignore` 对 16 个代表路径验证均被忽略，记录见 [baseline_audit.json](evidence/baseline_audit.json)。

Git 姓名、邮箱原未配置；用户已提供邮箱，计划以邮箱前缀作为显示名，仅用于本仓库。由于未进入提交步骤，未写入本地或全局身份配置，也没有创建作者身份的提交。

## 本次实际复测

引擎仍为 `4.7.2.stable.official.ed1daf0bf`。Windows 使用 `OpenGL API 3.3.0 NVIDIA 610.88 - Compatibility`、NVIDIA GeForce RTX 3070 Laptop GPU。未改动测试断言或降低要求。

| 命令 | 实际结果 | 证据 |
|---|---|---|
| `./tests/run.ps1` | 导入及测试退出码 0；**154 通过 / 0 失败** | [headless.log](evidence/headless.log)、[逐项结果](evidence/headless_results.json) |
| `./tests/run.ps1 -Rendered`（第 1 轮） | 导入退出码 0，测试退出码 1；**145 通过 / 14 失败** | [第 1 轮日志](evidence/baseline_rendered_attempt1.log)、[逐项结果](evidence/baseline_rendered_attempt1.json) |
| `./tests/run.ps1 -Rendered`（第 2 轮，原样复现） | 导入退出码 0，测试退出码 1；**151 通过 / 11 失败** | [第 2 轮日志](evidence/baseline_rendered_attempt2.log)、[逐项结果](evidence/baseline_rendered_attempt2.json) |
| Godot `--path . --quit-after 120 --log-file docs/evidence/main_startup.log` | 主入口实际启动，退出码 0；仅短时启动检查 | [main_startup.log](evidence/main_startup.log) |

两轮渲染测试各自保存，不用后一次覆盖来掩盖首轮失败。`rendered.log`、`rendered_results.json` 和截图为第 2 轮的最新输出；测试内有条件断言，某些进入失败后不会执行相应室内断言，因此各轮断言总数不同，不能把计数差异视为删除了测试。

## 尚未解决的问题

1. **阻断基线：原生窗口中的导航/点击/返回及方向检查未稳定通过。** 第 1 轮涉及 1920×1080 下进入宿舍/学校、商店反馈等；第 2 轮出现学校返回失败、1080×1920 方向/热点检查失败及长竖屏进入失败。错误均由既有断言记录，不是解析错误。
2. 第 2 轮 1080×1920 的记录中，逻辑视口已为 438×780，但先采样的宿舍/学校按钮仍为横屏的 200×110，后采样商店已为竖屏的 156×92。这证明该轮采样与输入期间布局未保持一致；是否来自测试等待条件、原生窗口事件/输入竞争或功能逻辑，**根因未确认**，不归因为用户操作，也不将其标成已修复。
3. headless 成功不替代原生渲染/输入验证；先前交付的通过记录是历史结果，本次失败不能被历史结果抵消。
4. Windows 发行包、macOS、Android/iOS 真机、移动安全区和生命周期等原未验证条件没有变化，本次未安装工具链或扩展验证范围。

当前仅更新忽略规则、收尾记录、报告状态提示和测试证据；保留现有功能与测试原样。修复或更改测试/功能应另行明确范围，本轮不擅自实施。任务停止在 P0-01，未启动下一阶段。
