local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local system = workspace:WaitForChild("System")
local lobby = system:WaitForChild("Lobby")
local field = system:WaitForChild("Field")
local blocker = system:WaitForChild("FieldBlocker")
local template = ReplicatedStorage:WaitForChild("Bomb")
local soundPack = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")

local state = Instance.new("Folder")
state.Name = "State"
state.Parent = shared
local effects = Instance.new("RemoteEvent")
effects.Name = "Effects"
effects.Parent = shared

local alive = {}
local playerConnections = {}
local holder, bomb, attachment, highlight
local expiresAt, nextPassAt = 0, 0
local roundId = 0
local phase = "Waiting"
local random = Random.new()
local temporarySounds = {}

-- 차단벽은 그대로 두고 캐릭터 전체의 통과 권한만 바꿉니다.
for _, name in ipairs({ "LobbyPlayers", "InGamePlayers", "FieldBlocker" }) do
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end
PhysicsService:CollisionGroupSetCollidable("FieldBlocker", "LobbyPlayers", true)
PhysicsService:CollisionGroupSetCollidable("FieldBlocker", "InGamePlayers", false)
PhysicsService:CollisionGroupSetCollidable("FieldBlocker", "Default", true)
for _, a in ipairs({ "LobbyPlayers", "InGamePlayers" }) do
	PhysicsService:CollisionGroupSetCollidable(a, "Default", true)
	for _, b in ipairs({ "LobbyPlayers", "InGamePlayers" }) do
		PhysicsService:CollisionGroupSetCollidable(a, b, false)
	end
end
local function setBlocker(part)
	if part:IsA("BasePart") then
		part.CollisionGroup = "FieldBlocker"
		part.CanCollide = true
	end
end
setBlocker(blocker)
for _, part in ipairs(blocker:GetDescendants()) do setBlocker(part) end
blocker.DescendantAdded:Connect(setBlocker)

local function characterParts(player)
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil
end

local function survivors()
	local list = {}
	for player in pairs(alive) do table.insert(list, player) end
	return list
end

local function setCharacterState(player, frozen)
	local character, humanoid, root = characterParts(player)
	if not character then return end
	local group = alive[player] and "InGamePlayers" or "LobbyPlayers"
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then part.CollisionGroup = group end
	end
	root.Anchored = frozen == true
	humanoid.WalkSpeed = player == holder and Config.HolderSpeed or Config.WalkSpeed
	player:SetAttribute("InRound", alive[player] == true)
end

local function publish(newPhase, deadline, winner)
	phase = newPhase
	state:SetAttribute("Phase", phase)
	state:SetAttribute("Deadline", deadline or 0)
	state:SetAttribute("AliveCount", #survivors())
	state:SetAttribute("Winner", winner or "")
	state:SetAttribute("RoundId", roundId)
	state:SetAttribute("HolderUserId", holder and holder.UserId or 0)
	state:SetAttribute("BombExpiresAt", expiresAt)
	state:SetAttribute("Revision", (state:GetAttribute("Revision") or 0) + 1)
end

local function stopSounds()
	for _, sound in ipairs(temporarySounds) do sound:Destroy() end
	table.clear(temporarySounds)
end

local function playSound(kind, parent)
	local source = soundPack:FindFirstChild(Config.Sounds[kind])
	if not source or not source:IsA("Sound") then return end
	local sound = source:Clone()
	sound.Looped = false
	sound.TimePosition = 0
	sound.Volume = math.min(source.Volume, kind == "Explosion" and 0.3 or 0.5)
	sound.Parent = parent or SoundService
	table.insert(temporarySounds, sound)
	sound:Play()
	Debris:AddItem(sound, 3)
end

-- 준비된 바닥만 Raycast하여 차단벽의 윗면에 스폰하지 않습니다.
local function moveToFloor(player, floor, x, z)
	local character, humanoid, root = characterParts(player)
	if not character then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { floor }
	local center = floor.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
	local hit = workspace:Raycast(center + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0), params)
	if not hit then return false end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local position = hit.Position + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.5, 0)
	character:PivotTo(CFrame.new(position))
	return true
end

local function moveToLobby(player)
	moveToFloor(player, lobby, random:NextNumber(-15, 15), random:NextNumber(-15, 15))
	setCharacterState(player, false)
end

local function clearBomb()
	local previous = holder
	holder = nil
	expiresAt = 0
	if attachment then attachment:Destroy() end
	if highlight then highlight:Destroy() end
	if bomb then bomb:Destroy() end
	attachment, highlight, bomb = nil, nil, nil
	if previous then setCharacterState(previous, false) end
	stopSounds()
end

local function eliminate(player)
	if not alive[player] then return end
	alive[player] = nil
	player:SetAttribute("EliminatedRound", roundId)
	player:SetAttribute("InRound", false)
	if player == holder then clearBomb() end
	moveToLobby(player)
	publish(phase, state:GetAttribute("Deadline"))
end

local function attachBomb(player, isPass)
	local character = characterParts(player)
	local head = character and character:FindFirstChild("Head")
	if not head then return false end
	local previous = holder
	if attachment then attachment:Destroy() end
	if highlight then highlight:Destroy() end
	stopSounds()
	if not bomb then
		bomb = template:Clone()
		bomb.Name = "HotPotatoBomb"
		bomb.Parent = workspace
		-- 원본은 보존하고 복제본의 물리 설정만 변경합니다.
		local parts = { bomb }
		for _, item in ipairs(bomb:GetDescendants()) do table.insert(parts, item) end
		for _, part in ipairs(parts) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Massless = true
				if part ~= bomb then
					local weld = Instance.new("WeldConstraint")
					weld.Part0, weld.Part1 = bomb, part
					weld.Parent = part
				end
			end
		end
	end
	bomb:PivotTo(head.CFrame * CFrame.new(0, Config.BombHeight, 0))
	attachment = Instance.new("WeldConstraint")
	attachment.Part0, attachment.Part1 = head, bomb
	attachment.Parent = bomb
	holder = player
	if previous then setCharacterState(previous, false) end
	setCharacterState(player, false)
	highlight = Instance.new("Highlight")
	highlight.Name = "BombHolder"
	highlight.FillColor = Color3.fromRGB(255, 210, 70)
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.4
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
	nextPassAt = workspace:GetServerTimeNow() + Config.PassCooldown
	bomb:SetAttribute("ExpiresAt", expiresAt)
	if isPass then
		playSound("Pass", bomb)
		effects:FireAllClients("Pass", bomb.Position)
	end
	publish("Playing")
	return true
end

local function eligiblePlayers()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if characterParts(player) then table.insert(list, player) end
	end
	return list
end

local function setupPlayer(player)
	player:SetAttribute("InRound", false)
	local connections = {}
	playerConnections[player] = connections
	local function onCharacter(character)
		eliminate(player)
		table.insert(connections, character.DescendantAdded:Connect(function(part)
			if part:IsA("BasePart") then
				part.CollisionGroup = alive[player] and "InGamePlayers" or "LobbyPlayers"
			end
		end))
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CollisionGroup = "LobbyPlayers" end
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if player.Character ~= character or not humanoid or not root then return end
		table.insert(connections, humanoid.Died:Connect(function() eliminate(player) end))
		moveToLobby(player)
	end
	table.insert(connections, player.CharacterAdded:Connect(onCharacter))
	table.insert(connections, player.CharacterRemoving:Connect(function() eliminate(player) end))
	if player.Character then task.spawn(onCharacter, player.Character) end
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	eliminate(player)
	for _, connection in ipairs(playerConnections[player] or {}) do connection:Disconnect() end
	playerConnections[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end

local function pause(seconds, cancel)
	local deadline = workspace:GetServerTimeNow() + seconds
	while workspace:GetServerTimeNow() < deadline do
		if cancel and cancel() then return false end
		task.wait(Config.CheckInterval)
	end
	return not cancel or not cancel()
end

local function passTarget()
	local _, _, root = characterParts(holder)
	if not root then return nil end
	local excluded = { blocker, bomb }
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then table.insert(excluded, player.Character) end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	local nearest, nearestDistance = nil, Config.PassDistance + 0.001
	for player in pairs(alive) do
		if player ~= holder then
			local _, _, otherRoot = characterParts(player)
			if otherRoot then
				local direction = otherRoot.Position - root.Position
				local distance = direction.Magnitude
				if distance <= Config.PassDistance and distance < nearestDistance
					and not workspace:Raycast(root.Position, direction, params) then
					nearest, nearestDistance = player, distance
				end
			end
		end
	end
	return nearest
end

local function playRound()
	local nextBombAt = 0
	local lastSecond = -1
	while #survivors() > 1 do
		for _, player in ipairs(survivors()) do
			if not characterParts(player) then eliminate(player) end
		end
		if #survivors() <= 1 then break end
		local now = workspace:GetServerTimeNow()
		if not holder then
			if nextBombAt == 0 then nextBombAt = now + Config.NextBombDelay end
			if now >= nextBombAt then
				local list = survivors()
				expiresAt = now + Config.BombTime
				if not attachBomb(list[random:NextInteger(1, #list)], false) then
					clearBomb()
				end
				nextBombAt, lastSecond = 0, -1
			end
		elseif now >= expiresAt then
			-- 만료를 전달보다 먼저 처리합니다. 주변에는 피해를 주지 않습니다.
			local victim = holder
			local position = bomb.Position
			eliminate(victim)
			playSound("Explosion")
			effects:FireAllClients("Explosion", position)
		elseif bomb then
			local seconds = math.ceil(expiresAt - now)
			local timer = bomb:FindFirstChild("BombTimer")
			if timer and seconds ~= lastSecond then
				timer.TimerLabel.Text = tostring(seconds)
				timer.TimerLabel.TextColor3 = seconds <= 5 and Color3.fromRGB(255, 80, 80) or Color3.new(1, 1, 1)
				if seconds <= 5 then playSound("Warning", bomb) end
				lastSecond = seconds
			end
			if now >= nextPassAt then
				local target = passTarget()
				if target then attachBomb(target, true) end
			end
		end
		task.wait(Config.CheckInterval)
	end
end

while true do
	publish("Waiting")
	repeat task.wait(Config.CheckInterval) until #eligiblePlayers() >= Config.MinPlayers
	publish("Countdown", workspace:GetServerTimeNow() + Config.LobbyCountdown)
	local ready = pause(Config.LobbyCountdown, function() return #eligiblePlayers() < Config.MinPlayers end)
	if ready then
		roundId += 1
		local list = eligiblePlayers()
		local columns = math.max(1, math.floor((field.Size.X - Config.FieldInset * 2) / Config.SpawnSpacing) + 1)
		local rows = math.max(1, math.floor((field.Size.Z - Config.FieldInset * 2) / Config.SpawnSpacing) + 1)
		for index, player in ipairs(list) do
			if index <= columns * rows then
				local x = ((index - 1) % columns - (columns - 1) / 2) * Config.SpawnSpacing
				local z = (math.floor((index - 1) / columns) - (rows - 1) / 2) * Config.SpawnSpacing
				if moveToFloor(player, field, x, z) then
					alive[player] = true
					setCharacterState(player, true)
				end
			end
		end
		publish("Ready", workspace:GetServerTimeNow() + Config.ReadyTime)
		pause(Config.ReadyTime, function() return #survivors() < Config.MinPlayers end)
		for player in pairs(alive) do setCharacterState(player, false) end
		publish("Playing")
		if #survivors() >= Config.MinPlayers then
			local listNow = survivors()
			expiresAt = workspace:GetServerTimeNow() + Config.BombTime
			attachBomb(listNow[random:NextInteger(1, #listNow)], false)
			playSound("Start")
			playRound()
		end
		clearBomb()
		local remaining = survivors()
		local winner = remaining[1]
		publish("Results", workspace:GetServerTimeNow() + Config.ResultTime, winner and winner.DisplayName or "")
		pause(Config.ResultTime)
		-- 예약 타이머 없이 한 루프에서 라운드를 마무리합니다.
		for _, player in ipairs(survivors()) do
			alive[player] = nil
			player:SetAttribute("InRound", false)
			moveToLobby(player)
		end
		clearBomb()
	end
end
