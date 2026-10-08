local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("BombGame"):WaitForChild("SkillCatalog"))
local SkinCatalog = require(game:GetService("ReplicatedStorage").BombGame:WaitForChild("BombSkinCatalog"))
local WinRankStore = require(script.Parent:WaitForChild("WinRankStore"))

local studio = RunService:IsStudio()
local store = DataStoreService:GetDataStore(studio and "BombGameLeaderstats_Studio_v1" or "BombGameLeaderstats_v1")
local sessions = {}
local closing = false
local leaseSeconds = 180

local function retry(operation)
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(operation)
		if ok then return true, result end
		lastError = result
		if attempt < 3 then task.wait(attempt) end
	end
	return false, lastError
end

local function save(player, release)
	local session = sessions[player]
	if not session or not session.loaded or session.closed then return end
	while session.saving do task.wait(0.1) end
	if session.closed then return end
	session.saving = true
	local stats = player:FindFirstChild("leaderstats")
	local money, wins = stats.MONEY.Value, stats.WIN.Value
	local owned = {}
	for id in pairs(Catalog.Items) do owned[id] = player:GetAttribute("OwnsSkill_" .. id) == true end
	local equipped = player:GetAttribute("EquippedSkill") or "DoubleJump"
	local ownedSkins = {}
	for id in pairs(SkinCatalog.Items) do ownedSkins[id] = player:GetAttribute("OwnsBombSkin_" .. id) == true end
	local equippedSkin = player:GetAttribute("EquippedBombSkin") or "Bomb"
	local ok, result = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(data)
			if not data or not data.Session or data.Session.Id ~= session.id then return nil end
			data.MONEY, data.WIN = money, wins
			data.OwnedSkills, data.EquippedSkill = owned, equipped
			data.OwnedBombSkins, data.EquippedBombSkin = ownedSkins, equippedSkin
			if release then
				data.Session = nil
			else
				data.Session = { Id = session.id, ExpiresAt = os.time() + leaseSeconds }
			end
			return data
		end)
	end)
	session.saving = false
	if ok and result then
		if release then
			session.closed = true
			sessions[player] = nil
		end
		WinRankStore.Publish(player.UserId, wins)
	else
		warn("Leaderstats save failed for " .. player.UserId .. ": " .. tostring(result))
		if player.Parent == Players then
			player:SetAttribute("StatsLoaded", false)
			player:Kick("Your progress could not be saved. Please rejoin.")
		end
	end
end

local function load(player)
	if sessions[player] then return end
	local session = { id = HttpService:GenerateGUID(false), loaded = false }
	sessions[player] = session
	player:SetAttribute("StatsLoaded", false)
	local ok, result = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(data)
			data = data or { MONEY = 0, WIN = 0 }
			if data.Session and data.Session.Id ~= session.id and data.Session.ExpiresAt > os.time() then
				return nil
			end
			data.Session = { Id = session.id, ExpiresAt = os.time() + leaseSeconds }
			return data
		end)
	end)
	if not ok or not result then
		warn("Leaderstats load failed for " .. player.UserId .. ": " .. tostring(result))
		if studio and not ok then
			result = { MONEY = 0, WIN = 0 }
		else
			sessions[player] = nil
			if player.Parent == Players then player:Kick("Your progress is unavailable. Please rejoin shortly.") end
			return
		end
	else
		session.loaded = true
	end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "MONEY", "WIN" }) do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = math.max(0, math.floor(tonumber(result[name]) or 0))
		value.Parent = stats
	end
	stats.Parent = player
	local owned, equipped = Catalog.Normalize(result.OwnedSkills, result.EquippedSkill)
	for id in pairs(Catalog.Items) do player:SetAttribute("OwnsSkill_" .. id, owned[id] == true) end
	player:SetAttribute("EquippedSkill", equipped)
	local ownedSkins, equippedSkin = SkinCatalog.Normalize(result.OwnedBombSkins, result.EquippedBombSkin)
	for id in pairs(SkinCatalog.Items) do player:SetAttribute("OwnsBombSkin_" .. id, ownedSkins[id] == true) end
	player:SetAttribute("EquippedBombSkin", equippedSkin)
	player:SetAttribute("StatsPersistent", session.loaded)
	if closing or player.Parent ~= Players then
		save(player, true)
		if not session.loaded then sessions[player] = nil end
		return
	end
	player:SetAttribute("StatsLoaded", true)
	if session.loaded then task.spawn(WinRankStore.Publish, player.UserId, stats.WIN.Value) end
end

Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(function(player)
	save(player, true)
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(load, player) end

task.spawn(function()
	while not closing do
		task.wait(60)
		if closing then break end
		for _, player in ipairs(Players:GetPlayers()) do task.spawn(save, player, false) end
	end
end)

game:BindToClose(function()
	closing = true
	local pending = 0
	for player, session in pairs(sessions) do
		if session.loaded then
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)
