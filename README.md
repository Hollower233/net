# net

`hollower233/net` is a small static networking module for Roblox. It creates remotes on the server and resolves them on clients by name.

`init.lua` is the authoritative API documentation: it contains the lifecycle rules and runnable examples beside every public method.

## Key behavior

Client lookup always waits until the named remote is replicated. It is never discarded merely because server initialization or replication takes longer than ten seconds. Roblox may log an infinite-yield warning while the remote is absent.

The server should still register every remote during startup so clients never wait for a module that was not initialized.

On the server, calling `RemoteEvent(name)` or `RemoteFunction(name)` for an already-created remote logs a warning and reuses it. A name that already belongs to the other remote type raises an error.

## API

```lua
local Net = require(game.ReplicatedStorage.Packages.Net)

-- Server
Net.handle("CloudConfig/GetAll", function(player)
	return snapshot
end)

Net.connect("RoundStarted", function(player, roundId)
	print(player, roundId)
end)

Net.fireClient("RoundStarted", player, roundId)
Net.fireAllClients("RoundStarted", roundId)

-- Client
local snapshot = Net.invoke("CloudConfig/GetAll")
Net.fireServer("Ready")
Net.connect("RoundStarted", function(roundId)
	print(roundId)
end)
```

## Wally

```toml
[dependencies]
Net = "hollower233/net@0.1.0"
```

Run `wally install`, then map the generated `Packages` directory to `ReplicatedStorage.Packages` with Rojo.
