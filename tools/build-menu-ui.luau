-- MCP 편집 모드에서 실행하는 UI 제작 도구. 게임 실행 코드는 src에서 Rojo로 동기화합니다.
local gui = game.StarterGui:WaitForChild("SubGui")
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local font = gui.ShopButton.StatusLabel.FontFace

local function decorate(target, source)
	target.BackgroundColor3 = source.BackgroundColor3
	target.BackgroundTransparency = source.BackgroundTransparency
	target.Image = source.Image
	target.ImageColor3 = source.ImageColor3
	target.ImageTransparency = source.ImageTransparency
	target.ScaleType = Enum.ScaleType.Tile
	target.TileSize = UDim2.fromOffset(112, 112)
	for _, child in ipairs(source:GetChildren()) do
		if child:IsA("UICorner") or child:IsA("UIStroke") or child.ClassName == "UIShadow" then
			child:Clone().Parent = target
		end
	end
end

local function text(parent, name, value, position, size, maxSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = font
	label.RichText = true
	label.Text = value
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.75
	label.TextScaled = true
	label.TextWrapped = true
	label.Position, label.Size = position, size
	label.ZIndex = 12
	label.Parent = parent
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxSize or 24
	constraint.MinTextSize = 10
	constraint.Parent = label
	return label
end

local function button(parent, name, caption, position, size, source)
	local result = Instance.new("ImageButton")
	result.Name = name
	decorate(result, source)
	result.AutoButtonColor = false
	result.Position, result.Size = position, size
	result.ZIndex = 13
	result.Parent = parent
	text(result, "Caption", caption, UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84), 24)
	local scale = Instance.new("UIScale")
	scale.Name = "InteractionScale"
	scale.Parent = result
	return result
end

local function attention(parent)
	local badge = text(parent, "AttentionBadge", "<b>!</b>", UDim2.new(1, -2, 0, 2), UDim2.fromOffset(24, 24), 22)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.BackgroundTransparency = 0
	badge.BackgroundColor3 = Color3.fromRGB(244, 108, 82)
	badge.TextStrokeTransparency = 1
	badge.ZIndex = 25
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = badge
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1.5
	stroke.Parent = badge
	local scale = Instance.new("UIScale")
	scale.Name = "AttentionScale"
	scale.Parent = badge
	return badge
end

local panels = gui:FindFirstChild("MenuPanels") or Instance.new("Folder")
panels.Name = "MenuPanels"
panels.Parent = gui
assert(#panels:GetChildren() == 0, "MenuPanels already contains UI; edit existing instances instead of rebuilding")

local function panel(name, source, title, subtitle, compact)
	local group = Instance.new("CanvasGroup")
	group.Name = name
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, compact and 0.77 or 0.43)
	group.Size = UDim2.fromScale(0.9, compact and 0.25 or 0.67)
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	group.Visible = false
	group.ZIndex = 10
	group.Parent = panels
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(680, compact and 200 or 500)
	bounds.Parent = group
	local scale = Instance.new("UIScale")
	scale.Name = "PanelScale"
	scale.Parent = group
	local background = Instance.new("ImageLabel")
	background.Name = "Background"
	decorate(background, source)
	background.Position = UDim2.fromOffset(24, 24)
	background.Size = UDim2.new(1, -48, 1, -48)
	background.ZIndex = 10
	background.Parent = group
	text(background, "Title", '<b>' .. title .. '</b>', UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.74, compact and 0.2 or 0.13), compact and 24 or 34).TextXAlignment = Enum.TextXAlignment.Left
	if not compact then
		text(background, "Subtitle", subtitle, UDim2.fromScale(0.05, 0.19), UDim2.fromScale(0.9, 0.08), 18).TextXAlignment = Enum.TextXAlignment.Left
	end
	local close = button(background, "CloseButton", "×", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(36, 36), source)
	close.AnchorPoint = Vector2.zero
	return background
end

local shop = panel("Shop", gui.ShopButton, "SHOP", "A LITTLE EXTRA STYLE FOR YOUR NEXT ROUND")
shop.Subtitle:Destroy()
local items = Instance.new("ScrollingFrame")
items.Name = "Items"
items.BackgroundTransparency = 1
items.BorderSizePixel = 0
items.Position, items.Size = UDim2.fromScale(0.04, 0.22), UDim2.fromScale(0.92, 0.64)
items.CanvasSize = UDim2.new()
items.AutomaticCanvasSize = Enum.AutomaticSize.Y
items.ScrollBarThickness = 4
items.ScrollBarImageColor3 = Color3.fromRGB(211, 243, 246)
items.ZIndex = 11
items.Parent = shop
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 16)
layout.Parent = items
local padding = Instance.new("UIPadding")
padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 20), UDim.new(0, 20)
padding.Parent = items
local item = button(items, "BuyButton", "TRY VIP FREE", UDim2.new(), UDim2.new(0.86, 0, 0, 140), gui.GuideButton)
item.LayoutOrder = 1
item.Caption.Position, item.Caption.Size = UDim2.fromScale(0.3, 0.65), UDim2.fromScale(0.65, 0.22)
item.Caption.TextXAlignment = Enum.TextXAlignment.Left
text(item, "Badge", '<font color="#FFE89D"><b>VIP</b></font>', UDim2.fromScale(0.04, 0.22), UDim2.fromScale(0.23, 0.4), 40)
text(item, "Description", '<b>GOLDEN CHAT TAG</b>\nStand out with [VIP] beside your name.', UDim2.fromScale(0.3, 0.12), UDim2.fromScale(0.64, 0.43), 21).TextXAlignment = Enum.TextXAlignment.Left
attention(item)
attention(gui.ShopButton)
text(shop, "Feedback", "", UDim2.fromScale(0.05, 0.89), UDim2.fromScale(0.9, 0.07), 15)

local guide = panel("Guide", gui.GuideButton, "HOW TO PLAY", "PASS THE BOMB. BE THE LAST ONE STANDING.")
local lines = {
	'<font color="#FFE89D"><b>01</b></font>  JOIN THE ROUND\nWait in the lobby. The round starts with 2 players.',
	'<font color="#FFE89D"><b>02</b></font>  PASS IT ON\nGet close to another survivor to pass the bomb. No button needed!',
	'<font color="#FFE89D"><b>03</b></font>  WATCH THE TIMER\nPassing does not reset the timer. Holding it at zero means elimination.',
	'<font color="#FFE89D"><b>04</b></font>  SURVIVE &amp; EARN\nPass: +$25   1st: $400   2nd: $250   3rd: $100',
}
for index, value in ipairs(lines) do
	text(guide, "Step" .. index, value, UDim2.fromScale(0.07, 0.31 + (index - 1) * 0.155), UDim2.fromScale(0.86, 0.135), 22).TextXAlignment = Enum.TextXAlignment.Left
end

local spectate = panel("Spectate", gui.SpectateButton, "SPECTATING", "", true)
button(spectate, "PreviousButton", "‹", UDim2.fromScale(0.04, 0.39), UDim2.fromScale(0.13, 0.45), gui.SpectateButton)
button(spectate, "NextButton", "›", UDim2.fromScale(0.83, 0.39), UDim2.fromScale(0.13, 0.45), gui.SpectateButton)
text(spectate, "TargetLabel", "NO ACTIVE PLAYERS", UDim2.fromScale(0.2, 0.36), UDim2.fromScale(0.6, 0.36), 27)
text(spectate, "CounterLabel", "WAITING FOR THE NEXT ROUND", UDim2.fromScale(0.2, 0.74), UDim2.fromScale(0.6, 0.18), 15)

for _, name in ipairs({ "Shop", "Guide", "Spectate" }) do
	local viewport = gui[name .. "Viewport"]
	local scale = viewport:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Name = "InteractionScale"
	scale.Parent = viewport
	gui[name .. "Button"].AutoButtonColor = false
end
return "Created Shop, Guide and Spectate panels using existing textures, Comic font, UIStroke and UIShadow."
