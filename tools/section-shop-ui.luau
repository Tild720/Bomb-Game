-- Apply after build-skill-ui and polish-menu-ui. Existing fonts and stud assets are retained.
local gui = game.StarterGui.SubGui
local source = gui.ShopButton
local function panel(parent, name, color, position, size, z)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local frame = Instance.new("Frame")
	frame.Name, frame.BackgroundColor3 = name, color
	frame.BorderSizePixel, frame.Position, frame.Size, frame.ZIndex = 0, position, size, z
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 8), frame
	return frame
end
local function action(parent, oldLabel)
	if oldLabel:IsA("ImageButton") then return oldLabel end
	local button = Instance.new("ImageButton")
	button.Name = "Action"
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.fromRGB(171, 125, 53)
	button.Image, button.ImageColor3 = source.Image, source.ImageColor3
	button.ImageTransparency, button.ScaleType, button.TileSize = 0.88, Enum.ScaleType.Tile, UDim2.fromOffset(112, 112)
	button.Position, button.Size = UDim2.fromScale(0.745, 0.29), UDim2.fromScale(0.23, 0.61)
	button.ZIndex, button.Parent = 25, parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 6), button
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Transparency = Color3.fromRGB(255, 229, 173), 1.5, 0.15
	stroke.Parent = button
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "InteractionScale", button
	oldLabel.Name, oldLabel.Parent = "Caption", button
	oldLabel.Position, oldLabel.Size, oldLabel.ZIndex = UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84), 26
	oldLabel.TextXAlignment = Enum.TextXAlignment.Center
	oldLabel.UITextSizeConstraint.MaxTextSize = 24
	return button
end
local skill = gui.SkillShop.Background
skill.BackgroundColor3 = Color3.fromRGB(43, 66, 77)
skill.ImageTransparency = 0.9
panel(skill, "HeaderBand", Color3.fromRGB(40, 106, 112), UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 98), 21)
skill.Title.Position, skill.Title.Size = UDim2.fromOffset(20, 9), UDim2.new(1, -106, 0, 40)
skill.Title.Text = '<b>SKILL SHOP</b> <font color="#FFE89D"><i>&amp; Inventory</i></font>'
skill.Title.UITextSizeConstraint.MaxTextSize = 34
skill.Balance.Position, skill.Balance.Size = UDim2.fromOffset(20, 57), UDim2.new(1, -100, 0, 28)
skill.Balance.UITextSizeConstraint.MaxTextSize = 24
skill.CloseButton.ZIndex = 25
skill.CloseButton.Caption.ZIndex = 26
panel(skill, "ListWell", Color3.fromRGB(29, 45, 56), UDim2.fromOffset(10, 108), UDim2.new(1, -20, 1, -147), 20)
skill.Items.Position, skill.Items.Size = UDim2.fromOffset(13, 111), UDim2.new(1, -26, 1, -153)
skill.Items.UIListLayout.Padding = UDim.new(0, 8)
skill.Items.UIPadding.PaddingTop, skill.Items.UIPadding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
skill.Hint.Position, skill.Hint.Size = UDim2.new(0, 14, 1, -31), UDim2.new(1, -28, 0, 23)
skill.Hint.Text = '<i>One skill equipped at a time.</i>'
local Catalog = require(game.ReplicatedStorage.BombGame.SkillCatalog)
for _, id in Catalog.Order do
	local row = skill.Items[id]
	if row:IsA("ImageButton") then
		local replacement = Instance.new("ImageLabel")
		for _, property in { "Name", "LayoutOrder", "Image", "ImageColor3", "ScaleType", "TileSize", "ZIndex" } do replacement[property] = row[property] end
		for _, child in row:GetChildren() do child.Parent = replacement end
		replacement.Parent = row.Parent
		row:Destroy()
		row = replacement
	end
	row.Size = UDim2.new(1, -14, 0, 112)
	row.BackgroundColor3 = id == "DoubleJump" and Color3.fromRGB(57, 85, 77) or Color3.fromRGB(54, 76, 88)
	row.ImageTransparency = 0.91
	row.Title.Position, row.Title.Size = UDim2.fromScale(0.025, 0.065), UDim2.fromScale(0.69, 0.28)
	row.Title.UITextSizeConstraint.MaxTextSize = 28
	row.Description.Position, row.Description.Size = UDim2.fromScale(0.025, 0.4), UDim2.fromScale(0.69, 0.54)
	row.Description.UITextSizeConstraint.MaxTextSize = 21
	row.Cooldown.Position, row.Cooldown.Size = UDim2.fromScale(0.745, 0.065), UDim2.fromScale(0.23, 0.17)
	row.Cooldown.TextXAlignment = Enum.TextXAlignment.Center
	row.Cooldown.UITextSizeConstraint.MaxTextSize = 14
	local buy = action(row, row.Action)
	buy.Caption.Text = id == "DoubleJump" and '<b>EQUIPPED</b>' or '<b>BUY</b>\n$' .. Catalog.Items[id].Price
	if id == "DoubleJump" then buy.BackgroundColor3 = Color3.fromRGB(76, 116, 92) end
end
-- Keep the existing VIP button contract; its card gets its own well and a clear call-to-action.
local vipGroup = gui.MenuPanels.Shop
vipGroup.UISizeConstraint.MaxSize = Vector2.new(740, 335)
local vip = vipGroup.Background
vip.BackgroundColor3, vip.ImageTransparency = Color3.fromRGB(43, 66, 77), 0.9
panel(vip, "HeaderBand", Color3.fromRGB(40, 106, 112), UDim2.new(), UDim2.new(1, 0, 0, 74), 10)
vip.Title.Position, vip.Title.Size = UDim2.fromOffset(20, 10), UDim2.new(1, -110, 0, 50)
vip.Title.Text = '<b>SHOP</b> <font color="#FFE89D"><i>VIP</i></font>'
vip.Title.ZIndex = 12
vip.CloseButton.ZIndex = 14
vip.CloseButton.Caption.ZIndex = 15
panel(vip, "ListWell", Color3.fromRGB(29, 45, 56), UDim2.fromOffset(10, 83), UDim2.new(1, -20, 1, -123), 10)
vip.Items.Position, vip.Items.Size = UDim2.fromOffset(13, 86), UDim2.new(1, -26, 1, -129)
vip.Items.UIPadding.PaddingTop, vip.Items.UIPadding.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
local buy = vip.Items.BuyButton
buy.Size = UDim2.new(1, -14, 0, 146)
buy.BackgroundColor3, buy.ImageTransparency = Color3.fromRGB(99, 95, 65), 0.9
buy.Badge.Position, buy.Badge.Size = UDim2.fromScale(0.025, 0.15), UDim2.fromScale(0.19, 0.6)
buy.Description.Position, buy.Description.Size = UDim2.fromScale(0.24, 0.09), UDim2.fromScale(0.71, 0.42)
buy.Description.UITextSizeConstraint.MaxTextSize = 25
local callout = panel(buy, "ActionBackground", Color3.fromRGB(155, 116, 49), UDim2.fromScale(0.24, 0.57), UDim2.fromScale(0.71, 0.35), 13)
local border = Instance.new("UIStroke")
border.Color, border.Thickness, border.Parent = Color3.fromRGB(255, 229, 173), 1.5, callout
buy.Caption.Position, buy.Caption.Size, buy.Caption.ZIndex = UDim2.fromScale(0.25, 0.59), UDim2.fromScale(0.69, 0.31), 14
buy.Caption.TextXAlignment = Enum.TextXAlignment.Center
buy.Caption.UITextSizeConstraint.MaxTextSize = 25
vip.Feedback.Position, vip.Feedback.Size = UDim2.new(0, 15, 1, -32), UDim2.new(1, -30, 0, 25)
return "Separated colored headers, recessed lists and explicit skill action buttons; compacted item rows."
