local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("BombGame")
local UI = require(shared:WaitForChild("WinLeaderboardUI"))
local state = shared:WaitForChild("WinLeaderboard")
local entries = state:WaitForChild("Entries")
local status = state:WaitForChild("Status")
local system = workspace:WaitForChild("System")
local board = system:FindFirstChild("WinLeaderBoard") or system:WaitForChild("WinLeaderboard")
local template = board:WaitForChild("WinLeaderboardSurface")
local surface = template:Clone()
surface.Adornee, surface.Enabled, surface.Parent = board, true, playerGui
template.Enabled = false
local function refresh()
	local ok, data = pcall(HttpService.JSONDecode, HttpService, entries.Value)
	if ok and typeof(data) == "table" then UI.Render(surface, data) end
end
entries.Changed:Connect(refresh)
status.Changed:Connect(function() surface.Background.Status.Text = status.Value end)
surface.Background.Status.Text = status.Value
refresh()
