local MapRotation = {}
MapRotation.__index = MapRotation

function MapRotation.SpawnPoints(model)
	local folder = model:FindFirstChild("SpawnPoints")
	local points = {}
	if folder then
		for _, point in folder:GetDescendants() do
			if point:IsA("BasePart") then table.insert(points, point) end
		end
	end
	return points
end

function MapRotation.Align(model, destination)
	local field = model:FindFirstChild("Field")
	-- Keep every part's transform relative to Field, including a non-centered model pivot.
	model:PivotTo(destination.CFrame * field.CFrame:Inverse() * model:GetPivot())
end

function MapRotation.new(folder, destination, random)
	return setmetatable({ folder = folder, destination = destination, random = random,
		originalCollision = destination.CanCollide, active = nil }, MapRotation)
end

function MapRotation:Clear()
	if self.active then self.active:Destroy() self.active = nil end
	self.destination.CanCollide = self.originalCollision
end

function MapRotation:Load()
	self:Clear()
	local candidates = {}
	for _, model in self.folder:GetChildren() do
		local field = model:FindFirstChild("Field")
		if model:IsA("Model") and model.Archivable and field and field:IsA("BasePart") and #MapRotation.SpawnPoints(model) > 0 then
			table.insert(candidates, model)
		end
	end
	if #candidates == 0 then return nil, "No maps with Field and SpawnPoints are available." end
	local original = candidates[self.random:NextInteger(1, #candidates)]
	local model = original:Clone()
	model.Name = "ActiveRoundMap"
	model:SetAttribute("MapName", original.Name)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then part.Anchored = true end
	end
	MapRotation.Align(model, self.destination)
	local points = MapRotation.SpawnPoints(model)
	for _, point in points do
		point.Transparency, point.CastShadow = 1, false
		point.CanCollide, point.CanTouch, point.CanQuery = false, false, false
		if point:IsA("SpawnLocation") then point.Enabled = false end
	end
	for index = #points, 2, -1 do
		local other = self.random:NextInteger(1, index)
		points[index], points[other] = points[other], points[index]
	end
	model.Parent = workspace
	self.active = model
	-- The map supplies its own floor; the alignment reference must not create a second floor.
	self.destination.CanCollide = false
	return model, points
end

return MapRotation
