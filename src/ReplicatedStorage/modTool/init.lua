-----------------------------------------------------------------------------------------------

-- SetUp

-----------------------------------------------------------------------------------------------
local Debris = game:GetService("Debris")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rand = Random.new()

local raycastHitbox = require(ReplicatedStorage:WaitForChild("RaycastHitboxV4"))
local camera = workspace:WaitForChild("Camera")
local shake = require(ReplicatedStorage.Packages:WaitForChild("shake"))
local meleeData = require(ReplicatedStorage.Source:WaitForChild("meleeData"))
local hitEffectHandler = require(ReplicatedStorage.HitEffectHandler)
local HitboxService = require(ReplicatedStorage:WaitForChild("HitboxService"))
-----------------------------------------------------------------------------------------------
local modTool = {}
modTool.__index = modTool

-----------------------------------------------------------------------------------------------
function modTool.New(player: Player, tool: Tool)
	local self = setmetatable({}, modTool)
	self.Player = player
	self.Tool = tool

	local toolData = meleeData[tool.Name]

	if toolData then
		local specs = toolData.Specs

		self.Dmg = specs.Damage
		self.Cooldown = specs.Cooldown
		self.Amplitude = specs.Shake or 0
		self.Sfx = toolData.Sounds
		self.Anims = toolData.Animations
		self.Hitbox = specs.HitBox(player, tool)
		self.TrailSpecs = specs.Trail

		self.Runnable = true
	else
		warn("The melee data table can't find data on:", tool.Name)
		-- So it doesn't runs INIT
		self.Runnable = false
	end
	return self
end

local function tableCount(table)
	if typeof(table) ~= "table" then
		warn("Not a table")
		return 0
	end
	local length = 0
	for _, _ in pairs(table) do
		length += 1
	end
	return length
end

local function createClass(parent, className: string, id: string | table, name: string?)
	if not id then
		return
	end

	warn(id)
	if className == "Animation" then
		local anim: Animation
		if typeof(id) == "table" and tableCount(id) > 1 then
			for i, soundData in pairs(id) do
				anim = Instance.new("Animation")
				warn("ANIMS", soundData)
				anim.AnimationId = soundData
				anim.Name = (name .. i) or "Animation"
				anim.Parent = parent
			end
		else
			anim = Instance.new("Animation")
			anim.AnimationId = id
			anim.Name = name or "Animation"
			anim.Parent = parent
		end

		return anim
	elseif className == "Sound" then
		local sound: Sound
		if typeof(id) == "table" and tableCount(id.ID) > 1 then
			for i, soundData in pairs(id.ID) do
				sound = Instance.new("Sound")
				sound.SoundId = soundData
				sound.Volume = id.Volume or 1
				sound.PlaybackSpeed = id.PlaybackSpeed or 1
				sound.Name = (name .. i) or "Sound"
				sound.Parent = parent
			end
		else
			sound = Instance.new("Sound")
			sound.SoundId = id.ID
			sound.Volume = id.Volume or 1
			sound.PlaybackSpeed = id.PlaybackSpeed or 1
			sound.Name = name or "Sound"
			sound.Parent = parent
		end

		return sound
	end
end

local function createFolder(name: string, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local animationFolder: Folder
local soundFolder: Folder

-----------------------------------------------------------------------------------------
-- Init Function that runs all other sub functions and sets up Trails and Folders with objects
function modTool:Init()
	if not self.Runnable then
		return
	end
	-----------------------------------------------------------------------------------------
	-- Prep
	--------------------------------
	-- Trail Setup
	self.Trail = self.TrailSpecs.Instance:Clone()
	local attach0, attach1 = self.TrailSpecs.Attachments(self.Player, self.Tool)
	self.Trail.Attachment0 = attach0
	self.Trail.Attachment1 = attach1
	self.Trail.Parent = self.Hitbox
	warn("TRAIL SETUP")
	-----------------------------------------------------------------------------------------
	--Create folders with sounds and animations
	animationFolder = createFolder("Animations", self.Tool)
	soundFolder = createFolder("Sounds", self.Tool)

	for name, sfxData: table in pairs(self.Sfx) do
		createClass(soundFolder, "Sound", sfxData, tostring(name))
	end

	for name, animData: table in pairs(self.Anims) do
		createClass(animationFolder, "Animation", animData, tostring(name))
	end

	-----------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------
	self:Equipped()
	self:Unequipped()
end

-- Checks if player is dead and if tool exists
local function sanityCheck(tool: Tool, plr: Player, hitbox: BasePart)
	return not (plr or plr.Character or plr.Character.PrimaryPart or tool or hitbox)
end

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

local newHitbox
local Activated
local cooldown
local removedConnect: RBXScriptConnection
local handleRemovedConnect: RBXScriptConnection
local playingTracks = {}

--------------------------------------------------------------------------------------------
-- Init Functions

--------------------------------------------------------------------------------------------
function modTool:Equipped()
	self.Tool.Equipped:Connect(function()
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end

		local idleAnim = self.Tool.Animations.Idle
		local idleTrack = self.Player.Character.Humanoid.Animator:LoadAnimation(idleAnim)
		table.insert(playingTracks, idleTrack)
		idleTrack.Looped = true
		idleTrack:Play(0.05)

		local equipSfx = self.Tool.Sounds.Equip
		equipSfx:Play()
		----------------------------------------------------------------
		-- Setup -------------------------------------------------------
		local swingAnims = {}
		for _, animation: Instance in ipairs(self.Tool:WaitForChild("Sounds"):GetChildren()) do
			if animation.Name:match("Swing")  and animation:IsA("Animation") then
				table.insert(swingAnims, animation)
			end
		end
		----------------------------------------------------------------
		ContextActionService:BindAction("Swing", function(_, inputState, _inputObject: InputObject)
			if inputState ~= Enum.UserInputState.Begin then
				return
			end
			if sanityCheck(self.Tool, self.Player, self.Hitbox) then
				return
			end
			if cooldown then
				return
			end
			cooldown = true

			self.Sfx.Swing:Play()

			-- local priority = Enum.RenderPriority.Last.Value

			-- local swingShake = shake.new()
			-- swingShake.FadeInTime = 0
			-- swingShake.Frequency = 0.1
			-- swingShake.Amplitude = self.Amplitude
			-- swingShake.RotationInfluence = Vector3.new(0.1, 0.1, 0.1)

			-- swingShake:Start()
			-- swingShake:BindToRenderStep(shake.NextRenderName(), priority, function(pos, rot)
			-- 	camera.CFrame *= CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
			-- end)

			bodyForce(self.Player.Character.Humanoid, 1)



			local swingTrack = self.Player.Character
				:WaitForChild("Humanoid")
				:WaitForChild("Animator")
				:LoadAnimation(swingAnims[Rand:NextInteger(1,#swingAnims)])
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
				if sanityCheck(self.Tool, self.Player, self.Hitbox) then
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
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end

		local db = true
		ContextActionService:UnbindAction("Swing")

		if newHitbox and Activated then
			newHitbox:Destroy()
			Activated = false
		end

		for _, track: AnimationTrack in ipairs(playingTracks) do
			track:Stop()
		end

		if db then
			db = false
			local toolClone = game:GetService("StarterPack")[self.Tool.Name]:Clone()
			toolClone.Parent = self.Player.Backpack
			self.Tool:Destroy()
		end
	end)

	handleRemovedConnect = self.Tool.Handle.ChildRemoved:Connect(function()
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end

		local db = true
		ContextActionService:UnbindAction("Swing")

		for _, track: AnimationTrack in ipairs(playingTracks) do
			track:Stop()
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
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end

		ContextActionService:UnbindAction("Swing")

		for _, track: AnimationTrack in ipairs(playingTracks) do
			track:Stop()
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
