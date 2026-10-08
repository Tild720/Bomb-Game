local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Catalog = require(shared:WaitForChild("SkillCatalog"))
local Config = require(shared:WaitForChild("Config"))
local unseat = require(script.Parent:WaitForChild("Unseat"))
local state = shared:WaitForChild("State")
local hitbox = workspace:WaitForChild("System"):WaitForChild("ShopHitbox")
local request = Instance.new("RemoteEvent")
request.Name = "SkillRequest"
request.Parent = shared
local fx = Instance.new("RemoteEvent")
fx.Name, fx.Parent = "SkillFX", shared
local soundPack = game:GetService("SoundService"):WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")
local visuals = Instance.new("Folder")
visuals.Name = "SkillEffects"
visuals.Parent = workspace
local cooldowns, requests, doubleJumps, swaps, slows = {}, {}, {}, {}, {}
local motionTokens = {}
local bananas = {}

local function skillSound(kind, parent)
	local item = Config.SkillSounds[kind]
	local template = item and soundPack:FindFirstChild(item.Name)
	if not template then return end
	local sound = template:Clone()
	sound.Looped, sound.TimePosition = false, 0
	sound.Volume, sound.PlaybackSpeed = item.Volume, item.Speed or 1
	sound.RollOffMinDistance, sound.RollOffMaxDistance = 8, 65
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 4)
end

local function parts(subject)
	local character = subject:IsA("Player") and subject.Character or subject
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 and character:IsDescendantOf(workspace) and not root.Anchored then
		return character, humanoid, root
	end
end
local function reply(player, success, message)
	if player.Parent == Players then request:FireClient(player, "Result", success, message) end
end
local function flat(vector)
	local horizontal = Vector3.new(vector.X, 0, vector.Z)
	return horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.new(0, 0, -1)
end
local function participants()
	local result = {}
	for _, player in Players:GetPlayers() do if player:GetAttribute("InRound") then table.insert(result, player) end end
	local dummies = workspace:FindFirstChild("StudioTestDummies")
	if RunService:IsStudio() and dummies then
		for _, dummy in dummies:GetChildren() do if dummy:GetAttribute("InRound") then table.insert(result, dummy) end end
	end
	return result
end
local function castParams()
	local params = RaycastParams.new()
	params.RespectCanCollide = true
	params.CollisionGroup = "InGamePlayers"
	local exclude = { visuals }
	for _, subject in participants() do
		local character = subject:IsA("Player") and subject.Character or subject
		if character then table.insert(exclude, character) end
	end
	params.FilterDescendantsInstances = exclude
	return params
end
local function nearest(player, root, range)
	local best, distance = nil, range
	local facing = flat(root.CFrame.LookVector)
	local params = castParams()
	for _, other in participants() do
		if other ~= player then
			local _, _, otherRoot = parts(other)
			if otherRoot then
				local delta = otherRoot.Position - root.Position
				local d = delta.Magnitude
				if d > 0.01 and d <= distance and facing:Dot(delta.Unit) >= 0.5
					and not workspace:Raycast(root.Position, delta, params) then
					best, distance = other, d
				end
			end
		end
	end
	return best
end
local function glow(character, color, duration)
	local effect = Instance.new("Highlight")
	effect.Name = "SkillFlash"
	effect.Adornee = character
	effect.FillColor, effect.OutlineColor = color, color
	effect.FillTransparency = 1
	effect.OutlineTransparency = 1
	effect.Parent = visuals
	TweenService:Create(effect, TweenInfo.new(0.07), { FillTransparency = 0.5, OutlineTransparency = 0.15 }):Play()
	task.delay(0.07, function()
		if effect.Parent then TweenService:Create(effect, TweenInfo.new(math.max(0.05, duration - 0.07)), { FillTransparency = 1, OutlineTransparency = 1 }):Play() end
	end)
	Debris:AddItem(effect, duration)
end
local function stopMotion(root, restoreOwner)
	local motion = motionTokens[root]
	if not motion then return end
	motionTokens[root] = nil
	if motion.tween then motion.tween:Cancel() end
	if motion.force then motion.force:Destroy() end
	if motion.attachment then motion.attachment:Destroy() end
	if restoreOwner and root.Parent and not root.Anchored and root:CanSetNetworkOwnership() then root:SetNetworkOwnershipAuto() end
end
local function motion(root, velocity, duration, kind)
	stopMotion(root, false)
	local token = { character = root.Parent, deadline = os.clock() + duration, kind = kind }
	motionTokens[root] = token
	if root:CanSetNetworkOwnership() then root:SetNetworkOwner(nil) end
	local attachment = Instance.new("Attachment")
	attachment.Name, attachment.Parent = "SkillMotionAttachment", root
	local force = Instance.new("LinearVelocity")
	force.Name, force.Attachment0 = "SkillMotion", attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	force.ForceLimitsEnabled, force.ForceLimitMode = true, Enum.ForceLimitMode.PerAxis
	force.MaxAxesForce = Vector3.new(root.AssemblyMass * 2500, 0, root.AssemblyMass * 2500)
	local current = root.AssemblyLinearVelocity
	force.VectorVelocity = Vector3.new(current.X, 0, current.Z)
	force.Parent = root
	token.attachment, token.force = attachment, force
	Debris:AddItem(force, duration + 0.1)
	Debris:AddItem(attachment, duration + 0.1)
	task.delay(duration, function() if motionTokens[root] == token then stopMotion(root, true) end end)
	if kind == "Push" then root:ApplyImpulse(Vector3.new(0, 5, 0) * root.AssemblyMass) end
	local peak = Vector3.new(velocity.X, 0, velocity.Z)
	local ramp = 0.04
	local hold = 0
	token.tween = TweenService:Create(force, TweenInfo.new(ramp, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { VectorVelocity = peak })
	token.tween:Play()
	task.delay(ramp + hold, function()
		if motionTokens[root] ~= token or not force.Parent then return end
		local humanoid = token.character:FindFirstChildOfClass("Humanoid")
		local finish = humanoid and humanoid.MoveDirection * humanoid.WalkSpeed or Vector3.zero
		token.tween = TweenService:Create(force, TweenInfo.new(duration - ramp - hold, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { VectorVelocity = finish })
		token.tween:Play()
	end)
end
local function consume(player, id)
	local untilTime = workspace:GetServerTimeNow() + Catalog.Items[id].Cooldown
	cooldowns[player] = untilTime
	player:SetAttribute("SkillReadyAt", untilTime)
	request:FireClient(player, "Used", id)
	local character, _, root = parts(player)
	if root then
		skillSound(id, root)
		fx:FireAllClients(id, character, root.Position)
	end
end
local function isPlaying(player)
	return player:GetAttribute("InRound") and state:GetAttribute("Phase") == "Playing"
end
local function safeDestination(root, params)
	local overlap = OverlapParams.new()
	overlap.RespectCanCollide = true
	overlap.CollisionGroup = params.CollisionGroup
	overlap.FilterDescendantsInstances = params.FilterDescendantsInstances
	return #workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(2, 3, 2), overlap) == 0
end

local function useSkill(player)
	if not isPlaying(player) then return reply(player, false, "Skills are available during the round.") end
	local character, humanoid, root = parts(player)
	if not character then return reply(player, false, "Your character is not ready.") end
	local id = player:GetAttribute("EquippedSkill") or "DoubleJump"
	if not Catalog.Items[id] or not player:GetAttribute("OwnsSkill_" .. id) then return end
	if swaps[player] then return reply(player, false, "Your swap is already preparing.") end
	local now = workspace:GetServerTimeNow()
	if (cooldowns[player] or 0) > now then return reply(player, false, "Your skill is still cooling down.") end
	if id == "DoubleJump" then
		if humanoid.FloorMaterial ~= Enum.Material.Air or doubleJumps[player] == character then
			return reply(player, false, "Jump into the air first. Land to recharge.")
		end
		doubleJumps[player] = character
		consume(player, id)
		glow(character, Color3.fromRGB(146, 226, 255), 0.4)
	elseif id == "Dash" then
		consume(player, id)
		glow(character, Color3.fromRGB(123, 232, 255), 0.25)
	elseif id == "Push" then
		local target = nearest(player, root, 9)
		if not target then return reply(player, false, "No player close enough in front of you.") end
		local targetCharacter, _, targetRoot = parts(target)
		consume(player, id)
		motion(targetRoot, flat(targetRoot.Position - root.Position) * 42, 0.34, "Push")
		skillSound("PushHit", targetRoot)
		fx:FireAllClients("PushHit", targetCharacter, targetRoot.Position)
		glow(targetCharacter, Color3.fromRGB(255, 197, 117), 0.35)
	elseif id == "Banana" then
		local floor = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), castParams())
		if not floor then return reply(player, false, "Move closer to the ground to drop a banana.") end
		consume(player, id)
		local peel = Instance.new("Model")
		peel.Name = "BananaPeel"
		peel.Parent = visuals
		for i = 1, 3 do
			local leaf = Instance.new("WedgePart")
			leaf.Size = Vector3.new(0.6, 0.3, 1.6)
			leaf.Color = Color3.fromRGB(255, 223, 60)
			leaf.Material = Enum.Material.SmoothPlastic
			leaf.Anchored, leaf.CanCollide, leaf.CanTouch, leaf.CanQuery = true, false, false, false
			local landing = CFrame.new(floor.Position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, i * math.pi * 2 / 3, 0) * CFrame.new(0, 0, 0.5)
			leaf.CFrame = landing + Vector3.new(0, 1.1, 0)
			leaf.Transparency = 1
			leaf.Parent = peel
			TweenService:Create(leaf, TweenInfo.new(0.23, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = landing, Transparency = 0 }):Play()
		end
		table.insert(bananas, { owner = player, model = peel, position = floor.Position, armedAt = now + 0.4, expires = now + 15 })
	elseif id == "Swap" then
		local target = nearest(player, root, 24)
		if not target then return reply(player, false, "No player in front of you within swap range.") end
		if swaps[target] then return reply(player, false, "That player is already swapping.") end
		local targetCharacter, _, targetRoot = parts(target)
		local roundId = state:GetAttribute("RoundId")
		local token = {}
		swaps[player], swaps[target] = token, token
		skillSound("SwapWarning", root)
		skillSound("SwapWarning", targetRoot)
		fx:FireAllClients("SwapWarning", character, root.Position)
		fx:FireAllClients("SwapWarning", targetCharacter, targetRoot.Position)
		glow(character, Color3.fromRGB(200, 157, 255), 0.65)
		glow(targetCharacter, Color3.fromRGB(200, 157, 255), 0.65)
		request:FireClient(player, "Notice", "Swapping in 0.65s!")
		if target:IsA("Player") then request:FireClient(target, "Notice", "Someone is swapping places with you!") end
		task.delay(0.65, function()
			if swaps[player] ~= token or swaps[target] ~= token then return end
			swaps[player], swaps[target] = nil, nil
			local current, currentHumanoid, currentRoot = parts(player)
			local other, otherHumanoid, otherRoot = parts(target)
			if not isPlaying(player) or not isPlaying(target) or roundId ~= state:GetAttribute("RoundId")
				or current ~= character or other ~= targetCharacter or not currentRoot or not otherRoot then
				return reply(player, false, "Swap canceled: the target is no longer available.")
			end
			local delta = otherRoot.Position - currentRoot.Position
			local params = castParams()
			if delta.Magnitude > 24 or workspace:Raycast(currentRoot.Position, delta, params)
				or not safeDestination(currentRoot, params) or not safeDestination(otherRoot, params) then
				return reply(player, false, "Swap canceled: the target moved away or the path is blocked.")
			end
			consume(player, id)
			unseat(currentHumanoid)
			unseat(otherHumanoid)
			stopMotion(currentRoot, true)
			stopMotion(otherRoot, true)
			fx:FireAllClients("Swap", other, otherRoot.Position)
			skillSound("Swap", otherRoot)
			current:PivotTo(current:GetPivot() + delta)
			other:PivotTo(other:GetPivot() - delta)
			currentRoot.AssemblyLinearVelocity, otherRoot.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
			fx:FireAllClients("SwapArrival", current, currentRoot.Position)
			fx:FireAllClients("SwapArrival", other, otherRoot.Position)
			glow(current, Color3.fromRGB(200, 157, 255), 0.4)
			glow(other, Color3.fromRGB(200, 157, 255), 0.4)
		end)
	end
end

request.OnServerEvent:Connect(function(player, action, id)
	if typeof(action) ~= "string" then return end
	local now = os.clock()
	if now - (requests[player] or 0) < 0.15 then return end
	requests[player] = now
	if player:GetAttribute("StatsLoaded") ~= true then return reply(player, false, "Your data is still loading. Please wait.") end
	if action == "Use" then return useSkill(player) end
	if action ~= "Buy" and action ~= "Equip" then return end
	if typeof(id) ~= "string" or not Catalog.Items[id] then return reply(player, false, "Unknown skill.") end
	local _, _, root = parts(player)
	if player:GetAttribute("InRound") or not Catalog.InShop(hitbox, root) then
		return reply(player, false, "Stand inside the skill shop to buy or equip.")
	end
	local owned = player:GetAttribute("OwnsSkill_" .. id) == true
	if action == "Buy" then
		local stats = player:FindFirstChild("leaderstats")
		local money = stats and stats:FindFirstChild("MONEY")
		if not money then return reply(player, false, "Your money is not available yet.") end
		local reason = Catalog.PurchaseError(id, owned, money.Value)
		if reason then return reply(player, false, reason) end
		money.Value -= Catalog.Items[id].Price
		player:SetAttribute("OwnsSkill_" .. id, true)
		reply(player, true, Catalog.Items[id].Name .. " purchased! Select EQUIP to use it.")
	else
		if not owned then return reply(player, false, "Purchase this skill first.") end
		player:SetAttribute("EquippedSkill", id)
		reply(player, true, Catalog.Items[id].Name .. " equipped.")
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	for root, record in pairs(motionTokens) do
		local subject = Players:GetPlayerFromCharacter(record.character) or record.character
		local humanoid = record.character:FindFirstChildOfClass("Humanoid")
		if not root.Parent or root.Anchored or not humanoid or humanoid.Health <= 0 or not isPlaying(subject)
			or os.clock() >= record.deadline then stopMotion(root, true) end
	end
	elapsed += delta
	if elapsed < 0.05 then return end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	for player, character in pairs(doubleJumps) do
		local current, humanoid = parts(player)
		if current ~= character or (humanoid and humanoid.FloorMaterial ~= Enum.Material.Air) then doubleJumps[player] = nil end
	end
	for humanoid, subject in pairs(slows) do
		if not humanoid.Parent or not isPlaying(subject) or (humanoid:GetAttribute("BananaSlowUntil") or 0) <= now then
			if humanoid.Parent then
				humanoid:SetAttribute("BananaSlowUntil", nil)
				humanoid.WalkSpeed = humanoid:GetAttribute("BaseMoveSpeed") or 20
			end
			slows[humanoid] = nil
		end
	end
	for i = #bananas, 1, -1 do
		local peel = bananas[i]
		local remove = not peel.model.Parent or now >= peel.expires or state:GetAttribute("Phase") ~= "Playing"
		if not remove and now >= peel.armedAt then
			for _, subject in participants() do
				local character, humanoid, root = parts(subject)
				local offset = root and root.Position - peel.position
				if subject ~= peel.owner and offset and offset.Y >= 0 and offset.Y <= 4.5
					and Vector3.new(offset.X, 0, offset.Z).Magnitude <= 1.8 then
					humanoid:SetAttribute("BananaSlowUntil", now + 1.5)
					humanoid.WalkSpeed = (humanoid:GetAttribute("BaseMoveSpeed") or 20) * 0.6
					slows[humanoid] = subject
					motion(root, flat(root.CFrame.LookVector) * 13, 0.28, "Slip")
					skillSound("BananaHit", root)
					fx:FireAllClients("BananaHit", character, root.Position)
					glow(character, Color3.fromRGB(255, 223, 60), 0.4)
					if subject:IsA("Player") then request:FireClient(subject, "Notice", "Slipped! 40% slower for 1.5s.") end
					remove = true
					break
				end
			end
		end
		if remove then
			for _, leaf in peel.model:GetChildren() do
				if leaf:IsA("BasePart") then TweenService:Create(leaf, TweenInfo.new(0.18), { Transparency = 1, Size = leaf.Size * 0.2 }):Play() end
			end
			Debris:AddItem(peel.model, 0.2)
			table.remove(bananas, i)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player], requests[player], doubleJumps[player] = nil, nil, nil
end)
