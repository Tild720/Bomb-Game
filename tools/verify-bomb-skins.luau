-- Edit-only contract checks: no Player data writes and no gameplay session.
local shared = game.ReplicatedStorage.BombGame
local module = shared.BombSkinCatalog:Clone()
module.Parent = shared
local Catalog = require(module)
module:Destroy()
local owned, equipped = Catalog.Normalize(nil, nil)
assert(owned.Bomb and equipped == "Bomb", "Old saves receive the free default")
owned, equipped = Catalog.Normalize({ BeachBall = true, Missing = true }, "BeachBall")
assert(owned.BeachBall and not owned.Missing and equipped == "BeachBall", "Purchased skins survive migration")
owned, equipped = Catalog.Normalize({ BeachBall = true }, "EyeBall")
assert(equipped == "Bomb", "An unowned skin cannot be equipped")
owned, equipped = Catalog.Normalize("corrupt", {})
assert(owned.Bomb and equipped == "Bomb", "Malformed saves recover safely")
assert(Catalog.PurchaseError("BeachBall", false, 2499), "Insufficient balance is rejected")
assert(Catalog.PurchaseError("BeachBall", false, 2500) == nil, "Exact balance is accepted")
assert(Catalog.PurchaseError("BeachBall", true, 100000), "Duplicate ownership cannot be charged")
assert(Catalog.PurchaseError("Missing", false, 100000), "Unknown skins are rejected")
local results = {}
for _, id in Catalog.Order do
	local bomb = Catalog.Clone(id)
	assert(bomb:IsA("BasePart") and bomb.Parent == nil, "Every skin clones without spawning into the map")
	assert(bomb:FindFirstChild("BombTimer") and bomb.BombTimer:FindFirstChild("TimerLabel"), "Every skin has the standard timer")
	for _, child in bomb:GetDescendants() do
		assert(not child:IsA("BaseScript") and not child:IsA("Sound"), "Skins cannot run template scripts or sounds")
	end
	assert(bomb:GetAttribute("BombSkinId") == id, "Skin identity is preserved")
	table.insert(results, { id = id, price = Catalog.Items[id].Price, timer = true })
	bomb:Destroy()
end
return results
