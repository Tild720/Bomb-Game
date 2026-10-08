local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local CoinService = {}
CoinService.__index = CoinService

function CoinService.new(template, config, award, canCollect)
	assert(template:IsA("BasePart"), "ReplicatedStorage.Coin must be a BasePart")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RoundCoins", workspace
	local self = setmetatable({ template = template, config = config, award = award,
		canCollect = canCollect, folder = folder, random = Random.new(), active = false,
		points = {}, count = 0, nextSpawn = 0, connections = {} }, CoinService)
	RunService.Heartbeat:Connect(function()
		if not self.active or workspace:GetServerTimeNow() < self.nextSpawn then return end
		self.nextSpawn = workspace:GetServerTimeNow() + self.random:NextNumber(config.IntervalMin, config.IntervalMax)
		self:SpawnBatch()
	end)
	return self
end

function CoinService:Stop()
	self.active = false
	for _, connection in pairs(self.connections) do connection:Disconnect() end
	table.clear(self.connections)
	self.folder:ClearAllChildren()
	table.clear(self.points)
end

function CoinService:Start(points, count)
	self:Stop()
	self.points = table.clone(points)
	self.count = count
	self.nextSpawn = workspace:GetServerTimeNow() + self.config.FirstDelay
	self.active = #points > 0 and count > 0
end

function CoinService:SpawnBatch()
	local empty, occupied = {}, {}
	for _, coin in self.folder:GetChildren() do
		if not coin:GetAttribute("CollectedAt") then occupied[coin:GetAttribute("SpawnIndex")] = true end
	end
	for index, point in self.points do
		if point.Parent and not occupied[index] then table.insert(empty, index) end
	end
	for _ = 1, self.count do
		local index
		if #empty > 0 then index = table.remove(empty, self.random:NextInteger(1, #empty))
		else index = self.random:NextInteger(1, #self.points) end
		local point = self.points[index]
		if point.Parent then self:SpawnCoin(point, index) end
	end
end

function CoinService:SpawnCoin(point, index)
	local coin = self.template:Clone()
	coin.Name = "Coin"
	coin.Anchored, coin.CanCollide, coin.CanTouch, coin.CanQuery = true, false, true, false
	coin.CFrame = CFrame.new(point.Position + Vector3.new(0, self.config.SpawnOffset, 0)) * self.template.CFrame.Rotation
	coin:SetAttribute("CoinBase", coin.CFrame)
	coin:SetAttribute("SpawnIndex", index)
	coin:SetAttribute("SpinStartedAt", workspace:GetServerTimeNow())
	coin:SetAttribute("CollectedAt", nil)
	coin:SetAttribute("CollectorId", nil)
	coin.Parent = self.folder
	local claimed = false
	self.connections[coin] = coin.Touched:Connect(function(hit)
		if claimed or not self.active or not coin.Parent then return end
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local stats = player and player:FindFirstChild("leaderstats")
		if not player or not self.canCollect(player) or not humanoid or humanoid.Health <= 0
			or not root or (root.Position - coin.Position).Magnitude > 7
			or player:GetAttribute("StatsLoaded") ~= true or not stats or not stats:FindFirstChild("MONEY") then return end
		claimed = true
		coin.CanTouch = false
		self.connections[coin]:Disconnect()
		self.connections[coin] = nil
		coin:SetAttribute("CollectorId", player.UserId)
		coin:SetAttribute("CollectedAt", workspace:GetServerTimeNow())
		self.award(player, self.config.Reward, "COIN PICKUP")
		Debris:AddItem(coin, self.config.FadeTime + 0.15)
	end)
end

return CoinService
