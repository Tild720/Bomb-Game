-- Apply to existing UI in Edit mode; does not recreate authored buttons or viewports.
local gui = game.StarterGui.SubGui
local function label(parent, name, value, position, size, maxSize)
	local object = parent[name]
	if value then object.Text = value end
	object.Position, object.Size = position, size
	object.RichText = true
	local limit = object:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then limit.MaxTextSize = maxSize end
	return object
end
local function closeButton(background)
	local button = background.CloseButton
	button.Size, button.Position = UDim2.fromOffset(54, 54), UDim2.new(1, -64, 0, 10)
	button.BackgroundColor3 = Color3.fromRGB(171, 87, 79)
	button.ImageTransparency = 0.86
	local caption = label(button, "Caption", "<b>X</b>", UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.9), 38)
	caption.TextXAlignment = Enum.TextXAlignment.Center
	caption.TextStrokeTransparency = 0.9
end
for _, group in gui.MenuPanels:GetChildren() do
	closeButton(group.Background)
	group.Background.Position, group.Background.Size = UDim2.fromOffset(16, 16), UDim2.new(1, -32, 1, -32)
end
local shop = gui.MenuPanels.Shop
shop.Size = UDim2.fromScale(0.94, 0.53)
shop.UISizeConstraint.MaxSize = Vector2.new(740, 380)
local background = shop.Background
label(background, "Title", '<b>SHOP</b>', UDim2.fromScale(0.035, 0.025), UDim2.new(1, -110, 0.17, 0), 40)
background.Items.Position, background.Items.Size = UDim2.fromScale(0.02, 0.22), UDim2.fromScale(0.96, 0.64)
background.Items.UIPadding.PaddingTop, background.Items.UIPadding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
local vip = background.Items.BuyButton
vip.Size = UDim2.new(0.96, 0, 0, 172)
label(vip, "Badge", '<font color="#FFE89D"><b>VIP</b></font>', UDim2.fromScale(0.025, 0.16), UDim2.fromScale(0.23, 0.56), 48)
label(vip, "Description", '<b>A <font color="#FFE89D">golden VIP tag.</font></b>\n<i>Beside your name in chat.</i>', UDim2.fromScale(0.29, 0.08), UDim2.fromScale(0.68, 0.49), 26)
label(vip, "Caption", '<font color="#FFE89D"><b>TRY VIP FREE</b></font>', UDim2.fromScale(0.29, 0.65), UDim2.fromScale(0.67, 0.23), 28)
label(background, "Feedback", '<i>Free Studio sample.</i> <b>No Robux charged.</b>', UDim2.fromScale(0.035, 0.9), UDim2.fromScale(0.93, 0.065), 20)
local guide = gui.MenuPanels.Guide
guide.Size = UDim2.fromScale(0.94, 0.76)
guide.UISizeConstraint.MaxSize = Vector2.new(760, 550)
background = guide.Background
label(background, "Title", '<b>HOW TO <font color="#FFE89D">SURVIVE</font></b>', UDim2.fromScale(0.035, 0.025), UDim2.new(1, -105, 0.115, 0), 36)
label(background, "Subtitle", '<i>Keep moving. Don’t be the one holding the bomb.</i>', UDim2.fromScale(0.035, 0.155), UDim2.fromScale(0.93, 0.07), 23)
local steps = {
	'<font color="#FFE89D"><b>01</b></font>  <b>JOIN A ROUND</b>\nThe game starts with <font color="#FFE89D">2 players</font>.',
	'<font color="#FFE89D"><b>02</b></font>  <b>GET CLOSE. PASS IT.</b>\nTouch another survivor to pass the bomb. <i>No button needed.</i>',
	'<font color="#FFE89D"><b>03</b></font>  <b>WATCH THE TIMER</b>\nAt <font color="#FFAC99"><b>zero</b></font>, the holder is out. Passing <i>doesn’t reset it</i>.',
	'<font color="#FFE89D"><b>04</b></font>  <b>SURVIVE &amp; EARN</b>\nPass <font color="#FFE89D">+$25</font>   1st <b>$400</b>   2nd <b>$250</b>   3rd <b>$100</b>',
}
for i, value in steps do
	label(background, "Step" .. i, value, UDim2.fromScale(0.035, 0.25 + (i - 1) * 0.18), UDim2.fromScale(0.93, 0.16), 26)
end
local spectate = gui.MenuPanels.Spectate
spectate.UISizeConstraint.MaxSize = Vector2.new(760, 235)
spectate.Size = UDim2.fromScale(0.94, 0.3)
background = spectate.Background
label(background, "Title", '<b>SPECTATING</b>', UDim2.fromScale(0.035, 0.04), UDim2.new(1, -105, 0.24, 0), 30)
label(background, "TargetLabel", nil, UDim2.fromScale(0.19, 0.4), UDim2.fromScale(0.62, 0.35), 34)
label(background, "CounterLabel", nil, UDim2.fromScale(0.2, 0.79), UDim2.fromScale(0.6, 0.16), 22)
for _, name in { "PreviousButton", "NextButton" } do
	local button = background[name]
	button.Position = UDim2.fromScale(name == "PreviousButton" and 0.025 or 0.85, 0.41)
	button.Size = UDim2.fromScale(0.125, 0.47)
	button.Caption.UITextSizeConstraint.MaxTextSize = 42
end
local skill = gui.SkillShop
game.StarterGui.HotPotatoGui.DisplayOrder = math.max(game.StarterGui.HotPotatoGui.DisplayOrder, gui.DisplayOrder + 1)
skill.Size = UDim2.fromScale(0.96, 0.86)
skill.UISizeConstraint.MaxSize = Vector2.new(820, 690)
background = skill.Background
background.Position, background.Size = UDim2.fromOffset(16, 16), UDim2.new(1, -32, 1, -32)
closeButton(background)
label(background, "Title", '<b>SKILLS</b> <font color="#FFE89D"><i>Your loadout</i></font>', UDim2.fromScale(0.03, 0.025), UDim2.new(1, -105, 0.075, 0), 36)
label(background, "Balance", '<font color="#FFE89D"><b>$0</b></font>  <i>Choose one skill</i>', UDim2.fromScale(0.03, 0.115), UDim2.fromScale(0.94, 0.05), 24)
background.Items.Position, background.Items.Size = UDim2.fromScale(0.015, 0.18), UDim2.fromScale(0.97, 0.75)
background.Items.UIListLayout.Padding = UDim.new(0, 10)
background.Items.UIPadding.PaddingTop, background.Items.UIPadding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
local descriptions = {
	DoubleJump = 'One extra jump <font color="#AEEAFF"><b>in midair.</b></font>\n<i>Land to recharge.</i>',
	Dash = '<font color="#AEEAFF"><b>Burst forward</b></font> to catch up or escape.\n<i>No invincibility.</i>',
	Push = '<font color="#FFD39A"><b>Push back</b></font> the player ahead.\n<i>Short knockback. No stun.</i>',
	Banana = 'Leave a peel. They move <font color="#FFE89D"><b>40% slower</b></font>\nfor <b>1.5 seconds.</b> <i>Watch your step.</i>',
	Smoke = 'Cover your tracks with <b>3 seconds</b> of smoke.\n<i>The <font color="#FFAC99">bomb timer</font> stays visible.</i>',
	Swap = '<font color="#D7B8FF"><b>Trade places</b></font> with the player ahead.\n<i>A short warning. The bomb stays with its owner.</i>',
}
for id, description in pairs(descriptions) do
	local row = background.Items[id]
	row.Size = UDim2.new(0.96, 0, 0, 132)
	label(row, "Title", nil, UDim2.fromScale(0.025, 0.075), UDim2.fromScale(0.68, 0.24), 29)
	label(row, "Description", description, UDim2.fromScale(0.025, 0.37), UDim2.fromScale(0.71, 0.53), 22)
	label(row, "Action", nil, UDim2.fromScale(0.765, 0.34), UDim2.fromScale(0.215, 0.5), 27)
	label(row, "Cooldown", nil, UDim2.fromScale(0.755, 0.075), UDim2.fromScale(0.225, 0.19), 16)
end
label(background, "Hint", '<i>Buy once.</i> <b>Equip here.</b> Step out to close.', UDim2.fromScale(0.03, 0.95), UDim2.fromScale(0.94, 0.035), 18)
for _, object in game.StarterGui:GetDescendants() do
	if object:IsA("TextLabel") or object:IsA("TextButton") then object.Text = object.Text:gsub("·", ""):gsub("•", "") end
end
return "Updated menu typography, density, rich text and 54px close buttons. Removed middle-dot text."
