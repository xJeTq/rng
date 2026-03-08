local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local AnalyticsService = require(script.Parent.AnalyticsService)

local DATASTORE_NAME = "CosmicCritters_PlayerData_v1"
local defaultData = {
	Currencies = { Stardust = 250, Energy = 10 },
	Creatures = {},
	EquippedCreatureId = nil,
	PityCount = 0,
	Daily = { LastClaimDay = 0, Streak = 0 },
	Quests = {},
	Habitat = { Level = 1, Theme = "Default" },
	Stats = { TotalOpens = 0, RarestTier = "Common" },
}

local profileStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local cache = {}

local DataService = {}

local function deepCopy(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = typeof(v) == "table" and deepCopy(v) or v
	end
	return out
end

function DataService.Get(player)
	return cache[player.UserId]
end

function DataService.Load(player)
	local key = tostring(player.UserId)
	local ok, loaded = pcall(function()
		return profileStore:GetAsync(key)
	end)

	if not ok then
		warn("Data load failed for", player.UserId, loaded)
		loaded = nil
	end

	local data = deepCopy(defaultData)
	if typeof(loaded) == "table" then
		for k, v in pairs(loaded) do
			data[k] = v
		end
	end

	cache[player.UserId] = data
	AnalyticsService.Track(player, "DataLoaded")
	return data
end

function DataService.Save(player)
	local data = cache[player.UserId]
	if not data then
		return true
	end

	local key = tostring(player.UserId)
	local ok, err = pcall(function()
		profileStore:SetAsync(key, data)
	end)

	if not ok then
		warn("Data save failed for", player.UserId, err)
		return false
	end

	AnalyticsService.Track(player, "DataSaved")
	return true
end

function DataService.StartAutoSave(intervalSeconds)
	task.spawn(function()
		while true do
			task.wait(intervalSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				DataService.Save(player)
			end
		end
	end)
end

function DataService.Remove(player)
	cache[player.UserId] = nil
end

return DataService
