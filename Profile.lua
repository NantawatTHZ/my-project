local Profile = {}

function Profile.Load(state, path)
    if not isfile or not readfile then
        return false
    end

    if not isfile(path) then
        return false
    end

    local ok, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(path))
    end)

    if not ok or type(decoded) ~= "table" then
        return false
    end

    state.isAutoRepair = decoded.isAutoRepair == true
    state.isAutoDoor = decoded.isAutoDoor == true
    state.isUpgrading = decoded.isUpgrading == true
    state.doorCap = tonumber(decoded.doorCap) or 15
    return true
end

function Profile.Save(state, path)
    if not writefile then
        return false
    end

    local data = {
        isAutoRepair = state.isAutoRepair,
        isAutoDoor = state.isAutoDoor,
        isUpgrading = state.isUpgrading,
        doorCap = state.doorCap,
    }

    local ok, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)

    if not ok then
        return false
    end

    return pcall(function()
        writefile(path, encoded)
    end)
end

return Profile
