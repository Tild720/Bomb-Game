local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local RankStore = require(script.Parent:WaitForChild("WinRankStore"))
local shared = ReplicatedStorage:WaitForChild("BombGame")
local state = Instance.new("Folder")
state.Name, state.Parent = "WinLeaderboard", shared
local entries = Instance.new("StringValue")
entries.Name, entries.Value, entries.Parent = "Entries", "[]", state
local status = Instance.new("StringValue")
status.Name, status.Value, status.Parent = "Status", "Loading rankings...", state
local names = {}
task.spawn(function()
	local system = workspace:WaitForChild("System")
	local board = system:FindFirstChild("WinLeaderBoard") or system:WaitForChild("WinLeaderboard")
	if board:IsA("BasePart") then board.CanQuery = true end
end)

local function currentServer()
	local result = {}
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		local wins = stats and stats:FindFirstChild("WIN")
		if wins and player:GetAttribute("StatsLoaded") then
			table.insert(result, { UserId = player.UserId, Name = player.Name, Wins = wins.Value })
		end
	end
	table.sort(result, function(a, b)
		if a.Wins == b.Wins then return a.UserId < b.UserId end
		return a.Wins > b.Wins
	end)
	while #result > 20 do table.remove(result) end
	return result
end

local function refresh()
	local ok, page = RankStore.Top()
	if not ok then
		if RunService:IsStudio() then
			entries.Value = HttpService:JSONEncode(currentServer())
			status.Value = "Studio server ranking. Global data is unavailable."
		else
			status.Value = "Rankings unavailable. Retrying soon."
		end
		return
	end
	local result = {}
	for _, record in page do
		local userId = tonumber(record.key)
		if userId and userId > 0 then
			local player = Players:GetPlayerByUserId(userId)
			local name = player and player.Name or names[userId]
			if not name then
				local success, value = pcall(Players.GetNameFromUserIdAsync, Players, userId)
				if success then name = value names[userId] = name end
			end
			table.insert(result, { UserId = userId, Name = name or "Player " .. userId, Wins = record.value })
		end
	end
	entries.Value = HttpService:JSONEncode(result)
	status.Value = "GLOBAL TOP 20   /   UPDATES EVERY MINUTE"
end

while true do
	refresh()
	task.wait(60)
end
