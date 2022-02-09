if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local modToolModule = require(game:GetService("ReplicatedStorage").Source:WaitForChild("modTool"))
local CollectionService = game:GetService("CollectionService")

local melees = CollectionService:GetTagged("Melee")

-- Make character massless because of body velocity

Player.CharacterAdded:Connect(function(chr)
	for _, limb: BasePart in ipairs(chr:GetChildren()) do
		if limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart" then
			limb.Massless = true
		end
	end
end)

for _, limb: BasePart in ipairs(Character:GetChildren()) do
	if limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart" then
		limb.Massless = true
	end
end

for _, melee in ipairs(melees) do
	local modTool = modToolModule.New(Player, melee)

	modTool:Init()
end

CollectionService:GetInstanceAddedSignal("Melee"):Connect(function(melee)
	local modTool = modToolModule.New(Player, melee)

	modTool:Init()
end)

