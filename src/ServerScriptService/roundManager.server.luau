--local Players = game:GetService("Players")
--local Workspace = game:GetService("Workspace")

--local lobbySpawn = Workspace:WaitForChild("LobbySpawn")
--local gameSpawn = Workspace:WaitForChild("GameSpawn")

--local roundLength = 40
--local intermission = 10

--while true do
--	-- INTERMISSION (Lobby time)
--	lobbySpawn.Enabled = true
--	gameSpawn.Enabled = false

--	for _, player in ipairs(Players:GetPlayers()) do
--		if player.Character then
--			player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
--		end
--	end

--	wait(intermission)

--	-- START GAME
--	lobbySpawn.Enabled = false
--	gameSpawn.Enabled = true

--	for _, player in ipairs(Players:GetPlayers()) do
--		if player.Character then
--			player.Character:PivotTo(gameSpawn.CFrame + Vector3.new(0, 3, 0))
--		end
--	end

--	wait(roundLength)

--	-- KILL OR RESET PLAYERS
--	for _, player in ipairs(Players:GetPlayers()) do
--		if player.Character then
--			player.Character:BreakJoints() -- forces respawn
--		end
--	end

--	wait(5)
--end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local lobbySpawn = Workspace:WaitForChild("lobbySpawn")
local gameSpawn = Workspace:WaitForChild("gameSpawn")

local roundLength = 40
local intermission = 10

while true do
	 --LOBBY
	lobbySpawn.Enabled = true
	gameSpawn.Enabled = false

	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Wait()
		player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 3, 0))
	end

	wait(intermission)

	-- GAME
	lobbySpawn.Enabled = false
	gameSpawn.Enabled = true

	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Wait()
		player.Character:PivotTo(gameSpawn.CFrame + Vector3.new(0, 3, 0))
	end

	wait(roundLength)

	-- RESET
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			player.Character:BreakJoints()
		end
	end

	wait(5)
end

