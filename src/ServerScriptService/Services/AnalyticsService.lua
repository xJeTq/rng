local AnalyticsService = {}

local buffer = {}
local counters = {
	RarePullsByTier = {},
	EventCounts = {},
}

local function bumpCount(map, key)
	map[key] = (map[key] or 0) + 1
end

function AnalyticsService.Track(player, eventName, payload)
	local entry = {
		UserId = player and player.UserId or 0,
		Event = eventName,
		Payload = payload or {},
		Timestamp = os.time(),
	}
	table.insert(buffer, entry)
	bumpCount(counters.EventCounts, eventName)

	if payload and payload.Rarity then
		bumpCount(counters.RarePullsByTier, payload.Rarity)
	end

	if #buffer > 500 then
		table.remove(buffer, 1)
	end
end

function AnalyticsService.GetBuffer()
	return buffer
end

function AnalyticsService.GetCounters()
	return counters
end

return AnalyticsService
