local RarityConfig = {}

RarityConfig.Tiers = {
	{ Name = "Common", Weight = 60, Color = Color3.fromRGB(201, 255, 210), Multiplier = 1 },
	{ Name = "Uncommon", Weight = 25, Color = Color3.fromRGB(130, 240, 255), Multiplier = 1.5 },
	{ Name = "Rare", Weight = 10, Color = Color3.fromRGB(115, 165, 255), Multiplier = 2.25 },
	{ Name = "Epic", Weight = 4, Color = Color3.fromRGB(189, 120, 255), Multiplier = 3.5 },
	{ Name = "Legendary", Weight = 0.9, Color = Color3.fromRGB(255, 205, 105), Multiplier = 7 },
	{ Name = "Cosmic", Weight = 0.1, Color = Color3.fromRGB(255, 120, 220), Multiplier = 20 },
}

RarityConfig.Pity = {
	Threshold = 30,
	TargetTier = "Legendary",
	PerRollBonus = 0.15,
	MaxBonus = 5,
}

return RarityConfig
