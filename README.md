<div align="center">

# 🎯 Off-Target

**A right-click context menu for FiveM, with drop-in `ox_target` and `qtarget` compatibility.**

Hold the menu key, right-click anything in the world, and act on it.

![FiveM](https://img.shields.io/badge/FiveM-resource-orange)
![Lua](https://img.shields.io/badge/Lua-5.4-blue)
![React](https://img.shields.io/badge/UI-React%2018-61dafb)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

## Preview

<a href="https://www.youtube.com/watch?v=peS7m275vEY">
  <img width="392" height="312" alt="Voir la vidéo" src="https://img.youtube.com/vi/peS7m275vEY/maxresdefault.jpg" />
</a>


<img width="392" height="312" alt="Capture d'écran 2026-06-05 213419" src="https://github.com/user-attachments/assets/496105e3-288b-42eb-9237-8f5012c85c31" />


---

## What's new

- **Full code refactor.** The menu core was rewritten around a flat, ID-based
  export API. No more passing builder objects across the resource boundary
  (which silently broke metatables and funcrefs in FiveM).
- **Proper `ox_target` & `qtarget` adaptation.** Both layers now track which
  resource registered each option/zone and clean up automatically on
  `stop`/`restart` — no leaks, no duplicates.
- **Everything is exported.** `Register`, `SetHeader`, `AddItem`, `AddCheckbox`,
  `AddSubmenu`, `AddSeparator`, `AddInfo`, `OnActivate`, `OnValueChanged`,
  `Toggle` — all callable from any resource.
- **New [`exports.md`](exports.md)** documenting every export (Off-Target,
  ox_target and qtarget) in one place.

---

## Table of contents

- [Features](#features)
- [How it works](#how-it-works)
- [Installation](#installation)
- [Building the UI](#building-the-ui)
- [Configuration](#configuration)
- [Quick start — the menu API](#quick-start--the-menu-api)
- [ox_target compatibility](#ox_target-compatibility)
- [qtarget compatibility](#qtarget-compatibility)
- [Lifecycle & cleanup](#lifecycle--cleanup)
- [Project structure](#project-structure)
- [Full documentation](#full-documentation)
- [Credits](#credits)
- [License](#license)
- [MIST145 Fork — Theme Customization](#mist145-fork--theme-customization)

---

## Features

- **Right-click context menu** with a clean, animated NUI (React + Vite).
- **Drop-in `ox_target` replacement** — existing scripts keep working.
- **`qtarget` compatibility layer** — legacy `exports.qtarget:*` scripts keep working.
- **Simple export API** for custom menus: items, checkboxes, submenus, separators, info rows.
- **Screen raycast** resolves the entity / model / coordinates under the cursor.
- **Player scoping** — target everyone, only yourself, or only other players.
- **Zones** — sphere, box and polygon, with optional on-screen markers.
- Per-item icons (Font Awesome), accent colors, descriptions and paging.

---

## How it works

1. You hold the **menu key** (default `LEFT ALT`) — the NUI cursor appears.
2. You **right-click** in the world.
3. A screen-space raycast finds what is under the cursor (entity, model, world position).
4. Every registered callback is asked what to show for that hit.
5. Matching options are merged into one menu and rendered.

There are two ways to add entries:

- The **`ox_target` / `qtarget` exports** — for the existing ecosystem.
- The **`Off-Target` exports** (`Register`, `AddItem`, …) — for full control.

---

## Installation

1. Drop the resource into your `resources` folder (folder name: `Off-Target`).
2. **Build the UI** once (see below) so `web/build` exists.
3. Add to your `server.cfg`:

```cfg
ensure Off-Target
```

> The manifest declares `provide 'ox_target'` and `provide 'qtarget'`.
> **Do not run the real `ox_target` or `qtarget` at the same time** — they would conflict.

---

## Building the UI

The menu interface lives in `web/` and compiles to `web/build`, which the manifest serves.

```bash
cd web
npm install
npm run build
```

| Command | Description |
| --- | --- |
| `npm run dev` | Browser preview (right-click anywhere to open a demo menu). |
| `npm run build` | Production build into `web/build`. |
| `npm run game` | Rebuild on every change (`vite build --watch`). |
| `npm run lint` | Run ESLint. |

---

## Configuration

Everything lives in [`shared/shared.lua`](shared/shared.lua):

```lua
Config = {}

Config.MenuKey = 'LMENU'                  -- key that opens the menu (FiveM key name)
Config.RaycastDistance = 300.0            -- max world raycast distance
Config.ItemsPerPage = 9                   -- items before paging kicks in
Config.DefaultEntityIcon = 'fa-solid fa-circle'
Config.PlayerInteractDistance = 2.5       -- default player interact distance

Config.MarkerClickRadius = 18             -- click radius (pixels) around a zone marker
Config.MarkerDrawDistance = 7.0           -- max distance a zone marker is drawn
```

| Key | Default | Description |
| --- | --- | --- |
| `MenuKey` | `'LMENU'` | FiveM key name that opens the menu. |
| `RaycastDistance` | `300.0` | Max world raycast distance. |
| `ItemsPerPage` | `9` | Root items shown before paging. |
| `DefaultEntityIcon` | `'fa-solid fa-circle'` | Fallback icon. |
| `PlayerInteractDistance` | `2.5` | Default interact distance on players. |
| `MarkerClickRadius` | `18` | Click radius in pixels around a zone marker. |
| `MarkerDrawDistance` | `7.0` | Max distance a zone marker is drawn. |

Common key names: `LMENU` (Left Alt), `RMENU` (Right Alt), `LCONTROL`, `B`, `F1`…
Players can also rebind it in **Settings → Key Bindings → FiveM**.

---

## Quick start — the menu API

Grab the resource exports and register a callback. The callback runs on every
right-click with the raycast result. Add entries, then attach behaviour to the
returned IDs.

```lua
local ContextMenu = exports['Off-Target']

ContextMenu:Register(function(entity, entityType, worldPos, hit)
    if not hit then return end
    if entity ~= PlayerPedId() then return end

    ContextMenu:SetHeader('Me', 'fa-solid fa-user')

    local handsUp = ContextMenu:AddItem(0, 'Hands Up', 'fa-solid fa-hands', { color = { 99, 102, 241 } })
    ContextMenu:OnActivate(handsUp, function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_HANDS_UP', 0, true)
    end)

    local drunk = ContextMenu:AddCheckbox(0, 'Drunk Walk', false, 'fa-solid fa-shoe-prints')
    ContextMenu:OnValueChanged(drunk, function(checked)
        if checked then
            SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 1.0)
        else
            ResetPedMovementClipset(PlayerPedId(), 0.0)
        end
    end)
end)
```

Key points:

- `entityType`: `0` world · `1` ped · `2` vehicle · `3` object.
- Each `Add*` returns a numeric **id**. Pass `0` as the parent for the root menu,
  or a submenu id (from `AddSubmenu`) to nest an item.
- Attach actions to ids with `OnActivate(id, fn)` (click) and
  `OnValueChanged(id, fn)` (checkbox).
- **No bridge file and nothing to require** — you only use the resource exports.

Full runnable examples are in [`examples/`](examples/), and every export is
documented in [`exports.md`](exports.md).

---

## ox_target compatibility

Existing `ox_target` scripts keep working unchanged:

```lua
exports.ox_target:addGlobalVehicle({
    {
        name = 'flip',
        label = 'Flip vehicle',
        icon = 'fa-solid fa-rotate',
        distance = 3.0,
        onSelect = function(data)
            SetVehicleOnGroundProperly(data.entity)
        end,
    },
})
```

> **Export resolution by folder name.** Scripts call `exports.ox_target:*`,
> which FiveM resolves by **resource folder name**. To take over the `ox_target`
> export, rename the folder to `ox_target` and remove the real one.
> The `qtarget` layer hooks the `__cfx_export_qtarget_*` events directly and
> works regardless of the folder name.

The full list of supported exports and option fields is in
[`exports.md`](exports.md) and [`DOCS.md`](DOCS.md).

---

## qtarget compatibility

Legacy `qtarget` scripts work without renaming the resource — the layer hooks the
`__cfx_export_qtarget_*` events and forwards to Off-Target.

```lua
exports.qtarget:Player({
    options = { ... },
    distance = 1.5,
    type = 'other',   -- 'self' = yourself, 'other' = others, nil/omitted = everyone
})
```

qtarget option fields (`action`, `job`, `item`/`required_item`, `event` + `type`)
are converted automatically to the Off-Target schema. See [`exports.md`](exports.md).

---

## Lifecycle & cleanup

The menu is **rebuilt on every right-click** — nothing is cached between opens,
so it always reflects live game state.

Registration is tied to the resource that made it:

- When a resource that called `Register` / `addGlobal*` / `add*Zone` **stops or
  restarts**, Off-Target removes its callbacks, options and zones. This prevents
  dead function references and duplicate entries on restart.
- When **Off-Target itself** restarts, other resources lose their registrations.
  They can re-register on the `off-target:ready` event:

```lua
AddEventHandler('off-target:ready', function()
    -- re-run your ContextMenu:Register(...) / ox_target / qtarget calls here
end)
```

---

## Project structure

```
Off-Target/
├─ fxmanifest.lua          # Resource manifest (provides 'ox_target' + 'qtarget')
├─ shared/
│  └─ shared.lua           # Config: key, distances, paging, markers
├─ client/
│  ├─ core/
│  │  ├─ keys.lua          # Keybinding helper
│  │  └─ contextmenu.lua   # Menu core: NUI bridge, raycast, exports, cleanup
│  └─ convert/
│     ├─ _utils.lua        # Shared helpers (list/convert/owner-tagging)
│     ├─ target.lua        # Targeting store + OxTarget API + matching + markers
│     ├─ ox_target.lua     # ox_target export layer
│     └─ qtarget.lua       # qtarget export layer
├─ examples/               # Standalone usage examples (not in the manifest)
├─ exports.md              # Every export (Off-Target / ox_target / qtarget)
├─ DOCS.md                 # Full documentation
└─ web/                    # React (Vite) NUI
   ├─ src/                 # UI source
   └─ build/               # Compiled UI (served by the manifest)
```

---

## Full documentation

- **[exports.md](exports.md)** — every export, parameters and return values.
- **[DOCS.md](DOCS.md)** — concepts, schemas, behaviour, troubleshooting.

---

## Credits

Off-Target builds on ideas and conventions from the FiveM targeting ecosystem:

- **[Kiminaze](https://github.com/Kiminaze/ContextMenu)** — the original
  right-click `ContextMenu` resource. Its flat, ID-based export design
  (`Register` → `AddItem` → `OnActivate`) is the pattern this resource follows
  so menus work cleanly across the resource boundary.
- **[ox_target](https://github.com/overextended/ox_target)** (Overextended) —
  the targeting API mirrored by the `ox_target` compatibility layer.
- **[qtarget](https://github.com/overextended/qtarget)** — the legacy targeting
  API mirrored by the `qtarget` compatibility layer.

All trademarks and resources belong to their respective authors.

---

## License

MIT — do what you want, no warranty.

---

---

## MIST145 Fork — Theme Customization

> This fork ([MIST145/off-target](https://github.com/MIST145/off-target)) is based on the original [OffSey/off-target](https://github.com/OffSey/off-target) and adds a **built-in Theme Editor** — a full per-player UI customization system with preset themes and a custom color editor.


## Preview


<a href="https://r2.fivemanage.com/gMiUDRxmYxB3TtNzN5a6G/test_folder/try/CustomizingThemesinFiveMResource(2)(online-video-cutter.com)(3)-ezremove.mp4">
  <img width="392" height="312" alt="See Preview" src="https://r2.fivemanage.com/gMiUDRxmYxB3TtNzN5a6G/test_folder/logos/17810801926142.png" />
</a>

### Theme Presets

<img width="392" height="312" alt="Theme Presets" src="https://r2.fivemanage.com/gMiUDRxmYxB3TtNzN5a6G/test_folder/try/IMG_20260609_002132.jpg" />

### Theme Customization

<img width="392" height="312" alt="Theme Customization" src="https://r2.fivemanage.com/gMiUDRxmYxB3TtNzN5a6G/test_folder/try/IMG_20260609_002152.jpg" />

---
### What was added

- 🖌️ **Theme Editor NUI** — in-game panel to customize every color in the context menu
- 🎨 **6 built-in preset themes** — Midnight, Carbon, Blood, Forest, Sapphire, Ash
- 🎛️ **Custom color editor** — independent RGB picker + alpha slider for each CSS variable
- 💾 **Per-player persistence** — theme choice is saved via KVP and restored automatically on next session
- ⌨️ **Configurable command** — open the editor with `/ctxtheme` (name set in `Config.ThemeCommand`)

---

### Opening the Theme Editor

Run in-game:

```
/ctxtheme
```

The command is configurable in `shared/shared.lua`:

```lua
Config.ThemeCommand = 'ctxtheme'   -- change to any command name you want
```

It is also registered as a FiveM key binding — players can assign a key to it in **Settings → Key Bindings → FiveM**.

---

### Presets tab

Six ready-made themes. Click any card to apply instantly.

| Theme | Accent |
| --- | --- |
| **Midnight** | Indigo `#6366f1` |
| **Carbon** | Amber `#f59e0b` |
| **Blood** | Red `#ef4444` |
| **Forest** | Emerald `#10b981` |
| **Sapphire** | Blue `#3b82f6` |
| **Ash** | Purple `#a855f7` |


---

### Custom tab

Fine-tune every CSS variable individually. Each row has an RGB color picker and an **α** (alpha/opacity) slider. A live **Preview** panel in the bottom-left shows changes in real time before saving.

| CSS Variable | Controls |
| --- | --- |
| `--ctx-bg` | Menu background color & opacity |
| `--ctx-border` | Border color & opacity |
| `--ctx-hover` | Row hover highlight & opacity |
| `--ctx-text` | Default text color & opacity |
| `--ctx-bright` | Highlighted / active text |
| `--ctx-muted` | Secondary / muted text |
| `--ctx-accent` | Accent color for icons and highlights |

Click **Save Custom** to persist. Press `ESC` to close without saving.

---

### New files added by this fork

| File | Purpose |
| --- | --- |
| `shared/themes.lua` | Built-in theme preset definitions |
| `client/themes.lua` | Theme editor NUI bridge + KVP save/load logic |
| `web/src/features/themeEditor/` | React UI for the Theme Editor panel |
