local ContextActionService = game:GetService("ContextActionService")

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://3932141920"
sound.Looped = true
sound.Parent = game:GetService("SoundService")
local pitch = Instance.new("PitchShiftSoundEffect")
pitch.Parent = sound

local function playSound(actionName, inputState, inputObject)
	if actionName == "playSound" then
		if inputState == Enum.UserInputState.Begin then
			sound:Play()
			pitch.Octave = math.random(970, 1000) / 1000

			sound.DidLoop:Connect(function(soundId, numOfTimesLooped)
				pitch.Octave = math.random(970, 1000) / 1000
			end)
		end
	else
		sound:Pause()
	end
end

ContextActionService:BindAction("playSound", playSound, true, Enum.KeyCode.LeftAlt, Enum.UserInputType.MouseButton1)
