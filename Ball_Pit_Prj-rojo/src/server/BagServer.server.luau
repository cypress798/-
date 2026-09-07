--!strict
-- BagServer —— 背包服务启动入口(调用 BagManager.init 连接玩家生命周期)

local BagManager = require(script.Parent:WaitForChild("Modules"):WaitForChild("BagManager"))

BagManager.init()
print("[BagServer] 背包系统已启动")