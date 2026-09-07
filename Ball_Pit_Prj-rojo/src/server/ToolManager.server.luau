--!strict
-- ToolManager —— 工具装备(服务器权威,单槽)
-- 规则(Tool.md + 用户澄清):
--   1. 玩家同一时间只能持有一把工具(单槽)
--   2. 出生/重生默认空手,不自动给工具
--   3. 靠近 Workspace.Tool 下的桶(切换站)按 E → 装备对应颜色工具(可反复切换)
--   4. 工具携带 BallColorCollect 属性,供吸附系统读取

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local ToolConfig = require(script.Parent:WaitForChild("Modules"):WaitForChild("ToolConfig"))

local WorkspaceToolFolder = workspace:WaitForChild("Tool")

local function removeCurrentTool(player: Player)
	local character = player.Character
	if not character then
		return
	end
	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end
end

local function equipTool(player: Player, toolName: string)
	local cfg = ToolConfig.getByToolName(toolName)
	if not cfg then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- 已持有同名工具则跳过,避免无谓重建
	local existing = character:FindFirstChild(toolName)
	if existing and existing:IsA("Tool") then
		return
	end

	-- 单槽:先卸下当前工具
	removeCurrentTool(player)

	local tool = ToolConfig.buildTool(toolName)
	if not tool then
		return
	end
	tool.Parent = character -- 挂在角色下即自动装备
end

-- 解析切换站对应的工具名:prompt 挂在 Workspace.Tool.<桶名>.model 上
local function getStationToolName(prompt: ProximityPrompt): string?
	local part = prompt.Parent
	if not part then
		return nil
	end
	local model = part.Parent
	if not model or model.Parent ~= WorkspaceToolFolder then
		return nil
	end
	if ToolConfig.getByToolName(model.Name) then
		return model.Name
	end
	return nil
end

-- 按 E(ProximityPrompt 触发)→ 装备/切换成对应颜色工具
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local toolName = getStationToolName(prompt)
	if toolName and player then
		equipTool(player, toolName)
	end
end)