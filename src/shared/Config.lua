-- Одно место для всех ID монетизации. Человек впишет реальные ID после создания
-- Developer Product и Game Pass на сайте Roblox.
return {
	ReviveProductId = 0, -- << ID Developer Product "Revive"
	SprintPassId    = 0, -- << ID Game Pass "Sprint"
	WalkSpeed       = 16,
	SprintSpeed     = 28,

	-- ===== Авто-постройка карты (MapBuilder.server.lua) =====
	-- true  = карту, свет, монстра и выход строит код сам при запуске сервера.
	-- false = ничего не строится, всё делаешь руками в Studio (старый режим).
	AutoBuildMap   = true,

	MonsterSpeed   = 10,  -- скорость монстра (у игрока WalkSpeed = 16)
	AmbientSoundId = "",  -- гул ламп, напр. "rbxassetid://9112854440" (необязательно)
}
