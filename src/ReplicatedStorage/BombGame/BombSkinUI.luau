local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(script.Parent:WaitForChild("BombSkinCatalog"))
local UI = {}

function UI.Layout(shop)
	local background = shop.Background
	local function layout()
		local scale = math.clamp(background.AbsoluteSize.X / 740, 0.65, 1)
		background.Title.TextSize = math.floor(40 * scale)
		background.Balance.TextSize = math.floor(32 * scale)
		background.Hint.TextSize = math.floor(23 * scale)
		for _, id in Catalog.Order do
			local row = background.Items[id]
			local inset, icon, gap, actionWidth = 12 * scale, 76 * scale, 12 * scale, 174 * scale
			local textX = inset + icon + gap
			row.Size = UDim2.new(1, -14, 0, 132 * scale)
			row.SkinPreview.Position, row.SkinPreview.Size = UDim2.new(0, inset, 0.5, 0), UDim2.fromOffset(icon, icon)
			row.Title.Position, row.Title.Size = UDim2.fromOffset(textX, 6 * scale), UDim2.new(1, -(textX + actionWidth + inset + gap), 0, 44 * scale)
			row.Description.Position, row.Description.Size = UDim2.fromOffset(textX, 50 * scale), UDim2.new(1, -(textX + actionWidth + inset + gap), 0, 76 * scale)
			row.Action.Position, row.Action.Size = UDim2.new(1, -inset, 0.61, 0), UDim2.fromOffset(actionWidth, 68 * scale)
			row.Cooldown.Position, row.Cooldown.Size = UDim2.new(1, -(inset + actionWidth), 0, 15 * scale), UDim2.fromOffset(actionWidth, 25 * scale)
			row.Title.TextSize, row.Description.TextSize = math.floor(40 * scale), math.floor(32 * scale)
			row.Action.Caption.TextSize, row.Cooldown.TextSize = math.floor(34 * scale), math.floor(21 * scale)
		end
	end
	layout()
	background:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
end

function UI.Create(gui)
	local existing = gui:FindFirstChild("BombSkinShop")
	if existing then UI.Layout(existing) return existing end
	local source = gui:WaitForChild("SkillShop")
	local shop = source:Clone()
	shop.Name, shop.Visible, shop.GroupTransparency = "BombSkinShop", false, 1
	shop.PanelScale.Scale = 1
	local background = shop.Background
	local items = background.Items
	local rowSource = source.Background.Items.DoubleJump
	for _, child in items:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
	background.BackgroundColor3 = Color3.fromRGB(112, 60, 66)
	background.HeaderBand.BackgroundColor3 = Color3.fromRGB(164, 83, 92)
	background.HeaderBand.SquareJoin.BackgroundColor3 = Color3.fromRGB(151, 65, 71)
	background.CloseButton.BackgroundColor3 = Color3.fromRGB(181, 99, 107)
	background.Title.Text = '<b>BOMB SKINS</b> <font color="#FFD4BC"><i>&amp; INVENTORY</i></font>'
	background.Balance.Text = '<font color="#FFE89D"><b>$0</b></font>  <i>Choose your bomb</i>'
	background.Hint.Text = '<i>Buy once. Equip here. Step out to close.</i>'
	items.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 190)
	for _, child in shop:GetDescendants() do
		if child:IsA("UIGradient") then
			child.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(235, 190, 186))
		elseif child:IsA("UIStroke") then child.Color = Color3.fromRGB(255, 202, 193)
		elseif child.Name == "Stripe" then child.BackgroundColor3 = Color3.fromRGB(255, 221, 208)
		elseif child.Name == "Sunburst" then child.ImageColor3 = Color3.fromRGB(255, 211, 196) end
	end
	for index, id in Catalog.Order do
		local item = Catalog.Items[id]
		local row = rowSource:Clone()
		row.Name, row.LayoutOrder = id, index
		row.BackgroundColor3 = Color3.fromRGB(138, 75, 83)
		row.Title.Text = '<b>' .. item.Name:upper() .. '</b>'
		row.Description.Text = '<i><font color="#FFE0D1">' .. item.Description .. '</font></i>'
		row.Cooldown.Text = id == "Bomb" and "DEFAULT" or "COSMETIC"
		row.Action.BackgroundColor3 = Color3.fromRGB(190, 109, 116)
		row.Action.Caption.Text = id == "Bomb" and '<b>EQUIPPED</b>' or '<b>BUY</b>\n$' .. item.Price
		for _, child in row:GetDescendants() do
			if child:IsA("UIGradient") then child.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(235, 190, 186))
			elseif child:IsA("UIStroke") then child.Color = Color3.fromRGB(255, 202, 193) end
		end
		local oldImage = row.SkillImage
		local preview = Instance.new("ViewportFrame")
		preview.Name, preview.BackgroundTransparency = "SkinPreview", 1
		preview.Position, preview.Size, preview.AnchorPoint = oldImage.Position, oldImage.Size, oldImage.AnchorPoint
		preview.ZIndex, preview.Active = oldImage.ZIndex, false
		preview.Ambient, preview.LightColor = Color3.fromRGB(210, 210, 210), Color3.new(1, 1, 1)
		preview.LightDirection = Vector3.new(-1, -1, -2)
		oldImage:Destroy()
		preview.Parent = row
		local world = Instance.new("WorldModel")
		world.Parent = preview
		local model = Catalog.Clone(id)
		local timer = model:FindFirstChild("BombTimer")
		if timer then timer:Destroy() end
		model.Name, model.Anchored, model.CanCollide = "PreviewBomb", true, false
		model.CFrame = model:GetAttribute("SkinRotation")
		model.Parent = world
		local camera = Instance.new("Camera")
		camera.FieldOfView = 35
		local radius = math.max(model.Size.X, model.Size.Y, model.Size.Z)
		camera.CFrame = CFrame.lookAt(Vector3.new(0, radius * 0.3, radius * 2.5), Vector3.zero)
		camera.Parent, preview.CurrentCamera = preview, camera
		row.Parent = items
	end
	shop.Parent = gui
	UI.Layout(shop)
	return shop
end

return UI
