local unseat = require("../src/ServerScriptService/BombGame/Unseat")

-- Roblox instances are unavailable in the standalone Luau runner.
local function seatedHumanoid(hasWeld)
	local weld = { destroyed = false }
	function weld:Destroy() self.destroyed = true end
	local seat = {}
	function seat:FindFirstChild(name)
		assert(name == "SeatWeld")
		return hasWeld and weld or nil
	end
	return { SeatPart = seat, Sit = true }, weld
end

local seated, weld = seatedHumanoid(true)
unseat(seated)
assert(weld.destroyed, "Teleport must detach the seat weld before moving the character")
assert(seated.Sit == false, "Teleport must clear the seated state")

local withoutWeld = seatedHumanoid(false)
unseat(withoutWeld)
assert(withoutWeld.Sit == false, "A seat whose weld is already gone must still be cleared")

local standing = { Sit = false }
unseat(standing)
assert(standing.Sit == false, "Standing characters must remain standing")

local sittingWithoutSeat = { Sit = true }
unseat(sittingWithoutSeat)
assert(sittingWithoutSeat.Sit == false, "Sitting without a SeatPart must also be cleared")
print("Unseat: detached weld, cleared sitting, missing weld and standing cases passed")
