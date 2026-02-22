Config = {}

-- Permission level required to use the cinema ('god', 'admin', 'mod', or 'all' for everyone)
Config.Permission = 'admin'

-- Job restriction (set to '' to disable job requirement)
-- If set, player must have this job OR the above permission level
Config.RequiredJob = ''

-- Minimum job grade required (only used when Config.RequiredJob is set)
Config.RequiredJobGrade = 0

-- Enable/disable proximity check when opening cinema UI
Config.UseProximity = false

-- Maximum distance (in game units) from a screen to open the cinema UI
-- Only applies when Config.UseProximity is true
Config.MaxDistance = 30.0

-- Notification style: 'qb' uses QBCore notifications, 'chat' uses chat messages
Config.NotificationStyle = 'qb'

-- Cinema screen locations used for proximity check and blip creation
-- Update these with the actual coordinates of your cinema screens in-game
Config.Screens = {
    -- { coords = vector3(0.0, 0.0, 0.0), name = 'Cinema Screen 1' },
}

-- Whether to show map blips for cinema screen locations
Config.ShowBlips = false

-- Blip sprite, colour, and scale (see FiveM docs for valid values)
Config.BlipSprite = 406
Config.BlipColor  = 47
Config.BlipScale  = 0.8
