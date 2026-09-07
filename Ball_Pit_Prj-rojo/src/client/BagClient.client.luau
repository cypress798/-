--!strict
-- BagClient —— 更新预建背包 UI(StarterGui.ScreenGui.Bag)
-- Bag.md: UI 为 ScreenGui 下 Bag;Num = 当前收集球数, TotalNum = 背包容量。
-- 服务器通过 UpdateBag(count, capacity) 广播;本脚本只负责把值写到 Num/TotalNum 文本。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local UpdateBag = Remotes:WaitForChild("UpdateBag") :: RemoteEvent

local function refreshLabels(count: number, capacity: number)
	local screenGui = playerGui:FindFirstChild("ScreenGui")
	local bag = screenGui and screenGui:FindFirstChild("Bag")
	if not bag then
		return
	end
	local numLabel = bag:FindFirstChild("Num")
	local totalLabel = bag:FindFirstChild("TotalNum")
	if numLabel and numLabel:IsA("TextLabel") then
		numLabel.Text = tostring(count)
	end
	if totalLabel and totalLabel:IsA("TextLabel") then
		totalLabel.Text = tostring(capacity)
	end
end

UpdateBag.OnClientEvent:Connect(function(count: number, capacity: number)
	refreshLabels(count, capacity)
end)