# net

`hollower233/net` is a small static networking module for Roblox. It creates remotes on the server and resolves them on clients by name.

## Key behavior

Client lookup waits indefinitely by default. This prevents a remote from being discarded merely because server initialization or replication takes longer than ten seconds. Roblox may log an infinite-yield warning while it waits; to opt into a failure deadline, call `Net:SetClientTimeout(seconds)` from the client before the first lookup.

The server should still register every remote during startup so clients never wait for a module that was not initialized.

## API

```lua
local Net = require(game.ReplicatedStorage.Packages.Net)

-- Server
Net:Handle("CloudConfig/GetAll", function(player)
	return snapshot
end)

Net:Connect("RoundStarted", function(player, roundId)
	print(player, roundId)
end)

Net:FireClient("RoundStarted", player, roundId)
Net:FireAllClients("RoundStarted", roundId)

-- Client
local snapshot = Net:Invoke("CloudConfig/GetAll")
Net:FireServer("Ready")
Net:Connect("RoundStarted", function(roundId)
	print(roundId)
end)
```

## Wally

```toml
[dependencies]
Net = "hollower233/net@0.1.0"
```

Run `wally install`, then map the generated `Packages` directory to `ReplicatedStorage.Packages` with Rojo.
