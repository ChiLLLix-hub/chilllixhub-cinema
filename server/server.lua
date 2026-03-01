local QBCore = nil

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
            -- Support both job.grade.level (newer QBCore) and job.grade (legacy numeric)
            local grade = type(job.grade) == 'table' and job.grade.level or job.grade
            if job.name == Config.RequiredJob and grade >= Config.RequiredJobGrade then
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

--- Evaluates a single player and applies the correct ACE principal.
---@param src number  Server-side player source
local function EvaluatePlayer(src)
    SetCinemaACE(src, HasCinemaAccess(src))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Startup: evaluate players who are already online when the resource starts
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    -- Wait until qb-core is available
    local attempts = 0
    while not QBCore do
        local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and obj then
            QBCore = obj
        else
            attempts = attempts + 1
            if attempts >= 20 then
                print('^1[chilllixhub-cinema] ERROR: qb-core not found after waiting. Make sure qb-core is started before chilllixhub-cinema.^0')
                return
            end
            Wait(500)
        end
    end

    -- Re-evaluate any players who were already connected when this resource started/restarted
    for _, src in ipairs(GetPlayers()) do
        local numericSrc = tonumber(src)
        if numericSrc then
            EvaluatePlayer(numericSrc)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Event: player loaded (initial permission grant)
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    EvaluatePlayer(src)
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
    EvaluatePlayer(src)
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

