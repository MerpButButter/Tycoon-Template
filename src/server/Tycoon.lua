local CollectionService = game:GetService("CollectionService")
local Template = game:GetService("ServerStorage").Template
local componentFolder = game:GetService("ServerScriptService").Server:WaitForChild("Components")
local tycoonStorage = game:GetService("ServerStorage").TycoonStorage
local playerManager = require(game:GetService("ServerScriptService").Server:WaitForChild("PlayerManager"))

local function NewModel(model, cframe)
	local newModel = model:Clone()
	newModel:SetPrimaryPartCFrame(cframe)
	newModel.Parent = workspace
	return newModel
end

local Tycoon = {}
Tycoon.__index = Tycoon

function Tycoon.new(player, spawnPoint)
	local self = setmetatable({}, Tycoon)
	self.Owner = player

	self._TopicEvent = Instance.new("BindableEvent")
	self._spawn = spawnPoint
	return self
end

function Tycoon:Init()
	self.Model = NewModel(Template, self._spawn.CFrame)
	self._spawn:SetAttribute("Occupied", true)
	self.Owner.RespawnLocation = self.Model.Spawn
	self.Owner:LoadCharacter()

	self:LockAll()
	self:WaitForExit()
end

function Tycoon:LockAll()
	for _, instance in ipairs(self.Model:GetDescendants()) do
		if CollectionService:HasTag(instance, "Unlockable") then
			self:Lock(instance)
		else
			self:AddComponents(instance)
		end
	end
end

function Tycoon:Lock(instance)
	instance.Parent = tycoonStorage
	self:CreateComponent(instance, componentFolder.Unlockable)
end

function Tycoon:Unlock(instance)
	CollectionService:RemoveTag(instance, "Unlockable")
	instance.Parent = self.Model
	self:AddComponents(instance)
end

function Tycoon:AddComponents(instance)
	for _, tag in ipairs(CollectionService:GetTags(instance)) do
		local component = componentFolder:FindFirstChild(tag)
		if component then
			self:CreateComponent(instance, component)
		end
	end
end

function Tycoon:CreateComponent(instance, componentScript)
	local compModule = require(componentScript)
	local newComp = compModule.New(self, instance)
	newComp:Init()
end

function Tycoon:PublishTopic(topicName, ...)
	self._TopicEvent:Fire(topicName, ...)
end

function Tycoon:SubscribeTopic(topicName, callback)
	local connection = self._TopicEvent.Event:Connect(function(name, ...)
		if name == topicName then
			callback(...)
		end
	end)
	return connection
end

function Tycoon:WaitForExit()
	playerManager.PlayerRemoving:Connect(function(player)
		if self.Owner == player then
			self:Destroy()
		end
	end)
end

function Tycoon:Destroy()
	self.Model:Destroy()
	self._spawn:SetAttribute("Occupied", false)
	self._TopicEvent:Destroy()
end

return Tycoon
