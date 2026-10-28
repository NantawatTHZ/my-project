local function saveProfile()
    if not writefile then
        return false
    end

    if not gui or not gui.Parent then
        return false
    end

    local caps, sels = {}, {}

    for n, d in pairs(unitData) do
        if d.owner == player.Name then
            caps[n] = d.cap
            sels[n] = d.selected == true
        end
    end

    local p = {
        isAutoRepair = isAutoRepair,
        isAutoDoor = isAutoDoor,
        isUpgrading = isUpgrading,
        doorCap = doorCap,
        unitCaps = caps,
        unitSelected = sels
    }

    local ok, enc = pcall(function()
        return HttpService:JSONEncode(p)
    end)

    if ok then
        return pcall(function()
            writefile(PROFILE_PATH, enc)
        end)
    end

    return false
end

local function loadProfile()
    if not isfile or not readfile then
        return
    end

    if not isfile(PROFILE_PATH) then
        return
    end

    local ok, d = pcall(function()
        return HttpService:JSONDecode(
            readfile(PROFILE_PATH)
        )
    end)

    if not ok or type(d) ~= "table" then
        return
    end

    if d.isAutoRepair ~= nil then
        isAutoRepair = d.isAutoRepair == true
    end

    if d.isAutoDoor ~= nil then
        isAutoDoor = d.isAutoDoor == true
    end

    if d.isUpgrading ~= nil then
        isUpgrading = d.isUpgrading == true
    end

    if d.doorCap then
        doorCap = tonumber(d.doorCap) or 15
        oldDoorCap = doorCap
    end

    local function ensureEntry(n)
        if not string.find(n, "|", 1, true) then
            n = player.Name .. "|" .. n
        end

        if not unitData[n] then
            local o, u = string.match(
                n,
                "^(.-)|(.+)$"
            )

            if not o or o ~= player.Name then
                return nil, n
            end

            unitData[n] = {
                owner = o,
                unit = u,
                selected = false,
                cap = 99
            }
        end

        return unitData[n], n
    end

    if type(d.unitCaps) == "table" then
        for n, cap in pairs(d.unitCaps) do
            local e = ensureEntry(tostring(n))

            if e then
                e.cap = tonumber(cap) or 99
            end
        end
    end

    if type(d.unitSelected) == "table" then
        for n, sel in pairs(d.unitSelected) do
            local e = ensureEntry(tostring(n))

            if e then
                e.selected = sel == true
            end
        end
    end
end

