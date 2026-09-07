--!strict
-- SuctionClient —— 扫描并请求吸附同色球
-- 依据 Ball_Pit_SKILL.md:客户端只做"空间扫描 + 发起请求",服务器权威裁决。
-- 本地缓存背包计数,满则停发(体验优化;服务器同样权威拒收)。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local SuctionConfig = require(Shared:WaitForChild("Config"):WaitForChild("SuctionConfig"))
local RequestSuction = Remotes:WaitForChild("RequestSuction") :: RemoteEvent
local UpdateBag = Remotes:WaitForChild("UpdateBag") :: RemoteEvent
local DepositStatus = Remotes:WaitForChild("DepositStatus") :: RemoteEvent

local player = Players.LocalPlayer
local poolFolder = Workspace:WaitForChild(SuctionConfig.WORKSPACE_POOL_NAME)

-- 本地背包计数(服务器广播)
local bagCount = 0
local bagCapacity = 25
UpdateBag.OnClientEvent:Connect(function(count: number, capacity: number)
	bagCount = count
	bagCapacity = capacity
end)

-- 倒球中:禁止扫描吸附
local depositing = false
DepositStatus.OnClientEvent:Connect(function(flag: boolean)
	depositing = flag
end)

-- 获取当前手持的工具
local function getEquippedTool(): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Tool") :: Tool?
end

-- 只扫球池容器(已移出/已隐藏的球不会被回收)
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { poolFolder }

local scanTimer = 0
RunService.Heartbeat:Connect(function(dt: number)
	scanTimer += dt
	if scanTimer < SuctionConfig.SCAN_INTERVAL then
		return
	end
	scanTimer = 0

	-- 倒球中不吸附
	if depositing then
		return
	end
	-- 背包已满则不再发起吸附
	if bagCount >= bagCapacity then
		return
	end

	local tool = getEquippedTool()
	if not tool then
		return
	end
	local toolColor = tool:GetAttribute(SuctionConfig.TOOL_COLOR_ATTR)
	if typeof(toolColor) ~= "string" then
		return
	end

	-- Handle 缺失则无法吸附
	local toolHandle = tool:FindFirstChild("Handle")
	if not toolHandle or not toolHandle:IsA("BasePart") then
		return
	end

	local parts = Workspace:GetPartBoundsInRadius(toolHandle.Position, SuctionConfig.SUCTION_RADIUS, params)
	local sent = 0
	for _, ball in parts do
		if sent >= SuctionConfig.MAX_SUCTION_BATCH then
			break
		end
		if ball:GetAttribute(SuctionConfig.BALL_COLOR_ATTR) ~= toolColor then
			continue
		end
		if ball.Transparency >= 1 then
			continue
		end
		if ball:GetAttribute("Collecting") then
			continue
		end
		RequestSuction:FireServer(ball)
		sent += 1
	end
end)