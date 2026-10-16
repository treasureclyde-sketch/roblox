-- DayService: считает «дни, проведённые в Бэкрумс» для каждого игрока.
-- Сохраняется между сессиями через DataStore. В Studio без включённого
-- "Enable Studio Access to API Services" DataStore недоступен — тогда работает
-- запасной режим в памяти (прогресс не сохранится, но игра не падает).
--
-- ModuleScript. Требуется из EntityController и server-скриптов.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

local DayService = {}

local store
local ok = pcall(function()
	store = DataStoreService:GetDataStore(Config.DayStoreName)
end)
if not ok then store = nil end

local days = {}       -- UserId -> number (кэш текущей сессии)
local memoryOnly = {} -- UserId -> true, если DataStore не сработал (не сохраняем)

-- возвращает (value, ok): value может быть nil (первый заход), ok=false при сбое DataStore
local function load(userId)
	if not store then return nil, false end
	local value
	local success = pcall(function()
		value = store:GetAsync("u_" .. userId)
	end)
	return value, success
end

local function save(userId, value)
	if not store or memoryOnly[userId] then return end
	pcall(function()
		store:SetAsync("u_" .. userId, value)
	end)
end

-- Вызвать при входе игрока: загружает/увеличивает день и вешает leaderstats.
function DayService.setup(plr)
	local stored, ok = load(plr.UserId)
	if not ok then
		-- DataStore недоступен (Studio без API-доступа) — не сохраняем, не спамим ошибками
		memoryOnly[plr.UserId] = true
	end
	if stored == nil then
		stored = 0 -- первый заход
	end

	local current = stored
	if Config.IncrementDayOnJoin then
		current = stored + 1
	end
	if current < 1 then current = 1 end

	days[plr.UserId] = current
	save(plr.UserId, current)

	-- leaderstats: игрок видит «День N»
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = plr
	end
	local dayVal = leaderstats:FindFirstChild("День")
	if not dayVal then
		dayVal = Instance.new("IntValue")
		dayVal.Name = "День"
		dayVal.Parent = leaderstats
	end
	dayVal.Value = current

	return current
end

function DayService.get(plr)
	return days[plr.UserId] or 1
end

-- Принудительно задать день (для теста/событий). Сохраняет и обновляет leaderstats.
function DayService.set(plr, value)
	value = math.max(1, math.floor(value))
	days[plr.UserId] = value
	save(plr.UserId, value)
	local ls = plr:FindFirstChild("leaderstats")
	local dv = ls and ls:FindFirstChild("День")
	if dv then dv.Value = value end
	return value
end

-- Стадия настроения Verity по числу дней.
function DayService.tierFor(day)
	if day >= Config.HostileDay then
		return "hostile"
	elseif day >= Config.UneasyDay then
		return "uneasy"
	end
	return "friendly"
end

-- Удобный хелпер: стадия конкретного игрока.
function DayService.tier(plr)
	return DayService.tierFor(DayService.get(plr))
end

Players.PlayerRemoving:Connect(function(plr)
	days[plr.UserId] = nil
	memoryOnly[plr.UserId] = nil
end)

return DayService
