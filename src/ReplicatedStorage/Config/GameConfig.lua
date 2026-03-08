local GameConfig = {}

GameConfig.Currencies = {
	Stardust = "Stardust",
	Energy = "Energy",
}

GameConfig.Crystals = {
	Basic = { Cost = 75, EnergyCost = 1 },
	Nova = { Cost = 500, EnergyCost = 3 },
	Nebula = { Cost = 2600, EnergyCost = 5 },
}

GameConfig.Production = {
	TickSeconds = 4,
	BaseStardustPerTick = 6,
}

GameConfig.Monetization = {
	DeveloperProducts = {
		CrystalBundle = 0,
		LuckBoostPotion = 0,
		InstantOpen = 0,
		HabitatUpgrade = 0,
		EnergyRefill = 0,
	},
	GamePasses = {
		VIPHabitat = 0,
		AutoOpener = 0,
		ExtraCreatureSlots = 0,
		DoubleStardust = 0,
		ExclusiveThemes = 0,
	},
}

GameConfig.Limits = {
	MaxTradeSlots = 6,
	BaseCreatureSlots = 50,
}

GameConfig.Moderation = {
	ReportCategories = { "Scam", "Bully", "BadWords", "Inappropriate", "Other" },
}

return GameConfig
