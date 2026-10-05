local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Catalog = require(shared:WaitForChild("BombSkinCatalog"))
local SkillCatalog = require(shared:WaitForChild("SkillCatalog"))
local hitbox = workspace:WaitForChild("System"):WaitForChild("SkinShopHitbox")
local request = Instance.new("RemoteEvent")
request.Name, request.Parent = "BombSkinRequest", shared
local requests = {}
local function reply(player, success, message)
	request:FireClient(player, success, message)
end
request.OnServerEvent:Connect(function(player, action, id)
	if action ~= "Buy" and action ~= "Equip" then return end
	local now = os.clock()
	if now - (requests[player] or 0) < 0.15 then return reply(player, false, "Please wait a moment.") end
	requests[player] = now
	if player:GetAttribute("StatsLoaded") ~= true then return reply(player, false, "Your data is still loading. Please wait.") end
	if typeof(id) ~= "string" or not Catalog.Items[id] then return reply(player, false, "Unknown bomb skin.") end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or player:GetAttribute("InRound") or not SkillCatalog.InShop(hitbox, root) then
		return reply(player, false, "Stand inside the bomb skin shop to buy or equip.")
	end
	local owned = player:GetAttribute("OwnsBombSkin_" .. id) == true
	if action == "Buy" then
		local stats = player:FindFirstChild("leaderstats")
		local money = stats and stats:FindFirstChild("MONEY")
		if not money then return reply(player, false, "Your money is not available yet.") end
		local reason = Catalog.PurchaseError(id, owned, money.Value)
		if reason then return reply(player, false, reason) end
		money.Value -= Catalog.Items[id].Price
		player:SetAttribute("OwnsBombSkin_" .. id, true)
		reply(player, true, Catalog.Items[id].Name .. " purchased! Select EQUIP to use it.")
	else
		if not owned then return reply(player, false, "Purchase this skin first.") end
		player:SetAttribute("EquippedBombSkin", id)
		reply(player, true, Catalog.Items[id].Name .. " equipped.")
	end
end)
Players.PlayerRemoving:Connect(function(player) requests[player] = nil end)
