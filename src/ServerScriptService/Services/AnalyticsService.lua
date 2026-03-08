local AnalyticsService = {}

local buffer = {}

function AnalyticsService.Track(player, eventName, payload)
	table.insert(buffer, {
		UserId = player and player.UserId or 0,
		Event = eventName,
		Payload = payload or {},
		Timestamp = os.time(),
	})

	if #buffer > 200 then
		table.remove(buffer, 1)
	end
end

function AnalyticsService.GetBuffer()
	return buffer
end

return AnalyticsService
