local arenaSize = 60
local wallHeight = 50
local wallThickness = 4
local center = Vector3.new(0, 0, 0)

local function createWall(size, position, name)
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.CanCollide = true
	wall.Material = Enum.Material.Metal
	wall.Color = Color3.fromRGB(85, 0, 0)
	wall.TopSurface = Enum.SurfaceType.Smooth
	wall.BottomSurface = Enum.SurfaceType.Smooth

	-- Add a glowing trim
	local trim = Instance.new("SelectionBox")
	trim.Adornee = wall
	trim.LineThickness = 0.05
	trim.Color3 = Color3.fromRGB(255, 0, 0)
	trim.Parent = wall

	wall.Parent = workspace
end

-- Front
createWall(
	Vector3.new(arenaSize, wallHeight, wallThickness),
	center + Vector3.new(0, wallHeight / 2, arenaSize / 2),
	"FrontWall"
)

-- Back
createWall(
	Vector3.new(arenaSize, wallHeight, wallThickness),
	center + Vector3.new(0, wallHeight / 2, -arenaSize / 2),
	"BackWall"
)

-- Left
createWall(
	Vector3.new(wallThickness, wallHeight, arenaSize),
	center + Vector3.new(-arenaSize / 2, wallHeight / 2, 0),
	"LeftWall"
)

-- Right
createWall(
	Vector3.new(wallThickness, wallHeight, arenaSize),
	center + Vector3.new(arenaSize / 2, wallHeight / 2, 0),
	"RightWall"
)