
-- Replacated Storage is instantiated so we can add variables such as round state to it
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roundState = ReplicatedStorage:FindFirstChild("RoundState")
local roundTimer = ReplicatedStorage:WaitForChild("RoundTimer")
if not roundState then
    roundState = Instance.new("StringValue")
    roundState.Name = "RoundState"
    roundState.Parent = ReplicatedStorage
end


local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local chairTemplate = ServerStorage:WaitForChild("Chair")

local cycleDuration = 20
local spawnHeight = 50
local arenaRadius = 20

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Timer = require(ReplicatedStorage:WaitForChild("Timer"))
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- SETTINGS
local cycleDuration = 10
local spawnHeight = 50
local arenaRadius = 25
local lobbyTime = 8 

-- REFERENCES
local roundState = ReplicatedStorage:WaitForChild("RoundState")
local chairTemplate = ServerStorage:WaitForChild("Chair")
local lobbySpawn = Workspace:WaitForChild("lobbySpawn")
print("LobbySpawn:", lobbySpawn)
local gameSpawn = Workspace:WaitForChild("gameSpawn")
local queueArea = Workspace:WaitForChild("QueueArea")

-- QUEUE SETTINGS
local QUEUE_PLAYERS_TO_START = 2
local QUEUE_COUNTDOWN_SECONDS = 5

-- Checks whether a player's HumanoidRootPart is standing within the
-- queueArea part's footprint (simple AABB check; queueArea isn't rotated).
local function isPlayerInQueueArea(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local relative = rootPart.Position - queueArea.Position
	local halfSize = queueArea.Size / 2

	local withinX = math.abs(relative.X) <= halfSize.X
	local withinZ = math.abs(relative.Z) <= halfSize.Z
	local withinY = relative.Y >= -2 and relative.Y <= 6 -- standing on/near the pad, not flying overhead

	return withinX and withinZ and withinY
end

local function getPlayersInQueueArea()
	local playersInZone = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if isPlayerInQueueArea(player) then
			table.insert(playersInZone, player)
		end
	end
	return playersInZone
end

while true do
	local queuedPlayers = getPlayersInQueueArea()

	if #queuedPlayers < QUEUE_PLAYERS_TO_START then
		print("Waiting for players in queue area... (Current: " .. #queuedPlayers .. ")")
		roundState.Value = "Lobby"
		task.wait(1)
		continue
	end

	-------------------
	-- GAME PHASE
	-------------------
	print("Queue filled with " .. #queuedPlayers .. " players - starting " .. QUEUE_COUNTDOWN_SECONDS .. "s countdown")
	roundState.Value = "Game"
	lobbySpawn.Enabled = false
	gameSpawn.Enabled = true
	Timer.Start(0, QUEUE_COUNTDOWN_SECONDS)

	for _, player in ipairs(queuedPlayers) do
		if player.Character then
			player.Character:PivotTo(gameSpawn.CFrame + Vector3.new(0, 3, 0))
		end
	end

	-------------------
	-- CHAIR LOGIC
	-------------------
	local totalChairs = #queuedPlayers - 1
	local fallInterval = cycleDuration / math.max(totalChairs, 1)
	local spawnedChairs = {}

	print("Spawning " .. totalChairs .. " chairs")
	task.wait(5)

	for i = 1, totalChairs do
		local chair = chairTemplate:Clone()
		chair.Parent = workspace
		table.insert(spawnedChairs, chair)

		chair:PivotTo(CFrame.new(
			math.random(-arenaRadius, arenaRadius),
			spawnHeight,
			math.random(-arenaRadius, arenaRadius)
			))

		-- Ensure it falls and stays intact
		for _, part in ipairs(chair:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true
			end
		end

		-- Weld chair together
		if chair.PrimaryPart then
			for _, part in ipairs(chair:GetDescendants()) do
				if part:IsA("BasePart") and part ~= chair.PrimaryPart then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = chair.PrimaryPart
					weld.Part1 = part
					weld.Parent = chair.PrimaryPart
				end
			end
		end

		task.wait(fallInterval)
	end

	-------------------
	-- ELIMINATION
	-------------------
	print("Eliminating non-sitters...")
	task.wait(3)

	for _, player in ipairs(queuedPlayers) do
		local character = player.Character
		print(character)

		if character then
			local humanoid = character:FindFirstChild("Humanoid")

			if humanoid and not humanoid.Sit then
				print(player.Name .. " was eliminated")

				-- teleport to spectator/lobby area instead of killing
				if lobbySpawn and character then
					character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
				else
					warn("Teleport failed: lobbySpawn or character is nil")
				end

				-- optional: mark them eliminated
				player:SetAttribute("Eliminated", true)
			end
		end
	end


	-------------------
	-- CLEANUP CHAIRS
	-------------------
	for _, chair in ipairs(spawnedChairs) do
		if chair and chair.Parent then
			chair:Destroy()
		end
	end
	-------------------
	-- CHECK WINNER
	-------------------

	local alivePlayers = {}

	for _, player in ipairs(queuedPlayers) do
		if player:GetAttribute("Eliminated") ~= true then
			table.insert(alivePlayers, player)
		end
	end

	if #alivePlayers == 1 then
		local winner = alivePlayers[1]

		print(winner.Name .. " won the game!")

		roundState.Value = winner.Name .. " won!"

		local leaderstats = winner:FindFirstChild("leaderstats")
		if leaderstats then
			local gamesWon = leaderstats:FindFirstChild("GamesWon")
			if gamesWon then
				gamesWon.Value += 1
			end
		end

		task.wait(5)

		-- reset all players for next round
		for _, player in ipairs(queuedPlayers) do
			player:SetAttribute("Eliminated", false)

			if player.Character then
				player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
			end
		end
		print("Game Ended")
		continue
	end
end
