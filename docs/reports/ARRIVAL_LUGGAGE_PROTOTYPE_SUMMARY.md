# 初到俄罗斯 · 行李整理机制一 DEV 原型交付

日期：2026-10-29。状态：**可独立试玩，等待负责人真人判断；没有宣布玩法合格或决定保留。**

负责人回复“1”后，本轮只实施已选的“长短成序＋共边对齐”。机制二、其他场景、随机题库和正式 Q02 接入均未实施。首次原型交付后停止；负责人可决定保留、明确一个局部问题并允许最多一轮针对性调整，或删除。当前负责人试玩后的调整轮数为 **0**。

## 先试玩

直接双击项目根目录 **`行李整理原型DEV.cmd`**，即可进入实验。它使用独立启动沙盒 `E:\俄语游戏\NEXT_STOP_RUSSIA\.local-dev\prototype-data\arrival-luggage`，不沿用原 PLAYTEST 玩家目录。

也可双击 `开发DEV.cmd` → 地图“模块” → **“实验 · 行李整理”**。该入口不会切换会话或档位；退出后恢复打开前的菜单／场景。

- 按住鼠标或单指拖动物品；轻点选中后点“转向”，PC 也可按 R。
- 可撤销、重来同一初始局面、主动查看线索。完成由实际空间关系自动识别，不按容量或固定答案点判题。
- 完成后桌面留在原处，可继续调整或退出。Esc／退出关闭实验；没有计时、扣分、评分、奖励或主线事件。

四件物品为护照、教材、折好围巾和洗漱包。只用一块摆放面、一个固定初始局面；没有 A/B/C 箱体或选仓操作。不要把本轮程序化表现视为正式美术定稿。

独立 Windows DEV 构建也已更新：`builds/modes/dev/NextStopRussia-DEV.exe`，进入地图“模块”菜单使用同一实验入口；配套 PCK 须同目录。直接启动实验可给该 DEV 程序传 `-- --luggage-prototype`，数据根目录仍按现有 NSR_DATA_ROOT／EXE 旁 player-data 规则解析；上述根目录快捷入口额外使用专门沙盒，推荐负责人从快捷入口试玩。

## 实现范围

`scripts/dev_tools/luggage_tidy/model.gd` 只保存内存坐标、朝向与撤销历史。根据真实宽高判断同向、长短顺序、任一共同边和合理间距，支持递增／递减、顶齐／底齐以及换轴摆放；不保存完整答案坐标表。允许中间临时叠放，越出摆放面则回原处，最终完成必须不遮叠。

`view.gd` 提供直接抓取、抬起阴影、附近边缘导线与吸附、90° 转向、落下、固定重来及完成停留。吸附候选基于原始指针位置计算，每轴只取最近一次修正，不能链式跳到远处。完成静止约 0.3 秒后亮起并生成短完成声。部分物件拿起时短显俄中词，松手淡出；洗漱包先用中文，未随意补未审词条。

手机为上下布局，PC 为侧栏与完整摆放面；物件按一致比例显示，点击区独立扩到至少 48 像素。窗口变化取消手势，不提交旧坐标。转向当前为即时 90° 原型反馈，尚未制作精细动画；真实手感及声音是否舒服均待负责人体验。

## 正式流程与存档隔离

- 原型不创建 P1Session，不调用原 Q02 判题、任务推进、奖励、保存或档位选择 API；几何模型／表现代码中没有文件访问。
- 打开时保存父场景原处理模式和焦点，暂停下层输入／处理；关闭及退出树时恢复此前状态。正在切换场景时拒绝打开，防止已排队的正式场景回调混入。
- 工程检查覆盖原型打开、拖放、完成、重来、退出前后的内存任务状态、原存档哈希及 selected_profile 状态；还覆盖运行中的猫场景暂停与恢复原处理标志。
- `scripts/main.gd`、`scripts/p1/`、正式 `data/`、`scenes/`、`ui/`、`project.godot` 与原 AI PNG 均与设计确认前基线一致。没有替换、删除或改写正式 Q02，也没有更改 Q00／Q01／Q03 的流程依赖或存档 schema。
- 实验脚本位于原本从 PLAYTEST／RELEASE 排除的 DEV 工具目录。实际 PCK 审计确认只有 DEV 包含新原型，非 DEV 对 `--luggage-prototype` 不启用实验。

## 表现资源来源与保留状态

本轮没有下载参考游戏素材、生成新 AI 图片或复制参考作关卡／UI。四物品与布垫均为同视角的原创程序化绘制，反馈声为原创程序化 WAV。统一登记新增六项，全部 **PROJECT_ORIGINAL / REVIEW_REQUIRED**，`permanentApproval=false`，只用于 `DEV_LUGGAGE_EXPERIMENT`；没有声称最终批准或必须永久保留。

| assetId | 路径／绑定 | 实际形态 |
| --- | --- | --- |
| `prototype.arrival_luggage.passport` | `scripts/dev_tools/luggage_tidy/view.gd`／`_draw_item/passport` | 90×135 逻辑轮廓 |
| `prototype.arrival_luggage.washbag` | 同文件／`_draw_item/washbag` | 125×190 逻辑轮廓 |
| `prototype.arrival_luggage.textbook` | 同文件／`_draw_item/textbook` | 150×220 逻辑轮廓 |
| `prototype.arrival_luggage.scarf` | 同文件／`_draw_item/scarf` | 95×280 逻辑轮廓 |
| `prototype.arrival_luggage.surface` | 同文件／`_draw` | 600×600 逻辑摆放面 |
| `prototype.arrival_luggage.feedback` | 同文件／`_tone`、`_process` | 运行时声音与轻亮起 |

以上不是 PNG，不虚报像素尺寸或文件 alpha；锚点和图层按程序化逻辑单位登记。`assets/art_registry.json` 原有 37 条逐项保持，旧素材来源／保留状态没有被本轮重标。

## 工程检查与真实画面

以下只证明原型可运行及隔离，不代表好玩或已通过负责人验收。

| 实际检查 | 结果 | 原始证据（项目内） |
| --- | --- | --- |
| 首轮内存几何与真实输入、退出隔离（Headless） | 48／0 | `docs/evidence/arrival-luggage-prototype/headless-02/` |
| 最终 PC 鼠标、转向、吸附、越界、撤销／重来、完成与退出 | 57／0 | `pc-final-07/` |
| 最终模拟手机单指触摸及上述流程 | 57／0 | `phone-final-08/` |
| 完整有效样本的链式吸附边界定向复核（Headless） | 53／0 | `final-headless-09/` |
| 原有 DEV 五模块重复进入、Q03 解锁、模式／保存回归（Headless） | 86／0 | `formal-modules-11/` |
| DEV／PLAYTEST／RELEASE 实际 Windows 启动、正常退出、包内隔离和常规保存哈希 | 三模式 PASS | `windows-final-10/` |
| 正式代码／数据／旧美术未变与新登记限定 DEV 的审计 | PASS | `scope-audit-12/scope_audit.json` |

除首行完整路径外，表中目录均在 `docs/evidence/arrival-luggage-prototype/` 下。工程测试验证了至少两种不同位置／相反书序的解及整体换轴解；真实交互走完一种可完成摆法。初轮 PC／手机记录仍保留在 `pc-03/`、`phone-04/`。源场景没有引入测试解法按钮。

实际 Godot 初始画面：[PC 横屏](../evidence/arrival-luggage-prototype/pc-final-07/01_initial.png)、[模拟手机竖屏](../evidence/arrival-luggage-prototype/phone-final-08/01_initial.png)。拖动及完成画面在同目录 `02_dragging_passport.png`、`03_complete.png`。这些是实际渲染，不是 AI 概念图。

首轮审查发现吸附候选可能连续累加，已按原始位置取最近候选修正并增加定向回归；入口也增加场景切换保护。均属首个交付前的工程修正，不代表负责人试玩后的针对性调整已开始。

打包时发现旧 `builds/` 下的保存路径被导出器纳入，早期记录在 `windows-05/` 保留。现已对所有导出预设排除 `builds/*,build/*,dist/*`；清理后的构建检查在 `windows-clean-06/`，最终源码构建为 `windows-final-10/`。最终三个包均确认无这些构建／玩家目录；没有删除或修改旧保存文件，早期包不作为本次交付。导出修正是数据隔离保护，不改变正式玩法。

## 未验收事项、Git 与停止点

负责人真人试玩尚未执行；真实手机、Android 系统返回、Apple 平台、声音主观质量和反复玩的意愿未验证。历史 P0 偶发合成触摸风险继续保留，不因本轮模拟触摸通过宣称根因修复。四件排序是否太简单、是否真的有“收好”的满足感，留给负责人判断；不靠追加物品、关卡、美术或统计挽救。

分支 `codex/arrival-luggage-prototype`；设计确认前基线 `eede196`；实现提交 **`d2007bb569a1fd340c684d8c94fb17bfa572fe5c`**。本报告和原始证据随后单独归档提交，可用 `git log -2 --oneline` 查验。仅本地提交，不推送远程；旧未跟踪 `docs/evidence/p1-01/` 与被暂停书桌草稿的证据原样保留，不宣称工作区完全干净。

**现在停止，等待负责人试玩。** 若决定保留，正式接入另行确认；若只有明确局部问题，最多一轮针对性调整；若不合适则停止整理玩法开发，并在负责人明确删除决定之后才提出正式 Q02／Q03 依赖与旧档兼容清理方案。当前不删除旧 Q02，不自动尝试机制二，不开始下一阶段。
