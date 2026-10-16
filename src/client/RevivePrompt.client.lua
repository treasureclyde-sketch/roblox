local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))
local plr = Players.LocalPlayer

plr.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid").Died:Connect(function()
		task.wait(1)
		if Config.ReviveProductId > 0 then
			MarketplaceService:PromptProductPurchase(plr, Config.ReviveProductId)
		end
	end)
end)
