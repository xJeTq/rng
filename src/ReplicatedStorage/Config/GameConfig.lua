local GameConfig = {}

GameConfig.Currencies = {
	Stardust = "Stardust",
	Energy = "Energy",
}

GameConfig.Crystals = {
	Basic = { Cost = 100, EnergyCost = 1 },
	Nova = { Cost = 1000, EnergyCost = 3 },
	Nebula = { Cost = 5000, EnergyCost = 5 },
}

GameConfig.Production = {
	TickSeconds = 5,
	BaseStardustPerTick = 5,
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

return GameConfig
