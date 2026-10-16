local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

local lastPos = {} -- UserId -> CFrame места смерти

local function track(plr)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then lastPos[plr.UserId] = root.CFrame end
		end)
	end)
end

Players.PlayerAdded:Connect(track)
for _, p in ipairs(Players:GetPlayers()) do track(p) end

Players.PlayerRemoving:Connect(function(plr)
	lastPos[plr.UserId] = nil
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local plr = Players:GetPlayerByUserId(receipt.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receipt.ProductId == Config.ReviveProductId then
		local pos = lastPos[plr.UserId]
		plr:LoadCharacter()
		if pos then
			local char = plr.Character or plr.CharacterAdded:Wait()
			local root = char:WaitForChild("HumanoidRootPart")
			task.wait(0.2)
			root.CFrame = pos + Vector3.new(0, 3, 0)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end
