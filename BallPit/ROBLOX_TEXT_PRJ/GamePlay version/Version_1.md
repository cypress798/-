# Version_1 开发日志

## 版本窗口
- 开始：2026-09-07（周一）00:00
- 结束：2026-09-14（周一）00:00
- 当前状态：进行中

## 记录约定
- 每周一 00:00 开始计算，到下周一 00:00 结束。
- 本周开发的所有内容写入 `Version_1.md`。
- 版本号每周递增：下周（2026-09-14 → 2026-09-21）为 `Version_2`，以此类推。
- 每次更新直接追加/更新到本文件，保持为本周的"活的"开发记录。

---

## 2026-09-07

### 开发基线确认
- **弃用** `Ball_Pit_SKILL.md` 作为实现与数据契约的基线（该模板与当前 Core gameplay system 规格不一致）。
- 采用 `Core gameplay system/*` 为当前实现规格，数据契约以「单背包 + 分类池销毁转金币」为准。

### 数据契约（当前定稿）
| 系统 | 约定来源 | 关键字段 |
|---|---|---|
| 工具 Tool | `Tool.md` | 4 初始工具 Blue/Green/Red/Yellowbucket；按 1 装备初始、按 E 切换不同色；工具分级 1/2/3；`BallColorCollect`=吸收颜色 |
| 球 / 球池 | `Ball.md` + `BallPool.md` | `ReplicatedStorage.BallPool` 为生成球池；Workspace `BallPoolp` 下 4 色 `<色>Pool` 存放池；球入池后销毁不可再收 |
| 背包 Bag | `Bag.md` | 单背包（非分色），初始容量 25，容量存服务端未来可升级；UI=`ScreenGui→Bag`（Num/TotalNum） |
| 经济 | `Economic system.md` | 1 球 = 1 金币；UI=`ScreenGui→Coins→CoinText`，每收 1 球 +1 |

### 当前开发动作（2026-09-07）
- [x] Suction/Collect、单背包容量校验与 UI、入池转金币、工具切换 —— 场景已实现（见项目结构盘点）。
- [x] 新增（Ball.md 第4条落地）：收集由「自动扫描吸附」改为「点击鼠标左键吸附一颗目标球」。
- [x] 新增（Ball.md 第5/6条落地）：点击吸附加 1s 冷却 + 工具槽半透明冷却遮罩（Size.Y→0）。

### 项目结构盘点（球池1 / placeId 134117600138350）——MCP 读取
> 场景已基本搭好（17 个脚本），非从零。

**共享配置（ReplicatedStorage）**
| 脚本 | 职责 |
|---|---|
| `SuctionConfig` | 吸附参数 + 属性名（`BallColor` 球色 / `BallColorCollect` 工具色，小写）+ 球池容器名 |
| `ToolModuleScript` | 工具配置唯一来源 + `buildTool`/`getByToolName`；类别 1 初始 / 2 特殊 / 3 预留 |
| `BagConfig` | 初始容量 25、叠球参数、背包 UI 路径 |
| `EconomyConfig` | 1 球 = 1 金币、DataStore `PlayerCoins_v1`、金币 UI 路径 |

**服务端（ServerScriptService）**
| 脚本 | 职责 |
|---|---|
| `ToolManager` | 单槽装备；靠近桶站按 E 切换工具；出生空手；写 `BallColorCollect` 等属性 |
| `BallSpawner` | 开局把 `ReplicatedStorage.BallPool` 克隆到 Workspace `BallPool`；注册碰撞组 `Balls`（球-球不碰、球-地面可碰） |
| `SuctionServer` | 吸附权威：校验颜色/距离/容量/单球在途 → Heartbeat 直线吸向 Handle → 到位叠桶口（WeldConstraint 跟随工具） |
| `BagManager` | 背包状态（count/capacity），服务器权威，广播 `UpdateBag` |
| `BagServer` | 启动入口，调 `BagManager.init()` |
| `DepositCoordinator` | 倒球中状态标记，广播 `DepositStatus` |
| `DepositServer` | 倒球入库：核对池颜色 → 叠球逐颗飞向池 → 到位销毁 + 转金币 + 池计数牌刷新 + 清空背包 |
| `EconomyManager` | 金币内存缓存 + DataStore 落盘（pcall + 重试 + BindToClose） |
| `EconomyServer` | 启动入口，调 `EconomyManager.init()` |

**客户端（StarterPlayerScripts）**
| 脚本 | 职责 |
|---|---|
| `SuctionClient` | 点击左键选最近同色目标球 → `FireServer`；缓存背包计数（满停发）；倒球中停发 |
| `BagClient` | 把 `UpdateBag` 刷新到 `Bag/Num`、`TotalNum` |
| `EconomyClient` | 把 `UpdateCoins` 刷新到 `Coins/CoinText` |
| `CoinFxClient` | 金币增长动效（UIScale 脉冲 + 8 副本涌向中心，仅增长触发） |

**场景对象**
- ReplicatedStorage：`SuctionConfig`、`ModuleScript`（3 配置）、`Tool`（4 工具模板）、RemoteEvent（`RequestSuction`/`UpdateBag`/`DepositStatus`/`UpdateCoins`）、`BallPool`(模板球源)
- Workspace：`Tool`（4 桶站 Model + ProximityPrompt）、`BallPoolp`（4 色存放池 + DepositPrompt + 计数牌）、`BallPool`(运行时克隆球)
- StarterGui：`ScreenGui`→`Bag`(`Num`/`TotalNum`/`/`) + `Coins`(`CoinLable`/`CoinText`)
- StarterPack：**空**；ServerStorage：`__Rojo_SessionLock`

**MCP 读取疑点（Claude.md 规则一 / 规则三，未改动仅记录）**
1. `SuctionConfig` 头注释过时：写"MVP 只做吸附收集，不含容量/站台/UI"，实际已实现容量（BagManager）、站台（BallPoolp）与 UI。
2. 与文档差异：`Tool.md` 说"按 1 装备初始 + 按 E 切换"，实际是「出生空手 + 靠近桶站按 E 装备/切换」，无数字键 1；`ReplicatedStorage.Tool`(Tool 类模板) 与 `Workspace.Tool`(Model 切换站) 同名不同类；`StarterPack` 为空。
3. Rojo 痕迹：`ServerStorage.__Rojo_SessionLock` 表明工程使用 Rojo，与"纯 Studio 内落地、无需 Rojo"说明不符。
4. `execute_luau` 稳定性：偶尔报 "Failed to parse command code"。已做逐项测试（递归/循环/ipairs/`table.concat`/开头空行/额外局部变量均通过，同一结构代码连跑 4 次全 PASS），判定为**工具端偶发/脆弱、非代码内容所致**，不影响游戏逻辑，也无法从游戏侧修复。对策：探查用稳定工具 `search_game_tree`/`script_read`/`inspect_instance`；`execute_luau` 调用全部加 try/catch 重试并保持单次任务简洁。

### 疑点定案（2026-09-07）
| # | 项 | 结论 | 动作 |
|---|---|---|---|
| 1 | `SuctionConfig` 头注释过时 | 已改为「现实现完整链路：吸附收集 + 背包容量 + 倒球站台 + 金币/UI」 | ✅ 已改（`multi_edit`） |
| 2 | 工具按 1 / E | 保持「出生空手 + 靠近桶站按 E 装备/切换」（无数字键 1）；`StarterPack` 为空不动 | ✅ 保持现状 |
| 3 | Rojo 痕迹 | 目前**不使用 Rojo**；`ServerStorage.__Rojo_SessionLock` 为遗留对象，无脚本引用，不影响逻辑 | ⏸ 保留不删（如需删除请明示） |
| 4 | `execute_luau` 稳定性 | 工具端偶发解析失败，非代码问题 | [done] 对策：用 `search_game_tree`/`script_read` + `execute_luau` 重试 |

### 2026-09-07 改动：Ball.md 第4条 点击左键吸附（已落地）
收集触发方式由「Heartbeat 自动扫描」改为「点击鼠标左键吸附一颗目标球」。
- **改动文件**：`StarterPlayer.StarterPlayerScripts.SuctionClient`（`multi_edit` 3 处）
- **实现**：新增 `pickTargetBall(tool)`（在工具 Handle 半径内选**最近**一颗可收集、同色、未在途的球）；`UserInputService.InputBegan` 监听左键 → 倒球中/背包满/无工具则忽略 → 发起 `RequestSuction(ball)`。
- **服务端零改动**：`SuctionServer` 原有校验（颜色/距离/容量/单球在途）继续生效。
- **去掉了**：自动扫描的 `RunService.Heartbeat` 与 `scanTimer`，移除 `RunService` 引入、新增 `UserInputService` 引入。
- **备注**：`SuctionConfig.SCAN_INTERVAL` / `MAX_SUCTION_BATCH` 现在代码不再使用（保留在配置未删）；当前为「最近目标球」实现，若要「点哪颗吸哪颗」需改用相机射线 raycast。

### 2026-09-07 改动：Ball.md 第5/6条 冷却 + 工具槽遮罩（已落地）
- **改动文件**：`ReplicatedStorage.SuctionConfig`（加 `SUCTION_COOLDOWN = 1`）、`StarterPlayer.StarterPlayerScripts.SuctionClient`（`multi_edit` 5 处）。
- **第5条 · 冷却**：`SUCTION_COOLDOWN`（初始 1s）作为两次「点击吸附」的最小间隔；点击用 `lastSuction` 记录时间，未满冷却则拒绝。
- **第6条 · UI**：新增工具槽 `ToolSlot`（底部居中 72x72 Frame，显示当前工具色）+ 半透明 `CooldownMask` 遮罩（`BackgroundTransparency=0.45`），遮罩 `AnchorPoint=(0.5,0)`、`Size.Y = 剩余冷却/冷却`，随冷却恢复逐渐缩到 0；`RunService.RenderStepped` 每帧刷新；`CharacterAdded` 重生后重建（ScreenGui 会被重新克隆）。
- **服务端零改动**：冷却与 UI 均为客户端表现，服务器仍按颜色/距离/容量/单球在途校验。
- **假设**：文档中的「Tool工具1」按**底部居中工具槽**实现（场景原先无工具槽 UI）；位置/尺寸如需调整请告知。

