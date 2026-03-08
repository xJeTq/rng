local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local UIConfig = require(ReplicatedStorage.Config.UIConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local OpenCrystal = remotes:WaitForChild("OpenCrystal")
local ClaimDailyReward = remotes:WaitForChild("ClaimDailyReward")
local UpgradeHabitat = remotes:WaitForChild("UpgradeHabitat")
local ClaimQuest = remotes:WaitForChild("ClaimQuest")
local CreateTrade = remotes:WaitForChild("CreateTrade")
local AcceptTrade = remotes:WaitForChild("AcceptTrade")
local GetSocialSnapshot = remotes:WaitForChild("GetSocialSnapshot")
local GetCreatureInventory = remotes:WaitForChild("GetCreatureInventory")
local SetFavoriteCreature = remotes:WaitForChild("SetFavoriteCreature")
local VisitHabitat = remotes:WaitForChild("VisitHabitat")
local TrackClientEvent = remotes:WaitForChild("TrackClientEvent")

local ServerAnnouncement = remotes:WaitForChild("ServerAnnouncement")
local DataReady = remotes:WaitForChild("DataReady")

local state = {
	Currencies = { Stardust = 0, Energy = 0 },
	Quests = {},
	HabitatLevel = 1,
	Collection = { Unlocked = 0, Total = 0, Percent = 0 },
	FavoriteCreatureId = nil,
	Creatures = {},
	SocialPlayers = {},
	TutorialDone = false,
	ActivePanel = nil,
	Trade = {
		Stage = "idle",
		Target = nil,
		TradeId = nil,
		Offer = {},
		ExpireAt = 0,
		Locked = false,
	},
	Milestones = {
		FirstCrystalOpened = false,
		FirstQuestClaimed = false,
		FirstShopOpen = false,
		FirstCreatureEquipped = false,
	},
}

local rootGui
local panels = {}
local toastHolder
local objectiveLabel
local stardustLabel
local energyLabel
local collectionLabel
local tutorialArrow
local blockedInput = false

local function make(className, props, children)
	local obj = Instance.new(className)
	for key, value in pairs(props or {}) do
		obj[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	return obj
end

local function track(eventName, payload)
	pcall(function()
		TrackClientEvent:InvokeServer(eventName, payload or {})
	end)
end

local function playSfx(key, opts)
	opts = opts or {}
	local cfg = UIConfig.Audio.SFX[key]
	if not cfg then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = cfg.Id
	s.Volume = (cfg.Volume or 0.4) * (UIConfig.Audio.MasterVolume or 0.45)
	s.PlaybackSpeed = opts.PlaybackSpeed or 1
	s.Parent = SoundService
	s:Play()
	task.delay(2, function()
		s:Destroy()
	end)
end

local function playRaritySfx(rarity)
	local cfg = UIConfig.Audio.RarityRevealByTier[rarity] or UIConfig.Audio.RarityRevealByTier.Common
	local s = Instance.new("Sound")
	s.SoundId = cfg.Id
	s.Volume = (cfg.Volume or 0.3) * (UIConfig.Audio.MasterVolume or 0.45)
	s.Parent = SoundService
	s:Play()
	task.delay(2, function()
		s:Destroy()
	end)
end

local function toast(message, tone)
	local color = UIConfig.Theme.PanelSoft
	if tone == "success" then
		color = UIConfig.Theme.Success
	elseif tone == "warning" then
		color = UIConfig.Theme.Warning
	elseif tone == "danger" then
		color = UIConfig.Theme.Danger
	end

	local item = make("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 10) }),
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = UIConfig.Theme.Text,
			Text = message,
		})
	})
	item.Parent = toastHolder
	item.BackgroundTransparency = 1
	TweenService:Create(item, TweenInfo.new(0.18), { BackgroundTransparency = 0.08 }):Play()
	task.delay(2.6, function()
		if item.Parent then
			TweenService:Create(item, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
			task.wait(0.2)
			item:Destroy()
		end
	end)
end

local function formatShort(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local function updateHud()
	if stardustLabel then
		stardustLabel.Text = "✨ " .. formatShort(state.Currencies.Stardust or 0)
	end
	if energyLabel then
		energyLabel.Text = "🔋 " .. tostring(state.Currencies.Energy or 0)
	end
	if collectionLabel then
		collectionLabel.Text = string.format("Collection %d/%d (%d%%)", state.Collection.Unlocked or 0, state.Collection.Total or 0, state.Collection.Percent or 0)
	end
end

local function closeAllPanels()
	for _, panel in pairs(panels) do
		panel.Visible = false
	end
	state.ActivePanel = nil
	playSfx("PanelClose")
end

local function openPanel(key)
	if blockedInput then
		return
	end
	if state.ActivePanel == key then
		closeAllPanels()
		return
	end
	closeAllPanels()
	local panel = panels[key]
	if panel then
		panel.Visible = true
		state.ActivePanel = key
		playSfx("PanelOpen")
		if key == "Shop" and not state.Milestones.FirstShopOpen then
			state.Milestones.FirstShopOpen = true
			track("FirstShopOpen")
		end
	end
end

local function rarityColor(rarity)
	return UIConfig.Theme.Rarity[rarity] or UIConfig.Theme.PanelSoft
end

local function makePanel(name, title)
	local panel = make("Frame", {
		Name = name,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromScale(0.9, 0.78),
		BackgroundColor3 = UIConfig.Theme.Panel,
		BorderSizePixel = 0,
		Parent = rootGui,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 16) }),
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(1, -70, 0, 42),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBlack,
			TextSize = 26,
			TextColor3 = UIConfig.Theme.Text,
			Text = title,
		}),
	})

	make("TextButton", {
		Parent = panel,
		Position = UDim2.new(1, -48, 0, 8),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = UIConfig.Theme.Danger,
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = UIConfig.Theme.Text,
		BorderSizePixel = 0,
	}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) }).MouseButton1Click:Connect(closeAllPanels)

	panels[name] = panel
	return panel
end

local function refreshInventory()
	local res = GetCreatureInventory:InvokeServer()
	if res.Ok then
		state.Creatures = res.Creatures
		state.FavoriteCreatureId = res.FavoriteCreatureId
		state.Collection = res.Collection
		updateHud()
	end
end

local function refreshSocial()
	local res = GetSocialSnapshot:InvokeServer()
	if res.Ok then
		state.SocialPlayers = res.Players
	end
end

local function rarityReveal(rarity, creatureName)
	local overlay = make("Frame", {
		Parent = rootGui,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, {
		make("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(450, 180),
			Font = Enum.Font.GothamBlack,
			TextSize = 38,
			TextColor3 = rarityColor(rarity),
			TextWrapped = true,
			Text = string.format("%s\n%s", string.upper(rarity), creatureName),
		}),
	})

	playRaritySfx(rarity)
	if rarity == "Epic" or rarity == "Legendary" or rarity == "Cosmic" then
		toast("WOW! Share this pull with your friends!", "success")
	end
	task.delay(1.15, function()
		overlay:Destroy()
	end)
end

local function rarityBadge(parent, rarity)
	return make("TextLabel", {
		Parent = parent,
		BackgroundColor3 = rarityColor(rarity),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(86, 24),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(32, 24, 42),
		Text = rarity,
	}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
end

local function buildHud()
	local insetTop = GuiService:GetGuiInset().Y

	make("Frame", {
		Name = "TopBar",
		Parent = rootGui,
		Position = UDim2.fromOffset(8, insetTop + 6),
		Size = UDim2.new(1, -16, 0, 56),
		BackgroundColor3 = UIConfig.Theme.Panel,
		BorderSizePixel = 0,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 12) }),
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})

	local topBar = rootGui.TopBar
	stardustLabel = make("TextLabel", {
		Parent = topBar,
		Size = UDim2.fromOffset(120, 40),
		BackgroundColor3 = UIConfig.Theme.PanelSoft,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = UIConfig.Theme.Text,
		Text = "✨ 0",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	energyLabel = make("TextLabel", {
		Parent = topBar,
		Size = UDim2.fromOffset(102, 40),
		BackgroundColor3 = UIConfig.Theme.PanelSoft,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = UIConfig.Theme.Text,
		Text = "🔋 0",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	collectionLabel = make("TextLabel", {
		Parent = topBar,
		Size = UDim2.fromOffset(190, 40),
		BackgroundColor3 = UIConfig.Theme.PanelSoft,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = UIConfig.Theme.SubText,
		Text = "Collection 0/0 (0%)",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	make("TextButton", {
		Parent = topBar,
		Size = UDim2.fromOffset(170, 40),
		BackgroundColor3 = UIConfig.Theme.Success,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(20, 46, 26),
		Text = "👫 Friend Bonus +10%",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) }).MouseButton1Click:Connect(function()
		toast("Play with friends for bonus stardust!", "success")
	end)

	objectiveLabel = make("TextLabel", {
		Parent = rootGui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, insetTop + 66),
		Size = UDim2.new(0.86, 0, 0, 38),
		BackgroundColor3 = UIConfig.Theme.Primary,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(10, 23, 40),
		Text = "🎯 Open crystals, collect critters, and show off!",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
end

local function buildTabs()
	local tabs = make("Frame", {
		Parent = rootGui,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.992),
		Size = UDim2.new(1, -8, 0, 86),
		BackgroundColor3 = UIConfig.Theme.Panel,
		BorderSizePixel = 0,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 16) }),
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5) }),
	})

	local defs = {
		{ "Crystals", "Crystals" },
		{ "Creatures", "Creatures" },
		{ "Quests", "Quests" },
		{ "Shop", "Shop" },
		{ "Trade", "Trade" },
		{ "Social", "Social" },
		{ "Daily", "Daily" },
		{ "Habitat", "Habitat" },
	}

	for _, def in ipairs(defs) do
		local key, text = def[1], def[2]
		make("TextButton", {
			Parent = tabs,
			Size = UDim2.fromOffset(108, 56),
			BackgroundColor3 = UIConfig.Theme.PanelSoft,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = UIConfig.Theme.Text,
			Text = text,
		}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) }).MouseButton1Click:Connect(function()
			openPanel(key)
		end)
	end
end

local function buildCrystalsPanel()
	local panel = makePanel("Crystals", "Open Crystals")
	local holder = make("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 0, 96),
		BackgroundTransparency = 1,
	}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })

	for crystalType, cfg in pairs(GameConfig.Crystals) do
		make("TextButton", {
			Parent = holder,
			Size = UDim2.fromOffset(180, 88),
			BackgroundColor3 = UIConfig.Theme.Primary,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBlack,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(13, 27, 47),
			Text = string.format("%s\n✨%d  🔋%d", crystalType, cfg.Cost, cfg.EnergyCost),
		}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) }).MouseButton1Click:Connect(function()
			local result = OpenCrystal:InvokeServer(crystalType)
			if result.Ok then
				if not state.Milestones.FirstCrystalOpened then
					state.Milestones.FirstCrystalOpened = true
					track("FirstCrystalOpened")
				end
				rarityReveal(result.Rarity, result.CreatureName)
				refreshInventory()
			else
				toast("Could not open: " .. tostring(result.Error), "warning")
			end
		end)
	end
end

local function buildCreaturesPanel()
	local panel = makePanel("Creatures", "My Critters")
	local list = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -74),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
	})
	local layout = make("UIGridLayout", {
		Parent = list,
		CellSize = UDim2.fromOffset(170, 120),
		CellPadding = UDim2.fromOffset(8, 8),
	})

	local function render()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for _, creature in ipairs(state.Creatures) do
			local card = make("Frame", {
				Parent = list,
				BackgroundColor3 = UIConfig.Theme.PanelSoft,
				BorderSizePixel = 0,
			}, {
				make("UICorner", { CornerRadius = UDim.new(0, 12) }),
			})
			rarityBadge(card, creature.Rarity).Position = UDim2.fromOffset(8, 8)
			make("TextLabel", {
				Parent = card,
				Position = UDim2.fromOffset(8, 38),
				Size = UDim2.new(1, -16, 0, 28),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 14,
				TextColor3 = UIConfig.Theme.Text,
				Text = creature.Name,
			})
			make("TextLabel", {
				Parent = card,
				Position = UDim2.fromOffset(8, 66),
				Size = UDim2.new(1, -16, 0, 20),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 12,
				TextColor3 = UIConfig.Theme.SubText,
				Text = "⭐ Stardust +" .. tostring(creature.Production),
			})
			local favText = state.FavoriteCreatureId == creature.Id and "Showcased" or "Showcase"
			make("TextButton", {
				Parent = card,
				Position = UDim2.new(1, -94, 1, -30),
				Size = UDim2.fromOffset(86, 24),
				BackgroundColor3 = UIConfig.Theme.Warning,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = Color3.fromRGB(53, 35, 9),
				Text = favText,
			}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) }).MouseButton1Click:Connect(function()
				local result = SetFavoriteCreature:InvokeServer(creature.Id)
				if result.Ok then
					state.FavoriteCreatureId = creature.Id
					if not state.Milestones.FirstCreatureEquipped then
						state.Milestones.FirstCreatureEquipped = true
						track("FirstCreatureEquipped")
					end
					toast("Favorite creature set for showcase!", "success")
					render()
				else
					toast("Could not set favorite.", "warning")
				end
			end)
		end
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			refreshInventory()
			render()
		end
	end)
end

local function buildQuestPanel()
	local panel = makePanel("Quests", "Daily Quests")
	local list = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -74),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
	})
	local layout = make("UIListLayout", { Parent = list, Padding = UDim.new(0, 8) })

	local function render()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		for _, quest in ipairs(state.Quests) do
			local card = make("Frame", {
				Parent = list,
				Size = UDim2.new(1, -4, 0, 78),
				BackgroundColor3 = UIConfig.Theme.PanelSoft,
				BorderSizePixel = 0,
			}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
			make("TextLabel", {
				Parent = card,
				Position = UDim2.fromOffset(10, 8),
				Size = UDim2.new(1, -120, 0, 26),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 15,
				TextColor3 = UIConfig.Theme.Text,
				Text = string.format("%s (%d/%d)", quest.Id, quest.Progress, quest.Goal),
			})
			local claim = make("TextButton", {
				Parent = card,
				Position = UDim2.new(1, -102, 0.5, -16),
				Size = UDim2.fromOffset(92, 32),
				BackgroundColor3 = quest.Claimed and UIConfig.Theme.Panel or UIConfig.Theme.Success,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = UIConfig.Theme.Text,
				Text = quest.Claimed and "Claimed" or "Claim",
			}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
			claim.Active = not quest.Claimed
			claim.MouseButton1Click:Connect(function()
				local result = ClaimQuest:InvokeServer(quest.Id)
				if result.Ok then
					playSfx("QuestComplete")
					if not state.Milestones.FirstQuestClaimed then
						state.Milestones.FirstQuestClaimed = true
						track("FirstQuestClaimed")
					end
					quest.Claimed = true
					refreshInventory()
					toast("Quest completed! +" .. tostring(result.Reward), "success")
					render()
				else
					toast("Quest not ready: " .. tostring(result.Error), "warning")
				end
			end)
		end
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then render() end
	end)
end

local function buildShopPanel()
	local panel = makePanel("Shop", "Shop")
	local list = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -74),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
	})
	local layout = make("UIListLayout", { Parent = list, Padding = UDim.new(0, 8) })

	local products = {
		{ Category = "Starter", Name = "Starter Cosmic Pack", Desc = "Energy + stardust to jump in fast.", Type = "Product", Id = GameConfig.Monetization.DeveloperProducts.CrystalBundle },
		{ Category = "VIP", Name = "VIP Habitat", Desc = "Exclusive look + daily bonus style.", Type = "Pass", Id = GameConfig.Monetization.GamePasses.VIPHabitat },
		{ Category = "Slots", Name = "Extra Creature Slots", Desc = "Keep more critters for flex and trade.", Type = "Pass", Id = GameConfig.Monetization.GamePasses.ExtraCreatureSlots },
		{ Category = "Boost", Name = "Energy Refill", Desc = "Open more crystals instantly.", Type = "Product", Id = GameConfig.Monetization.DeveloperProducts.EnergyRefill },
	}

	for _, info in ipairs(products) do
		local card = make("Frame", {
			Parent = list,
			Size = UDim2.new(1, -4, 0, 96),
			BackgroundColor3 = UIConfig.Theme.PanelSoft,
			BorderSizePixel = 0,
		}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		make("TextLabel", {
			Parent = card,
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(66, 22),
			BackgroundColor3 = UIConfig.Theme.Warning,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBlack,
			TextSize = 11,
			TextColor3 = Color3.fromRGB(53, 35, 9),
			Text = info.Category,
		}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		make("TextLabel", {
			Parent = card,
			Position = UDim2.fromOffset(86, 7),
			Size = UDim2.new(1, -190, 0, 26),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = UIConfig.Theme.Text,
			Text = info.Name,
		})
		make("TextLabel", {
			Parent = card,
			Position = UDim2.fromOffset(10, 36),
			Size = UDim2.new(1, -120, 0, 48),
			BackgroundTransparency = 1,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = UIConfig.Theme.SubText,
			Text = info.Desc,
		})
		make("TextButton", {
			Parent = card,
			Position = UDim2.new(1, -98, 0.5, -18),
			Size = UDim2.fromOffset(88, 36),
			BackgroundColor3 = UIConfig.Theme.Success,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(20, 48, 26),
			Text = "Get",
		}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) }).MouseButton1Click:Connect(function()
			if info.Id == 0 then
				toast("Set this product ID in GameConfig.", "warning")
				return
			end
			track("PurchasePromptOpened", { Offer = info.Name, Type = info.Type })
			if info.Type == "Pass" then
				MarketplaceService:PromptGamePassPurchase(player, info.Id)
			else
				MarketplaceService:PromptProductPurchase(player, info.Id)
			end
		end)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
end

local function buildTradePanel()
	local panel = makePanel("Trade", "Trade Center")
	local left = make("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(0.42, 0, 1, -74),
		BackgroundColor3 = UIConfig.Theme.PanelSoft,
		BorderSizePixel = 0,
	}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })

	local right = make("Frame", {
		Parent = panel,
		Position = UDim2.new(0.44, 8, 0, 58),
		Size = UDim2.new(0.56, -22, 1, -74),
		BackgroundColor3 = UIConfig.Theme.PanelSoft,
		BorderSizePixel = 0,
	}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })

	make("TextLabel", { Parent = left, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = UIConfig.Theme.Text, Text = "Players" })
	make("TextLabel", { Parent = right, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = UIConfig.Theme.Text, Text = "Your Offer" })

	local playerList = make("ScrollingFrame", { Parent = left, Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0.42, 0), CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local playerLayout = make("UIListLayout", { Parent = playerList, Padding = UDim.new(0, 6) })

	local invList = make("ScrollingFrame", { Parent = left, Position = UDim2.new(0, 8, 0.45, 0), Size = UDim2.new(1, -16, 0.55, -8), CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local invLayout = make("UIListLayout", { Parent = invList, Padding = UDim.new(0, 6) })

	local offerList = make("ScrollingFrame", { Parent = right, Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0.62, 0), CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local offerLayout = make("UIListLayout", { Parent = offerList, Padding = UDim.new(0, 6) })

	local statusLabel = make("TextLabel", { Parent = right, Position = UDim2.new(0, 10, 0.65, 0), Size = UDim2.new(1, -20, 0, 24), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = UIConfig.Theme.Warning, Text = "Pick player and select critters to offer." })
	local timerLabel = make("TextLabel", { Parent = right, Position = UDim2.new(0, 10, 0.70, 0), Size = UDim2.new(1, -20, 0, 24), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = UIConfig.Theme.SubText, Text = "Expiry: --" })

	local sendButton = make("TextButton", { Parent = right, Position = UDim2.new(0, 10, 1, -46), Size = UDim2.fromOffset(148, 36), BackgroundColor3 = UIConfig.Theme.Primary, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(8, 21, 38), Text = "Send Request" }, { make("UICorner", { CornerRadius = UDim.new(0, 9) }) })
	local confirmButton = make("TextButton", { Parent = right, Position = UDim2.new(0, 164, 1, -46), Size = UDim2.fromOffset(148, 36), BackgroundColor3 = UIConfig.Theme.Success, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(19, 46, 24), Text = "Confirm Trade" }, { make("UICorner", { CornerRadius = UDim.new(0, 9) }) })
	make("TextLabel", { Parent = right, Position = UDim2.new(0, 320, 1, -44), Size = UDim2.new(1, -328, 0, 36), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = UIConfig.Theme.Warning, Text = "Safety: Always double-check names and rarity before confirm." })

	local function renderOfferList()
		for _, ch in ipairs(offerList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
		for _, creature in ipairs(state.Trade.Offer) do
			local row = make("Frame", { Parent = offerList, Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = UIConfig.Theme.Panel, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
			rarityBadge(row, creature.Rarity).Position = UDim2.fromOffset(6, 6)
			make("TextLabel", { Parent = row, Position = UDim2.fromOffset(98, 7), Size = UDim2.new(1, -130, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UIConfig.Theme.Text, Text = creature.Name })
			make("TextButton", { Parent = row, Position = UDim2.new(1, -30, 0.5, -12), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = UIConfig.Theme.Danger, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UIConfig.Theme.Text, Text = "-" }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) }).MouseButton1Click:Connect(function()
				for i, c in ipairs(state.Trade.Offer) do
					if c.Id == creature.Id then table.remove(state.Trade.Offer, i) break end
				end
				renderOfferList()
			end)
		end
	end

	local function renderInventory()
		for _, ch in ipairs(invList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
		for _, creature in ipairs(state.Creatures) do
			local row = make("Frame", { Parent = invList, Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = UIConfig.Theme.Panel, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
			rarityBadge(row, creature.Rarity).Position = UDim2.fromOffset(6, 6)
			make("TextLabel", { Parent = row, Position = UDim2.fromOffset(98, 7), Size = UDim2.new(1, -130, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UIConfig.Theme.Text, Text = creature.Name })
			make("TextButton", { Parent = row, Position = UDim2.new(1, -30, 0.5, -12), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = UIConfig.Theme.Success, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UIConfig.Theme.Text, Text = "+" }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) }).MouseButton1Click:Connect(function()
				if #state.Trade.Offer >= GameConfig.Limits.MaxTradeSlots then
					toast("Offer is full.", "warning")
					return
				end
				for _, c in ipairs(state.Trade.Offer) do
					if c.Id == creature.Id then
						toast("Already in offer.", "warning")
						return
					end
				end
				table.insert(state.Trade.Offer, creature)
				renderOfferList()
			end)
		end
	end

	local function renderPlayers()
		for _, ch in ipairs(playerList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
		for _, pinfo in ipairs(state.SocialPlayers) do
			local row = make("Frame", { Parent = playerList, Size = UDim2.new(1, -4, 0, 44), BackgroundColor3 = UIConfig.Theme.Panel, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
			make("TextLabel", { Parent = row, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -82, 0, 32), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = UIConfig.Theme.Text, Text = string.format("%s  (%d%%)", pinfo.DisplayName, pinfo.CollectionPercent) })
			make("TextButton", { Parent = row, Position = UDim2.new(1, -70, 0.5, -14), Size = UDim2.fromOffset(62, 28), BackgroundColor3 = UIConfig.Theme.Primary, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(9, 21, 37), Text = "Select" }, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) }).MouseButton1Click:Connect(function()
				state.Trade.Target = pinfo
				statusLabel.Text = "Target: " .. pinfo.DisplayName .. " • choose creatures"
			end)
		end
	end

	sendButton.MouseButton1Click:Connect(function()
		if state.Trade.Locked then
			toast("Please wait.", "warning")
			return
		end
		if not state.Trade.Target then
			toast("Select a player first.", "warning")
			return
		end
		if #state.Trade.Offer == 0 then
			toast("Add at least one creature.", "warning")
			return
		end
		state.Trade.Locked = true
		local ids = {}
		for _, c in ipairs(state.Trade.Offer) do table.insert(ids, c.Id) end
		local res = CreateTrade:InvokeServer(state.Trade.Target.UserId, ids)
		state.Trade.Locked = false
		if res.Ok then
			state.Trade.TradeId = res.TradeId
			state.Trade.ExpireAt = os.time() + 120
			state.Trade.Stage = "requested"
			statusLabel.Text = "Trade request sent to " .. state.Trade.Target.DisplayName
			track("TradeRequestSent", { TargetUserId = state.Trade.Target.UserId, OfferSize = #ids })
			playSfx("TradeConfirm")
		else
			toast("Trade request failed: " .. tostring(res.Error), "warning")
			track("TradeRequestFailed", { Reason = tostring(res.Error) })
		end
	end)

	confirmButton.MouseButton1Click:Connect(function()
		if not state.Trade.TradeId then
			toast("No active trade request.", "warning")
			return
		end
		if os.time() >= state.Trade.ExpireAt then
			toast("Trade expired. Send a new one.", "warning")
			track("TradeExpired", { TradeId = state.Trade.TradeId })
			state.Trade.TradeId = nil
			return
		end
		local res = AcceptTrade:InvokeServer(state.Trade.TradeId)
		if res.Ok then
			track("TradeCompleted", { TradeId = state.Trade.TradeId })
			toast("Trade completed!", "success")
			playSfx("TradeConfirm")
			state.Trade = { Stage = "idle", Target = nil, TradeId = nil, Offer = {}, ExpireAt = 0, Locked = false }
			renderOfferList()
			refreshInventory()
		else
			toast("Trade not completed: " .. tostring(res.Result), "warning")
			track("TradeAcceptFailed", { Reason = tostring(res.Result) })
		end
	end)

	RunService.Heartbeat:Connect(function()
		if state.Trade.TradeId and state.Trade.ExpireAt > 0 then
			local leftSec = state.Trade.ExpireAt - os.time()
			if leftSec <= 0 then
				timerLabel.Text = "Expiry: expired"
			else
				timerLabel.Text = "Expiry: " .. tostring(leftSec) .. "s"
			end
		else
			timerLabel.Text = "Expiry: --"
		end
	end)

	playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() playerList.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 8) end)
	invLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() invList.CanvasSize = UDim2.new(0, 0, 0, invLayout.AbsoluteContentSize.Y + 8) end)
	offerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() offerList.CanvasSize = UDim2.new(0, 0, 0, offerLayout.AbsoluteContentSize.Y + 8) end)

	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			refreshSocial()
			refreshInventory()
			renderPlayers()
			renderInventory()
			renderOfferList()
		end
	end)
end

local function buildSocialPanel()
	local panel = makePanel("Social", "Social & Visits")
	local list = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -74),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
	})
	local layout = make("UIListLayout", { Parent = list, Padding = UDim.new(0, 8) })

	local function render()
		for _, ch in ipairs(list:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
		for _, pinfo in ipairs(state.SocialPlayers) do
			local card = make("Frame", {
				Parent = list,
				Size = UDim2.new(1, -4, 0, 88),
				BackgroundColor3 = UIConfig.Theme.PanelSoft,
				BorderSizePixel = 0,
			}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
			make("TextLabel", { Parent = card, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -120, 0, 24), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = UIConfig.Theme.Text, Text = pinfo.DisplayName .. " @" .. pinfo.Name })
			make("TextLabel", { Parent = card, Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -120, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = rarityColor(pinfo.RarestTier), Text = "Rarest: " .. pinfo.RarestTier })
			make("TextLabel", { Parent = card, Position = UDim2.fromOffset(10, 54), Size = UDim2.new(1, -120, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = UIConfig.Theme.SubText, Text = string.format("Collection %d/%d (%d%%) • Habitat Lv.%d", pinfo.CollectionUnlocked, pinfo.CollectionTotal, pinfo.CollectionPercent, pinfo.HabitatLevel) })
			make("TextButton", { Parent = card, Position = UDim2.new(1, -102, 0.5, -16), Size = UDim2.fromOffset(92, 32), BackgroundColor3 = UIConfig.Theme.Primary, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(10, 24, 40), Text = "Visit" }, { make("UICorner", { CornerRadius = UDim.new(0, 9) }) }).MouseButton1Click:Connect(function()
				local result = VisitHabitat:InvokeServer(pinfo.UserId)
				if result.Ok then
					toast("Visiting " .. result.Target.DisplayName .. "'s habitat!", "success")
					track("HabitatVisitStarted", { TargetUserId = pinfo.UserId })
				else
					toast("Could not visit: " .. tostring(result.Error), "warning")
				end
			end)
		end
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8) end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then refreshSocial(); render() end
	end)
end

local function buildDailyPanel()
	local panel = makePanel("Daily", "Daily Reward")
	make("TextLabel", {
		Parent = panel,
		Position = UDim2.new(0.5, -160, 0.5, -80),
		Size = UDim2.fromOffset(320, 34),
		BackgroundTransparency = 1,
		Text = "Claim your daily cosmic gift!",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = UIConfig.Theme.Text,
	})
	make("TextButton", {
		Parent = panel,
		Position = UDim2.new(0.5, -130, 0.5, -28),
		Size = UDim2.fromOffset(260, 70),
		BackgroundColor3 = UIConfig.Theme.Warning,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(64, 42, 9),
		Text = "Claim Daily ✨",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 14) }) }).MouseButton1Click:Connect(function()
		local result = ClaimDailyReward:InvokeServer()
		if result.Ok then
			playSfx("DailyClaim")
			toast(string.format("Streak %d! +%d Stardust", result.Streak, result.Reward), "success")
			track("DailyClaimed", { Streak = result.Streak, Reward = result.Reward })
			refreshInventory()
		else
			toast("Daily unavailable: " .. tostring(result.Error), "warning")
		end
	end)
end

local function buildHabitatPanel()
	local panel = makePanel("Habitat", "Habitat")
	local level = make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 0, 26),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = UIConfig.Theme.Text,
		Text = "Habitat Lv. " .. tostring(state.HabitatLevel),
	})

	make("TextButton", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 98),
		Size = UDim2.fromOffset(190, 48),
		BackgroundColor3 = UIConfig.Theme.Success,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(18, 47, 24),
		Text = "Upgrade Habitat",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) }).MouseButton1Click:Connect(function()
		local result = UpgradeHabitat:InvokeServer()
		if result.Ok then
			state.HabitatLevel = result.Result
			level.Text = "Habitat Lv. " .. tostring(state.HabitatLevel)
			toast("Habitat upgraded!", "success")
		else
			toast("Upgrade failed: " .. tostring(result.Result), "warning")
		end
	end)

	make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 154),
		Size = UDim2.new(1, -32, 0, 50),
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Showcase pedestal uses your favorite creature from the Creatures panel.",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = UIConfig.Theme.SubText,
	})
end

local function runTutorial()
	if state.TutorialDone then
		objectiveLabel.Text = "🎯 New goal: trade, visit habitats, and complete your collection!"
		return
	end

	track("TutorialStarted")
	blockedInput = true
	toast("Welcome! Quick tour starts now.", "success")
	local steps = {
		"Move around and collect energy.",
		"Tap Crystals and open your first crystal.",
		"Open Creatures and set one as your showcase favorite.",
		"Claim one quest reward.",
		"Open Social and visit a player habitat.",
	}
	for i, text in ipairs(steps) do
		objectiveLabel.Text = "🎯 " .. text
		tutorialArrow.Visible = true
		tutorialArrow.Position = UDim2.fromScale(0.5, 0.88)
		task.wait(i == 2 and 7 or 4)
	end

	state.TutorialDone = true
	blockedInput = false
	objectiveLabel.Text = "🎯 Keep collecting rare critters and flex your favorites!"
	tutorialArrow.Visible = false
	state.Currencies.Stardust = (state.Currencies.Stardust or 0) + 250
	updateHud()
	toast("Tutorial complete! +250 Stardust", "success")
	track("TutorialCompleted", { Bonus = 250 })
end

local function wirePurchases()
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, productId, purchased)
		if purchased then
			playSfx("PurchaseSuccess")
			toast("Purchase complete!", "success")
			track("PurchaseSuccess", { ProductId = productId, Kind = "Product" })
		else
			playSfx("PurchaseCancel")
			toast("Purchase canceled.", "warning")
			track("PurchaseCancelled", { ProductId = productId, Kind = "Product" })
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, passId, purchased)
		if purchased then
			playSfx("PurchaseSuccess")
			toast("Game pass unlocked!", "success")
			track("PurchaseSuccess", { ProductId = passId, Kind = "Pass" })
		else
			playSfx("PurchaseCancel")
			toast("Game pass purchase canceled.", "warning")
			track("PurchaseCancelled", { ProductId = passId, Kind = "Pass" })
		end
	end)
end

local function buildUi()
	rootGui = make("ScreenGui", {
		Name = "CosmicCrittersUI",
		ResetOnSpawn = false,
		Parent = playerGui,
	})

	toastHolder = make("Frame", {
		Parent = rootGui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.new(0.72, 0, 0, 170),
		BackgroundTransparency = 1,
	}, { make("UIListLayout", { Padding = UDim.new(0, 6) }) })

	tutorialArrow = make("TextLabel", {
		Parent = rootGui,
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(34, 34),
		Font = Enum.Font.GothamBlack,
		TextSize = 30,
		TextColor3 = UIConfig.Theme.Warning,
		Text = "⬇",
	})

	buildHud()
	buildTabs()
	buildCrystalsPanel()
	buildCreaturesPanel()
	buildQuestPanel()
	buildShopPanel()
	buildTradePanel()
	buildSocialPanel()
	buildDailyPanel()
	buildHabitatPanel()
	wirePurchases()
end

DataReady.OnClientEvent:Connect(function(payload)
	state.Currencies = payload.Currencies or state.Currencies
	state.Quests = payload.Quests or state.Quests
	state.HabitatLevel = payload.HabitatLevel or state.HabitatLevel
	state.Collection = payload.Collection or state.Collection
	state.FavoriteCreatureId = payload.FavoriteCreatureId
	state.TutorialDone = (payload.CreatureCount or 0) > 0

	if not rootGui then
		buildUi()
	end

	refreshInventory()
	refreshSocial()
	updateHud()
	track("SessionMilestone", { Stage = "DataReady" })
	runTutorial()
end)

ServerAnnouncement.OnClientEvent:Connect(function(text)
	playSfx("RareAnnouncement")
	toast("🌟 " .. text, "success")
	track("RareAnnouncementSeen", { Message = text })
end)

task.delay(10, function()
	if not rootGui then
		buildUi()
		toast("Loading player data...", "warning")
	end
end)
