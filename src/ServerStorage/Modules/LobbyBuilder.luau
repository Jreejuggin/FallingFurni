--[[
	LobbyBuilder.lua (ModuleScript)

	WHERE THIS GOES: ServerStorage/Modules/LobbyBuilder.lua

	WHAT IT DOES: Builds the lobby ROOM ITSELF — floor, walls, ceiling,
	social seating, atmosphere, music. Queue stations are a separate
	concern and live in QueueStationBuilder.lua (called after this from
	LobbyInit.server.lua) — keeps "the room" and "the matchmaking UI
	inside the room" independently editable and independently ownable.

	DESIGN DIRECTION (per team decision):
	Open-air neon aesthetic, but actually enclosed. Solved by using a
	solid lower wall band for structure + a glass upper band and glass
	ceiling for the airy/open feel, instead of a fully solid box.

	Returns lobby, base, baseTopY — QueueStationBuilder needs the same
	ground reference this module computes, so we hand it back rather
	than recalculating it twice (single source of truth for "where is
	the floor").
]]

local LobbyBuilder = {}

local BENCH_COLOR = Color3.fromRGB(110, 80, 60) -- kept for reference/future props, unused now that seating is individual Seats
local BORDER_COLOR = Color3.fromRGB(0, 170, 255)
local CENTER_COLOR = Color3.fromRGB(140, 0, 255)
local WALL_COLOR = Color3.fromRGB(20, 20, 25)
local GLASS_COLOR = Color3.fromRGB(150, 200, 255)

local SOCIAL_SEAT_COUNT = 8
local SOCIAL_SEAT_RADIUS = 14

local WALL_LOWER_HEIGHT = 20
local WALL_UPPER_HEIGHT = 10
local WALL_HALF_EXTENT = 35 -- matches the 70x70 base platform

function LobbyBuilder.Build(workspaceRef, lobbySpawn)
	local old = workspaceRef:FindFirstChild("LobbyBuild")
	if old then
		old:Destroy()
	end

	local lobby = Instance.new("Folder")
	lobby.Name = "LobbyBuild"

	----------------------------------------------------------------
	-- GROUND REFERENCE (see prior fix — anchor to spawn's actual
	-- top surface, never to an assumed offset)
	----------------------------------------------------------------
	local spawnTopY = lobbySpawn.Position.Y + (lobbySpawn.Size.Y / 2)
	local groundPosition = Vector3.new(lobbySpawn.Position.X, spawnTopY, lobbySpawn.Position.Z)

	----------------------------------------------------------------
	-- BASE PLATFORM
	----------------------------------------------------------------
	local BASE_HEIGHT = 2
	local base = Instance.new("Part")
	base.Size = Vector3.new(70, BASE_HEIGHT, 70)
	base.Anchored = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(25, 25, 25)
	base.Position = groundPosition - Vector3.new(0, BASE_HEIGHT / 2, 0)
	base.Parent = lobby

	local baseTopY = base.Position.Y + (BASE_HEIGHT / 2)

	lobbySpawn.Transparency = 1

	----------------------------------------------------------------
	-- BORDER ACCENT RING (now doubles as wall-floor trim lighting)
	----------------------------------------------------------------
	for i = 1, 12 do
		local part = Instance.new("Part")
		part.Size = Vector3.new(4, 1, 2)
		part.Anchored = true
		part.Material = Enum.Material.Neon
		part.Color = BORDER_COLOR

		local angle = math.rad(i * 30)
		local radius = 30
		part.Position = Vector3.new(
			base.Position.X + math.cos(angle) * radius,
			baseTopY + (part.Size.Y / 2),
			base.Position.Z + math.sin(angle) * radius
		)
		part.Parent = lobby
	end

	----------------------------------------------------------------
	-- CENTER PLATFORM
	----------------------------------------------------------------
	local center = Instance.new("Part")
	center.Size = Vector3.new(12, 1, 12)
	center.Anchored = true
	center.Material = Enum.Material.Neon
	center.Color = CENTER_COLOR
	center.Position = Vector3.new(base.Position.X, baseTopY + (center.Size.Y / 2), base.Position.Z)
	center.Parent = lobby

	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Range = 15
	light.Color = Color3.fromRGB(150, 150, 255)
	light.Parent = center

	----------------------------------------------------------------
	-- SOCIAL SEATING
	-- FIX: these were plain Parts before, which is why you couldn't
	-- sit on them — Roblox only allows sitting on a Seat (or
	-- VehicleSeat) instance. Switched to individual Seat parts
	-- clustered around the center platform, flush on the floor using
	-- the same "top-surface" math as everything else, so no z-fighting.
	----------------------------------------------------------------
	for i = 1, SOCIAL_SEAT_COUNT do
		local seat = Instance.new("Seat")
		seat.Size = Vector3.new(2, 1, 2)
		seat.Anchored = true
		seat.Material = Enum.Material.Wood
		seat.Color = BENCH_COLOR

		local angle = math.rad((360 / SOCIAL_SEAT_COUNT) * i)
		seat.Position = Vector3.new(
			base.Position.X + math.cos(angle) * SOCIAL_SEAT_RADIUS,
			baseTopY + (seat.Size.Y / 2),
			base.Position.Z + math.sin(angle) * SOCIAL_SEAT_RADIUS
		)
		-- Face each seat toward the center platform so sitting players look inward
		seat.CFrame = CFrame.lookAt(seat.Position, Vector3.new(base.Position.X, seat.Position.Y, base.Position.Z))
		seat.Parent = lobby
	end

	----------------------------------------------------------------
	-- WALLS (enclosed shell, open-air feel via glass upper band)
	----------------------------------------------------------------
	local wallSides = {
		{ axis = "z", sign = -1 }, -- north
		{ axis = "z", sign = 1 },  -- south
		{ axis = "x", sign = 1 },  -- east
		{ axis = "x", sign = -1 }, -- west
	}

	for _, side in ipairs(wallSides) do
		local isZAxis = side.axis == "z"
		local lowerSize = isZAxis
			and Vector3.new(70, WALL_LOWER_HEIGHT, 2)
			or Vector3.new(2, WALL_LOWER_HEIGHT, 70)
		local upperSize = isZAxis
			and Vector3.new(70, WALL_UPPER_HEIGHT, 2)
			or Vector3.new(2, WALL_UPPER_HEIGHT, 70)

		local offset = isZAxis
			and Vector3.new(0, 0, WALL_HALF_EXTENT * side.sign)
			or Vector3.new(WALL_HALF_EXTENT * side.sign, 0, 0)

		-- Solid lower band (structure)
		local lowerWall = Instance.new("Part")
		lowerWall.Size = lowerSize
		lowerWall.Anchored = true
		lowerWall.Material = Enum.Material.SmoothPlastic
		lowerWall.Color = WALL_COLOR
		lowerWall.Position = base.Position + offset + Vector3.new(0, baseTopY - base.Position.Y + (WALL_LOWER_HEIGHT / 2), 0)
		lowerWall.Parent = lobby

		-- Neon trim strip at the seam between solid and glass
		local trim = Instance.new("Part")
		trim.Size = isZAxis and Vector3.new(70, 0.5, 2.2) or Vector3.new(2.2, 0.5, 70)
		trim.Anchored = true
		trim.Material = Enum.Material.Neon
		trim.Color = BORDER_COLOR
		trim.Position = lowerWall.Position + Vector3.new(0, WALL_LOWER_HEIGHT / 2, 0)
		trim.Parent = lobby

		-- Glass upper band (open-air feel)
		local upperWall = Instance.new("Part")
		upperWall.Size = upperSize
		upperWall.Anchored = true
		upperWall.Material = Enum.Material.Glass
		upperWall.Color = GLASS_COLOR
		upperWall.Transparency = 0.55
		upperWall.Position = lowerWall.Position + Vector3.new(0, (WALL_LOWER_HEIGHT / 2) + (WALL_UPPER_HEIGHT / 2), 0)
		upperWall.Parent = lobby
	end

	----------------------------------------------------------------
	-- CEILING (glass, elevated — keeps the room feeling open despite
	-- being enclosed)
	----------------------------------------------------------------
	local ceiling = Instance.new("Part")
	ceiling.Size = Vector3.new(70, 2, 70)
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.Glass
	ceiling.Color = GLASS_COLOR
	ceiling.Transparency = 0.6
	ceiling.Position = Vector3.new(
		base.Position.X,
		baseTopY + WALL_LOWER_HEIGHT + WALL_UPPER_HEIGHT + 1,
		base.Position.Z
	)
	ceiling.Parent = lobby

	----------------------------------------------------------------
	-- INFO BOARD
	----------------------------------------------------------------
	local board = Instance.new("Part")
	board.Size = Vector3.new(18, 10, 1)
	board.Anchored = true
	board.Color = Color3.fromRGB(40, 40, 40)
	board.Position = Vector3.new(base.Position.X, baseTopY + 6, base.Position.Z - 28)
	board.CFrame = board.CFrame * CFrame.Angles(0, math.rad(180), 0)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = "MUSICAL CHAIRS\n\nSit before time runs out!\nLast player wins!"

	text.Parent = gui
	gui.Parent = board
	board.Parent = lobby

	----------------------------------------------------------------
	-- ATMOSPHERE
	----------------------------------------------------------------
	local atmosphere = workspaceRef:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
	end
	atmosphere.Density = 0.25
	atmosphere.Color = Color3.fromRGB(200, 200, 255)
	atmosphere.Parent = workspaceRef

	----------------------------------------------------------------
	-- MUSIC
	-- NOTE: rbxassetid://1843529634 is still not a valid audio asset —
	-- replace with a real Sound asset ID from the Creator Store.
	----------------------------------------------------------------
	local sound = Instance.new("Sound")
	sound.Name = "LobbyMusic"
	sound.SoundId = "rbxassetid://137960148851757" -- TODO: replace with a valid Sound asset ID
	sound.Looped = true
	sound.Volume = 0.25
	sound.Parent = lobby

	local played, err = pcall(function()
		sound:Play()
	end)
	if not played then
		warn("[LobbyBuilder] LobbyMusic failed to play — check that SoundId is a valid audio asset:", err)
	end

	lobby.Parent = workspaceRef

	return lobby, base, baseTopY
end

return LobbyBuilder