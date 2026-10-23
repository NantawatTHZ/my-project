-- SmartUpgrade Loader
-- Keeps the current SmartUpgrade.lua as the single source of truth.
-- Once the modular refactor is ready, Loader.lua can be updated to load the modules.

local SOURCE_URL = "https://raw.githubusercontent.com/NantawatTHZ/my-project/main/SmartUpgrade.lua"

local ok, source = pcall(function()
    return game:HttpGet(SOURCE_URL)
end)

if not ok or type(source) ~= "string" or source == "" then
    warn("[SmartUpgrade] Could not download SmartUpgrade.lua: " .. tostring(source))
    return
end

local compile = loadstring
if type(compile) ~= "function" then
    warn("[SmartUpgrade] loadstring is not available in this executor.")
    return
end

local chunk, compileError = compile(source)
if not chunk then
    warn("[SmartUpgrade] Lua compile error: " .. tostring(compileError))
    return
end

local ran, runtimeError = pcall(chunk)
if not ran then
    warn("[SmartUpgrade] Runtime error: " .. tostring(runtimeError))
end
