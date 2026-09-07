--!strict
-- CoinFxClient —— 金币增长 UI 动效(纯客户端)
-- 触发:UpdateCoins 广播且金币数比上次增长时。
-- 动效:
--   1. CoinLable(ImageLabel)的 UIScale:0.05s 1→1.1,再 0.05s →1
--   2. 在 CoinLable 周围生成多个副本 ImageLabel,由小到大涌向其中心,重合后移除

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local UpdateCoins = Remotes:WaitForChild("UpdateCoins") :: RemoteEvent

local COIN_IMAGE = "rbxassetid://13249575568"
local BURST_COUNT = 8          -- 涌向中心的副本数
local BURST_DISTANCE = 90      -- 副本起始离中心距离(px)
local BURST_DURATION = 0.3     -- 副本涌向时长(s)
local PULSE_GROW = 1.1
local PULSE_HALF = 0.05

local lastCoins: number? = nil

-- 动态定位 UI(重生后引用会失效,每次重新找)
local function getCoinUI(): (ScreenGui?, ImageLabel?, TextLabel?)
	local screenGui = playerGui:FindFirstChild("ScreenGui")
	local coinsFrame = screenGui and screenGui:FindFirstChild("Coins")
	local icon = coinsFrame and coinsFrame:FindFirstChild("CoinLable")
	local text = coinsFrame and coinsFrame:FindFirstChild("CoinText")
	return screenGui :: ScreenGui?, icon :: ImageLabel?, text :: TextLabel?
end

-- 等 UI 完成布局(至少渲染一帧),保证 AbsolutePosition 有效
local function ensureLayout(icon: ImageLabel)
	local waited = 0
	while waited < 2 do
		if icon.AbsoluteSize.X > 1 and icon.AbsoluteSize.Y > 1 then
			return
		end
		RunService.RenderStepped:Wait()
		waited += 0.016
	end
end

-- UIScale 脉冲:1 → 1.1(0.05s)→ 1(0.05s)
local function playPulse(icon: ImageLabel)
	local uiscale = icon:FindFirstChildOfClass("UIScale")
	if not uiscale then
		uiscale = Instance.new("UIScale")
		uiscale.Parent = icon
	end
	uiscale.Scale = 1
	local grow = TweenService:Create(uiscale, TweenInfo.new(PULSE_HALF, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = PULSE_GROW,
	})
	local shrink = TweenService:Create(uiscale, TweenInfo.new(PULSE_HALF, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 1,
	})
	grow:Play()
	grow.Completed:Connect(function()
		shrink:Play()
	end)
end

-- 副本从图标左上方向涌向中心,重合后移除
local function playBurst(screenGui: ScreenGui, icon: ImageLabel)
	local center = icon.AbsolutePosition + icon.AbsoluteSize / 2
	local targetSize = icon.AbsoluteSize
	local startSize = targetSize * 0.3

	-- 起点全部落在中心左上方的扇形区域(方向朝左上方)
	local spreadAngle = math.rad(30) -- 扇形半宽
	local baseAngle = math.pi * 1.25 -- 指向左上(cos<0, sin<0)

	for i = 1, BURST_COUNT do
		local offsetAngle = (math.random() - 0.5) * 2 * spreadAngle
		local angle = baseAngle + offsetAngle
		local dir = Vector2.new(math.cos(angle), math.sin(angle))
		local dist = BURST_DISTANCE * (0.6 + math.random() * 0.8)
		local startPos = center + dir * dist

		local copy = Instance.new("ImageLabel")
		copy.Name = "CoinBurst"
		copy.Image = COIN_IMAGE
		copy.BackgroundTransparency = 1
		copy.AnchorPoint = Vector2.new(0.5, 0.5)
		copy.Size = UDim2.fromOffset(startSize.X, startSize.Y)
		copy.Position = UDim2.fromOffset(startPos.X, startPos.Y)
		copy.ZIndex = icon.ZIndex
		copy.Parent = screenGui

		local tween = TweenService:Create(copy, TweenInfo.new(BURST_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(center.X, center.Y),
			Size = UDim2.fromOffset(targetSize.X, targetSize.Y),
		})
		tween:Play()
		tween.Completed:Connect(function()
			copy:Destroy()
		end)
	end
end

-- 触发整段动效
local function playCoinGain()
	local screenGui, icon = getCoinUI()
	if not screenGui or not icon then
		return
	end
	ensureLayout(icon)
	playPulse(icon)
	playBurst(screenGui, icon)
end

-- 监听金币更新:只有"增长"才播放
UpdateCoins.OnClientEvent:Connect(function(coins: number)
	if typeof(coins) ~= "number" then
		return
	end
	if lastCoins ~= nil and coins > lastCoins then
		playCoinGain()
	end
	lastCoins = coins
end)