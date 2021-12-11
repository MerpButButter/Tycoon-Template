local PlayerManager = require(game:GetService("ServerScriptService").Server:WaitForChild("PlayerManager"))
local Button = {}
Button.__index = Button

function Button.New(tycoon, part)
	local self = setmetatable({}, Button)
	self.Tycoon = tycoon
	self.Instance = part

	return self
end

function Button:Init()
	self.Prompt = self:CreatePrompt()
	self.Prompt.Triggered:Connect(function(...)
		self:Press(...)
	end)
end

function Button:CreatePrompt()
	local promt = Instance.new("ProximityPrompt")
	promt.HoldDuration = 0.5
	promt.ActionText = self.Instance:GetAttribute("Display")
	promt.ObjectText = "$" .. self.Instance:GetAttribute("Cost")
	promt.Parent = self.Instance
	return promt
end

function Button:Press(player)
	local id = self.Instance:GetAttribute("Id")
	local cost = self.Instance:GetAttribute("Cost")
	local money = PlayerManager.GetMoney(player)

	if player == self.Tycoon.Owner and money >= cost then
		PlayerManager.SetMoney(player, money - cost)
		self.Tycoon:PublishTopic("Button", id)
		self.Instance:Destroy()
	end
end

return Button
