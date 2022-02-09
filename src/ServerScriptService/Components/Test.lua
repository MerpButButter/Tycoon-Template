local Test = {}

Test.__index = Test

function Test.New(tycoon, instance)
	local self = setmetatable({}, Test)
	self.Tycoon = tycoon
	self.Instance = instance
	return self
end

function Test:Init()
end

return Test
