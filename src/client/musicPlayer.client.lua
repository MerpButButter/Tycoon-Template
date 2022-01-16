local music = {
	1844296642,
	1839307258,
	1846441683,
	1836821834,
	1840682490,
	4643446128,
	4930282522,
	4456886461,
	6694425493,
	837030083,
	7282519907,
}
local musicPlayerMdl = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("musicPlayer"))
local musicPlayer = musicPlayerMdl.New(music)
local sound = musicPlayer:LoadMusicData()

local plr = game:GetService("Players").LocalPlayer
local musicPlayerGui = plr.PlayerGui:WaitForChild("musicPlayer")

local activated = false
musicPlayerGui.skip_backward.ImageColor3 = Color3.fromRGB(145, 83, 153)
musicPlayerGui.playButton.MouseButton1Up:Connect(function()
	if not activated then
		activated = true
		musicPlayerGui.playButton.Image = "rbxassetid://8364767981"
		musicPlayer:Play()
	elseif activated then
		activated = false
		musicPlayerGui.playButton.Image = "rbxassetid://8364588048"
		musicPlayer:Pause()
	end
end)

local shuffled = false
musicPlayerGui.shuffleButton.MouseButton1Up:Connect(function()
	if not shuffled then
		musicPlayerGui.shuffleButton.ImageColor3 = Color3.fromRGB(145, 83, 153)
		shuffled = true
		musicPlayer:Shuffle()
	elseif shuffled then
		musicPlayerGui.shuffleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		shuffled = false
		musicPlayer.Music = musicPlayer.SavedMusic
	end
end)

musicPlayerGui.skip_foward.MouseButton1Up:Connect(function()
	if musicPlayerGui.skip_foward.ImageColor3 == Color3.fromRGB(255, 255, 255) then
		musicPlayer:SkipFoward()
	end
end)

musicPlayerGui.skip_backward.MouseButton1Up:Connect(function()
	if musicPlayerGui.skip_backward.ImageColor3 == Color3.fromRGB(255, 255, 255) then
		musicPlayer:SkipBackward()
	end
end)

musicPlayer.Sort.Changed:Connect(function()
	if musicPlayer.Sort.Value < #music then
		musicPlayerGui.skip_foward.ImageColor3 = Color3.fromRGB(255, 255, 255)
	else
		musicPlayerGui.skip_foward.ImageColor3 = Color3.fromRGB(145, 83, 153)
	end

	if musicPlayer.Sort.Value > 1 then
		musicPlayerGui.skip_backward.ImageColor3 = Color3.fromRGB(255, 255, 255)
	else
		musicPlayerGui.skip_backward.ImageColor3 = Color3.fromRGB(145, 83, 153)
	end
end)

sound:GetPropertyChangedSignal("SoundId"):Connect(function()
	local soundData = musicPlayer:LoadAssetData(sound.SoundId)

	musicPlayerGui.musicDescription.Text = soundData.Description
	musicPlayerGui.musicDuration.Text = "Duration: " .. sound.TimeLength
	musicPlayerGui.musicName.Text = soundData.Name
	musicPlayerGui.musicOwner.Text = "By " .. soundData.Creator.Name
end)
