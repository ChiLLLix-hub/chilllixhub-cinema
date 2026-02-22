local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

--- Send a notification using the style set in Config.NotificationStyle.
---@param message string
---@param notifType string  'success' | 'error' | 'primary' (qb) / 'success' | 'error' (chat)
local function Notify(message, notifType)
    if Config.NotificationStyle == 'qb' then
        QBCore.Functions.Notify(message, notifType or 'primary')
    else
        TriggerEvent('chat:addMessage', {
            color = notifType == 'error' and { 255, 50, 50 } or { 0, 200, 100 },
            multiline = false,
            args = { '[Cinema]', message },
        })
    end
end

--- Returns the nearest cinema screen and distance, or nil when Config.Screens
--- is empty.
---@return table|nil screen
---@return number    dist
local function GetNearestScreen()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearest, nearestDist = nil, math.huge

    for _, screen in ipairs(Config.Screens) do
        local d = #(playerCoords - screen.coords)
        if d < nearestDist then
            nearest, nearestDist = screen, d
        end
    end

    return nearest, nearestDist
end

--- Returns true when the player is close enough to any registered screen
--- (or when proximity checking is disabled / no screens are configured).
---@return boolean
local function IsNearScreen()
    if not Config.UseProximity or #Config.Screens == 0 then
        return true
    end

    local _, dist = GetNearestScreen()
    return dist <= Config.MaxDistance
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Blips
-- ─────────────────────────────────────────────────────────────────────────────

if Config.ShowBlips then
    CreateThread(function()
        for _, screen in ipairs(Config.Screens) do
            local blip = AddBlipForCoord(screen.coords.x, screen.coords.y, screen.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipColour(blip, Config.BlipColor)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(screen.name or 'Cinema')
            EndTextCommandSetBlipName(blip)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Markers
-- ─────────────────────────────────────────────────────────────────────────────

if Config.UseProximity and #Config.Screens > 0 then
    CreateThread(function()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local sleep = 1000

            for _, screen in ipairs(Config.Screens) do
                local dist = #(playerCoords - screen.coords)
                if dist < Config.MaxDistance + 10.0 then
                    sleep = 0
                    -- Draw a subtle cylinder marker at the screen location
                    DrawMarker(
                        1,                                         -- type: cylinder
                        screen.coords.x, screen.coords.y, screen.coords.z,
                        0.0, 0.0, 0.0,                             -- direction
                        0.0, 0.0, 0.0,                             -- rotation
                        1.5, 1.5, 0.5,                             -- scale
                        0, 200, 255, 80,                           -- RGBA
                        false, false, 2, false, nil, nil, false
                    )
                end
            end

            Wait(sleep)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Command: open cinema UI
-- The Lua command checks qb-core permissions; if approved the server grants
-- the ACE used by the Hypnonema C# layer, then the C# command is executed.
-- ─────────────────────────────────────────────────────────────────────────────

local commandName = GetConvar('hypnonema_command_name', 'play')

-- Prevents recursive command invocation after ACE is granted
local awaitingPermission = false

RegisterCommand(commandName, function()
    -- After ACE is granted we re-invoke the command so the Hypnonema C# layer
    -- opens the NUI (it now passes its own ACE check).  Skip our logic here.
    if awaitingPermission then
        awaitingPermission = false
        return
    end

    if not IsNearScreen() then
        Notify('You must be near a cinema screen to use this.', 'error')
        return
    end

    -- Request a server-side permission check.
    TriggerServerEvent('chilllixhub-cinema:server:checkPermission')
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- Net event: permission result from server
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent('chilllixhub-cinema:client:permissionResult', function(allowed)
    if not allowed then
        Notify('You do not have permission to use the cinema.', 'error')
        return
    end

    -- ACE has been granted server-side.  Re-invoke the command so the
    -- Hypnonema C# layer now passes its internal ACE check and opens the NUI.
    awaitingPermission = true
    ExecuteCommand(commandName)
end)
