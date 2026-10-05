-- 테스트할 설정값은 이 파일에서 변경합니다.
return {
	MinPlayers = 2,
	LobbyCountdown = 10,
	ReadyTime = 3,
	ReadyDelay = 1,
	BombTime = 15,
	NextBombDelay = 1,
	ResultTime = 5,
	WalkSpeed = 20,
	HolderSpeed = 24,
	PassDistance = 4,
	PassCooldown = 0.8,
	CheckInterval = 0.1,
	SpawnSpacing = 7,
	FieldInset = 5,
	FieldHeightOffset = 3.5, -- Field 배치 높이에 추가할 스튜드
	BombForwardOffset = 2,
	BombRotationX = -180,
	HolderAnimationId = "rbxassetid://96785512575883",
	MessageDuration = 3,
	EliminationMessageDuration = 2.5,
	DeathRespawnDelay = 3,
	DeathFadeDelay = 2,
	DeathFadeDuration = 0.6,
	PanicSeconds = 5,
	RewardPopupDuration = 2.5,
	Coins = {
		FirstDelay = 3,
		IntervalMin = 4,
		IntervalMax = 7,
		SpawnOffset = 1,
		Reward = 50,
		SpinSpeed = 120, -- degrees per second, around world Y
		FadeTime = 0.3,
		PickupSound = "button.wav",
		PickupVolume = 0.5,
		PickupPitch = 1.5,
	},
	Menus = {
		TweenTime = 0.22,
		SoundVolume = 0.35,
		HoverSound = "clickfast.wav",
		ClickSound = "button.wav",
		PopupSound = "pageturn.wav",
		UseSound = "swoosh.wav",
		CloseSound = "switch.wav",
	},
	VIP = {
		GamePassId = 0, -- 실제 패스 ID를 넣으면 Roblox 구매창을 사용합니다.
		StudioSamplePurchase = true, -- 무료 샘플은 Studio 세션에서만 적용합니다.
	},
	SkillSounds = {
		DoubleJump = { Name = "Short spring sound.wav", Volume = 0.3, Speed = 1.12 },
		Dash = { Name = "swoosh.wav", Volume = 0.4, Speed = 1.15 },
		Push = { Name = "swordslash.wav", Volume = 0.28, Speed = 1.1 },
		PushHit = { Name = "hit.wav", Volume = 0.35 },
		Banana = { Name = "Kerplunk.wav", Volume = 0.28, Speed = 1.2 },
		BananaHit = { Name = "splat.wav", Volume = 0.35, Speed = 1.05 },
		SwapWarning = { Name = "SWITCH3.wav", Volume = 0.25, Speed = 0.85 },
		Swap = { Name = "unsheath.wav", Volume = 0.32, Speed = 1.3 },
	},
	Rewards = {
		Pass = 25,
		Placements = { 400, 250, 100 },
	},
	-- Enabled가 true면 Studio와 실제 서버 모두 부족한 참가자를 Dummy로 채웁니다.
	StudioTesting = {
		Enabled = true,
		DummyName = "Dummy", -- ReplicatedStorage의 원본 모델 이름
	},
	-- Classic Sound Pack > Songs의 기존 곡을 순서대로 반복합니다.
	Bgm = {
		Volume = 0.1,
		FadeTime = 0.6,
		LoadTimeout = 8,
		Lobby = {
			"Tobu - Hope",
			"Daniel Bautista  - Opening Theme (Music for a Film)",
			"Daniel Bautista  - Intro",
		},
		InGame = {
			"Tobu - Infectious",
			"Noisestorm - Crab Rave",
			"Daniel Bautista  - Gothic",
		},
	},
	Sounds = {
		Start = "switch.wav",
		Countdown = "clickfast.wav",
		Ready = "electronicpingshort.wav",
		Elimination = "uuhhh.mp3",
		Victory = "victory.wav",
		NoWinner = "bass.wav",
		Pass = "button.wav",
		Warning = "electronicpingshort.wav",
		Explosion = "Rocket shot.wav",
		Notification = "electronicpingshort.wav",
		ObbyComplete = "victory.wav",
	},
}
