# Neon Backrooms: Level 0

Roblox-игра в жанре лиминального хоррора (Backrooms-style) с монетизацией.
Код синхронизируется в Roblox Studio через [Rojo](https://rojo.space). Карту и
монетизацию доделываешь вручную в Studio (см. чеклист ниже).

## Структура

```
.
├── default.project.json        -- конфиг Rojo
└── src/
    ├── shared/
    │   └── Config.lua              -- ModuleScript → ReplicatedStorage.Config (ID монетизации + настройки карты)
    ├── server/
    │   ├── ReviveHandler.server.lua -- Script → ServerScriptService (обработка покупок, Revive)
    │   └── MapBuilder.server.lua    -- Script → ServerScriptService (СТРОИТ ВЕСЬ УРОВЕНЬ КОДОМ)
    ├── client/
    │   ├── RevivePrompt.client.lua  -- LocalScript → StarterPlayerScripts (окно покупки после смерти)
    │   └── SprintPass.client.lua    -- LocalScript → StarterPlayerScripts (Shift = спринт для владельцев пасса)
    └── manual/                      -- НЕ синкается Rojo! (старый ручной режим, опционально)
        ├── EntityAI.server.lua      -- Script внутрь модели монстра
        └── ExitDoor.server.lua      -- Script внутрь Part-выхода
```

## Авто-постройка карты (главное!)

`MapBuilder.server.lua` строит **весь уровень кодом** при запуске сервера: зал,
стены, потолок с лампами, тёмное освещение + туман (Atmosphere/Haze), спавн, монстра
с красными неоновыми глазами и светящийся выход. Руками в Studio карту строить
**не нужно** — просто синкни код и жми **Play**.

Управляется через `src/shared/Config.lua`:
- `AutoBuildMap = true` — карта строится сама (по умолчанию).
- `AutoBuildMap = false` — ничего не строится, собираешь руками (чеклист «Ручной режим» ниже).
- `MonsterSpeed` — скорость монстра. `AmbientSoundId` — гул ламп (вставь `rbxassetid://...`, необязательно).

> Папка `src/manual/` намеренно не указана в `default.project.json`, поэтому Rojo
> её не переносит. Эти скрипты нужны только если делаешь карту руками (`AutoBuildMap = false`).

## Как синкнуть в Studio

1. Установи Rojo: плагин **Rojo** в Studio (вкладка Plugins → Manage Plugins) + CLI
   (`cargo install rojo`, или скачай бинарник с [rojo.space](https://rojo.space)).
2. В корне проекта запусти: `rojo serve`
3. В Studio: вкладка **Rojo** → **Connect**. Скрипты появятся в дереве автоматически.
4. Файлы из `src/manual/` Rojo НЕ переносит — вставляешь руками (см. ниже).

## Ручной режим в Studio (только если `AutoBuildMap = false`)

> При `AutoBuildMap = true` (по умолчанию) всё ниже делает код сам — пропускай.

### Карта и атмосфера
- [ ] Baseplate → зал из Part: пол (жёлто-бежевый `#C2B280`, SmoothPlastic),
      стены (высокие Part, обои), потолок с панелями света. Всё **Anchored = true**.
- [ ] Lighting: `Brightness` ≈ 1, `ClockTime` = 0, `Ambient` тёмный.
- [ ] В Lighting вставить **Atmosphere**, `Density` ≈ 0.4, добавить Haze — мутная дымка.
- [ ] В потолок — PointLight / SurfaceLight, холодный жёлтый.
- [ ] В Workspace — Sound с гулом ламп (`Looped = true`, `Playing = true`).
- [ ] Поставить **SpawnLocation** на старте.

### Монстр
- [ ] Вставить риг с Humanoid, назвать модель **Entity**, задать `PrimaryPart = HumanoidRootPart`.
- [ ] Внутрь модели вставить Script с кодом из `src/manual/EntityAI.server.lua`.

### Выход
- [ ] Поставить яркий Part-выход в конце, внутрь — Script из `src/manual/ExitDoor.server.lua`.
- [ ] Дальше поставить пустой Part с именем **NextLevelSpawn**.

### Публикация и монетизация (на create.roblox.com)
- [ ] File → **Publish to Roblox** (сначала опубликовать, иначе пассы не создать).
- [ ] Monetization → **Developer Products** → Create "Revive", цена ~20 Robux → скопировать ID.
- [ ] Monetization → **Passes** → Create "Sprint", цена ~75 Robux → скопировать ID.
- [ ] Вписать оба ID в `src/shared/Config.lua` (`ReviveProductId`, `SprintPassId`), пересинкнуть.

### Проверка
- [ ] Play: монстр идёт к игроку, касание убивает.
- [ ] После смерти всплывает окно покупки Revive.
- [ ] Касание выхода телепортит на NextLevelSpawn.
- [ ] (если куплен Sprint) Shift ускоряет.

## Апгрейды на потом
- Монстр через **PathfindingService**, чтобы обходил стены.
- Процедурная генерация комнат вместо ручной.
- Несколько уровней, мигающий свет, звук шагов монстра для саспенса.
- Лидерборд «кто дальше прошёл».
