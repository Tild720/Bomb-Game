local TweenService = game:GetService("TweenService")
local UI = {}
local function escape(value)
	return tostring(value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

function UI.Render(surface, entries)
	local list = surface.Background.Rankings
	surface.Background.Empty.Visible = #entries == 0
	for rank = 1, 20 do
		local row = list:FindFirstChild(string.format("Rank%02d", rank))
		local entry = entries[rank]
		if row then
			local wasVisible = row.Visible
			row.Visible = entry ~= nil
			if entry then
				row.PlayerName.Text = '<b>' .. escape(entry.Name) .. '</b>'
				row.Wins.Text = '<font color="#FFE7A0"><b>' .. entry.Wins .. '</b></font>'
				row.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. entry.UserId .. "&w=150&h=150"
				if not wasVisible then
					local transparency = row.BackgroundTransparency
					row.BackgroundTransparency = 1
					TweenService:Create(row, TweenInfo.new(0.25), { BackgroundTransparency = transparency }):Play()
				end
			end
		end
	end
end

return UI
