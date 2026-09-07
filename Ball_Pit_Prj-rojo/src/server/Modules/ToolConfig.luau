-- ToolConfig —— 工具配置 + 构建函数(仅服务器使用)
-- 约定:
--   ToolType   : 工具大类("Bucket" = 桶)
--   ToolName   : 与 ReplicatedStorage.Tool / Workspace.Tool 下的模型名一致(如 "Redbucket")
--   Category   : 工具类别 1=初始工具 2=特殊工具 3=预留
--   BallColorCollect: 该工具能收集的球的颜色

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfig = {

	RedBucket = {
		ToolType = "Bucket",
		ToolName = "Redbucket",
		Category = 1,            -- 初始工具
		SuctionRange = 8,        -- 吸附范围（stud）
		SuctionSpeed = 0.3,      -- 单球吸附耗时（秒）
		SuctionRate = 1,         -- 同时吸附数量/秒
		ModelId = "rbxassetid://1234567890",
		BallColorCollect = "red",-- 收集球的颜色
	},
	BlueBucket = {
		ToolType = "Bucket",
		ToolName = "Bluebucket",
		Category = 1,            -- 初始工具
		SuctionRange = 8,
		SuctionSpeed = 0.3,
		SuctionRate = 1,
		ModelId = "rbxassetid://1234567890",
		BallColorCollect = "blue",
	},

	YellowBucket = {
		ToolType = "Bucket",
		ToolName = "Yellowbucket",
		Category = 1,            -- 初始工具
		SuctionRange = 8,
		SuctionSpeed = 0.3,
		SuctionRate = 1,
		ModelId = "rbxassetid://1234567890",
		BallColorCollect = "yellow",
	},

	GreenBucket = {
		ToolType = "Bucket",
		ToolName = "Greenbucket",
		Category = 1,            -- 初始工具
		SuctionRange = 8,
		SuctionSpeed = 0.3,
		SuctionRate = 1,
		ModelId = "rbxassetid://1234567890",
		BallColorCollect = "green",
	},
}

-- 按模型名(与 Workspace 桶名一致)查找工具配置
function ToolConfig.getByToolName(toolName)
	for _, cfg in ToolConfig do
		if type(cfg) == "table" and cfg.ToolName == toolName then
			return cfg
		end
	end
	return nil
end

-- 构建一个可装备的 Tool:直接克隆 ReplicatedStorage.Tool.<ToolName>(模板本身是 Tool 类,
-- 含 Handle + 桶身焊接),并写入 BallColorCollect / ToolType / Category 等属性。
-- toolName 非法或模板缺失则返回 nil。
function ToolConfig.buildTool(toolName)
	local cfg = ToolConfig.getByToolName(toolName)
	if not cfg then
		return nil
	end

	local toolFolder = ReplicatedStorage:FindFirstChild("Tool")
	local template = toolFolder and toolFolder:FindFirstChild(cfg.ToolName)
	if not template or not template:IsA("Tool") then
		warn(string.format("[ToolConfig] 缺少工具模板: ReplicatedStorage.Tool.%s (Tool)", cfg.ToolName))
		return nil
	end

	local tool = template:Clone()
	tool.Name = cfg.ToolName
	tool:SetAttribute("ToolType", cfg.ToolType)
	tool:SetAttribute("ToolName", cfg.ToolName)
	tool:SetAttribute("Category", cfg.Category)
	tool:SetAttribute("BallColorCollect", cfg.BallColorCollect)
	tool:SetAttribute("SuctionRange", cfg.SuctionRange)
	tool:SetAttribute("SuctionSpeed", cfg.SuctionSpeed)
	tool:SetAttribute("SuctionRate", cfg.SuctionRate)

	return tool
end

return ToolConfig
