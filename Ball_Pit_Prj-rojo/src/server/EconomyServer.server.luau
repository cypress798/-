--!strict
-- EconomyServer —— 经济系统启动入口

local EconomyManager = require(script.Parent:WaitForChild("Modules"):WaitForChild("EconomyManager"))

EconomyManager.init()
print("[EconomyServer] 经济系统已启动")