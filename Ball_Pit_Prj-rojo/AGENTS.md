# Ball_Pit_Prj (球池) — 项目规范

## 项目概述与目录

Roblox 球池游戏，采用 Rojo 官方 place 模板的 client/server/shared 分层：

- `src/client/` → `StarterPlayer.StarterPlayerScripts.Client`：客户端输入、UI、表现，入口为 `.client.luau`。
- `src/server/` → `ServerScriptService.Server`：服务器权威逻辑，入口为 `.server.luau`。
- `src/server/Modules/`：BagManager、EconomyManager、DepositCoordinator 和服务器工具构建模块 ToolConfig。
- `src/shared/` → `ReplicatedStorage.Shared`：共享 ModuleScript。
- `src/shared/Config/`：SuctionConfig、BagConfig、EconomyConfig，保留迁移时 Studio 的参数和 DataStore 名。
- `src/shared/Remotes/`：四个 `.model.json` RemoteEvent，双端统一从 `ReplicatedStorage.Shared.Remotes` 获取。
- `src/check-structure.ps1`：本地结构校验，不属于游戏运行代码，不在上述三个 Rojo 映射内。

保留独立启动脚本，不引入自动模块加载器、框架或额外依赖；不要在客户端 require 服务器模块。
当前没有角色客户端脚本，不保留空的 StarterCharacterScripts 映射；需要时再增加。

## 工具链与编辑边界

1. 工具由 `aftman.toml` 管理（Rojo 7.7.0）。用户通过 VS Code 启动同步，默认端口 34872。
2. **不要自行执行 `rojo serve`、`rojo build`、`rojo sync`、`aftman install` 等命令。** 不启动、重启或替代用户的同步进程。
3. **持久游戏改动写入 `src/`，不在 Studio 手动创建、编辑或删除实例。** 普通任务只改源码；目录/映射重构经用户明确授权后，才可同时修改 `default.project.json` 和本文件。
4. 新服务器脚本用 `.server.luau`，新客户端脚本用 `.client.luau`，模块用 `.luau`。`init.luau` 会把目录变成 ModuleScript，不用它充当普通目录占位文件。
5. 角色速度、背包、金币等玩家数值由服务器决定。客户端只负责请求和显示。
6. 不自动提交，不修改 `sourcemap.json` 生成文件；目录变化后，由用户的 VS Code/Rojo 工具链重新生成。

## Studio 保留资产与迁移边界

本项目仍是代码同步项目，不是包含全部地图资产的独立 place：

- `ReplicatedStorage.BallPool`：球模板；`ReplicatedStorage.Tool`：四种 Tool 模板。
- `Workspace.Tool`：切换站；`Workspace.BallPoolp`：四色存放池及 ProximityPrompt/展示牌。
- `StarterGui.ScreenGui`：预建 Bag、Coins UI。
- 服务级 `$ignoreUnknownInstances: true` 保留不由源码管理的实例；不要把服务根直接映射为源码目录并清除未知资产。

**用户确认新版已同步，并另行授权一次性直接清理 Studio 旧残留；清理已完成。**
在“球池1”（placeId: 134117600138350）的 Edit 模式下，已删除 4 个旧 `Script` 文件夹、根目录旧服务器/客户端脚本、旧 SuctionConfig、旧 ModuleScript 配置文件夹及根目录 4 个 RemoteEvent，共 23 个旧根实例（含后代 45 个实例）。
已检查保留脚本的依赖路径，并确认 Shared / Server / Client 新版目录及球、工具、站台、UI 资产未受影响。新源码只依赖 Shared.Config/Shared.Remotes 和 Server.Modules。
这是本次清理的明确授权，不构成以后任意直接修改 Studio 的许可；正常开发仍遵守源码编辑边界。
本次未启动 Play，未保存或发布 place；用户需在 Studio 保存清理结果。修改本地文件仍可能被用户已启动的 Rojo 自动同步。

## 验证工作流

- 从项目根目录运行 `powershell -NoProfile -File src/check-structure.ps1`：校验映射、脚本后缀、配置/模块/事件依赖和旧路径残留。不启动 Rojo，不写入游戏，不替代 Luau 类型检查或行为测试。
- 修改后可通过 Roblox Studio MCP **只读**核对 Shared、Server、Client 树和源码引用；若未同步，报告实际状态，由用户在 VS Code/插件中刷新连接。
- 当前迁移阶段**不启动 Play**。旧版退役且用户允许后，才使用 `start_stop_play` 和查询验证行为，结束后恢复 Edit 模式。
- 经济模块既有的 DataStore 加载失败处理、保存策略不在本次结构重构范围内；不要以重构完成宣称存档安全问题已修复。

## 参考

- Rojo 官方 place 模板：https://github.com/rojo-rbx/rojo/blob/master/assets/project-templates/place/default.project.json
- Rojo 项目映射与未知实例规则：https://rojo.space/docs/v7/project-format/
