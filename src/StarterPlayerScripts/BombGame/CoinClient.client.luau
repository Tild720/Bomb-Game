local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("BombGame"):WaitForChild("Config")).Coins
local player = Players.LocalPlayer
local folder = workspace:WaitForChild("RoundCoins")
local sounds = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")
local coins = {}

local function track(coin)
	if not coin:IsA("BasePart") or coins[coin] then return end
	local surfaces = { [coin] = coin.Transparency }
	for _, child in coin:GetDescendants() do
		if child:IsA("Decal") or child:IsA("Texture") then surfaces[child] = child.Transparency end
	end
	coins[coin] = { surfaces = surfaces, played = false }
end
folder.ChildAdded:Connect(track)
folder.ChildRemoved:Connect(function(coin) coins[coin] = nil end)
for _, coin in folder:GetChildren() do track(coin) end

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	for coin, record in pairs(coins) do
		local base = coin:GetAttribute("CoinBase")
		local started = coin:GetAttribute("SpinStartedAt")
		if not base or not started then continue end
		local collected = coin:GetAttribute("CollectedAt")
		local fade = collected and math.clamp((now - collected) / Config.FadeTime, 0, 1) or 0
		local angle = math.rad(Config.SpinSpeed) * (now - started)
		coin.CFrame = CFrame.new(base.Position + Vector3.new(0, fade * 0.8, 0)) * CFrame.Angles(0, angle, 0) * base.Rotation
		if collected then
			for surface, original in pairs(record.surfaces) do surface.Transparency = original + (1 - original) * fade end
			if not record.played and coin:GetAttribute("CollectorId") == player.UserId then
				record.played = true
				local source = sounds:FindFirstChild(Config.PickupSound)
				if source then
					local sound = source:Clone()
					sound.Looped, sound.TimePosition = false, 0
					sound.Volume, sound.PlaybackSpeed = Config.PickupVolume, Config.PickupPitch
					sound.Parent = SoundService
					sound:Play()
					Debris:AddItem(sound, 3)
				end
			end
		end
	end
end)
