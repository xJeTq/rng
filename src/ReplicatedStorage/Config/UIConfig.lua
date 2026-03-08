local UIConfig = {}

UIConfig.Theme = {
	Background = Color3.fromRGB(17, 24, 46),
	Panel = Color3.fromRGB(33, 43, 76),
	PanelAlt = Color3.fromRGB(47, 60, 103),
	PanelSoft = Color3.fromRGB(62, 78, 125),
	Primary = Color3.fromRGB(76, 190, 255),
	Success = Color3.fromRGB(103, 232, 153),
	Warning = Color3.fromRGB(255, 208, 122),
	Danger = Color3.fromRGB(255, 125, 145),
	Text = Color3.fromRGB(242, 246, 255),
	SubText = Color3.fromRGB(177, 193, 230),
	Rarity = {
		Common = Color3.fromRGB(184, 229, 197),
		Uncommon = Color3.fromRGB(137, 229, 255),
		Rare = Color3.fromRGB(126, 167, 255),
		Epic = Color3.fromRGB(198, 136, 255),
		Legendary = Color3.fromRGB(255, 210, 121),
		Cosmic = Color3.fromRGB(255, 127, 230),
	},
}

UIConfig.Mobile = {
	ButtonHeight = 64,
	LargeButtonHeight = 78,
	CornerRadius = 16,
	PanelPadding = 12,
	MinTapSize = 52,
}

UIConfig.GameFeel = {
	RareShakeDuration = 0.35,
	RareShakeStrength = 0.25,
	HeavyEffectsOnLowEnd = false,
}

UIConfig.Audio = {
	MasterVolume = 0.45,
	SFX = {
		ButtonClick = { Id = "rbxassetid://9118828564", Volume = 0.25 },
		PanelOpen = { Id = "rbxassetid://12222225", Volume = 0.2 },
		PanelClose = { Id = "rbxassetid://12222216", Volume = 0.2 },
		CrystalOpen = { Id = "rbxassetid://9120292229", Volume = 0.45 },
		QuestComplete = { Id = "rbxassetid://9120107958", Volume = 0.45 },
		TradeConfirm = { Id = "rbxassetid://9120020965", Volume = 0.42 },
		DailyClaim = { Id = "rbxassetid://9119913120", Volume = 0.45 },
		PurchaseSuccess = { Id = "rbxassetid://9120009625", Volume = 0.45 },
		PurchaseCancel = { Id = "rbxassetid://12222152", Volume = 0.3 },
		RareAnnouncement = { Id = "rbxassetid://9119965949", Volume = 0.45 },
	},
	RarityRevealByTier = {
		Common = { Id = "rbxassetid://9120286810", Volume = 0.25 },
		Uncommon = { Id = "rbxassetid://9120286810", Volume = 0.28 },
		Rare = { Id = "rbxassetid://9120286810", Volume = 0.35 },
		Epic = { Id = "rbxassetid://9120286810", Volume = 0.45 },
		Legendary = { Id = "rbxassetid://9120286810", Volume = 0.55 },
		Cosmic = { Id = "rbxassetid://9120286810", Volume = 0.65 },
	},
}

return UIConfig
