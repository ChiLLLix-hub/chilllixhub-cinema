# chilllixhub-cinema

A FiveM cinema resource built on [Hypnonema](https://github.com/thiago-dev/fivem-hypnonema) with full **qb-core** framework integration.

---

## Features

- Play and synchronise videos on in-game cinema screens
- **qb-core permission system** – restrict access by permission level (`god`, `admin`, `mod`) and/or by player job
- **Proximity check** – optionally require players to be near a cinema screen before they can open the UI
- **Map blips & markers** – optional indicators on the map and in the world for each cinema screen location
- **qb-core notifications** – all feedback messages go through QBCore's notification system

---

## Dependencies

| Resource | Notes |
|---|---|
| [qb-core](https://github.com/qbcore-framework/qb-core) | Required |

---

## Installation

1. Drop the `chilllixhub-cinema` folder into your `resources` directory.

2. Add the following lines to your **`server.cfg`**:

   ```cfg
   # Allow the cinema group to run the Hypnonema command
   add_ace group.cinema command.play allow

   ensure chilllixhub-cinema
   ```

   > **Note:** If you changed `hypnonema_command_name` in `fxmanifest.lua`, replace `play` above with the new command name.

3. Configure the resource by editing **`config.lua`** (see [Configuration](#configuration) below).

---

## Configuration

`config.lua` is shared between the client and server scripts.

| Key | Type | Default | Description |
|---|---|---|---|
| `Config.Permission` | `string` | `'admin'` | Minimum qb-core permission level required (`'god'`, `'admin'`, `'mod'`, `'all'`). Use `'all'` to allow everyone. |
| `Config.RequiredJob` | `string` | `''` | If non-empty, players with this job (at or above `RequiredJobGrade`) are also granted access regardless of `Permission`. |
| `Config.RequiredJobGrade` | `number` | `0` | Minimum job grade when `RequiredJob` is set. |
| `Config.UseProximity` | `boolean` | `false` | Require the player to be within `MaxDistance` of a screen entry in `Config.Screens`. |
| `Config.MaxDistance` | `number` | `30.0` | Maximum distance (game units) for the proximity check. |
| `Config.NotificationStyle` | `string` | `'qb'` | `'qb'` uses QBCore.Functions.Notify; `'chat'` uses the chat system. |
| `Config.ShowBlips` | `boolean` | `false` | Show map blips for every entry in `Config.Screens`. |
| `Config.Screens` | `table` | `{}` | Cinema screen locations. Each entry: `{ coords = vector3(x, y, z), name = 'Label' }`. |

---

## How permissions work

1. When a player loads (or their job changes) the server checks whether they meet the configured criteria.
2. If they do, they are added to the **`group.cinema`** principal, which is granted the Hypnonema command ACE in `server.cfg`.
3. If they no longer meet the criteria (e.g. after a job change) the principal is removed automatically.
4. Players can also trigger a manual re-check by running the cinema command; the result is returned as a qb-core notification.
