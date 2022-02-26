local Tycoon = require(script.Parent.Tycoon)
local PlayerManager = require(script.Parent.PlayerManager)

local function findSpawn()
	for _, spawnPoint in ipairs(workspace:WaitForChild("Spawns"):GetChildren()) do
		if not spawnPoint:GetAttribute("Occupied") then
			return spawnPoint
		end
	end
end

PlayerManager.Start()

PlayerManager.PlayerAdded:Connect(function(player)
	local tycoon = Tycoon.new(player, findSpawn())
	tycoon:Init()
end)
