# P0-03 中文开发与技术验证报告

日期：2026-10-28。阶段：正视广角宿舍空间灰盒。技术基线：Godot `4.7.2.stable.official.ed1daf0bf`、GDScript、Compatibility。

## 1. 完成状态

本轮已在原主工程完成最小宿舍灰盒、家具换位与标记遮挡实验，保留地图导航和学校/商店行为。结论为：**当前三个几何样例的 2D 正视透视方案初步可行，建议保留为候选；视觉方向与竖屏交互仍等待负责人按截图确认。** 自动化通过不代表正式视觉验收通过。完成后停止在 P0-03，不开发 P0-04。

开工时工作区干净，可恢复的 P0-02 稳定 HEAD 为 `2c324abb8a38cae2952d0ad8e6f7c6addbbde3a3`，实现父提交为 `d9503390fe109cb24f3b60adfa925e82b1cce8b5`。已先阅读工程规则、技术基线、功能可行性、P0-01 任务、P0-02 汇总、风险登记与既有 ADR，再核对新任务的范围。最新正式任务书授权本轮 P0-03，旧阶段的停止条款保留为历史。

前置审查认为：固定镜头与三件轴对齐家具可以低成本先用 CanvasItem 验证；整件家具按底边排序不足以处理床面、桌腿空隙与高柜。主要扩展风险是未来插画切层、复杂角色姿态/家具旋转和小屏精确操作，不能凭本轮样例推定已解决。决策与限制见 [ADR 0003](../adr/0003-dormitory-fixed-projection.md)。未读取、移植或使用 WorkBuddy 旧 DEMO 资源；全部灰盒由本工程简单几何绘制。

## 2. 请优先审看的真实截图

以下均由本轮 Godot Windows 窗口真实渲染保存，不是示意设计稿或 headless 产物。路径均相对于项目根目录；报告中的链接用于直接打开文件。

| 证据 | 项目内相对路径及观察点 |
|---|---|
| **PC 主图 1920×1080** | [docs/evidence/p0-03/06_final_spatial_rendered/room_auto_1920x1080.png](../evidence/p0-03/06_final_spatial_rendered/room_auto_1920x1080.png)：后墙、两侧墙和纵深地面，前床/中桌/后柜同一水平视轴。 |
| **手机主图 360×780 模拟** | [docs/evidence/p0-03/06_final_spatial_rendered/room_auto_360x780.png](../evidence/p0-03/06_final_spatial_rendered/room_auto_360x780.png)：默认书桌聚焦，三列按钮，左右家具部分裁切，可直接切换聚焦。 |
| 手机床聚焦 | [docs/evidence/p0-03/06_final_spatial_rendered/portrait_focus_bed.png](../evidence/p0-03/06_final_spatial_rendered/portrait_focus_bed.png)：床和标记可清楚辨认。 |
| 手机全景对照 | [docs/evidence/p0-03/06_final_spatial_rendered/room_overview_360x780.png](../evidence/p0-03/06_final_spatial_rendered/room_overview_360x780.png)：三家具同时可见，但尺寸偏小。 |
| 标记在床前 | [docs/evidence/p0-03/06_final_spatial_rendered/marker_front_bed.png](../evidence/p0-03/06_final_spatial_rendered/marker_front_bed.png)：橙色头部、杆和底座在床前可见。 |
| 标记在床后 | [docs/evidence/p0-03/06_final_spatial_rendered/marker_behind_bed.png](../evidence/p0-03/06_final_spatial_rendered/marker_behind_bed.png)：标记被遮住，点击该位置命中床体。 |
| 局部遮挡边界 | [docs/evidence/p0-03/06_final_spatial_rendered/bed_boundary_z2.10.png](../evidence/p0-03/06_final_spatial_rendered/bed_boundary_z2.10.png)：标记部分露出、躯干被床体遮挡；这是穿过实体的技术探针，不是角色碰撞。 |
| 桌腿间隙 | [docs/evidence/p0-03/06_final_spatial_rendered/marker_desk_gap.png](../evidence/p0-03/06_final_spatial_rendered/marker_desk_gap.png)：标记从腿间可见、头部被桌面局部遮挡。 |
| 家具换位前 | [docs/evidence/p0-03/06_final_spatial_rendered/desk_before_move.png](../evidence/p0-03/06_final_spatial_rendered/desk_before_move.png)：固定镜头与标记，书桌仍在后方。 |
| 家具换位后 | [docs/evidence/p0-03/06_final_spatial_rendered/desk_front_overlap.png](../evidence/p0-03/06_final_spatial_rendered/desk_front_overlap.png)：前方书桌覆盖部分床体及标记头部，腿间仍透出杆和底座。 |

同目录还保存 1280×800、1080×1920、1170×2532、各竖屏全景/聚焦和模拟安全区图，共 20 张。原始尺寸、实际窗口、逻辑视口、画布矩形、标记和书桌状态逐图记录在 `spatial_results.json`。

开发者已通过图片工具审看真实渲染：PC 空间方向与家具轮廓初步可辨，墙/地线汇聚一致；没有用拉伸改变家具比例。手机全景有较多空白，家具不适合精确触摸，聚焦可改善但增加一步取景操作。这是当前方案明确的体验取舍，不能通过数字断言自动消除。

## 3. 实现与操作

`DormitoryWorld` 为局部 Node2D，记录家具、标记和两个书桌槽位。床、书桌、衣柜各有独立场景、稳定内部 ID、地面坐标、占地尺寸和盒体样例。`DormitoryView` 通过 CanvasItem 绘制墙地与家具，使用同一固定正视投影；Vector3 只表达计算坐标，没有 Node3D、Camera3D、完整 3D 场景或第三方依赖。

家具几何拆为有限盒体，桌腿和床脚保持空隙；侧/顶面按盒体前后边界和标记所在深度切片，从远到近绘制，不依赖整件家具单一 Y-sort。拾取反向检查实际投影多边形，遮住的物体不穿透响应。家具换位后重建绘制和点击区域；取景/空间变化使旧按下无效，任意释放均清除按下状态。审查中补充了“拖离取消后重复释放”和“家具按下跨方向变化”的保障。

操作：从地图点击宿舍；点家具显示名称/深度；“书桌换位”在两个合法槽位切换；“标记换点”循环六处，“标记前后”按 0.35m 步长往返。移动接口拒绝越界和家具占地交叉。标记可以穿过实体用于观察遮挡，不包含移动碰撞、寻路或猫咪状态。

PC 默认整体取景、九列控件；手机默认书桌聚焦、三列控件，床/书桌/衣柜按钮可直接切换，也可受约束横移，“全景”明确恢复。所有取景使用同一世界数据、水平视轴和等比投影。返回按钮、Escape 和系统返回语义仍由既有导航处理；保留 BuildingDefinition、宿舍建筑 ID、BuildingRoom 返回/交互接口、地图实例与焦点。未改学校、锁定商店或导航脚本。

## 4. 实际测试与证据

测试运行于本机 Windows 桌面，实际日志后端为 OpenGL 3.3 Compatibility，GPU 为 NVIDIA GeForce RTX 3070 Laptop GPU；此处未做性能基准。全部五种要求尺寸均实际设置窗口并核对；Rendered 模式另外检查截图实际像素尺寸。所有输入均为通过 Godot 事件管线注入的合成输入，不是人手点击或真机触摸。旧测试未删除或降低断言，原测试文件和稳定性脚本未修改。

| 最终测试 | 实际结果 | 原始证据目录（项目相对路径） |
|---|---|---|
| 既有 Headless 回归 | **254 通过 / 0 失败** | `docs/evidence/p0-03/07_final_integration_headless/` |
| 既有 Windows Rendered | **268 通过 / 0 失败** | `docs/evidence/p0-03/04_integration_rendered/`；最终代码另见下面连续轮次 |
| 最终既有 Rendered 连续五轮 | **五轮各 268 通过 / 0 失败**，全部退出码 0、引擎日志干净 | `docs/evidence/p0-03/08_final_stability/results.json` |
| 新空间 Headless | **208 通过 / 0 失败** | `docs/evidence/p0-03/05_final_spatial_headless/` |
| 新空间 Windows Rendered | **237 通过 / 0 失败**，20 张真实截图 | `docs/evidence/p0-03/06_final_spatial_rendered/` |

空间测试覆盖：主入口加载、三件家具各尺寸下可见/鼠标/单次合成触摸、全景返回与平移、桌腿空隙、床前/床后/局部遮挡、书桌前后换位与床体投影重叠、拒绝非法摆放、标记跨深度边界、方向/模拟安全区变化保持状态、取消旧按下、返回地图焦点及八轮重入无室内节点残留。既有回归覆盖学校、锁定商店、错误目的场景和导航防抖、反复进出、尺寸变化期间输入与系统返回。

独立深度校验从视点逆投影射线，与世界轴对齐盒求交，不读取绘制排序；27 个场景累计 **43,092** 个采样射线，拾取结果无不一致。Windows 另在其中关键场景从真实渲染图读取 **746** 个家具/标记内部像素，与独立深度归属一致；避开边缘采样，未穷举每一像素。标记圆头用近似圆与保守边缘排除，不能将该采样当成任意几何排序的数学证明。九个床深度边界状态另作明确断言，三处保存截图。

复测命令（证据目录须选择未存在的新路径，连续测试首个失败会停止）：

```powershell
./tests/run.ps1 -EvidenceDir docs/evidence/自选_既有无窗口
./tests/run.ps1 -Rendered -EvidenceDir docs/evidence/自选_既有渲染
./tests/stability.ps1 -Rounds 5 -EvidenceRoot docs/evidence/自选_连续五轮
./tests/dormitory.ps1 -EvidenceDir docs/evidence/自选_空间无窗口
./tests/dormitory.ps1 -Rendered -EvidenceDir docs/evidence/自选_空间渲染
```

初次验证和最终验证按不同目录保留；`00_baseline_headless`、`01_integration_headless`、`02_spatial_headless`、`03_spatial_rendered` 为较早轮次，不用其结果替换最终轮次。控制台文本、引擎 import/runtime log、JSON 与 PNG 均在 `docs/evidence/p0-03/`。汇总检查本阶段 26 份引擎日志，`ERROR:` / `SCRIPT ERROR` / `FAIL:` / `TIMEOUT` 命中 0 条；原生 UI 工具初始化失败单独记录，不隐藏为“全部环境通过”。

原生可视化操作尝试使用 [computer-use 技能](C:/Users/yyy/.codex/plugins/cache/openai-bundled/computer-use/26.1021.31345/skills/computer-use/SKILL.md)，初始化即报 `windows sandbox failed: helper_unknown_error: setup refresh had errors`，未执行原生 UI 点击。记录在 `docs/evidence/p0-03/native_ui_attempt.txt`。这是工具环境失败，不是游戏测试失败或自动审批拒绝；本报告仅提供引擎实际截图、图片审看及合成 GUI 证据。负责人仍需直接运行试玩。

本轮没有 Android 真机/模拟器或 Apple 主机，**未验证 Android/iOS 实机触摸、安全区、生命周期、macOS 运行或移动性能/发热**。未重新构建 P0-03 EXE/APK；P0-02 构建结果不能代表新增宿舍已完成跨平台包验收。

## 5. 十项技术评估

| 任务书问题 | 基于本轮结果的回答 |
|---|---|
| 1. 正视广角空间感是否初步成立？ | 初步成立：PC 实图能见两侧墙、后墙、深度地格和前后家具，镜头基本水平正对房间；是否符合期望的“真实房间”观感由负责人定。 |
| 2. 当前 2D 分层是否足够？ | 对三个固定镜头几何样例与两个合法换位槽位足够，射线与真实像素支持此结论；未证明可处理所有室内布局。 |
| 3. 墙地家具透视是否协调？ | 实图中统一投影与交界线一致，床/桌顶面、高柜侧面保持同视轴；正式插画尚未试制，风格融合未验证。 |
| 4. 家具遮挡主要限制？ | 轴对齐盒和局部切片，拒绝实体相交；旋转、复杂曲面、动画互穿、多层透明和可转动镜头尚未验证。家具内切片过多也可能增加维护及重建成本。 |
| 5. 家具移动是否有高维护成本？ | 当前两个槽位切换只改位置并重建，可维护；任意摆放/旋转及正式贴图切层需要额外规则和测试，不能沿用此低成本估计。 |
| 6. 手机是否需要专门取景？ | 需要。360×780 全景图家具过小；默认聚焦、直接切换和横移可操作，但取景操作负担与细桌腿触摸精度尚待真人/真机验证。 |
| 7. 能否支持未来猫咪藏身与互动？ | 已证明薄标记前后、桌下空隙和可见面点击有基础；真实猫的尺寸、姿态、肢体分层与藏点行为没有实验，不能据此宣称猫咪系统可交付。 |
| 8. 是否足以要求局部 3D？ | 当前没有已复现且必须用 3D 的故障，不建议仅因广角改完整 3D。若明确需要旋转家具、复杂藏身姿态或切层成本过高，可在新授权下比较一个局部 3D 样例。 |
| 9. 正式美术主要约束？ | 共用视点/眼高/尺度与地面锚点；为桌腿空隙、床面/前挡、高柜前侧面准备匹配遮挡层/遮罩。家具独立场景与几何合同可替换，但任意整张插画不能直接获得遮挡；贴图生产与移动包体成本未测。 |
| 10. 负责人需决定什么？ | 是否保留正视广角；房间宽深比、眼高与家具大小是否合适；手机默认聚焦还是先全景；直接聚焦/横移是否足够；正式美术能否接受分层约束；被挡标记/未来物体是否应增加提示。 |

## 6. 文件变更与风险

| 新增/修改 | 文件及职责 |
|---|---|
| 新增 | `scripts/dormitory/dormitory.gd`、`furniture.gd`、`room_world.gd`、`room_view.gd` 及四个 `.uid`：局部 UI、家具合同、状态、2D 投影/切片/拾取。 |
| 新增 | `scenes/dormitory/bed.tscn`、`desk.tscn`、`wardrobe.tscn`：三件可分别替换的几何样例。 |
| 修改 | `scenes/buildings/dormitory.tscn`：稳定路径与 BuildingRoom 语义保留，挂接新宿舍脚本。 |
| 新增 | `tests/dormitory_tests.gd`、对应 `.uid`、`tests/dormitory.ps1`：独立空间测试及证据执行器。 |
| 新增 | `docs/tasks/P0-03_TASK.md`（本轮正式任务原文）、ADR 0003、本报告及 `docs/evidence/p0-03/` 原始证据。 |
| 修改 | `AGENTS.md`、`README.md`、`docs/TECH_BASELINE.md`、`docs/RISK_REGISTER.md`：当前授权范围、操作/复测、原型边界与风险。 |

地图/学校/商店实现、BuildingDefinition、输入配置、全局布局与既有测试均无修改。引擎、语言和主代码库保持不变。DEMO/正式内容仍共用工程，未来依显式资源清单隔离；本轮不增加正式内容。没有制作正式美术、家具装修、猫咪、任务、剧情、经济、存档或联网系统，也没有建立通用家具/深度管理框架。

尚存问题：竖屏全景太小、聚焦默认会裁切部分家具；细家具表面未保证 48 单位触摸宽度，只保证底部取景与测试按钮至少 48；实际手指精度和操作体验待确认。测试仅抽样验证有限状态，复杂形状和移动性能需后续单独实验。原型暂无发布级验证，不建议据此启动正式房间资源量产。

## 7. Git 与停止点

P0-03 本地实现提交：提交后登记。只建立本地提交；不创建远程、不推送。缓存、便携引擎/下载、SDK、调试密钥及构建文件由现有 `.gitignore` 排除，脚本 UID 和技术证据纳入版本。提交前核查 715 个 Git 候选文件，禁止路径/产物与常见私钥令牌模式命中均为 0，8 项忽略规则探针全部命中；这不是穷尽式安全保证。源码与测试的 18 项 SHA-256 记录于 `docs/evidence/p0-03/final_repository_audit.json`，便于核对实际被测版本；其中哈希基于本机原始文件字节，Git 源码文本入库按既有 LF 规则规范化。

建议负责人先比较第 2 节 PC、手机全景/聚焦和换位截图，并本机从主地图进入宿舍试玩，再决定是否保留镜头和手机取景。未来若另获授权，优先小规模正式美术切层样例与目标手机验证，再决定复杂角色或局部 3D 是否必要；这些均未在本轮自动开始。
