local Conveyor = {}
Conveyor.__index = Conveyor

function Conveyor.New(tycoon, instance)
	local self = setmetatable({}, Conveyor)
	self.Tycoon = tycoon
	self.Instance = instance
	self.Speed = instance:GetAttribute("Speed")

	return self
end

function Conveyor:Init()
	local belt = self.Instance.Belt
	belt.AssemblyLinearVelocity = belt.CFrame.LookVector * self.Speed
end

return Conveyor
