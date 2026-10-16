local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))
local plr = Players.LocalPlayer

if Config.SprintPassId <= 0 then return end

local owns = false
local ok, res = pcall(function()
	return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, Config.SprintPassId)
end)
if ok then owns = res end
if not owns then return end

local function hum()
	return plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		local h = hum(); if h then h.WalkSpeed = Config.SprintSpeed end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		local h = hum(); if h then h.WalkSpeed = Config.WalkSpeed end
	end
end)
