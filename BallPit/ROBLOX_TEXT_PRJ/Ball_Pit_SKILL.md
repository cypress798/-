---
name: "roblox-suction-collect"
description: "Build a config-driven, server-authoritative suction/attract-collect & deposit system in Roblox (vacuum color-matched balls/items from a pool into a capacity-limited Tool, then deposit at color-matching ProximityPrompt stations). Use for auto-suction tools, magnet/vacuum collect mechanics, ball-pit/collect-and-deposit prototypes, or when asked to reuse the \"球池\" gameplay pattern."
---

---
name: roblox-suction-collect
description: >
  Build a config-driven, server-authoritative suction/attract-collect & deposit system
  in Roblox — vacuum color-matched balls/items from a pool into a capacity-limited Tool,
  then deposit at color-matching ProximityPrompt stations. Use for auto-suction tools,
  magnet/vacuum collect mechanics, ball-pit / collect-and-deposit prototypes, or when the
  user asks to reuse the「球池」吸附收集 pattern.
---

# Roblox 吸附收集玩法模板(Suction-Collect & Deposit)

从已验证的「球池」原型(v7 服务器权威架构)提炼的可复用玩法模板。无需依赖 Rojo/任何外部工具,纯 Roblox Studio 内可落地;也可通过 Roblox Studio MCP 逐步生成。

## 一、何时使用

- 需要"手持工具自动吸附/磁吸同色物、收集满后到站台存放堆叠"的玩法。
- 需要"吸尘器 / 磁铁 / 渔网 / 割草收集"类 Tool 机制的雏形。
- 需要一个**服务器权威 + 客户端扫描 + 双端共享配置**的干净参考实现。

不适用:不需要物理吸附、只用拾取(Raycast/ClickDetector)的普通收集。

## 二、架构总览

```
┌─ ReplicatedStorage ──────────────────────────────────────┐
│  SuctionConfig (ModuleScript)   ← 双端唯一参数源        │
│  SuctionRemotes (Folder)                                 │
│   ├─ RequestSuction    RemoteEvent  C→S 请求吸附        │
│   ├─ SyncSuction       RemoteEvent  S→All 球消失广播     │
│   ├─ PlayCollectSound  RemoteEvent  S→C 播放音效         │
│   └─ UpdateCollectUI   RemoteEvent  S→C 刷新容量计数     │
└──────────────────────────────────────────────────────────┘

┌─ ServerScriptService ──┐        ┌─ StarterPlayer.StarterPlayerScripts ─┐
│  SuctionServer (Script)│        │  SuctionClient (LocalScript)          │
└────────────────────────┘        └───────────────────────────────────────┘
```

- **服务器权威**:吸附成败、容量、在途球、飞行、存放全部由服务器裁决。客户端只做"视觉扫描 + 发起请求",一切参数校验在服务端重复执行(不信任客户端)。
- **共享配置**:所有可调参数集中在 `SuctionConfig`,保证双端检测口径一致。
- **不持久化**:本模板不含存档(收集状态在服务器内存)。需要存档时参考 DataStoreService / ProfileService 另行接入。

## 三、数据契约(命名与属性)

固定约定,改名字要同步改 `SuctionConfig` 里的映射表。

| 实体 | 要求 | 属性 |
|---|---|---|
| 球/可吸物 | `BasePart`(建议球形,直径按 `BALL_SIZE`),非锚定可碰撞 | `BallColor` = 颜色名 |
| 池容器 `BallPool` | 一个父容器(**只**包含可被吸附的球);客户端扫描只过滤它 | — |
| 工具(在 StarterPack) | `Tool`,含 `Handle`,Handle 即吸附起点 | `ToolColor` = 颜色名 |
| 站台 `<色>ToolCollect` | `BasePart` + 子级 `ProximityPrompt`(ActionText='Interact',默认 E) | 运行时 `StoredCount` 累计 |
| 隐藏点 | 常量 `HIDE_POS = Vector3.new(0,-500,0)` | — |
| 展示文件夹 | 服务器运行时创建 `DepositedBalls`(父级=池所在组),存放已展示球 | — |

颜色表(默认 4 色,可增删):

```
RedTool      → Red     站台 RedToolCollect
BlueTool     → Blue    站台 BlueToolCollect
YellowTool   → Yellow  站台 YellowToolCollect
GreenTool    → Green   站台 GreenToolCollect
```

## 四、分步搭建

1. **场景**:建球池容器 `BallPitPrototype > BallPool`(Part,建议 12×12×2,`Material=ForceField`、`Transparency≈0.5`),在其中放球:每颗球是 `Shape=Ball` 的 Part,Size 0.8×0.8×0.8,给 `BallColor` 属性。球要能滚动,故 **Anchored=false、CanCollide=true**。
2. **站台**:Workspace 下放 4 个 BasePart `RedToolCollect / BlueToolCollect / YellowToolCollect / GreenToolCollect`,各挂一个 `ProximptPrompt`。
3. **工具**:StarterPack 放 4 个 `Tool`,各含 `Handle`(尺寸约 1.2,颜色与球一致),Handle 设 `ToolColor` 属性。
4. **共享层**(ReplicatedStorage):创建 `SuctionConfig`(见下代码)与 `SuctionRemotes` 文件夹内 4 个 RemoteEvent(名称按架构图)。
5. **服务端**(ServerScriptService):`SuctionServer` Script,贴服务器代码。
6. **客户端**(StarterPlayer > StarterPlayerScripts):`SuctionClient` LocalScript,贴客户端代码。
7. **调参**:改 `SuctionConfig` 即可(半径/速度/容量/颜色…)。改完**双端都会读到**,无需改业务代码。

> 通过 Roblox Studio MCP 落地时:用 `mass_create_objects`/`create_ui_tree` 建层级,`set_attribute` 写属性,`set_script_source` 贴脚本。球多(数百)时用 Luau 循环在 `execute_luau` 里生成,不要逐个 create。

## 五、代码模板

### 1) SuctionConfig(ReplicatedStorage)

```lua
-- SuctionConfig —— 双端共享配置
local SuctionConfig = {}

SuctionConfig.SUCTION_RADIUS = 20      -- 吸附检测半径(stud)
SuctionConfig.SUCTION_SPEED = 28       -- 吸向 Handle 速度(stud/s)
SuctionConfig.COLLECT_DISTANCE = 0.7   -- 判定收集成功的距离
SuctionConfig.COLLECT_COOLDOWN = 0.5   -- 两次收集最小间隔(s)
SuctionConfig.TOOL_CAPACITY = 25       -- 每把工具容量
SuctionConfig.DEPOSIT_RADIUS = 5       -- 站台可交互半径
SuctionConfig.DEPOSIT_SPEED = 40       -- 存放飞行速度
SuctionConfig.DEPOSIT_STAGGER = 0.06   -- 存放逐颗起飞间隔(s)
SuctionConfig.SCAN_INTERVAL = 0.08     -- 客户端扫描间隔(s)
SuctionConfig.MAX_SUCTION_BATCH = 1    -- 每次扫描最多请求 1 球
SuctionConfig.BALL_SIZE = 0.8          -- 球的直径

-- 工具名 → 颜色
SuctionConfig.TOOL_COLORS = {
	RedTool = "Red", BlueTool = "Blue",
	YellowTool = "Yellow", GreenTool = "Green",
}
-- 站台名 → 颜色
SuctionConfig.STATION_COLORS = {
	RedToolCollect = "Red", BlueToolCollect = "Blue",
	YellowToolCollect = "Yellow", GreenToolCollect = "Green",
}

SuctionConfig.BALL_COLOR_ATTR = "BallColor"
SuctionConfig.TOOL_COLOR_ATTR = "ToolColor"

SuctionConfig.COLOR_VALUES = {
	Red = Color3.fromRGB(249, 97, 103),
	Blue = Color3.fromRGB(66, 133, 244),
	Yellow = Color3.fromRGB(249, 168, 38),
	Green = Color3.fromRGB(42, 157, 143),
}

return SuctionConfig
```

### 2) SuctionServer(ServerScriptService)

```lua
-- SuctionServer —— 吸附收集 + 存放(服务器权威)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local remotes = ReplicatedStorage:WaitForChild("SuctionRemotes")
local requestSuction = remotes:WaitForChild("RequestSuction")
local syncSuction = remotes:WaitForChild("SyncSuction")
local playCollectSound = remotes:WaitForChild("PlayCollectSound")
local updateCollectUI = remotes:WaitForChild("UpdateCollectUI")
local config = require(ReplicatedStorage:WaitForChild("SuctionConfig"))

local colorToTool, colorToStation = {}, {}
for toolName, color in pairs(config.TOOL_COLORS) do colorToTool[color] = toolName end
for stationName, color in pairs(config.STATION_COLORS) do colorToStation[color] = stationName end

local suctioning = {}          -- { ball = {handle, player, arrived} }
local suctionCount = 0
local playerBall = {}          -- 每玩家同时在途球
local lastCollectTime = {}
local collected = {}           -- [Player][color] = { ball, ... }
local collectedCount = {}      -- [Player][color] = n
local depositingFlag = {}      -- [Player][color] = true
local depositing = {}          -- 存放飞行表
local depositingCount = 0
local HIDE_POS = Vector3.new(0, -500, 0)

local depositedBin = Instance.new("Folder")
depositedBin.Name = "DepositedBalls"
depositedBin.Parent = workspace:WaitForChild("BallPitPrototype")

local function broadcastUI(player, color)
	local count = collectedCount[player] and collectedCount[player][color] or 0
	updateCollectUI:FireClient(player, color, count, config.TOOL_CAPACITY)
end

local function initPlayer(player)
	collected[player], collectedCount[player] = {}, {}
	for color in pairs(colorToTool) do
		collected[player][color] = {}
		collectedCount[player][color] = 0
	end
end
local function cleanupPlayer(player)
	playerBall[player] = nil; lastCollectTime[player] = nil
	collected[player] = nil; collectedCount[player] = nil
end
local function clearPlayerBall(player, ball)
	if playerBall[player] == ball then playerBall[player] = nil end
end

local function doCollect(ball, player)
	ball.Transparency = 1; ball.CanCollide = false; ball.Anchored = true
	ball:SetAttribute("Collecting", nil)
	ball.Position = HIDE_POS
	local color = ball:GetAttribute(config.BALL_COLOR_ATTR)
	if color then
		table.insert(collected[player][color], ball)
		collectedCount[player][color] += 1
	end
	syncSuction:FireAllClients(ball)
	if player then
		playCollectSound:FireClient(player)
		lastCollectTime[player] = os.clock()
		if color then broadcastUI(player, color) end
	end
end

local function isValidBall(ball, handlePos, toolColor)
	if not ball or not ball:IsA("BasePart") then return false end
	if not ball:GetAttribute(config.BALL_COLOR_ATTR) then return false end
	if ball:GetAttribute("Collecting") then return false end
	if ball.Transparency == 1 or not ball.Parent then return false end
	if ball:GetAttribute(config.BALL_COLOR_ATTR) ~= toolColor then return false end
	if (ball.Position - handlePos).Magnitude > config.SUCTION_RADIUS + 3 then return false end
	return true
end

requestSuction.OnServerEvent:Connect(function(player, ball, handlePos, toolColor)
	if not ball or not handlePos or not toolColor then return end
	if not isValidBall(ball, handlePos, toolColor) then return end
	if playerBall[player] then return end
	local count = collectedCount[player] and collectedCount[player][toolColor] or 0
	if count >= config.TOOL_CAPACITY then return end
	local character = player.Character
	if not character then return end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool.Handle then return end
	if tool:GetAttribute(config.TOOL_COLOR_ATTR) ~= toolColor then return end
	ball:SetAttribute("Collecting", true)
	ball.Anchored = true; ball.CanCollide = false
	suctioning[ball] = { handle = tool.Handle, player = player, arrived = false }
	playerBall[player] = ball
	suctionCount += 1
end)

-- 吸附飞行(直线、全程锚定)
RunService.Heartbeat:Connect(function(dt)
	if suctionCount == 0 then return end
	local now = os.clock()
	local toRemove = {}
	for ball, data in pairs(suctioning) do
		local handle, player = data.handle, data.player
		if not ball or not ball.Parent then
			toRemove[ball] = true; clearPlayerBall(player, ball); continue
		end
		if not handle or not handle.Parent then
			toRemove[ball] = true; ball:SetAttribute("Collecting", nil)
			clearPlayerBall(player, ball); continue
		end
		if data.arrived then
			local last = lastCollectTime[player] or 0
			if now - last >= config.COLLECT_COOLDOWN then
				toRemove[ball] = true; clearPlayerBall(player, ball)
				doCollect(ball, player)
			else
				ball.Position = handle.Position
			end
			continue
		end
		local toTarget = handle.Position - ball.Position
		local dist = toTarget.Magnitude
		if dist <= config.COLLECT_DISTANCE then
			ball.Position = handle.Position; data.arrived = true
		else
			ball.Position += toTarget.Unit * math.min(config.SUCTION_SPEED * dt, dist)
		end
	end
	for ball in pairs(toRemove) do suctioning[ball] = nil; suctionCount -= 1 end
end)

-- 存放飞行
RunService.Heartbeat:Connect(function(dt)
	if depositingCount == 0 then return end
	local toRemove = {}
	for ball, d in pairs(depositing) do
		if not ball or not ball.Parent then toRemove[ball] = true; continue end
		local dist = (d.target - ball.Position).Magnitude
		if dist <= 0.5 then
			ball.Position = d.landing
			ball.Parent = depositedBin      -- 移出球池,客户端扫描无法再吸它
			toRemove[ball] = true
		else
			ball.Position += (d.target - ball.Position).Unit * math.min(config.DEPOSIT_SPEED * dt, dist)
		end
	end
	for ball in pairs(toRemove) do depositing[ball] = nil; depositingCount -= 1 end
end)

-- 存放触发。注意事件签名 prompt 在前!
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local stationPart = prompt.Parent
	if not stationPart or not stationPart:IsA("BasePart") then return end
	local color = config.STATION_COLORS[stationPart.Name]
	if not color then return end
	if not collected[player] then return end
	local list = collected[player][color]
	if not list or #list == 0 then return end
	depositingFlag[player] = depositingFlag[player] or {}
	if depositingFlag[player][color] then return end
	depositingFlag[player][color] = true

	local character = player.Character
	local handle = character and character:FindFirstChildOfClass("Tool") and character:FindFirstChildOfClass("Tool").Handle or nil
	local startPos = handle and handle.Position or (character and character:GetPivot().Position or stationPart.Position)
	local stationPos = stationPart.Position
	local count = #list
	local balls = {}
	for i = 1, count do balls[i] = list[i] end
	table.clear(list)
	collectedCount[player][color] = 0

	for i = 1, count do
		local ball = balls[i]
		if not ball or not ball.Parent then continue end
		local idx = i - 1
		task.delay(idx * config.DEPOSIT_STAGGER, function()
			if not ball or not ball.Parent then return end
			ball.Anchored = true; ball.CanCollide = false
			ball.Position = startPos
			ball.Parent = depositedBin
			ball.Transparency = 0
			local offset = Vector3.new((idx % 5) * 0.3 - 0.6, 0.4 + math.floor(idx / 5) * 0.35, math.floor(idx / 5) * 0.2 - 0.3)
			local landing = stationPos + offset
			depositing[ball] = { target = landing, landing = landing }
			depositingCount += 1
		end)
	end

	task.delay(count * config.DEPOSIT_STAGGER + 0.2, function()
		stationPart:SetAttribute("StoredCount", (stationPart:GetAttribute("StoredCount") or 0) + count)
		if depositingFlag[player] then depositingFlag[player][color] = nil end
		if player then broadcastUI(player, color) end
	end)
end)

Players.PlayerAdded:Connect(function(player)
	initPlayer(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		for color in pairs(collected[player]) do broadcastUI(player, color) end
	end)
end)
for _, player in ipairs(Players:GetPlayers()) do initPlayer(player) end
Players.PlayerRemoving:Connect(cleanupPlayer)
```

### 3) SuctionClient(StarterPlayer > StarterPlayerScripts)

```lua
-- SuctionClient —— 扫描吸附 + 容量 UI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("SuctionRemotes")
local requestSuction = remotes:WaitForChild("RequestSuction")
local playCollectSound = remotes:WaitForChild("PlayCollectSound")
local updateCollectUI = remotes:WaitForChild("UpdateCollectUI")
local config = require(ReplicatedStorage:WaitForChild("SuctionConfig"))

local pool = workspace:WaitForChild("BallPitPrototype")
local ballPool = pool:WaitForChild("BallPool")

local function getEquippedTool()
	local character = player.Character
	if not character then return nil end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then return child end
	end
	return nil
end

-- UI(运行时生成,顶部居中计数 + 颜色圆点)
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CollectCountUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Name = "Bg"
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bg.BackgroundTransparency = 0.45
bg.AnchorPoint = Vector2.new(0.5, 0)
bg.Position = UDim2.new(0.5, 0, 0, 10)
bg.Size = UDim2.new(0, 210, 0, 48)
bg.Parent = screenGui
local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(0, 12); bgCorner.Parent = bg

local label = Instance.new("TextLabel")
label.Name = "CountLabel"
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 28
label.TextColor3 = Color3.new(1, 1, 1)
label.Text = "--/--"
label.Size = UDim2.new(1, 0, 1, 0)
label.Position = UDim2.new(0, 36, 0, 0)
label.ZIndex = 10
label.Parent = bg

local colorDot = Instance.new("Frame")
colorDot.Name = "ColorDot"
colorDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
colorDot.Position = UDim2.new(0, 8, 0.5, -10)
colorDot.Size = UDim2.new(0, 20, 0, 20)
colorDot.Parent = bg
local dotCorner = Instance.new("UICorner"); dotCorner.CornerRadius = UDim.new(1, 0); dotCorner.Parent = colorDot

local counts = {}
for color in pairs(config.COLOR_VALUES) do counts[color] = 0 end
local capacity = config.TOOL_CAPACITY

local function updateUI()
	local tool = getEquippedTool()
	local color = tool and tool:GetAttribute(config.TOOL_COLOR_ATTR) or nil
	if color then
		local c = counts[color] or 0
		label.Text = string.format("%d/%d", c, capacity)
		colorDot.BackgroundColor3 = config.COLOR_VALUES[color] or Color3.new(1, 1, 1)
	else
		label.Text = "--/--"
		colorDot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	end
end

updateCollectUI.OnClientEvent:Connect(function(color, count)
	if counts[color] ~= nil then counts[color] = count; updateUI() end
end)

local collectSound = Instance.new("Sound")
collectSound.SoundId = "rbxassetid://128062463831151"  -- 替换为自己的音效
collectSound.Volume = 0.5
collectSound.Parent = playerGui

local lastEquippedName = ""
task.spawn(function()
	while true do
		local tool = getEquippedTool()
		local name = tool and tool.Name or ""
		if name ~= lastEquippedName then lastEquippedName = name; updateUI() end
		task.wait(0.1)
	end
end)

-- 只扫球池,已存放到池外的展示球不会被回收
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { ballPool }

local scanTimer = 0
RunService.Heartbeat:Connect(function(dt)
	scanTimer += dt
	if scanTimer < config.SCAN_INTERVAL then return end
	scanTimer = 0
	local tool = getEquippedTool()
	if not tool or not tool.Handle then return end
	local toolColor = tool:GetAttribute(config.TOOL_COLOR_ATTR)
	if not toolColor then return end
	if (counts[toolColor] or 0) >= capacity then return end  -- 本地满容量拦截(双保险)

	local parts = workspace:GetPartBoundsInRadius(tool.Handle.Position, config.SUCTION_RADIUS, params)
	local batch = 0
	for _, ball in ipairs(parts) do
		if batch >= config.MAX_SUCTION_BATCH then break end
		if ball:GetAttribute(config.BALL_COLOR_ATTR) ~= toolColor then continue end
		if ball.Transparency == 1 then continue end
		if ball:GetAttribute("Collecting") then continue end
		requestSuction:FireServer(ball, tool.Handle.Position, toolColor)
		batch += 1
	end
end)

-- 服务器确认后本地立即隐藏
remotes.SyncSuction.OnClientEvent:Connect(function(ball)
	if ball and ball:IsA("BasePart") then
		ball.Transparency = 1; ball.CanCollide = false
	end
end)

playCollectSound.OnClientEvent:Connect(function()
	if collectSound then collectSound:Stop(); collectSound:Play() end
end)
```

## 六、调参指南

| 想改 | 参数 |
|---|---|
| 吸附范围/手感 | `SUCTION_RADIUS`(默认 20 已偏大,若池小先调小)、`SUCTION_SPEED`、`COLLECT_COOLDOWN` |
| 工具容量 | `TOOL_CAPACITY`(客户端 UI 与服务器校验都会跟随) |
| 存放手感 | `DEPOSIT_SPEED`、`DEPOSIT_STAGGER`(越小堆叠起飞越顺滑)、`DEPOSIT_RADIUS` |
| 网络压力 | `SCAN_INTERVAL` 调大、`MAX_SUCTION_BATCH` 保持 1、`COLLECT_COOLDOWN` 调大 |
| 增减颜色 | 改 `TOOL_COLORS`/`STATION_COLORS`/`COLOR_VALUES` 三张表 + 场景里对应球/工具/站台 |
| 球的材质/形状 | 球可为 `Part.Shape=Ball` 或换 MeshPart,只要带 `BallColor` 属性即可 |

## 七、验证清单(Playtest)

1. 手持红 Tool 靠近红球 → 球被直线吸向 Handle,到手后隐藏、计数 +1,显示 `x/25`。
2. 吸附途中切空手/换工具 → 在途球逻辑不报错、不卡死(服务器 handle 丢失会清理)。
3. 某色收集到 25 → 客户端不再发起、服务器也拒绝;换色工具不受影响。
4. 走到红站台按 E → 球逐颗从 Handle 飞向站台、堆叠成形,计数归 0。
5. 存放中的球不会被再次吸附(已移出 BallPool → 客户端扫不到)。
6. 重生(CharacterAdded)后 UI 计数仍同步显示。
7. 打开 Studio 输出无报错;注意 `ProximityPromptService.PromptTriggered` 参数顺序是 `(prompt, player)`。

## 八、易踩的坑(源自原型复盘)

- **遗留死 Remote**:原型曾在 `SuctionRemotes` 里声明 `FrameMoved`、`DepositRequest`,但从未使用(存放走 ProximityPromptService)。模板已剔除;建新系统时只建真正用到的 Remote。
- **SUCTION_RADIUS 偏大**:原型为 20,而池体仅 12×12,等于站池边能吸全池。按池尺寸缩到 ~6–10 更有玩法梯度。
- **必须把已展示球移出球池容器**:客户端用 `FilterDescendantsInstances = { BallPool }` 做过滤,展示球若不挪出 `BallPool` 会被再次吸走。这是"存放动画"正确性的关键。
- **服务器才是权威**:容量与冷却在客户端拦截只是体验优化,必须在服务器再校验一次(模板已做双保险)。
- **无存档**:状态纯内存;要做跨会话/跨服请接入 ProfileService,并在 `cleanupPlayer` 处落盘。

