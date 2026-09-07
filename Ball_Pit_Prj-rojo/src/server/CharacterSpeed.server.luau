--!strict
-- 角色生成时速度翻倍(默认 16 -> 32),服务器权威
local Players = game:GetService("Players")

local function applySpeed(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = humanoid.WalkSpeed * 2
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(applySpeed)
	if player.Character then
		applySpeed(player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
