local Upgrader = {}
Upgrader.__index = Upgrader

function Upgrader.New(_tycoon, instance)
	local self = setmetatable({}, Upgrader)
	self.Instance = instance

	return self
end

function Upgrader:Init()
	self.Instance.Detector.Touched:Connect(function(...)
		self:OnTouch(...)
	end)
end

function Upgrader:OnTouch(hit)
	if not hit:GetAttribute("Worth") then
		return
	end

		hit:SetAttribute("Worth", hit:GetAttribute("Worth") * self.Instance:GetAttribute("Multiply"))
end

return Upgrader
