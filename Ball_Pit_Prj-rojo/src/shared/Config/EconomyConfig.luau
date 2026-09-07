-- EconomyConfig —— 经济系统共享配置
-- Economic system.md:
--   1 球 = 1 金币(倒球入库时发放);UI: ScreenGui > Coins > CoinText 实时显示。
--   金币为跨局资源,存 DataStore(服务器权威,客户端仅显示)。

local EconomyConfig = {}

EconomyConfig.COINS_PER_BALL = 1        -- 每颗入库球转换的金币数
EconomyConfig.DATA_STORE_NAME = "PlayerCoins_v1"
EconomyConfig.DEFAULT_COINS = 0

-- UI 固定路径(StarterGui 预建,克隆到 PlayerGui)
EconomyConfig.UI_ROOT = "ScreenGui"
EconomyConfig.UI_COINS = "Coins"        -- Coins Frame
EconomyConfig.UI_TEXT = "CoinText"      -- 金币 TextLabel

return EconomyConfig
