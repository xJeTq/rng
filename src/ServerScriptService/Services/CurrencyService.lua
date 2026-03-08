local GameConfig = require(game.ReplicatedStorage.Config.GameConfig)
local DataService = require(script.Parent.DataService)

local CurrencyService = {}

function CurrencyService.Get(player, currency)
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	return data.Currencies[currency] or 0
end

function CurrencyService.Add(player, currency, amount)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	data.Currencies[currency] = (data.Currencies[currency] or 0) + amount
	return true
end

function CurrencyService.TrySpend(player, currency, amount)
	local current = CurrencyService.Get(player, currency)
	if current < amount then
		return false
	end
	return CurrencyService.Add(player, currency, -amount)
end

function CurrencyService.StartPassiveIncome(players)
	task.spawn(function()
		while true do
			task.wait(GameConfig.Production.TickSeconds)
			for _, player in ipairs(players:GetPlayers()) do
				local data = DataService.Get(player)
				if data then
					local rate = GameConfig.Production.BaseStardustPerTick
					for _, creature in ipairs(data.Creatures) do
						rate += creature.Production or 0
					end
					CurrencyService.Add(player, GameConfig.Currencies.Stardust, rate)
				end
			end
		end
	end)
end

return CurrencyService
