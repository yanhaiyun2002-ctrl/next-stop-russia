# P1-01R｜临时美术准备汇总

日期：2026-10-29。状态：**候选与最小工作流已准备，全部 REVIEW_PENDING，等待负责人确认**。本轮没有下载第三方素材包、替换 Godot 场景、修改玩法/台词/剧情进度/存档结构，也没有实施地图入口或拖放整改；这些仍属于 P1-01R 后续实施。

## 1. 建议先确认什么

推荐顺序：**整理四物品＋三仓位 → 开场背景与两位 NPC → 宿舍同透视分层素材**。

- 整理：优先围绕现有 `textbook/passport/scarf/washbag` 原创一小组统一图形，UI 可选 Kenney 基础件。当前没有核实到同时覆盖这四物品、又适合本项目的完整免费套装；不以不相干的 RPG 物品替换题目。
- 剧情：原创少量环境图＋独立人物最符合故事；若先压低制作成本，可选 Open Peeps 的可改人物占位。人物外观与正式形象均待确认。
- 宿舍：先确认近正视、略高视点及表面标签方案，再生产床/桌/柜/窗与猫。没有找到可直接无缝替换当前投影的免费完整宿舍 PNG 套件；不拼接俯视/等距家具，不为素材改引擎。

请负责人确认：①整理图形方向与物品托盘/收纳区分布；②剧情采用原创人物候选还是免费线稿占位；③宿舍视点、画面范围与标签附着表面。**确认其中一项不代表其余模块或正式画风已批准。** 本轮不依据未回复自动接入。

## 2. 本机生成能力与项目 Skill

实际检查到官方 `C:\Users\yyy\.codex\skills\.system\imagegen\SKILL.md` 和内置 `image_gen.imagegen`，且已成功调用。使用官方 Skill 默认内置路径，**未使用 CLI/API fallback，未配置密钥、购买服务或安装替代生成工具**。工具未公开本次具体模型标识，因此不猜测模型版本或价格。

本轮共 **3 次新图生成＋2 次针对性纠错编辑**，最终保留三张候选，没有批量制作素材。首版整理图误加列车/莫斯科风格地标，首版宿舍图也误加外部地标；均在单次编辑中移除，未将地理错误当成设计决定。被舍弃的初版仍留工具默认目录，未自动删除。

内置工具实际先写入 `C:\Users\yyy\.codex\generated_images\01a183bb-5cde-7040-9648-1da9ff19faa0\`。选中的三张已**原样复制**到 E 盘 `docs/art-prep/p1-01r/`，没有搬迁 CODEX_HOME、认证、全局配置或改变系统环境。不是零 C 盘写入；E 盘这三张合计 **5712739 bytes**，C 盘还保留生成原件及舍弃版本。

适合建立项目级 Skill：本项目反复需要“候选筛选→许可核验→少量预览→确认→分层交接”，已有明确的稳定 ID 与 TEMP 规范，无需新框架。已建立：

`.agents/skills/game-art-pipeline/SKILL.md`

仅一个自包含 Skill：列出适用边界、候选状态、官方生成工具选择、来源核验、透视一致性、E 盘路径、PNG/锚点/遮挡合同和实际接入后的检查。未加插件、自动化编排、全局配置或自制生成 SDK。项目级放置适合仓库协作；**本轮未验证 Codex 重启后是否自动发现该 Skill**，必要时后续可显式指明此文件。

## 3. 免费资源候选与授权核验

核验范围是 **2026-10-29 作者/官方发布页与其许可说明**，没有下载 ZIP/7z，因此“页面已核验”不等于“包内逐文件许可/透明度已核验”。价格为该页面当次可免费获取的档位；不点付款或捐款。使用前仍需保留下载版本的 LICENSE、文件哈希与衍生修改记录。

CC0 的修改、商用及无需许可条件，依据 [CC0 官方说明](https://creativecommons.org/publicdomain/zero/1.0/)；CC BY 3.0 需要署名、许可链接与衍生修改说明，依据 [CC BY 3.0 官方说明](https://creativecommons.org/licenses/by/3.0/)。这些许可不等于本项目画风批准。

| 候选、作者与来源 | 免费档/许可证；署名；修改 | 格式与透视 | 适用性与本轮决定 |
|---|---|---|---|
| **Kenney UI Pack**；Kenney；[官方素材页](https://kenney.nl/assets/ui-pack)、[官方 FAQ](https://kenney.nl/support) | 独立包可免费获取；CC0；不强制署名；允许修改。只考虑素材，不使用 Kenney 品牌 Logo。 | 官方页列 2D UI、按钮/面板/滑条；**该页未列包内编码，PNG/九宫格边距须下载后核对**。平面 UI，不受宿舍相机约束。 | **优先 UI 候选**：收纳边框、拖动高亮、按钮、对话框。不能代替四件物品或俄中字库，不据此新增经济/血条系统。 |
| **Game-icons 单件组合**；Passport/Gym bag：Delapouite；Book cover：Lorc；[护照](https://game-icons.net/1x1/delapouite/passport.html)、[书封](https://game-icons.net/1x1/lorc/book-cover.html)、[运动包](https://game-icons.net/1x1/delapouite/gym-bag.html)、[作者/使用说明](https://game-icons.net/about.html) | 免费；CC BY 3.0；**要署名作者及来源/许可，记录改色或改形**；允许修改。 | 页面明确 SVG、PNG，提供透明底选项；二维单色符号，非房间家具透视。 | **物品低成本备选**，同一图标体系可统一描边/配色。尚缺已核验围巾；运动包不是洗漱包，需批准后改绘，不能直接冒充完整套装。书封与护照须测试小尺寸辨识。 |
| **Skymon Icon Pack Free**；Deface Games；[OpenGameArt 作者页](https://opengameart.org/content/skymon-icon-pack-free) | 免费版本明确 CC0；不要求署名、作者欢迎署名；允许修改。区分免费与 premium。 | 页面明确白色 PNG、512×512、有留白；二维图标；手绘符号体系。 | **UI 符号备选**，适合撤销/帮助等选件。偏 RPG/中世纪标签；没有核实其包含全部现代行李物品，不将“200+”等同需求覆盖。 |
| **Open Peeps**；Pablo Stanley；[官方页](https://www.openpeeps.com/) | CC0，免费个人/商业使用；不强制署名；允许组合/修改。 | 官方单件可取 PNG、SVG；前视/轻侧视人物与半身像。单件 alpha、裁边及具体形象仍需实际检查。 | **剧情人物备选**：安娜/管理员可替换半身占位；不当作两人已批准形象。黑白线稿与本轮彩色候选不是同套风格，不能直接混搭视为统一成品。无圣彼得堡背景。 |
| **Critters - Pixel UI**；绘制 David（chroma_dave）、发行 Foozle；[itch.io 作者页](https://foozlecc.itch.io/critters-pixel-ui) | Name your own price 的免费档；CC0；不要求署名；明确可改、可商用。 | 官方说明像素 UI/背包界面及 `.ase` 源文件；ZIP 3.1 MB；PNG 编码/单件切片未解包核验。平面像素 UI。 | **统一像素方向的备选**，不是当前非像素插画方案的直接补丁。若负责人选择这条路线，应整体统一 UI；不引入其生命/体力/经验等玩法。 |
| **Simple Game GUI**；coolgameart；[itch.io 作者页](https://coolgameart.itch.io/simple-game-gui) | 免费下载；页面 metadata 写 CC0，正文又写禁止再分发/分享，**互相冲突**。正文允许修改；署名要求未写清。 | 作者说明 PNG，7z 2.5 MB；平面按钮、空/满物品格、面板。 | **LICENSE_REVIEW_PENDING，不集成**。需作者澄清再分发是否包含游戏/源码交付、实际适用许可证和署名；不能只看 CC0 标签判通过。 |
| **Hand drawn dungeon icon pack**；Limofeus；[itch.io 作者页](https://limofeus.itch.io/handdrawniconpack) | 页面明确图标 CC0，可改、署名非必需；支持者源文件另有说明，不扩大解释。 | 页面描述 1024×1024 黑白/透明版本；主图标 ZIP 124 MB；PNG 等实际编码未解包核验。平面手绘地图/符号。 | **低优先级候选**，可看 UI 符号方向，题材偏地下城，未核实完整四物品。本轮不下载 124 MB 或 661 MB 支持者包。 |
| **Sprout Lands - UI Pack Basic**；Cup Nooble；[itch.io 作者许可](https://cupnooble.itch.io/sprout-lands-ui-pack) | 免费版**仅限非商业**、允许改，禁止再分发；页面请求署名 Cup Nooble。商业许可属于付费 premium，不属于本轮免费候选。 | 像素 sprites/表情/UI；Basic ZIP 140 kB，具体编码未核；平面 UI。 | **排除工程候选**，不因 DEMO 暂未收费就推定满足后续商业目标，也不购买升级。其猫形象不替代西伯利亚森林猫。 |
| **Furniture Kit**；Kenney；[官方页](https://kenney.nl/assets/furniture-kit) | 免费单包，CC0；不强制署名；允许修改。 | 官方明确 **3D**、140 项；具体模型格式未下载核验，不是可直接用的同投影分层 PNG。 | **本轮不推荐宿舍直接接入**。相机/离线渲染/分层工作尚未做，不能拿等距预览截图拼当前宿舍，更不为此切成 3D 引擎方案。 |

推荐的含义是“值得负责人挑选、下一步逐件核查”，**没有任何第三方资源被标为可直接集成**。候选页面 URL 即本轮外部预览入口；未复制其素材到项目、未重新分发作者预览图。当前最小原创方向与资源库备选应择一统一，不把每套的元素全部拼到同一画面。

## 4. 三张原创视觉候选

原始生成、纠错 prompt 和精确工具输出路径全部保存在 `docs/art-prep/p1-01r/prompts.json`；文件尺寸/哈希/来源/状态在 `candidate_manifest.json`。生成器没有接收宿舍参考图作为图像输入，仅依据文字空间约束作全新候选。三图都标 `CANDIDATE / TEMP_REPLACE_REQUIRED`，并非实际运行截图、最终角色设计或画风批准。

### A. 整理候选｜最高优先级

![整理视觉候选](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/art-prep/p1-01r/candidate_organization_v02.png)

四件物品保持共同图形语言，收纳区用 2＋2＋1 可见格位，表达拖动预览和手机点选替代操作。PC 意图是物品托盘在左、收纳区居中、操作在下；手机是收纳在上、物品托盘在下、底部操作。

**待修/待确认：** PC 的 A 标签仍漏绘，重置/返回与容量反馈也没有完整表现；图片中的书和拖动半透明副本不是第五个物品。三仓位用箱体表现只是容器视觉候选，不能改变源题目的区域或规则。不能从这张图推定拖放、吸附或非法反馈已经实现。

### B. Q00 剧情候选

![开场剧情视觉候选](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/art-prep/p1-01r/candidate_story_v01.png)

画面体现抵达城市、安娜交流、管理员交钥匙及门口过渡；给俄语主字幕和中文辅字幕分别留空区域。没有新增剧情/第三位正式 NPC，也没有把现有台词画进图片。

**待确认：** 两人脸型、发型、衣着、表情和场景都只是候选；城市轮廓是生成的氛围示意，不是准确地理复原。后续应交付独立背景与透明人物，不把整张拼板塞进过场。

### C. 宿舍与标签候选

![宿舍视觉候选](E:/俄语游戏/NEXT_STOP_RUSSIA/docs/art-prep/p1-01r/candidate_dormitory_v02.png)

表现近正视略高视点、可见床/桌表面、前景行李/地毯、家具纵深，以及床前板/桌前沿/柜门/窗框上的标签位置；猫头线索避开标签。手机示意同一房间的局部横向浏览，非整房拉伸。

**待确认：** 此图比整理/剧情候选更接近写实渲染，三张不是已统一的最终风格；光照、纹样、颜色、房间宽深、家具布置、猫造型均不能据此锁定。后续还需补独立层、接地点、四藏点可发现性，以及实际 48 逻辑单位的标签点击区。图中文字只表达附着意图，工程应使用真实文字控件。

**文件实测共同限制：** 三张均为 **1536×1024、RGB、无 alpha** 的平面概念拼板。内含横/竖构图研究，但屏幕外框不严格等于 1280×720 和 360×780，不能据此验收目标比例/按钮尺寸。负责人选方向后，才制作精确目标比例布局和独立 RGBA 图层；本轮没有把概念图伪装成可直接导入的透明素材。

## 5. 后续 Godot 资源合同（提案，尚未生产）

统一建议：独立 PNG、sRGB、RGBA8；透明物体有真实 alpha，背景可 alpha=255；保留可编辑源和许可文件。下列尺寸是**建议母版**，经布局确认再固定，不意味着新任务规则或屏幕硬编码。PC 以 1280×720、手机以 360×780 逻辑布局独立构图，实际输出可分别 1920×1080 与 1080×2340，不能简单拉伸。

| 模块/独立 assetId 示例 | 建议尺寸与锚点 | 图层、交互与现有 ID |
|---|---|---|
| `temp.p1r.organize.item.textbook` | 512×256 透明母版，中心锚点 (0.5,0.5)；视觉占 2 单位 | 图标与阴影可分层，语义仍是 `textbook.size=2`，不新增旋转/二维格坐标存档。 |
| `temp.p1r.organize.item.passport/scarf/washbag`（三个文件） | 各 256×256，中心锚点；各 1 单位 | 透明底、共同光线/描边/留白；护照不含真实证件信息。名称和占用提示由现有数据绘制。 |
| `temp.p1r.organize.bin.a/b/c`（分别导出） | 如 384×256 可伸缩边框母版；左上 UI 锚点，九宫格边距在 metadata 记录 | 边框/底板/目标预览分层；容量 **2/2/1** 由现有题目数据驱动，不把容量数字烘焙进图。 |
| `temp.p1r.ui.drag_preview`、按钮状态 | 小型独立 PNG/九宫格；中心或控件锚点 | 选中/可放/不可放视觉分开。最终点击区由 Control 矩形管理，不以透明像素定义，目标至少 48 逻辑单位；不增加颜色分类规则。 |
| `temp.p1r.story.bg.arrival/reception`（两个背景） | PC 1920×1080；手机独立构图或经批准的裁切规则；背景锚点与安全裁切记录 | 背景/前景遮罩分离；不画字幕和按钮；相同 `dialogueId`、speakerId 与台词不变。 |
| `temp.p1r.story.anna/admin`（两个角色） | 如 768×1024 RGBA，人物底部接地点约 (0.5,0.95)，按实图记录 | 半身/表情层可替换；不命名为最终角色稿，不因替图增加剧情。 |
| `temp.p1r.home.bed/desk/wardrobe/window` | 待批准相机定大小，建议单件最长边 1024～1536；接地点/窗构件基准点 | base/back/front_occluder 独立 PNG，共用画布、比例与世界锚点；绑定现有 `bed/desk/wardrobe/window`，不按固定屏幕像素摆藏点。 |
| `temp.p1r.cat.siberian` | 如 512×512 RGBA，地面接触点约 (0.5,0.92)，逐帧一致 | 头/耳/身/尾或少量动作帧分离；保留已验证的运动路径与状态，不引入新宠物逻辑。 |

每件元数据最低包含：`assetId/revision/status=TEMP_REPLACE_REQUIRED/approval/sourceUrl/author/licenseNote/attribution/modification/commercialUse/pixelSize/alpha/anchorNormalized/layers/perspective/targetSlot/fileHash/permanentApproval=false`。未知项明确 `REVIEW_PENDING`，不伪造已批准值。

候选只在 `docs/art-prep/p1-01r/`，位于现有文档 `.gdignore` 范围。负责人选中并允许接入后，才复制独立素材到 E 盘 `assets/temp/p1-01r/<模块>/`，保留原资源版本和许可证；不把未审素材混入现有运行清单。家具标签/俄中字幕/容量数字必须继续用 Godot 控件，以便翻译与投影适配。

宿舍参考 `docs/references/dorm_layout_camera_reference.jfif` 已按实际 JPEG/JFIF 查看；本轮没有转换、描摹、提取其具体美术或传给生成器复刻。它不决定最终画风、家具造型或精确俯视角。

## 6. 实际核验、未测与文件变化

**已做：**

- 阅读官方 imagegen、skill-creator 与项目 TEMP/存储/协作要求；核对本轮 Git 基线 `78a792acf35f9942343e181cec23998ce9129d70`，保留原有未跟踪 `docs/evidence/p1-01/`。
- 浏览上述官方/作者页及 CC 许可页，记录免费/商业/修改/署名差异与冲突。未解包第三方资产，不假称已做包内审计。
- 内置生成实际成功；Pillow 对三张 E 盘候选进行了 PNG 解码、尺寸/模式/alpha 与 SHA256 检查，结果见 `candidate_manifest.json`。三张可读，但没有透明通道。
- **官方 `quick_validate.py` 尝试失败**：现有 Python 缺少 `yaml`（PyYAML），不是 Skill 已通过自动验证。没有为此安装依赖；另做 frontmatter/命名/链接/范围的本地结构检查，实际结果见 `docs/evidence/p1-art-prep/validation.json`。不把结构检查等同未来自动发现或实际调用验收。
- 确认本轮没有写入 `scripts/`、`scenes/`、`data/`、`ui/`、`project.godot`、存档或现有运行资源清单；检查记录同上。没有启动游戏，因此不宣称新增 Godot/拖放/平台测试通过。

**未测/待批：** 精确横竖屏布局、分层/真实 alpha 导出、第三方 ZIP 内许可与字体、Godot 接入、标签投影/遮挡、鼠标/触摸拖放、Windows 新包、真机与真人试玩。P0 历史偶发合成触摸风险仍保留，本轮没有尝试用环境调整宣称修复。

本轮新增文件仅：项目 `.agents/skills/game-art-pipeline/SKILL.md`；文档区三张 PNG、`prompts.json`、`candidate_manifest.json`；本汇总和核验日志。未批准/未生产任何“最终选中的工程素材”，所以不将候选放入 `assets/`。生成图片不自行标 CC0，也不声称 AI 输出拥有排他版权；正式分发仍应确认适用条款、内容与项目授权记录。

本轮只向主线交付本汇总，预览与证据从本文链接查看。**等待负责人选定方向与具体布局后，再在 P1-01R 授权内制作/接入必要临时资源；不进入 Q04/Q05。**
