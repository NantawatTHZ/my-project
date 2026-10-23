local BASE = "https://raw.githubusercontent.com/NantawatTHZ/my-project/main/"

local function loadRemote(fileName)
    local url = BASE .. fileName

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("Failed to load: " .. url)
        return nil
    end

    local fn, err = loadstring(result)
    if not fn then
        warn("Failed to compile: " .. fileName .. " | " .. tostring(err))
        return nil
    end

    local ok, module = pcall(fn)
    if not ok then
        warn("Failed to execute: " .. fileName .. " | " .. tostring(module))
        return nil
    end

    return module
end

local Config = loadRemote("Config.lua")
local State = loadRemote("State.lua")
local UI = loadRemote("UI.lua")
local UpgradeLogic = loadRemote("UpgradeLogic.lua")
local Profile = loadRemote("Profile.lua")

if not Config or not State or not UI or not UpgradeLogic or not Profile then
    error("One or more modules failed to load.")
end

local state = State.Create()

state.isAutoRepair = false
state.isAutoDoor = false
state.isUpgrading = false
state.doorCap = 15

local ui = UI.Create(state)
local upgradeLogic = UpgradeLogic.New(state, Config)

ui:BindActions(function()
    upgradeLogic:RunLoop()
end)

ui:Show()

local profilePath = Config.ProfileFolder .. "profile.json"

if isfile and profilePath and isfile(profilePath) then
    Profile.Load(state, profilePath)
end
