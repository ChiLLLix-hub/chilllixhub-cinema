local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

--- Returns true when the player meets the configured permission/job criteria.
---@param src number  Server-side player source
---@return boolean
local function HasCinemaAccess(src)
    if Config.Permission == 'all' then
        return true
    end

    -- qb-core permission check (god / admin / mod)
    if QBCore.Functions.HasPermission(src, Config.Permission) then
        return true
    end

    -- Job-based check
    if Config.RequiredJob ~= '' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            local job = Player.PlayerData.job
            if job.name == Config.RequiredJob
                and job.grade.level >= Config.RequiredJobGrade then
                return true
            end
        end
    end

    return false
end

--- Grants/revokes the ACE principal that Hypnonema uses internally.
--- Requires `add_ace group.cinema command.<hypnonema_command_name> allow`
--- in your server.cfg (see README).
---@param src     number
---@param grant   boolean
local function SetCinemaACE(src, grant)
    local action = grant and 'add_principal' or 'remove_principal'
    ExecuteCommand(('%s player.%d group.cinema'):format(action, src))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Event: player loaded (initial permission grant)
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    SetCinemaACE(src, HasCinemaAccess(src))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Event: player disconnected (cleanup)
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    SetCinemaACE(source, false)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Event: job change – re-evaluate access when a player's job changes
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(jobData)
    local src = source
    SetCinemaACE(src, HasCinemaAccess(src))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Net event: explicit permission check requested by the client
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent('chilllixhub-cinema:server:checkPermission', function()
    local src = source
    local allowed = HasCinemaAccess(src)
    SetCinemaACE(src, allowed)
    TriggerClientEvent('chilllixhub-cinema:client:permissionResult', src, allowed)
end)
