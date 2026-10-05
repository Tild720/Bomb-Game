-- Final finish, after gradient-menu-ui: slate blue tones, rounded clipped patterns, visible outlines.
local Theme = {}
function Theme.Apply(gui)
if gui:GetAttribute("ToneThemeVersion") == 8 then return end
local function surface(object, color, radius, thickness)
	object.BackgroundColor3 = color
	local corner = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), object
	for _, child in object:GetChildren() do if child:IsA("UIStroke") then child:Destroy() end end
	if thickness ~= 0 then
	local stroke = Instance.new("UIStroke")
	stroke.Name, stroke.ApplyStrokeMode = "SurfaceOutline", Enum.ApplyStrokeMode.Border
	stroke.Color, stroke.Thickness, stroke.Transparency = Color3.fromRGB(210, 228, 244), thickness or 1.5, 0.18
	stroke.Parent = object
	end
	local gradient = object:FindFirstChild("SurfaceGradient") or Instance.new("UIGradient")
	gradient.Name, gradient.Rotation = "SurfaceGradient", 90
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(196, 214, 232))
	gradient.Parent = object
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then object.ImageTransparency = 0.91 end
end
local function pattern(parent, burst)
	local old = parent:FindFirstChild("PatternClip")
	if old then old:Destroy() end
	local clip = Instance.new("CanvasGroup")
	clip.Name, clip.BackgroundTransparency = "PatternClip", 1
	clip.Position, clip.Size = UDim2.fromOffset(2, 2), UDim2.new(1, -4, 1, -4)
	clip.ClipsDescendants, clip.Active, clip.ZIndex = true, false, parent.ZIndex
	clip.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 13), clip
	for index = -4, 30 do
		local stripe = Instance.new("Frame")
		stripe.Name = "Stripe"
		stripe.BorderSizePixel, stripe.BackgroundTransparency = 0, 0.955
		stripe.BackgroundColor3 = Color3.fromRGB(229, 240, 255)
		stripe.Size, stripe.Position = UDim2.fromOffset(13, 400), UDim2.new(0, index * 34, 0.5, 0)
		stripe.AnchorPoint, stripe.Rotation = Vector2.new(0.5, 0.5), 24
		stripe.ZIndex, stripe.Parent = clip.ZIndex, clip
	end
	if burst then
		local image = Instance.new("ImageLabel")
		-- Texture resolved from the user's Decal asset 76707185718665.
		image.Name, image.Image = "Sunburst", "rbxassetid://84880292033466"
		image.BackgroundTransparency, image.ImageTransparency = 1, 0.9
		image.ImageColor3 = Color3.fromRGB(225, 238, 255)
		image.AnchorPoint, image.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.77, 0.5)
		image.Size, image.ZIndex, image.Parent = UDim2.fromOffset(450, 450), clip.ZIndex, clip
	end
end
local function shop(background)
	surface(background, Color3.fromRGB(77, 101, 128), 22, 1.5)
	local header = background.HeaderBand
	surface(header, Color3.fromRGB(98, 131, 161), 22, 0)
	header.Position, header.Size = UDim2.new(), UDim2.new(1, 0, 0, background.Parent.Name == "SkillShop" and 98 or 74)
	header.ClipsDescendants = true
	pattern(header, true)
	local bridge = header:FindFirstChild("SquareJoin") or Instance.new("Frame")
	bridge.Name, bridge.BorderSizePixel = "SquareJoin", 0
	bridge.BackgroundColor3 = Color3.new(98 / 255 * 196 / 255, 131 / 255 * 214 / 255, 161 / 255 * 232 / 255)
	bridge.Position, bridge.Size = UDim2.new(0, 0, 1, -20), UDim2.new(1, 0, 0, 20)
	bridge.ZIndex, bridge.Parent = header.ZIndex, header
	surface(background.ListWell, Color3.fromRGB(77, 101, 128), 0, 0)
	background.ListWell.BackgroundTransparency = 1
	surface(background.CloseButton, Color3.fromRGB(113, 143, 170), 14, 1)
end
shop(gui.SkillShop.Background)
shop(gui.MenuPanels.Shop.Background)
local catalog = require(game.ReplicatedStorage.BombGame.SkillCatalog)
for _, id in catalog.Order do
	local row = gui.SkillShop.Background.Items[id]
	surface(row, id == "DoubleJump" and Color3.fromRGB(101, 132, 157) or Color3.fromRGB(92, 119, 147), 10, 0)
	surface(row.Action, id == "DoubleJump" and Color3.fromRGB(87, 119, 149) or Color3.fromRGB(121, 153, 180), 10, 1)
	pattern(row.Action, false)
end
local vip = gui.MenuPanels.Shop.Background.Items.BuyButton
surface(vip, Color3.fromRGB(92, 119, 147), 10, 0)
surface(vip.ActionBackground, Color3.fromRGB(121, 153, 180), 10, 1)
pattern(vip.ActionBackground, false)
for _, name in { "Guide", "Spectate" } do
	local background = gui.MenuPanels[name].Background
	local color = name == "Guide" and Color3.fromRGB(147, 146, 105) or Color3.fromRGB(113, 104, 147)
	surface(background, color, 22, 1.5)
	surface(background.CloseButton, color:Lerp(Color3.new(1, 1, 1), 0.15), 14, 1)
	background.SurfaceGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(210, 210, 210))
	background.CloseButton.SurfaceGradient.Color = background.SurfaceGradient.Color
end
for _, name in { "PreviousButton", "NextButton" } do surface(gui.MenuPanels.Spectate.Background[name], Color3.fromRGB(137, 127, 168), 12, 1) end
surface(gui.SkillHUD.UseButton, Color3.fromRGB(147, 146, 105), 14, 1)
for _, name in { "Guide", "Spectate" } do
	local button = gui[name .. "Button"]
	button.BackgroundColor3 = name == "Guide" and Color3.fromRGB(147, 146, 105) or Color3.fromRGB(113, 104, 147)
	if button:FindFirstChild("SurfaceGradient") then button.SurfaceGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(210, 210, 210)) end
end
for _, parent in { gui.ShopButton, vip } do
	local badge = parent:FindFirstChild("AttentionBadge")
	if badge then badge:Destroy() end
end
local descriptions = {
	DoubleJump = '<b>Jump again <font color="#C3EAFF">in midair.</font></b>\n<i>Land to recharge.</i>',
	Dash = '<b><font color="#C3EAFF">Dash forward.</font></b>\n<i>No invincibility.</i>',
	Push = '<b><font color="#FFE2B9">Push players away.</font></b>\n<i>No stun.</i>',
	Banana = '<font color="#FFE89D"><b>40% slower for 1.5s.</b></font>\n<i>Leave a peel in their path.</i>',
	Swap = '<b><font color="#DDD0FF">Swap</font></b> with a player.\n<i>Bomb keeps its owner.</i>',
}
for id, description in pairs(descriptions) do
	local row = gui.SkillShop.Background.Items[id]
	row.Size = UDim2.new(1, -14, 0, 146)
	row.Title.UITextSizeConstraint.MaxTextSize = 34
	row.Description.Text = description
	row.Description.UITextSizeConstraint.MaxTextSize = 27
	row.Description.Position, row.Description.Size = UDim2.fromScale(0.025, 0.38), UDim2.fromScale(0.69, 0.57)
	row.Action.Caption.UITextSizeConstraint.MaxTextSize = 29
	row.Cooldown.UITextSizeConstraint.MaxTextSize = 17
end
gui.SkillShop.Background.Title.UITextSizeConstraint.MaxTextSize = 40
gui.SkillShop.Background.Balance.UITextSizeConstraint.MaxTextSize = 28
gui.SkillShop.Background.Hint.UITextSizeConstraint.MaxTextSize = 21
vip.Description.UITextSizeConstraint.MaxTextSize = 29
vip.Caption.UITextSizeConstraint.MaxTextSize = 29
gui.MenuPanels.Shop.Background.Feedback.UITextSizeConstraint.MaxTextSize = 23
for _, object in gui.MenuPanels.Guide.Background:GetChildren() do
	if object:IsA("TextLabel") then
		local limit = object:FindFirstChildOfClass("UITextSizeConstraint")
		if limit then limit.MaxTextSize = object.Name == "Title" and 40 or 29 end
	end
end
gui.MenuPanels.Spectate.Background.TargetLabel.UITextSizeConstraint.MaxTextSize = 40
gui.MenuPanels.Spectate.Background.CounterLabel.UITextSizeConstraint.MaxTextSize = 25
gui.SkillHUD.Size = UDim2.fromOffset(220, 125)
gui.SkillHUD.UseButton.Title.UITextSizeConstraint.MaxTextSize = 24
gui.SkillHUD.UseButton.Status.UITextSizeConstraint.MaxTextSize = 24
-- Scale from the center so hover doesn't drift toward the lower right or cross panel edges.
for _, object in gui:GetDescendants() do
	if object:IsA("GuiButton") and object:FindFirstChild("InteractionScale") then
		local shift = Vector2.new(0.5, 0.5) - object.AnchorPoint
		local size = object.Size
		object.Position += UDim2.new(size.X.Scale * shift.X, size.X.Offset * shift.X, size.Y.Scale * shift.Y, size.Y.Offset * shift.Y)
		object.AnchorPoint = Vector2.new(0.5, 0.5)
	end
end
-- Fixed desktop text sizes avoid TextScaled silently shrinking despite a larger max size.
local function readable(label, size, container)
	label.TextScaled = false
	label.TextWrapped = true
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then limit.MaxTextSize = size end
	local function resize()
		label.TextSize = math.floor(size * math.clamp(container.AbsoluteSize.X / 740, 0.65, 1))
	end
	resize()
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
end
local skill = gui.SkillShop.Background
readable(skill.Title, 46, skill)
skill.Title.Size = UDim2.new(1, -100, 0, 50)
readable(skill.Balance, 32, skill)
skill.Balance.Position, skill.Balance.Size = UDim2.fromOffset(20, 59), UDim2.new(1, -100, 0, 34)
readable(skill.Hint, 23, skill)
for _, id in catalog.Order do
	local row = skill.Items[id]
	row.Title.Position, row.Title.Size = UDim2.fromScale(0.025, 0.03), UDim2.fromScale(0.69, 0.33)
	readable(row.Title, 40, skill)
	readable(row.Description, 32, skill)
	readable(row.Action.Caption, 34, skill)
	readable(row.Cooldown, 21, skill)
end
readable(vip.Description, 32, gui.MenuPanels.Shop.Background)
vip.Description.Position, vip.Description.Size = UDim2.fromScale(0.24, 0.055), UDim2.fromScale(0.71, 0.5)
readable(vip.Caption, 34, gui.MenuPanels.Shop.Background)
readable(gui.MenuPanels.Shop.Background.Title, 48, gui.MenuPanels.Shop.Background)
readable(gui.MenuPanels.Shop.Background.Feedback, 26, gui.MenuPanels.Shop.Background)
gui.MenuPanels.Shop.Background.Feedback.Position = UDim2.new(0, 15, 1, -35)
gui.MenuPanels.Shop.Background.Feedback.Size = UDim2.new(1, -30, 0, 30)
local guide = gui.MenuPanels.Guide.Background
guide.Subtitle.Text = '<i>Pass it. Survive. <font color="#FFE89D"><b>Win.</b></font></i>'
guide.Step1.Text = '<font color="#FFE89D"><b>01</b></font> <b>JOIN A ROUND</b>\nThe game starts with <b>2 players.</b>'
guide.Step2.Text = '<font color="#FFE89D"><b>02</b></font> <b>PASS IT ON</b>\nGet close to pass. <i>No button needed.</i>'
guide.Step3.Text = '<font color="#FFE89D"><b>03</b></font> <b>WATCH THE TIMER</b>\nAt <font color="#FFAC99"><b>zero</b></font>, the holder is out.'
guide.Step4.Text = '<font color="#FFE89D"><b>04</b></font> <b>SURVIVE &amp; EARN</b>\nPass <b>$25</b>   1st <b>$400</b>   2nd <b>$250</b>   3rd <b>$100</b>'
for _, name in { "Guide", "Spectate" } do
	local background = gui.MenuPanels[name].Background
	for _, label in background:GetChildren() do
		if label:IsA("TextLabel") then readable(label, label.Name == "Title" and 44 or (label.Name == "TargetLabel" and 44 or 32), background) end
	end
end
-- One outline per window; internal regions and buttons are separated by surface tone.
local windows = { gui.SkillShop.Background, gui.MenuPanels.Shop.Background, gui.MenuPanels.Guide.Background, gui.MenuPanels.Spectate.Background }
for _, background in windows do
	for _, child in background:GetDescendants() do
		if child:IsA("UIStroke") and child.Parent ~= background then child:Destroy() end
		if child.ClassName == "UIShadow" and child.Parent ~= background then child:Destroy() end
	end
end
-- VIP has one content surface, not a card nested inside another framed well.
vip.BackgroundTransparency = 1
vip.ImageTransparency = 1
gui.MenuPanels.Shop.Background.ListWell.Visible = false
gui.SkillShop.Background.ListWell.Visible = false
for _, id in catalog.Order do
	local row = gui.SkillShop.Background.Items[id]
	local image = row:FindFirstChild("SkillImage") or Instance.new("ImageLabel")
	image.Name, image.Image = "SkillImage", catalog.Items[id].Image or ""
	image.AnchorPoint, image.Position = Vector2.new(0, 0.5), UDim2.fromScale(0.025, 0.5)
	image.Size = UDim2.fromScale(0.125, 0.72)
	image.BackgroundColor3, image.BackgroundTransparency = Color3.fromRGB(70, 96, 121), 1
	image.BorderSizePixel, image.ZIndex, image.Parent = 0, row.ZIndex + 1, row
	local ratio = image:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio, ratio.DominantAxis, ratio.Parent = 1, Enum.DominantAxis.Width, image
	local corner = image:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 10), image
	row.Title.Position, row.Title.Size = UDim2.fromScale(0.175, 0.03), UDim2.fromScale(0.54, 0.33)
	row.Description.Position, row.Description.Size = UDim2.fromScale(0.175, 0.38), UDim2.fromScale(0.54, 0.57)
	-- One compact text column next to the image; avoid vertically centered labels in oversized boxes.
	row.Title.TextXAlignment, row.Title.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	row.Description.TextXAlignment, row.Description.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	local function layoutRow()
		local scale = math.clamp(skill.AbsoluteSize.X / 740, 0.65, 1)
		local inset, icon, gap, actionWidth = 12 * scale, 76 * scale, 12 * scale, 174 * scale
		local textX = inset + icon + gap
		row.Size = UDim2.new(1, -14, 0, 132 * scale)
		image.Position, image.Size = UDim2.new(0, inset, 0.5, 0), UDim2.fromOffset(icon, icon)
		row.Title.Position, row.Title.Size = UDim2.fromOffset(textX, 6 * scale), UDim2.new(1, -(textX + actionWidth + inset + gap), 0, 44 * scale)
		row.Description.Position, row.Description.Size = UDim2.fromOffset(textX, 50 * scale), UDim2.new(1, -(textX + actionWidth + inset + gap), 0, 76 * scale)
		row.Action.AnchorPoint = Vector2.new(1, 0.5)
		row.Action.Position, row.Action.Size = UDim2.new(1, -inset, 0.61, 0), UDim2.fromOffset(actionWidth, 68 * scale)
		row.Cooldown.Position, row.Cooldown.Size = UDim2.new(1, -(inset + actionWidth), 0, 15 * scale), UDim2.fromOffset(actionWidth, 25 * scale)
		row.Cooldown.TextXAlignment = Enum.TextXAlignment.Center
		row.Cooldown.Text = tostring(catalog.Items[id].Cooldown) .. "s COOLDOWN"
	end
	layoutRow()
	skill:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutRow)
end
gui:SetAttribute("ToneThemeVersion", 8)
end
return Theme
