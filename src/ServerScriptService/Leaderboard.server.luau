local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local gamesWon = Instance.new("IntValue")
	gamesWon.Name = "GamesWon"
	gamesWon.Value = 0
	gamesWon.Parent = leaderstats
end)