# chilllixhub-cinema

A FiveM cinema resource built on [Hypnonema](https://github.com/thiago-dev/fivem-hypnonema) with full **qb-core** framework integration.

---

## Features

- Play and synchronise videos on in-game cinema screens
- **qb-core permission system** – restrict access by permission level (`god`, `admin`, `mod`) and/or by player job
- **Proximity check** – optionally require players to be near a cinema screen before they can open the UI
- **Map blips & markers** – optional indicators on the map and in the world for each cinema screen location
- **qb-core notifications** – all feedback messages go through QBCore's notification system
- **Startup ACE evaluation** – players already connected when the resource (re)starts are evaluated immediately

---

## Dependencies

| Resource | Notes |
|---|---|
| [qb-core](https://github.com/qbcore-framework/qb-core) | Required – must be started before this resource |

---

## Installation

### 1. Add the resource

Drop the `chilllixhub-cinema` folder into your `resources` directory (or into a category sub-folder, e.g. `resources/[standalone]/chilllixhub-cinema`).

### 2. Configure `server.cfg`

Add the following lines **before** the `ensure chilllixhub-cinema` line:

```cfg
# Grant the cinema group permission to run the Hypnonema UI command
add_ace group.cinema command.play allow

ensure qb-core          # qb-core must start first
ensure chilllixhub-cinema
```

> **Note:** If you changed `hypnonema_command_name` in `fxmanifest.lua` from the default `play`, replace `command.play` above with `command.<your_command_name>`.

### 3. Edit `config.lua`

Open `config.lua` and adjust the values to match your server setup (see [Configuration](#configuration) below). At minimum, check `Config.Permission` and `Config.RequiredJob`.

### 4. (Re)start the resource

```
refresh
ensure chilllixhub-cinema
```

Players who are already online when the resource starts are automatically re-evaluated, so a live `ensure` after configuration changes works correctly.

---

## Configuration

`config.lua` is shared between the client and server scripts.

| Key | Type | Default | Description |
|---|---|---|---|
| `Config.Permission` | `string` | `'admin'` | Minimum qb-core permission level required: `'god'`, `'admin'`, `'mod'`. Set to `'all'` to allow every player. |
| `Config.RequiredJob` | `string` | `''` | If non-empty, players with this job at or above `RequiredJobGrade` are granted access **in addition to** any permission match. Set to `''` to disable the job check. |
| `Config.RequiredJobGrade` | `number` | `0` | Minimum job grade when `Config.RequiredJob` is set (grade `0` = any grade). |
| `Config.UseProximity` | `boolean` | `false` | When `true`, players must be within `MaxDistance` of an entry in `Config.Screens` to open the UI. |
| `Config.MaxDistance` | `number` | `30.0` | Maximum distance (game units) for the proximity check. Only used when `UseProximity` is `true`. |
| `Config.NotificationStyle` | `string` | `'qb'` | `'qb'` – uses `QBCore.Functions.Notify`; `'chat'` – sends a chat message. |
| `Config.ShowBlips` | `boolean` | `false` | Show a map blip for every entry in `Config.Screens`. |
| `Config.BlipSprite` | `number` | `406` | Blip sprite ID (see [FiveM blip reference](https://docs.fivem.net/game-references/blips/)). |
| `Config.BlipColor` | `number` | `47` | Blip colour ID. |
| `Config.BlipScale` | `number` | `0.8` | Blip icon scale. |
| `Config.Screens` | `table` | `{}` | List of cinema screen locations. Each entry: `{ coords = vector3(x, y, z), name = 'Label' }`. Used for proximity checks and blips. |

### Example: job-based access

```lua
Config.Permission    = 'admin'   -- admins always have access
Config.RequiredJob   = 'police'  -- police officers at grade ≥ 2 also have access
Config.RequiredJobGrade = 2
```

### Example: open to all players

```lua
Config.Permission = 'all'
Config.RequiredJob = ''
```

---

## How permissions work

1. When a player **loads in** or their **job changes**, the server evaluates whether they meet the configured criteria.
2. When the **resource starts or restarts**, all currently-connected players are evaluated immediately so no one is left without (or stuck with) access.
3. When a player **disconnects**, their ACE principal is cleaned up.
4. If access is granted, the player is added to the **`group.cinema`** principal, which is allowed to run the Hypnonema command via the ACE rule in `server.cfg`.
5. Players can trigger a **manual re-check** by running the cinema command; the result is returned as a notification.

---

## ACE / Permissions reference

The resource uses FiveM's native ACE (Access Control Entries) system. The key rule is:

```cfg
add_ace group.cinema command.play allow
```

This line lets anyone in `group.cinema` execute the `play` command (Hypnonema's UI trigger). The server script manages who is in `group.cinema` by calling `add_principal` / `remove_principal` at runtime based on the rules in `config.lua`.

You do **not** need to add players to `group.cinema` manually. The server script handles this automatically.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Players cannot open the cinema UI | Missing ACE rule in `server.cfg` | Ensure `add_ace group.cinema command.play allow` is present and `qb-core` starts before this resource. |
| Players who were online during a `ensure` don't get access | Old version of the resource | Update to the latest version – the startup thread now re-evaluates all connected players. |
| Job check never grants access | Wrong `job.grade` field in your QBCore version | The server script supports both `job.grade.level` (newer QBCore) and `job.grade` (numeric legacy builds) automatically. |
| Notifications not showing | Wrong `NotificationStyle` | Set `Config.NotificationStyle = 'qb'` and confirm `QBCore.Functions.Notify` is available in your build. |
| Server console shows "qb-core not found after waiting" | `qb-core` not started yet | Make sure `ensure qb-core` appears before `ensure chilllixhub-cinema` in `server.cfg`. |

---

## Migrating from ESX

If you were previously running an ESX-based cinema resource, note the following differences:

| ESX | QBCore (this resource) |
|---|---|
| `ESX.GetPlayerFromId(src)` | `QBCore.Functions.GetPlayer(src)` |
| `xPlayer.getJob().grade` | `Player.PlayerData.job.grade.level` (or `.grade` in legacy builds) |
| Permission groups via `es_extended` | ACE principals via `add_ace` / `add_principal` in `server.cfg` |
| `TriggerEvent('esx:...')` | `TriggerEvent('QBCore:...')` |
| `exports['es_extended']:getSharedObject()` | `exports['qb-core']:GetCoreObject()` |

There is no automatic migration. You will need to recreate your `config.lua` settings and update your `server.cfg` ACE rules as described above.

---

## License

This resource is based on [Hypnonema](https://github.com/thiago-dev/fivem-hypnonema) by thiago-dev.  
QBCore integration by [ChiLLLix-hub](https://github.com/ChiLLLix-hub).
