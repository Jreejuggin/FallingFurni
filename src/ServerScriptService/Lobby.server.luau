local Workspace = game:GetService("Workspace")

local lobbySpawn = Workspace:WaitForChild("lobbySpawn")

-- Remove old lobby
local old = Workspace:FindFirstChild("LobbyBuild")
if old then old:Destroy() end

local lobby = Instance.new("Folder")
lobby.Name = "LobbyBuild"
lobby.Parent = Workspace

--------------------------------------------------
-- BASE PLATFORM (clean + centered)
--------------------------------------------------
local base = Instance.new("Part")
base.Size = Vector3.new(70, 2, 70)
base.Anchored = true
base.Material = Enum.Material.SmoothPlastic
base.Color = Color3.fromRGB(25, 25, 25)
base.Position = lobbySpawn.Position - Vector3.new(0, 3, 0)
base.Parent = lobby

--------------------------------------------------
-- BORDER RING (neon edge, not spammy)
--------------------------------------------------
for i = 1, 12 do
	local part = Instance.new("Part")
	part.Size = Vector3.new(4, 1, 2)
	part.Anchored = true
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(0, 170, 255)

	local angle = math.rad(i * 30)
	local radius = 32

	part.Position = base.Position + Vector3.new(
		math.cos(angle) * radius,
		2,
		math.sin(angle) * radius
	)

	part.Parent = lobby
end

--------------------------------------------------
-- CENTER PLATFORM (focus point)
--------------------------------------------------
local center = Instance.new("Part")
center.Size = Vector3.new(12, 1, 12)
center.Anchored = true
center.Material = Enum.Material.Neon
center.Color = Color3.fromRGB(140, 0, 255)
center.Position = lobbySpawn.Position - Vector3.new(0, 2, 0)
center.Parent = lobby

--------------------------------------------------
-- SIMPLE SEATING (clean benches)

for i = 1, 4 do
	local bench = Instance.new("Part")
	bench.Size = Vector3.new(8, 1, 3)
	bench.Anchored = true
	bench.Material = Enum.Material.Wood
	bench.Color = Color3.fromRGB(110, 80, 60)

	local angle = math.rad(i * 90)
	local radius = 18

	bench.Position = base.Position + Vector3.new(
		math.cos(angle) * radius,
		2,
		math.sin(angle) * radius
	)

	bench.Parent = lobby
end

--------------------------------------------------
-- INFO BOARD (clean UI)
--------------------------------------------------
local board = Instance.new("Part")
board.Size = Vector3.new(18, 10, 1)
board.Anchored = true
board.Position = base.Position + Vector3.new(0, 7, -28)
board.Color = Color3.fromRGB(40, 40, 40)
board.Parent = lobby

local gui = Instance.new("SurfaceGui", board)
gui.Face = Enum.NormalId.Front

local text = Instance.new("TextLabel", gui)
text.Size = UDim2.new(1, 0, 1, 0)
text.BackgroundTransparency = 1
text.TextScaled = true
text.Font = Enum.Font.GothamBold
text.TextColor3 = Color3.new(1,1,1)
text.Text = "MUSICAL CHAIRS\n\nSit before time runs out!\nLast player wins!"

--------------------------------------------------
-- SOFT LIGHTING (not spammy)
--------------------------------------------------
local light = Instance.new("PointLight")
light.Brightness = 1
light.Range = 15
light.Color = Color3.fromRGB(150, 150, 255)
light.Parent = center

--------------------------------------------------
-- ATMOSPHERE (subtle)
--------------------------------------------------
local atmosphere = Workspace:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.25
atmosphere.Color = Color3.fromRGB(200, 200, 255)
atmosphere.Parent = Workspace

--------------------------------------------------
-- MUSIC (single instance only)
--------------------------------------------------
if not lobby:FindFirstChild("LobbyMusic") then
	local sound = Instance.new("Sound")
	sound.Name = "LobbyMusic"
	sound.SoundId = "rbxassetid://1843529634"
	sound.Looped = true
	sound.Volume = 0.25
	sound.Parent = lobby
	sound:Play()
end

print("Clean lobby built.")