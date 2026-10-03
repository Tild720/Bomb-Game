local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BombGame")
local state = shared:WaitForChild("State")
local effects = shared:WaitForChild("Effects")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("HotPotatoGui")
local status = gui:WaitForChild("StatusLabel")
local aliveLabel = gui:WaitForChild("AliveLabel")
local message = gui:WaitForChild("MessageLabel")
local eliminatedAt = 0
local previousEliminated = player:GetAttribute("EliminatedRound")

player:GetAttributeChangedSignal("EliminatedRound"):Connect(function()
	local current = player:GetAttribute("EliminatedRound")
	if current ~= previousEliminated then eliminatedAt = workspace:GetServerTimeNow() end
	previousEliminated = current
end)

-- UI는 Studio의 기존 인스턴스를 갱신하며 서버 시각으로 카운트다운합니다.
local function updateUi()
	local now = workspace:GetServerTimeNow()
	local phase = state:GetAttribute("Phase") or "Waiting"
	local remaining = math.max(0, math.ceil((state:GetAttribute("Deadline") or 0) - now))
	local inRound = player:GetAttribute("InRound") == true
	local text = ""
	if phase == "Waiting" then
		status.Text = "인원 대기"
	elseif phase == "Countdown" then
		status.Text = "시작까지 " .. remaining .. "초"
	elseif phase == "Ready" then
		status.Text = "경기 준비"
		if inRound then text = tostring(remaining) end
	elseif phase == "Playing" then
		status.Text = "경기 진행"
		if inRound and state:GetAttribute("HolderUserId") == player.UserId then text = "폭탄을 넘겨!" end
	elseif phase == "Results" then
		status.Text = "경기 종료"
		local winner = state:GetAttribute("Winner") or ""
		text = winner ~= "" and ("승리: " .. winner) or "승자 없음"
	end
	if now - eliminatedAt < 2 and not inRound and phase ~= "Results" then text = "탈락!" end
	aliveLabel.Visible = phase == "Ready" or phase == "Playing"
	aliveLabel.Text = "생존자 " .. (state:GetAttribute("AliveCount") or 0) .. "명"
	message.Text = text
	message.Visible = text ~= ""
	local bomb = workspace:FindFirstChild("HotPotatoBomb")
	local timer = bomb and bomb:FindFirstChild("BombTimer")
	if timer then
		local seconds = math.max(0, (bomb:GetAttribute("ExpiresAt") or 0) - now)
		local scale = timer.TimerLabel:FindFirstChild("PulseScale")
		if scale then scale.Scale = seconds > 0 and seconds <= 5 and (1 + 0.06 * math.sin(now * 10)) or 1 end
	end
end

effects.OnClientEvent:Connect(function(kind, position)
	local effect = Instance.new("Part")
	effect.Name = "HotPotatoEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = kind == "Explosion" and Color3.fromRGB(255, 110, 50) or Color3.fromRGB(255, 230, 120)
	effect.Anchored = true
	effect.CanCollide, effect.CanTouch, effect.CanQuery = false, false, false
	effect.Size = Vector3.one
	effect.Position = position
	effect.Transparency = 0.4
	effect.Parent = workspace
	local size = kind == "Explosion" and 7 or 3
	TweenService:Create(effect, TweenInfo.new(0.3), { Size = Vector3.one * size, Transparency = 1 }):Play()
	Debris:AddItem(effect, 0.35)
end)

local elapsed = 0
RunService.RenderStepped:Connect(function(delta)
	elapsed += delta
	if elapsed >= 0.05 then
		elapsed = 0
		updateUi()
	end
end)
updateUi()
