local CreatureCatalog = {}

CreatureCatalog.Definitions = {
	StarBunny = {
		DisplayName = "Star Bunny",
		Rarity = "Common",
		BaseProduction = 1,
		Visual = { Glow = false, Trail = false, Particle = "" },
	},
	NebulaSlime = {
		DisplayName = "Nebula Slime",
		Rarity = "Uncommon",
		BaseProduction = 2,
		Visual = { Glow = true, Trail = false, Particle = "Sparkle" },
	},
	MeteorTurtle = {
		DisplayName = "Meteor Turtle",
		Rarity = "Rare",
		BaseProduction = 4,
		Visual = { Glow = true, Trail = true, Particle = "RockBurst" },
	},
	CometFox = {
		DisplayName = "Comet Fox",
		Rarity = "Epic",
		BaseProduction = 6,
		Visual = { Glow = true, Trail = true, Particle = "CometTail" },
	},
	GalaxyDragon = {
		DisplayName = "Galaxy Dragon",
		Rarity = "Legendary",
		BaseProduction = 12,
		Visual = { Glow = true, Trail = true, Particle = "GalaxyBurst" },
	},
	BlackHoleCat = {
		DisplayName = "Black Hole Cat",
		Rarity = "Cosmic",
		BaseProduction = 30,
		Visual = { Glow = true, Trail = true, Particle = "VoidPulse" },
	},
}

CreatureCatalog.ByRarity = {
	Common = { "StarBunny" },
	Uncommon = { "NebulaSlime" },
	Rare = { "MeteorTurtle" },
	Epic = { "CometFox" },
	Legendary = { "GalaxyDragon" },
	Cosmic = { "BlackHoleCat" },
}

return CreatureCatalog
