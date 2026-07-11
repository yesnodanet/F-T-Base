# F&T Base

[English](README.md) | [Русский](README.ru.md)

**Familia & Tarka Base** - оригинальная платформа разработки оружия для
Garry's Mod.

F&T Base не является клоном TFA, ARC9, ArcCW, MW Base, SWB или TacRP. Эти базы
могут служить ориентирами по удобству, возможностям и ожиданиям разработчиков,
но F&T Base имеет собственную архитектуру, компилятор, промежуточное
представление, runtime, API и модульные границы.

Главная идея проекта:

> Разработчик описывает намерение оружия. F&T Base компилирует это описание в
> единое внутреннее представление. Runtime исполняет только это представление.

## Статус проекта

Сейчас репозиторий содержит первую архитектурную реализацию платформы:

- загрузчик аддона;
- оригинальные lexer, parser, resolver, compiler и emitter;
- схему F&T IR;
- адаптеры стилей `FT`, `TFA`, `ARC9`, `ArcCW`, `MW`, `TacRP` и `SWB`;
- валидацию, оптимизацию, стратегии merge и compile reports;
- модульный runtime оружия;
- базовый SWEP;
- пример оружия со смешанными dialect-стилями;
- standalone API конвертера;
- документацию для разработчиков.

Это ранний фундамент, а не полностью готовая production-база оружия. Архитектура
специально сделана ближе к движку, чтобы новые системы можно было добавлять без
переписывания ядра.

## Зачем нужен F&T Base

Большинство weapon base заставляют разработчика писать оружие под один
конкретный runtime-стиль. F&T Base вместо этого относится к файлам оружия как к
исходному коду.

Разные синтаксические стили можно распарсить, нормализовать, провалидировать,
оптимизировать и исполнить через один runtime. Это полезно для:

- создания нового оружия через чистый F&T-native API;
- миграции legacy-оружия;
- смешивания знакомого синтаксиса во время перехода;
- конвертации между форматами weapon base;
- экспериментов с recoil, animation, camera и attachment системами;
- расширения платформы через plugins без правки core-кода.

## Pipeline компиляции

```text
Weapon File
  -> Lexer
  -> Parser
  -> Style Resolver
  -> AST
  -> F&T IR
  -> Validation
  -> Optimization
  -> Runtime Objects
  -> Weapon Engine
```

Runtime не исполняет логику внешних weapon base. Внешние namespaces принимаются
только как source dialects и переводятся в F&T IR.

## Смешивание namespaces

Один файл оружия может использовать несколько стилей одновременно:

```lua
using "TFA"
using "ARC9"
using "MW"
using "TacRP"

FT.Priority = {
    "ARC9",
    "MW",
    "TFA"
}

TFA.Primary.Damage = 35
TFA.Primary.ClipSize = 30

ARC9.Recoil.Up = 0.8
ARC9.Recoil.Side = 0.24

MW.Camera.Shake = 0.35
MW.Camera.Sway = 0.15

TacRP.BlindFire = true

FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
```

Каждый namespace обрабатывается собственным адаптером. Адаптеры не запускают
игровую логику. Они только переводят поля в IR-операции.

## Using directives

`using` импортирует namespace, чтобы поля можно было писать без префикса, если
значение однозначно:

```lua
using "TFA"

Primary.Damage = 35
Primary.ClipSize = 30
```

Если несколько импортированных стилей понимают одно и то же поле, компилятор
выдаст читаемую ошибку и предложит явно указать нужный namespace.

## Merge system

Когда несколько стилей записывают одно и то же поле IR, F&T Base применяет
настраиваемые merge-правила.

Поддерживаемые стратегии:

- `override`;
- `first`;
- `last`;
- `average`;
- `maximum`;
- `minimum`;
- `multiply`;
- custom Lua functions через compiler API.

Пример:

```lua
FT.Priority = {
    "ARC9",
    "MW",
    "TFA"
}

FT.Merge = {
    ["damage.base"] = "maximum",
    ["recoil.scalar"] = "multiply"
}
```

## Compile reports

Каждая компиляция создает отчет, в котором есть:

- примененные свойства;
- проигнорированные свойства;
- конфликты;
- warnings;
- заметки оптимизатора;
- неизвестные поля;
- deprecated-синтаксис;
- отсутствующие animations;
- отсутствующие sounds;
- некорректные attachments;
- performance suggestions.

Отчеты рассчитаны на разработчиков, а не только на машины. Цель - сделать
разработку оружия ближе к работе с полноценным SDK.

## Runtime modules

Runtime разделен на независимые модули:

- Core;
- Prediction;
- Networking;
- Weapon Lifecycle;
- Ballistics;
- Precision Recoil;
- Camera;
- Animation;
- Attachments;
- Sound;
- Movement;
- Effects;
- Rendering;
- NPC;
- Vehicles;
- Physics;
- Customization;
- Developer Tools;
- Debug;
- Profiler;
- Utilities.

Каждый модуль потребляет F&T IR и предоставляет понятный интерфейс.

## Ballistics

IR рассчитан на описание:

- hitscan weapons;
- projectile weapons;
- hybrid weapons;
- travel time;
- drag;
- gravity;
- wind;
- penetration;
- armor;
- ricochet;
- fragments;
- material responses;
- custom damage curves.

Текущий runtime содержит первый слой реализации для hitscan и projectile
dispatch. Более сложную физическую симуляцию можно развивать за тем же IR
контрактом.

## Precision Recoil

F&T Base включает precision recoil model с поддержкой точного per-shot pattern.

Pattern entry может задавать horizontal movement, vertical movement, roll,
camera influence, weapon influence, recovery, randomness и animation hints.

Компактный синтаксис:

```lua
FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
```

Расширенное намерение:

```lua
FT.Recoil.Pattern = {
    {
        horizontal = 0.4,
        vertical = 1.2,
        roll = 0,
        camera = 1,
        weapon = 1,
        recovery = 1,
        randomness = 0
    }
}
```

Такой формат оставляет место для CS-style, Valorant-style, Rust-style, random,
hybrid, procedural и полностью вручную заданного recoil behavior.

## Camera engine

Camera IR поддерживает модульное поведение:

- shake;
- sway;
- free aim;
- spring physics;
- breathing;
- landing effects;
- sprint movement;
- micro jitter;
- deadzone;
- aim transitions.

Разные source styles могут добавлять camera-данные, но runtime все равно видит
единую camera model.

## Animation engine

Animation schema построена вокруг:

- base animation maps;
- layered animation state;
- IK data;
- procedural animation hooks;
- animation events;
- animation curves;
- reload stages;
- inspect animation;
- partial-body data.

## Attachment engine

Attachment schema поддерживает:

- universal slots;
- nested attachments;
- runtime-generated slots;
- dynamic modifiers;
- attachment inheritance;
- custom attachment types.

## Sound engine

F&T Base описывает звук как layered data:

- firing layers;
- mechanical layers;
- indoor tails;
- outdoor tails;
- distance layers;
- suppressed variants;
- occlusion configuration;
- suppression effects.

## Converter

F&T Converter парсит source text, компилирует его в F&T IR, затем генерирует
другой стиль.

```lua
local result = FTConverter.Convert(sourceText, "TFA", "ARC9")

print(result.output)
print(result.report:ToString())
```

Текущий generator поддерживает target styles:

- `FT`;
- `TFA`;
- `ARC9`;
- `ArcCW`;
- `MW`;
- `TacRP`;
- `SWB`.

Некоторые стили не могут напрямую выразить все возможности F&T. В таких случаях
converter сохраняет читаемый output и добавляет warnings.

## Минимальное F&T оружие

```lua
SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Example Rifle"
SWEP.Category = "F&T Base"
SWEP.Spawnable = true

SWEP.FTSource = [[
FT.Meta.Category = "F&T Base"
FT.Damage.Base = 35
FT.Fire.RPM = 650
FT.Ammo.ClipSize = 30
FT.Ammo.DefaultClip = 90
FT.Ammo.Type = "SMG1"
FT.Rendering.HoldType = "ar2"

FT.Sounds.Fire.Layers = {
    {
        sound = "Weapon_AR2.Single",
        role = "body"
    }
}

FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
]]
```

## Структура репозитория

```text
lua/
  autorun/
    ft_base_loader.lua
  ft_base/
    adapters/      Style adapters
    compiler/      Lexer, parser, resolver, compiler, emitter
    core/          IR, schema, merge, report, validation, optimization
    runtime/       Weapon engine modules
    util/          Shared utility helpers
  ft_converter/    Converter API and generators
  weapons/
    ft_base/       Base SWEP
    ft_example_mixed/
tools/
  ft_converter.lua
  ft_smoke_test.lua
docs/
  ARCHITECTURE.md
  COMPILER.md
  IR_SCHEMA.md
  CONVERTER.md
```

## Development smoke test

В Garry's Mod Lua окружении после загрузки аддона:

```lua
include("tools/ft_smoke_test.lua")
```

Smoke test компилирует mixed-style source file и печатает compile report.

## Правила дизайна

F&T Base следует нескольким жестким правилам:

- внешние weapon base никогда не являются runtime dependencies;
- adapters только переводят syntax;
- runtime потребляет только F&T IR;
- conflicts должны быть видимыми и читаемыми;
- unknown fields должны попадать в report, а не молча игнорироваться;
- plugins расширяют платформу без patching internals;
- developer experience важен не меньше, чем количество features.

## Roadmap

Планируемые следующие шаги:

- более широкое покрытие Lua parsing для legacy weapon files;
- более точная математическая конвертация между styles;
- advanced projectile simulation;
- полноценный attachment UI и persistence;
- более глубокие animation layers и IK helpers;
- networked customization state;
- developer overlay и in-game profiler panels;
- generated documentation для weapon packs;
- примеры plugin SDK.

## Документация

Подробнее:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/COMPILER.md`](docs/COMPILER.md)
- [`docs/IR_SCHEMA.md`](docs/IR_SCHEMA.md)
- [`docs/CONVERTER.md`](docs/CONVERTER.md)

## Название

**F&T Base** означает **Familia & Tarka Base**.

Долгосрочная цель проекта - стать серьезной weapon development platform для
Garry's Mod: compiler, SDK, runtime, toolkit и migration layer в одном аддоне.
