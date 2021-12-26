local meleeData = require(script:WaitForChild("meleeData"))
local raycastHitbox = require(game:GetService("ReplicatedStorage"):WaitForChild("RaycastHitboxV4"))
local modTool = {}
modTool.__index = modTool

function modTool.New(player: Player, tool: Tool)
	local self = setmetatable({}, modTool)
	self.Player = player
	self.Tool = tool

	local toolData = self.Tool:GetAttribute("meleeData")
	self.toolSfx = {
		swingSfx = meleeData[toolData].SwingSfx,
		hitSfx = meleeData[toolData].HitSfx,
		plrHitSfx = meleeData[toolData].PlrHitSfx,
	}

	self.toolAnim = {
		idleAnim = meleeData[toolData].IdleAnim,
		walkAnim = meleeData[toolData].WalkAnim,
		swinganim = meleeData[toolData].SwingAnim,
	}

	self.toolDmg = meleeData[toolData].Dmg

	return self
end

function modTool:Init()
	print("Module initiated")

	self:Activated()
	self:Deactivated()
	self:Equipped()
	self:Unequipped()
end

-- Checks if player is dead and if tool exists
local function sanityCheck(tool: Tool, plr: Player)
	return plr.Character.Humanoid.Health <= 0 or not tool
end

-- TODO Add idle animation
-- TODO Add equip animation and make it so you cant attack until equip animation has played

--TODO Add motor6d WELDS so you can actually use the tool and make it RequireHandle = false
local idleTrack: AnimationTrack
function modTool:Equipped()
	self.Tool.Equipped:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end

		print("Equiped on module")
		-- Create the sounds to handle
		task.defer(function()
			for key, sound in pairs(self.toolSfx) do
				local sfx = Instance.new("Sound")
				sfx.Name = tostring(key)
				sfx.SoundId = "rbxassetid://" .. sound
				sfx.Parent = self.Tool.Handle
			end
		end)
		
		local idleAnim = Instance.new("Animation")
		idleAnim.AnimationId = "rbxassetid://" .. self.toolAnim.idleAnim
		idleTrack = self.Player.Character:WaitForChild("Humanoid"):WaitForChild("Animator"):LoadAnimation(idleAnim)

		idleTrack.Looped = true
		idleTrack:Play()
	end)
end

local newHitbox
local Activated

--TODO Add swing animation
function modTool:Activated()
	self.Tool.Activated:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end

		print("Activated on module")

		local soundLoc = self.Tool.Handle
		soundLoc.swingSfx:Play()

		local Params = RaycastParams.new()
		Params.FilterDescendantsInstances = { self.Tool:GetChildren(), self.Player.Character }
		Params.FilterType = Enum.RaycastFilterType.Blacklist

		newHitbox = raycastHitbox.new(self.Tool.Blade)
		newHitbox.RaycastParams = Params

		newHitbox.OnHit:Connect(function(hit, humanoid: Humanoid)
			if sanityCheck(self.Tool, self.Player) then
				return
			end

			print(hit)

			soundLoc.plrHitSfx:Play()
			humanoid:TakeDamage(self.toolDmg)
		end)

		newHitbox:HitStart()
		Activated = true
	end)
end

function modTool:Deactivated()
	self.Tool.Deactivated:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end

		print("Deactivated on module")

		if newHitbox and Activated then
			newHitbox:HitStop()
			Activated = false
		end
	end)
end

function modTool:Unequipped()
	self.Tool.Unequipped:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end
		-- Delete sounds from handle
		task.defer(function()
			if sanityCheck(self.Tool, self.Player) then
				return
			end

			if self.Tool and self.Tool:FindFirstChild("Handle") then
				for _, child in ipairs(self.Tool.Handle:GetChildren()) do
					if child:IsA("Sound") then
						child:Destroy()
					end
				end
			end
			--
			if idleTrack then
				idleTrack:Stop()
			end
			if newHitbox and Activated then
				newHitbox:Destroy()
				Activated = false
			end

			print("Unequipped on module")
		end)
	end)
end

return modTool
