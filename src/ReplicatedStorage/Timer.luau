local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roundTimer = ReplicatedStorage:WaitForChild("RoundTimer")

local Timer = {}



function Timer.Start(mins, sec)
	local totalSeconds = mins * 60 + sec

	while totalSeconds >= 0 do
		roundTimer.Value = totalSeconds
		task.wait(1)
		totalSeconds -= 1
	end
end

return Timer
