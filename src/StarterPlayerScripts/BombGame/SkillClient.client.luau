local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local Catalog = require(shared:WaitForChild("SkillCatalog"))
local LocalMotion = require(script.Parent:WaitForChild("LocalSkillMotion"))
local motionPending = false
local motionReadyAt = 0
local remote = shared:WaitForChild("SkillRequest")
local state = shared:WaitForChild("State")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SubGui")
require(shared:WaitForChild("MenuTheme")).Apply(gui)
local shop = gui:WaitForChild("SkillShop")
local removedRow = shop.Background.Items:FindFirstChild("Smoke")
if removedRow then removedRow:Destroy() end
local hud = gui:WaitForChild("SkillHUD")
local equippedImage = player.PlayerGui:WaitForChild("HotPotatoGui"):WaitForChild("SkillImage")
local notice = gui:WaitForChild("MenuNotice")
local hitbox = workspace:WaitForChild("System"):WaitForChild("ShopHitbox")
local sounds = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")
local money = player:WaitForChild("leaderstats"):WaitForChild("MONEY")
local tweens = {}
local inside, dismissed, open, hudShown = false, false, false, false
local requestPending, requestVersion, lastUse, lastHover = false, 0, 0, 0
local jumpHeld, jumped, lastGrounded = false, false, os.clock()

local function animate(object, goal, duration)
	if tweens[object] then tweens[object]:Cancel() end
	local t = TweenService:Create(object, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tweens[object] = t
	t:Play()
	return t
end
local function sound(kind)
	if kind == "HoverSound" then
		if os.clock() - lastHover < 0.07 then return end
		lastHover = os.clock()
	end
	local template = sounds:FindFirstChild(Config.Menus[kind])
	if not template then return end
	local copy = template:Clone()
	copy.Looped, copy.Volume, copy.TimePosition = false, Config.Menus.SoundVolume, 0
	copy.Parent = SoundService
	copy:Play()
	Debris:AddItem(copy, 3)
end
local function dollars(value)
	local formatted = tostring(math.floor(value)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. formatted
end
local function selected()
	local id = player:GetAttribute("EquippedSkill") or "DoubleJump"
	return Catalog.Items[id] and id or "DoubleJump"
end
local function refresh()
	shop.Background.Balance.Text = '<font color="#FFE89D"><b>' .. dollars(money.Value) .. '</b></font>  <i>Choose one skill</i>'
	for _, id in Catalog.Order do
		local row = shop.Background.Items[id]
		row.SkillImage.Image = Catalog.Items[id].Image
		row.Cooldown.Text = tostring(Catalog.Items[id].Cooldown) .. "s COOLDOWN"
		local owned = player:GetAttribute("OwnsSkill_" .. id) == true
		local equipped = selected() == id
		row.Action.Caption.Text = equipped and '<b>EQUIPPED</b>'
			or owned and '<b>EQUIP</b>' or '<b>BUY</b>\n' .. dollars(Catalog.Items[id].Price)
		row.BackgroundColor3 = equipped and Color3.fromRGB(101, 132, 157) or Color3.fromRGB(92, 119, 147)
		row.Action.BackgroundColor3 = equipped and Color3.fromRGB(87, 119, 149)
			or owned and Color3.fromRGB(135, 167, 193) or Color3.fromRGB(121, 153, 180)
		row.Action.Interactable = open and not requestPending and not equipped
	end
	hud.UseButton.Title.Text = '<b>' .. Catalog.Items[selected()].Name .. '</b>'
	equippedImage.Image = Catalog.Items[selected()].Image
end
local function setOpen(value)
	if value == open then return end
	open = value
	gui:SetAttribute("SkillShopOpen", value)
	shop.Visible = true
	if value then
		shop.PanelScale.Scale = 0.93
		sound("PopupSound")
	else
		sound("CloseSound")
	end
	shop.Background.CloseButton.Interactable = value
	animate(shop.PanelScale, { Scale = value and 1 or 0.96 })
	local fade = animate(shop, { GroupTransparency = value and 0 or 1 })
	fade.Completed:Once(function(status)
		if status == Enum.PlaybackState.Completed and not open then shop.Visible = false end
	end)
	refresh()
end
gui:GetAttributeChangedSignal("SkillShopOpen"):Connect(function()
	if open and not gui:GetAttribute("SkillShopOpen") then dismissed = true setOpen(false) end
end)
local function bind(button, action)
	local scale = button.InteractionScale
	local hovered = false
	button.MouseEnter:Connect(function()
		hovered = true
		if button.Interactable then animate(scale, { Scale = 1.015 }, 0.14) sound("HoverSound") end
	end)
	button.MouseLeave:Connect(function() hovered = false animate(scale, { Scale = 1 }, 0.14) end)
	button.InputBegan:Connect(function(input)
		if button.Interactable and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			animate(scale, { Scale = 0.985 }, 0.08)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then animate(scale, { Scale = hovered and button.Interactable and 1.015 or 1 }, 0.14) end
	end)
	button.Activated:Connect(function()
		if not button.Interactable then return end
		sound("ClickSound")
		action()
	end)
end
bind(shop.Background.CloseButton, function() dismissed = true setOpen(false) end)
for _, id in Catalog.Order do
	bind(shop.Background.Items[id].Action, function()
		if not open or requestPending then return end
		local owned = player:GetAttribute("OwnsSkill_" .. id) == true
		if not owned then
			local reason = Catalog.PurchaseError(id, false, money.Value)
			if reason then notice:Fire(reason) return end
		end
		requestPending = true
		requestVersion += 1
		local version = requestVersion
		refresh()
		remote:FireServer(owned and "Equip" or "Buy", id)
		task.delay(5, function()
			if requestPending and requestVersion == version then
				requestPending = false
				refresh()
				notice:Fire("The shop did not respond. Please try again.")
			end
		end)
	end)
end
local function use()
	if not hudShown or UserInputService:GetFocusedTextBox() then return end
	if os.clock() - lastUse < 0.25 then return end
	lastUse = os.clock()
	if motionPending or math.max(motionReadyAt, player:GetAttribute("SkillReadyAt") or 0) > workspace:GetServerTimeNow() then
		notice:Fire("Your skill is still cooling down.")
		return
	end
	local id = selected()
	if id == "Dash" or id == "DoubleJump" then
		if id == "DoubleJump" and jumped then notice:Fire("Land to recharge your double jump.") return end
		if not LocalMotion.Start(id) then notice:Fire(id == "Dash" and "There is no room to dash here." or "Jump into the air first.") return end
		motionPending = true
		motionReadyAt = workspace:GetServerTimeNow() + Catalog.Items[id].Cooldown
		local pendingDeadline = motionReadyAt
		task.delay(2, function()
			if motionPending and motionReadyAt == pendingDeadline then
				motionPending = false
				LocalMotion.Confirm()
				LocalMotion.Cancel()
				notice:Fire("Skill confirmation timed out. Please try again shortly.")
			end
		end)
		if id == "DoubleJump" then jumped = true end
	end
	remote:FireServer("Use")
end
bind(hud.UseButton, use)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape and open then dismissed = true setOpen(false) end
	if (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonX) and selected() ~= "DoubleJump" then use() end
end)
UserInputService.JumpRequest:Connect(function()
	if jumpHeld then return end
	jumpHeld = true
	if selected() ~= "DoubleJump" or not hudShown or jumped then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.FloorMaterial == Enum.Material.Air and os.clock() - lastGrounded > 0.15 then use() end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA or input.UserInputType == Enum.UserInputType.Touch then jumpHeld = false end
end)
remote.OnClientEvent:Connect(function(kind, successOrId, message)
	if kind == "Result" then
		if motionPending and not successOrId then
			LocalMotion.Cancel()
			motionPending, motionReadyAt, jumped = false, 0, false
		end
		requestPending = false
		refresh()
		if message then notice:Fire(message) end
	elseif kind == "Notice" then notice:Fire(successOrId)
	elseif kind == "Used" then
		if successOrId == "Dash" or successOrId == "DoubleJump" then motionPending = false LocalMotion.Confirm() end
		if successOrId == "DoubleJump" then jumped = true end
		animate(hud.PanelScale, { Scale = 1.02 }, 0.08).Completed:Once(function(status)
			if status == Enum.PlaybackState.Completed then animate(hud.PanelScale, { Scale = 1 }) end
		end)
	end
end)
money.Changed:Connect(refresh)
player:GetAttributeChangedSignal("EquippedSkill"):Connect(refresh)
for _, id in Catalog.Order do player:GetAttributeChangedSignal("OwnsSkill_" .. id):Connect(refresh) end
player.CharacterAdded:Connect(function() jumped, jumpHeld, motionPending = false, false, false end)
refresh()
local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed < 0.08 then return end
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local living = humanoid and humanoid.Health > 0
	local wasInside = inside
	inside = living and not player:GetAttribute("InRound") and Catalog.InShop(hitbox, root) or false
	if not inside then dismissed = false setOpen(false)
	elseif not wasInside and not dismissed then setOpen(true) end
	local playing = living and player:GetAttribute("InRound") == true and state:GetAttribute("Phase") == "Playing" or false
	if playing ~= hudShown then
		hudShown = playing
		hud.Visible = true
		hud.UseButton.Interactable = playing
		animate(hud, { GroupTransparency = playing and 0 or 1 }).Completed:Once(function(status)
			if status == Enum.PlaybackState.Completed and not hudShown then hud.Visible = false end
		end)
	end
	if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then jumped = false lastGrounded = os.clock() end
	local remaining = math.max(0, math.max(motionReadyAt, player:GetAttribute("SkillReadyAt") or 0) - workspace:GetServerTimeNow())
	local status = remaining > 0 and string.format('<font color="#FFE89D"><b>%.1fs</b></font>', remaining)
		or (selected() == "DoubleJump" and (jumped and "LAND TO RECHARGE" or "JUMP AGAIN"))
		or (UserInputService.TouchEnabled and "TAP TO USE" or "[Q] USE SKILL")
	hud.UseButton.Status.Text = status
end)
