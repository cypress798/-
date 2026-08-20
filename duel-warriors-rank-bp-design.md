# Duel Warriors — Rank BP(Ban/Pick)流程设计

> ⚠️ 本文件为技术实现层参考;规则数值(时间、超时兜底、UI 状态)以 `duel-warriors-rank-bp-gdd.md` 为准。
> 状态:v2(按最新 spec 修订)
> 适用模式:1v1 / 2v2
> 原则:服务端权威,客户端纯表现;队内可见,队间不可见;对局节奏不变。

---

## 0. 已确认的设计决策

| # | 决策点 | 结论 |
|---|---|---|
| D1 | ban 方式 | **同时盲ban**——各方盲选,全部提交后统一揭示 |
| D2 | ban 数量 | **每队 2 个**——1v1:每人 2(共 4 提交);2v2:每人 1(共 4 提交) |
| D3 | 2v2 队内镜像 | **允许**——队友可重复选同一技能,只提示不限制 |
| D4 | pick 超时兜底 | **自动默认 loadout**——拥有的前 6 个未被 ban 技能(GDD 已决议:每人装配 6 个) |
| D5 | ban 视觉 | **灰 + ban 者头像**——头像栈边界:1v1 ≤ 2 个,2v2 ≤ 4 个 |
| D6 | 池布局 | **默认:单列表按等级排序,等级越高放下面**;金/紫分区作为可切换配置(见第 8 节) |

## 1. 阶段状态机

```
进入Rank → 加载(技能目录 + 拥有列表下发) → BAN → BAN_REVEAL → PICK → BATTLE
```

- `BAN`:各方盲选 ban(队内可见,队间不可见),提交到服务端
- `BAN_REVEAL`:收齐(或超时)后服务端结算,广播"技能 → ban者头像列表",固定 3s 展示
- `PICK`:各选 6 技能(3组×2,槽位1~6),提交即锁定
- `BATTLE`:收齐(或超时兜底)后服务端为每人装配 loadout,战斗开始

节奏预算(GDD 为准):1v1 = 5s + 3s + 10s = 18s;2v2 = 10s + 3s + 10s = 23s。
支持 **EarlyReady**:双方都确认后跳过剩余倒计时,保证"对局节奏不变"。

## 2. 服务端权威状态

```lua
local Match = {
  matchId = ...,
  mode = "1v1",                 -- "1v1" | "2v2"
  phase = "BAN",
  players = {},                 -- { userId, team, connected, banDone, pickDone }
  cfg = {
    banPerPlayer = (mode == "1v1") and 2 or 1,  -- 每队恒为2:1v1每人2,2v2每人1
    pickPerPlayer = 6,                              -- 每人装配6技能(3组×2)
    banTimer  = (mode == "1v1") and 5 or 10,       -- GDD:1v1 5s,2v2 10s
    pickTimer = 10,
    revealTimer = 3,
    allowEarlyReady = true,
    layout = { groupBy = "level", levelOrder = "asc" },  -- 默认:等级越高放下面(asc=低在上,高在下)
  },
  banSubmissions  = {},         -- [userId] = { skillId|nil, ... }  提交即锁定
  bannedBy        = {},         -- Reveal 时结算:[skillId] = { userId, ... }(提交顺序去重)
  pickSubmissions = {},         -- [userId] = { skillId, skillId, skillId }
}

-- 结算:重叠ban -> 同一技能挂多个ban者头像;空ban -> 跳过
function Match:resolveBans()
  local banned = {}
  for userId, subs in pairs(self.banSubmissions) do
    for _, sid in ipairs(subs) do
      if sid ~= nil and SkillCatalog[sid] then
        banned[sid] = banned[sid] or {}
        table.insert(banned[sid], userId)
      end
    end
  end
  return banned                 -- 头像栈天然 ≤ 玩家人数(1v1=2, 2v2=4),无需额外裁剪
end

-- pick 超时兜底:拥有的前6个未被ban技能
function Match:defaultLoadout(userId)
  local owned = PlayerInventory:GetOwned(userId)
  local out = {}
  for _, sid in ipairs(owned) do
    if #out >= 6 then break end
    if not self.bannedBy[sid] then table.insert(out, sid) end
  end
  return out                     -- 不足6个时允许空槽,由战斗侧按现有技能数适配
end
```

## 3. 1v1 适配

**Ban(每人 2,共 4 提交,同时盲ban)**
- 各自界面显示全技能池,互不可见
- 盲选 2 个(可留空);自己已勾选的卡片 = 高亮 + 自己头像
- 收齐 4 个提交或超时(未提交槽记空)→ 结算 → 广播 `BanResult`

**Ban 结算后(Reveal)**
- 被 ban 技能 = **灰 + ban 者头像**(重叠 ban 时一张卡最多叠 2 个头像)

**Pick(每人 6 = 3 组×2)**
- 池 = 所有技能,三种状态:
  - 已拥有 = 高亮
  - 未拥有 = 灰 + 🔒
  - 被 ban = 灰 + ban 者头像(最多叠 2 个)
- 提交即锁定;**对方永远收不到你的 loadout**(防插件偷窥)

```
P1(蓝)                    Server                     P2(红)
  │ ◀── BanPhaseInfo ────── │ ────── BanPhaseInfo ──▶ │
  │ ── SubmitBan×2 ───────▶ │ ◀────── SubmitBan×2 ─── │
  │                         │ 收齐 → resolveBans()     │
  │ ◀───── BanResult ────── │ ─────── BanResult ────▶ │
  │                         │ 3s Reveal → PICK         │
  │ ◀── PickPhaseInfo ───── │ ────── PickPhaseInfo ─▶ │
  │ ── SubmitPick×6 ──────▶ │ ◀────── SubmitPick×6 ── │
  │                         │ 收齐 → BATTLE(服务端装配) │
```

## 4. 2v2 适配

与 1v1 的差异:**队内可见,队间不可见**。ban 每队 2 个、每人 1 个,总提交与 1v1 相同(4)。

| 环节 | 1v1 | 2v2 |
|---|---|---|
| ban 槽 | 每人 2,共 4 提交 | **每人 1,共 4 提交**(每队 2) |
| ban 可见性 | 完全盲ban | 盲ban,但队友实时可见(带队友头像),敌方不可见 |
| ban 后卡片 | 灰 + 头像栈(≤2) | 灰 + 头像栈(≤4) |
| pick 可见性 | 互不可见 | 队友确认后可见,敌方不可见 |
| 镜像技能 | — | 允许(仅提示) |
| 掉线 | 判负 | ban 掉线 → 空ban;pick 掉线 → 默认 loadout |

```
A1/B1(蓝队)                Server                A2/B2(红队)
  │ ◀─ BanPhaseInfo ─────── │ ───── BanPhaseInfo ─▶ │
  │ 各自盲选1,队内实时可见  │                       │
  │ ── SubmitBan ─────────▶ │ ◀──── SubmitBan ───── │  (×4人 = 4提交)
  │ ◀── BanResult ───────── │ ─────── BanResult ──▶ │
  │ ◀── PickPhaseInfo ───── │ ───── PickPhaseInfo ─▶ │
  │ ── SubmitPick×6 ──────▶ │ ◀──── SubmitPick×6 ── │
  │ ◀─ TeammatePick(队友) ─ │ ─ TeammatePick(队友) ─▶│  队内广播,敌方收不到
```

队内同步通道(仅 2v2 开启):

```lua
-- ban 阶段:队友勾选时低频率同步(卡片显示队友头像,敌方不可见)
SendToTeam(team, "BanTeamPreview", { userId, currentSelections })

-- pick 阶段:队友提交后广播其3技能(便于配阵容;镜像允许,仅展示)
SendToTeam(team, "TeammatePick", { userId, loadout })
```

## 5. 服务端校验(客户端不可信)

```lua
local function ValidateBan(userId, skillIdOrNil)
  assert(Match.phase == "BAN", "阶段错误")
  local sub = Match.banSubmissions[userId]
  assert(sub and #sub < Match.cfg.banPerPlayer, "槽位已满")
  if skillIdOrNil ~= nil then
    assert(SkillCatalog[skillIdOrNil], "技能不存在")
    -- ban 池 = 全目录(未解锁也可ban)
    for _, s in ipairs(sub) do
      assert(s ~= skillIdOrNil, "同一玩家不能重复ban同一技能")   -- 自己的槽内不重复
    end
    -- 玩家之间重叠ban合法(头像栈),不检查其他玩家
  end
end

local function ValidatePick(userId, loadout)
  assert(Match.phase == "PICK", "阶段错误")
  assert(not Match.pickSubmissions[userId], "已提交")
  assert(#loadout == Match.cfg.pickPerPlayer, "数量必须为6")
  local owned = PlayerInventory:GetOwned(userId)   -- DataStore 权威
  local seen = {}
  for _, sid in ipairs(loadout) do
    assert(SkillCatalog[sid], "技能不存在")
    assert(owned[sid], "未解锁")
    assert(not Match.bannedBy[sid], "该技能已被ban")
    assert(not seen[sid], "loadout内重复")
    seen[sid] = true
  end
end
```

## 6. Remote 设计(单 Remote + action 枚举)

```lua
-- C→S
Rank.Remote:FireServer("SubmitBan",  skillIdOrNil)
Rank.Remote:FireServer("SubmitPick", {s1, s2, s3, s4, s5, s6})
Rank.Remote:FireServer("EarlyReady")

-- S→C
SendTo(p,      "BanPhaseInfo",  { skills, cfg, timerEnd })          -- 全技能池
SendToTeam(t,  "BanTeamPreview", { userId, selections })            -- 仅2v2
BroadcastAll(  "BanResult",      { bannedBy, layout })              -- [skillId]={userId...}
SendTo(p,      "PickPhaseInfo",  { skills, owned, bannedBy, layout, timerEnd })
SendToTeam(t,  "TeammatePick",   { userId, loadout })               -- 仅2v2
BroadcastAll(  "BattleStart",    {})
```

## 7. 技能卡片 UI 状态表

**布局(配置驱动,见 D6)**:默认单列表按等级升序(等级越高放下面);卡片仍带金/紫稀有度边框/角标。

| 阶段 | 状态 | 表现 |
|---|---|---|
| Ban | 可选 | 正常图标(紫框/金框) |
| Ban | 自己已勾选 | 高亮 + 自己头像 |
| Ban(2v2) | 队友已勾选 | 队友头像(仅队内可见) |
| Reveal | 被 ban | 灰 + ban 者头像栈(1v1 ≤2 / 2v2 ≤4) |
| Pick | 已拥有 | 高亮 |
| Pick | 未拥有 | 灰 + 🔒 |
| Pick | 被 ban | 灰 + ban 者头像栈(1v1 ≤2 / 2v2 ≤4) |
| Pick | 已选入 loadout | 槽位序号 1~6(组1/组2/组3) |

**状态优先级(一张卡同时命中多个状态时)**:被 ban > 未拥有(🔒) > 已拥有 > 已选。
即:被 ban 的卡只显示 灰+头像,不再叠加 🔒;🔒 只在"未拥有且未被 ban"时显示。

## 8. 布局配置(D6 展开)

```lua
-- 默认方案:单列表按等级升序——"等级越高放下面"(低等级在上,高等级在底部)
layout = { groupBy = "level", levelOrder = "asc" }

-- 备选方案:金/紫分区——两个横向区块,金区在上,区内按等级降序
layout = { groupBy = "rarity", rarityOrder = {"gold", "purple"}, levelOrder = "desc" }
```

两种方案可随时切换,只影响客户端排列逻辑,服务端数据不变。单列表布局下,卡片仍通过紫框/金框显示稀有度。

## 9. 边界情况

- **重叠 ban**:合法,同一技能可挂多个 ban 者头像(1v1 ≤2 / 2v2 ≤4),按提交顺序排列
- **空 ban**:合法,视为放弃槽位,不产生 bannedBy 记录
- **同一玩家两槽 ban 同一技能**:服务端拒绝(见 ValidateBan)
- **重复提交/超时后提交**:按 phase + 槽位校验拒绝并记审计日志
- **伪造技能 id**:全部走服务端 SkillCatalog + DataStore 拥有列表校验
- **ban 阶段掉线**:1v1 判负;2v2 该槽记空 ban
- **pick 阶段掉线/超时**:自动默认 loadout(拥有的前 6 个未 ban 技能;不足 6 允许空槽)
- **2v2 队内 ban 同一技能**:允许,队内预览加"队友已选"提示

## 10. 实现顺序建议

1. 服务端 Match 状态机 + SkillCatalog / PlayerInventory(权威数据)
2. 单 Remote + action 枚举 + 校验(先 1v1)
3. Ban 阶段 UI(盲选 + 头像预览 + 提交)
4. Reveal UI(灰 + 头像栈)与 Pick 阶段 UI(🔒 / 头像栈 / 槽位 + EarlyReady)
5. 布局模块(金/紫分区 / 等级排序,配置切换)
6. 2v2 增量:team 字段 + BanTeamPreview + TeammatePick + 掉线托管
7. 上线后监控:重叠ban率、超时率、审计日志中的校验失败次数
