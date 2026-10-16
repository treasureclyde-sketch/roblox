# Neon Backrooms: Level 0

Roblox-игра в жанре лиминального хоррора (Backrooms-style) с монетизацией и
сюжетным энтити, который звереет со временем. Код синкается в Roblox Studio через
[Rojo](https://rojo.space). Карту строит код сам; тебе остаётся вставить свои
модели и настроить монетизацию.

## Главная фишка — энтити **Verity**

Verity — твой «проводник», который меняется в зависимости от того, сколько **дней**
игрок провёл в Бэкрумс (счётчик сохраняется между заходами, виден в лидерборде):

| День | Стадия | Поведение |
|------|--------|-----------|
| 1 | 🙂 **friendly** | добрый парящий шар, парит рядом, **даёт подсказки** к выходу |
| 2 | 😐 **uneasy** | тревожный, подсказки мутные, тон злее, цвет холоднее |
| 3+ | 😈 **hostile** | **МЕНЯЕТ модель на злую**, преследует и убивает касанием |

Плюс **Pirate Clark** — враждебный энтити с 1-го дня: преследует и убивает.

Реплики Verity лежат в `src/shared/VerityDialogue.lua` — правь их как хочешь.
Пороги дней (`UneasyDay`, `HostileDay`), скорости и дистанции — в `src/shared/Config.lua`.

## Как подключить СВОИ модели (Verity злая, Pirate Clark и т.д.)

3D-модели нельзя затащить из Google Drive в код — они живут внутри Studio как
ассеты. Поэтому схема такая:

1. Импортируй модель в Studio (меш/риг → собери в один **Model**).
2. В **ReplicatedStorage** создай папку с именем **`Entities`** (руками, один раз).
3. Положи туда модели с **ТОЧНО** такими именами:
   - **`VerityFriendly`** — добрый/тревожный шар (день 1–2). Если это просто меш
     без Humanoid — движок будет её «парить» за игроком.
   - **`VerityEvil`** — злая форма (день 3+). Сделай это **Humanoid-риг**
     (Humanoid + HumanoidRootPart, `PrimaryPart = HumanoidRootPart`) — тогда она
     будет ходить и гнаться. Анимацию навесишь сам на риг.
   - **`PirateClark`** — враждебный энтити. Тоже Humanoid-риг.
4. Всё. Движок сам клонирует модель и подключает к ней логику (настроение,
   преследование, убийство касанием, реплики).

> Папку `Entities` создавай **руками в Studio**, НЕ через Rojo — иначе синк может
> затереть вложенные модели. Rojo управляет только тем, что описано в
> `default.project.json`.

**Пока моделей нет** — движок строит процедурные заглушки (шар + блочные риги с
красными глазами), так что игра полностью играбельна уже сейчас, а твои модели
встанут на место без единой правки кода.

## Структура

```
.
├── default.project.json        -- конфиг Rojo
└── src/
    ├── shared/
    │   ├── Config.lua               -- ID монетизации + все настройки игры
    │   └── VerityDialogue.lua       -- реплики Verity по стадиям
    ├── server/
    │   ├── ReviveHandler.server.lua -- обработка покупок, Revive после смерти
    │   ├── MapBuilder.server.lua    -- строит зал/свет/туман/спавн/выход
    │   ├── DayService.lua           -- счётчик дней (DataStore) + стадия настроения
    │   └── EntityController.server.lua -- ВСЯ логика энтити (Verity + Pirate Clark)
    ├── client/
    │   ├── RevivePrompt.client.lua  -- окно покупки Revive после смерти
    │   └── SprintPass.client.lua    -- Shift = спринт для владельцев пасса
    └── manual/                      -- НЕ синкается Rojo (старый ручной режим, опционально)
        ├── EntityAI.server.lua
        └── ExitDoor.server.lua
```

## Как синкнуть в Studio

1. Поставь Rojo: плагин **Rojo** в Studio (Plugins → Manage Plugins) + CLI
   (`cargo install rojo` или бинарник с [rojo.space](https://rojo.space)).
2. В корне проекта: `rojo serve`
3. В Studio: вкладка **Rojo** → **Connect**. Скрипты появятся в дереве.
4. Жми **Play** — зал, свет, Verity и Pirate Clark уже на месте.

## Настройки (`src/shared/Config.lua`)

- `AutoBuildMap` — `true`: зал/свет/выход строит код; `false`: строишь руками (`src/manual/`).
- `UneasyDay` / `HostileDay` — на какой день Verity тревожная / злая (по умолч. 2 / 3).
- `IncrementDayOnJoin` — каждый заход = +1 день (так «накручивается» прогрессия).
- `HostileSpeed`, `PirateClarkSpeed`, `VerityFollowDist`, `VeritySpeakRange` и т.д.
- `ReviveProductId`, `SprintPassId` — ID монетизации (впишешь после публикации).
- `AmbientSoundId` — гул ламп, `rbxassetid://...` (необязательно).

### Как протестить злую форму, не наигрывая 3 дня
`IncrementDayOnJoin = true` — каждый повторный заход добавляет день. Либо в
командной строке Studio (вкладка **Model** → **Command Bar**) принудительно:
```lua
require(game.ServerScriptService.DayService).set(game.Players:GetPlayers()[1], 3)
```
и Verity на глазах сменит форму на злую.

## Монетизация (на create.roblox.com)

- [ ] File → **Publish to Roblox** (сначала опубликовать, иначе пассы не создать).
- [ ] Monetization → **Developer Products** → "Revive" (~20 Robux) → скопировать ID.
- [ ] Monetization → **Passes** → "Sprint" (~75 Robux) → скопировать ID.
- [ ] Вписать оба ID в `Config.lua` (`ReviveProductId`, `SprintPassId`), пересинкнуть.

> DataStore (счётчик дней) в Studio работает только если включить
> **Game Settings → Security → Enable Studio Access to API Services**. Без него игра
> не падает, но прогресс дней в Studio не сохраняется (на боевом сервере — сохраняется).

## Ручной режим карты (только если `AutoBuildMap = false`)

Тогда строишь зал сам и вставляешь скрипты из `src/manual/` (EntityAI в модель
монстра, ExitDoor в Part-выход). При `AutoBuildMap = true` это не нужно.

## Апгрейды на потом
- Монстр через **PathfindingService** (обход стен).
- Анимации на риги Verity/Clark (AnimationController + Animator).
- Процедурная генерация комнат, мигающий свет, звук шагов.
- Несколько уровней Бэкрумс, отдельные энтити на каждом.
