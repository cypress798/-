--!strict
-- EconomyClient —— 更新金币 UI(StarterGui.ScreenGui.Coins.CoinText)
-- 服务器通过 UpdateCoins(coins) 广播,本脚本把值写入 CoinText。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local UpdateCoins = Remotes:WaitForChild("UpdateCoins") :: RemoteEvent

local function refreshCoins(coins: number)
	local screenGui = playerGui:FindFirstChild("ScreenGui")
	local coinsFrame = screenGui and screenGui:FindFirstChild("Coins")
	local coinText = coinsFrame and coinsFrame:FindFirstChild("CoinText")
	if coinText and coinText:IsA("TextLabel") then
		coinText.Text = tostring(coins)
	end
end

UpdateCoins.OnClientEvent:Connect(function(coins: number)
	refreshCoins(coins)
end)