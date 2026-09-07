-- SuctionConfig —— 吸附收集共享配置(双端唯一参数源)
-- 现实现完整链路:吸附收集 + 背包容量(BagManager) + 倒球站台(BallPoolp) + 金币/UI;本文件只放吸附专项参数

local SuctionConfig = {}

-- 吸附参数
SuctionConfig.SUCTION_RADIUS = 20       -- 客户端扫描半径(stud)
SuctionConfig.SUCTION_SPEED = 45        -- 球飞向 Handle 速度(stud/s)
SuctionConfig.COLLECT_DISTANCE = 0.7    -- 判定收集成功的距离
SuctionConfig.SCAN_INTERVAL = 0.08      -- 客户端扫描间隔(s)
SuctionConfig.MAX_SUCTION_BATCH = 1     -- 每次扫描最多请求 1 球
SuctionConfig.SUCTION_COOLDOWN = 1      -- Ball.md 第5条 点击吸附冷却(s)

-- 球/工具属性名
SuctionConfig.BALL_COLOR_ATTR = "BallColor"        -- 球的颜色属性(已小写: red/blue/yellow/green)
SuctionConfig.TOOL_COLOR_ATTR = "BallColorCollect" -- 工具收集颜色属性(小写,已在 ToolConfig 配置)

-- 球池容器:服务器把 ReplicatedStorage.BallPool 的球克隆到 Workspace 的该容器下
SuctionConfig.WORKSPACE_POOL_NAME = "BallPool"     -- workspace 下实际参与收集的球池容器名
SuctionConfig.SOURCE_POOL = "ReplicatedStorage.BallPool" -- 模板源(仅供服务器读取)

-- 收集后隐藏点
SuctionConfig.HIDE_POS = Vector3.new(0, -500, 0)

return SuctionConfig
