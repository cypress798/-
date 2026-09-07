--!strict
-- SuctionServer —— 吸附收集(服务器权威)
-- 依据 Ball_Pit_SKILL.md + Bag.md:
--   球吸到工具 Handle 即"入背包"(BagManager 计数);收集球不在原地消失,
--   而是叠在当前桶 Handle 上方沿 y 轴逐颗叠高(随工具,焊到 Handle)。
--   背包满(当前数>=容量)则拒绝新吸附;倒球清空后续实现。
-- 客户端扫描同色球 → FireServer(ball) → 服务器校验 → Heartbeat 直线吸向 Handle → 到位入包+叠球。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Modules = script.Parent:WaitForChild("Modules")
local SuctionConfig = require(Config:WaitForChild("SuctionConfig"))
local BagConfig = require(Config:WaitForChild("BagConfig"))
local BagManager = require(Modules:WaitForChild("BagManager"))
local DepositCoordinator = require(Modules:WaitForChild("DepositCoordinator"))
local RequestSuction = Shared:WaitForChild("Remotes"):WaitForChild("RequestSuction") :: RemoteEvent

local poolFolder = Workspace:WaitForChild(SuctionConfig.WORKSPACE_POOL_NAME)

-- 吸附中集合: ball -> { player }
local suctioning: { [BasePart]: { player: Player } } = {}
-- 每玩家同时在途球(单球在途)
local playerBall: { [Player]: BasePart } = {}

local function isBallCollectable(ball: Instance): boolean
	if not ball:IsA("BasePart") then
		return false
	end
	if ball.Parent ~= poolFolder then
		return false
	end
	if not ball:GetAttribute(SuctionConfig.BALL_COLOR_ATTR) then
		return false
	end
	if suctioning[ball] then
		return false
	end
	if ball.Transparency >= 1 then
		return false
	end
	return true
end

-- 把球放回球池,并恢复"可动"物理状态(用户要求:球可滚动但球与球无碰撞)
local function restoreToPool(ball: BasePart)
	ball.Parent = poolFolder
	ball.Transparency = 0
	ball.Anchored = false
	ball.CanCollide = true
	ball.CollisionGroup = "Balls"
	ball.Massless = false
	ball:SetAttribute("Collecting", nil)
	ball:SetAttribute("StackedBall", nil)
end

-- 背包是否还有空间
local function bagHasSpace(player: Player): boolean
	return BagManager.getCount(player) < BagManager.getCapacity(player)
end

RequestSuction.OnServerEvent:Connect(function(player: Player, ball: Instance)
	-- 类型校验
	if typeof(ball) ~= "Instance" then
		return
	end
	-- 倒球中禁止收集
	if DepositCoordinator.isDepositing(player) then
		return
	end
	if not isBallCollectable(ball) then
		return
	end
	-- 每玩家单球在途
	if playerBall[player] then
		return
	end
	-- 背包满则拒收
	if not bagHasSpace(player) then
		return
	end

	-- 校验玩家角色与当前手持工具
	local character = player.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool:IsA("Tool") then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end
	-- 工具颜色必须与球颜色匹配
	local toolColor = tool:GetAttribute(SuctionConfig.TOOL_COLOR_ATTR)
	if typeof(toolColor) ~= "string" then
		return
	end
	local ballColor = ball:GetAttribute(SuctionConfig.BALL_COLOR_ATTR)
	if ballColor ~= toolColor then
		return
	end
	-- 距离防作弊:球需在吸附半径 + 3 内
	if (ball.Position - handle.Position).Magnitude > SuctionConfig.SUCTION_RADIUS + 3 then
		return
	end

	-- 锁定该球与玩家:吸附中临时锚定,服务器完全驱动位置(避免物理引擎拉扯)
	ball:SetAttribute("Collecting", true)
	ball.Anchored = true
	ball.CanCollide = false
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero
	suctioning[ball] = { player = player }
	playerBall[player] = ball
end)

-- 把到位的球叠到工具 Handle 上方第 n 层,焊到 Handle 使其随工具
local function stackBallOnTool(ball: BasePart, tool: Tool, n: number)
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return false
	end
	-- 从球池移出(避免客户端再扫到),随工具销毁而销毁
	ball.Parent = tool
	ball.Transparency = 0
	ball.CanCollide = false
	ball.Anchored = false
	ball.Massless = true
	ball:SetAttribute("StackedBall", true)
	-- y 轴逐颗叠高:第 1 颗在 Handle 上方 START_OFFSET,之后每颗再高 STACK_GAP
	local offsetY = BagConfig.STACK_START_OFFSET + (n - 1) * BagConfig.STACK_GAP
	ball.CFrame = handle.CFrame * CFrame.new(0, offsetY, 0)
	-- 焊到 Handle,玩家走动/转桶时球跟随
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = ball
	weld.Parent = ball
	return true
end

-- 每帧推进吸附
RunService.Heartbeat:Connect(function(dt: number)
	if next(suctioning) == nil then
		return
	end
	local toRemove: { BasePart } = {}
	for ball, data in suctioning do
		local player = data.player
		local character = player and player.Character
		if not character then
			restoreToPool(ball)
			playerBall[player] = nil
			table.insert(toRemove, ball)
			continue
		end
		-- 玩家开始倒球:取消在途球并放回球池(恢复可动)
		if DepositCoordinator.isDepositing(player) then
			restoreToPool(ball)
			playerBall[player] = nil
			table.insert(toRemove, ball)
			continue
		end
		local tool = character:FindFirstChildOfClass("Tool")
		local handle = tool and tool:FindFirstChild("Handle")
		if not tool or not tool:IsA("Tool") or not handle or not handle:IsA("BasePart") then
			restoreToPool(ball)
			playerBall[player] = nil
			table.insert(toRemove, ball)
			continue
		end

		local target = handle.Position
		local toTarget = target - ball.Position
		local dist = toTarget.Magnitude

		if dist <= SuctionConfig.COLLECT_DISTANCE then
			-- 收集:先 snap 到 Handle 中心 → 入背包 → 叠到桶口
			ball.Position = target
			if bagHasSpace(player) and BagManager.tryAddBall(player) then
				-- 叠球高度按当前工具已叠数量计算(换桶会重置,与视觉一致)
				local stacked = 0
				for _, child in tool:GetChildren() do
					if child:IsA("BasePart") and child:GetAttribute("StackedBall") then
						stacked += 1
					end
				end
				stackBallOnTool(ball, tool, stacked + 1)
			else
				-- 背包满了(竞态兜底):把球放回球池(恢复可动)
				restoreToPool(ball)
			end
			playerBall[player] = nil
			table.insert(toRemove, ball)
		else
			-- 直线飞向 Handle 实时位置(跟随手持移动)
			local move = math.min(SuctionConfig.SUCTION_SPEED * dt, dist)
			ball.Position += toTarget.Unit * move
		end
	end
	for _, ball in toRemove do
		ball:SetAttribute("Collecting", nil)
		suctioning[ball] = nil
	end
end)

-- 清理
Players.PlayerRemoving:Connect(function(player: Player)
	local ball = playerBall[player]
	if ball then
		restoreToPool(ball)
		suctioning[ball] = nil
		playerBall[player] = nil
	end
end)