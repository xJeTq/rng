local DataService = require(script.Parent.DataService)

local TradingService = {}

local activeTrades = {}
local nextTradeId = 1

function TradingService.CreateTrade(fromPlayer, toPlayer, offeredCreatureIds)
	local fromData = DataService.Get(fromPlayer)
	local toData = DataService.Get(toPlayer)
	if not fromData or not toData then
		return false, "NoData"
	end

	local tradeId = nextTradeId
	nextTradeId += 1

	activeTrades[tradeId] = {
		From = fromPlayer.UserId,
		To = toPlayer.UserId,
		Offered = offeredCreatureIds,
		Accepted = false,
	}

	return true, tradeId
end

function TradingService.AcceptTrade(player, tradeId)
	local trade = activeTrades[tradeId]
	if not trade then
		return false, "TradeNotFound"
	end
	if trade.To ~= player.UserId then
		return false, "Unauthorized"
	end

	trade.Accepted = true
	activeTrades[tradeId] = nil
	return true, "TradeCompleted"
end

return TradingService
