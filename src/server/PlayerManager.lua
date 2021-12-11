local Players = game:GetService("Players")

local function LeaderboardSetup()
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats
	return leaderstats
end

local playerAdded = Instance.new("BindableEvent")
local playerRemoving = Instance.new("BindableEvent")

local PlayerManager = {}

PlayerManager.PlayerAdded = playerAdded.Event
PlayerManager.PlayerRemoving = playerRemoving.Event

function PlayerManager.Start()
	for _, player in ipairs(Players:GetPlayers()) do
		coroutine.wrap(PlayerManager.OnPlayerAdded)(player)
		coroutine.wrap(PlayerManager.OnPlayerRemoving)(player)
	end
	Players.PlayerAdded:Connect(PlayerManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerManager.OnPlayerRemoving)
end

function PlayerManager.OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		PlayerManager.OnCharacterAdded(player, char)
	end)
	local leaderstats = LeaderboardSetup()
	leaderstats.Parent = player

	playerAdded:Fire(player)
end

function PlayerManager.OnCharacterAdded(plr, char)
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.wait(3)
			plr:LoadCharacter()
		end)
	end
end

function PlayerManager.GetMoney(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Money = leaderstats:FindFirstChild("Money")
		if Money then
			return Money.Value
		end
	end
	return 0
end

function PlayerManager.SetMoney(player, value)
	if value then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local Money = leaderstats:FindFirstChild("Money")
			if Money then
				Money.Value = value
			end
		end
	end
end

function PlayerManager.OnPlayerRemoving(player)
	playerRemoving:Fire(player)
end

return PlayerManager
