# Codex 数据合同与模块边界（V0.3 草案；尚未授权编码）

**状态**：接口名称与字段是为了让 Codex 少猜测而拟定的 `PROPOSED` 合同；若用户确认，可转为接口冻结版。不可把下列 TypeScript 误认为已有源码。

## 1. 全局边界

- `StoryDirector` 监听领域事件，不向小游戏内部写判题代码。
- `MinigameHost` 只处理启动、暂停、退出、结算、回到来源场景；不同小游戏可有不同进度模型。
- `RoomObjectRegistry` 提供家具/构件与空间锚点；猫咪找藏点依据实际场景对象，不读取静态题卡坐标。
- `RewardService` 是贴纸、徽章、日期印章唯一发放入口，手账只读其结果。
- `LocalizationService` 将故事俄罗斯 NPC 的俄语＋中文字幕与地图中俄显示模式分开配置。
- `SaveRepository` 负责数据迁移、断点恢复以及 DEV/PLAYTEST 存档命名空间。

## 2. 建议核心接口

```ts
// 所有事件都要带 ID 以支持去重、QA 断言和调试复现。
type GameEvent = {
  eventId: string;       // UUID/单次事件稳定唯一标识
  type: string;          // 例如 cat.pet_reaction_completed
  occurredAt: string;    // ISO 时间；判每日事件另用本地 dayKey
  payload?: Record<string, unknown>;
};

type QuestId = 'q00_arrival'|'q01_cat'|'q02_organize'|
  'q03_anna_message'|'q04_visit_university'|'q05_collect_pack';
type QuestState = 'locked'|'active'|'completed';

type DialogueEntry = {
  id: string;
  speakerId: 'anna'|'dorm_admin'|'player_inner'|'system';
  ru?: string;
  zhSubtitle: string;
  voiceAssetId?: string;
  presentation: 'in_scene'|'message'|'tutorial'|'narration';
  blocking: boolean;
};

type LocalizedLabel = { zh: string; ru: string };
type MapLabelMode = 'both'|'zh'|'ru';

type RoomObject = {
  instanceId: string;
  definitionId: string;
  assetId: string;
  slotId?: string;      // 床、书桌、衣柜等必备家具锚点
  transform: {x: number; y: number; orientationId: string};
  interactionIds: string[];
};
type HidingSpot = {
  spotId: 'bed'|'window'|'wardrobe'|'desk'|string;
  roomObjectId: string;
  vocabId: string;
  labelAnchor: {x: number;y: number};
  hideAnchor: {x: number;y: number};
  clueAnchor: {x: number;y: number};
  exitWaypoints: Array<{x: number;y: number}>;
  foregroundOccluderId: string;
};

type MinigameOutcome = {
  gameId: string;
  sessionId: string;
  status: 'completed'|'exited'|'interrupted';
  mode: 'tutorial'|'daily'|'free_replay'|'first_meeting';
  events: GameEvent[];
};

type PuzzleRule =
  | {type:'fixedBin';itemId:string;binId:string}
  | {type:'allowedBins';itemId:string;binIds:string[]}
  | {type:'forbiddenTogether';itemIds:[string,string]};
type OrganizationTemplate = {
  schemaVersion: number;
  puzzleId: string;
  templateVersion: number;
  themeId: string;
  bins: Array<{id:string;capacity:number}>;
  items: Array<{id:string;size:number}>;
  rules: PuzzleRule[];
  hints: string[];
};

// 领域存档的最小必要字段；具体更细的 UI 快照可作版本化子文档。
type DemoSave = {
  saveVersion: number;
  saveId: string;
  questStates: Record<QuestId, QuestState>;
  hasHomeKey: boolean;
  cat: {
    petId: string;
    breedId: 'siberian_forest_cat';
    displayName: string|null;
    firstPetCompleted: boolean;
    namePending: boolean;
    replayUnlocked: boolean;
  };
  organization: {
    tutorialCompleted: boolean;
    dailyUnlocked: boolean;
    pinnedDay?: {dayKey:string;puzzleId:string;templateVersion:number;payload:OrganizationTemplate};
    completedDayKeys: string[];
  };
  cityUnlocked: boolean;
  registrationPackCollected: boolean;
  rewardKeysGranted: string[];
  stickerIds: string[];
  badgeIds: string[];
  learnedVocabIds: string[];
  journalStoryMilestoneIds: string[];
  outfit: {coatId:string;scarfId:string};
  settings: {mapLabelMode:MapLabelMode};
};
```

**技术补充**：`GameEvent` 可以采用唯一事件 ID 和 `RewardService` 的稳定业务 `rewardKey` 双层去重；前者用于防重复投递，后者用于奖励幂等。`String` 化后的猫名字作为普通文本渲染，不构造 HTML。`QuestState` 不允许与真实事件无对应地手动改变，除 DEV preset。

## 3. 事件词典与先后顺序

| 事件 | 触发者 | 允许的下一步 | 是否一次性 |
|---|---|---|---|
| `story.home_entered` | Prologue/Scene | 允许 Q01 | 首次里程碑 |
| `cat.correct_label_selected` | CatGame | 播放猫出场动画 | 每局可多次 |
| `cat.pet_reaction_completed` | CatGame | 发首次奖、设置 `namePending` | 每局一次，首遇奖唯一 |
| `cat.name_confirmed` | PetNaming | `q01_cat` 完成，允许 Q02 | 首次命名事件一次 |
| `organization.tutorial_completed` | OrganizationGame | Q02 完成，开启每日入口 | 一次 |
| `organization.daily_completed` | OrganizationGame | 记录日期、每日印章 | 每局可发事件，奖励按日唯一 |
| `story.city_unlocked` | StoryDirector | Q03 完成→进入城市 | 一次 |
| `story.university_arrived` | CityMap | Q04 完成→展示资料领取点 | 首次里程碑 |
| `story.registration_pack_collected` | SchoolPreview | Q05 完成、结束 DEMO 主线 | 一次 |

**硬不变量**：

1. `cityUnlocked ⇒ cat.displayName != null && cat.firstPetCompleted && organization.tutorialCompleted`。
2. `q01_cat=completed ⇒ cat.displayName != null && !cat.namePending && cat.firstPetCompleted`。
3. `cat.firstPetCompleted=false ⇒ 'cat_first_meeting_v1'` 不在 `rewardKeysGranted`。
4. `q02_organize=completed ⇒ organization.tutorialCompleted=true`。
5. `registrationPackCollected ⇒ cityUnlocked && q04_visit_university=completed`。
6. 一日一枚日常印章；同日多次完成允许 UI 成功提示但不增加奖励。
7. 装修素材更换不得更改 `roomObjectId/slotId/vocabId` 的逻辑对应关系。

## 4. 每日确定性选择

题库的 JSON 列出了 5 道日常题和一个入门题。`selectionPolicy` 提议通过种子、自然日和题库版本求散列并取模选题；但模板选择算法的具体跨平台字节序和顺序应在编码前固定，并写同日重复测试。**最重要的产品合同不是散列方法，而是首进入日后保存 `pinnedDay.payload`；同日绝不变题**。

## 5. 资源与本地化

- 资源清单：`assetId` 稳定，贴图路径、方向、世界锚点、图层与遮挡可单独更新；所有开发用非正式素材标记 `TEMP_REPLACE_REQUIRED`。
- 俄语学习词汇：`vocabId` 关联名词 `кровать`, `окно`, `шкаф`, `стол`；位置短句属于将来单独配置。
- 角色：仅 Anna 和宿舍管理员两名正式人类 NPC；宠物有独立 `petId` 和名字。
- 真实大学的地理位置作为锚点，不将真实大学全称显示为游戏建筑标题，使用「大学 / Университет」。

## 6. 预备工程目录（PROPOSED）

```text
src/core/{events,save,camera,asset-manifest}/
src/systems/{story,rewards,localization,room,pet,daily}/
src/minigames/{registry,cat-find,organization}/
src/scenes/{home,city-map,school-preview}/
src/ui/{dialogue,activities,journal,wardrobe}/
content/{story,npc,room,locations,minigames,localization}/
tests/{fixtures,unit,integration,e2e}/
```

所有内容配置应有一致的 ID 命名、静态验证和 SchemaVersion。该目录是交付建议，不代表已建仓或已有源码。
