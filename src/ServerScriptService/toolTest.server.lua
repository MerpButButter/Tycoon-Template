print("WAITED")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local modToolModule = require(ServerStorage.Source.modTool)
local CollectionService = game:GetService("CollectionService")

local melees = CollectionService:GetTagged("Melee")

-- Make character massless because of body velocity
local Player: Player
local Character
for _, player in ipairs(Players:GetPlayers()) do
	Player = player
	Character = player.Character or player.CharacterAdded:Wait()

	for _, melee in ipairs(melees) do
		local modTool = modToolModule.New(Player, melee)

		modTool:Init()
	end
end
Players.PlayerAdded:Connect(function(plr)
	Player = plr
	Player.CharacterAdded:Connect(function(chr)
		Character = chr
		for _, limb: BasePart in ipairs(chr:GetChildren()) do
			if limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart" then
				limb.Massless = true
			end
		end
	end)
end)

CollectionService:GetInstanceAddedSignal("Melee"):Connect(function(melee)
	local modTool = modToolModule.New(Player, melee)

	modTool:Init()
end)
