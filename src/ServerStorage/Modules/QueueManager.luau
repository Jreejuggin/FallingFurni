--[[
	QueueManager.lua (ModuleScript)

	WHERE THIS GOES: ServerStorage/Modules/QueueManager.lua

	WHAT IT DOES:
	  1. Every POLL_INTERVAL seconds, checks which players are standing
	     inside each station's pad (simple AABB check — pads aren't
	     rotated, so this is cheap and accurate).
	  2. Updates each station's sign with a live waiting count / countdown.
	  3. Once a station has MIN_PLAYERS_TO_START, begins a countdown.
	     If the count drops below the minimum, the countdown cancels.
	     If the countdown finishes (or the station hits MAX_PLAYERS),
	     that station locks and teleports its current players to a
	     freshly reserved private server.

	⚠️ CRITICAL INTEGRATION GAP — READ BEFORE WIRING THIS IN:
	This teleports players to a reserved server of the SAME place
	(game.PlaceId). That new server will run LobbyInit.server.lua
	again and build ANOTHER lobby, because nothing currently tells it
	"you're an arena server, not a lobby server."

	You must add a check at the top of whatever script decides lobby-vs-
	arena (likely a new top-level bootstrap, or the top of LobbyInit
	itself) that reads the teleported player's join data:

		local Players = game:GetService("Players")
		Players.PlayerAdded:Connect(function(player)
			local joinData = player:GetJoinData()
			local teleportData = joinData.TeleportData
			if teleportData and teleportData.isArenaServer then
				-- run arena/round setup (ClassicArena?) instead of LobbyBuilder
			end
		end)

	Until that check exists, do not point this at real matches — it will
	teleport players into an empty duplicate lobby with no way back.
	Flagging this as the next required piece of work, not building it
	myself since I can't see ClassicArena.lua's current structure.

	SUGGESTED OWNERSHIP: whoever owns arena/round logic, since it's the
	receiving side of this handoff — natural pairing with ClassicArena.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local QueueManager = {}

local POLL_INTERVAL = 1
local MIN_PLAYERS_TO_START = 2 -- matches your current "starts when more than one joins" behavior; raise once you're ready for bigger matches
local MAX_PLAYERS_PER_MATCH = 8
local COUNTDOWN_SECONDS = 10

-- Internal per-station runtime state, keyed by station.id.
-- Kept as a plain state table rather than a class — each station's
-- behavior is identical and stateless between stations, so an OOP
-- wrapper would just add ceremony here. Worth revisiting as a proper
-- class if stations start needing per-station behavior differences
-- (e.g. different game modes per station).
local stationStates = {}

local function isPlayerInPad(player, pad)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local relative = rootPart.Position - pad.Position
	local halfSize = pad.Size / 2

	local withinX = math.abs(relative.X) <= halfSize.X
	local withinZ = math.abs(relative.Z) <= halfSize.Z
	local withinY = relative.Y >= -2 and relative.Y <= 6 -- standing on/near the pad, not flying overhead

	return withinX and withinZ and withinY
end

local function getPlayersInStation(station)
	local playersInZone = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if isPlayerInPad(player, station.pad) then
			table.insert(playersInZone, player)
		end
	end
	return playersInZone
end

local function updateStationLabel(station, playerCount, countdownRemaining)
	if countdownRemaining then
		station.statusLabel.Text = ("STATION %d\nStarting in %d..."):format(station.id, countdownRemaining)
	else
		station.statusLabel.Text = ("STATION %d\nWaiting: %d/%d"):format(station.id, playerCount, MIN_PLAYERS_TO_START)
	end
end

-- Reserves a private server and teleports the given players into it.
-- teleportData.isArenaServer is the flag the receiving server MUST
-- check (see module header) to know to skip lobby setup.
local function launchMatch(station, matchPlayers)
	local matchId = HttpService:GenerateGUID(false)

	local reserveSuccess, accessCodeOrErr = pcall(function()
		return TeleportService:ReserveServer(game.PlaceId)
	end)

	if not reserveSuccess then
		warn(("[QueueManager] Station %d: failed to reserve server: %s"):format(station.id, tostring(accessCodeOrErr)))
		return false
	end

	local accessCode = accessCodeOrErr

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = accessCode
	teleportOptions:SetTeleportData({
		isArenaServer = true,
		matchId = matchId,
		stationId = station.id,
	})

	local teleportSuccess, teleportErr = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, matchPlayers, teleportOptions)
	end)

	if not teleportSuccess then
		warn(("[QueueManager] Station %d: teleport failed: %s"):format(station.id, tostring(teleportErr)))
		return false
	end

	print(("[QueueManager] Station %d: launched match %s with %d players"):format(station.id, matchId, #matchPlayers))
	return true
end

local function pollStation(station)
	local state = stationStates[station.id]
	if state.locked then
		return -- already mid-teleport for this station, ignore until it resets
	end

	local playersInZone = getPlayersInStation(station)
	local count = #playersInZone

	if count >= MIN_PLAYERS_TO_START and not state.countdownActive then
		state.countdownActive = true
		state.countdownRemaining = COUNTDOWN_SECONDS
	elseif count < MIN_PLAYERS_TO_START and state.countdownActive then
		-- Someone left before the countdown finished — cancel and reset
		state.countdownActive = false
		state.countdownRemaining = nil
	end

	if state.countdownActive then
		updateStationLabel(station, count, state.countdownRemaining)
		state.countdownRemaining -= POLL_INTERVAL

		local shouldLaunch = state.countdownRemaining <= 0 or count >= MAX_PLAYERS_PER_MATCH
		if shouldLaunch then
			state.locked = true
			local launched = launchMatch(station, playersInZone)
			-- Reset state whether or not the launch succeeded, so the
			-- station becomes available again rather than staying stuck.
			state.locked = false
			state.countdownActive = false
			state.countdownRemaining = nil
			if not launched then
				updateStationLabel(station, 0)
			end
		end
	else
		updateStationLabel(station, count)
	end
end

-- Starts the polling loop. Call once after stations are built.
function QueueManager.Start(stations)
	for _, station in ipairs(stations) do
		stationStates[station.id] = { countdownActive = false, countdownRemaining = nil, locked = false }
	end

	task.spawn(function()
		while true do
			for _, station in ipairs(stations) do
				local ok, err = pcall(pollStation, station)
				if not ok then
					warn(("[QueueManager] Station %d poll error: %s"):format(station.id, tostring(err)))
				end
			end
			task.wait(POLL_INTERVAL)
		end
	end)

	print(("[QueueManager] Started polling %d station(s), min %d / max %d players per match"):format(
		#stations, MIN_PLAYERS_TO_START, MAX_PLAYERS_PER_MATCH))
end

return QueueManager