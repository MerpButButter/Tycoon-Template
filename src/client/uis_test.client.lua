local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local Part = workspace.Part

-- Wait for the character to load
Player.CharacterAdded:Wait()
local CframelookAtConnection: RBXScriptConnection
Player.CharacterAdded:Connect(function(character)
	CframelookAtConnection = RunService.Heartbeat:Connect(function()
		if not character then
			CframelookAtConnection:Disconnect()
		end
		task.wait(0.1)
		Part.CFrame = CFrame.lookAt(Part.Position, character:WaitForChild("HumanoidRootPart").Position)
	end)
end)
