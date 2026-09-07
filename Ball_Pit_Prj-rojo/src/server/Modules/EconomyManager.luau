--!strict
-- EconomyManager —— 经济系统(服务器权威)
-- Economic system.md:
--   每颗入库球 = 1 金币;倒球入库时发放,CoinText 实时 +1。
--   金币为跨局资源:服务器内存缓存 + DataStore 落盘(PlayerRemoving/BindToClose/定时)。
-- 注:MVP 用 DataStoreService + 简单 key;生产多服建议换 ProfileService(会话锁)。
--   DataStore 读写一律 pcall + 重试。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local UpdateCoins = Shared:WaitForChild("Remotes"):WaitForChild("UpdateCoins") :: RemoteEvent

local store = DataStoreService:GetDataStore(EconomyConfig.DATA_STORE_NAME)

local MAX_RETRIES = 3
local RETRY_DELAY = 1

-- [Player] = coins 当前内存值
local coins: { [Player]: number } = {}
-- 是否已从 DataStore 载入(避免未载入就保存覆盖)
local loaded: { [Player]: boolean } = {}

local EconomyManager = {}

local function getKey(player: Player): string
	return "Player_" .. player.UserId
end

local function broadcast(player: Player)
	if loaded[player] then
		UpdateCoins:FireClient(player, coins[player] or EconomyConfig.DEFAULT_COINS)
	end
end

-- ---------- DataStore ----------

local function loadCoins(player: Player): number?
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(function()
			return store:GetAsync(getKey(player))
		end)
		if ok then
			return result
		end
		warn("[EconomyManager] 加载失败(" .. attempt .. "/" .. MAX_RETRIES .. "): " .. tostring(result))
		if attempt < MAX_RETRIES then
			task.wait(RETRY_DELAY * attempt)
		end
	end
	return nil
end

local function saveCoins(player: Player): boolean
	local value = coins[player]
	if value == nil then
		return false
	end
	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			store:SetAsync(getKey(player), value)
		end)
		if ok then
			return true
		end
		warn("[EconomyManager] 保存失败(" .. attempt .. "/" .. MAX_RETRIES .. "): " .. tostring(err))
		if attempt < MAX_RETRIES then
			task.wait(RETRY_DELAY * attempt)
		end
	end
	return false
end

-- ---------- 生命周期 ----------

function EconomyManager.setupPlayer(player: Player)
	coins[player] = EconomyConfig.DEFAULT_COINS
	loaded[player] = false

	local data = loadCoins(player)
	if data ~= nil and type(data) == "number" then
		coins[player] = data
	end
	loaded[player] = true
	broadcast(player)

	-- 角色就绪后重发一次(客户端 PlayerGui 可能刚生成)
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

function EconomyManager.cleanupPlayer(player: Player)
	saveCoins(player)
	coins[player] = nil
	loaded[player] = nil
end

-- ---------- 查询/操作 ----------

function EconomyManager.getCoins(player: Player): number
	return coins[player] or EconomyConfig.DEFAULT_COINS
end

-- 增加金币(倒球入库每颗调用一次),广播 UI
function EconomyManager.addCoins(player: Player, amount: number)
	assert(type(amount) == "number" and amount > 0)
	coins[player] = (coins[player] or EconomyConfig.DEFAULT_COINS) + amount
	broadcast(player)
end

function EconomyManager.init()
	Players.PlayerAdded:Connect(function(player: Player)
		EconomyManager.setupPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		EconomyManager.cleanupPlayer(player)
	end)

	-- 服务器关停:落盘所有人
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(function()
				saveCoins(player)
			end)
		end
		task.wait(2)
	end)

	-- 处理已在线玩家(Studio 重载)
	for _, player in Players:GetPlayers() do
		task.spawn(EconomyManager.setupPlayer, player)
	end
end

return EconomyManager