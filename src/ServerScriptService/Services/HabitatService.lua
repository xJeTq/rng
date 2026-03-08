local CurrencyService = require(script.Parent.CurrencyService)
local GameConfig = require(game.ReplicatedStorage.Config.GameConfig)
local DataService = require(script.Parent.DataService)

local HabitatService = {}

function HabitatService.Upgrade(player)
	local data = DataService.Get(player)
	if not data then
		return false, "NoData"
	end

	local level = data.Habitat.Level
	local cost = level * 250
	if not CurrencyService.TrySpend(player, GameConfig.Currencies.Stardust, cost) then
		return false, "NotEnoughStardust"
	end

	data.Habitat.Level += 1
	return true, data.Habitat.Level
end

return HabitatService
