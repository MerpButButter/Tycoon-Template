local DataStoreService = game:GetService("DataStoreService")
local player = game:GetService("Players")

local moneyStore = DataStoreService:GetDataStore("Money")
local playerCount = 0
local playerLeaveEvent = Instance.new("BindableEvent")

player.PlayerAdded:Connect(function(plr)
	local leaderstats = plr:WaitForChild("leaderstats")
	local money = Instance.new("IntValue")
	money.Name = "Coins"
	money.Parent = leaderstats

	local savedData
	local success = pcall(function()
		savedData = moneyStore:GetAsync(plr.UserId)
	end)
	if success then
		if savedData then
			money.Value = savedData
		end
	end
	playerCount += 1
end)

player.PlayerRemoving:Connect(function(plr)
	local money = plr.leaderstats.Coins
	pcall(function()
		moneyStore:SetAsync(plr.UserId, money.Value)
	end)
	playerCount -= 1
	playerLeaveEvent:Fire()
end)

game:BindToClose(function()
	while playerCount > 0 do
		playerLeaveEvent.Event:Wait()
	end
end)
