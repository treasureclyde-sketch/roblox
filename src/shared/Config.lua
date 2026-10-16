-- Одно место для всех ID монетизации и настроек игры.
-- Человек впишет реальные ID после создания Developer Product и Game Pass на сайте Roblox.
return {
	-- ===== монетизация =====
	ReviveProductId = 0, -- << ID Developer Product "Revive"
	SprintPassId    = 0, -- << ID Game Pass "Sprint"
	WalkSpeed       = 16,
	SprintSpeed     = 28,

	-- ===== авто-постройка карты (MapBuilder.server.lua) =====
	-- true  = зал/свет/туман/спавн/выход строит код сам при запуске сервера.
	-- false = ничего не строится, карту делаешь руками в Studio (src/manual/).
	AutoBuildMap   = true,
	AmbientSoundId = "", -- гул ламп, напр. "rbxassetid://9112854440" (необязательно)

	-- ===== прогрессия «дней в Бэкрумс» (DayService.lua) =====
	IncrementDayOnJoin = true, -- каждый заход игрока = +1 день (сохраняется в DataStore)
	UneasyDay          = 2,    -- с какого дня Verity делается тревожной
	HostileDay         = 3,    -- с какого дня Verity становится злой (меняет модель)
	DayStoreName       = "NeonBackroomsDays_v1", -- имя DataStore (не меняй после релиза)

	-- ===== энтити и подключение твоих моделей =====
	-- Положи СВОИ модели в папку ReplicatedStorage/Entities (создай её руками в Studio)
	-- с ТОЧНО такими именами. Нет модели — движок построит процедурную заглушку.
	EntitiesFolderName  = "Entities",
	VerityFriendlyModel = "VerityFriendly", -- добрый/тревожный шар (день 1-2)
	VerityEvilModel     = "VerityEvil",     -- злая форма Verity (день 3+)
	PirateClarkModel    = "PirateClark",    -- враждебный энтити (с 1-го дня)

	-- ===== поведение энтити =====
	VerityFollowDist   = 12,  -- на какой дистанции шар держится от игрока
	VerityHoverHeight  = 4,   -- высота парения над полом
	VerityFloatSpeed   = 6,   -- скорость парящего шара (заглушка/безногая модель)
	VerityHintCooldown = 12,  -- пауза между подсказками, сек
	VeritySpeakRange   = 40,  -- на какой дистанции Verity вообще заговаривает
	HostileSpeed       = 14,  -- скорость злой Verity (у игрока 16 — почти догоняет)
	PirateClarkEnabled = true,
	PirateClarkSpeed   = 12,

	-- ===== укрытия и защита от Кларка =====
	HideSpotCount  = 4,  -- сколько шкафов-укрытий строит MapBuilder
	FlareCharges   = 3,  -- вспышек на одну жизнь (клавиша F / кнопка на телефоне)
	ClarkStunTime  = 4,  -- на сколько секунд вспышка оглушает Кларка
	ClarkStunRange = 22, -- дистанция, на которой вспышка достаёт Кларка
}
