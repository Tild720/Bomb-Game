local Catalog = {}
Catalog.Order = { "DoubleJump", "Dash", "Push", "Banana", "Swap" }
Catalog.Items = {
	DoubleJump = { Name = "DOUBLE JUMP", Image = "rbxassetid://94527049285000", Price = 0, Cooldown = 0.25, Description = "Jump once more in midair. Recharges when you land." },
	Dash = { Name = "DASH", Image = "rbxassetid://120938680230838", Price = 3000, Cooldown = 2, Description = "A short forward burst. Movement only, no invincibility." },
	Push = { Name = "PUSH", Image = "rbxassetid://138870488917156", Price = 5000, Cooldown = 3, Description = "Knock back the closest player in front of you. No stun." },
	Banana = { Name = "BANANA", Image = "rbxassetid://116226052279372", Price = 8000, Cooldown = 5, Description = "Drop a peel. The next opponent moves 40% slower for 1.5s." },
	Swap = { Name = "SWAP", Image = "rbxassetid://101678945831696", Price = 25000, Cooldown = 8, Description = "Trade places with the nearest player ahead after a short warning." },
}

function Catalog.PurchaseError(id, owned, money)
	local item = Catalog.Items[id]
	if not item then return "Unknown skill." end
	if owned then return "You already own this skill." end
	if money < item.Price then return "Not enough money. You need $" .. tostring(item.Price - money) .. " more." end
	return nil
end

function Catalog.Normalize(owned, equipped)
	local result = { DoubleJump = true }
	if typeof(owned) == "table" then
		for id in pairs(Catalog.Items) do if owned[id] == true then result[id] = true end end
	end
	return result, (typeof(equipped) == "string" and result[equipped]) and equipped or "DoubleJump"
end

function Catalog.InShop(hitbox, root)
	if not root or not hitbox then return false end
	local p = hitbox.CFrame:PointToObjectSpace(root.Position)
	local half = hitbox.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Z) <= half.Z
		and p.Y >= -half.Y - 2 and p.Y <= half.Y + 3
end

return Catalog
