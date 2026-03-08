local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local RNG = require(ReplicatedStorage.Modules.RNG)
local CreatureCatalog = require(ReplicatedStorage.Modules.CreatureCatalog)

local DataService = require(script.Services.DataService)
local CurrencyService = require(script.Services.CurrencyService)
local QuestService = require(script.Services.QuestService)
local TradingService = require(script.Services.TradingService)
local HabitatService = require(script.Services.HabitatService)
local MonetizationService = require(script.Services.MonetizationService)
local AnalyticsService = require(script.Services.AnalyticsService)
local AntiExploitService = require(script.Services.AntiExploitService)

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function ensureRemote(name, className)
	local existing = remotes:FindFirstChild(name)
	if existing then
		return existing
	end
	local obj = Instance.new(className)
	obj.Name = name
	obj.Parent = remotes
	return obj
end

local OpenCrystal = ensureRemote("OpenCrystal", "RemoteFunction")
local ClaimDailyReward = ensureRemote("ClaimDailyReward", "RemoteFunction")
local CreateTrade = ensureRemote("CreateTrade", "RemoteFunction")
local AcceptTrade = ensureRemote("AcceptTrade", "RemoteFunction")
local UpgradeHabitat = ensureRemote("UpgradeHabitat", "RemoteFunction")
local ClaimQuest = ensureRemote("ClaimQuest", "RemoteFunction")
local ServerAnnouncement = ensureRemote("ServerAnnouncement", "RemoteEvent")
local DataReady = ensureRemote("DataReady", "RemoteEvent")

local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Cosmic = 6 }

local function createLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stardust = Instance.new("IntValue")
	stardust.Name = "Stardust"
	stardust.Parent = leaderstats
	stardust.Value = data.Currencies.Stardust

	local discovered = Instance.new("IntValue")
	discovered.Name = "Discovered"
	discovered.Parent = leaderstats
	discovered.Value = #data.Creatures
end

local function syncLeaderstats(player)
	local data = DataService.Get(player)
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	leaderstats.Stardust.Value = data.Currencies.Stardust
	leaderstats.Discovered.Value = #data.Creatures
end

local function ensureQuestState(data)
	QuestService.EnsureDailyQuests(data)
end

local function getMaxCreatureSlots(player)
	local base = GameConfig.Limits.BaseCreatureSlots
	if MonetizationService.PlayerHasPass(player, "ExtraCreatureSlots") then
		return base + 50
	end
	return base
end

local function grantCreature(player, data, rarity)
	local maxSlots = getMaxCreatureSlots(player)
	if #data.Creatures >= maxSlots then
		return nil, nil, "CreatureStorageFull"
	end

	local pool = CreatureCatalog.ByRarity[rarity]
	local creatureId = pool[math.random(1, #pool)]
	local def = CreatureCatalog.Definitions[creatureId]
	local instanceId = string.format("%d_%d", os.time(), math.random(1000, 9999))

	table.insert(data.Creatures, {
		Id = instanceId,
		CatalogId = creatureId,
		Rarity = rarity,
		Production = def.BaseProduction,
		ObtainedAt = os.time(),
	})

	if rarityOrder[rarity] > rarityOrder[data.Stats.RarestTier] then
		data.Stats.RarestTier = rarity
	end

	if rarity == "Legendary" or rarity == "Cosmic" then
		ServerAnnouncement:FireAllClients(string.format("🌟 %s discovered a %s %s!", player.Name, string.upper(rarity), def.DisplayName))
	end

	return creatureId, def, nil
end

OpenCrystal.OnServerInvoke = function(player, crystalType)
	if not AntiExploitService.WithinRateLimit(player, "OpenCrystal", 0.2) then
		return { Ok = false, Error = "RateLimited" }
	end

	local data = DataService.Get(player)
	if not data then
		return { Ok = false, Error = "NoData" }
	end
	ensureQuestState(data)

	local selectedType = crystalType or "Basic"
	local crystal = GameConfig.Crystals[selectedType]
	if not crystal then
		return { Ok = false, Error = "InvalidCrystal" }
	end

	if not CurrencyService.TrySpend(player, GameConfig.Currencies.Stardust, crystal.Cost) then
		return { Ok = false, Error = "NotEnoughStardust" }
	end

	if not CurrencyService.TrySpend(player, GameConfig.Currencies.Energy, crystal.EnergyCost) then
		CurrencyService.Add(player, GameConfig.Currencies.Stardust, crystal.Cost)
		return { Ok = false, Error = "NotEnoughEnergy" }
	end

	local rarity = RNG.RollTier(data.PityCount)
	if rarity == "Legendary" or rarity == "Cosmic" then
		data.PityCount = 0
	else
		data.PityCount += 1
	end

	local creatureId, creatureDef, grantError = grantCreature(player, data, rarity)
	if grantError then
		CurrencyService.Add(player, GameConfig.Currencies.Stardust, crystal.Cost)
		CurrencyService.Add(player, GameConfig.Currencies.Energy, crystal.EnergyCost)
		return { Ok = false, Error = grantError }
	end

	data.Stats.TotalOpens += 1
	QuestService.Progress(data, "OpenCrystals", 1)
	AnalyticsService.Track(player, "CrystalOpened", { Rarity = rarity, CrystalType = selectedType })
	syncLeaderstats(player)

	return {
		Ok = true,
		Rarity = rarity,
		CreatureId = creatureId,
		CreatureName = creatureDef.DisplayName,
		PityCount = data.PityCount,
	}
end

ClaimDailyReward.OnServerInvoke = function(player)
	if not AntiExploitService.WithinRateLimit(player, "ClaimDailyReward", 1) then
		return { Ok = false, Error = "RateLimited" }
	end

	local data = DataService.Get(player)
	if not data then
		return { Ok = false, Error = "NoData" }
	end
	ensureQuestState(data)

	local day = math.floor(os.time() / 86400)
	if data.Daily.LastClaimDay == day then
		return { Ok = false, Error = "AlreadyClaimed" }
	end

	if data.Daily.LastClaimDay == day - 1 then
		data.Daily.Streak += 1
	else
		data.Daily.Streak = 1
	end

	data.Daily.LastClaimDay = day
	local reward = 100 + (data.Daily.Streak * 25)
	CurrencyService.Add(player, GameConfig.Currencies.Stardust, reward)
	syncLeaderstats(player)

	return { Ok = true, Reward = reward, Streak = data.Daily.Streak }
end

ClaimQuest.OnServerInvoke = function(player, questId)
	if not AntiExploitService.WithinRateLimit(player, "ClaimQuest", 0.5) then
		return { Ok = false, Error = "RateLimited" }
	end
	if typeof(questId) ~= "string" then
		return { Ok = false, Error = "BadRequest" }
	end

	local data = DataService.Get(player)
	if not data then
		return { Ok = false, Error = "NoData" }
	end
	ensureQuestState(data)

	local ok, result, reward = QuestService.Claim(data, questId)
	if not ok then
		return { Ok = false, Error = result }
	end

	CurrencyService.Add(player, GameConfig.Currencies.Stardust, reward)
	syncLeaderstats(player)
	return { Ok = true, Reward = reward }
end

CreateTrade.OnServerInvoke = function(player, targetUserId, offeredCreatureIds)
	if not AntiExploitService.WithinRateLimit(player, "CreateTrade", 0.5) then
		return { Ok = false, Error = "RateLimited" }
	end
	if typeof(targetUserId) ~= "number" or typeof(offeredCreatureIds) ~= "table" then
		return { Ok = false, Error = "BadRequest" }
	end

	if #offeredCreatureIds > GameConfig.Limits.MaxTradeSlots then
		return { Ok = false, Error = "TooManyTradeItems" }
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return { Ok = false, Error = "TargetOffline" }
	end

	local ok, tradeIdOrError = TradingService.CreateTrade(player, targetPlayer, offeredCreatureIds)
	if not ok then
		return { Ok = false, Error = tradeIdOrError }
	end

	return { Ok = true, TradeId = tradeIdOrError }
end

AcceptTrade.OnServerInvoke = function(player, tradeId)
	if not AntiExploitService.WithinRateLimit(player, "AcceptTrade", 0.5) then
		return { Ok = false, Error = "RateLimited" }
	end
	if typeof(tradeId) ~= "number" then
		return { Ok = false, Error = "BadRequest" }
	end

	local ok, result = TradingService.AcceptTrade(player, tradeId)
	if ok then
		syncLeaderstats(player)
		local target = Players:GetPlayerByUserId(result.InitiatorUserId)
		if target then
			syncLeaderstats(target)
		end
	end
	return { Ok = ok, Result = result }
end

UpgradeHabitat.OnServerInvoke = function(player)
	if not AntiExploitService.WithinRateLimit(player, "UpgradeHabitat", 0.5) then
		return { Ok = false, Error = "RateLimited" }
	end

	local ok, result = HabitatService.Upgrade(player)
	if ok then
		syncLeaderstats(player)
	end
	return { Ok = ok, Result = result }
end

Players.PlayerAdded:Connect(function(player)
	local data = DataService.Load(player)
	ensureQuestState(data)
	createLeaderstats(player, data)
	DataReady:FireClient(player, {
		Currencies = data.Currencies,
		CreatureCount = #data.Creatures,
		HabitatLevel = data.Habitat.Level,
		Quests = data.Quests,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.Save(player)
	DataService.Remove(player)
end)

game:BindToClose(function()
	DataService.SaveAll()
	task.wait(2)
end)

DataService.StartAutoSave(60)
CurrencyService.StartPassiveIncome(Players)
MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt
