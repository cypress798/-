# 《Clean All the Leaves!（清理所有树叶！）》玩法循环与经济体系分析

> 游戏：**Clean all the leaves!**（Roblox）
> 制作相关：Muffin Interactive 关联（社区 Wiki 归类）
> 游戏页：[Roblox 游戏链接](https://www.roblox.com/games/92637789841354/Clean-all-the-leaves)
> 资料整理日期：2026-09-02
> 说明：本文基于多个第三方攻略站（Roonby、NerdsChalk、Pocket-Codes、GameStratWiki、RobloxDatabase）的公开文章交叉整理。游戏处于持续更新中，具体价格与数值会随版本变化，涉及精确数值处以"据攻略报道"标注。

---

## 1. 一句话概括

《Clean All the Leaves!》是一款"**清树叶·经营·闯关**"类 Roblox 游戏：玩家进入一座房子及其院子，把散落各处的树叶收集/推扫/焚烧掉、送入"通风口（vent）"处理，把一个区域清到 100% 后解锁下一个区域，最终清完整张地图并触发（含隐藏）结局。它的骨架非常接近常见的 Roblox "模拟经营 + 区域解锁"模型——**收集 → 出售变现 → 买工具/升级 → 更高效地收集 → 解锁新区域**。

---

## 2. 游戏基本信息（据公开资料）

| 项目 | 内容 |
|---|---|
| 英文名 | Clean All the Leaves! / Clean all the leaves |
| 中文名 | 清理所有树叶！ |
| 核心题材 | 清理树叶、庭院整理、经营升级 |
| 单局形态 | 一张地图内按区域推进，清到 100% 解锁下一区域 |
| 结局系统 | 常规通关 + 隐藏"秘密结局" |
| 支持模式 | 可单人也建议多人合作（不同玩家分工清不同区域） |
| 已知区域 | Lobby、Front Yard、Porch、Shed、Garage、Court、Pool、Rooftop、Basement 等 |

---

## 3. 玩法循环（Core Loop）分析

### 3.1 微观循环（几十秒级）

```
发现树叶/落叶堆
   │
   ▼
用工具收集或聚拢（手 / 耙子 / 吹叶机）
   │
   ▼
送到处理点（通风口 vent / 垃圾桶 bin）或直接焚烧（地下室用燃烧瓶）
   │
   ▼
换成现金（Cash），清空一片 → 区域进度 +%
   │
   ▼
回大厅或下一片继续
```

- 玩家用手捡、用耙子搂、或用吹叶机把大片叶子"吹成一堆再推入通风口"。
- 通风口是效率关键：**把叶子推进通风口比自己一趟趟背去卖快得多**；地图各处散布多个通风口，部分需花钱解锁。
- 角落里卡住的叶子要换用手（配合 Grasp 抓取升级）去捡。

### 3.2 局内成长循环（单张图 / 数分钟级）

```
清小区域 → 触发"现金加成（cash boost / 收益倍率）"
   │
   ▼
用赚到的钱买更强工具 / 升级（吹叶机功率、宽度、扩散等）
   │
   ▼
清更大的区域更快 → 收益更高
   │
   ▼
清完一片 100% → 解锁下一区域 / 新通风口
```

关键技巧（攻略共识）：**先清小区域（门廊 Porch、棚屋 Shed）拿收益倍率，再去清大区域**，这样同样一车叶子能卖更多钱。

### 3.3 宏观循环（跨局 / 大厅 Meta）

```
把局内赚到的钱（现金）与宝石（Gems）投入"大厅升级"
（移速、背包容量、现金加成、宝石加成、职业等）
   │
   ▼
下一局起点更强 → 清得更快 → 解锁更后面区域
   │
   ▼
全区域 100% → 地下室两波 → 秘密结局
```

- **大厅升级（永久/跨局）**：移动速度（Walk Speed）、背包容量（Bag Size）、现金加成（Cash boost）、宝石加成（Gems boost），以及"抽职业"（Spin Class）。
- **局内购买（一次性）**：耙子 Rake、吹叶机 Leaf Blower、燃烧瓶 Molotov、局内背包扩容等，用当局现金购买。
- 宝石也用于大厅升级与职业抽取，属于"硬通货"。

### 3.4 完整循环图

```
         ┌────────────────────────────────────────────┐
         │                                            │
         ▼                                            │
   [收集/聚拢树叶] → [通风口/垃圾桶/焚烧] → [获得现金+偶尔宝石]
         │                                            │
         ▼                                            │
   [买工具/升级（局内+大厅）] ──→ [清到 100% 解锁区域] ──┘
         │
         ▼
  [全图 100% → 地下室两波 → 秘密结局/徽章]
```

---

## 4. 工具与升级体系

### 4.1 工具（局内用现金购买为主）

| 工具 | 作用 | 已知价格（据攻略） |
|---|---|---|
| 双手（基础） | 手动捡取；配合 Grasp/Dexterity/Hold 强化 | 初始自带 |
| 耙子 Rake | 聚拢/拖动成片叶子，早期过渡工具 | $7.99 |
| 吹叶机 Leaf Blower | 大范围吹动叶子、聚成大堆推入通风口；**全游戏最大提速点** | $29.99 |
| 燃烧瓶 Molotov | 地下室（无通风口）把聚拢的叶子批量烧掉 | $100 |
| 一次性垃圾桶 Disposable Bin | 就近快速换现金 | 地图内使用 |
| 通风口 Vents | 处理点，把叶子吸走换钱；部分需解锁 | 部分需现金解锁 |

### 4.2 大厅升级（跨局，用 Gems 等）

据攻略站报道的常见项目：

| 升级 | 作用 | 参考成本（据攻略） |
|---|---|---|
| Walk Speed 移速 | 减少区域间往返耗时 | ~50（50 Gems / 或 50 Cash，各站口径不同） |
| Bag Size 背包容量（大厅） | 提高一次能携带的叶子数 | 40 |
| Cash boost 现金加成 | 提高叶子卖出单价/收益 | 50 |
| Gems boost 宝石加成 | 提高宝石产出 | 40 |
| Spin Class 职业抽取 | 随机解锁职业 | 40（每抽） |
| Infinite Bag 无限背包 | 免除背包容量限制 | **Robux 购买（Game Pass）** |

> 注：不同攻略站对"大厅升级用 Gems 还是 Cash"口径略有出入（例如 Pocket-Codes 写 "Bag Size (40 cash)/Walk Speed (50 cash)"，NerdsChalk 写 "Walk Speed ~50 gems / Bag Size 40 gems"）。文档据此只列相对大小关系，具体币种以游戏内当前版本为准。

### 4.3 局内属性升级

- **Grasp（抓取）**：一次能捡更多叶子 —— 被多篇攻略列为**第一优先**。
- **Dexterity（灵巧）**：进一步加快手动拾取。
- **Hold（持握）**：更顺手地携带更多叶子。
- **Bag Capacity（局内容量）**：50 → 100 → 525 之类档位，减少"回卖"次数。
- **吹叶机强化**：Power（功率）、Width（宽度）、Spread（扩散）。
- **耙子强化**：Radius（半径）、Stickiness（黏性/聚拢保持力）。

### 4.4 职业系统（Class，经 Spin Class 解锁）

| 职业 | 效果 | 社区评级 |
|---|---|---|
| Handyman 全能手 | 多维度平衡加成，不锁定单一玩法 | S 级（公认最强） |
| Blower Specialist 吹叶机专精 | 降低吹叶机升级成本 | A 级 |
| Cash Treasurer 现金管库 | 提高捡叶子的现金收入 | A 级 |
| Diamond Treasurer 钻石管库 | 提高钻石（Diamonds）产出 | B 级 |
| Bag Specialist 背包专精 | 提高叶子容量 | B 级（前期好用，后期价值下降） |
| Rake Specialist 耙子专精 | 降低耙子升级成本 | C 级（后期意义有限） |
| Starter 初始职业 | 无特殊加成 | D 级（尽早替换） |

> 钻石（Diamonds）是文中出现的高级资源，用于部分升级与职业解锁。攻略建议的替代梯度：**Handyman > Blower Specialist / Cash Treasurer > Diamond Treasurer / Bag Specialist > Rake Specialist > Starter**。

---

## 5. 经济体系分析

### 5.1 货币分层

| 货币 | 性质 | 来源 | 主要用途 |
|---|---|---|---|
| Cash 现金（$） | 软货币/局内货币 | 叶子出售（单叶底价约 $0.01）、收益倍率放大 | 买耙子/吹叶机/燃烧瓶、局内升级 |
| Gems 宝石 | 硬货币/大厅货币 | 每日奖励、商店免费礼包、群组奖励、特殊叶子掉落、区域/收集进度 | 大厅升级、职业抽取 |
| Diamonds 钻石 | 高级资源 | 特殊来源/职业加成 | 升级与解锁职业等 |
| Robux | 平台真实货币 | 充值 | 购买 Game Pass（如 Infinite Bag）等 |

### 5.2 现金的产出逻辑（滚雪球）

- 基础：叶子卖出 ≈ $0.01/片，靠**数量**与**区域收益倍率（cash boost/multiplier）**放大。
- 清完小区域（Porch、Shed 等）会**永久（当局）提升现金倍率**；攻略提及如 Shed 完成可把收益推到 +20%，地下室完成后有 +110% 之类的大额加成。
- 大叶/特殊叶（红、蓝、彩虹）价值更高，优先拾取可显著提高单趟收益。
- 特殊/发光叶子有 RNG 概率直接掉宝石。

### 5.3 免费宝石获取（F2P 重点，据 Pocket-Codes 等）

| 来源 | 说明 |
|---|---|
| 每日签到（Daily Reward） | 连续签到递增，**第 8 天可领 1,000 Gems** |
| 商店免费礼包 | 每次进游戏打开商店可领约 10 Gems 袋 |
| 群组奖励 | 加入官方 Roblox 群领取一次性宝箱奖励 |
| 特殊叶子掉落 | 清小区域/发光叶子有概率掉 Gems（RNG，区域不同掉率不同） |
| 区域/收集进度 | 完成地图与收集进度给宝石 |
| "重进刷新"（Rejoin Loop） | 清完小区域后退出重进，重置叶子刷新点继续刷（偏"刷法"） |

> 有攻略明确警告：**"自动收集/自动胜利"类脚本/外挂存在，但会危及账号，不建议使用**；上述快速路线均为纯正常玩法。

### 5.4 变现（Robux）设计

- 据多方攻略，已知含 **Robux 购买的"无限背包（Infinite Bag）"Game Pass**，用于移除背包容量限制、减少回卖。
- 职业抽取（Spin Class）可作为宝石回收点（也可能提供 Robux 直购入口）。
- 整体属"**买便利/买加速、不买通关**"的轻度变现结构：不买也能 100% 通关（Leaf Blower 等关键工具用游戏内现金即可买）。

### 5.5 经济设计点评

1. **双轨货币制造目标感**：Cash 管"当局爽感"，Gems 管"跨局成长"，形成两层留存。
2. **倍率乘法驱动滚雪球**：清小图拿倍率 → 打大图 → 再升级 → 这是标准"模拟器"式正反馈。
3. **"少走路"即收益**：背包容量 + 通风口 + 移速本质都在压缩"无效通勤时间"，把经济效率等同于操作路线优化，玩家自会形成最优路径。
4. **稀缺资源靠特殊叶 + 签到保底**：宝石既有随机掉落（刺激），又有每日 1000 保底（防挫败），是典型混合设计。
5. **变现温和但存在**：无限背包这类"省事型"Game Pass 对高频玩家有吸引力，且不破坏公平。

---

## 6. 区域与推进结构（地图进度 = 关卡解锁）

| 区域 | 解锁条件 / 特点 |
|---|---|
| Lobby | 大厅，做升级与进入地图 |
| Front Yard 前院 | 开局主区域；**清到 100% 是解锁 Rooftop 的关键** |
| Porch 门廊 | 紧凑小图，速清刷倍率首选 |
| Shed 棚屋 | 小图，完成后给现金加成（+20% 例） |
| Garage 车库 | 封闭区域，适合聚拢后一锅端 |
| Court 庭院 | 中大面积，配合移速升级更高效 |
| Pool 泳池 | 有**第二波叶子**，清完记得复查 |
| Rooftop 屋顶 | 需 Front Yard 100%（存在解锁 Bug 时重进可解） |
| Basement 地下室 | **无通风口**，需用燃烧瓶；完成后高额现金加成 |
| Secret Path 秘密通道 | 全区域 100% + 地下室两波后开放 → 秘密结局 |

> 每区域有左上角完成度百分比；卡在 99% 时多查角落、围栏、楼梯后与高处。

---

## 7. 结局与徽章

- **正常通关**：清完整张地图所有区域。
- **秘密结局（Secret Ending）**：
  1. 所有区域 100%；
  2. 地下室（Basement）连续清**两波**叶子；
  3. 打开秘密通道走向出口；
  4. 触发特殊过场 + **Secret Ending 徽章**。
- 剧情彩蛋：过场揭示朋友从一开始就在屋内，用监控看着玩家 —— 整个"大扫除委托"其实是朋友对玩家的恶作剧。
- 平均耗时：攻略称约 1 小时左右（视熟练度与吹叶机入手速度）。

---

## 8. 值得借鉴/可复用的 Roblox 设计点

1. **把"模拟经营"翻译成"物理动作"**：收集资源（树叶）不是点按钮，而是"吹/搂/扫"的物理互动，表现力强、操作有爽感。
2. **通风口 = 传送带式"自动交单点"**：大幅降低重复通勤，是手游玩法节奏的关键设计。
3. **倍率与区域解锁绑定**：清小图给倍率 → 让"区域进度"本身变成经济引擎的一部分。
4. **"先小后大"默认最优解**：攻略社区形成一致策略，说明数值曲线引导成功。
5. **合作即效率**：多人在线让大图分工清理，天然带社交动力。

---

## 9. 资料与参考来源

- Roblox 游戏页：[Clean all the leaves](https://www.roblox.com/games/92637789841354/Clean-all-the-leaves)
- RobloxDatabase（徽章与商店指南）：[Clean all the leaves! Badges and Shop Guide](https://robloxdatabase.com/games/clean-all-the-leaves/)
- Roblox Fandom Wiki（Muffin Interactive 关联页，抓取超时未能展开）：[Muffin Interactive/Clean all the leaves](https://roblox.fandom.com/wiki/Muffin_Interactive/Clean_all_the_leaves)
- Roonby 新手进阶：[10+ Clean All The Leaves Roblox Beginner Guide](https://roonby.com/2026/08/26/10-clean-all-the-leaves-roblox-beginner-guide-how-to-progress-faster-tips-tricks/)
- Roonby 快速通关：[How to Win Fast and Easy in Clean All The Leaves Roblox](https://roonby.com/2026/08/19/how-to-win-fast-and-easy-in-clean-all-the-leaves-roblox/)
- Roonby 秘密结局：[Secret Ending in Clean All the Leaves Roblox Guide](https://roonby.com/2026/08/27/secret-ending-in-clean-all-the-leaves-roblox-guide/)
- Roonby 屋顶解锁：[How to Unlock Rooftop in Clean All the Leaves Roblox Guide](https://roonby.com/2026/08/27/how-to-unlock-rooftop-in-clean-all-the-leaves-roblox-guide/)
- NerdsChalk（快速入手吹叶机 / 路线）：[How to Get the Leaf Blower Fast in Clean All The Leaves](https://nerdschalk.com/how-to-get-the-leaf-blower-fast-in-clean-all-the-leaves-roblox/)
- NerdsChalk（屋顶解锁/99% 卡关）：[Clean All The Leaves Rooftop Unlock Explained](https://nerdschalk.com/clean-all-the-leaves-rooftop-unlock-house-map-cleanup-steps-and-99-fixes/)
- Pocket-Codes（宝石速刷）：[How to Farm Gems Fast in Clean All The Leaves](https://pocket-codes.com/how-to-farm-gems-fast-in-clean-all-the-leaves.html)
- GameStratWiki（职业强度榜）：[Best Classes Tier List in Clean All the Leaves Roblox](https://gamestratwiki.com/best-classes-tier-list-in-clean-all-the-leaves/)
- AllThings.How（秘密结局，抓取被 CDN 拦截，未展开）：[Clean All the Leaves: How to Get the Secret Ending](https://allthings.how/clean-all-the-leaves-roblox-how-to-get-the-secret-ending/)

---

*文档由多来源整理，供玩法与数值设计参考；如后续定位到官方/更新日志，可再校对价格与职业数值。*
