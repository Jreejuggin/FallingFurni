local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MapService = {}

local mapsFolder = ServerStorage:WaitForChild("Maps")
local currentMap = nil

function MapService.LoadMap(mapName)
	if currentMap then
		currentMap:Destroy()
		currentMap = nil
	end

	local mapTemplate = mapsFolder:WaitForChild(mapName)
	currentMap = mapTemplate:Clone()
	currentMap.Name = "CurrentMap"
	currentMap.Parent = Workspace

	print("Loaded map:", mapName)

	return currentMap
end

function MapService.LoadRandomMap()
	if currentMap then
		currentMap:Destroy()
		currentMap = nil
	end

	local maps = mapsFolder:GetChildren()

	if #maps == 0 then
		warn("No maps found in ServerStorage > Maps")
		return nil
	end

	local chosenMap = maps[math.random(1, #maps)]
	currentMap = chosenMap:Clone()
	currentMap.Name = "CurrentMap"
	currentMap.Parent = Workspace

	print("Loaded random map:", chosenMap.Name)

	return currentMap
end

function MapService.GetCurrentMap()
	return currentMap
end

function MapService.CleanupMap()
	if currentMap then
		currentMap:Destroy()
		currentMap = nil
	end
end

return MapService