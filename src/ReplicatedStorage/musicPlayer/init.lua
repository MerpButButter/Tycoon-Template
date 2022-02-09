local MarketplaceService = game:GetService("MarketplaceService")
local tabelUtil = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("TableUtil"))
local musicPlayer = {}
musicPlayer.__index = musicPlayer

function musicPlayer.New(music: table)
	local self = setmetatable({}, musicPlayer)
	self.Music = music
	self.SavedMusic = music
	self.Sort = Instance.new("IntValue")
	self.Sort.Value = 1
	self.Sort.Parent = workspace
	self._Maid = {}

	return self
end

local musicSound: Sound
function musicPlayer:LoadMusicData()
	musicSound = Instance.new("Sound")
	musicSound.SoundId = "rbxassetid://" .. self.Music[self.Sort.Value]
	musicSound.Looped = true
	musicSound.Parent = workspace
	-- At the end of the song it goes to the next one following up
	self._Maid = musicSound.DidLoop:Connect(function()
		if self.Sort.Value < #self.Music then
		print(tostring(self.Sort.Value))
		self.Sort.Value += 1
		print(tostring(self.Sort.Value))
		musicSound.SoundId = "rbxassetid://" .. self.Music[self.Sort.Value]
		musicSound.TimePosition = 0
		else
			musicSound:Stop()
		end
	end)
	return musicSound
end

function musicPlayer:Play()
	if musicSound.IsPaused == true then
		musicSound:Resume()
	else
		musicSound:Play()
	end
end

function musicPlayer:Pause()
	musicSound:Pause()
end

function musicPlayer:SkipFoward()
	self.Sort.Value += 1
	musicSound.SoundId = "rbxassetid://" .. self.Music[self.Sort.Value]
	musicSound.TimePosition = 0
end

function musicPlayer:SkipBackward()
	self.Sort.Value -= 1
	musicSound.SoundId = "rbxassetid://" .. self.Music[self.Sort.Value]
	musicSound.TimePosition = 0
end

function musicPlayer:Shuffle()
	self.Music = tabelUtil.Shuffle(self.Music)
end

function musicPlayer:UnShuffle()
	self.Music = self.SavedMusic
end

function musicPlayer:Loop()
	
end

function musicPlayer:LoadAssetData(asset)
	local assetid = string.match(asset,"%d+")
	print(assetid)
	local assetData = MarketplaceService:GetProductInfo(tonumber(assetid))
	print(assetData)
	return assetData 
end

return musicPlayer
