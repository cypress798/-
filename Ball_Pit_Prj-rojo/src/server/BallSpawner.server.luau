--!strict
-- BallSpawner —— 开局把 ReplicatedStorage.BallPool(模板源)的球克隆到 Workspace 参与收集
-- 依据 Ball.md + 用户要求:克隆球为"可动"——Anchored=false、CanCollide=true,
-- 且放入 CollisionGroup "Balls"(组内球与球不碰撞,但与 Default 地面/池壁碰撞可滚动)。
-- 物理负载通过组内无碰撞显著降低。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local SuctionConfig = require(Config:WaitForChild("SuctionConfig"))

-- 运行时注册碰撞组(幂等)
local function ensureCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Balls")
		PhysicsService:CollisionGroupSetCollidable("Balls", "Balls", false)   -- 球与球不碰撞
		PhysicsService:CollisionGroupSetCollidable("Balls", "Default", true)  -- 球与地面/池壁可碰撞
	end)
end
ensureCollisionGroups()

-- 解析源路径(如 "ReplicatedStorage.BallPool")
local function resolvePath(path: string): Instance?
	local seg = string.split(path, ".")
	local cur: Instance? = game
	for _, s in seg do
		if s ~= "game" and cur then
			cur = cur:FindFirstChild(s)
			if not cur then
				return nil
			end
		end
	end
	return cur
end

local source = resolvePath(SuctionConfig.SOURCE_POOL)

-- 目标容器(客户端空间查询过滤对象)
local poolFolder = Workspace:FindFirstChild(SuctionConfig.WORKSPACE_POOL_NAME)
if not poolFolder or not poolFolder:IsA("Folder") then
	if poolFolder then
		poolFolder:Destroy()
	end
	poolFolder = Instance.new("Folder")
	poolFolder.Name = SuctionConfig.WORKSPACE_POOL_NAME
	poolFolder.Parent = Workspace
end

local existingCount = 0
for _, child in poolFolder:GetChildren() do
	if child:IsA("BasePart") then
		existingCount += 1
	end
end

if existingCount > 0 then
	print(string.format("[BallSpawner] 球池已存在 %d 颗,跳过克隆", existingCount))
else
	if not source then
		warn("[BallSpawner] 未找到模板源 " .. SuctionConfig.SOURCE_POOL)
	else
		local spawned = 0
		for _, ball in source:GetChildren() do
			if ball:IsA("BasePart") then
				local clone = ball:Clone()
				clone.Anchored = false      -- 可动
				clone.CanCollide = true     -- 可与地面/池壁碰撞滚动
				clone.CollisionGroup = "Balls" -- 组内球与球无碰撞
				clone.Parent = poolFolder
				spawned += 1
			end
		end
		print(string.format("[BallSpawner] 克隆 %d 颗可动球到 Workspace.%s", spawned, SuctionConfig.WORKSPACE_POOL_NAME))
	end
end