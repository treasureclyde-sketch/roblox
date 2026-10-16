-- HideService: укрытия (шкафы). Игрок подходит к части с именем "HidingSpot",
-- жмёт E (ProximityPrompt) — прячется. Пока спрятан:
--   * у игрока атрибут Hidden = true → энтити его не выбирают целью и не убивают
--     касанием (см. EntityController.nearestPlayer / makeKiller);
--   * HumanoidRootPart заякорен (игрок «сидит» в шкафу), жмёт E ещё раз — выходит.
-- Один шкаф = одно место (атрибут OccupiedBy на части).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local occupantSpot = {} -- UserId -> BasePart (где спрятан)

local function exitHide(plr)
	local spot = occupantSpot[plr.UserId]
	if not spot then return end
	occupantSpot[plr.UserId] = nil
	if spot:GetAttribute("OccupiedBy") == plr.UserId then
		spot:SetAttribute("OccupiedBy", nil)
	end
	local prompt = spot:FindFirstChild("HidePrompt")
	if prompt then prompt.ActionText = "Спрятаться" end

	plr:SetAttribute("Hidden", false)
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp then
		hrp.Anchored = false
		-- слегка вытолкнуть из шкафа «в комнату» (в сторону +X от стены)
		hrp.CFrame = spot.CFrame * CFrame.new(4, -1, 0)
	end
	if hum then hum.AutoRotate = true end
end

local function enterHide(plr, spot, prompt)
	if spot:GetAttribute("OccupiedBy") then return end -- занято
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	occupantSpot[plr.UserId] = spot
	spot:SetAttribute("OccupiedBy", plr.UserId)
	prompt.ActionText = "Выйти"

	plr:SetAttribute("Hidden", true)
	hum.AutoRotate = false
	-- втянуть игрока в шкаф и заякорить
	hrp.CFrame = spot.CFrame * CFrame.new(0, -1, 0)
	hrp.Anchored = true
end

local function toggleHide(plr, spot, prompt)
	if occupantSpot[plr.UserId] == spot then
		exitHide(plr)
	else
		enterHide(plr, spot, prompt)
	end
end

local function setupSpot(spot)
	if not spot:IsA("BasePart") then return end
	if spot:FindFirstChild("HidePrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HidePrompt"
	prompt.ActionText = "Спрятаться"
	prompt.ObjectText = "Шкаф"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = spot
	prompt.Triggered:Connect(function(plr)
		toggleHide(plr, spot, prompt)
	end)
end

-- навесить на уже существующие шкафы и на новые (напр. от Rojo/MapBuilder)
local function scan()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") and inst.Name == "HidingSpot" then
			setupSpot(inst)
		end
	end
end

workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("BasePart") and inst.Name == "HidingSpot" then
		setupSpot(inst)
	end
end)
-- также поддержим тег "HidingSpot" (CollectionService), если делаешь укрытия руками
CollectionService:GetInstanceAddedSignal("HidingSpot"):Connect(setupSpot)
for _, t in ipairs(CollectionService:GetTagged("HidingSpot")) do setupSpot(t) end

task.defer(scan)

-- если игрок умер/вышел пока спрятан — освободить шкаф
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		plr:SetAttribute("Hidden", false)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			exitHide(plr)
		end)
	end)
end)
Players.PlayerRemoving:Connect(function(plr)
	local spot = occupantSpot[plr.UserId]
	if spot and spot:GetAttribute("OccupiedBy") == plr.UserId then
		spot:SetAttribute("OccupiedBy", nil)
	end
	occupantSpot[plr.UserId] = nil
end)
