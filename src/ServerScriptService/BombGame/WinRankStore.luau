local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local store = DataStoreService:GetOrderedDataStore(RunService:IsStudio() and "BombGameWinRanks_Studio_v1" or "BombGameWinRanks_v1")
local published = {}
local RankStore = {}

function RankStore.Publish(userId, wins)
	wins = math.max(0, math.floor(wins))
	if userId <= 0 or (published[userId] and published[userId] >= wins) then return end
	local ok, result = pcall(function()
		return store:UpdateAsync(tostring(userId), function(previous)
			return math.max(tonumber(previous) or 0, wins)
		end)
	end)
	if ok then published[userId] = math.max(published[userId] or 0, result or wins)
	else warn("WIN rank update failed: " .. tostring(result)) end
end

function RankStore.Top()
	return pcall(function()
		return store:GetSortedAsync(false, 20):GetCurrentPage()
	end)
end

return RankStore
