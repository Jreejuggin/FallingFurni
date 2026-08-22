--[[
	QueueStationBuilder.lua (ModuleScript)

	WHERE THIS GOES: ServerStorage/Modules/QueueStationBuilder.lua

	WHAT IT DOES: Builds the VISUAL/STRUCTURAL side of matchmaking
	stations — a standing zone (no seats, per team decision: players
	just stand inside the marked pad) and a numbered sign per station,
	arranged evenly around the lobby.

	WHAT THIS DOES NOT DO (next milestone, separate file):
	Actually detecting which players are standing in each zone, filling
	a queue, forming a match, and teleporting a group to a fresh arena
	instance. That's real gameplay logic with state and RemoteEvents —
	belongs in QueueManager.lua, not here. This module hands back each
	station's pad Part and TextLabel so QueueManager can hook into them
	(e.g. via Region3/GetPartsInPart against pad.Position + pad.Size,
	or workspace:GetPartsInPart(pad) each heartbeat/second).

	SUGGESTED OWNERSHIP: whoever isn't currently owning arena/round
	logic — this is self-contained and only needs `base`/`baseTopY`
	from LobbyBuilder as inputs, so it can be built in parallel.
]]

local QueueStationBuilder = {}

local STATION_RADIUS = 26
local STATION_ANGLE_OFFSET = 45 -- degrees; keeps stations out of the board's line and off the cardinal spawn axis
local PAD_SIZE = Vector3.new(10, 0.2, 10)
local SIGN_SIZE = Vector3.new(4, 3, 0.3)
local SIGN_DISTANCE = 8 -- studs further out than the pad, so players approaching from center see it first

local STATION_COLORS = {
	Color3.fromRGB(0, 255, 140),
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(80, 140, 255),
	Color3.fromRGB(255, 200, 0),
}

-- stationCount: how many stations to build. Passed in explicitly rather
-- than hardcoded so scaling up later (e.g. from 4 to 8 as your player
-- base grows) is a one-line change at the call site in LobbyInit.
function QueueStationBuilder.Build(workspaceRef, lobby, base, baseTopY, stationCount)
	local stationsFolder = lobby:FindFirstChild("QueueStations")
	if stationsFolder then
		stationsFolder:Destroy()
	end
	stationsFolder = Instance.new("Folder")
	stationsFolder.Name = "QueueStations"
	stationsFolder.Parent = lobby

	local stations = {}

	for i = 1, stationCount do
		local angle = math.rad(STATION_ANGLE_OFFSET + (360 / stationCount) * (i - 1))
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local color = STATION_COLORS[((i - 1) % #STATION_COLORS) + 1]

		----------------------------------------------------------------
		-- STANDING PAD (marked zone, no seat — matches team decision)
		-- Thin and lifted half its own height above the floor's top
		-- surface, same flush-stacking pattern as everything else in
		-- LobbyBuilder, so it can't clip into or float above the floor.
		----------------------------------------------------------------
		local pad = Instance.new("Part")
		pad.Name = ("StationPad_%d"):format(i)
		pad.Size = PAD_SIZE
		pad.Anchored = true
		pad.CanCollide = false -- players stand ON the floor, this is a visual marker only
		pad.Material = Enum.Material.Neon
		pad.Color = color
		pad.Transparency = 0.25
		pad.Position = base.Position + outward * STATION_RADIUS
		pad.Position = Vector3.new(pad.Position.X, baseTopY + (PAD_SIZE.Y / 2), pad.Position.Z)
		pad.Parent = stationsFolder

		----------------------------------------------------------------
		-- SIGN (station number + placeholder status text)
		----------------------------------------------------------------
		local signPosition = base.Position + outward * (STATION_RADIUS + SIGN_DISTANCE)
		signPosition = Vector3.new(signPosition.X, baseTopY + (SIGN_SIZE.Y / 2), signPosition.Z)

		local sign = Instance.new("Part")
		sign.Name = ("StationSign_%d"):format(i)
		sign.Size = SIGN_SIZE
		sign.Anchored = true
		sign.Material = Enum.Material.SmoothPlastic
		sign.Color = Color3.fromRGB(30, 30, 30)
		sign.CFrame = CFrame.lookAt(signPosition, Vector3.new(base.Position.X, signPosition.Y, base.Position.Z))

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0

		local label = Instance.new("TextLabel")
		label.Name = "StatusLabel"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = color
		label.Text = ("STATION %d\nWaiting: 0"):format(i) -- placeholder; QueueManager will update this live

		label.Parent = gui
		gui.Parent = sign
		sign.Parent = stationsFolder

		table.insert(stations, {
			id = i,
			pad = pad,
			sign = sign,
			statusLabel = label,
			position = pad.Position,
		})
	end

	return stations
end

return QueueStationBuilder