if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Player = game:GetService("Players").LocalPlayer
local modToolModule = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("modTool"))
local CollectionService = game:GetService("CollectionService")

local melees = CollectionService:GetTagged("Melee")

for _, melee in ipairs(melees) do
	print(melee)
	local modTool = modToolModule.New(Player, melee)

	modTool:Init()
end
