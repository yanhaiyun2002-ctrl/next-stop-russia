# 正式产品流程与 P1-01 First Playable 切片

## 完整 V0.3 DEMO 序列（来源，不得换序）

| ID | 主线事件 | 完成判据 | 本期状态 |
|---|---|---|---|
| `q00_arrival` | 抵达圣彼得堡；安娜/宿舍管理员引导，交钥匙进入宿舍 | `story.home_entered`，已获得钥匙 | **P1-01 实施**（简化对白） |
| `q01_cat` | 初遇猫→四个候选藏点之一→俄语家具标签→走出→摸猫→必填命名 | `cat.name_confirmed`；首遇奖励仅在摸猫反馈完成之后发一次 | **P1-01 实施** |
| `q02_organize` | 独立整理入口→首次教程题（格位、容量、可解性） | `organization.tutorial_completed` | **P1-01 实施** |
| `q03_anna_message` | 安娜俄语消息＋中文字幕，城市开放 | `story.city_unlocked`，且 Q01 和 Q02 已完成 | **P1-01 实施** |
| `q04_visit_university` | 城市正式地图找到并进入大学 | `story.university_arrived` | 后续 P1-02 |
| `q05_collect_pack` | 大学交互领取报到资料、安娜后续信息 | `story.registration_pack_collected` | 后续 P1-02 |

**P1-01 成功的最低连续路径：** 从新游戏开始 → 安娜及管理员简化俄中对白 → 入宿舍 → 猫先出现后藏到四处之一 → 点对应俄语家具词 → 可见猫连续走出 → 玩家摸猫 → 首次奖励只记一次 → 玩家确认猫名字 → HUD 侧边整理 → 完成教程合法收纳 → 收到安娜消息 → 城市开放 → 可以继续自由玩找猫／从地图返回宿舍。游戏视觉全部仍可为 TEMP。

## 不得破坏的领域不变量

- `q01_cat.completed` ⇒ `firstPetCompleted=true` AND 非空 `cat.displayName` AND `catNamePending=false`。
- `story.city_unlocked` ⇒ `q01_cat.completed` AND `q02_organize.completed`。
- 摸猫前不授予首遇奖励；摸猫完成后奖励 **grantOnce**；从命名待确认状态退出再进入必须恢复命名且不重领奖。
- 反复找猫没有线性关卡，也不强制每局重命名；错误俄语标签不惩罚、不更换位置。
- 整理至少存在多约束合法判定，不要把 `verification.exampleSolution` 写死为唯一答案。
- 俄语 NPC 主字幕和中文字幕同显；地图语言模式不能关掉 NPC 中文字幕。
- DEV/PLAYTEST 数据目录隔离；DEV 可指定四藏点和 `catNamePending`；正常新档不能见测试入口。

## 内容来源及审批

- 原完整事件与脚本：`source_v03/01_MAIN_STORY_NPC_RU_ZH.md`。**行为合同 LOCKED，逐句对白 PROPOSED**。Codex 可以临时导入并标记 `TEMP_TEXT / REVIEW_PENDING`，严禁写入“终稿已审批”。
- 猫：`source_v03/02_CAT_R32_MANDATORY_NAMING.md`（完整状态机、奖励触发、恢复边界）。
- 整理：`source_v03/03_ORGANIZATION_REWARDS_JOURNAL.md` + `source_v03/organization_templates.v1.json`（带 1+5 候选题）以及可解性来源。P1-01 先教程，后续再接日期轮换。
- 词条：俄语家具名 `кровать` 床、`окно` 窗、`шкаф` 衣柜、`стол` 桌；`Где кот?`、`Вот кот!` 及位置短句仅做辅佐。
- 参考视频只作为**视觉观察资料**，不复制其像素、资产、游戏系统或代码；旧 WorkBuddy 全部排除。

## 游戏内容实施原则

剧情、语言、藏点及题目版本按 stable ID／结构化资源保存；不要求将原 TypeScript 接口逐字移植。首段实现仅需满足真实的状态恢复和可供其他模块调用的最小接口。引导可简短，但必须让用户清楚下一步，不允许靠 Codex 操作面板才能推进。
