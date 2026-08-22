--[[
	LobbyInit.server.lua (Script)

	WHERE THIS GOES: ServerScriptService/LobbyInit.server.lua

	Thin wiring script: builds the room, then builds the queue stations
	inside it. QUEUE_STATION_COUNT is the one place to change how many
	concurrent game queues the lobby supports — bump this up as your
	player base grows, no other code needs to change.
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local LobbyBuilder = require(ServerStorage.Modules.LobbyBuilder)
local QueueStationBuilder = require(ServerStorage.Modules.QueueStationBuilder)
local QueueManager = require(ServerStorage.Modules.QueueManager)

local QUEUE_STATION_COUNT = 4 -- recommended starting point; see chat for reasoning

local lobbySpawn = Workspace:WaitForChild("lobbySpawn", 10)
if not lobbySpawn then
	warn("[LobbyInit] 'lobbySpawn' not found in Workspace within 10s. Lobby was not built.")
	return
end

local lobby, base, baseTopY = LobbyBuilder.Build(Workspace, lobbySpawn)
print("[LobbyInit] Lobby built:", lobby:GetFullName())

local stations = QueueStationBuilder.Build(Workspace, lobby, base, baseTopY, QUEUE_STATION_COUNT)
print(("[LobbyInit] Built %d queue stations"):format(#stations))

-- ⚠️ Do not enable this until the receiving server checks TeleportData
-- for isArenaServer (see QueueManager.lua header). Until then this will
-- teleport players into an empty duplicate lobby with no way back.
QueueManager.Start(stations)