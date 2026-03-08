local QuestService = {}

local DAILY_QUESTS = {
	{ Id = "Open3", Type = "OpenCrystals", Goal = 3, Reward = 160 },
	{ Id = "Earn400", Type = "EarnStardust", Goal = 400, Reward = 220 },
}

local function getCurrentDay()
	return math.floor(os.time() / 86400)
end

function QuestService.EnsureDailyQuests(data)
	local today = getCurrentDay()
	if data.QuestDay ~= today then
		data.QuestDay = today
		data.Quests = {}
		for _, quest in ipairs(DAILY_QUESTS) do
			table.insert(data.Quests, {
				Id = quest.Id,
				Type = quest.Type,
				Goal = quest.Goal,
				Progress = 0,
				Reward = quest.Reward,
				Claimed = false,
			})
		end
	end
end

function QuestService.Progress(data, questType, amount)
	if typeof(data.Quests) ~= "table" then
		return
	end

	for _, quest in ipairs(data.Quests) do
		if quest.Type == questType and not quest.Claimed then
			quest.Progress = math.min(quest.Progress + amount, quest.Goal)
		end
	end
end

function QuestService.Claim(data, questId)
	for _, quest in ipairs(data.Quests) do
		if quest.Id == questId then
			if quest.Claimed then
				return false, "AlreadyClaimed", 0
			end

			if quest.Progress < quest.Goal then
				return false, "NotComplete", 0
			end

			quest.Claimed = true
			return true, "Claimed", quest.Reward
		end
	end

	return false, "QuestNotFound", 0
end

return QuestService
