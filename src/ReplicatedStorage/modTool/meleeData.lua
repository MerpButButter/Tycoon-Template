--!Convert all data to attributes in tool in the modTool module
local meleeData = {
	Fists = {
		WalkAnim = 0,
		IdleAnim = 0,
		SwingAnim = 0,
		Dmg = 10,
		SwingSfx = "rbxassetid://3932507990",
		HitSfx = "rbxassetid://3932505023",
		PlrHitSfx = "rbxassetid://3932141920",
		Cooldown = .5,
	},
	Sword = {
		WalkAnim = "rbxassetid://8326471826",
		IdleAnim = "rbxassetid://8441980236", --updated to blender
		SwingAnim = "rbxassetid://8324326162", --fix anim(broken)
		Dmg = 25,
		SwingSfx = "rbxassetid://4085939047",
		HitSfx = "rbxassetid://6331329239",
		PlrHitSfx = "rbxassetid://3932141920",
		Cooldown = 1,
	},
}

return meleeData
