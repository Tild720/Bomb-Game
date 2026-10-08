local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local vipRequest = shared:WaitForChild("VIPRequest")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SubGui")
require(shared:WaitForChild("MenuTheme")).Apply(gui)
local panels = gui:WaitForChild("MenuPanels")
local vipButton = panels.Shop.Background.Items.BuyButton
local miniMessage = player.PlayerGui:WaitForChild("HotPotatoGui"):WaitForChild("MiniMessageLabel")
local miniScale = miniMessage:WaitForChild("AnimationScale")
local sounds = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")
local activePanel
local animations = {}
local baseline = {}
local available = false
local targetKey
local cameraOwned = false
local savedSubject
local savedCameraType
local purchasePending = false
local lastHoverAt = 0
local noticeVersion = 0
local purchaseVersion = 0
local closePanel

local function sound(kind)
	if kind == "HoverSound" then
		if os.clock() - lastHoverAt < 0.06 then return end
		lastHoverAt = os.clock()
	end
	local source = sounds:FindFirstChild(Config.Menus[kind])
	if not source then return end
	local clone = source:Clone()
	clone.Name = "MenuSound"
	clone.Looped = false
	clone.TimePosition = 0
	clone.Volume = Config.Menus.SoundVolume
	clone.Parent = SoundService
	clone:Play()
	Debris:AddItem(clone, 3)
end

local function tween(object, properties, duration)
	if animations[object] then animations[object]:Cancel() end
	local animation = TweenService:Create(object, TweenInfo.new(duration or Config.Menus.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	animations[object] = animation
	animation:Play()
	return animation
end

local function escape(text)
	return tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local miniTextTransparency = miniMessage.TextTransparency
local miniStrokeTransparency = miniMessage.TextStrokeTransparency
local miniBaseScale = miniScale.Scale
local function notify(message)
	noticeVersion += 1
	local version = noticeVersion
	miniMessage.RichText = true
	miniMessage.TextColor3 = Color3.new(1, 1, 1)
	local styled = escape(message):gsub('(%$[%d,]+)', '<font color="#FFE89D"><b>%1</b></font>')
	miniMessage.Text = '<font color="#FFCE65"><b>!</b></font> ' .. styled
	miniMessage.Visible = true
	miniMessage.TextTransparency = 1
	miniMessage.TextStrokeTransparency = 1
	miniScale.Scale = miniBaseScale * 0.9
	tween(miniMessage, { TextTransparency = miniTextTransparency, TextStrokeTransparency = miniStrokeTransparency })
	tween(miniScale, { Scale = miniBaseScale })
	sound("PopupSound")
	task.delay(2.5, function()
		if noticeVersion ~= version then return end
		tween(miniScale, { Scale = miniBaseScale * 0.95 })
		local fade = tween(miniMessage, { TextTransparency = 1, TextStrokeTransparency = 1 })
		fade.Completed:Once(function(status)
			if noticeVersion == version and status == Enum.PlaybackState.Completed then miniMessage.Visible = false end
		end)
	end)
end

local noticeEvent = Instance.new("BindableEvent")
noticeEvent.Name = "MenuNotice"
noticeEvent.Event:Connect(notify)
noticeEvent.Parent = gui

local function remember(object)
	local values = {}
	if object:IsA("GuiObject") then values.BackgroundTransparency = object.BackgroundTransparency end
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		values.TextTransparency = object.TextTransparency
		values.TextStrokeTransparency = object.TextStrokeTransparency
	end
	if object:IsA("ImageLabel") or object:IsA("ImageButton") or object:IsA("ViewportFrame") then
		values.ImageTransparency = object.ImageTransparency
	end
	if object:IsA("UIStroke") or object.ClassName == "UIShadow" then values.Transparency = object.Transparency end
	if next(values) then baseline[object] = values end
end
local menuRoots = {}
for _, name in ipairs({ "Shop", "Guide", "Spectate" }) do
	local root = gui:WaitForChild(name .. "Button")
	table.insert(menuRoots, root)
	remember(root)
	for _, object in ipairs(root:GetDescendants()) do remember(object) end
end

local function restoreCamera()
	if not cameraOwned then return end
	cameraOwned = false
	local camera = workspace.CurrentCamera
	if not camera then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	elseif savedSubject and savedSubject.Parent then
		camera.CameraType = savedCameraType or Enum.CameraType.Custom
		camera.CameraSubject = savedSubject
	end
	savedSubject = nil
end

local function spectateTargets()
	local result = {}
	local function add(key, character, name, order)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and character:IsDescendantOf(workspace) then
			table.insert(result, { key = key, humanoid = humanoid, name = name, order = order })
		end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other:GetAttribute("InRound") then add(other, other.Character, other.DisplayName, other.UserId) end
	end
	local dummies = workspace:FindFirstChild("StudioTestDummies")
	if RunService:IsStudio() and dummies then
		for _, dummy in ipairs(dummies:GetChildren()) do
			if dummy:GetAttribute("InRound") then add(dummy, dummy, dummy.Name, dummy:GetAttribute("TestUserId") or 0) end
		end
	end
	table.sort(result, function(a, b) return a.order < b.order end)
	return result
end

local function refreshSpectate(step)
	if activePanel ~= "Spectate" or not available then return end
	local targets = spectateTargets()
	local panel = panels.Spectate.Background
	panel.PreviousButton.Interactable = #targets > 1
	panel.NextButton.Interactable = #targets > 1
	if #targets == 0 then
		targetKey = nil
		closePanel(false)
		notify("No players to spectate right now.")
		return
	end
	local index = 1
	for i, target in ipairs(targets) do if target.key == targetKey then index = i break end end
	index = ((index - 1 + (step or 0)) % #targets) + 1
	local target = targets[index]
	local changed = target.key ~= targetKey
	targetKey = target.key
	local camera = workspace.CurrentCamera
	if camera then
		if not cameraOwned then
			savedSubject, savedCameraType = camera.CameraSubject, camera.CameraType
			cameraOwned = true
		end
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = target.humanoid
	end
	panel.TargetLabel.Text = '<b>' .. escape(target.name) .. '</b>'
	panel.CounterLabel.Text = '<font color="#FFE89D"><b>' .. index .. '</b></font> / ' .. #targets .. '  <i>Survivors</i>'
	if changed then
		panel.TargetLabel.TextTransparency = 0.7
		tween(panel.TargetLabel, { TextTransparency = 0 })
	end
end

local function panelInputs(panel, enabled)
	for _, object in ipairs(panel:GetDescendants()) do
		if object:IsA("GuiButton") then object.Interactable = enabled end
	end
end

closePanel = function(withSound)
	if not activePanel then return end
	local closing = panels[activePanel]
	activePanel = nil
	panelInputs(closing, false)
	restoreCamera()
	if withSound then sound("CloseSound") end
	tween(closing.PanelScale, { Scale = 0.94 })
	local fade = tween(closing, { GroupTransparency = 1 })
	fade.Completed:Once(function(status)
		if status == Enum.PlaybackState.Completed and activePanel ~= closing.Name then closing.Visible = false end
	end)
end

local function refreshShop()
	local panel = panels.Shop.Background
	local vip = player:GetAttribute("VIP") == true
	vipButton.Caption.Text = vip and "VIP ACTIVE" or (Config.VIP.GamePassId > 0 and "GET VIP" or '<font color="#FFE89D"><b>TRY VIP FREE</b></font>')
	vipButton.Interactable = available and activePanel == "Shop" and not vip and not purchasePending
	if vip then
		panel.Feedback.Text = player:GetAttribute("VIPSample") and '<font color="#B9F6CE"><b>Activated!</b></font> <i>This session only</i>' or 'Your <font color="#FFE89D"><b>VIP</b></font> chat tag is ready!'
	elseif Config.VIP.GamePassId == 0 and (not RunService:IsStudio() or not Config.VIP.StudioSamplePurchase) then
		vipButton.Caption.Text = "COMING SOON"
		vipButton.Interactable = false
	end
	if not vip and Config.VIP.GamePassId == 0 then panel.Feedback.Text = '<i>Free Studio sample.</i> <b>No Robux charged.</b>' end
end

local function openPanel(name)
	if not available then return end
	gui:SetAttribute("SkillShopOpen", false)
	gui:SetAttribute("BombSkinShopOpen", false)
	if activePanel == name then closePanel(true) return end
	if name == "Spectate" and #spectateTargets() == 0 then
		notify("No players to spectate right now.")
		return
	end
	closePanel(false)
	activePanel = name
	local panel = panels[name]
	panel.Visible = true
	panel.GroupTransparency = 1
	panel.PanelScale.Scale = 0.9
	panelInputs(panel, true)
	tween(panel, { GroupTransparency = 0 })
	tween(panel.PanelScale, { Scale = 1 })
	sound("PopupSound")
	if name == "Shop" then refreshShop() end
	if name == "Spectate" then refreshSpectate() end
end

local function bindButton(button, scale, action, panelName)
	local baseScale = scale.Scale
	local hoverScale = 1.015
	local hovered = false
	local function allowed()
		return available and button.Interactable and (not panelName or activePanel == panelName)
	end
	button.MouseEnter:Connect(function()
		hovered = true
		if allowed() then tween(scale, { Scale = baseScale * hoverScale }, 0.14) sound("HoverSound") end
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		tween(scale, { Scale = baseScale })
	end)
	button.InputBegan:Connect(function(input)
		if allowed() and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			tween(scale, { Scale = baseScale * 0.985 }, 0.08)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tween(scale, { Scale = baseScale * (hovered and allowed() and hoverScale or 1) }, 0.14)
		end
	end)
	button.Activated:Connect(function()
		if not allowed() then return end
		sound("ClickSound")
		action()
	end)
end

gui:GetAttributeChangedSignal("SkillShopOpen"):Connect(function()
	if gui:GetAttribute("SkillShopOpen") then closePanel(false) end
end)
gui:GetAttributeChangedSignal("BombSkinShopOpen"):Connect(function()
	if gui:GetAttribute("BombSkinShopOpen") then closePanel(false) end
end)

for _, name in ipairs({ "Shop", "Guide", "Spectate" }) do
	local button = gui[name .. "Button"]
	local shift = Vector2.new(0.5, 0.5) - button.AnchorPoint
	button.Position += UDim2.new(button.Size.X.Scale * shift.X, button.Size.X.Offset * shift.X,
		button.Size.Y.Scale * shift.Y, button.Size.Y.Offset * shift.Y)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Name, scale.Parent = "InteractionScale", button
	bindButton(button, scale, function() openPanel(name) end)
	local close = panels[name].Background.CloseButton
	bindButton(close, close.InteractionScale, function() closePanel(true) end, name)
end
local spectate = panels.Spectate.Background
bindButton(spectate.PreviousButton, spectate.PreviousButton.InteractionScale, function() refreshSpectate(-1) end, "Spectate")
bindButton(spectate.NextButton, spectate.NextButton.InteractionScale, function() refreshSpectate(1) end, "Spectate")
local buy = vipButton
bindButton(buy, buy.InteractionScale, function()
	if player:GetAttribute("VIP") then return end
	purchasePending = true
	purchaseVersion += 1
	local version = purchaseVersion
	refreshShop()
	if Config.VIP.GamePassId > 0 then
		local ok = pcall(function() MarketplaceService:PromptGamePassPurchase(player, Config.VIP.GamePassId) end)
		if not ok then
			purchasePending = false
			notify("Purchase unavailable. Please try again.")
			refreshShop()
		end
	elseif RunService:IsStudio() and Config.VIP.StudioSamplePurchase then
		vipRequest:FireServer(version)
		task.delay(5, function()
			if purchasePending and purchaseVersion == version then
				purchasePending = false
				refreshShop()
				notify("Purchase confirmation timed out. Please try again.")
			end
		end)
	else
		purchasePending = false
		refreshShop()
		notify("This purchase is currently unavailable.")
	end
end, "Shop")

vipRequest.OnClientEvent:Connect(function(version, success, reason)
	if version ~= purchaseVersion then return end
	purchasePending = false
	refreshShop()
	if not success then notify(reason or "Purchase failed. Please try again.") end
end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId, purchased)
	if who == player and passId == Config.VIP.GamePassId then
		purchasePending = false
		refreshShop()
		if not purchased then notify("Purchase canceled or could not be completed.") end
	end
end)
player:GetAttributeChangedSignal("VIP"):Connect(function()
	purchasePending = false
	refreshShop()
	if activePanel == "Shop" then
		sound("PopupSound")
		panels.Shop.PanelScale.Scale = 0.96
		tween(panels.Shop.PanelScale, { Scale = 1 })
	end
end)

TextChatService.OnIncomingMessage = function(message)
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if speaker and speaker:GetAttribute("VIP") then
		local properties = Instance.new("TextChatMessageProperties")
		properties.PrefixText = '<font color="#FFD65A"><b>[VIP]</b></font> ' .. message.PrefixText
		return properties
	end
	return nil
end

local function refreshAvailability()
	available = player:GetAttribute("InRound") ~= true
	if not available then closePanel(true) end
	for _, root in ipairs(menuRoots) do root.Visible = true end
	for _, name in ipairs({ "Shop", "Guide", "Spectate" }) do
		gui[name .. "Button"].Interactable = available
		gui[name .. "Button"].Active = available
	end
	for object, original in pairs(baseline) do
		local goal = {}
		for property, value in pairs(original) do goal[property] = available and value or 1 end
		tween(object, goal)
	end
	local shown = available
	task.delay(Config.Menus.TweenTime, function()
		if not shown and not available then
			for _, root in ipairs(menuRoots) do root.Visible = false end
		end
	end)
end
player:GetAttributeChangedSignal("InRound"):Connect(refreshAvailability)
refreshAvailability()
refreshShop()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not activePanel then return end
	if input.KeyCode == Enum.KeyCode.Escape then closePanel(true) end
	if activePanel == "Spectate" and available then
		if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right then
			sound("ClickSound")
			refreshSpectate(input.KeyCode == Enum.KeyCode.Left and -1 or 1)
		end
	end
end)
local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed >= 0.25 then elapsed = 0 refreshSpectate() end
end)
