local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local afkRequest = ReplicatedStorage:WaitForChild("BombGame"):WaitForChild("AFKRequest")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("QuickSettings")
local afk = gui:WaitForChild("AFKButton")
local music = gui:WaitForChild("MusicButton")
local muted = false
music.Text = "BGM ON"

local function refreshAFK()
	local enabled = player:GetAttribute("AFK") == true
	afk.Text = enabled and "AFK ON" or "AFK OFF"
	afk.BackgroundColor3 = enabled and Color3.fromRGB(178, 161, 89) or Color3.fromRGB(147, 146, 105)
end
player:GetAttributeChangedSignal("AFK"):Connect(refreshAFK)
refreshAFK()
afk.Activated:Connect(function()
	afkRequest:FireServer(player:GetAttribute("AFK") ~= true)
end)

local musicGroup = SoundService:WaitForChild("HotPotatoMusic")
music.Activated:Connect(function()
	muted = not muted
	musicGroup.Volume = muted and 0 or 1
	music.Text = muted and "BGM OFF" or "BGM ON"
	music.BackgroundColor3 = muted and Color3.fromRGB(77, 101, 128) or Color3.fromRGB(98, 131, 161)
end)
