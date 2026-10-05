local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local Catalog = require(shared:WaitForChild("BombSkinCatalog"))
local SkillCatalog = require(shared:WaitForChild("SkillCatalog"))
local remote = shared:WaitForChild("BombSkinRequest")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SubGui")
require(shared:WaitForChild("MenuTheme")).Apply(gui)
local shop = require(shared:WaitForChild("BombSkinUI")).Create(gui)
local hitbox = workspace:WaitForChild("System"):WaitForChild("SkinShopHitbox")
local notice = gui:WaitForChild("MenuNotice")
local sounds = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")
local money = player:WaitForChild("leaderstats"):WaitForChild("MONEY")
local inside, dismissed, open, pending = false, false, false, false
local version, lastHover = 0, 0
local tweens = {}
local function animate(object, goal, duration)
	if tweens[object] then tweens[object]:Cancel() end
	local tween = TweenService:Create(object, TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tweens[object] = tween
	tween:Play()
	return tween
end
local function sound(kind)
	if kind == "HoverSound" then
		if os.clock() - lastHover < 0.07 then return end
		lastHover = os.clock()
	end
	local source = sounds:FindFirstChild(Config.Menus[kind])
	if not source then return end
	local copy = source:Clone()
	copy.Looped, copy.Volume, copy.TimePosition = false, Config.Menus.SoundVolume, 0
	copy.Parent = SoundService
	copy:Play()
	Debris:AddItem(copy, 3)
end
local function dollars(value)
	return "$" .. tostring(math.floor(value)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
local function refresh()
	shop.Background.Balance.Text = '<font color="#FFE89D"><b>' .. dollars(money.Value) .. '</b></font>  <i>Choose your bomb</i>'
	local selected = player:GetAttribute("EquippedBombSkin") or "Bomb"
	for _, id in Catalog.Order do
		local row = shop.Background.Items[id]
		local owned = player:GetAttribute("OwnsBombSkin_" .. id) == true
		local equipped = selected == id
		row.Cooldown.Text = owned and "OWNED" or "COSMETIC"
		row.Action.Caption.Text = equipped and '<b>EQUIPPED</b>' or owned and '<b>EQUIP</b>' or '<b>BUY</b>\n' .. dollars(Catalog.Items[id].Price)
		row.BackgroundColor3 = equipped and Color3.fromRGB(157, 85, 92) or Color3.fromRGB(138, 75, 83)
		row.Action.BackgroundColor3 = equipped and Color3.fromRGB(133, 69, 77) or Color3.fromRGB(190, 109, 116)
		row.Action.Interactable = open and not pending and not equipped
	end
end
local function setOpen(value)
	if value == open then return end
	open = value
	if value then gui:SetAttribute("SkillShopOpen", false) end
	gui:SetAttribute("BombSkinShopOpen", value)
	shop.Visible = true
	if value then shop.PanelScale.Scale = 0.93 end
	sound(value and "PopupSound" or "CloseSound")
	shop.Background.CloseButton.Interactable = value
	animate(shop.PanelScale, { Scale = value and 1 or 0.96 })
	animate(shop, { GroupTransparency = value and 0 or 1 }).Completed:Once(function(status)
		if status == Enum.PlaybackState.Completed and not open then shop.Visible = false end
	end)
	refresh()
end
local function bind(button, action)
	local scale = button.InteractionScale
	local hovered = false
	button.MouseEnter:Connect(function()
		hovered = true
		if open and button.Interactable then animate(scale, { Scale = 1.015 }, 0.14) sound("HoverSound") end
	end)
	button.MouseLeave:Connect(function() hovered = false animate(scale, { Scale = 1 }, 0.14) end)
	button.InputBegan:Connect(function(input)
		if open and button.Interactable and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then animate(scale, { Scale = 0.985 }, 0.08) end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then animate(scale, { Scale = hovered and open and button.Interactable and 1.015 or 1 }, 0.14) end
	end)
	button.Activated:Connect(function()
		if not open or not button.Interactable then return end
		sound("ClickSound")
		action()
	end)
end
bind(shop.Background.CloseButton, function() dismissed = true setOpen(false) end)
for _, id in Catalog.Order do
	bind(shop.Background.Items[id].Action, function()
		if pending then return end
		local owned = player:GetAttribute("OwnsBombSkin_" .. id) == true
		if not owned then
			local reason = Catalog.PurchaseError(id, false, money.Value)
			if reason then notice:Fire(reason) return end
		end
		pending = true
		version += 1
		local current = version
		refresh()
		remote:FireServer(owned and "Equip" or "Buy", id)
		task.delay(5, function()
			if pending and current == version then pending = false refresh() notice:Fire("The shop did not respond. Please try again.") end
		end)
	end)
	player:GetAttributeChangedSignal("OwnsBombSkin_" .. id):Connect(refresh)
end
remote.OnClientEvent:Connect(function(_, message)
	pending = false
	refresh()
	if message then notice:Fire(message) end
end)
player:GetAttributeChangedSignal("EquippedBombSkin"):Connect(refresh)
money.Changed:Connect(refresh)
gui:GetAttributeChangedSignal("BombSkinShopOpen"):Connect(function()
	if open and not gui:GetAttribute("BombSkinShopOpen") then dismissed = true setOpen(false) end
end)
gui:GetAttributeChangedSignal("SkillShopOpen"):Connect(function()
	if gui:GetAttribute("SkillShopOpen") then dismissed = true setOpen(false) end
end)
refresh()
local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed < 0.08 then return end
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local previous = inside
	inside = humanoid and humanoid.Health > 0 and not player:GetAttribute("InRound") and SkillCatalog.InShop(hitbox, root) or false
	if not inside then dismissed = false setOpen(false)
	elseif not previous and not dismissed then setOpen(true) end
end)
RunService.RenderStepped:Connect(function(delta)
	if not open then return end
	for _, id in Catalog.Order do
		local model = shop.Background.Items[id].SkinPreview.WorldModel.PreviewBomb
		model.CFrame = CFrame.Angles(0, math.rad(18) * delta, 0) * model.CFrame
	end
end)
