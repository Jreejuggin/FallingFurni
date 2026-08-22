local playerService = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local playerData = DataStoreService:GetDataStore("PlayerData")

--When player leaves the game, save their stats
playerService.PlayerRemoving:Connect(function(player)
	local playerUserId = "Player_"..player.UserId
	local playerData = {
		player.leaderstats.GamesWon.Value
	}
	
	playerData:SetAsync(playerUserId, playerData)
end)

--When player joins the game, load saved game stats
playerService.PlayerAdded:Connect(function(player)
	local playerUserId = "Player_"..player.UserId
	local playerData = playerData:GetAsync(playerUserId)
	
	if playerData then
		player.leaderstats.GamesWon.Value = playerData.GamesWon --load saved data
	else
		player.leaderstats.GamesWon.Value = 0 -- if no saved data, set to 0 (initial value)
		playerData:SetAsync(playerUserId, 0)
	end
	
	local leaderstats = player:WaitForChild("leaderstats")
	leaderstats.GamesWon.Value = playerData.GamesWon

end)

