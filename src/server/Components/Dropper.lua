local dropsFolder = game:GetService("ServerStorage"):WaitForChild("Drops")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Dropper = {}
local tweenData = {}
tweenData.tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quart)
tweenData.Goal = { Transparency = 1 }

local function tweenDropFade(drop)
	if drop and time then
		local tween = TweenService:Create(drop, tweenData.tweenInfo, tweenData.Goal)
		tween:Play()
		Debris:AddItem(drop, 2)
		print("Destroyed")
	else
		return
	end
end

Dropper.__index = Dropper

function Dropper.New(tycoon, instance)
	local self = setmetatable({}, Dropper)
	self.Tycoon = tycoon
	self.Instance = instance
	self.Rate = instance:GetAttribute("Rate")
	self.DropTemplate = dropsFolder[instance:GetAttribute("Drop")]
	self.DropSpawn = instance.Spout.Spawn
	return self
end

function Dropper:Init()
	coroutine.wrap(function()
		while self.Instance.Parent do
			self:Drop()
			task.wait(self.Rate)
		end
	end)()
end

function Dropper:Drop()
	local drop = self.DropTemplate:Clone()
	drop.Position = self.DropSpawn.WorldPosition
	drop.Parent = self.Instance
	task.defer(function()
		task.wait(10)
		if drop.Parent == self.Instance then
			tweenDropFade(drop)
		else
			return
		end
	end)
end

return Dropper
