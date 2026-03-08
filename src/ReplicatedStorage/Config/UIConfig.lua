local UIConfig = {}

UIConfig.Theme = {
	Background = Color3.fromRGB(17, 24, 46),
	Panel = Color3.fromRGB(33, 43, 76),
	PanelAlt = Color3.fromRGB(47, 60, 103),
	Primary = Color3.fromRGB(76, 190, 255),
	Success = Color3.fromRGB(103, 232, 153),
	Warning = Color3.fromRGB(255, 208, 122),
	Danger = Color3.fromRGB(255, 125, 145),
	Text = Color3.fromRGB(242, 246, 255),
	SubText = Color3.fromRGB(177, 193, 230),
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
	ButtonClick = "rbxassetid://9118828564",
	CrystalOpen = "rbxassetid://9120292229",
	RarityReveal = "rbxassetid://9120286810",
	QuestComplete = "rbxassetid://9120107958",
	TradeConfirm = "rbxassetid://9120020965",
	DailyClaim = "rbxassetid://9119913120",
	PurchaseSuccess = "rbxassetid://9120009625",
	RareAnnouncement = "rbxassetid://9119965949",
}

return UIConfig
