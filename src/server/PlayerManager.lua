local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local playerData = DSS:GetDataStore("Tycoon")

local function LeaderboardSetup(value)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = value
	money.Parent = leaderstats
	return leaderstats
end

local function LoadData(plr)
	local success, result = pcall(function()
		return playerData:GetAsync(plr.UserId)
	end)
	if not success then
		warn(result)
	end
	return success, result
end

local function SaveData(plr, data)
	local success, result = pcall(function()
		playerData:SetAsync(plr.UserId, data)
	end)
	if not success then
		warn(result)
	end
	return success
end

local sessionData = {}

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

	game:BindToClose(PlayerManager.OnClose)
end

function PlayerManager.OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		PlayerManager.OnCharacterAdded(player, char)
	end)

	local success, data = LoadData(player)
	sessionData[player.UserId] = success and data or {
		Money = 0,
		UnlockIds = {}
	}

	local leaderstats = LeaderboardSetup(PlayerManager.GetMoney(player))
	leaderstats.Parent = player

	playerAdded:Fire(player)
end

function PlayerManager.OnCharacterAdded(plr, char)
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid and plr then
		humanoid.Died:Connect(function()
			task.wait(3)
			plr:LoadCharacter()
		end)
	end
end

function PlayerManager.GetMoney(player)
	return sessionData[player.UserId].Money
end

function PlayerManager.SetMoney(player, value)
	if value then
		sessionData[player.UserId].Money = value
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local Money = leaderstats:FindFirstChild("Money")
			if Money then
				Money.Value = value
			end
		end
	end
end

function PlayerManager.AddUnlockId(player, id)
	local data = sessionData[player.UserId].UnlockIds

	if not table.find(data, id) then
		table.insert(data, id)
	end
end

function PlayerManager.GetUnlockIds(player)
	return sessionData[player.UserId].UnlockIds
end

function PlayerManager.OnPlayerRemoving(player)
	SaveData(player, sessionData[player.UserId])
	playerRemoving:Fire(player)
end

function PlayerManager.OnClose()
	for _, player in ipairs(Players:GetPlayers()) do
		coroutine.wrap(PlayerManager.OnPlayerRemoving(player))()
	end
end

return PlayerManager
