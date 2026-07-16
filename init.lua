--!strict

--[=[
	# Net

	静态远程通信模块。远程实例由服务端创建在本 ModuleScript 下，客户端按名称等待复制完成。

	## 接入

	```lua
	local Net = require(game.ReplicatedStorage.Packages.Net)
	```

	## 服务端生命周期

	必须在玩家调用前注册远程；推荐在服务启动时调用 `Handle` 或 `Connect`。

	```lua
	Net.Handle("CloudConfig/GetAll", function(player)
		return snapshot
	end)

	Net.Connect("Round/Ready", function(player)
		print(player.Name, "is ready")
	end)
	```

	## 客户端调用

	```lua
	local snapshot = Net.Invoke("CloudConfig/GetAll")
	Net.FireServer("Round/Ready")
	```

	## 命名与冲突

	- Event 使用内部名称 `RE/<name>`，Function 使用 `RF/<name>`；两种类型可使用相同业务名。
	- 服务端重复获取同名同类型远程会 `warn` 并复用实例；同名但类型不一致会 `error`。
	- 客户端会一直等待远程出现，不使用固定超时。
]=]

local RunService = game:GetService("RunService")

local Net = {}

-- 验证公共接口传入的业务名称。
local function assertRemoteName(name: string)
	if type(name) ~= "string" or name == "" then
		error("Remote name must be a non-empty string", 3)
	end
end

-- 将业务名称转换为实际存放在本模块下的实例名称。
local function getRemoteName(prefix: string, name: string): string
	assertRemoteName(name)
	return prefix .. "/" .. name
end

-- 客户端先快速查找；若尚未复制，则无超时地等待服务端创建的实例。
local function waitForRemote(remoteName: string): Instance
	local remote = script:FindFirstChild(remoteName)
	if remote then
		return remote
	end

	return script:WaitForChild(remoteName)
end

-- 服务端创建远程；遇到已有实例时校验类型、警告并复用。
local function getServerRemote(remoteName: string, className: string): Instance
	local remote = script:FindFirstChild(remoteName)
	if remote ~= nil then
		if not remote:IsA(className) then
			error(`Remote "{remoteName}" already exists as {remote.ClassName}, expected {className}`, 3)
		end

		warn(`Remote "{remoteName}" already exists; reusing the existing {className}`)
		return remote
	end

	remote = Instance.new(className)
	remote.Name = remoteName
	remote.Parent = script

	if not remote:IsA(className) then
		error(`Remote "{remoteName}" already exists as {remote.ClassName}, expected {className}`, 3)
	end

	return remote
end

--[=[
	获取名为 `name` 的 RemoteEvent。

	服务端不存在时创建，存在时警告并复用；客户端一直等待其复制完成。

	```lua
	local event = Net.RemoteEvent("Round/Started")
	```
]=]
function Net.RemoteEvent(name: string): RemoteEvent
	local remoteName = getRemoteName("RE", name)
	if RunService:IsServer() then
		return getServerRemote(remoteName, "RemoteEvent") :: RemoteEvent
	end

	local remote = waitForRemote(remoteName)
	if not remote:IsA("RemoteEvent") then
		error(`Remote "{remoteName}" is not a RemoteEvent`, 2)
	end
	return remote
end

--[=[
	获取名为 `name` 的 RemoteFunction。

	服务端不存在时创建，存在时警告并复用；客户端一直等待其复制完成。

	```lua
	local request = Net.RemoteFunction("CloudConfig/GetAll")
	```
]=]
function Net.RemoteFunction(name: string): RemoteFunction
	local remoteName = getRemoteName("RF", name)
	if RunService:IsServer() then
		return getServerRemote(remoteName, "RemoteFunction") :: RemoteFunction
	end

	local remote = waitForRemote(remoteName)
	if not remote:IsA("RemoteFunction") then
		error(`Remote "{remoteName}" is not a RemoteFunction`, 2)
	end
	return remote
end

--[=[
	监听一个 RemoteEvent。

	服务端 handler 签名为 `(player, ...)`；客户端 handler 签名为 `(...)`。

	```lua
	Net.Connect("Round/Started", function(roundId)
		print(roundId)
	end)
	```
]=]
function Net.Connect(name: string, handler: (...any) -> ()): RBXScriptConnection
	local remote = Net.RemoteEvent(name)
	if RunService:IsServer() then
		return remote.OnServerEvent:Connect(handler)
	end
	return remote.OnClientEvent:Connect(handler)
end

--[=[
	仅服务端：注册一个 RemoteFunction 的处理器。

	```lua
	Net.Handle("CloudConfig/GetAll", function(player)
		return snapshot
	end)
	```
]=]
function Net.Handle(name: string, handler: (player: Player, ...any) -> ...any)
	if not RunService:IsServer() then
		error("Handle can only be called on the server", 2)
	end

	Net.RemoteFunction(name).OnServerInvoke = handler
end

--[=[
	仅客户端：调用服务端的 RemoteFunction 并返回其结果。

	```lua
	local snapshot = Net.Invoke("CloudConfig/GetAll")
	```
]=]
function Net.Invoke(name: string, ...: any): ...any
	if RunService:IsServer() then
		error("Invoke can only be called on the client", 2)
	end

	return Net.RemoteFunction(name):InvokeServer(...)
end

--[=[
	仅客户端：向服务端发送 RemoteEvent。

	```lua
	Net.FireServer("Round/Ready")
	```
]=]
function Net.FireServer(name: string, ...: any)
	if RunService:IsServer() then
		error("FireServer can only be called on the client", 2)
	end

	Net.RemoteEvent(name):FireServer(...)
end

--[=[
	仅服务端：向指定玩家发送 RemoteEvent。

	```lua
	Net.FireClient("Round/Started", player, roundId)
	```
]=]
function Net.FireClient(name: string, player: Player, ...: any)
	if not RunService:IsServer() then
		error("FireClient can only be called on the server", 2)
	end

	Net.RemoteEvent(name):FireClient(player, ...)
end

--[=[
	仅服务端：向全部客户端发送 RemoteEvent。

	```lua
	Net.FireAllClients("Round/Started", roundId)
	```
]=]
function Net.FireAllClients(name: string, ...: any)
	if not RunService:IsServer() then
		error("FireAllClients can only be called on the server", 2)
	end

	Net.RemoteEvent(name):FireAllClients(...)
end

return Net
