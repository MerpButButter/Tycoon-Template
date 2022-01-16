local PlayerManager = require(game:GetService("ServerScriptService").Server:WaitForChild("PlayerManager"))
local Bank = {}
Bank.__index = Bank

function Bank.New(tycoon, instance)
	local self = setmetatable({}, Bank)
	self.Tycoon = tycoon
	self.Instance = instance
	self.Balance = 0

	return self
end

function Bank:Init()
	self.Tycoon:SubscribeTopic("WorthChange", function(...)
		self:OnWorthChange(...)
	end)
	self.Instance.Pad.Touched:Connect(function(...)
		self:OnTouched(...)
	end)
end

function Bank:OnWorthChange(worth)
	self.Balance += worth
	self:SetDisplay("$" .. math.round(self.Balance))
end

function Bank:SetDisplay(str)
	self.Instance.Display.Money.Text = tostring(str)
end

function Bank:OnTouched(hitPart)
	local char = hitPart:FindFirstAncestorWhichIsA("Model")
	if char then
		local plr = game:GetService("Players"):GetPlayerFromCharacter(char)
		if plr and plr == self.Tycoon.Owner then
			local plrMoney = PlayerManager.GetMoney(plr) + self.Balance
			PlayerManager.SetMoney(plr, plrMoney)
			self.Balance = 0
			self:SetDisplay("$0")
		end
	end
end

return Bank
