-- Defense (клиент): вспышка против Pirate Clark.
--   ПК: клавиша F.  Телефон/планшет: кнопка на экране.
-- Логику (оглушение, расход зарядов) считает сервер в EntityController.
-- На экране — счётчик вспышек (атрибут Flares игрока).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local defendEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Defend")

local function flare()
	defendEvent:FireServer()
end

-- ПК: F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		flare()
	end
end)

-- Телефон: экранная кнопка
ContextActionService:BindAction("NB_Flare", function(_, state)
	if state == Enum.UserInputState.Begin then flare() end
end, true, Enum.KeyCode.F)
ContextActionService:SetTitle("NB_Flare", "Вспышка")

-- ===== индикатор зарядов =====
local gui = Instance.new("ScreenGui")
gui.Name = "DefenseHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = plr:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -16)
label.Size = UDim2.new(0, 220, 0, 34)
label.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
label.BackgroundTransparency = 0.35
label.TextColor3 = Color3.fromRGB(255, 230, 120)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Text = "Вспышки: ?"
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = label

local function refresh()
	local n = plr:GetAttribute("Flares") or 0
	label.Text = "Вспышки (F): " .. tostring(n)
	label.TextColor3 = (n > 0) and Color3.fromRGB(255, 230, 120) or Color3.fromRGB(150, 150, 150)
end

plr:GetAttributeChangedSignal("Flares"):Connect(refresh)
refresh()
