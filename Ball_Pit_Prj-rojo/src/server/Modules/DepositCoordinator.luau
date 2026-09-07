--!strict
-- DepositCoordinator —— 倒球过程的共享协调状态(服务器)
-- 标记"玩家正在倒球",供 SuctionServer 拒收新的吸附请求;
-- 通过 DepositStatus RemoteEvent 广播给客户端,让客户端停发吸附请求。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local DepositStatus = Remotes:WaitForChild("DepositStatus") :: RemoteEvent

-- [Player] = true 表示正在倒球
local depositing: { [Player]: boolean } = {}

local DepositCoordinator = {}

function DepositCoordinator.isDepositing(player: Player): boolean
	return depositing[player] == true
end

-- 开始/结束倒球;结束时向客户端广播恢复收集
function DepositCoordinator.setDepositing(player: Player, flag: boolean)
	if flag then
		depositing[player] = true
	else
		depositing[player] = nil
	end
	DepositStatus:FireClient(player, flag)
end

function DepositCoordinator.cleanupPlayer(player: Player)
	depositing[player] = nil
end

-- 注册玩家生命周期清理(由 DepositServer 调 init)
function DepositCoordinator.init()
	Players.PlayerRemoving:Connect(function(player: Player)
		DepositCoordinator.cleanupPlayer(player)
	end)
end

return DepositCoordinator