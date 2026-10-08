return function(humanoid)
	local seat = humanoid.SeatPart
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end
	end
	humanoid.Sit = false
end
