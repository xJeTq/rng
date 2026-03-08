local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local OpenCrystal = remotes:WaitForChild("OpenCrystal")
local ClaimDailyReward = remotes:WaitForChild("ClaimDailyReward")
local UpgradeHabitat = remotes:WaitForChild("UpgradeHabitat")
local ClaimQuest = remotes:WaitForChild("ClaimQuest")
local ServerAnnouncement = remotes:WaitForChild("ServerAnnouncement")
local DataReady = remotes:WaitForChild("DataReady")

local function toast(message)
	print("[CosmicCritters]", message)
end

local function runTutorial()
	toast("Welcome! Collect a crystal.")
	task.wait(2)
	toast("Open your first crystal.")
	task.wait(2)
	toast("Equip your creature and generate stardust!")
	task.wait(2)
	toast("Upgrade your habitat to unlock more space.")
end

local function openBasicCrystal()
	local result = OpenCrystal:InvokeServer("Basic")
	if result.Ok then
		toast(string.format("You discovered %s (%s)!", result.CreatureName, result.Rarity))
	else
		toast("Could not open crystal: " .. result.Error)
	end
end

local function claimDaily()
	local result = ClaimDailyReward:InvokeServer()
	if result.Ok then
		toast(string.format("Daily claimed! +%d Stardust. Streak: %d", result.Reward, result.Streak))
	else
		toast("Daily unavailable: " .. result.Error)
	end
end


local function claimQuest(questId)
	local result = ClaimQuest:InvokeServer(questId)
	if result.Ok then
		toast(string.format("Quest claimed! +%d Stardust", result.Reward))
	else
		toast("Quest claim failed: " .. tostring(result.Error))
	end
end

local function upgradeHabitat()
	local result = UpgradeHabitat:InvokeServer()
	if result.Ok then
		toast("Habitat upgraded to level " .. tostring(result.Result))
	else
		toast("Habitat upgrade failed: " .. tostring(result.Result))
	end
end

DataReady.OnClientEvent:Connect(function(payload)
	toast("Data loaded. Stardust: " .. tostring(payload.Currencies.Stardust))
	runTutorial()
end)

ServerAnnouncement.OnClientEvent:Connect(function(text)
	toast(text)
end)

-- Replace these with real UI button hookups.
task.delay(4, openBasicCrystal)
task.delay(6, claimDaily)
task.delay(8, upgradeHabitat)
task.delay(10, function() claimQuest("Open3") end)
