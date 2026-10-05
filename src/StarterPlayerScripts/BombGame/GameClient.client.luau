local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BombGame")
local Config = require(shared:WaitForChild("Config"))
local SoundService = game:GetService("SoundService")
local soundPack = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Local Sounds")
local state = shared:WaitForChild("State")
local effects = shared:WaitForChild("Effects")
local rewards = shared:WaitForChild("Reward")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("HotPotatoGui")
local status = gui:WaitForChild("StatusLabel")
local aliveLabel = gui:WaitForChild("AliveLabel")
local message = gui:WaitForChild("MessageLabel")
local announcement = gui:WaitForChild("AnnouncementLabel")
local countdown = gui:WaitForChild("CountdownLabel")
local eliminatedAt = 0
local previousEliminated = player:GetAttribute("EliminatedRound")
local lastCountdownCue = ""
local lastMessageKey = ""
local messageExpiresAt = 0
local lastAnnouncementKey = ""
local announcementExpiresAt = 0
local popupRandom = Random.new()
local labelTweens = {}
local labelTargets = {}
local labelStrokeTransparency = {}
local songs = SoundService:WaitForChild("Classic Sound Pack"):WaitForChild("Songs")
local musicMode
local music
local musicEnded
local musicFade
local musicFinished = false
local musicStartedAt = 0
local musicFadedIn = false
local nextMusicAttempt = 0
local musicIndex = { Lobby = 0, InGame = 0 }

-- 플레이어 이름의 기호가 RichText 태그로 해석되지 않도록 처리합니다.
local function escapeRichText(text)
	return tostring(text):upper():gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function boldColor(text, color)
	return '<font color="' .. color .. '"><b>' .. escapeRichText(text) .. '</b></font>'
end

local function stopMusic()
	if musicEnded then musicEnded:Disconnect() end
	if musicFade then musicFade:Cancel() end
	musicEnded, musicFade = nil, nil
	if music then
		local previous = music
		TweenService:Create(previous, TweenInfo.new(Config.Bgm.FadeTime), { Volume = 0 }):Play()
		Debris:AddItem(previous, Config.Bgm.FadeTime + 0.05)
		music = nil
	end
	musicFinished = false
end

local function startNextMusic(now)
	local playlist = Config.Bgm[musicMode]
	for _ = 1, #playlist do
		musicIndex[musicMode] = musicIndex[musicMode] % #playlist + 1
		local source = songs:FindFirstChild(playlist[musicIndex[musicMode]])
		if source and source:IsA("Sound") then
			music = source:Clone()
			music.Name = "HotPotatoBgm"
			music.Looped = false
			music.TimePosition = 0
			music.Volume = 0
			music.Parent = SoundService
			musicStartedAt = now
			musicFadedIn = false
			musicFinished = false
			musicEnded = music.Ended:Connect(function() musicFinished = true end)
			music:Play()
			return
		end
	end
	nextMusicAttempt = now + Config.Bgm.LoadTimeout
end

-- 각 플레이어가 로비/경기 상태에 맞는 곡을 듣습니다. 실패한 곡은 건너뜁니다.
local function updateMusic(now)
	local mode = player:GetAttribute("InRound") == true and "InGame" or "Lobby"
	if mode ~= musicMode then
		stopMusic()
		musicMode = mode
		nextMusicAttempt = 0
	end
	if music and (musicFinished or (not music.IsLoaded and now - musicStartedAt >= Config.Bgm.LoadTimeout)) then
		stopMusic()
	end
	if not music and now >= nextMusicAttempt then startNextMusic(now) end
	if music and music.IsLoaded and not musicFadedIn then
		musicFadedIn = true
		musicFade = TweenService:Create(music, TweenInfo.new(Config.Bgm.FadeTime), { Volume = Config.Bgm.Volume })
		musicFade:Play()
	end
end

local function playLocalSound(kind)
	local source = soundPack:FindFirstChild(Config.Sounds[kind])
	if not source or not source:IsA("Sound") then return end
	local sound = source:Clone()
	sound.Name = "HotPotato" .. kind
	sound.Looped = false
	sound.TimePosition = 0
	sound.Volume = math.min(source.Volume, 0.45)
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function() sound:Destroy() end)
	Debris:AddItem(sound, 15)
end

rewards.OnClientEvent:Connect(function(amount, reason)
	local popup = Instance.new("TextLabel")
	popup.Name = "MoneyReward"
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	-- 중앙 70% 영역 안의 좌우 사이드에 작은 알림을 표시합니다.
	popup.Size = UDim2.fromScale(0.16, 0.05)
	popup.Rotation = popupRandom:NextNumber(-15, 15)
	local topInset, bottomInset = GuiService:GetGuiInset()
	local viewport = workspace.CurrentCamera.ViewportSize
	if not gui.IgnoreGuiInset then viewport -= topInset + bottomInset end
	-- 이유 텍스트와 회전/팝 효과의 여백까지 중앙 60% 안에 둡니다.
	local angle = math.rad(math.abs(popup.Rotation))
	local halfWidth = math.min(viewport.X * 0.08, viewport.Y * 0.2)
	local halfHeight = viewport.Y * 0.0425
	popup.Size = UDim2.fromOffset(halfWidth * 2, viewport.Y * 0.05)
	local marginX = (halfWidth * math.cos(angle) + halfHeight * math.sin(angle)) * 1.1 / viewport.X
	local marginY = (halfWidth * math.sin(angle) + halfHeight * math.cos(angle)) * 1.1 / viewport.Y
	local minX, maxX = 0.2 + marginX, 0.8 - marginX
	local sideWidth = math.min(0.1, (maxX - minX) / 2)
	local leftSide = popupRandom:NextInteger(0, 1) == 0
	local x = leftSide and popupRandom:NextNumber(minX, minX + sideWidth)
		or popupRandom:NextNumber(maxX - sideWidth, maxX)
	popup.Position = UDim2.fromScale(x, popupRandom:NextNumber(0.2 + marginY, 0.8 - marginY))
	popup.BackgroundTransparency = 1
	popup.FontFace = status.FontFace
	popup.RichText = true
	popup.Text = boldColor("+$" .. tostring(amount), "#78FF96")
	popup.TextColor3 = Color3.fromRGB(120, 255, 150)
	popup.TextStrokeTransparency = 0.3
	popup.TextScaled = true
	popup.ZIndex = 20
	popup.Parent = gui
	local amountSize = Instance.new("UITextSizeConstraint")
	amountSize.MaxTextSize = 42
	amountSize.Parent = popup
	local caption = Instance.new("TextLabel")
	caption.Name = "Reason"
	caption.AnchorPoint = Vector2.new(0.5, 0)
	caption.Position = UDim2.fromScale(0.5, 1)
	caption.Size = UDim2.fromScale(1, 0.35)
	caption.BackgroundTransparency = 1
	caption.FontFace = status.FontFace
	caption.RichText = true
	caption.Text = '<font color="#E2E8F0">' .. escapeRichText(reason) .. '</font>'
	caption.TextColor3 = Color3.new(1, 1, 1)
	caption.TextStrokeTransparency = 0.3
	caption.TextScaled = true
	caption.ZIndex = popup.ZIndex
	caption.Parent = popup
	local reasonSize = Instance.new("UITextSizeConstraint")
	reasonSize.MaxTextSize = 20
	reasonSize.Parent = caption
	local scale = Instance.new("UIScale")
	scale.Scale = 0.65
	scale.Parent = popup
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if reason == "OBBY COMPLETE" then
		playLocalSound("ObbyComplete")
	elseif reason ~= "COIN PICKUP" then
		playLocalSound("Notification")
	end
	task.delay(Config.RewardPopupDuration, function()
		if not popup.Parent then return end
		local fadeInfo = TweenInfo.new(0.4)
		TweenService:Create(popup, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(caption, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(scale, fadeInfo, { Scale = 0.9 }):Play()
	end)
	Debris:AddItem(popup, Config.RewardPopupDuration + 0.45)
end)

-- 표시 요청을 기준으로 애니메이션을 관리하여 매 UI 갱신마다 재시작하지 않습니다.
local function setLabel(label, text, visible, emphasis)
	local previous = labelTargets[label]
	if previous and previous.visible == visible and (not visible or previous.text == text) then return end
	local target = { text = text, visible = visible }
	labelTargets[label] = target
	local shadow = label:FindFirstChildOfClass("UIShadow")
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke and labelStrokeTransparency[label] == nil then
		labelStrokeTransparency[label] = stroke.Transparency
	end
	local noShadow = label:GetAttribute("NoShadow") == true
	local strokeTransparency = stroke and 1 or 0.2
	if noShadow and shadow then shadow.Transparency = 1 end
	for _, tween in ipairs(labelTweens[label] or {}) do tween:Cancel() end
	labelTweens[label] = {}
	local scale = label:FindFirstChild("AnimationScale")
	if not visible then
		if not label.Visible then return end
		-- 문구는 남겨 둔 채 투명하게 만든 뒤 숨깁니다.
		local fadeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local fadeOut = TweenService:Create(label, fadeInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		table.insert(labelTweens[label], fadeOut)
		fadeOut.Completed:Once(function(playbackState)
			-- 퇴장 중 새 문구가 표시되면 이전 완료 콜백이 숨기지 못하게 합니다.
			if playbackState == Enum.PlaybackState.Completed and labelTargets[label] == target then
				label.Visible = false
			end
		end)
		if scale then
			local shrink = TweenService:Create(scale, fadeInfo, { Scale = 0.9 })
			table.insert(labelTweens[label], shrink)
			shrink:Play()
		end
		for _, effect in ipairs(label:GetChildren()) do
			if effect == stroke or effect == shadow then
				local effectFade = TweenService:Create(effect, fadeInfo, { Transparency = 1 })
				table.insert(labelTweens[label], effectFade)
				effectFade:Play()
			end
		end
		fadeOut:Play()
		return
	end
	label.Text = text
	label.Visible = true
	label.TextTransparency = emphasis and 0.65 or 0.25
	label.TextStrokeTransparency = strokeTransparency == 1 and 1 or 0.8
	local fade = TweenService:Create(label, TweenInfo.new(0.18), {
		TextTransparency = 0,
		TextStrokeTransparency = strokeTransparency,
	})
	table.insert(labelTweens[label], fade)
	fade:Play()
	if stroke then
		stroke.Transparency = 1
		local strokeFade = TweenService:Create(stroke, TweenInfo.new(0.18), { Transparency = labelStrokeTransparency[label] })
		table.insert(labelTweens[label], strokeFade)
		strokeFade:Play()
	end
	if shadow and not noShadow then
		shadow.Transparency = 1
		local shadowFade = TweenService:Create(shadow, TweenInfo.new(0.18), { Transparency = 0.45 })
		table.insert(labelTweens[label], shadowFade)
		shadowFade:Play()
	end
	if scale then
		scale.Scale = emphasis and 0.78 or 0.94
		local pop = TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		table.insert(labelTweens[label], pop)
		pop:Play()
	end
end

player:GetAttributeChangedSignal("EliminatedRound"):Connect(function()
	local current = player:GetAttribute("EliminatedRound")
	if current ~= previousEliminated then
		eliminatedAt = workspace:GetServerTimeNow()
		playLocalSound("Elimination")
	end
	previousEliminated = current
end)

local function placementText(place)
	local suffix = "TH"
	if place % 100 < 11 or place % 100 > 13 then
		local endings = { [1] = "ST", [2] = "ND", [3] = "RD" }
		suffix = endings[place % 10] or suffix
	end
	return "YOU PLACED " .. boldColor(tostring(place) .. suffix, "#FFD65A")
end

local shakes = {}
local previousCamera
local previousShake = CFrame.identity
local function shakeCamera(strong)
	table.insert(shakes, { started = os.clock(), duration = strong and 0.55 or 0.22, strength = strong and 1 or 0.25 })
end

-- 매 프레임 기본 카메라 계산 전 이전 오프셋을 제거하여 흔들림이 누적되지 않습니다.
RunService:BindToRenderStep("HotPotatoShakeReset", Enum.RenderPriority.Camera.Value - 1, function()
	if previousCamera and previousCamera == workspace.CurrentCamera then
		previousCamera.CFrame *= previousShake:Inverse()
	end
	previousCamera = nil
	previousShake = CFrame.identity
end)
RunService:BindToRenderStep("HotPotatoShake", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local now = os.clock()
	local x, y, roll = 0, 0, 0
	for index = #shakes, 1, -1 do
		local shake = shakes[index]
		local age = now - shake.started
		if age >= shake.duration then
			table.remove(shakes, index)
		else
			local envelope = shake.strength * (1 - age / shake.duration) ^ 2
			x += math.sin(age * 83) * 0.45 * envelope
			y += math.sin(age * 107) * 0.3 * envelope
			roll += math.sin(age * 91) * math.rad(2) * envelope
		end
	end
	previousCamera = camera
	previousShake = CFrame.new(x, y, 0) * CFrame.Angles(0, 0, roll)
	camera.CFrame *= previousShake
end)

local panicBubble, panicPanel, panicText, panicShadow
local panicHead, panicSecond
local panicPhrases = { "NOOO!!", "TAKE IT!!", "NOT ME!!", "GET IT AWAY!!", "HELP!!" }
local function clearPanic()
	if panicBubble then panicBubble:Destroy() end
	panicBubble, panicPanel, panicText, panicShadow, panicHead, panicSecond = nil, nil, nil, nil, nil, nil
end

local function updatePanic(now)
	local bomb = workspace:FindFirstChild("HotPotatoBomb")
	local seconds = bomb and math.ceil((bomb:GetAttribute("ExpiresAt") or 0) - now) or 0
	local weld = bomb and bomb:FindFirstChildOfClass("WeldConstraint")
	local character = weld and weld.Part0 and weld.Part0.Parent
	local head = character and character:FindFirstChild("Head")
	if state:GetAttribute("Phase") ~= "Playing" or seconds <= 0 or seconds > Config.PanicSeconds or not head then
		clearPanic()
		return
	end
	if panicHead ~= head then
		clearPanic()
		panicHead = head
		panicBubble = Instance.new("BillboardGui")
		panicBubble.Name = "BombPanic"
		panicBubble.Adornee = head
		panicBubble.Size = UDim2.fromOffset(180, 52)
		panicBubble.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
		panicBubble.AlwaysOnTop = true
		panicBubble.MaxDistance = 100
		panicBubble.Parent = player.PlayerGui
		panicPanel = Instance.new("Frame")
		panicPanel.AnchorPoint = Vector2.new(0.5, 0.5)
		panicPanel.Position = UDim2.fromScale(0.5, 0.5)
		panicPanel.Size = UDim2.fromOffset(148, 30)
		panicPanel.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
		panicPanel.BackgroundTransparency = 1
		panicPanel.BorderSizePixel = 0
		panicPanel.Parent = panicBubble
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = panicPanel
		panicShadow = Instance.new("UIShadow")
		panicShadow.Color = Color3.fromRGB(10, 4, 6)
		panicShadow.BlurRadius = UDim.new(0, 7)
		panicShadow.Offset = UDim2.fromOffset(0, 3)
		panicShadow.Spread = UDim2.fromOffset(4, 4)
		panicShadow.Transparency = 1
		panicShadow.Parent = panicPanel
		panicText = Instance.new("TextLabel")
		panicText.Size = UDim2.fromScale(1, 1)
		panicText.BackgroundTransparency = 1
		panicText.FontFace = status.FontFace
		panicText.TextSize = 16
		panicText.TextColor3 = Color3.fromRGB(255, 215, 205)
		panicText.TextTransparency = 1
		panicText.Parent = panicPanel
		local fade = TweenInfo.new(0.2)
		TweenService:Create(panicPanel, fade, { BackgroundTransparency = 0.18 }):Play()
		TweenService:Create(panicShadow, fade, { Transparency = 0.35 }):Play()
		TweenService:Create(panicText, fade, { TextTransparency = 0 }):Play()
	end
	if seconds ~= panicSecond then
		panicSecond = seconds
		panicText.Text = panicPhrases[(Config.PanicSeconds - seconds) % #panicPhrases + 1]
	end
	panicPanel.Rotation = math.sin(now * 29) * 4 + math.sin(now * 43) * 2
end

-- UI는 Studio의 기존 인스턴스를 갱신하며 서버 시각으로 카운트다운합니다.
local function updateUi()
	local now = workspace:GetServerTimeNow()
	updateMusic(now)
	updatePanic(now)
	local phase = state:GetAttribute("Phase") or "Waiting"
	local remaining = math.max(0, math.ceil((state:GetAttribute("Deadline") or 0) - now))
	local inRound = player:GetAttribute("InRound") == true
	local text = ""
	local announcementText = ""
	local countdownText = ""
	local round = state:GetAttribute("RoundId")
	local place = player:GetAttribute("PlacementRound") == round and player:GetAttribute("RoundPlacement") or nil
	local statusText = "WAITING FOR PLAYERS"
	if phase == "Waiting" then
		statusText = "WAITING FOR PLAYERS"
	elseif phase == "Countdown" then
		statusText = "STARTING IN " .. remaining .. "S"
	elseif phase == "Preparing" then
		statusText = "GET READY!"
	elseif phase == "Ready" then
		statusText = "GET READY!"
		if inRound and remaining > 0 then
			countdownText = boldColor(remaining, "#FFFFFF")
		end
	elseif phase == "Playing" then
		statusText = "ROUND IN PROGRESS"
		if inRound and state:GetAttribute("HolderUserId") == player.UserId then text = "PASS THE BOMB!" end
		local firstHolder = state:GetAttribute("FirstBombHolder") or ""
		if place then
			announcementText = placementText(place)
		elseif firstHolder ~= "" then
			announcementText = "FIRST BOMB: " .. boldColor(firstHolder, "#A8DEFF")
		end
	elseif phase == "Results" then
		statusText = "ROUND OVER"
		local winner = state:GetAttribute("Winner") or ""
		announcementText = winner ~= "" and ("WINNER: " .. boldColor(winner, "#FFD65A"))
			or (boldColor("NO WINNER", "#FFD65A") .. " THIS ROUND")
		if place then announcementText ..= "\n" .. placementText(place) end
	end
	if now - eliminatedAt < Config.EliminationMessageDuration and not inRound then text = "ELIMINATED!" end
	local messageKey = tostring(state:GetAttribute("RoundId")) .. ":" .. phase .. ":" .. text
	if text == "ELIMINATED!" then
		messageKey = tostring(player:GetAttribute("EliminatedRound")) .. ":Eliminated"
	end
	if text ~= "" and messageKey ~= lastMessageKey then
		lastMessageKey = messageKey
		messageExpiresAt = text == "ELIMINATED!" and (eliminatedAt + Config.EliminationMessageDuration)
			or (now + Config.MessageDuration)
		if phase ~= "Ready" and text ~= "ELIMINATED!" then playLocalSound("Notification") end
	elseif text == "" then
		lastMessageKey = ""
	end
	local messageVisible = text ~= "" and now < messageExpiresAt
	setLabel(status, '<b>' .. escapeRichText(statusText) .. '</b>', true, false)
	setLabel(aliveLabel, "PLAYERS LEFT: " .. boldColor(state:GetAttribute("AliveCount") or 0, "#78FF96"), phase == "Preparing" or phase == "Ready" or phase == "Playing", false)
	local messageColor = text == "ELIMINATED!" and "#FF6464" or "#FFDC64"
	local messageRich = text == "PASS THE BOMB!" and ("PASS THE " .. boldColor("BOMB!", messageColor))
		or (text == "ELIMINATED!" and (boldColor("ELIMINATED", messageColor) .. "!") or escapeRichText(text))
	setLabel(message, messageRich, messageVisible, true)
	message.TextColor3 = Color3.new(1, 1, 1)
	setLabel(countdown, countdownText, phase == "Ready" and inRound and remaining > 0, true)
	local announcementKey = tostring(round) .. ":" .. phase .. ":" .. announcementText
	if announcementText ~= "" and announcementKey ~= lastAnnouncementKey then
		lastAnnouncementKey = announcementKey
		announcementExpiresAt = now + Config.MessageDuration
		if phase ~= "Ready" then playLocalSound("Notification") end
	end
	setLabel(announcement, announcementText, announcementText ~= "" and now < announcementExpiresAt, true)
	local cue = phase .. ":" .. remaining
	if cue ~= lastCountdownCue then
		lastCountdownCue = cue
		if remaining > 0 and remaining <= 3 then
			if phase == "Countdown" then playLocalSound("Countdown") end
			if phase == "Ready" and inRound then playLocalSound("Ready") end
		end
	end
	local bomb = workspace:FindFirstChild("HotPotatoBomb")
	local timer = bomb and bomb:FindFirstChild("BombTimer")
	if timer then
		local seconds = math.max(0, (bomb:GetAttribute("ExpiresAt") or 0) - now)
		local scale = timer.TimerLabel:FindFirstChild("PulseScale")
		if scale then scale.Scale = seconds > 0 and seconds <= 5 and (1 + 0.06 * math.sin(now * 10)) or 1 end
	end
end

effects.OnClientEvent:Connect(function(kind, position)
	if kind == "Notice" then
		local menu = player.PlayerGui:FindFirstChild("SubGui")
		local notice = menu and menu:FindFirstChild("MenuNotice")
		if notice then notice:Fire(position) end
		return
	end
	if kind == "Explosion" then
		shakeCamera(true)
		playLocalSound("Explosion")
		local explosion = Instance.new("Explosion")
		explosion.Name = "HotPotatoExplosion"
		explosion.Position = position
		explosion.BlastRadius = 7
		explosion.BlastPressure = 0
		explosion.DestroyJointRadiusPercent = 0
		explosion.ExplosionType = Enum.ExplosionType.NoCraters
		explosion.Parent = workspace
		Debris:AddItem(explosion, 3)
		return
	end
	if kind == "Pass" then shakeCamera(false) end
	local effect = Instance.new("Part")
	effect.Name = "HotPotatoEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 230, 120)
	effect.Anchored = true
	effect.CanCollide, effect.CanTouch, effect.CanQuery = false, false, false
	effect.Size = Vector3.one
	effect.Position = position
	effect.Transparency = 0.4
	effect.Parent = workspace
	TweenService:Create(effect, TweenInfo.new(0.3), { Size = Vector3.one * 3, Transparency = 1 }):Play()
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
