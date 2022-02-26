local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local tool: Tool?

type Actions = {
	NormalAttacks: {
		Swing: { Enum.UserInputType },
	},
	SpecialsAttacks: {}?,
}
local ACTIONS: Actions = {
	NormalAttacks = {
		Swing = {
			Enum.UserInputType.MouseButton1,
		},
	},
}

local cooldown_time = 0.1
local cooldown = false
local function onInput(actionName, inputState, _inputObject)
	if cooldown then
		return
	end
	cooldown = true
	if inputState == Enum.UserInputState.Begin then
		local remoteEventInput: RemoteEvent = ReplicatedStorage:WaitForChild("ToolRemotes"):WaitForChild("OnInput")
		print("fired SERVER👍")
		remoteEventInput:FireServer(actionName,tool)
	end
	task.wait(cooldown_time)
	cooldown = false
end

--! MAKE SPECIAL ATTACKS WORK WITH SPECIAL ATTACKS IN TABLE
ContextActionService.LocalToolEquipped:Connect(function(_tool)
	-- Loop through attacks and bind actions to them
	tool = _tool
	for name, value in pairs(ACTIONS.NormalAttacks) do
		ContextActionService:BindAction(name, onInput, true, table.unpack(value))
		print(name)
		print(value)
	end
end)

ContextActionService.LocalToolUnequipped:Connect(function(_tool)
	tool = nil
	for name, _value in pairs(ACTIONS.NormalAttacks) do
		ContextActionService:UnbindAction(name)
		print(name)
	end
end)
