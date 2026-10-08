local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local unseat = require(script.Parent:WaitForChild("Unseat"))
Players.RespawnTime = Config.DeathRespawnDelay
local system = workspace:WaitForChild("System")
local lobby = system:WaitForChild("Lobby")
local field = system:WaitForChild("Field")
local blocker = system:WaitForChild("FieldBlocker")
local lobbyBlocker = system:WaitForChild("LobbyBlocker")
local SkinCatalog = require(shared:WaitForChild("BombSkinCatalog"))
local soundPack = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")

local state = Instance.new("Folder")
state.Name = "State"
state.Parent = shared
local effects = Instance.new("RemoteEvent")
effects.Name = "Effects"
effects.Parent = shared
local rewards = Instance.new("RemoteEvent")
rewards.Name = "Reward"
rewards.Parent = shared
local afkRequest = Instance.new("RemoteEvent")
afkRequest.Name = "AFKRequest"
afkRequest.Parent = shared

local alive = {}
local playerConnections = {}
local holder, bomb, attachment, highlight
local holderTrack
local holderAnimation = Instance.new("Animation")
holderAnimation.Name = "BombHoldAnimation"
holderAnimation.AnimationId = Config.HolderAnimationId
holderAnimation.Parent = script
local expiresAt, nextPassAt = 0, 0
local roundId = 0
local phase = "Waiting"
local roundStarted = false
local random = Random.new()
local MapRotation = require(script.Parent:WaitForChild("MapRotation"))
local maps = MapRotation.new(game:GetService("ServerStorage"):WaitForChild("Maps"), field, random)
local temporarySounds = {}
local testDummies = {}
local dummyFolder
local nextDummyId = 0
local studioTesting = Config.StudioTesting.Enabled == true

for _, name in ipairs({ "LobbyPlayers", "InGamePlayers", "FieldBlocker", "LobbyBlocker" }) do
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end
PhysicsService:CollisionGroupSetCollidable("FieldBlocker", "LobbyPlayers", true)
PhysicsService:CollisionGroupSetCollidable("FieldBlocker", "InGamePlayers", false)
PhysicsService:CollisionGroupSetCollidable("FieldBlocker", "Default", true)
PhysicsService:CollisionGroupSetCollidable("LobbyBlocker", "LobbyPlayers", false)
PhysicsService:CollisionGroupSetCollidable("LobbyBlocker", "InGamePlayers", true)
PhysicsService:CollisionGroupSetCollidable("LobbyBlocker", "Default", true)
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
local function setLobbyBlocker(part)
	if part:IsA("BasePart") then
		part.CollisionGroup = "LobbyBlocker"
		part.CanCollide = true
	end
end
setLobbyBlocker(lobbyBlocker)
for _, part in ipairs(lobbyBlocker:GetDescendants()) do setLobbyBlocker(part) end
lobbyBlocker.DescendantAdded:Connect(setLobbyBlocker)

local function awardMoney(player, amount, reason)
	if not player:IsA("Player") or player.Parent ~= Players then return end
	local stats = player:FindFirstChild("leaderstats")
	local money = stats and stats:FindFirstChild("MONEY")
	if not money then return end
	money.Value += amount
	rewards:FireClient(player, amount, reason)
end

local CoinService = require(script.Parent:WaitForChild("CoinService"))
local coins = CoinService.new(ReplicatedStorage:WaitForChild("Coin"), Config.Coins, awardMoney, function(player)
	return roundStarted and phase == "Playing" and alive[player] == true
end)

local function awardPlacement(player, place)
	player:SetAttribute("RoundPlacement", place)
	player:SetAttribute("PlacementRound", roundId)
	local amount = Config.Rewards.Placements[place]
	local reasons = { "1ST PLACE", "2ND PLACE", "3RD PLACE" }
	if amount then awardMoney(player, amount, reasons[place]) end
	if place == 1 and player:IsA("Player") and player.Parent == Players then
		player.leaderstats.WIN.Value += 1
	end
end

local function participantCharacter(player)
	return player:IsA("Player") and player.Character or player
end

local function participantId(player)
	return player:IsA("Player") and player.UserId or player:GetAttribute("TestUserId")
end

local function participantName(player)
	return player:IsA("Player") and player.DisplayName or player.Name
end

local function characterParts(player)
	local character = participantCharacter(player)
	if not character then return nil end
	if not character:IsDescendantOf(workspace) then return nil end
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
	local baseSpeed = player == holder and Config.HolderSpeed or Config.WalkSpeed
	humanoid:SetAttribute("BaseMoveSpeed", baseSpeed)
	humanoid.WalkSpeed = baseSpeed * ((humanoid:GetAttribute("BananaSlowUntil") or 0) > workspace:GetServerTimeNow() and 0.6 or 1)
	player:SetAttribute("InRound", alive[player] == true)
end

local function publish(newPhase, deadline, winner)
	phase = newPhase
	state:SetAttribute("Phase", phase)
	state:SetAttribute("Deadline", deadline or 0)
	state:SetAttribute("AliveCount", #survivors())
	state:SetAttribute("Winner", winner or "")
	state:SetAttribute("RoundId", roundId)
	state:SetAttribute("HolderUserId", holder and participantId(holder) or 0)
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

local function moveToFloor(player, floor, x, z)
	local character, humanoid, root = characterParts(player)
	if not character then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { floor }
	local center = floor.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
	local hit = workspace:Raycast(center + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0), params)
	if not hit then return false end
	unseat(humanoid)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local position = hit.Position + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.5, 0)
	if floor == field then position += Vector3.new(0, Config.FieldHeightOffset, 0) end
	character:PivotTo(CFrame.new(position))
	return true
end

local function moveToLobby(player)
	moveToFloor(player, lobby, random:NextNumber(-15, 15), random:NextNumber(-15, 15))
	setCharacterState(player, false)
end

local function moveToSpawn(player, point)
	local character, humanoid, root = characterParts(player)
	if not character then return false end
	unseat(humanoid)
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	local top = point.Position + Vector3.new(0, point.Size.Y / 2, 0)
	local height = humanoid.HipHeight + root.Size.Y / 2 + 0.5 + Config.FieldHeightOffset
	local target = CFrame.new(top + Vector3.new(0, height, 0)) * root.CFrame.Rotation
	character:PivotTo(target * root.CFrame:ToObjectSpace(character:GetPivot()))
	return true
end

local obbyFinish = system:WaitForChild("ObbyFinish")
local obbySpawn = system:WaitForChild("SpawnLocation")
local obbyReadyAt = setmetatable({}, { __mode = "k" })
obbyFinish.CanTouch = true
obbyFinish.Touched:Connect(function(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or player:GetAttribute("StatsLoaded") ~= true or player:GetAttribute("InRound") then return end
	local currentCharacter, humanoid, root = characterParts(player)
	if currentCharacter ~= character or not humanoid or humanoid.Health <= 0 or not root then return end
	local now = os.clock()
	if now < (obbyReadyAt[player] or 0) then return end
	local stats = player:FindFirstChild("leaderstats")
	if not stats or not stats:FindFirstChild("MONEY") then return end
	obbyReadyAt[player] = now + 2
	unseat(humanoid)
	local height = obbySpawn.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + 0.5
	local target = CFrame.new(obbySpawn.Position + Vector3.new(0, height, 0)) * root.CFrame.Rotation
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	character:PivotTo(target * root.CFrame:ToObjectSpace(character:GetPivot()))
	awardMoney(player, 10, "OBBY COMPLETE")
end)

local function stopHolderAnimation()
	if holderTrack then
		holderTrack:Stop(0.1)
		Debris:AddItem(holderTrack, 0.2)
		holderTrack = nil
	end
end

local function playHolderAnimation(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local success, track = pcall(function() return animator:LoadAnimation(holderAnimation) end)
	if not success then
		warn("Could not load bomb holder animation: " .. tostring(track))
		return
	end
	holderTrack = track
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.15)
end

local function clearBomb()
	stopHolderAnimation()
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

local function eliminate(player, leaving, bombDeath)
	if not alive[player] then return end
	local place = #survivors()
	alive[player] = nil
	if roundStarted and not leaving and place >= 2 then awardPlacement(player, place) end
	player:SetAttribute("EliminatedRound", roundId)
	player:SetAttribute("InRound", false)
	if player == holder then clearBomb() end
	if bombDeath then
		local character, humanoid, root = characterParts(player)
		if humanoid then
			humanoid.BreakJointsOnDeath = true
			humanoid.Health = 0
			character:BreakJoints()
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					if part.Parent == character and part ~= root then
						local offset = part.Position - root.Position
						local spread = offset.Magnitude > 0 and offset.Unit * 0.4 or Vector3.zero
						spread = Vector3.new(spread.X, math.max(0, spread.Y), spread.Z)
						TweenService:Create(part, TweenInfo.new(0.15), { CFrame = part.CFrame + spread }):Play()
					end
				end
			end
			task.delay(Config.DeathFadeDelay, function()
				if not character.Parent then return end
				for _, item in ipairs(character:GetDescendants()) do
					if item:IsA("BasePart") or item:IsA("Decal") or item:IsA("Texture") then
						TweenService:Create(item, TweenInfo.new(Config.DeathFadeDuration), { Transparency = 1 }):Play()
					end
				end
			end)
		end
		if not player:IsA("Player") then Debris:AddItem(player, Config.DeathRespawnDelay) end
	else
		moveToLobby(player)
	end
	publish(phase, state:GetAttribute("Deadline"))
end

local function attachBomb(player, isPass)
	local character, humanoid = characterParts(player)
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	if not torso or not torso:IsA("BasePart") then return false end
	local previous = holder
	stopHolderAnimation()
	if attachment then attachment:Destroy() end
	if highlight then highlight:Destroy() end
	stopSounds()
	local skinId = player:GetAttribute("EquippedBombSkin") or "Bomb"
	if not SkinCatalog.Items[skinId] or (player:IsA("Player") and player:GetAttribute("OwnsBombSkin_" .. skinId) ~= true) then skinId = "Bomb" end
	if bomb and bomb:GetAttribute("BombSkinId") ~= skinId then bomb:Destroy() bomb = nil end
	if not bomb then
		bomb = SkinCatalog.Clone(skinId)
		bomb.Name = "HotPotatoBomb"
		bomb.Parent = workspace
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
	local rotation = skinId == "Bomb" and CFrame.Angles(math.rad(Config.BombRotationX), 0, 0)
		or bomb:GetAttribute("SkinRotation")
	bomb:PivotTo(torso.CFrame * CFrame.new(0, 0, -Config.BombForwardOffset) * rotation)
	attachment = Instance.new("WeldConstraint")
	attachment.Part0, attachment.Part1 = torso, bomb
	attachment.Parent = bomb
	holder = player
	if roundStarted and (state:GetAttribute("FirstBombHolder") or "") == "" then
		state:SetAttribute("FirstBombHolder", participantName(player))
	end
	if previous then setCharacterState(previous, false) end
	setCharacterState(player, false)
	playHolderAnimation(humanoid)
	highlight = Instance.new("Highlight")
	highlight.Name = "BombHolder"
	highlight.FillColor = Color3.fromRGB(255, 55, 55)
	highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
	highlight.FillTransparency = isPass and 0.25 or 0.8
	highlight.OutlineTransparency = isPass and 0 or 0.4
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
	if isPass then
		TweenService:Create(highlight, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FillTransparency = 0.8,
			OutlineTransparency = 0.4,
		}):Play()
	end
	nextPassAt = workspace:GetServerTimeNow() + Config.PassCooldown
	bomb:SetAttribute("ExpiresAt", expiresAt)
	local timer = bomb:FindFirstChild("BombTimer")
	if timer then
		local seconds = math.max(0, math.ceil(expiresAt - workspace:GetServerTimeNow()))
		timer.TimerLabel.Text = tostring(seconds)
		timer.TimerLabel.TextColor3 = seconds <= 5 and Color3.fromRGB(255, 80, 80) or Color3.new(1, 1, 1)
	end
	if isPass then
		if previous then awardMoney(previous, Config.Rewards.Pass, "BOMB PASSED") end
		playSound("Pass", bomb)
		effects:FireAllClients("Pass", bomb.Position)
	end
	publish("Playing")
	return true
end

local function eligiblePlayers()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("AFK") ~= true and player:GetAttribute("StatsLoaded") == true and characterParts(player) then
			table.insert(list, player)
		end
	end
	if studioTesting then
		if phase == "Waiting" or phase == "Countdown" then
			for index = #testDummies, 1, -1 do
				if not characterParts(testDummies[index]) then
					testDummies[index]:Destroy()
					table.remove(testDummies, index)
				end
			end
			local needed = #list > 0 and math.max(0, Config.MinPlayers - #list) or 0
			while #testDummies > needed do
				table.remove(testDummies):Destroy()
			end
			if #testDummies < needed then
				local source = ReplicatedStorage:FindFirstChild(Config.StudioTesting.DummyName)
				if not source or not source:IsA("Model") or not source:FindFirstChildOfClass("Humanoid")
					or not source:FindFirstChild("HumanoidRootPart") or not source:FindFirstChild("Head") then
					warn("Testing requires a Dummy model with Humanoid, HumanoidRootPart and Head in ReplicatedStorage")
					studioTesting = false
				else
					if not dummyFolder then
						dummyFolder = Instance.new("Folder")
						dummyFolder.Name = "StudioTestDummies"
						dummyFolder.Parent = workspace
					end
					while #testDummies < needed do
						nextDummyId += 1
						local dummy = source:Clone()
						dummy.Name = "Test Dummy " .. nextDummyId
						dummy:SetAttribute("TestUserId", -nextDummyId)
						dummy:SetAttribute("InRound", false)
						for _, part in ipairs(dummy:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Anchored = false
								part.CollisionGroup = "InGamePlayers"
							end
						end
						local humanoid = dummy:FindFirstChildOfClass("Humanoid")
						humanoid.Health = humanoid.MaxHealth
						dummy.Parent = dummyFolder
						dummy.HumanoidRootPart:SetNetworkOwner(nil)
						humanoid.Died:Connect(function() eliminate(dummy) end)
						dummy.DescendantAdded:Connect(function(part)
							if part:IsA("BasePart") then
								part.CollisionGroup = alive[dummy] and "InGamePlayers" or "LobbyPlayers"
							end
						end)
						table.insert(testDummies, dummy)
						moveToLobby(dummy)
					end
				end
			end
		end
		for _, dummy in ipairs(testDummies) do
			if characterParts(dummy) then table.insert(list, dummy) end
		end
	end
	return list
end

local function setupPlayer(player)
	player:SetAttribute("InRound", false)
	player:SetAttribute("AFK", false)
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
	eliminate(player, true)
	for _, connection in ipairs(playerConnections[player] or {}) do connection:Disconnect() end
	playerConnections[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end

afkRequest.OnServerEvent:Connect(function(player, enabled)
	if typeof(enabled) ~= "boolean" or player:GetAttribute("AFK") == enabled then return end
	player:SetAttribute("AFK", enabled)
	if enabled then eliminate(player, true) end
end)

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
	if dummyFolder then table.insert(excluded, dummyFolder) end
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
			local victim = holder
			local position = bomb.Position
			local explosionSound = Config.ExplosionSounds[random:NextInteger(1, #Config.ExplosionSounds)]
			effects:FireAllClients("Explosion", position, explosionSound)
			eliminate(victim, false, true)
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
		local map, spawnPoints = maps:Load()
		if not map then
			warn(spawnPoints)
			effects:FireAllClients("Notice", "The next map is unavailable. Please wait.")
			task.wait(3)
			continue
		end
		state:SetAttribute("MapName", map:GetAttribute("MapName"))
		roundStarted = false
		roundId += 1
		state:SetAttribute("FirstBombHolder", "")
		local list = eligiblePlayers()
		for index, player in ipairs(list) do
			local point = spawnPoints[((index - 1) % #spawnPoints) + 1]
			if moveToSpawn(player, point) then
				player:SetAttribute("RoundPlacement", nil)
				player:SetAttribute("PlacementRound", nil)
				alive[player] = true
				setCharacterState(player, true)
			end
		end
		publish("Preparing", workspace:GetServerTimeNow() + Config.ReadyDelay)
		pause(Config.ReadyDelay, function() return #survivors() < Config.MinPlayers end)
		publish("Ready", workspace:GetServerTimeNow() + Config.ReadyTime)
		pause(Config.ReadyTime, function() return #survivors() < Config.MinPlayers end)
		for player in pairs(alive) do setCharacterState(player, false) end
		publish("Playing")
		if #survivors() >= Config.MinPlayers then
			roundStarted = true
			local listNow = survivors()
			coins:Start(spawnPoints, #listNow)
			expiresAt = workspace:GetServerTimeNow() + Config.BombTime
			attachBomb(listNow[random:NextInteger(1, #listNow)], false)
			playSound("Start")
			playRound()
		end
		coins:Stop()
		clearBomb()
		local remaining = survivors()
		local winner = remaining[1]
		if winner and roundStarted then awardPlacement(winner, 1) end
		roundStarted = false
		publish("Results", workspace:GetServerTimeNow() + Config.ResultTime, winner and participantName(winner) or "")
		playSound(winner and "Victory" or "NoWinner")
		pause(Config.ResultTime)
		for _, player in ipairs(survivors()) do
			alive[player] = nil
			player:SetAttribute("InRound", false)
			moveToLobby(player)
		end
		clearBomb()
		maps:Clear()
		state:SetAttribute("MapName", nil)
	end
end
