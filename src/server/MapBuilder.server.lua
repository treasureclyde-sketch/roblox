-- MapBuilder: строит весь уровень кодом при запуске сервера.
-- Зал, стены, потолок с лампами, освещение, туман, спавн, монстр, выход — всё тут.
-- Выключается флагом Config.AutoBuildMap = false (тогда строишь руками в Studio).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

if not Config.AutoBuildMap then return end

-- ===== параметры зала =====
local ROOM_W   = 120 -- ширина (X)
local ROOM_L   = 90  -- длина (Z)
local WALL_H   = 22  -- высота стен
local WALL_T   = 2   -- толщина стен
local FLOOR_COLOR = Color3.fromRGB(194, 178, 128) -- #C2B280
local WALL_COLOR  = Color3.fromRGB(150, 140, 95)
local CEIL_COLOR  = Color3.fromRGB(120, 112, 80)

local world = workspace

-- общий контейнер, чтобы дерево было чистым и легко удалить всё разом
local map = Instance.new("Folder")
map.Name = "NeonBackroomsMap"
map.Parent = world

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	p.Parent = map
	return p
end

-- ===== пол / потолок / стены =====
part({ Name = "Floor", Size = Vector3.new(ROOM_W, 1, ROOM_L),
	CFrame = CFrame.new(0, -0.5, 0), Color = FLOOR_COLOR })

part({ Name = "Ceiling", Size = Vector3.new(ROOM_W, 1, ROOM_L),
	CFrame = CFrame.new(0, WALL_H + 0.5, 0), Color = CEIL_COLOR })

part({ Name = "WallPX", Size = Vector3.new(WALL_T, WALL_H, ROOM_L),
	CFrame = CFrame.new(ROOM_W / 2, WALL_H / 2, 0), Color = WALL_COLOR })
part({ Name = "WallNX", Size = Vector3.new(WALL_T, WALL_H, ROOM_L),
	CFrame = CFrame.new(-ROOM_W / 2, WALL_H / 2, 0), Color = WALL_COLOR })
part({ Name = "WallPZ", Size = Vector3.new(ROOM_W, WALL_H, WALL_T),
	CFrame = CFrame.new(0, WALL_H / 2, ROOM_L / 2), Color = WALL_COLOR })
part({ Name = "WallNZ", Size = Vector3.new(ROOM_W, WALL_H, WALL_T),
	CFrame = CFrame.new(0, WALL_H / 2, -ROOM_L / 2), Color = WALL_COLOR })

-- ===== панели света на потолке =====
for x = -ROOM_W / 2 + 15, ROOM_W / 2 - 15, 24 do
	for z = -ROOM_L / 2 + 12, ROOM_L / 2 - 12, 22 do
		local panel = part({
			Name = "LightPanel",
			Size = Vector3.new(10, 0.4, 5),
			CFrame = CFrame.new(x, WALL_H - 0.3, z),
			Color = Color3.fromRGB(255, 247, 200),
			Material = Enum.Material.Neon,
		})
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Color = Color3.fromRGB(255, 244, 190) -- холодный жёлтый
		light.Brightness = 3
		light.Range = 30
		light.Angle = 90
		light.Parent = panel
	end
end

-- ===== освещение / атмосфера =====
Lighting.Brightness = 1
Lighting.ClockTime = 0
Lighting.Ambient = Color3.fromRGB(25, 24, 18)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 20)
Lighting.GlobalShadows = true

local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmo.Density = 0.4
atmo.Haze = 2.5
atmo.Color = Color3.fromRGB(199, 190, 150)
atmo.Decay = Color3.fromRGB(106, 112, 125)
atmo.Parent = Lighting

-- ===== гул ламп =====
local hum = Instance.new("Sound")
hum.Name = "AmbientHum"
hum.Looped = true
hum.Volume = 0.5
if Config.AmbientSoundId ~= "" then
	hum.SoundId = Config.AmbientSoundId
	hum.Playing = true
end
hum.Parent = map

-- ===== спавн игрока =====
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, 0.5, -ROOM_L / 2 + 10)
spawn.Color = FLOOR_COLOR
spawn.Material = Enum.Material.SmoothPlastic
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = map

-- ===== выход + точка следующего уровня =====
local nextSpawn = part({
	Name = "NextLevelSpawn",
	Size = Vector3.new(4, 1, 4),
	CFrame = CFrame.new(0, 3, ROOM_L / 2 + 35),
	Transparency = 1,
	CanCollide = false,
})

local exit = part({
	Name = "ExitDoor",
	Size = Vector3.new(10, 14, 1),
	CFrame = CFrame.new(0, 7, ROOM_L / 2 - 1),
	Color = Color3.fromRGB(80, 255, 170),
	Material = Enum.Material.Neon,
})

local exitDebounce = {}
exit.Touched:Connect(function(hitPart)
	local char = hitPart.Parent
	local plr = char and Players:GetPlayerFromCharacter(char)
	if plr and not exitDebounce[plr.UserId] then
		exitDebounce[plr.UserId] = true
		if char.PrimaryPart then
			char:PivotTo(CFrame.new(nextSpawn.Position + Vector3.new(0, 3, 0)))
		else
			char:MoveTo(nextSpawn.Position)
		end
		task.wait(2)
		exitDebounce[plr.UserId] = nil
	end
end)

-- ===== монстр (Entity) =====
local monster = Instance.new("Model")
monster.Name = "Entity"

local mroot = Instance.new("Part")
mroot.Name = "HumanoidRootPart"
mroot.Size = Vector3.new(2.5, 6, 1.5)
mroot.Color = Color3.fromRGB(18, 18, 20)
mroot.Material = Enum.Material.SmoothPlastic
mroot.Anchored = false
mroot.CanCollide = true
mroot.Parent = monster

local mhead = Instance.new("Part")
mhead.Name = "Head"
mhead.Size = Vector3.new(2, 1.8, 1.8)
mhead.Color = Color3.fromRGB(10, 10, 12)
mhead.Material = Enum.Material.SmoothPlastic
mhead.CanCollide = false
mhead.CFrame = mroot.CFrame * CFrame.new(0, 3.9, 0)
mhead.Parent = monster

-- неоновые «глаза» для саспенса
for _, dx in ipairs({ -0.5, 0.5 }) do
	local eye = Instance.new("Part")
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(0.35, 0.35, 0.35)
	eye.Color = Color3.fromRGB(255, 40, 40)
	eye.Material = Enum.Material.Neon
	eye.CanCollide = false
	eye.CFrame = mhead.CFrame * CFrame.new(dx, 0.2, -0.9)
	eye.Parent = monster
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = mhead, eye
	w.Parent = eye
end

local wHead = Instance.new("WeldConstraint")
wHead.Part0, wHead.Part1 = mroot, mhead
wHead.Parent = mhead

local mhum = Instance.new("Humanoid")
mhum.WalkSpeed = Config.MonsterSpeed
mhum.HipHeight = mroot.Size.Y / 2
mhum.Parent = monster

monster.PrimaryPart = mroot
monster.Parent = map
monster:PivotTo(CFrame.new(0, mroot.Size.Y / 2 + mhum.HipHeight, ROOM_L / 4))

-- смерть игрока при касании монстра
local function wireTouchKill(p)
	p.Touched:Connect(function(hit)
		local char = hit.Parent
		local h = char and char:FindFirstChildOfClass("Humanoid")
		if h and Players:GetPlayerFromCharacter(char) then
			h.Health = 0
		end
	end)
end
wireTouchKill(mroot)
wireTouchKill(mhead)

-- преследование ближайшего игрока
local function nearest()
	local best, dist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = (hrp.Position - mroot.Position).Magnitude
			if d < dist then best, dist = hrp, d end
		end
	end
	return best
end

task.spawn(function()
	while task.wait(0.4) do
		if mhum.Health <= 0 then break end
		local target = nearest()
		if target then
			mhum:MoveTo(target.Position)
		end
	end
end)

print("[NeonBackrooms] Карта построена кодом (AutoBuildMap = true).")
