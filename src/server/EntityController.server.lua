-- EntityController: вся логика энтити Neon Backrooms.
--
--  * Verity — конечный автомат настроения, зависит от «дней в Бэкрумс» (DayService):
--      friendly (день 1)  — добрый парящий шар, даёт подсказки к выходу;
--      uneasy   (день 2)  — тревожный, подсказки мутные, тон злее;
--      hostile  (день 3+) — МЕНЯЕТ модель на злую, преследует и убивает касанием.
--  * Pirate Clark — враждебный энтити с 1-го дня: преследует и убивает.
--
-- Твои модели: положи в ReplicatedStorage/<EntitiesFolderName> модели с именами
-- VerityFriendlyModel / VerityEvilModel / PirateClarkModel (см. Config).
-- Нет модели — строится процедурная заглушка, игра работает сразу.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Dialogue = require(ReplicatedStorage:WaitForChild("VerityDialogue"))
local DayService = require(ServerScriptService:WaitForChild("DayService"))

-- ============================================================ утилиты

local MOOD_COLOR = {
	friendly = Color3.fromRGB(120, 210, 255), -- мягкий голубой
	uneasy   = Color3.fromRGB(210, 160, 70),  -- тревожный янтарный
	hostile  = Color3.fromRGB(255, 45, 45),   -- красный
}

local entitiesFolder = ReplicatedStorage:FindFirstChild(Config.EntitiesFolderName)

-- клон пользовательской модели из ReplicatedStorage/Entities или nil
local function cloneUserModel(name)
	if not entitiesFolder then return nil end
	local src = entitiesFolder:FindFirstChild(name)
	if src and src:IsA("Model") then
		return src:Clone()
	end
	return nil
end

-- привести произвольную модель к виду {model, primary, humanoid}
local function wrapModel(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local primary = model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChildWhichIsA("BasePart", true)
	if primary and not model.PrimaryPart then
		model.PrimaryPart = primary
	end
	return { model = model, primary = primary, humanoid = humanoid }
end

local function setAnchored(model, state)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = state end
	end
end

local function nameTag(adornee, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Adornee = adornee
	gui.Size = UDim2.new(0, 160, 0, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	gui.Parent = adornee
	return label
end

-- убивать игроков касанием любой части модели
local function makeKiller(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Touched:Connect(function(hit)
				local char = hit.Parent
				local h = char and char:FindFirstChildOfClass("Humanoid")
				if h and h.Health > 0 and Players:GetPlayerFromCharacter(char) then
					h.Health = 0
				end
			end)
		end
	end
end

-- собственный речевой бабл над энтити (не зависит от Legacy/TextChatService)
local function say(primary, text)
	if not primary or not text then return end
	local bubble = primary:FindFirstChild("SpeechBubble")
	if not bubble then
		bubble = Instance.new("BillboardGui")
		bubble.Name = "SpeechBubble"
		bubble.Adornee = primary
		bubble.Size = UDim2.new(0, 260, 0, 72)
		bubble.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
		bubble.AlwaysOnTop = true
		bubble.Parent = primary

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
		label.BackgroundTransparency = 0.3
		label.TextColor3 = Color3.fromRGB(238, 238, 238)
		label.Font = Enum.Font.Gotham
		label.TextScaled = true
		label.TextWrapped = true
		label.Parent = bubble
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = label
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = label
	end

	bubble.Text.Text = text
	bubble.Enabled = true
	local token = (primary:GetAttribute("BubbleToken") or 0) + 1
	primary:SetAttribute("BubbleToken", token)
	task.delay(4.5, function()
		if primary and primary.Parent and primary:GetAttribute("BubbleToken") == token then
			bubble.Enabled = false
		end
	end)
end

-- ближайший живой игрок к точке
local function nearestPlayer(pos)
	local best, bestPlr, dist = nil, nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - pos).Magnitude
			if d < dist then best, bestPlr, dist = hrp, plr, d end
		end
	end
	return best, bestPlr, dist
end

-- ============================================================ заглушки моделей

-- парящий шар (друг/тревога)
local function buildOrb(tier)
	local model = Instance.new("Model")
	model.Name = "Verity"
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(3, 3, 3)
	core.Material = Enum.Material.Neon
	core.Color = MOOD_COLOR[tier] or MOOD_COLOR.friendly
	core.Anchored = true
	core.CanCollide = false
	core.Parent = model
	model.PrimaryPart = core
	local light = Instance.new("PointLight")
	light.Color = core.Color
	light.Range = 18
	light.Brightness = 2
	light.Parent = core
	return wrapModel(model)
end

-- гуманоид-преследователь (злая Verity / Pirate Clark заглушка)
local function buildRig(name, color, eyeColor)
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.5, 6, 1.5)
	root.Color = color
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = false
	root.CanCollide = true
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1.8, 1.8)
	head.Color = color
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.CFrame = root.CFrame * CFrame.new(0, 3.9, 0)
	head.Parent = model
	local wHead = Instance.new("WeldConstraint")
	wHead.Part0, wHead.Part1 = root, head
	wHead.Parent = head

	for _, dx in ipairs({ -0.5, 0.5 }) do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.35, 0.35, 0.35)
		eye.Color = eyeColor
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.CFrame = head.CFrame * CFrame.new(dx, 0.2, -0.9)
		eye.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = head, eye
		w.Parent = eye
	end

	local hum = Instance.new("Humanoid")
	hum.HipHeight = root.Size.Y / 2
	hum.Parent = model

	model.PrimaryPart = root
	return wrapModel(model)
end

-- ============================================================ Verity

local Verity = {
	entry = nil,   -- {model, primary, humanoid}
	form = nil,    -- "orb" | "hostile"
	tier = nil,    -- "friendly" | "uneasy" | "hostile"
	lastHint = 0,
}

local function clearVerity()
	if Verity.entry and Verity.entry.model then
		Verity.entry.model:Destroy()
	end
	Verity.entry = nil
end

local function spawnVerity(tier, atCFrame)
	clearVerity()
	local form = (tier == "hostile") and "hostile" or "orb"
	local entry

	if form == "hostile" then
		local user = cloneUserModel(Config.VerityEvilModel)
		entry = user and wrapModel(user) or buildRig("Verity", Color3.fromRGB(20, 18, 22), MOOD_COLOR.hostile)
		-- хостайл ходит физикой: части НЕ якорим
		makeKiller(entry.model)
	else
		local user = cloneUserModel(Config.VerityFriendlyModel)
		if user then
			entry = wrapModel(user)
			setAnchored(entry.model, true) -- парящая форма управляется кодом (PivotTo)
			entry.humanoid = nil
		else
			entry = buildOrb(tier)
		end
	end

	if entry.primary then
		nameTag(entry.primary, "Verity", MOOD_COLOR[tier] or MOOD_COLOR.friendly)
	end
	entry.model.Parent = workspace
	if atCFrame and entry.model.PrimaryPart then
		entry.model:PivotTo(atCFrame)
	end
	if entry.humanoid then
		entry.humanoid.WalkSpeed = Config.HostileSpeed
	end

	Verity.entry = entry
	Verity.form = form
	Verity.tier = tier
	Verity.lastHint = os.clock() -- чтобы приветствие и первая подсказка не наложились
	say(entry.primary, Dialogue.line(tier, "greet"))
end

-- старт Verity в дружелюбной форме у центра
spawnVerity("friendly", CFrame.new(0, Config.VerityHoverHeight, -10))

-- ============================================================ Pirate Clark

local Clark = nil
if Config.PirateClarkEnabled then
	local user = cloneUserModel(Config.PirateClarkModel)
	Clark = user and wrapModel(user)
		or buildRig("Pirate Clark", Color3.fromRGB(35, 25, 20), Color3.fromRGB(255, 200, 60))
	if Clark.primary then
		nameTag(Clark.primary, "Pirate Clark", Color3.fromRGB(255, 200, 60))
	end
	makeKiller(Clark.model)
	Clark.model.Parent = workspace
	if Clark.model.PrimaryPart then
		Clark.model:PivotTo(CFrame.new(-40, (Clark.humanoid and Clark.humanoid.HipHeight or 3), 25))
	end
	if Clark.humanoid then
		Clark.humanoid.WalkSpeed = Config.PirateClarkSpeed
	end
end

-- ============================================================ дни при входе

local function onPlayer(plr)
	DayService.setup(plr)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end

-- ============================================================ главный цикл

local function floatToward(entry, desiredPos, lookAt, dt)
	local cur = entry.primary.Position
	local delta = desiredPos - cur
	local dist = delta.Magnitude
	local step = Config.VerityFloatSpeed * dt
	local newPos = (dist <= step or dist < 0.05) and desiredPos or (cur + delta.Unit * step)
	entry.model:PivotTo(CFrame.lookAt(newPos, lookAt))
end

while true do
	local dt = task.wait(0.12)

	-- --- Verity ---
	if Verity.entry and Verity.entry.primary then
		local origin = Verity.entry.primary.Position
		local targetRoot, targetPlr = nearestPlayer(origin)

		if targetPlr then
			local wantTier = DayService.tier(targetPlr)

			-- смена формы (orb <-> hostile) при переходе через 3-й день
			local wantForm = (wantTier == "hostile") and "hostile" or "orb"
			if wantForm ~= Verity.form then
				spawnVerity(wantTier, CFrame.new(origin))
			elseif wantTier ~= Verity.tier then
				-- внутри парящей формы: сменить цвет/тон, поздороваться заново
				Verity.tier = wantTier
				if Verity.form == "orb" and Verity.entry.primary.Name == "Core" then
					Verity.entry.primary.Color = MOOD_COLOR[wantTier]
					local pl = Verity.entry.primary:FindFirstChildOfClass("PointLight")
					if pl then pl.Color = MOOD_COLOR[wantTier] end
				end
				say(Verity.entry.primary, Dialogue.line(wantTier, "greet"))
			end

			-- движение
			local tPos = targetRoot.Position
			if Verity.form == "hostile" and Verity.entry.humanoid then
				Verity.entry.humanoid:MoveTo(tPos)
			else
				local flat = (origin - tPos)
				flat = Vector3.new(flat.X, 0, flat.Z)
				if flat.Magnitude < 0.1 then flat = Vector3.new(0, 0, 1) end
				local desired = tPos + flat.Unit * Config.VerityFollowDist
					+ Vector3.new(0, Config.VerityHoverHeight, 0)
				floatToward(Verity.entry, desired, tPos, dt)
			end

			-- реплики
			local now = os.clock()
			local dist = (tPos - origin).Magnitude
			if now - Verity.lastHint >= Config.VerityHintCooldown and dist <= Config.VeritySpeakRange then
				Verity.lastHint = now
				local cat = (Verity.tier == "hostile") and "taunt" or "hint"
				say(Verity.entry.primary, Dialogue.line(Verity.tier, cat))
			end
		end
	end

	-- --- Pirate Clark ---
	if Clark and Clark.humanoid and Clark.primary then
		local targetRoot = nearestPlayer(Clark.primary.Position)
		if targetRoot then
			Clark.humanoid:MoveTo(targetRoot.Position)
		end
	end
end
