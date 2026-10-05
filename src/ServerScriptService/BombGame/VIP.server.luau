local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local request = Instance.new("RemoteEvent")
request.Name = "VIPRequest"
request.Parent = shared

local function loadVIP(player)
	player:SetAttribute("VIP", false)
	player:SetAttribute("VIPSample", false)
	if Config.VIP.GamePassId <= 0 then return end
	local ok, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.VIP.GamePassId)
	end)
	if player.Parent == Players and ok and owned then player:SetAttribute("VIP", true) end
end
Players.PlayerAdded:Connect(loadVIP)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadVIP, player) end

-- 샘플 구매는 Robux와 저장 데이터에 영향을 주지 않습니다.
request.OnServerEvent:Connect(function(player, version)
	if typeof(version) ~= "number" then return end
	if not RunService:IsStudio() or not Config.VIP.StudioSamplePurchase then
		request:FireClient(player, version, false, "Sample purchases are only available in Studio.")
		return
	end
	if player:GetAttribute("InRound") then
		request:FireClient(player, version, false, "Please wait until you return to the lobby.")
		return
	end
	if player:GetAttribute("VIP") then
		request:FireClient(player, version, false, "You already have VIP.")
		return
	end
	player:SetAttribute("VIPSample", true)
	player:SetAttribute("VIP", true)
	request:FireClient(player, version, true)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if Config.VIP.GamePassId > 0 and passId == Config.VIP.GamePassId and purchased then
		player:SetAttribute("VIPSample", false)
		player:SetAttribute("VIP", true)
	end
end)
