# Ball Pit 项目 · 实现状态与架构总览

> 整理日期：2026-09-07
> 适用工程：Roblox Studio Place「cypress7988 的地方：09062026_1」（GameId 10765399872 / PlaceId 134117600138350）
> 说明：本文档汇总当前会话中所有已确认的需求澄清、已落地的模块、脚本位置、验证状态与后续待办，作为后续开发与交接的依据。

---

## 一、项目定位与文档体系

### 1.1 一句话定位
休闲解压 · 多人合作（当前实现为单人可玩）——玩家扮演波波池清洁员工，手持彩色收集工具（桶），把球池中 4 色波波球按颜色分类收集、存入背包、到对应颜色存放池倒球换取金币，金币跨局存档。

### 1.2 顶层规则（CLAUDE.md）
1. 先思考再编码：不假设、不隐藏困惑、暴露取舍；不确定就问。
2. 极简优先：最小代码解决，不做投机式扩展。
3. 外科手术式改动：只改必须改的，清理只属于自己的乱。
4. 目标驱动执行：把任务转成可验证目标，循环到验证通过。
5. **使用中文回答问题。**

### 1.3 工作区文档地图
```
D:\桌面\BallPit\ROBLOX_TEXT_PRJ\
├── CLAUDE.md                                  开发规则（五条）
├── Ball_Pit_策划案.md                         完整策划案（目标产品全貌）
├── Clean-All-the-Leaves-玩法与经济分析.md      对标产品分析
├── Ball_Pit_SKILL.md                          吸附收集玩法模板（服务器权威 Suction 架构参考）
├── 球池_项目结构分析.md                       玩法概述（较早版本）
├── SKILL.md                                   roblox-game 技能副本
├── Core gameplay system\
│   ├── Tool.md           工具系统需求（4色桶、单槽、纯E获取）
│   ├── Ball.md           收集球需求（用 SKILL 架构、BallPool、BallColorCollect）
│   ├── Bag.md            背包系统需求（统一背包、容量25、可扩展）
│   ├── BallPool.md       存放池需求（4色池、入库销毁、转金币）
│   └── Economic system.md 经济系统需求（1球=1金币、CoinText 实时显示）
├── Backpack System\Backpack System.md          （空，待规划）
└── roblox-game-skill\                        技能库
    ├── references\（16 篇技术参考）
    ├── templates\（game-scaffold + 6 品类）
    └── workflows\（7 个流程）
```

---

## 二、实现范围（MVP 边界）

已确定采用「先做单局可玩 MVP · 纯 Studio 内开发 · 本地单人优先」：

**本轮已实现**：工具装备（纯 E）→ 吸附收集 → 叠球 → 背包（25）→ 存放池倒球 → 金币（DataStore 存档）→ UI 显示 + 动效。

**明确后置（不在本轮）**：4 人联机协作、大厅/Teleport 多 Place、容量升级系统、任务/成就、赛季、正式存档会话锁（ProfileService 生产化）、总数校验逻辑、Backpack System。

---

## 三、工程架构总览（当前 Roblox 实例树）

### 3.1 场景（Workspace）
```
Workspace
├── Baseplate / SpawnLocation / Camera         默认元素
├── Map…（Zone1 / Zone2 / Zone3）              地图分区（占位，尚未接玩法判定）
├── Tool（Folder）                             4 色桶「切换站」（Model + model 网格 + ProximityPrompt）
│   ├── Redbucket / Bluebucket / Yellowbucket / Greenbucket
├── BallPoolp（Folder）                        4 色存放池
│   ├── RedPool / BluePool / YellowPool / GreenPool（Part）
│   │   ├── DepositPrompt（ProximityPrompt，按 E 倒球）
│   │   ├── Part > BillboardGui > Frame > TextLabel   展示牌（显示该池累计入库球数）
└── DepositedBalls（Folder，服务器运行时创建）   入库球中转/计数容器
```

### 3.2 共享层（ReplicatedStorage）
```
ReplicatedStorage
├── Tool（Folder）                             4 个工具模板（已转 Tool 类）
│   └── Redbucket 等 → model（MeshPart 桶身）+ Handle（Part，精确名）+ BucketWeld
├── ModuleScript（Folder）
│   ├── ToolModuleScript      工具配置 + buildTool(toolName)
│   ├── BagConfig             背包常量（容量25/叠球参数/UI路径）
│   └── EconomyConfig         经济常量（1球=1币/DataStore名/UI路径）
├── BallPool（Part，551 球）                   球「模板源」（不可见，BallSpawner 克隆到 Workspace）
├── SuctionConfig            吸附参数（双端共享）
└── Remotes：RequestSuction / UpdateBag / DepositStatus / UpdateCoins
```

### 3.3 服务端（ServerScriptService）
```
ServerScriptService
├── ToolManager（Script）           工具装备（单槽，纯 E 获取）
├── BallSpawner（Script）           开局克隆球 + 注册碰撞组
├── SuctionServer（Script）         吸附收集裁决（入背包/叠球）
├── BagManager（Module） + BagServer（Script）   背包状态
├── DepositCoordinator（Module）    倒球互斥标志
├── DepositServer（Script）         倒球入库 + 展示牌计数 + 发金币
└── EconomyManager（Module） + EconomyServer（Script）  金币存档
```

### 3.4 客户端（StarterPlayerScripts）
```
StarterPlayer.StarterPlayerScripts
├── SuctionClient（LocalScript）   扫描同色球并发吸附请求（满/倒球中停发）
├── BagClient（LocalScript）        更新背包 UI（Bag.Num / TotalNum）
├── EconomyClient（LocalScript）    更新金币 UI（Coins.CoinText）
└── CoinFxClient（LocalScript）     金币增长动效
```

### 3.5 预建 UI（StarterGui）
```
ScreenGui
├── Bag（Frame）
│   ├── Num（TextLabel，当前收集数）  /  /（TextLabel）  TotalNum（TextLabel，容量）
└── Coins（Frame）
    ├── CoinLable（ImageLabel + UIScale）  金币图标（rbxassetid://13249575568）
    └── CoinText（TextLabel，金币数值）
```

---

## 四、已实现系统分模块说明

### 4.1 工具系统（Tool.md）
**需求要点**：4 色桶（Blue/Green/Red/Yellow bucket）；单槽装备；按 E 从 Workspace 切换站拿工具；工具 `BallColorCollect` 属性决定可吸颜色。

**关键澄清**：
- 无背包系统：Tool 直接 `Parent = Character` 装备（Roblox 引擎唯一手持方式）。
- 出生/重生**一律空手**，没有「按 1 初始红桶」——工具唯一获取方式 = 走近世界桶按 E。
- `ReplicatedStorage.Tool` 下 4 个桶模型本身 = 工具模板，已由 Model 转成 **Tool 类**；Handle 摆在桶口正上方并焊接桶身（`Handle` 精确命名，供 `tool.Handle` 读取）。
- Handle 放 Tool 直接子级（非 model 内），否则 `tool.Handle` 为 nil。

**脚本职责**：
- `ToolModuleScript.buildTool(name)`：克隆 Tool 模板，写入 `BallColorCollect`/`ToolType`/`Category`/`Suction*` 属性。Category：1=初始，2=特殊，3=预留。
- `ToolManager`：监听 `ProximityPromptService.PromptTriggered(prompt, player)`；把 prompt.Parent 的父级（Workspace.Tool 下的桶名）映射到配置；单槽替换；已持同名跳过。

### 4.2 球与收集（Ball.md + Ball_Pit_SKILL 架构）
**需求要点**：`ReplicatedStorage.BallPool` 是球源；`BallColorCollect` 对应吸收颜色。

**关键澄清与状态**：
- 球颜色统一**小写**：球属性 `BallColor = "red"/"blue"/"yellow"/"green"`，与工具 `BallColorCollect` 严格相等。
- 球「可动化」：**可滚动但球与球无碰撞** → 用碰撞组实现：注册 `Balls` 组，`Balls-Balls=false`、`Balls-Default=true`；源模板 551 球 `Anchored=false + CanCollide=true + CollisionGroup="Balls"`。
- 运行时 `BallSpawner` 每次启动都 `ensureCollisionGroups()`（运行时注册不随 place 保存）。
- `SuctionClient`：每帧扫描当前手持 Tool 的 Handle 周围（`GetPartBoundsInRadius`，过滤 Workspace.BallPool），命中同色可见球则 `FireServer(ball)`；本地缓存背包计数，满/倒球中停发。
- `SuctionServer`：服务器权威校验（球属于球池、颜色匹配、单玩家单球在途、距离、倒球中禁收）；吸附中临时锚定+清速度，由服务器驱动飞向 Handle 实时位置；到位入背包。
- 收集到的球**叠在当前工具 Handle 上方**（y 轴逐颗叠高，焊到 Handle 随工具；换桶时旧叠球随旧工具销毁，仅计数保留）。

### 4.3 背包系统（Bag.md）
**需求要点**：ScreenGui>Bag，Num=当前数、TotalNum=容量；初始容量 25、可扩展（后置升级/无限）；容量服务端持有；不同颜色球共存一背包（防换桶丢球）。

**实现**：
- `BagManager`（服务器权威）：每玩家 `{count, capacity}`；`tryAddBall`（满拒收）、`setCapacity`（升级预留，传 `math.huge` 即无限）、`clearBag`；变更经 `UpdateBag` 广播。
- `BagClient`：更新 Num/TotalNum。
- 收集到位：背包 count+1，同时叠球在桶口。

### 4.4 存放/倒球（BallPool.md）
**需求要点**：`Workspace.BallPoolp` 下 4 色池；把手中球丢进对应颜色池；入库动画如收集；进池球不可再收集；**入库后销毁并转金币**（第 5 条）。

**实现与澄清**：
- 触发：池上 ProximityPrompt（E）。只接受工具颜色与池色匹配（`RedPool→red`…）。
- 倒球对象：当前工具上叠的实体球（标记 `StackedBall`），自上而下逐颗飞出。
- 动画：球保留飞入动画（`DEPOSIT_SPEED=220` 提速），到位即销毁。
- **一次性结算**（用户反馈逐颗更新太慢后优化）：倒球开始即 `poolStoredCount[pool]+=total`、刷新池展示牌、`EconomyManager.addCoins(player, total*币值)`；到位循环只销毁不再逐颗更新数字。
- 池展示牌（Pool>Part>BillboardGui>Frame>TextLabel）显示该池**累计入库球数**，由服务器 `refreshPoolLabel` 实时刷新（曾改客户端轮询 PoolCountClient，因不稳定回退并删除）。
- 倒球期间：`DepositCoordinator.isDepositing` → SuctionServer 拒收、SuctionClient 停发，最后一颗到位后恢复。
- 玩家中途离开：清理并销毁在途球（结算已发生）。

### 4.5 经济系统（Economic system.md）
**需求要点**：`ScreenGui>Coins>CoinText`；1 球 = 1 金币；倒球入库实时 +1（已优化为一次性到总数）；金币**跨局存档**。

**实现**：
- `EconomyManager`（服务器权威内存态）+ DataStore：`EconomyConfig.DATA_STORE_NAME = "PlayerCoins_v1"`；pcall + 重试 3；PlayerAdded 加载 / PlayerRemoving + BindToClose 落盘；`addCoins` 经 `UpdateCoins` 广播。
- `EconomyClient`：写 `Coins.CoinText`。
- 注意：MVP 用 DataStoreService 简易 key，未上 ProfileService 会话锁（生产多服前应替换）。

### 4.6 金币 UI 动效（CoinFxClient）
需求（用户）：CoinText 增长时——
1. CoinLable 的 UIScale 在 0.1s 内变化：0.05s 变大为 **1.1**，0.05s 变回 **1**。
2. CoinLable 周围有副本由小到大涌向中心直至重合。

实现澄清（最新修正）：
- **副本从左上角方向涌来**（不再四面八方）：起点落在中心左上方扇形（指向 225° ± 30°），随机距离 0.6~1.4×90px；0.3s 内 0.3 倍放大到 1 倍并移向中心，重合后销毁。
- 触发条件：`UpdateCoins` 值比上次**增长**才播；首次只记录不播。

---

## 五、脚本 → 位置速查表

| 脚本 | 位置 | 类型 | 职责 |
|---|---|---|---|
| ToolModuleScript | ReplicatedStorage.ModuleScript | Module | 工具配置 + buildTool |
| SuctionConfig | ReplicatedStorage | Module | 吸附参数 |
| BagConfig | ReplicatedStorage.ModuleScript | Module | 背包常量 |
| EconomyConfig | ReplicatedStorage.ModuleScript | Module | 经济常量 |
| ToolManager | ServerScriptService | Script | 工具装备（E） |
| BallSpawner | ServerScriptService | Script | 克隆球 + 碰撞组注册 |
| SuctionServer | ServerScriptService | Script | 吸附收集/叠球/入背包 |
| BagManager | ServerScriptService | Module | 背包状态 |
| BagServer | ServerScriptService | Script | BagManager.init |
| DepositCoordinator | ServerScriptService | Module | 倒球互斥标志 |
| DepositServer | ServerScriptService | Script | 倒球/展示牌/发金币 |
| EconomyManager | ServerScriptService | Module | 金币 + DataStore |
| EconomyServer | ServerScriptService | Script | EconomyManager.init |
| SuctionClient | StarterPlayerScripts | Local | 扫描吸附 |
| BagClient | StarterPlayerScripts | Local | 背包 UI |
| EconomyClient | StarterPlayerScripts | Local | 金币 UI |
| CoinFxClient | StarterPlayerScripts | Local | 金币动效 |

---

## 六、关键坑与教训（踩过/已修）

1. **PromptTriggered 参数顺序**是 `(prompt, player)`，prompt 在前；写反会导致 `prompt.Parent` 取到玩家而非站台/池。
2. **客户端访问子实例**用 `WaitForChild`/`FindFirstChild`，别用点语法（点语法在客户端复制副本上不可靠）。
3. **Tool 的 Handle 必须精确命名为 `Handle`** 且是 Tool 直接子级，否则 `tool.Handle` 为 nil。
4. **球移出池容器**才能不可再被收集/扫描（DepositedBalls / Destroy）。
5. **碰撞组运行时注册不随 place 保存**，每次服务器启动需重新注册。
6. **物理球吸附**：吸附中临时锚定+清速度，由服务器驱动；取消/离开须 `restoreToPool()` 恢复可动状态。
7. **PoolCountClient 曾启动时缓存 UI 引用导致永不更新**（子级复制时机）；已整体回退为服务器刷新方案。
8. **倒球逐颗结算体验差** → 改为一次性结算。
9. **DataStore 一律 pcall + 重试**；MVP 未上 ProfileService 会话锁（SE-1 风险，上线前需补）。

---

## 七、验证状态与限制

- **已自动验证**：全部脚本 `loadstring` 语法通过；克隆 551 球、空间查询命中、池色映射、UI 定位等编辑环境模拟通过。
- **环境限制**：本 headless 环境 Playtest 输出通道超时（`get_playtest_output` 连接超时、无玩家注入），**无法全自动运行验证**。
- **需用户在 Studio 手动 Play 验证**：吸球/叠球手感、倒球动画与结算、CoinText/展示牌刷新时机、金币存档跨局恢复、金币动效观感。

---

## 八、待办 / 后续方向

- [ ] 用户在 Studio 手动 Play 全流程回归（收集→倒球→金币→动效→存档）。
- [ ] 球「入库总数验证」逻辑（用户计划自写或后续实现）。
- [ ] 容量升级系统（setCapacity 已预留；无限背包/升级入口后置）。
- [ ] Backpack System 文档与实现（当前为空目录，工具不走背包）。
- [ ] Map.Zone 区域推进/完成度判定（地图分区尚未接玩法）。
- [ ] DataStore 生产化：ProfileService 会话锁（SE-1）、存档字段版本化。
- [ ] 多人 4 人联机、大厅、Teleport 多 Place 架构（大版本后置）。
- [ ] 特殊工具（Category=2，如吸球器/多色/飓风收集器）扩展。
- [ ] Linux 沙盒 C 盘空间不足（VM_DISK_SPACE_INSUFFICIENT）——如后续需跑 node/脚本需清理 C 盘或重启应用。
```
