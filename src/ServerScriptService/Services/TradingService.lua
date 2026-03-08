local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local TradingService = {}

local TRADE_EXPIRY_SECONDS = 120

local activeTrades = {}
local nextTradeId = 1

local function indexCreaturesById(creatures)
	local index = {}
	for i, creature in ipairs(creatures) do
		index[creature.Id] = i
	end
	return index
end

local function removeCreatureSet(creatures, ids)
	local removeLookup = {}
	for _, id in ipairs(ids) do
		removeLookup[id] = true
	end

	local kept = {}
	for _, creature in ipairs(creatures) do
		if not removeLookup[creature.Id] then
			table.insert(kept, creature)
		end
	end
	return kept
end

local function isTradeExpired(trade)
	return os.time() - trade.CreatedAt >= TRADE_EXPIRY_SECONDS
end

function TradingService.CreateTrade(fromPlayer, toPlayer, offeredCreatureIds)
	local fromData = DataService.Get(fromPlayer)
	local toData = DataService.Get(toPlayer)
	if not fromData or not toData then
		return false, "NoData"
	end

	if fromPlayer.UserId == toPlayer.UserId then
		return false, "CannotTradeSelf"
	end

	if #offeredCreatureIds == 0 then
		return false, "NoOffer"
	end

	local ownerIndex = indexCreaturesById(fromData.Creatures)
	local dedupe = {}
	for _, creatureId in ipairs(offeredCreatureIds) do
		if typeof(creatureId) ~= "string" then
			return false, "InvalidCreatureId"
		end
		if dedupe[creatureId] then
			return false, "DuplicateCreature"
		end
		dedupe[creatureId] = true

		if not ownerIndex[creatureId] then
			return false, "NotOwned"
		end
	end

	local tradeId = nextTradeId
	nextTradeId += 1

	activeTrades[tradeId] = {
		From = fromPlayer.UserId,
		To = toPlayer.UserId,
		Offered = offeredCreatureIds,
		CreatedAt = os.time(),
	}

	return true, tradeId
end

function TradingService.AcceptTrade(player, tradeId)
	local trade = activeTrades[tradeId]
	if not trade then
		return false, "TradeNotFound"
	end

	if isTradeExpired(trade) then
		activeTrades[tradeId] = nil
		return false, "TradeExpired"
	end

	if trade.To ~= player.UserId then
		return false, "Unauthorized"
	end

	local fromPlayer = Players:GetPlayerByUserId(trade.From)
	if not fromPlayer then
		activeTrades[tradeId] = nil
		return false, "InitiatorOffline"
	end

	local fromData = DataService.Get(fromPlayer)
	local toData = DataService.Get(player)
	if not fromData or not toData then
		activeTrades[tradeId] = nil
		return false, "NoData"
	end

	local ownerIndex = indexCreaturesById(fromData.Creatures)
	local transferred = {}
	for _, creatureId in ipairs(trade.Offered) do
		local idx = ownerIndex[creatureId]
		if not idx then
			activeTrades[tradeId] = nil
			return false, "OfferNoLongerValid"
		end
		table.insert(transferred, fromData.Creatures[idx])
	end

	fromData.Creatures = removeCreatureSet(fromData.Creatures, trade.Offered)
	for _, creature in ipairs(transferred) do
		table.insert(toData.Creatures, creature)
	end

	activeTrades[tradeId] = nil
	return true, { Message = "TradeCompleted", InitiatorUserId = trade.From }
end

return TradingService
