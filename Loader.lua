local BASE_URL = "https://raw.githubusercontent.com/NantawatTHZ/my-project/main/"
local MODULES = {
    "Modules/Core.lua",
    "Modules/Profile.lua",
    "Modules/UI.lua",
    "Modules/Dashboard.lua",
    "Modules/Scanning.lua",
    "Modules/Automation.lua",
    "Modules/Initialization.lua",
}

local compile = loadstring
if type(compile) ~= "function" then
    warn("[SmartUpgrade] loadstring is not available in this executor.")
    return
end

local parts = {}
for _, path in ipairs(MODULES) do
    local url = BASE_URL .. path
    local ok, downloaded = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok or type(downloaded) ~= "string" or downloaded == "" then
        warn("[SmartUpgrade] Failed to download module " .. path .. ": " .. tostring(downloaded))
        return
    end

    parts[#parts + 1] = downloaded
end

-- A separator newline prevents tokens from adjacent fragments merging.
local combined = table.concat(parts, "\n")
local chunk, compileError = compile(combined)
if not chunk then
    warn("[SmartUpgrade] Combined Lua compile error: " .. tostring(compileError))
    return
end

local ran, runtimeError = pcall(chunk)
if not ran then
    warn("[SmartUpgrade] Runtime error: " .. tostring(runtimeError))
end
