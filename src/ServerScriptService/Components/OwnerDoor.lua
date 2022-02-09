local ownerDoor = {}
ownerDoor.__index = ownerDoor

function ownerDoor.New(tycoon, instance)
	local self = setmetatable({}, ownerDoor)
	self.Tycoon = tycoon
	self.Instance = instance
	self.openButton = self.Instance.openButton
	self.closeButton = self.Instance.closeButton
	self.killPart = self.Instance.killPart
	self.Owner = self.Tycoon.Owner

	return self
end

function ownerDoor:Init()
	self:Open()
	self:Close()
end

local touchConnect: RBXScriptConnection
function ownerDoor:Open()
	self.openButton.ClickDetector.MouseClick:Connect(function(plrhc)
		if plrhc.Name ~= self.Owner.Name then
			return
		end
		self.openButton.Material = Enum.Material.Neon
		self.closeButton.Material = Enum.Material.Plastic

		self.killPart.Transparency = 0.5
		touchConnect = self.killPart.Touched:Connect(function(hit)
			if hit.Parent.Name == self.Owner.Name then
				return
			end

			if game:GetService("Players"):GetPlayerFromCharacter(hit.Parent) then
				hit.Parent.Humanoid:TakeDamage(100)
			end
		end)
	end)
end

function ownerDoor:Close()
	self.closeButton.ClickDetector.MouseClick:Connect(function(plrhc)
		if plrhc.Name ~= self.Owner.Name then
			return
		end

		self.killPart.Transparency = 0.9
		if touchConnect then
			touchConnect:Disconnect()
		end
		self.openButton.Material = Enum.Material.Plastic
		self.closeButton.Material = Enum.Material.Neon
	end)
end

return ownerDoor

