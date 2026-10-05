local Motion = { DashDuration = 0.2, DashFadeTime = 0.07, DashDistance = 9, DashSpeed = 52, JumpVelocity = 34 }
function Motion.DashWeight(elapsed)
	local t = math.clamp((elapsed - (Motion.DashDuration - Motion.DashFadeTime)) / Motion.DashFadeTime, 0, 1)
	return 1 - t * t * (3 - 2 * t)
end
return Motion
