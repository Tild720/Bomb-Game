local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Settings = require(game:GetService("ReplicatedStorage"):WaitForChild("BombGame"):WaitForChild("SkillMotion"))
local player = Players.LocalPlayer
local Motion = {}
local dash, jump
local function finish()
	local current = dash
	dash = nil
	if current and current.root.Parent and not current.root.Anchored and not current.root:FindFirstChild("SkillMotion") then
		local velocity = current.root.AssemblyLinearVelocity
		local walking = current.humanoid.MoveDirection * current.humanoid.WalkSpeed
		current.root.AssemblyLinearVelocity = Vector3.new(walking.X, velocity.Y, walking.Z)
	end
end
function Motion.Cancel()
	finish()
	if jump and jump.root.Parent and not jump.root.Anchored then
		local v = jump.root.AssemblyLinearVelocity
		jump.root.AssemblyLinearVelocity = Vector3.new(v.X, math.min(v.Y, jump.previousY), v.Z)
	end
	jump = nil
end
function Motion.Confirm()
	jump = nil
end
local function params(character)
	local p = RaycastParams.new()
	p.RespectCanCollide, p.CollisionGroup = true, "InGamePlayers"
	local exclude = { character }
	for _, other in Players:GetPlayers() do if other.Character then table.insert(exclude, other.Character) end end
	for _, name in { "StudioTestDummies", "SkillEffects", "LocalSkillEffects" } do
		local folder = workspace:FindFirstChild(name)
		if folder then table.insert(exclude, folder) end
	end
	p.FilterDescendantsInstances = exclude
	return p
end
function Motion.Start(id)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or root.Anchored or root:FindFirstChild("SkillMotion") then return false end
	if id == "DoubleJump" then
		if humanoid.FloorMaterial ~= Enum.Material.Air then return false end
		local v = root.AssemblyLinearVelocity
		jump = { root = root, previousY = v.Y }
		root.AssemblyLinearVelocity = Vector3.new(v.X, Settings.JumpVelocity, v.Z)
		return true
	end
	if id ~= "Dash" then return false end
	finish()
	local facing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if facing.Magnitude < 0.01 then return false end
	local direction = facing.Unit
	local cast = params(character)
	local hit = workspace:Blockcast(root.CFrame, Vector3.new(2, 3, 2), direction * Settings.DashDistance, cast)
	local distance = hit and math.max(0, hit.Distance - 1) or Settings.DashDistance
	if distance < 1 then return false end
	dash = { root = root, humanoid = humanoid, started = os.clock(), origin = root.Position, direction = direction, distance = distance, params = cast }
	local token = dash
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = direction * Settings.DashSpeed + Vector3.new(0, v.Y, 0)
	task.delay(Settings.DashDuration, function() if dash == token then finish() end end)
	return true
end
RunService.PreSimulation:Connect(function(delta)
	local d = dash
	if not d then return end
	local elapsed = os.clock() - d.started
	if not d.root.Parent or d.root.Anchored or d.humanoid.Health <= 0 or not player:GetAttribute("InRound")
		or d.root:FindFirstChild("SkillMotion") or elapsed >= Settings.DashDuration then finish() return end
	local remaining = d.distance - (d.root.Position - d.origin).Magnitude
	local walking = d.humanoid.MoveDirection * d.humanoid.WalkSpeed
	local velocity = walking:Lerp(d.direction * Settings.DashSpeed, Settings.DashWeight(elapsed))
	local step = math.max(delta, 1 / 240)
	if remaining <= 0.1 or workspace:Blockcast(d.root.CFrame, Vector3.new(2, 3, 2), d.direction * math.min(remaining, velocity.Magnitude * step + 0.5), d.params) then finish() return end
	if velocity.Magnitude * step > remaining then velocity = velocity.Unit * remaining / step end
	d.root.AssemblyLinearVelocity = Vector3.new(velocity.X, d.root.AssemblyLinearVelocity.Y, velocity.Z)
end)
player.CharacterRemoving:Connect(function() finish() jump = nil end)
return Motion
