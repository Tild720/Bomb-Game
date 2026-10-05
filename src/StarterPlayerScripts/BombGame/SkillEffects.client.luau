local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = game:GetService("Players").LocalPlayer
local fx = ReplicatedStorage:WaitForChild("BombGame"):WaitForChild("SkillFX")
local folder = Instance.new("Folder")
local swapDeparture
folder.Name, folder.Parent = "LocalSkillEffects", workspace

local colors = {
	DoubleJump = Color3.fromRGB(158, 223, 255), Dash = Color3.fromRGB(174, 233, 255),
	Push = Color3.fromRGB(255, 210, 155), PushHit = Color3.fromRGB(255, 228, 193),
	Banana = Color3.fromRGB(255, 229, 108), BananaHit = Color3.fromRGB(255, 229, 108),
	Swap = Color3.fromRGB(206, 183, 255),
	SwapWarning = Color3.fromRGB(206, 183, 255), SwapArrival = Color3.fromRGB(224, 210, 255),
}
local function pulse(position, color, duration, diameter)
	local ring = Instance.new("Part")
	ring.Name, ring.Shape = "SkillPulse", Enum.PartType.Cylinder
	ring.Anchored, ring.CanCollide, ring.CanTouch, ring.CanQuery = true, false, false, false
	ring.Material, ring.Color, ring.Transparency = Enum.Material.Neon, color, 0.65
	ring.Size = Vector3.new(0.045, 1.5, 1.5)
	ring.CFrame = CFrame.new(position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.025, diameter, diameter), Transparency = 1,
	}):Play()
	Debris:AddItem(ring, duration)
end
local function trail(root, color, duration)
	local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
	top.Position, bottom.Position = Vector3.new(0, 0.8, 0.3), Vector3.new(0, -0.8, 0.3)
	top.Parent, bottom.Parent = root, root
	local ribbon = Instance.new("Trail")
	ribbon.Name, ribbon.Attachment0, ribbon.Attachment1 = "SkillRibbon", top, bottom
	ribbon.Lifetime, ribbon.MinLength, ribbon.FaceCamera = 0.18, 0.05, true
	ribbon.Color = ColorSequence.new(color)
	ribbon.Transparency = NumberSequence.new(0.55, 1)
	ribbon.WidthScale = NumberSequence.new(0.65, 0)
	ribbon.Parent = root
	task.delay(duration, function() if ribbon.Parent then ribbon.Enabled = false end end)
	Debris:AddItem(top, duration + 0.2)
	Debris:AddItem(bottom, duration + 0.2)
	Debris:AddItem(ribbon, duration + 0.2)
end
fx.OnClientEvent:Connect(function(kind, character, position)
	if not colors[kind] or typeof(position) ~= "Vector3" then return end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == player.Character then
		if kind == "Swap" then swapDeparture = position end
		if kind == "SwapArrival" and swapDeparture and root then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local offset = swapDeparture - position
				if offset.Magnitude > 8 then offset = offset.Unit * 8 end
				local original = humanoid.CameraOffset
				humanoid.CameraOffset = original + root.CFrame:VectorToObjectSpace(offset)
				TweenService:Create(humanoid, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CameraOffset = original }):Play()
			end
			swapDeparture = nil
		end
	end
	local duration = kind == "SwapWarning" and 0.65 or 0.4
	pulse(position, colors[kind], duration, kind == "SwapWarning" and 7 or 5)
	if root and (kind == "Dash" or kind == "DoubleJump" or kind == "PushHit" or kind == "BananaHit") then
		trail(root, colors[kind], kind == "Dash" and 0.32 or 0.25)
	end
end)
