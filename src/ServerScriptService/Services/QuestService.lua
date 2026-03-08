local QuestService = {}

local DAILY_QUESTS = {
	{ Id = "Open3", Type = "OpenCrystals", Goal = 3, Reward = 100 },
	{ Id = "Earn500", Type = "EarnStardust", Goal = 500, Reward = 150 },
}

function QuestService.EnsureDailyQuests(data)
	if not data.Quests or #data.Quests == 0 then
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
	for _, quest in ipairs(data.Quests) do
		if quest.Type == questType and not quest.Claimed then
			quest.Progress = math.min(quest.Progress + amount, quest.Goal)
		end
	end
end

return QuestService
