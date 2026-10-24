local Players = game:GetService("Players")
local player = Players.LocalPlayer

local successHui, huiResult = pcall(function()
    return gethui and gethui() or game:GetService("CoreGui")
end)

local hui = (successHui and huiResult)
    or player:WaitForChild("PlayerGui")

pcall(function()
    for _, old in ipairs(hui:GetChildren()) do
        if old.Name == "SmartUpgradeUI" then
            old:Destroy()
        end
    end

    if player:FindFirstChild("PlayerGui") then
        for _, old in ipairs(player.PlayerGui:GetChildren()) do
            if old.Name == "SmartUpgradeUI" then
                old:Destroy()
            end
        end
    end
end)

local rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

local TowerStats, TowerConfig

local PROFILE_DIR = "XGAMEZ/Profile/"
local PROFILE_PATH = PROFILE_DIR .. player.Name .. ".json"

if makefolder and isfolder then
    pcall(function()
        if not isfolder("XGAMEZ") then
            makefolder("XGAMEZ")
        end

        if not isfolder(PROFILE_DIR) then
            makefolder(PROFILE_DIR)
        end
    end)
end

local C = {
    Bg = Color3.fromRGB(18, 18, 22),
    P = Color3.fromRGB(28, 28, 35),
    A = Color3.fromRGB(74, 158, 255),
    D = Color3.fromRGB(255, 95, 95),
    S = Color3.fromRGB(46, 204, 113),
    T = Color3.fromRGB(235, 235, 245),
    G = Color3.fromRGB(241, 196, 15),
    L = Color3.fromRGB(155, 89, 182),
    Border = Color3.fromRGB(45, 45, 55)
}

local unitData = {}

local isUpgrading = false
local isAutoDoor = false
local isAutoRepair = false

local myDoorCount = 1
local doorCap = 15
local oldDoorCap = 15

local gui
local recentSpend = 0
local nextText = "--"

local upgradeCooldown = setmetatable({}, {
    __mode = "k"
})

local UPGRADE_COOLDOWN = 1.0
local UPGRADE_FAIL_COOLDOWN = 2.0
local CONFIRM_TIMEOUT = 2.5

local FARM_TYPES = {
    VaultFarm = true,
    VoidFarm = true,
    Farm = true,
    MoneyMachine = true,
    MiningCaveFarm = true,
    DivineBank = true
}

local function isFarmTower(t)
    return FARM_TYPES[t] == true
end

local function getStats()
    local s = player:FindFirstChild("leaderstats")

    if not s then
        return 0, 0
    end

    local c = s:FindFirstChild("Cash")
    local l = s:FindFirstChild("LVL")

    return (c and c.Value or 0),
        (l and l.Value or 0)
end

local function getCash()
    return getStats()
end

local cachedHouse = nil

local function getMyHouseName()
    local t = player:GetAttribute("TeamHouseName")

    if type(t) == "string" and t ~= "" then
        return t
    end

    local c = player:GetAttribute("ClaimedHouseName")

    if type(c) == "string" and c ~= "" then
        return c
    end

    return nil
end

local function getMyHouse()
    local gm = workspace:FindFirstChild("GameMap")
    local hs = gm and gm:FindFirstChild("Houses")

    if not hs then
        cachedHouse = nil
        return nil
    end

    local want = getMyHouseName()

    if cachedHouse
        and cachedHouse.Parent
        and (not want or cachedHouse.Name == want) then

        if want
            or cachedHouse:GetAttribute("OwnerName") == player.Name then
            return cachedHouse
        end
    end

    cachedHouse = nil

    if want then
        local h = hs:FindFirstChild(want)

        if h then
            cachedHouse = h
            return h
        end
    end

    for _, h in ipairs(hs:GetChildren()) do
        if h:GetAttribute("OwnerName") == player.Name then
            cachedHouse = h
            return h
        end
    end

    return nil
end

local function ownerRank(owner, house)
    if owner == player.Name then
        return 0
    end

    if house and owner == house:GetAttribute("OwnerName") then
        return 1
    end

    return 2
end

local function isHouseOwned()
    return getMyHouse() ~= nil
end

local function getUnitUpgradeCost(t, lv)
    if not TowerStats then
        return nil
    end

    local d = TowerStats[t]
    local nxt = d and d.Levels and d.Levels[lv + 1]

    return nxt and nxt.Cost or nil
end

local function getDoorUpgradeCost(lv)
    if not TowerConfig then
        return nil
    end

    if TowerConfig.GetDoorUpgradeCost then
        local ok, c = pcall(
            TowerConfig.GetDoorUpgradeCost,
            lv
        )

        if ok and type(c) == "number" and c > 0 then
            return c
        end
    end

    local base = TowerConfig.DoorBaseUpgradeCost or 100
    local mult = TowerConfig.DoorCostMultiplierPerLevel or 1.55

    return math.floor(
        base * (mult ^ (lv - 1)) + 0.5
    )
end

local function isTowerLocked(obj)
    local untilTs = obj:GetAttribute("LockedUntil")

    return untilTs ~= nil and os.time() < untilTs
end

local function canFireTower(obj, expectedX, expectedY)
    if not obj or not obj.Parent then
        return false
    end

    local hn = obj:GetAttribute("HouseName")
    local mh = getMyHouse()

    if hn and mh and hn ~= mh.Name then
        return false
    end

    local ck = obj:GetAttribute("CellKey")

    if ck ~= (expectedX .. ":" .. expectedY) then
        return false
    end

    local lv = obj:GetAttribute("Level") or 0
    local cap = obj:GetAttribute("LevelCap") or 99

    if lv >= cap then
        return false
    end

    return true
end

local function getRepairState()
    local now = workspace:GetServerTimeNow()

    local activeUntil = tonumber(
        player:GetAttribute("DoorRepairActiveUntil")
    ) or 0

    local readyAt = tonumber(
        player:GetAttribute("DoorRepairReadyAt")
    ) or 0

    local a = activeUntil - now
    local r = readyAt - now

    if a > 0 and a < 300 then
        return "active", a
    end

    if r > 0 and r < 300 then
        return "cooldown", r
    end

    return "ready", 0
end

local function getRemote(name)
    local f = rs:FindFirstChild("TowerDefenseRemotes")

    return f and f:FindFirstChild(name)
end

local function fireAndConfirm(
    remote,
    obj,
    args,
    validator,
    getProgress
)
    if validator and not validator() then
        return false
    end

    if not obj or not obj.Parent then
        return false
    end

    local before, beforeSpent

    if getProgress then
        local ok, v = pcall(getProgress)

        if not ok or type(v) ~= "number" then
            return false
        end

        before = v
    else
        before = obj:GetAttribute("Level") or 0
        beforeSpent = obj:GetAttribute("TotalSpent") or 0

        if type(before) ~= "number"
            or type(beforeSpent) ~= "number" then
            return false
        end
    end

    local fired = pcall(function()
        remote:FireServer(unpack(args))
    end)

    if not fired then
        return false
    end

    local t0 = os.clock()

    while os.clock() - t0 < CONFIRM_TIMEOUT do
        task.wait(0.05)

        if not obj.Parent then
            return false
        end

        if getProgress then
            local ok2, cur = pcall(getProgress)

            if ok2
                and type(cur) == "number"
                and cur > before then
                return true
            end
        else
            local newLv = obj:GetAttribute("Level")
            local newSpent = obj:GetAttribute("TotalSpent")

            newLv = type(newLv) == "number"
                and newLv or before

            newSpent = type(newSpent) == "number"
                and newSpent or beforeSpent

            if newLv > before or newSpent > beforeSpent then
                return true
            end
        end
    end

    return false
end

local function refreshDoorCount()
    local h = getMyHouse()

    if not h then
        return
    end

    local c = h:GetAttribute("DoorFolderCount")

    if type(c) == "number" and c >= 1 then
        myDoorCount = c
    end
end

local function doorLvKey(i)
    return (myDoorCount > 1)
        and ("DoorLevel" .. i)
        or "DoorLevel"
end

local doorFailCount = 0
local doorBlockUntil = 0

local function upgradeSpecificDoor(house, cash, doorIndex)
    if os.clock() < doorBlockUntil then
        return "none"
    end

    local key = doorLvKey(doorIndex)
    local lv = house:GetAttribute(key) or 0

    if lv >= doorCap then
        return "none"
    end

    local cost = getDoorUpgradeCost(lv)

    if not cost or cash < cost then
        return "wait"
    end

    local r = getRemote("UpgradeDoor")

    if not r then
        return "none"
    end

    local ok = fireAndConfirm(
        r,
        house,
        {doorIndex},
        isHouseOwned,
        function()
            return house:GetAttribute(key) or 0
        end
    )

    if ok then
        doorFailCount = 0
        recentSpend = recentSpend + cost
    else
        doorFailCount = doorFailCount + 1

        if doorFailCount >= 3 then
            doorFailCount = 0
            doorBlockUntil = os.clock() + 5
        end

        task.wait(1)
    end

    return "fired"
end

local function upgradeLowestDoor(house, cash)
    if os.clock() < doorBlockUntil then
        return "none"
    end

    local lowestLv = math.huge
    local idx = nil

    for i = 1, myDoorCount do
        local lv = house:GetAttribute(doorLvKey(i)) or 0

        if lv < doorCap and lv < lowestLv then
            lowestLv = lv
            idx = i
        end
    end

    if not idx then
        return "none"
    end

    return upgradeSpecificDoor(house, cash, idx)
end

local isMatchSession = (function()
    if not workspace:FindFirstChild("PlacedTowers") then
        return false
    end

    local remotes = rs:FindFirstChild("TowerDefenseRemotes")

    if not remotes then
        return false
    end

    return remotes:FindFirstChild("UpgradeTower") ~= nil
end)()

local function getRealXP()
    local hotbarGui = player.PlayerGui:FindFirstChild("HotbarGui")

    if not hotbarGui then
        return nil
    end

    local hotbar = hotbarGui:FindFirstChild("Hotbar")

    if not hotbar then
        return nil
    end

    local expBar = hotbar:FindFirstChild("ExpBar")

    if not expBar then
        return nil
    end

    local label = expBar:FindFirstChild("Label")

    if label and label:IsA("TextLabel") then
        local cur, max = label.Text:match(
            "(%d+)%s*/%s*(%d+)"
        )

        if cur and max then
            return tonumber(cur), tonumber(max)
        end
    end

    return nil
end
