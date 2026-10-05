-- Offline Luau checks only. Never starts a Studio play session or touches player data.
local Catalog = require("../src/ReplicatedStorage/BombGame/SkillCatalog")
local owned, equipped = Catalog.Normalize(nil, nil)
assert(owned.DoubleJump and equipped == "DoubleJump", "Existing saves must receive the free default")
owned, equipped = Catalog.Normalize({ Dash = true, Swap = false, Unknown = true }, "Swap")
assert(owned.Dash and not owned.Swap and not owned.Unknown and equipped == "DoubleJump", "Unowned or removed skills cannot be equipped")
owned, equipped = Catalog.Normalize({ Smoke = true }, "Smoke")
assert(not owned.Smoke and owned.DoubleJump and equipped == "DoubleJump", "Removed Smoke must fall back to DoubleJump")
owned, equipped = Catalog.Normalize({ Swap = true }, "Swap")
assert(owned.Swap and equipped == "Swap", "Available purchased skills must survive reload")
assert(Catalog.PurchaseError("Smoke", false, 100000), "Removed Smoke cannot be purchased")
owned, equipped = Catalog.Normalize("corrupt", {})
assert(owned.DoubleJump and equipped == "DoubleJump", "Invalid stored values must recover safely")
assert(Catalog.PurchaseError("Dash", false, 2999), "Reject insufficient funds")
assert(Catalog.PurchaseError("Dash", false, 3000) == nil, "Allow exact balance")
assert(Catalog.PurchaseError("Dash", true, 100000), "Never charge for duplicate ownership")
assert(Catalog.PurchaseError("Unknown", false, 100000), "Reject unknown items")
local count = 0
for _, id in Catalog.Order do
	assert(Catalog.Items[id] and Catalog.Items[id].Cooldown > 0)
	count += 1
end
assert(count == 5, "Only the five remaining skills must be offered")
print("Skill catalog: migration, ownership and purchase boundary checks passed")
