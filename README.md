# net

`hollower233/net` is a small static networking module for Roblox. It creates remotes on the server and resolves them on clients by name.

## Key behavior

Client lookup always waits until the named remote is replicated. It is never discarded merely because server initialization or replication takes longer than ten seconds. Roblox may log an infinite-yield warning while the remote is absent.

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
