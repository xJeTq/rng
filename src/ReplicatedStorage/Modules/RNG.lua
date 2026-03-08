local RarityConfig = require(script.Parent.Parent.Config.RarityConfig)

local RNG = {}

local function cloneTiers()
	local copy = {}
	for _, tier in ipairs(RarityConfig.Tiers) do
		table.insert(copy, {
			Name = tier.Name,
			Weight = tier.Weight,
			Color = tier.Color,
			Multiplier = tier.Multiplier,
		})
	end
	return copy
end

function RNG.RollTier(pityCount)
	local tiers = cloneTiers()
	local pity = RarityConfig.Pity

	if pityCount >= pity.Threshold then
		local bonusRolls = math.min(pityCount - pity.Threshold + 1, math.floor(pity.MaxBonus / pity.PerRollBonus))
		local bonus = bonusRolls * pity.PerRollBonus
		for _, tier in ipairs(tiers) do
			if tier.Name == pity.TargetTier then
				tier.Weight += bonus
			end
		end
	end

	local totalWeight = 0
	for _, tier in ipairs(tiers) do
		totalWeight += tier.Weight
	end

	local roll = math.random() * totalWeight
	local running = 0
	for _, tier in ipairs(tiers) do
		running += tier.Weight
		if roll <= running then
			return tier.Name
		end
	end

	return "Common"
end

return RNG
