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
local ServerAnnouncement = remotes:WaitForChild("ServerAnnouncement")
local DataReady = remotes:WaitForChild("DataReady")

local state = {
	Currencies = { Stardust = 0, Energy = 0 },
	Quests = {},
	CreatureCount = 0,
	HabitatLevel = 1,
	TutorialDone = false,
	ActivePanel = nil,
	PendingTradeId = nil,
}

local rootGui
local toastHolder
local panels = {}
local objectiveLabel
local stardustLabel
local energyLabel
local tutorialArrow
local blockInput = false

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

local function playSfx(soundKey)
	local sound = Instance.new("Sound")
	sound.SoundId = UIConfig.Audio[soundKey] or UIConfig.Audio.ButtonClick
	sound.Volume = 0.4
	sound.Parent = SoundService
	sound:Play()
	task.delay(2, function()
		sound:Destroy()
	end)
end

local function tweenIn(frame)
	frame.Visible = true
	frame.BackgroundTransparency = 1
	TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()
end

local function toast(message, tone)
	local color = UIConfig.Theme.PanelAlt
	if tone == "success" then
		color = UIConfig.Theme.Success
	elseif tone == "warning" then
		color = UIConfig.Theme.Warning
	elseif tone == "danger" then
		color = UIConfig.Theme.Danger
	end

	local item = make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 12) }),
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = UIConfig.Theme.Text,
			Text = message,
		})
	})

	item.Parent = toastHolder
	item.Position = UDim2.new(0, 0, 0, 12)
	item.BackgroundTransparency = 1
	TweenService:Create(item, TweenInfo.new(0.2), { BackgroundTransparency = 0.05, Position = UDim2.new(0, 0, 0, 0) }):Play()

	task.delay(3, function()
		if item.Parent then
			TweenService:Create(item, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			task.wait(0.22)
			item:Destroy()
		end
	end)
end

local function updateCurrencyHud()
	stardustLabel.Text = string.format("✨ %d", state.Currencies.Stardust or 0)
	energyLabel.Text = string.format("🔋 %d", state.Currencies.Energy or 0)
end

local function closeAllPanels()
	for _, panel in pairs(panels) do
		panel.Visible = false
	end
	state.ActivePanel = nil
end

local function openPanel(key)
	if blockInput then
		return
	end
	playSfx("ButtonClick")
	if state.ActivePanel == key then
		closeAllPanels()
		return
	end
	closeAllPanels()
	state.ActivePanel = key
	tweenIn(panels[key])
end

local function addCloseButton(panel)
	make("TextButton", {
		Name = "CloseButton",
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = UIConfig.Theme.Text,
		BackgroundColor3 = UIConfig.Theme.Danger,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -50, 0, 8),
		Parent = panel,
	}, {
		make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	}).MouseButton1Click:Connect(closeAllPanels)
end

local function screenShake(strength, duration)
	if not workspace.CurrentCamera then
		return
	end
	local cam = workspace.CurrentCamera
	local base = cam.CFrame
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - start
		if elapsed > duration then
			cam.CFrame = base
			conn:Disconnect()
			return
		end
		local x = (math.random() - 0.5) * strength
		local y = (math.random() - 0.5) * strength
		cam.CFrame = base * CFrame.new(x, y, 0)
	end)
end

local function rarityReveal(rarity, creatureName)
	local overlay = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = rootGui,
	}, {
		make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(400, 160),
			BackgroundTransparency = 1,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
			TextSize = 34,
			TextColor3 = UIConfig.Theme.Text,
			Text = string.format("%s\n%s", string.upper(rarity), creatureName),
		}),
	})

	playSfx("RarityReveal")
	if rarity == "Epic" or rarity == "Legendary" or rarity == "Cosmic" then
		screenShake(UIConfig.GameFeel.RareShakeStrength, UIConfig.GameFeel.RareShakeDuration)
		toast("BIG PULL! Show your friends!", "success")
	end

	task.delay(1.2, function()
		overlay:Destroy()
	end)
end

local function buildPanel(name, title)
	local panel = make("Frame", {
		Name = name,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.88, 0.76),
		BackgroundColor3 = UIConfig.Theme.Panel,
		BorderSizePixel = 0,
		Parent = rootGui,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 18) }),
		make("TextLabel", {
			Size = UDim2.new(1, -80, 0, 50),
			Position = UDim2.fromOffset(16, 8),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = UIConfig.Theme.Text,
			Text = title,
		}),
	})
	addCloseButton(panel)
	panels[name] = panel
	return panel
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
		make("UICorner", { CornerRadius = UDim.new(0, 14) }),
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }),
	}).Parent = rootGui

	local topBar = rootGui.TopBar
	stardustLabel = make("TextLabel", {
		Parent = topBar,
		Size = UDim2.fromOffset(130, 44),
		BackgroundColor3 = UIConfig.Theme.PanelAlt,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = UIConfig.Theme.Text,
		Text = "✨ 0",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	energyLabel = make("TextLabel", {
		Parent = topBar,
		Size = UDim2.fromOffset(120, 44),
		BackgroundColor3 = UIConfig.Theme.PanelAlt,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = UIConfig.Theme.Text,
		Text = "🔋 0",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	local friendBonus = make("TextButton", {
		Parent = topBar,
		Size = UDim2.fromOffset(170, 44),
		BackgroundColor3 = UIConfig.Theme.Success,
		TextColor3 = Color3.fromRGB(16, 37, 21),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Text = "👫 Friend Bonus +10%",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	friendBonus.MouseButton1Click:Connect(function()
		playSfx("ButtonClick")
		toast("Invite friends for stardust boosts!", "success")
	end)

	if GameConfig.Monetization.GamePasses.VIPHabitat ~= 0 then
		local vip = make("TextLabel", {
			Parent = topBar,
			Size = UDim2.fromOffset(88, 44),
			BackgroundColor3 = UIConfig.Theme.Warning,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBlack,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(68, 42, 8),
			Text = "VIP ⭐",
		}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
		vip.Visible = false
		task.spawn(function()
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.Monetization.GamePasses.VIPHabitat)
			end)
			if ok and owns then
				vip.Visible = true
			end
		end)
	end

	objectiveLabel = make("TextLabel", {
		Parent = rootGui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, insetTop + 68),
		Size = UDim2.new(0.86, 0, 0, 42),
		BackgroundColor3 = UIConfig.Theme.Primary,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(7, 17, 35),
		Text = "🎯 Objective: Open a crystal to discover a critter!",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
end

local function buildMenuButtons()
	local holder = make("Frame", {
		Parent = rootGui,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.99),
		Size = UDim2.new(1, -12, 0, 84),
		BackgroundColor3 = UIConfig.Theme.Panel,
		BorderSizePixel = 0,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 18) }),
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})

	local tabData = {
		{ "Crystals", "Open Crystals" },
		{ "Creatures", "Creatures" },
		{ "Quests", "Quests" },
		{ "Shop", "Shop" },
		{ "Trade", "Trade" },
		{ "Habitat", "Habitat" },
		{ "Daily", "Daily" },
	}

	for _, entry in ipairs(tabData) do
		local key = entry[1]
		local label = entry[2]
		local button = make("TextButton", {
			Parent = holder,
			Size = UDim2.fromOffset(128, 58),
			BackgroundColor3 = UIConfig.Theme.PanelAlt,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = UIConfig.Theme.Text,
			Text = label,
		}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		button.MouseButton1Click:Connect(function()
			openPanel(key)
		end)
	end
end

local function createCrystalPanel()
	local panel = buildPanel("Crystals", "Open Crystals")
	local row = make("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 70),
		Size = UDim2.new(1, -32, 0, 92),
		BackgroundTransparency = 1,
	}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })

	for crystalType, config in pairs(GameConfig.Crystals) do
		local button = make("TextButton", {
			Parent = row,
			Size = UDim2.fromOffset(180, 86),
			BackgroundColor3 = UIConfig.Theme.Primary,
			TextColor3 = Color3.fromRGB(7, 20, 34),
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBlack,
			TextSize = 17,
			Text = string.format("%s\n✨%d  🔋%d", crystalType, config.Cost, config.EnergyCost),
		}, { make("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		button.MouseButton1Click:Connect(function()
			if blockInput then
				return
			end
			playSfx("CrystalOpen")
			local result = OpenCrystal:InvokeServer(crystalType)
			if result.Ok then
				state.CreatureCount += 1
				rarityReveal(result.Rarity, result.CreatureName)
				toast(string.format("You found %s!", result.CreatureName), "success")
				objectiveLabel.Text = "🎯 Objective: Claim quests and grow your habitat!"
			else
				toast("Could not open: " .. tostring(result.Error), "warning")
			end
		end)
	end
end

local function createCollectionPanel()
	local panel = buildPanel("Creatures", "Creature Collection")
	make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(20, 66),
		Size = UDim2.new(1, -40, 0, 28),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = UIConfig.Theme.SubText,
		Text = "Collect all cosmic critters!",
	})

	local gridHolder = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(18, 100),
		Size = UDim2.new(1, -36, 1, -130),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 8,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	local layout = make("UIGridLayout", {
		Parent = gridHolder,
		CellSize = UDim2.fromOffset(148, 130),
		CellPadding = UDim2.fromOffset(10, 10),
	})

	local names = { "Star Bunny", "Nebula Slime", "Meteor Turtle", "Comet Fox", "Galaxy Dragon", "Black Hole Cat" }
	for i, name in ipairs(names) do
		make("Frame", {
			Parent = gridHolder,
			BackgroundColor3 = UIConfig.Theme.PanelAlt,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(148, 130),
		}, {
			make("UICorner", { CornerRadius = UDim.new(0, 12) }),
			make("TextLabel", {
				Size = UDim2.new(1, -12, 0, 60),
				Position = UDim2.fromOffset(6, 12),
				BackgroundTransparency = 1,
				TextWrapped = true,
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextColor3 = UIConfig.Theme.Text,
				Text = name,
			}),
			make("TextLabel", {
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.new(0, 6, 1, -30),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextColor3 = UIConfig.Theme.SubText,
				Text = i <= state.CreatureCount and "Unlocked" or "Locked",
			}),
		})
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		gridHolder.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

local function createQuestPanel()
	local panel = buildPanel("Quests", "Daily Quests")
	local list = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 66),
		Size = UDim2.new(1, -32, 1, -84),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 8,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	local layout = make("UIListLayout", { Parent = list, Padding = UDim.new(0, 8) })

	for _, quest in ipairs(state.Quests) do
		local card = make("Frame", {
			Parent = list,
			Size = UDim2.new(1, -4, 0, 78),
			BackgroundColor3 = UIConfig.Theme.PanelAlt,
			BorderSizePixel = 0,
		}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		make("TextLabel", {
			Parent = card,
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -128, 0, 28),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = UIConfig.Theme.Text,
			Text = string.format("%s (%d/%d)", quest.Id, quest.Progress, quest.Goal),
		})
		local claim = make("TextButton", {
			Parent = card,
			Position = UDim2.new(1, -106, 0.5, -18),
			Size = UDim2.fromOffset(96, 36),
			BackgroundColor3 = UIConfig.Theme.Success,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(22, 48, 21),
			Text = quest.Claimed and "Claimed" or "Claim",
		}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
		claim.Active = not quest.Claimed
		claim.MouseButton1Click:Connect(function()
			local result = ClaimQuest:InvokeServer(quest.Id)
			if result.Ok then
				playSfx("QuestComplete")
				toast(string.format("Quest complete! +%d Stardust", result.Reward), "success")
				claim.Text = "Claimed"
				claim.Active = false
			else
				toast("Quest not ready: " .. tostring(result.Error), "warning")
			end
		end)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end)
end

local function createShopPanel()
	local panel = buildPanel("Shop", "Shop")
	make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 56),
		Size = UDim2.new(1, -32, 0, 26),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextColor3 = UIConfig.Theme.SubText,
		Text = "Boost speed, style, and convenience.",
	})

	local scroller = make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 86),
		Size = UDim2.new(1, -32, 1, -102),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
	})
	local layout = make("UIListLayout", { Parent = scroller, Padding = UDim.new(0, 8) })

	local cards = {
		{ Name = "Starter Offer", Desc = "✨ + 🔋 bundle to jump-start your habitat", Type = "Product", Id = GameConfig.Monetization.DeveloperProducts.CrystalBundle },
		{ Name = "VIP Habitat", Desc = "Exclusive style + daily bonus vibes", Type = "Pass", Id = GameConfig.Monetization.GamePasses.VIPHabitat },
		{ Name = "Extra Creature Slots", Desc = "Keep more favorites equipped and shown", Type = "Pass", Id = GameConfig.Monetization.GamePasses.ExtraCreatureSlots },
		{ Name = "Energy Refill", Desc = "Open more crystals right now", Type = "Product", Id = GameConfig.Monetization.DeveloperProducts.EnergyRefill },
	}

	for _, info in ipairs(cards) do
		local card = make("Frame", {
			Parent = scroller,
			Size = UDim2.new(1, -4, 0, 84),
			BackgroundColor3 = UIConfig.Theme.PanelAlt,
			BorderSizePixel = 0,
		}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		make("TextLabel", {
			Parent = card,
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -140, 0, 30),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 17,
			TextColor3 = UIConfig.Theme.Text,
			Text = info.Name,
		})
		make("TextLabel", {
			Parent = card,
			Position = UDim2.fromOffset(12, 34),
			Size = UDim2.new(1, -146, 0, 44),
			BackgroundTransparency = 1,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = UIConfig.Theme.SubText,
			Text = info.Desc,
		})
		local buy = make("TextButton", {
			Parent = card,
			Position = UDim2.new(1, -106, 0.5, -20),
			Size = UDim2.fromOffset(96, 40),
			BackgroundColor3 = UIConfig.Theme.Warning,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(52, 34, 9),
			Text = "Get",
		}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
		buy.MouseButton1Click:Connect(function()
			if info.Id == 0 then
				toast("Set product IDs in GameConfig first.", "warning")
				return
			end
			if info.Type == "Pass" then
				MarketplaceService:PromptGamePassPurchase(player, info.Id)
			else
				MarketplaceService:PromptProductPurchase(player, info.Id)
			end
		end)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

local function createTradePanel()
	local panel = buildPanel("Trade", "Trade Hub")
	make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 0, 24),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = UIConfig.Theme.SubText,
		Text = "Friendly reminder: Double-check before confirming!",
	})

	local targetBox = make("TextBox", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 92),
		Size = UDim2.new(1, -32, 0, 46),
		BackgroundColor3 = UIConfig.Theme.PanelAlt,
		BorderSizePixel = 0,
		PlaceholderText = "Target UserId",
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = UIConfig.Theme.Text,
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	local idsBox = make("TextBox", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 146),
		Size = UDim2.new(1, -32, 0, 46),
		BackgroundColor3 = UIConfig.Theme.PanelAlt,
		BorderSizePixel = 0,
		PlaceholderText = "Creature IDs (comma separated)",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextColor3 = UIConfig.Theme.Text,
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	local timerLabel = make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 198),
		Size = UDim2.new(1, -32, 0, 24),
		BackgroundTransparency = 1,
		Text = "Trade requests expire in 120s.",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = UIConfig.Theme.Warning,
	})

	local request = make("TextButton", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 230),
		Size = UDim2.fromOffset(180, 48),
		BackgroundColor3 = UIConfig.Theme.Primary,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(7, 22, 40),
		Text = "Send Trade Request",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	local accept = make("TextButton", {
		Parent = panel,
		Position = UDim2.fromOffset(206, 230),
		Size = UDim2.fromOffset(140, 48),
		BackgroundColor3 = UIConfig.Theme.Success,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(19, 49, 25),
		Text = "Confirm",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	request.MouseButton1Click:Connect(function()
		local userId = tonumber(targetBox.Text)
		if not userId then
			toast("Enter a valid UserId.", "warning")
			return
		end
		local ids = {}
		for id in string.gmatch(idsBox.Text, "[^,%s]+") do
			table.insert(ids, id)
		end
		local res = CreateTrade:InvokeServer(userId, ids)
		if res.Ok then
			state.PendingTradeId = res.TradeId
			playSfx("TradeConfirm")
			toast("Trade request sent!", "success")
		else
			toast("Trade failed: " .. tostring(res.Error), "warning")
		end
	end)

	accept.MouseButton1Click:Connect(function()
		if not state.PendingTradeId then
			toast("No pending trade id yet.", "warning")
			return
		end
		local res = AcceptTrade:InvokeServer(state.PendingTradeId)
		if res.Ok then
			playSfx("TradeConfirm")
			toast("Trade complete!", "success")
			state.PendingTradeId = nil
		else
			toast("Trade not completed: " .. tostring(res.Result), "warning")
		end
	end)

	timerLabel.Text = "Trade requests expire in 120s • confirm carefully"
end

local function createHabitatPanel()
	local panel = buildPanel("Habitat", "My Habitat")
	local levelLabel = make("TextLabel", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 66),
		Size = UDim2.new(1, -32, 0, 32),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = UIConfig.Theme.Text,
		Text = "Habitat Level: 1",
	})
	levelLabel.Text = "Habitat Level: " .. tostring(state.HabitatLevel)

	local upgrade = make("TextButton", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 108),
		Size = UDim2.fromOffset(200, 52),
		BackgroundColor3 = UIConfig.Theme.Success,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(20, 54, 24),
		Text = "Upgrade Habitat",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	upgrade.MouseButton1Click:Connect(function()
		local res = UpgradeHabitat:InvokeServer()
		if res.Ok then
			state.HabitatLevel = res.Result
			levelLabel.Text = "Habitat Level: " .. tostring(state.HabitatLevel)
			toast("Habitat upgraded!", "success")
		else
			toast("Upgrade failed: " .. tostring(res.Result), "warning")
		end
	end)

	local showcase = make("TextButton", {
		Parent = panel,
		Position = UDim2.fromOffset(226, 108),
		Size = UDim2.fromOffset(210, 52),
		BackgroundColor3 = UIConfig.Theme.Warning,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(58, 40, 12),
		Text = "Set Favorite Showcase",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	showcase.MouseButton1Click:Connect(function()
		toast("Favorite creature set on showcase pedestal!", "success")
	end)
end

local function createDailyPanel()
	local panel = buildPanel("Daily", "Daily Reward")
	local claimButton = make("TextButton", {
		Parent = panel,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(260, 72),
		BackgroundColor3 = UIConfig.Theme.Warning,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(62, 43, 12),
		Text = "Claim Daily ✨",
	}, { make("UICorner", { CornerRadius = UDim.new(0, 14) }) })
	claimButton.MouseButton1Click:Connect(function()
		local result = ClaimDailyReward:InvokeServer()
		if result.Ok then
			playSfx("DailyClaim")
			toast(string.format("Daily claimed! +%d", result.Reward), "success")
		else
			toast("Daily unavailable: " .. tostring(result.Error), "warning")
		end
	end)
end

local function moveArrowTo(target)
	if not tutorialArrow then
		return
	end
	local absPos = target.AbsolutePosition
	tutorialArrow.Position = UDim2.fromOffset(absPos.X + target.AbsoluteSize.X * 0.5 - 16, absPos.Y - 36)
	tutorialArrow.Visible = true
end

local function runTutorial()
	if state.TutorialDone then
		objectiveLabel.Text = "🎯 Objective: Collect rare critters and flex your habitat!"
		return
	end

	blockInput = true
	toast("Welcome to Cosmic Critters! Let's learn fast.", "success")

	local topBar = rootGui:FindFirstChild("TopBar")
	local tutorialSteps = {
		{ Text = "Move around and collect an energy crystal!", Wait = 4 },
		{ Text = "Tap 'Open Crystals' below.", TargetPanel = "Crystals", Wait = 2 },
		{ Text = "Open your first crystal now!", Wait = 6 },
		{ Text = "Great! Now claim one quest reward.", TargetPanel = "Quests", Wait = 4 },
		{ Text = "Upgrade your habitat one time.", TargetPanel = "Habitat", Wait = 4 },
	}

	for _, step in ipairs(tutorialSteps) do
		objectiveLabel.Text = "🎯 " .. step.Text
		if step.TargetPanel then
			openPanel(step.TargetPanel)
		end
		if topBar then
			moveArrowTo(topBar)
		end
		task.wait(step.Wait)
	end

	blockInput = false
	state.TutorialDone = true
	objectiveLabel.Text = "🎯 Next: open crystals, finish quests, and trade with friends!"
	tutorialArrow.Visible = false
	toast("Tutorial complete! Bonus +200 Stardust", "success")
	state.Currencies.Stardust += 200
	updateCurrencyHud()
end

local function wireMarketplaceFeedback()
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, productId, purchased)
		if purchased then
			playSfx("PurchaseSuccess")
			toast("Purchase complete! Enjoy your boost.", "success")
		else
			toast("Purchase canceled.", "warning")
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, passId, purchased)
		if purchased then
			playSfx("PurchaseSuccess")
			toast("Game pass unlocked!", "success")
		else
			toast("Game pass purchase canceled.", "warning")
		end
	end)
end

local function buildUiShell()
	rootGui = make("ScreenGui", {
		Name = "CosmicCrittersUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	make("UIScale", {
		Parent = rootGui,
		Scale = 1,
	})

	toastHolder = make("Frame", {
		Parent = rootGui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.17),
		Size = UDim2.new(0.72, 0, 0, 190),
		BackgroundTransparency = 1,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	tutorialArrow = make("TextLabel", {
		Parent = rootGui,
		Visible = false,
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		Text = "⬇",
		TextColor3 = UIConfig.Theme.Warning,
		Font = Enum.Font.GothamBlack,
		TextSize = 30,
	})

	buildHud()
	buildMenuButtons()
	createCrystalPanel()
	createCollectionPanel()
	createQuestPanel()
	createShopPanel()
	createTradePanel()
	createHabitatPanel()
	createDailyPanel()
	wireMarketplaceFeedback()
end

DataReady.OnClientEvent:Connect(function(payload)
	state.Currencies = payload.Currencies or state.Currencies
	state.Quests = payload.Quests or {}
	state.CreatureCount = payload.CreatureCount or 0
	state.HabitatLevel = payload.HabitatLevel or 1
	state.TutorialDone = state.CreatureCount > 0

	if not rootGui then
		buildUiShell()
	end

	updateCurrencyHud()
	runTutorial()
end)

ServerAnnouncement.OnClientEvent:Connect(function(text)
	playSfx("RareAnnouncement")
	toast("🌟 " .. text, "success")
end)

-- Failsafe boot in Studio test if server payload arrives late.
task.delay(10, function()
	if not rootGui then
		buildUiShell()
		toast("Loading player data...", "warning")
	end
end)
