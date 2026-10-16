-- MapBuilder: строит окружение уровня кодом при запуске сервера.
-- Зал, стены, потолок с лампами, освещение, туман, спавн, выход — всё тут.
-- Энтити (Verity, Pirate Clark) строит отдельный EntityController.server.lua.
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

-- ===== шкафы-укрытия (логику навесит HideService по имени "HidingSpot") =====
local spotCount = Config.HideSpotCount or 0
for i = 1, spotCount do
	local z = -ROOM_L / 2 + 14 + (i - 1) * ((ROOM_L - 28) / math.max(1, spotCount - 1))
	part({
		Name = "HidingSpot",
		Size = Vector3.new(4, 7, 3),
		CFrame = CFrame.new(-ROOM_W / 2 + WALL_T + 1.6, 3.5, z),
		Color = Color3.fromRGB(70, 48, 32),
		Material = Enum.Material.WoodPlanks,
	})
end

print("[NeonBackrooms] Окружение построено кодом (AutoBuildMap = true). Энтити — в EntityController.")
