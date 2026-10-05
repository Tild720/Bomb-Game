local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = ReplicatedStorage:WaitForChild("BombSkins")
local Catalog = { Items = {}, Order = {} }
local prices = { Bomb = 0, Smile = 1000, SoccerBall = 1500, ["Beach Ball"] = 2500, Epic = 4000, ["Eye Ball"] = 6000 }
local descriptions = {
	Bomb = "The original bomb. Always in your inventory.",
	Smile = "Keep smiling while the timer ticks.",
	SoccerBall = "Pass the ball before time runs out.",
	["Beach Ball"] = "A little summer chaos.",
	Epic = "An epic face for a close escape.",
	["Eye Ball"] = "All eyes on the bomb holder.",
}
for _, template in folder:GetChildren() do
	if template:IsA("BasePart") then
		local id = template.Name:gsub("[^%w_]", "")
		assert(id ~= "" and not Catalog.Items[id], "Bomb skin names must have unique identifiers")
		local price = template:GetAttribute("Price")
		price = typeof(price) == "number" and math.max(0, math.floor(price)) or prices[template.Name] or 2500
		Catalog.Items[id] = { Name = template.Name, Price = id == "Bomb" and 0 or price,
			Description = descriptions[template.Name] or "A new look for your bomb.", TemplateName = template.Name }
		table.insert(Catalog.Order, id)
	end
end
assert(Catalog.Items.Bomb, "BombSkins must include the default Bomb")
table.sort(Catalog.Order, function(a, b)
	if a == "Bomb" then return b ~= "Bomb" end
	if b == "Bomb" then return false end
	local x, y = Catalog.Items[a], Catalog.Items[b]
	return x.Price == y.Price and a < b or x.Price < y.Price
end)

function Catalog.Normalize(owned, equipped)
	local result = { Bomb = true }
	if typeof(owned) == "table" then
		for id in pairs(Catalog.Items) do if owned[id] == true then result[id] = true end end
	end
	return result, (typeof(equipped) == "string" and result[equipped]) and equipped or "Bomb"
end

function Catalog.PurchaseError(id, owned, money)
	local item = Catalog.Items[id]
	if not item then return "Unknown bomb skin." end
	if owned then return "You already own this skin." end
	if money < item.Price then return "Not enough money. You need $" .. tostring(item.Price - money) .. " more." end
	return nil
end

function Catalog.Clone(id)
	local item = Catalog.Items[id] or Catalog.Items.Bomb
	local source = folder:FindFirstChild(item.TemplateName)
	if not source or not source:IsA("BasePart") then source = ReplicatedStorage:WaitForChild("Bomb") end
	local bomb = source:Clone()
	for _, child in bomb:GetDescendants() do
		if child:IsA("BaseScript") or child:IsA("ModuleScript") or child:IsA("Sound")
			or child:IsA("BillboardGui") or child:IsA("JointInstance") or child:IsA("WeldConstraint") then child:Destroy() end
	end
	local timer = ReplicatedStorage:WaitForChild("Bomb"):FindFirstChild("BombTimer")
	if timer then timer:Clone().Parent = bomb end
	bomb:SetAttribute("BombSkinId", id)
	bomb:SetAttribute("SkinRotation", source.CFrame.Rotation)
	return bomb
end

return Catalog
