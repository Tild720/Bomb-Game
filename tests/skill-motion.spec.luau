local Motion = require("../src/ReplicatedStorage/BombGame/SkillMotion")
assert(Motion.DashWeight(0) == 1, "Dash must start without a stationary ramp")
assert(Motion.DashWeight(Motion.DashDuration) <= 0.000001, "No dash contribution may remain at the deadline")
assert(Motion.DashWeight(1) == 0, "Late frames must not extend the dash")
local previous = 1
for i = 0, 100 do
	local value = Motion.DashWeight(Motion.DashDuration * i / 100)
	assert(value >= 0 and value <= previous + 0.000001, "Dash deceleration must be bounded and monotonic")
	previous = value
end
assert(Motion.JumpVelocity < 48, "Extra jump must be shorter than the previous impulse")
assert(Motion.DashDuration <= 0.2 and Motion.DashDistance <= 9)
print("Skill motion: immediate start, smooth bounded decay, finite deadline and shorter jump passed")
