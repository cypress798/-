--!strict
-- DepositServer —— 倒球入库(服务器权威)
-- BallPool.md + Economic system.md:
--   Workspace.BallPoolp 下 4 个颜色 Pool = 存放池;走到对应池按 E → 当前工具叠球逐颗飞入池中。
--   球保留入库飞行动画,到位后销毁并转金币(每颗 = EconomyConfig.COINS_PER_BALL);
--   池展示牌计数(累计入库球数)仍实时刷新;期间禁用收集;倒球完成后清空背包。
--   金币为跨局资源,由 EconomyManager 存 DataStore。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Modules = script.Parent:WaitForChild("Modules")
local SuctionConfig = require(Config:WaitForChild("SuctionConfig"))
local BagConfig = require(Config:WaitForChild("BagConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local BagManager = require(Modules:WaitForChild("BagManager"))
local DepositCoordinator = require(Modules:WaitForChild("DepositCoordinator"))
local EconomyManager = require(Modules:WaitForChild("EconomyManager"))

local poolFolder = Workspace:WaitForChild("BallPoolp")

-- 池名 → 颜色
local POOL_COLORS: { [string]: string } = {
	RedPool = "red",
	BluePool = "blue",
	YellowPool = "yellow",
	GreenPool = "green",
}

-- 倒球飞行参数(提速,入库更干脆)
local DEPOSIT_SPEED = 220
local ARRIVE_DISTANCE = 0.5
local DEPOSITED_NAME = "DepositedBalls"

-- 入库飞行表: ball -> { player, target, pool }
local flights: { [BasePart]: { player: Player, target: CFrame, pool: BasePart } } = {}
-- 每玩家飞行状态
local playerFlightState: { [Player]: { total: number, done: number, finalized: boolean } } = {}
-- 每池已存放球数(服务器权威)
local poolStoredCount: { [BasePart]: number } = {}

local depositedFolder = Workspace:FindFirstChild(DEPOSITED_NAME)
if not depositedFolder then
	depositedFolder = Instance.new("Folder")
	depositedFolder.Name = DEPOSITED_NAME
	depositedFolder.Parent = Workspace
end

local function getEquippedTool(player: Player): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Tool") :: Tool?
end

-- 收集工具上叠的实体球(标记 StackedBall,且在工具下)
local function getStackedBalls(tool: Tool): { BasePart }
	local list: { BasePart } = {}
	for _, child in tool:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("StackedBall") then
			table.insert(list, child)
		end
	end
	-- 自上而下(高 Y 先飞)
	table.sort(list, function(a: BasePart, b: BasePart)
		return a.Position.Y > b.Position.Y
	end)
	return list
end

-- 定位池展示牌 TextLabel: 池 > Part > BillboardGui > Frame > TextLabel
local function getPoolLabel(pool: BasePart): TextLabel?
	local labelPart = pool:FindFirstChild("Part")
	if not labelPart then
		return nil
	end
	local billboard = labelPart:FindFirstChildOfClass("BillboardGui")
	if not billboard then
		return nil
	end
	local frame = billboard:FindFirstChild("Frame")
	if not frame then
		return nil
	end
	local label = frame:FindFirstChildOfClass("TextLabel")
	return label :: TextLabel?
end

-- 刷新某池展示牌文本
local function refreshPoolLabel(pool: BasePart)
	local label = getPoolLabel(pool)
	if label then
		label.Text = tostring(poolStoredCount[pool] or 0)
	end
end

-- 生成池面上的落点
local function computeLanding(pool: BasePart, index: number): CFrame
	local halfX = (pool.Size.X / 2) - 0.9
	local halfZ = (pool.Size.Z / 2) - 0.9
	local col = index % 6
	local row = math.floor(index / 6) % 4
	local layer = math.floor(index / 24)
	local ox = (col - 2.5) * 1.35
	local oz = (row - 1.5) * 1.5
	local oy = BagConfig.STACK_GAP * layer
	if math.abs(ox) > halfX or math.abs(oz) > halfZ then
		return CFrame.new(
			pool.Position + Vector3.new(
				math.random() * (halfX * 2) - halfX,
				pool.Size.Y / 2 + BagConfig.BALL_SIZE / 2 + 0.1 + oy,
				math.random() * (halfZ * 2) - halfZ
			)
		)
	end
	return CFrame.new(
		pool.Position + Vector3.new(
			ox,
			pool.Size.Y / 2 + BagConfig.BALL_SIZE / 2 + 0.05 + oy,
			oz
		)
	)
end

local function detachStackedBall(ball: BasePart)
	-- 解焊
	for _, weld in ball:GetChildren() do
		if weld:IsA("WeldConstraint") or weld:IsA("Weld") then
			weld:Destroy()
		end
	end
	ball:SetAttribute("StackedBall", nil)
	ball:SetAttribute("Collecting", nil)
	ball.Anchored = false
	ball.CanCollide = false
	ball.Massless = true
	ball.Transparency = 0
	ball.Parent = depositedFolder
end

local function startDeposit(player: Player, pool: BasePart)
	local tool = getEquippedTool(player)
	if not tool then
		return
	end
	local toolColor = tool:GetAttribute(SuctionConfig.TOOL_COLOR_ATTR)
	local poolColor = POOL_COLORS[pool.Name]
	if not poolColor or toolColor ~= poolColor then
		return
	end
	local stacked = getStackedBalls(tool)
	local total = #stacked
	if total == 0 then
		return
	end

	-- 标记倒球中(禁收集)并广播;背包清空
	DepositCoordinator.setDepositing(player, true)
	BagManager.clearBag(player)

	-- 一次性结算:展示牌计数 += total,金币 += total(即时显示,不等动画)
	poolStoredCount[pool] = (poolStoredCount[pool] or 0) + total
	refreshPoolLabel(pool)
	EconomyManager.addCoins(player, total * EconomyConfig.COINS_PER_BALL)

	local state = { total = total, done = 0, finalized = false }
	playerFlightState[player] = state

	for i, ball in stacked do
		detachStackedBall(ball)
		flights[ball] = { player = player, target = computeLanding(pool, i), pool = pool }
	end
end

local function finishDeposit(player: Player)
	local state = playerFlightState[player]
	if not state or state.finalized then
		return
	end
	state.finalized = true
	playerFlightState[player] = nil
	DepositCoordinator.setDepositing(player, false)
end

-- 每帧推进入库飞行
RunService.Heartbeat:Connect(function(dt: number)
	if next(flights) == nil then
		return
	end
	local toRemove: { BasePart } = {}
	for ball, data in flights do
		local target = data.target
		local toTarget = target.Position - ball.Position
		local dist = toTarget.Magnitude
		if dist <= ARRIVE_DISTANCE then
			-- 到位:完成落点表现后销毁(结算已在 startDeposit 一次性完成)
			ball.CFrame = target
			ball.Anchored = true
			ball.CanCollide = false
			table.insert(toRemove, ball)
			ball:Destroy()
			local state = playerFlightState[data.player]
			if state and not state.finalized then
				state.done += 1
				if state.done >= state.total then
					finishDeposit(data.player)
				end
			end
		else
			local move = math.min(DEPOSIT_SPEED * dt, dist)
			ball.Position += toTarget.Unit * move
		end
	end
	for _, ball in toRemove do
		flights[ball] = nil
	end
end)

-- 池子 E 触发
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if not player then
		return
	end
	local pool = prompt.Parent
	if not pool or not pool:IsA("BasePart") then
		return
	end
	if pool.Parent ~= poolFolder then
		return
	end
	if DepositCoordinator.isDepositing(player) then
		return
	end
	startDeposit(player, pool)
end)

-- 玩家离开清理
Players.PlayerRemoving:Connect(function(player: Player)
	DepositCoordinator.cleanupPlayer(player)
	playerFlightState[player] = nil
	for ball, data in flights do
		if data.player == player then
			flights[ball] = nil
			ball:Destroy()
		end
	end
end)

DepositCoordinator.init()

-- 初始化:把 4 个池展示牌文本设为当前计数(0)
for _, pool in poolFolder:GetChildren() do
	if pool:IsA("BasePart") and POOL_COLORS[pool.Name] then
		refreshPoolLabel(pool)
	end
end