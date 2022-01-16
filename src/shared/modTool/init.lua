local Debris = game:GetService("Debris")
local ContextActionService = game:GetService("ContextActionService")
local shake = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("shake"))
local camera = workspace:WaitForChild("Camera")
local hitEffectHandler = require(game:GetService("ReplicatedStorage").HitEffectHandler)
local ContentProvider = game:GetService("ContentProvider")
local raycastHitbox = require(game:GetService("ReplicatedStorage"):WaitForChild("RaycastHitboxV4"))
local modTool = {}
modTool.__index = modTool

function modTool.New(player: Player, tool: Tool)
	local self = setmetatable({}, modTool)
	self.Player = player
	self.Tool = tool

	self.Dmg = self.Tool:GetAttribute("Damage")
	self.Cooldown = self.Tool:GetAttribute("Cooldown")
	self.Amplitude = self.Tool:GetAttribute("Shake")
	self.Sfx = self.Tool:WaitForChild("Sounds")
	self.Anims = self.Tool:WaitForChild("Animations")

	return self
end

function modTool:Init()
	-- Loads anims and sounds
	ContentProvider:PreloadAsync(self.Anims:GetChildren())
	ContentProvider:PreloadAsync(self.Sfx:GetChildren())
	self:Equipped()
	self:Unequipped()
end

-- Checks if player is dead and if tool exists
local function sanityCheck(tool: Tool, plr: Player)
	return plr.Character.Humanoid.Health <= 0 or not tool
end

local newHitbox
local Activated
local cooldown
local removedConnect: RBXScriptConnection
local handleRemovedConnect: RBXScriptConnection

local function bodyForce(humanoid: Humanoid, amount: number, parent: Instance?)
	local bodForce = Instance.new("BodyVelocity")

	local primaryPart = humanoid.RootPart

	local lookVector = primaryPart.CFrame.LookVector

	local force = 5000
	bodForce.MaxForce = Vector3.new(force, 0, force)
	bodForce.P = 200
	bodForce.Velocity = lookVector.Unit * amount

	bodForce.Parent = parent or primaryPart
	Debris:AddItem(bodForce, 0.5)
end

local idleTrack: AnimationTrack
function modTool:Equipped()
	self.Tool.Equipped:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end

		idleTrack = self.Player.Character
			:WaitForChild("Humanoid")
			:WaitForChild("Animator")
			:LoadAnimation(self.Anims.Idle)

		idleTrack.Looped = true
		idleTrack:Play(0.05)

		ContextActionService:BindAction("Swing", function(_, inputState, _inputObject: InputObject)
			if inputState ~= Enum.UserInputState.Begin then
				return
			end
			if sanityCheck(self.Tool, self.Player) then
				return
			end
			if cooldown then
				return
			end
			cooldown = true

			self.Sfx.Swing:Play()

			local priority = Enum.RenderPriority.Last.Value

			local swingShake = shake.new()
			swingShake.FadeInTime = 0
			swingShake.Frequency = 0.1
			swingShake.Amplitude = self.Amplitude
			swingShake.RotationInfluence = Vector3.new(0.1, 0.1, 0.1)

			swingShake:Start()
			swingShake:BindToRenderStep(shake.NextRenderName(), priority, function(pos, rot)
				camera.CFrame *= CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
			end)

			bodyForce(self.Player.Character.Humanoid, 1)
			local swingTrack: AnimationTrack = self.Player.Character
				:WaitForChild("Humanoid")
				:WaitForChild("Animator")
				:LoadAnimation(self.Anims.Swing1)
			swingTrack:Play(0.05)

			local Params = RaycastParams.new()
			Params.FilterDescendantsInstances = { self.Tool:GetChildren(), self.Player.Character }
			Params.FilterType = Enum.RaycastFilterType.Blacklist
			if not self.Tool.Blade then
				return
			end
			newHitbox = raycastHitbox.new(self.Tool.Blade)
			newHitbox.RaycastParams = Params

			newHitbox.OnHit:Connect(function(_hit, humanoid: Humanoid)
				if sanityCheck(self.Tool, self.Player) then
					return
				end
				if humanoid.Health <= 0 then
					return
				end

				local particleEffect = hitEffectHandler.new(
					humanoid.RootPart,
					game:GetService("ReplicatedStorage").Effects:WaitForChild("MainPar"),
					1,
					1
				)

				particleEffect:GenerateParticles()

				local meshEffect = hitEffectHandler.new(
					humanoid.RootPart,
					game:GetService("ReplicatedStorage").Effects:WaitForChild("MeshStick"),
					0.25,
					10
				)
				meshEffect:MeshExplode()

				bodyForce(self.Player.Character.Humanoid, 5, humanoid.RootPart)

				self.Sfx.Hit:Play()
				humanoid:TakeDamage(self.Dmg)
			end)

			newHitbox:HitStart()
			Activated = true
			swingTrack.Stopped:Connect(function()
				if newHitbox and Activated then
					newHitbox:HitStop()
					Activated = false
				end
				task.wait(self.Cooldown)
				cooldown = false
			end)
		end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.E)
		ContextActionService:SetPosition("Swing", UDim2.fromScale(24, 230))
	end)
	removedConnect = self.Tool.ChildRemoved:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end
		local db = true
		ContextActionService:UnbindAction("Swing")
		if idleTrack then
			idleTrack:Stop()
		end
		if newHitbox and Activated then
			newHitbox:Destroy()
			Activated = false
		end
		if db then
			db = false
			local toolClone = game:GetService("StarterPack")[self.Tool.Name]:Clone()
			toolClone.Parent = self.Player.Backpack
			self.Tool:Destroy()
		end
	end)

	handleRemovedConnect = self.Tool.Handle.ChildRemoved:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end
		local db = true
		ContextActionService:UnbindAction("Swing")
		if idleTrack then
			idleTrack:Stop()
		end
		if newHitbox and Activated then
			newHitbox:Destroy()
			Activated = false
		end
		if db then
			db = false
			local toolClone = game:GetService("StarterPack")[self.Tool.Name]:Clone()
			toolClone.Parent = self.Player.Backpack
			self.Tool:Destroy()
		end
	end)
end

function modTool:Unequipped()
	self.Tool.Unequipped:Connect(function()
		if sanityCheck(self.Tool, self.Player) then
			return
		end
		--
		ContextActionService:UnbindAction("Swing")
		if idleTrack then
			idleTrack:Stop()
		end
		if newHitbox and Activated then
			newHitbox:Destroy()
			Activated = false
		end
		handleRemovedConnect:Disconnect()
		removedConnect:Disconnect()
	end)
end

return modTool
