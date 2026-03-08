local MarketplaceService = game:GetService("MarketplaceService")
local GameConfig = require(game.ReplicatedStorage.Config.GameConfig)
local CurrencyService = require(script.Parent.CurrencyService)

local MonetizationService = {}

function MonetizationService.ProcessReceipt(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local products = GameConfig.Monetization.DeveloperProducts
	if receiptInfo.ProductId == products.CrystalBundle then
		CurrencyService.Add(player, "Stardust", 7500)
		CurrencyService.Add(player, "Energy", 40)
	elseif receiptInfo.ProductId == products.EnergyRefill then
		CurrencyService.Add(player, "Energy", 50)
	elseif receiptInfo.ProductId == products.HabitatUpgrade then
		CurrencyService.Add(player, "Stardust", 1000)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.PlayerHasPass(player, passKey)
	local passId = GameConfig.Monetization.GamePasses[passKey]
	if not passId or passId == 0 then
		return false
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and result
end

return MonetizationService
