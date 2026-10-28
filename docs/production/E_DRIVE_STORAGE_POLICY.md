# Windows 开发 E 盘优先／减少 C 盘写入（P1 有效）

## 硬约束

- 当前已知工作工程：`E:\俄语游戏\NEXT_STOP_RUSSIA`。**工程、Godot 便携引擎、源码仓库、工作树、SDK/JDK、导出模板、构建产物、录屏、自动化证据、测试临时数据及大缓存优先 E 盘**。
- 不迁走已经存在的 C 盘用户目录，不修改全局系统变量、不批量删除 C 盘缓存，不动 Windows 自己必需的文件。
- 若某个工具必须在 C 盘使用少量系统组件或其写入路径不可简单重定向，记录真实原因/估计占用和替代方案，**不要声称零 C 盘写入**。
- 任何**可能产生几百 MB～GB** 的安装、SDK/虚拟机镜像/素材包/新 Worktree 前，先检查目标位置与 E 盘剩余空间；不能以“加速项目”为由擅自往 C 盘下载。

## 当前 Godot 实际配置

- P0-02 报告已指出已有便携版 Godot 位于 `.tools/godot-4.7.2/`，Android SDK/JDK 和调试密钥保存在项目 `.tools/`，导出产物保存在 `builds/`，受 `.gitignore` 忽略。**优先沿用现有内容，禁止重复下载/安装**。
- Godot 正式文档说明：与 Godot 编辑器可执行文件同目录的 `_sc_`（或 `._sc_`）标记可启用 **self-contained mode**，将**编辑器数据、设置、缓存**放到编辑器目录下的 `editor_data/`。若当前已存在 `_sc_`，不要再改动或重新安装；如不存在，先核对编辑器二进制位置在 E 盘、关闭 Godot，才评估安全启用。
- 每个 Godot 工程导入产生的 `.godot/` 默认位于**相应项目目录**；将主工程、Worktree 放 E 盘可使其也在 E 盘，但多 Worktree 会重复导入缓存。
- **Godot 导出的游戏不支持直接使用编辑器 `_sc_` 模式**。运行测试包的 `user://` 玩家数据通常仍在系统用户数据目录；正式测试要设计 DEV/PLAYTEST 独立存档并在适当时点验证实际目录，不能仅靠 `%TEMP%` 认为已经转移。

## 本包提供的进程级脚本

在项目目录打开 PowerShell，执行：

```powershell
.\scripts\dev\use-e-drive.ps1
```

当前 PowerShell 进程配置项目 `.local-dev/` 下的 TEMP/TMP、Gradle 缓存、Android AVD/用户目录、Python/pip/uv/npm 缓存；不修改 Windows 永久设置。**同一终端**启动 Codex、Godot、测试命令才能继承变量（不同终端不会自动继承）。脚本不会修改 `project.godot`，不会移动或删除现有数据；若无法写入项目磁盘则抛错。

## 工具、构建和工作树建议路径

| 项目 | 推荐路径 |
|---|---|
| Godot 编辑器与其编辑器缓存 | `E:\俄语游戏\NEXT_STOP_RUSSIA\.tools\godot-4.7.2\...` |
| Godot 工程导入 | `E:\俄语游戏\NEXT_STOP_RUSSIA\.godot\` |
| Android SDK、JDK、私钥 | `E:\俄语游戏\NEXT_STOP_RUSSIA\.tools\...`（以当前实际目录为准） |
| Android AVD 镜像 | `E:\俄语游戏\NEXT_STOP_RUSSIA\.local-dev\android-avd\` |
| 构建输出 | `E:\俄语游戏\NEXT_STOP_RUSSIA\builds\` |
| 原始测试/截图 | `E:\俄语游戏\NEXT_STOP_RUSSIA\docs\evidence\` |
| 临时下载／构建 cache | `E:\俄语游戏\NEXT_STOP_RUSSIA\.local-dev\` |
| 独立 worktree | `E:\俄语游戏\worktrees\<task>` |
| 设计与临时素材 | `E:\俄语游戏\NEXT_STOP_RUSSIA\assets` 和 `docs/design` |

检查 `.gitignore` 已忽略 `.local-dev/`；若未忽略，在以后 P1-01 阶段允许加精确一行，不覆盖已有忽略规则。

## 不承诺的事情

修改 PowerShell 的 `TEMP/TMP` 不能保证 Windows Defender、GPU 驱动、VSCode/Codex 自身全局用户配置、Windows 更新或其它工具不会写入 C 盘。若要改变 Codex 自身 HOME，请先确认工具官方支持的参数，不要全局重定向 `USERPROFILE` 或 `APPDATA` 冒险破坏登录设置。

Godot 官方文档：https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html
