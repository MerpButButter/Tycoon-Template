-----------------------------------------------------------------------------------------------

-- SetUp

-----------------------------------------------------------------------------------------------
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rand = Random.new()

local TAG_NAME = "Melee"
local camera = workspace:WaitForChild("Camera")
local shake = require(ReplicatedStorage.Packages:WaitForChild("shake"))
local meleeData = require(ServerStorage.Source.meleeData)
local hitEffectHandler = require(ReplicatedStorage.HitEffectHandler)
local HitboxService = require(ReplicatedStorage:WaitForChild("HitboxService"))
-----------------------------------------------------------------------------------------------
local modTool = {}
modTool.__index = modTool

type table = { [any]: any }

-----------------------------------------------------------------------------------------------
function modTool.New(tool: Tool)
	local self = setmetatable({}, modTool)
	self.Tool = tool
	self.Player = self:GetOwner()

	print(".NEW TOOL FUNCTION")
	local toolData = meleeData[tool.Name]

	if toolData then
		local specs = toolData.Specs

		self.Dmg = specs.Damage
		self.Cooldown = specs.Cooldown
		self.Amplitude = specs.Shake or 0
		self.Sfx = toolData.Sounds
		self.Anims = toolData.Animations
		self.Hitbox = specs.HitBox(self.Player, tool)
		self.TrailSpecs = specs.Trail

		self.Runnable = true
	else
		warn("Can't find data on:", tool.Name)
		-- So it doesn't runs INIT
		self.Runnable = false
	end
	return self
end

local function tableCount(table)
	if typeof(table) ~= "table" then
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

	if className == "Animation" then
		local anim: Animation
		if typeof(id) == "table" and tableCount(id) > 1 then
			for i, soundData in pairs(id) do
				anim = Instance.new("Animation")
				anim.AnimationId = soundData
				anim.Name = (name .. i) or "Animation"
				anim.Parent = parent
			end
		else
			local animID = id :: string
			anim = Instance.new("Animation")
			anim.AnimationId = animID
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
			local tableID = id :: table
			sound = Instance.new("Sound")
			sound.SoundId = tableID.ID
			sound.Volume = tableID.Volume or 1
			sound.PlaybackSpeed = tableID.PlaybackSpeed or 1
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

local function findClass(loc: Instance, name: string, classType: any): table
	local classObjects = {}
	for _, class: Instance in ipairs(loc:GetChildren()) do
		if class.Name:match(name) and class:IsA(classType) then
			table.insert(classObjects, class)
		end
	end

	return classObjects
end

local animationFolder: Folder
local soundFolder: Folder

local swingAnims: table
local swingSfx: table
local hitSfx: table

local onInputRemote: RemoteEvent
-----------------------------------------------------------------------------------------
-- Init Function that runs all other sub functions and sets up Trails and Folders with objects
function modTool:Setup()
	if not self.Runnable then
		return
	end
	-----------------------------------------------------------------------------------------
	-- Prep
	onInputRemote = ReplicatedStorage:WaitForChild("ToolRemotes"):FindFirstChild("OnInput")
	--------------------------------
	-- Trail Setup
	if not self.Hitbox:FindFirstChildOfClass("Trail") then
		self.Trail = self.TrailSpecs.Instance:Clone()
		local attach0, attach1 = self.TrailSpecs.Attachments(self.Player, self.Tool)
		self.Trail.Attachment0 = attach0
		self.Trail.Attachment1 = attach1
		self.Trail.Parent = self.Hitbox
	end
	-----------------------------------------------------------------------------------------
	-- Create folders with sounds and animations
	if not self.Tool:FindFirstChildOfClass("Folder") then
		animationFolder = createFolder("Animations", self.Tool)
		soundFolder = createFolder("Sounds", self.Tool)

		for name, sfxData: table in pairs(self.Sfx) do
			createClass(soundFolder, "Sound", sfxData, tostring(name))
		end

		for name, animData: table in pairs(self.Anims) do
			createClass(animationFolder, "Animation", animData, tostring(name))
		end
	end
	----------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Parenting the local script
	-----------------------------------------------------------------------------------------
	-- Getting Animation and Sound Setup ----------------------------------------------------
	swingAnims = findClass(self.Tool:WaitForChild("Animations"), "Swing*", "Animation")
	swingSfx = findClass(self.Tool:WaitForChild("Sounds"), "Swing*", "Sound")
	hitSfx = findClass(self.Tool:WaitForChild("Sounds"), "Hit*", "Sound")
	----------------------------------------------------------------
	-----------------------------------------------------------------------------------------
	self:Equipped()
	self:Unequipped()
end

-- Checks if player is dead and if tool exists
local function sanityCheck(tool: Tool, plr: Player, hitbox: BasePart)
	local character = plr.Character
	return not (plr or plr.Character or plr.Character.Humanoid.Health <= 0 or character.PrimaryPart or tool or hitbox)
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
local Params
local cooldown
local removedConnect: RBXScriptConnection
local handleRemovedConnect: RBXScriptConnection
local playingTracks = {}
local lastHit = {}

--------------------------------------------------------------------------------------------
-- Init Functions

--------------------------------------------------------------------------------------------
function modTool:Equipped()
	self.Tool.Equipped:Connect(function()
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end

		self.Hitbox:SetNetworkOwner(nil)
		local idleAnim = self.Tool.Animations.Idle
		local idleTrack = self.Player.Character.Humanoid.Animator:LoadAnimation(idleAnim)
		table.insert(playingTracks, idleTrack)
		idleTrack.Looped = true
		idleTrack:Play(0.05)

		Params = OverlapParams.new()
		Params.FilterDescendantsInstances = { self.Tool:GetChildren(), self.Player.Character }
		Params.FilterType = Enum.RaycastFilterType.Blacklist

		local equipSfx = self.Tool.Sounds.Equip
		equipSfx:Play()
		----------------------------------------------------------------
		-- Attack Initialization
		----------------------------------------------------------------
		onInputRemote.OnServerEvent:Connect(function(_player, _atkname, tool: Tool)
			if CollectionService:HasTag(tool, TAG_NAME) and tool == self.Tool then
				self:Swing(self.Player, self.Tool)
			end
		end)

		----------------------------------------------------------------

		removedConnect = self.Tool.ChildRemoved:Connect(function()
			if sanityCheck(self.Tool, self.Player, self.Hitbox) then
				return
			end

			if newHitbox and Activated then
				newHitbox:Stop()
				Activated = false
			end

			for _, track: AnimationTrack in ipairs(playingTracks) do
				track:Stop()
			end

			Debris:AddItem(self.Tool)
			table.clear(lastHit)
		end)

		local removedItems = {}
		handleRemovedConnect = self.Tool.Handle.ChildRemoved:Connect(function(instance: Instance)
			if sanityCheck(self.Tool, self.Player, self.Hitbox) then
				return
			end
			-- So it give you the tool multiple times
			local model = instance:FindFirstAncestorOfClass("Model")
			if not model then
				return
			end
			if table.find(removedItems, model) then
				return
			end

			table.insert(removedItems, model)

			for _, track: AnimationTrack in ipairs(playingTracks) do
				track:Stop()
			end
			table.clear(playingTracks)

			if newHitbox:GetState() and Activated then
				newHitbox:Destroy()
				Activated = false
			end

			Debris:AddItem(self.Tool)
			table.clear(removedItems)
			table.clear(lastHit)
		end)
		--------------------------------------
	end)
end

function modTool:Unequipped()
	self.Tool.Unequipped:Connect(function()
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end

		for _, track: AnimationTrack in ipairs(playingTracks) do
			track:Stop()
		end
		table.clear(playingTracks)

		if newHitbox:GetState() and Activated then
			pcall(function()
				newHitbox:Destroy()
				Activated = false
			end)
		end

		handleRemovedConnect:Disconnect()
		removedConnect:Disconnect()
		table.clear(lastHit)
	end)
end

-------------------------------------------------------------------------------------------------
-- Attacks
cooldown = false
function modTool:Swing(player: Player, _tool: Tool)
	local tool = player.Character:FindFirstChildOfClass("Tool")
	if sanityCheck(tool, player, tool:FindFirstChild(self.Hitbox.Name)) then
		return
	end
	if cooldown then
		return
	end
	-- Cooldown
	task.spawn(function()
		cooldown = true
		task.wait(self.Cooldown)
		cooldown = false
	end)
	swingSfx[Rand:NextInteger(1, #swingSfx)]:Play()

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

	local swingTrack = self.Player.Character
		:WaitForChild("Humanoid")
		:WaitForChild("Animator")
		:LoadAnimation(swingAnims[Rand:NextInteger(1, #swingAnims)])

	swingTrack:Play(0.05)
	table.insert(playingTracks, swingTrack)

	-- Trail
	task.spawn(function()
		self.Trail.Enabled = true
		task.wait(swingTrack.Length)
		self.Trail.Enabled = false
	end)

	print("PARENT:", tool.Parent)
	print("NAME:", tool.Name)
	local Hitbox = tool:WaitForChild(self.Hitbox.Name)

	newHitbox = HitboxService:CreateWithPart(Hitbox, Params)

	newHitbox:Start()
	newHitbox.Entered:Connect(function(object: BasePart)
		if sanityCheck(self.Tool, self.Player, self.Hitbox) then
			return
		end
		print("sanity check")

		local chr = object:FindFirstAncestorOfClass("Model")
		if not chr:FindFirstChildOfClass("Humanoid") then
			return
		end
		print("character check")

		if table.find(lastHit, chr) then
			return
		end
		print("table check")

		table.insert(lastHit, chr)
		print(chr)

		local humanoid: Humanoid = chr:WaitForChild("Humanoid")
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

		hitSfx[Rand:NextInteger(1, #hitSfx)]:Play()
		humanoid:TakeDamage(self.Dmg)
	end)

	Activated = true
	print("STARTED HITBOX")
	swingTrack.Stopped:Connect(function()
		if newHitbox:GetState() and Activated then
			newHitbox:Stop()
			table.clear(lastHit)
			print("STOPPED HITBOX")
			Activated = false
		end
	end)
end

function modTool:GetOwner()
	if self.Tool:FindFirstAncestorOfClass("Player") then
		return self.Tool:FindFirstAncestorOfClass("Player")
	end
	local model = self.Tool:FindFirstAncestorOfClass("Model")
	print(self.Tool.Parent)
	if model then
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player
		end
	end
end
-------------------------------------------------------------------------------------------------
return modTool.New
