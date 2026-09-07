-- BagConfig —— 背包配置(双端共享常量)
-- 依据 Bag.md:
--   1. 初始容量 25,可扩展(后续升级系统增加,也有"无限")
--   2. 不同颜色的球都存入同一背包(防止中途换桶丢球)
--   3. UI: ScreenGui 下 Bag,Num=当前数,TotalNum=容量(脚本只更新文本)

local BagConfig = {}

BagConfig.INITIAL_CAPACITY = 25     -- 初始背包容量

-- 叠球参数(用户要求收集的球在桶口 y 轴逐颗叠高)
BagConfig.BALL_SIZE = 0.8           -- 球直径(stud)
BagConfig.STACK_START_OFFSET = -1.5  -- 第一颗相对 Handle 中心的上方偏移
BagConfig.STACK_GAP = 0.8           -- 每颗叠高的间隔(= 球直径)

-- UI 固定路径(StarterGui 预建;克隆到 PlayerGui)
BagConfig.UI_ROOT = "ScreenGui"     -- PlayerGui 下 ScreenGui 名
BagConfig.UI_BAG = "Bag"            -- Bag Frame 名
BagConfig.UI_NUM = "Num"            -- 当前收集数 TextLabel
BagConfig.UI_TOTAL = "TotalNum"     -- 容量 TextLabel

return BagConfig
