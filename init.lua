local RunService = game:GetService("RunService")

local Net = {
	clientTimeout = nil :: number?,
}

local function assertRemoteName(name: string)
	if type(name) ~= "string" or name == "" then
		error("Remote name must be a non-empty string", 3)
	end
end

local function getRemoteName(prefix: string, name: string): string
	assertRemoteName(name)
	return prefix .. "/" .. name
end

local function waitForRemote(remoteName: string): Instance
	local remote = script:FindFirstChild(remoteName)
	if remote then
		return remote
	end

	local timeout = Net.clientTimeout
	if timeout ~= nil then
		remote = script:WaitForChild(remoteName, timeout)
		if remote == nil then
			error(`Timed out waiting for remote "{remoteName}" after {timeout} seconds`, 3)
		end
		return remote
	end

	return script:WaitForChild(remoteName)
end

local function getServerRemote(remoteName: string, className: string): Instance
	local remote = script:FindFirstChild(remoteName)
	if remote == nil then
		remote = Instance.new(className)
		remote.Name = remoteName
		remote.Parent = script
	end

	if not remote:IsA(className) then
		error(`Remote "{remoteName}" already exists as {remote.ClassName}, expected {className}`, 3)
	end

	return remote
end

function Net:SetClientTimeout(timeout: number?)
	if RunService:IsServer() then
		error("SetClientTimeout can only be called on the client", 2)
	end
	if timeout ~= nil and (type(timeout) ~= "number" or timeout < 0) then
		error("Client timeout must be nil or a non-negative number", 2)
	end

	self.clientTimeout = timeout
end

function Net:RemoteEvent(name: string): RemoteEvent
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

function Net:RemoteFunction(name: string): RemoteFunction
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

function Net:Connect(name: string, handler: (...any) -> ()): RBXScriptConnection
	local remote = self:RemoteEvent(name)
	if RunService:IsServer() then
		return remote.OnServerEvent:Connect(handler)
	end
	return remote.OnClientEvent:Connect(handler)
end

function Net:Handle(name: string, handler: (player: Player, ...any) -> ...any)
	if not RunService:IsServer() then
		error("Handle can only be called on the server", 2)
	end

	self:RemoteFunction(name).OnServerInvoke = handler
end

function Net:Invoke(name: string, ...: any): ...any
	if RunService:IsServer() then
		error("Invoke can only be called on the client", 2)
	end

	return self:RemoteFunction(name):InvokeServer(...)
end

function Net:FireServer(name: string, ...: any)
	if RunService:IsServer() then
		error("FireServer can only be called on the client", 2)
	end

	self:RemoteEvent(name):FireServer(...)
end

function Net:FireClient(name: string, player: Player, ...: any)
	if not RunService:IsServer() then
		error("FireClient can only be called on the server", 2)
	end

	self:RemoteEvent(name):FireClient(player, ...)
end

function Net:FireAllClients(name: string, ...: any)
	if not RunService:IsServer() then
		error("FireAllClients can only be called on the server", 2)
	end

	self:RemoteEvent(name):FireAllClients(...)
end

return Net
