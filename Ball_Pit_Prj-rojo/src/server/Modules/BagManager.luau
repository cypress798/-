--!strict
-- BagManager —— 背包状态(服务器权威)
-- 依据 Bag.md:
--   每玩家一个背包 { count 当前收集球数, capacity 容量 },初始容量 25;
--   容量服务端持有,后续升级系统扩展(甚至"无限");
--   不同颜色球共存同一背包,防止中途换桶丢球。
-- 状态变更后通过 UpdateBag RemoteEvent 广播给客户端更新 UI(Bag/Num/TotalNum)。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BagConfig = require(Shared:WaitForChild("Config"):WaitForChild("BagConfig"))
local UpdateBag = Shared:WaitForChild("Remotes"):WaitForChild("UpdateBag") :: RemoteEvent

-- [Player] = { count: number, capacity: number }
local bags: { [Player]: { count: number, capacity: number } } = {}

local BagManager = {}

local function getBag(player: Player): { count: number, capacity: number }
	local bag = bags[player]
	if not bag then
		bag = { count = 0, capacity = BagConfig.INITIAL_CAPACITY }
		bags[player] = bag
	end
	return bag
end

local function broadcast(player: Player)
	local bag = bags[player]
	if not bag then
		return
	end
	UpdateBag:FireClient(player, bag.count, bag.capacity)
end

-- 初始化玩家(懒建),并在一段延迟后(角色就绪)同步一次 UI
function BagManager.setupPlayer(player: Player)
	getBag(player)
	-- 等角色生成后再广播,确保客户端 PlayerGui 存在
	player.CharacterAdded:Connect(function(_character: Model)
		task.delay(0.5, function()
			broadcast(player)
		end)
	end)
	if player.Character then
		task.delay(0.5, function()
			broadcast(player)
		end)
	end
end

function BagManager.cleanupPlayer(player: Player)
	bags[player] = nil
end

-- 查询
function BagManager.getCount(player: Player): number
	return getBag(player).count
end

function BagManager.getCapacity(player: Player): number
	return getBag(player).capacity
end

-- 增加容量(供后续升级系统调用;若为 math.huge 则为"无限")
function BagManager.setCapacity(player: Player, newCapacity: number)
	getBag(player).capacity = newCapacity
	broadcast(player)
end

-- 尝试加入一颗球:未满则 count+1 并广播,返回 true;已满返回 false
function BagManager.tryAddBall(player: Player): boolean
	local bag = getBag(player)
	if bag.count >= bag.capacity then
		return false
	end
	bag.count += 1
	broadcast(player)
	return true
end

-- 清空背包(倒球入库后调用),并广播 UI
function BagManager.clearBag(player: Player)
	local bag = getBag(player)
	bag.count = 0
	broadcast(player)
end

-- 启动入口:连接玩家生命周期(由 BagServer Script 调用一次)
function BagManager.init()
	Players.PlayerAdded:Connect(function(player: Player)
		BagManager.setupPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		BagManager.cleanupPlayer(player)
	end)
	-- 处理已在线玩家(Studio 重载)
	for _, player in Players:GetPlayers() do
		task.spawn(BagManager.setupPlayer, player)
	end
end

return BagManager