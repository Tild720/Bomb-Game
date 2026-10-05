-- Run in Bomb Studio Edit mode. Runtime code lives in src and is synced by Rojo.
local gui = game.StarterGui.SubGui
assert(not gui:FindFirstChild("SkillShop"), "SkillShop already exists; preserve manual edits")
local Catalog = require(game.ReplicatedStorage.BombGame.SkillCatalog)
local source = gui.ShopButton
local font = source.StatusLabel.FontFace
local function text(parent, name, value, position, size, maxSize)
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, value
	label.BackgroundTransparency = 1
	label.FontFace = font
	label.RichText, label.TextScaled, label.TextWrapped = true, true, true
	label.TextColor3, label.TextStrokeTransparency = Color3.new(1, 1, 1), 0.75
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position, label.Size, label.ZIndex = position, size, 22
	label.Parent = parent
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize = 10, maxSize
	limit.Parent = label
	return label
end
local function decorate(object)
	object.Image, object.ImageColor3, object.ImageTransparency = source.Image, source.ImageColor3, source.ImageTransparency
	object.BackgroundColor3 = source.BackgroundColor3
	object.ScaleType, object.TileSize = Enum.ScaleType.Tile, UDim2.fromOffset(112, 112)
	for _, child in source:GetChildren() do
		if child:IsA("UICorner") or child:IsA("UIStroke") or child.ClassName == "UIShadow" then child:Clone().Parent = object end
	end
end
local function button(parent, name, position, size)
	local b = Instance.new("ImageButton")
	b.Name, b.Position, b.Size = name, position, size
	b.AutoButtonColor, b.ZIndex = false, 22
	decorate(b)
	b.Parent = parent
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "InteractionScale", b
	return b
end
local shop = Instance.new("CanvasGroup")
shop.Name, shop.AnchorPoint = "SkillShop", Vector2.new(0.5, 0.5)
shop.Position, shop.Size = UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.94, 0.8)
shop.BackgroundTransparency, shop.GroupTransparency, shop.Visible, shop.ZIndex = 1, 1, false, 20
shop.Parent = gui
local bounds = Instance.new("UISizeConstraint")
bounds.MaxSize, bounds.Parent = Vector2.new(760, 640), shop
local scale = Instance.new("UIScale")
scale.Name, scale.Parent = "PanelScale", shop
local background = Instance.new("ImageLabel")
background.Name = "Background"
background.Position, background.Size = UDim2.fromOffset(20, 20), UDim2.new(1, -40, 1, -40)
background.ZIndex = 20
decorate(background)
background.Parent = shop
text(background, "Title", '<b>SKILLS</b> <font color="#FFE89D">&amp; INVENTORY</font>', UDim2.fromScale(0.05, 0.035), UDim2.fromScale(0.76, 0.08), 30)
text(background, "Balance", '$0  Choose one skill', UDim2.fromScale(0.05, 0.13), UDim2.fromScale(0.9, 0.055), 18)
local close = button(background, "CloseButton", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(36, 36))
text(close, "Caption", "×", UDim2.fromScale(0.1, 0.05), UDim2.fromScale(0.8, 0.85), 28).TextXAlignment = Enum.TextXAlignment.Center
local items = Instance.new("ScrollingFrame")
items.Name, items.BackgroundTransparency, items.BorderSizePixel = "Items", 1, 0
items.Position, items.Size = UDim2.fromScale(0.035, 0.21), UDim2.fromScale(0.93, 0.7)
items.CanvasSize, items.AutomaticCanvasSize = UDim2.new(), Enum.AutomaticSize.Y
items.ScrollBarThickness, items.ZIndex = 5, 21
items.ScrollBarImageColor3 = Color3.fromRGB(211, 243, 246)
items.Parent = background
local layout = Instance.new("UIListLayout")
layout.Padding, layout.HorizontalAlignment = UDim.new(0, 14), Enum.HorizontalAlignment.Center
layout.SortOrder, layout.Parent = Enum.SortOrder.LayoutOrder, items
local padding = Instance.new("UIPadding")
padding.PaddingTop, padding.PaddingBottom, padding.Parent = UDim.new(0, 12), UDim.new(0, 12), items
for index, id in Catalog.Order do
	local item = Catalog.Items[id]
	local row = button(items, id, UDim2.new(), UDim2.new(0.94, 0, 0, 126))
	row.LayoutOrder = index
	text(row, "Title", "<b>" .. item.Name .. "</b>", UDim2.fromScale(0.04, 0.09), UDim2.fromScale(0.65, 0.22), 24)
	text(row, "Description", item.Description, UDim2.fromScale(0.04, 0.35), UDim2.fromScale(0.69, 0.52), 17)
	text(row, "Cooldown", tostring(item.Cooldown) .. "s COOLDOWN", UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.25, 0.2), 12).TextXAlignment = Enum.TextXAlignment.Right
	text(row, "Action", item.Price == 0 and "EQUIPPED" or '<font color="#FFE89D"><b>BUY $' .. item.Price .. '</b></font>', UDim2.fromScale(0.74, 0.38), UDim2.fromScale(0.23, 0.4), 22).TextXAlignment = Enum.TextXAlignment.Center
end
text(background, "Hint", "Buy once. Equip here. Step out to close.", UDim2.fromScale(0.05, 0.94), UDim2.fromScale(0.9, 0.035), 13).TextXAlignment = Enum.TextXAlignment.Center
local hud = Instance.new("CanvasGroup")
hud.Name, hud.AnchorPoint = "SkillHUD", Vector2.new(1, 1)
hud.Position, hud.Size = UDim2.fromScale(0.97, 0.68), UDim2.fromOffset(190, 108)
hud.BackgroundTransparency, hud.GroupTransparency, hud.Visible, hud.ZIndex = 1, 1, false, 15
hud.Parent = gui
local hudScale = Instance.new("UIScale")
hudScale.Name, hudScale.Parent = "PanelScale", hud
local use = button(hud, "UseButton", UDim2.fromOffset(16, 16), UDim2.new(1, -32, 1, -32))
text(use, "Title", "DOUBLE JUMP", UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.3), 18).TextXAlignment = Enum.TextXAlignment.Center
text(use, "Status", "JUMP AGAIN", UDim2.fromScale(0.05, 0.52), UDim2.fromScale(0.9, 0.34), 18).TextXAlignment = Enum.TextXAlignment.Center
return "Created skill shop / inventory and skill HUD; preserved stud texture, font, stroke and shadow."
