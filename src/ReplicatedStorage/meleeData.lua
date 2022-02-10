local ReplicatedStorage = game:GetService("ReplicatedStorage")

local baseURL = "rbxassetid://%d"

type MeleeData = {
	[string]: {
		Animations: {
			Swing: { string },
			Idle: string,
			Equip: string?,
		},
		Sounds: {
			Equip: {
				ID: string,
				Volume: number?,
				PlaybackSpeed: number?,
			}?,
			Swing: {
				ID: { string },
				Volume: number?,
				PlaybackSpeed: number?,
			},
			Hit: {
				ID: { string },
				Volume: number?,
				PlaybackSpeed: number?,
			},
		},
		Specs: {
			Damage: number,
			Cooldown: number,
			Shake: number?,
			HitEffectLocation: (Folder | Instance)?,
			Trail: {
				Instance: Trail,
				Attachments: (player: Player, tool: Tool) -> ...Attachment | { Attachment }, -- function which gives you the player and tool and returns a table with attach1 and attach0 or a folder in which you have the attachments
			}?,
			HitBox: ((player: Player, tool: Tool) -> BasePart), -- hit box on a tool or a character
		},
	},
}

local Melee: MeleeData = {}

-- Melee.Sword = {
-- 	Animations = {

-- 		Swing = {
-- 			baseURL:format(),
-- 			baseURL:format(),
-- 		},
-- 		Idle = baseURL:format(),

-- 		Equip = baseURL:format(),
-- 	},
-- 	Sounds = {
-- 		Equip = {
-- 			ID = baseURL:format(),
-- 			Volume = 0.5,
-- 		},
-- 		Swing = {
-- 			ID = { baseURL:format(), baseURL:format() },
-- 			Volume = 0.3,
-- 			PlaybackSpeed = 0.7,
-- 		},
-- 		Hit = {
-- 			ID = { baseURL:format(), baseURL:format() },
-- 			Volume = 0.8,
-- 			PlaybackSpeed = 1,
-- 		},
-- 	},
-- 	Specs = {
-- 		Damage = 0,
-- 		Cooldown = 0,
-- 		Shake = 0,
-- 		HitEffectLocation = nil,
-- 		Trail = {
-- 			Instance = ReplicatedStorage.Trails.swordTrail,
-- 			Attachments = function(_player: Player, _tool: Tool)
-- 				return {}
-- 			end,
-- 		},
-- 		HitBox = function(_player, _tool) end,
-- 	},
-- }

Melee.RoyalSword = {
	Animations = {
		Swing = baseURL:format(8535372298),
		Idle = baseURL:format(8441980236),
		Equip = nil,
	},
	Sounds = {
		Equip = {
			ID = baseURL:format(4458750270),
			Volume = 0.4,
			PlaybackSpeed = 1,
		},
		Swing = {
			ID = { baseURL:format(4953118406), baseURL:format(4307216336) },
			Volume = 0.5,
			PlaybackSpeed = 0.4,
		},
		Hit = {
			ID = { baseURL:format(4459570664), baseURL:format(4459571224) },
			Volume = 0.4,
			PlaybackSpeed = 0.6,
		},
	},
	Specs = {
		Damage = 30,
		Cooldown = 3,
		Shake = 1,
		HitEffectLocation = nil,
		Trail = {
			Instance = ReplicatedStorage.Trails:WaitForChild("RoyalSwordTrail"),
			Attachments = function(_player, _tool)
				local handle = _tool:WaitForChild("Handle")

				return handle.Trail0, handle.Trail1
			end,
		},
		HitBox = function(_player, _tool)
			local blade = _tool:WaitForChild("Blade")
			return blade
		end,
	},
}

return Melee
