-- Apply after section-shop-ui. Gradients shade the surface, preserving rich-text colors.
local gui = game.StarterGui.SubGui
local function gradient(object, top, bottom, rotation)
	local shade = object:FindFirstChild("SurfaceGradient") or Instance.new("UIGradient")
	shade.Name = "SurfaceGradient"
	shade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.45, Color3.new(0.94, 0.97, 1)),
		ColorSequenceKeypoint.new(1, bottom),
	})
	shade.Rotation, shade.Parent = rotation or 90, object
end
local white = Color3.new(1, 1, 1)
local cool = Color3.fromRGB(160, 198, 221)
local deep = Color3.fromRGB(122, 156, 184)
for _, name in { "Shop", "Guide", "Spectate" } do
	gradient(gui[name .. "Button"], white, cool)
	local background = gui.MenuPanels[name].Background
	gradient(background, white, deep, 70)
	gradient(background.CloseButton, Color3.fromRGB(255, 238, 230), Color3.fromRGB(184, 146, 160))
	for _, object in background:GetDescendants() do
		if object:IsA("ImageButton") and object.Name ~= "CloseButton" then gradient(object, white, cool) end
	end
	if background:FindFirstChild("HeaderBand") then
		gradient(background.HeaderBand, Color3.fromRGB(220, 255, 250), Color3.fromRGB(130, 177, 222), 20)
		gradient(background.ListWell, Color3.fromRGB(200, 224, 244), Color3.fromRGB(130, 155, 188))
	end
end
local vip = gui.MenuPanels.Shop.Background.Items.BuyButton
gradient(vip, Color3.fromRGB(255, 250, 219), Color3.fromRGB(197, 194, 147), 75)
gradient(vip.ActionBackground, Color3.fromRGB(255, 252, 224), Color3.fromRGB(213, 167, 96))
local skill = gui.SkillShop.Background
gradient(skill, white, deep, 70)
gradient(skill.HeaderBand, Color3.fromRGB(220, 255, 250), Color3.fromRGB(130, 177, 222), 20)
gradient(skill.ListWell, Color3.fromRGB(200, 224, 244), Color3.fromRGB(130, 155, 188))
gradient(skill.CloseButton, Color3.fromRGB(255, 238, 230), Color3.fromRGB(184, 146, 160))
local catalog = require(game.ReplicatedStorage.BombGame.SkillCatalog)
for _, id in catalog.Order do
	local row = skill.Items[id]
	gradient(row, Color3.fromRGB(240, 251, 255), Color3.fromRGB(166, 190, 217), 80)
	gradient(row.Action, Color3.fromRGB(255, 252, 235), Color3.fromRGB(183, 204, 204))
	for _, child in row:GetChildren() do
		if child:IsA("UIStroke") then gradient(child, white, Color3.fromRGB(137, 188, 205)) end
	end
end
gradient(gui.SkillHUD.UseButton, white, cool)
return "Applied surface gradients to menu headers, content wells, cards, buttons and borders."
