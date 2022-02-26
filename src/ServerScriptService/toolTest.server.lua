local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TAG_NAME = "Melee"

local MODTOOL = require(ServerStorage.Source.ModTool)
local ModuleTool =  ServerStorage.Source.ModTool


local function createFolder(name: string, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- Create Remotes
local remoteFolder = createFolder("ToolRemotes", ReplicatedStorage)
local onInputRemote = Instance.new("RemoteEvent")
onInputRemote.Name = "OnInput"
onInputRemote.Parent = remoteFolder


-- Make character massless because of body velocity
Players.PlayerAdded:Connect(function(plr)
	-- Create a screen gui so you can get input
	local ScriptGUI: ScreenGui
	if not plr.PlayerGui:FindFirstChild("LocalScript") then
		ScriptGUI = Instance.new("ScreenGui")
		ScriptGUI.ResetOnSpawn = false
		ScriptGUI.Parent = plr.PlayerGui
	end
	if not ScriptGUI:FindFirstChild("ClientTool") then
		local localScript: LocalScript = ModuleTool.ClientTool:Clone()
		localScript.Parent = ScriptGUI
		localScript.Disabled = false
	end
	plr.CharacterAdded:Connect(function(chr)
		for _, limb: BasePart in ipairs(chr:GetChildren()) do
			if limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart" then
				limb.Massless = true
			end
		end
	end)
end)

for _, melee: Tool in ipairs(CollectionService:GetTagged(TAG_NAME)) do
	if not (melee:FindFirstAncestorOfClass("StarterPack")) then
		local MOD = MODTOOL(melee)
		MOD:Setup()
	end
end

CollectionService:GetInstanceAddedSignal("Melee"):Connect(function(melee)
	if not (melee:FindFirstAncestorOfClass("StarterPack")) then
	local MOD = MODTOOL(melee)
	MOD:Setup()
end
end)
