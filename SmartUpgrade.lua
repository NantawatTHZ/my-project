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
local CONFIRM_TIMEOUT = 0.3

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
            doorBlockUntil = os.clock() + 30
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

local function isInMatch()
    if not workspace:FindFirstChild("PlacedTowers") then
        return false
    end

    local remotes = rs:FindFirstChild("TowerDefenseRemotes")

    if not remotes then
        return false
    end

    return remotes:FindFirstChild("UpgradeTower") ~= nil
end

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

gui = Instance.new("ScreenGui", hui)
gui.Name = "SmartUpgradeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 48, 0, 48)
toggleBtn.Visible = false
toggleBtn.Position = UDim2.new(1, -70, 1, -160)
toggleBtn.BackgroundColor3 = C.P
toggleBtn.TextColor3 = C.A
toggleBtn.Text = "⚡"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.GothamBold

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = C.Border
toggleStroke.Thickness = 1.5

local CONTAINER_W = 260
local PANEL_GAP = 10

local container = Instance.new("Frame", gui)
container.Name = "Container"
container.Size = UDim2.new(0, CONTAINER_W, 0, 0)
container.Position = UDim2.new(0.5, 0, 0.5, -160)
container.AnchorPoint = Vector2.new(0.5, 0)
container.BackgroundTransparency = 1
container.Visible = false
container.AutomaticSize = Enum.AutomaticSize.Y

local containerLayout = Instance.new("UIListLayout", container)
containerLayout.FillDirection = Enum.FillDirection.Horizontal
containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
containerLayout.Padding = UDim.new(0, PANEL_GAP)
containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local containerScale = Instance.new("UIScale", container)
containerScale.Scale = 1

local infoPanel = Instance.new("Frame", container)
infoPanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)
infoPanel.BackgroundColor3 = C.Bg
infoPanel.LayoutOrder = 1
infoPanel.AutomaticSize = Enum.AutomaticSize.Y
infoPanel.Visible = false

Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 10)

local infoStroke = Instance.new("UIStroke", infoPanel)
infoStroke.Color = C.Border
infoStroke.Thickness = 1

local infoLayout = Instance.new("UIListLayout", infoPanel)
infoLayout.Padding = UDim.new(0, 6)
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder

local infoPad = Instance.new("UIPadding", infoPanel)
infoPad.PaddingTop = UDim.new(0, 10)
infoPad.PaddingBottom = UDim.new(0, 10)
infoPad.PaddingLeft = UDim.new(0, 10)
infoPad.PaddingRight = UDim.new(0, 10)

local infoHeader = Instance.new("Frame", infoPanel)
infoHeader.Size = UDim2.new(1, 0, 0, 24)
infoHeader.BackgroundTransparency = 1
infoHeader.LayoutOrder = 1

local infoTitle = Instance.new("TextLabel", infoHeader)
infoTitle.Size = UDim2.new(1, -30, 1, 0)
infoTitle.BackgroundTransparency = 1
infoTitle.Text = "📊  Status Dashboard"
infoTitle.TextColor3 = C.A
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextSize = 12
infoTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", infoHeader)
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -22, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "-"
closeBtn.TextColor3 = C.D
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13

closeBtn.MouseButton1Click:Connect(function()
    container.Visible = false
end)

local function mkIcon(parent, glyph, pos)
    local ic = Instance.new("TextLabel", parent)
    ic.Size = UDim2.new(0, 20, 1, 0)
    ic.Position = pos
    ic.BackgroundTransparency = 1
    ic.Text = glyph
    ic.TextSize = 12
    ic.Font = Enum.Font.Gotham
    ic.TextColor3 = Color3.new(1, 1, 1)
    return ic
end

local userBox = Instance.new("Frame", infoPanel)
userBox.Size = UDim2.new(1, 0, 0, 28)
userBox.BackgroundColor3 = C.P
userBox.LayoutOrder = 2
Instance.new("UICorner", userBox).CornerRadius = UDim.new(0, 6)

local nameLbl = Instance.new("TextLabel", userBox)
nameLbl.Size = UDim2.new(0.65, -28, 1, 0)
nameLbl.Position = UDim2.new(0, 28, 0, 0)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = player.Name

mkIcon(userBox, "👤", UDim2.new(0, 6, 0, 0))

nameLbl.TextColor3 = C.T
nameLbl.TextSize = 11
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

local lvlInlineLbl = Instance.new("TextLabel", userBox)
lvlInlineLbl.Size = UDim2.new(0.35, -8, 1, 0)
lvlInlineLbl.Position = UDim2.new(0.65, 0, 0, 0)
lvlInlineLbl.BackgroundTransparency = 1
lvlInlineLbl.Text = "⭐ Lv0"
lvlInlineLbl.TextColor3 = C.L
lvlInlineLbl.TextSize = 11
lvlInlineLbl.Font = Enum.Font.GothamBold
lvlInlineLbl.TextXAlignment = Enum.TextXAlignment.Right

local houseBox = Instance.new("Frame", infoPanel)
houseBox.Size = UDim2.new(1, 0, 0, 28)
houseBox.BackgroundColor3 = C.P
houseBox.LayoutOrder = 3
Instance.new("UICorner", houseBox).CornerRadius = UDim.new(0, 6)

local houseLbl = Instance.new("TextLabel", houseBox)
houseLbl.Size = UDim2.new(1, -34, 1, 0)
houseLbl.Position = UDim2.new(0, 28, 0, 0)
houseLbl.BackgroundTransparency = 1
houseLbl.Text = "--"

mkIcon(houseBox, "🏠", UDim2.new(0, 6, 0, 0))

houseLbl.TextColor3 = C.A
houseLbl.TextSize = 11
houseLbl.Font = Enum.Font.GothamBold
houseLbl.TextXAlignment = Enum.TextXAlignment.Left
houseLbl.TextTruncate = Enum.TextTruncate.AtEnd

local statGrid = Instance.new("Frame", infoPanel)
statGrid.Size = UDim2.new(1, 0, 0, 58)
statGrid.BackgroundTransparency = 1
statGrid.LayoutOrder = 4

local statGridLayout = Instance.new("UIGridLayout", statGrid)
statGridLayout.CellSize = UDim2.new(0.5, -4, 0, 26)
statGridLayout.CellPadding = UDim2.new(0, 8, 0, 6)
statGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function mkCard(icon, text, color, order)
    local card = Instance.new("Frame", statGrid)
    card.BackgroundColor3 = C.P
    card.LayoutOrder = order

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    mkIcon(card, icon, UDim2.new(0, 6, 0, 0))

    local l = Instance.new("TextLabel", card)
    l.Size = UDim2.new(1, -30, 1, 0)
    l.Position = UDim2.new(0, 26, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left

    return l
end

local playerCountLbl = mkCard("👥", "0 Players", C.A, 1)
local timeLbl = mkCard("🕒", "--:--", C.T, 2)
local incomeLbl = mkCard("📈", "~$0/min", C.G, 3)
local repairLbl = mkCard("🔧", "Ready", C.S, 4)

local netBox = Instance.new("Frame", infoPanel)
netBox.Size = UDim2.new(1, 0, 0, 28)
netBox.BackgroundColor3 = C.P
netBox.LayoutOrder = 5
Instance.new("UICorner", netBox).CornerRadius = UDim.new(0, 6)

local pingLbl = Instance.new("TextLabel", netBox)
pingLbl.Size = UDim2.new(0.5, -30, 1, 0)
pingLbl.Position = UDim2.new(0, 28, 0, 0)

mkIcon(netBox, "📡", UDim2.new(0, 6, 0, 0))

pingLbl.BackgroundTransparency = 1
pingLbl.Text = "-- ms"
pingLbl.TextColor3 = C.A
pingLbl.TextSize = 11
pingLbl.Font = Enum.Font.GothamBold
pingLbl.TextXAlignment = Enum.TextXAlignment.Left

local fpsLbl = Instance.new("TextLabel", netBox)
fpsLbl.Size = UDim2.new(0.5, -30, 1, 0)
fpsLbl.Position = UDim2.new(0.5, 28, 0, 0)

mkIcon(netBox, "🖥", UDim2.new(0.5, 6, 0, 0))

fpsLbl.BackgroundTransparency = 1
fpsLbl.Text = "-- fps"
fpsLbl.TextColor3 = C.S
fpsLbl.TextSize = 11
fpsLbl.Font = Enum.Font.GothamBold
fpsLbl.TextXAlignment = Enum.TextXAlignment.Left

local nextBox = Instance.new("Frame", infoPanel)
nextBox.Size = UDim2.new(1, 0, 0, 28)
nextBox.BackgroundColor3 = C.P
nextBox.LayoutOrder = 6
Instance.new("UICorner", nextBox).CornerRadius = UDim.new(0, 6)

mkIcon(nextBox, "🎯", UDim2.new(0, 6, 0, 0))

local nextLbl = Instance.new("TextLabel", nextBox)
nextLbl.Size = UDim2.new(1, -34, 1, 0)
nextLbl.Position = UDim2.new(0, 28, 0, 0)
nextLbl.BackgroundTransparency = 1
nextLbl.Text = "--"
nextLbl.TextColor3 = C.T
nextLbl.TextSize = 11
nextLbl.Font = Enum.Font.GothamBold
nextLbl.TextXAlignment = Enum.TextXAlignment.Left
nextLbl.TextTruncate = Enum.TextTruncate.AtEnd

local upgradePanel = Instance.new("Frame", container)
upgradePanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)
upgradePanel.BackgroundColor3 = C.Bg
upgradePanel.LayoutOrder = 2
upgradePanel.AutomaticSize = Enum.AutomaticSize.Y
upgradePanel.Visible = false

Instance.new("UICorner", upgradePanel).CornerRadius = UDim.new(0, 10)

local upStroke = Instance.new("UIStroke", upgradePanel)
upStroke.Color = C.Border
upStroke.Thickness = 1

local upLayout = Instance.new("UIListLayout", upgradePanel)
upLayout.Padding = UDim.new(0, 6)
upLayout.SortOrder = Enum.SortOrder.LayoutOrder

local upPad = Instance.new("UIPadding", upgradePanel)
upPad.PaddingTop = UDim.new(0, 10)
upPad.PaddingBottom = UDim.new(0, 10)
upPad.PaddingLeft = UDim.new(0, 10)
upPad.PaddingRight = UDim.new(0, 10)

local upHeader = Instance.new("Frame", upgradePanel)
upHeader.Size = UDim2.new(1, 0, 0, 24)
upHeader.BackgroundTransparency = 1
upHeader.LayoutOrder = 1

local upTitle = Instance.new("TextLabel", upHeader)
upTitle.Size = UDim2.new(1, -35, 1, 0)
upTitle.BackgroundTransparency = 1
upTitle.Text = "⚡  Smart Upgrader"
upTitle.TextColor3 = C.A
upTitle.Font = Enum.Font.GothamBold
upTitle.TextSize = 12
upTitle.TextXAlignment = Enum.TextXAlignment.Left

local upSaveBtn = Instance.new("TextButton", upHeader)
upSaveBtn.Size = UDim2.new(0, 32, 0, 20)
upSaveBtn.Position = UDim2.new(1, -32, 0, 2)
upSaveBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
upSaveBtn.Text = "💾"
upSaveBtn.TextColor3 = Color3.new(1, 1, 1)
upSaveBtn.TextSize = 11
upSaveBtn.Font = Enum.Font.GothamBold

Instance.new("UICorner", upSaveBtn).CornerRadius = UDim.new(0, 4)

upSaveBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if saveProfile() then
            upSaveBtn.Text = "✅"
            task.wait(1)
            upSaveBtn.Text = "💾"
        else
            upSaveBtn.Text = "❌"
            task.wait(1)
            upSaveBtn.Text = "💾"
        end
    end)
end)

local listFrame = Instance.new("ScrollingFrame", upgradePanel)
listFrame.Size = UDim2.new(1, 0, 0, 170)
listFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 3
listFrame.LayoutOrder = 2

Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local listPad = Instance.new("UIPadding", listFrame)
listPad.PaddingTop = UDim.new(0, 5)
listPad.PaddingBottom = UDim.new(0, 5)
listPad.PaddingLeft = UDim.new(0, 5)
listPad.PaddingRight = UDim.new(0, 5)

local noDataLabel = Instance.new("TextLabel", listFrame)
noDataLabel.Size = UDim2.new(1, 0, 0, 30)
noDataLabel.BackgroundTransparency = 1
noDataLabel.Text = "No towers placed"
noDataLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
noDataLabel.TextSize = 11
noDataLabel.Font = Enum.Font.Gotham

local actionFrame = Instance.new("Frame", upgradePanel)
actionFrame.Size = UDim2.new(1, 0, 0, 32)
actionFrame.BackgroundTransparency = 1
actionFrame.LayoutOrder = 3

local repairBtn = Instance.new("TextButton", actionFrame)
repairBtn.Size = UDim2.new(0.5, -4, 1, 0)
repairBtn.Position = UDim2.new(0, 0, 0, 0)
repairBtn.BackgroundColor3 = C.P
repairBtn.Text = "🔧 Repair"
repairBtn.TextColor3 = C.T
repairBtn.Font = Enum.Font.GothamBold
repairBtn.TextSize = 11

Instance.new("UICorner", repairBtn).CornerRadius = UDim.new(0, 6)

local doorUpBtn = Instance.new("TextButton", actionFrame)
doorUpBtn.Size = UDim2.new(0.5, -4, 1, 0)
doorUpBtn.Position = UDim2.new(0.5, 4, 0, 0)
doorUpBtn.BackgroundColor3 = C.P
doorUpBtn.Text = "🚪 Upgrade Door"
doorUpBtn.TextColor3 = C.T
doorUpBtn.Font = Enum.Font.GothamBold
doorUpBtn.TextSize = 11

Instance.new("UICorner", doorUpBtn).CornerRadius = UDim.new(0, 6)

local capFrame = Instance.new("Frame", upgradePanel)
capFrame.Size = UDim2.new(1, 0, 0, 30)
capFrame.BackgroundColor3 = C.P
capFrame.LayoutOrder = 4

Instance.new("UICorner", capFrame).CornerRadius = UDim.new(0, 6)

local capLbl = Instance.new("TextLabel", capFrame)
capLbl.Size = UDim2.new(0.5, -8, 1, 0)
capLbl.Position = UDim2.new(0, 8, 0, 0)
capLbl.Font = Enum.Font.GothamBold
capLbl.BackgroundTransparency = 1
capLbl.Text = "🚪  Door Cap"
capLbl.TextColor3 = C.T
capLbl.TextSize = 11
capLbl.TextXAlignment = Enum.TextXAlignment.Left

local capMinus = Instance.new("TextButton", capFrame)
capMinus.Size = UDim2.new(0, 18, 0, 18)
capMinus.Position = UDim2.new(0.55, 0, 0, 6)
capMinus.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
capMinus.Text = "-"
capMinus.TextColor3 = C.T
capMinus.TextSize = 12
capMinus.Font = Enum.Font.GothamBold

Instance.new("UICorner", capMinus).CornerRadius = UDim.new(0, 4)

local capInput = Instance.new("TextBox", capFrame)
capInput.Size = UDim2.new(0, 38, 0, 18)
capInput.Position = UDim2.new(0.64, 0, 0, 6)
capInput.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
capInput.TextColor3 = C.A
capInput.TextSize = 11
capInput.Font = Enum.Font.GothamBold
capInput.Text = tostring(doorCap)
capInput.ClearTextOnFocus = false

Instance.new("UICorner", capInput).CornerRadius = UDim.new(0, 4)

local capPlus = Instance.new("TextButton", capFrame)
capPlus.Size = UDim2.new(0, 18, 0, 18)
capPlus.Position = UDim2.new(0.85, 0, 0, 6)
capPlus.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
capPlus.Text = "+"
capPlus.TextColor3 = C.T
capPlus.TextSize = 12
capPlus.Font = Enum.Font.GothamBold

Instance.new("UICorner", capPlus).CornerRadius = UDim.new(0, 4)

capInput.Focused:Connect(function()
    capInput.Text = ""
end)

capInput.FocusLost:Connect(function()
    local n = tonumber(capInput.Text)

    if n and n >= 1 then
        doorCap = math.floor(n)
        oldDoorCap = doorCap
    else
        doorCap = oldDoorCap
    end

    capInput.Text = tostring(doorCap)
end)

capMinus.MouseButton1Click:Connect(function()
    if doorCap > 1 then
        doorCap = doorCap - 1
        oldDoorCap = doorCap
        capInput.Text = tostring(doorCap)
    end
end)

capPlus.MouseButton1Click:Connect(function()
    doorCap = doorCap + 1
    oldDoorCap = doorCap
    capInput.Text = tostring(doorCap)
end)

local toggleAutoBtn = Instance.new("TextButton", upgradePanel)
toggleAutoBtn.Size = UDim2.new(1, 0, 0, 36)
toggleAutoBtn.BackgroundColor3 = C.S
toggleAutoBtn.Text = "🚀 Start Auto Upgrade"
toggleAutoBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoBtn.Font = Enum.Font.GothamBold
toggleAutoBtn.TextSize = 12
toggleAutoBtn.LayoutOrder = 5

Instance.new("UICorner", toggleAutoBtn).CornerRadius = UDim.new(0, 6)

local lobbyPanel = Instance.new("Frame", container)
lobbyPanel.Name = "LobbyPanel"
lobbyPanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)
lobbyPanel.BackgroundTransparency = 1
lobbyPanel.LayoutOrder = 3
lobbyPanel.AutomaticSize = Enum.AutomaticSize.Y
lobbyPanel.Visible = false

local lobbyPanelLayout = Instance.new("UIListLayout", lobbyPanel)
lobbyPanelLayout.FillDirection = Enum.FillDirection.Horizontal
lobbyPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
lobbyPanelLayout.Padding = UDim.new(0, PANEL_GAP)

local lobbyMainCard = Instance.new("Frame", lobbyPanel)
lobbyMainCard.Size = UDim2.new(0, CONTAINER_W, 0, 0)
lobbyMainCard.BackgroundColor3 = C.Bg
lobbyMainCard.LayoutOrder = 1
lobbyMainCard.AutomaticSize = Enum.AutomaticSize.Y

Instance.new("UICorner", lobbyMainCard).CornerRadius = UDim.new(0, 10)

local lobbyStroke = Instance.new("UIStroke", lobbyMainCard)
lobbyStroke.Color = C.Border
lobbyStroke.Thickness = 1

local lobbyGradient = Instance.new("UIGradient", lobbyMainCard)
lobbyGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 18))
})
lobbyGradient.Rotation = 135

local lobbyPad = Instance.new("UIPadding", lobbyMainCard)
lobbyPad.PaddingTop = UDim.new(0, 10)
lobbyPad.PaddingBottom = UDim.new(0, 10)
lobbyPad.PaddingLeft = UDim.new(0, 10)
lobbyPad.PaddingRight = UDim.new(0, 10)

local lobbyLayout = Instance.new("UIListLayout", lobbyMainCard)
lobbyLayout.Padding = UDim.new(0, 6)
lobbyLayout.SortOrder = Enum.SortOrder.LayoutOrder

local lobbyHeader = Instance.new("Frame", lobbyMainCard)
lobbyHeader.Size = UDim2.new(1, 0, 0, 24)
lobbyHeader.BackgroundTransparency = 1
lobbyHeader.LayoutOrder = 1

local lobbyTitle = Instance.new("TextLabel", lobbyHeader)
lobbyTitle.Size = UDim2.new(1, 0, 1, 0)
lobbyTitle.BackgroundTransparency = 1
lobbyTitle.Text = "🏠  Lobby Player Info"
lobbyTitle.TextColor3 = C.A
lobbyTitle.Font = Enum.Font.GothamBold
lobbyTitle.TextSize = 13
lobbyTitle.ZIndex = 2

local lobbyUserBox = Instance.new("Frame", lobbyMainCard)
lobbyUserBox.Size = UDim2.new(1, 0, 0, 28)
lobbyUserBox.BackgroundColor3 = C.P
lobbyUserBox.LayoutOrder = 2

Instance.new("UICorner", lobbyUserBox).CornerRadius = UDim.new(0, 6)

local lobbyName = Instance.new("TextLabel", lobbyUserBox)
lobbyName.Size = UDim2.new(1, -12, 1, 0)
lobbyName.Position = UDim2.new(0, 6, 0, 0)
lobbyName.BackgroundTransparency = 1
lobbyName.Text = "👤  " .. player.Name
lobbyName.TextColor3 = C.T
lobbyName.TextSize = 11
lobbyName.Font = Enum.Font.GothamBold
lobbyName.TextXAlignment = Enum.TextXAlignment.Left

local lobbyMoneyGrid = Instance.new("Frame", lobbyMainCard)
lobbyMoneyGrid.Size = UDim2.new(1, 0, 0, 28)
lobbyMoneyGrid.BackgroundTransparency = 1
lobbyMoneyGrid.LayoutOrder = 3

local lobbyMoneyLayout = Instance.new("UIGridLayout", lobbyMoneyGrid)
lobbyMoneyLayout.CellSize = UDim2.new(0.5, -4, 0, 28)
lobbyMoneyLayout.CellPadding = UDim2.new(0, 8, 0, 0)

local function mkLobbyCard(parent, text, color, order)
    local card = Instance.new("Frame", parent)
    card.BackgroundColor3 = C.P
    card.LayoutOrder = order

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", card)
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.new(0, 6, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left

    return l
end

local lobbyCoins = mkLobbyCard(lobbyMoneyGrid, "💰 0", C.G, 1)
local lobbyGems = mkLobbyCard(lobbyMoneyGrid, "💎 0", C.L, 2)

local lobbyNetBox = Instance.new("Frame", lobbyMainCard)
lobbyNetBox.Size = UDim2.new(1, 0, 0, 28)
lobbyNetBox.BackgroundColor3 = C.P
lobbyNetBox.LayoutOrder = 4

Instance.new("UICorner", lobbyNetBox).CornerRadius = UDim.new(0, 6)

local lobbyNetLayout = Instance.new("UIListLayout", lobbyNetBox)
lobbyNetLayout.FillDirection = Enum.FillDirection.Horizontal
lobbyNetLayout.SortOrder = Enum.SortOrder.LayoutOrder
lobbyNetLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local lobbyNetPad = Instance.new("UIPadding", lobbyNetBox)
lobbyNetPad.PaddingLeft = UDim.new(0, 6)
lobbyNetPad.PaddingRight = UDim.new(0, 6)

local lobbyPlayerLbl = Instance.new("TextLabel", lobbyNetBox)
lobbyPlayerLbl.Size = UDim2.new(0.25, 0, 1, 0)
lobbyPlayerLbl.BackgroundTransparency = 1
lobbyPlayerLbl.Text = "👥 0"
lobbyPlayerLbl.TextColor3 = C.T
lobbyPlayerLbl.TextSize = 10
lobbyPlayerLbl.Font = Enum.Font.GothamBold
lobbyPlayerLbl.TextXAlignment = Enum.TextXAlignment.Left
lobbyPlayerLbl.LayoutOrder = 1

local lobbyPingLbl = Instance.new("TextLabel", lobbyNetBox)
lobbyPingLbl.Size = UDim2.new(0.25, 0, 1, 0)
lobbyPingLbl.BackgroundTransparency = 1
lobbyPingLbl.Text = "📡 --"
lobbyPingLbl.TextColor3 = C.A
lobbyPingLbl.TextSize = 10
lobbyPingLbl.Font = Enum.Font.GothamBold
lobbyPingLbl.TextXAlignment = Enum.TextXAlignment.Center
lobbyPingLbl.LayoutOrder = 2

local lobbyFpsLbl = Instance.new("TextLabel", lobbyNetBox)
lobbyFpsLbl.Size = UDim2.new(0.25, 0, 1, 0)
lobbyFpsLbl.BackgroundTransparency = 1
lobbyFpsLbl.Text = "🖥 --"
lobbyFpsLbl.TextColor3 = C.S
lobbyFpsLbl.TextSize = 10
lobbyFpsLbl.Font = Enum.Font.GothamBold
lobbyFpsLbl.TextXAlignment = Enum.TextXAlignment.Center
lobbyFpsLbl.LayoutOrder = 3

local lobbyClockLbl = Instance.new("TextLabel", lobbyNetBox)
lobbyClockLbl.Size = UDim2.new(0.25, 0, 1, 0)
lobbyClockLbl.BackgroundTransparency = 1
lobbyClockLbl.Text = "🕒 --:--"
lobbyClockLbl.TextColor3 = C.T
lobbyClockLbl.TextSize = 10
lobbyClockLbl.Font = Enum.Font.GothamBold
lobbyClockLbl.TextXAlignment = Enum.TextXAlignment.Right
lobbyClockLbl.LayoutOrder = 4

local lobbyXpBox = Instance.new("Frame", lobbyMainCard)
lobbyXpBox.Size = UDim2.new(1, 0, 0, 32)
lobbyXpBox.BackgroundColor3 = C.P
lobbyXpBox.LayoutOrder = 5

Instance.new("UICorner", lobbyXpBox).CornerRadius = UDim.new(0, 6)

local lobbyXpLbl = Instance.new("TextLabel", lobbyXpBox)
lobbyXpLbl.Size = UDim2.new(1, -12, 0, 14)
lobbyXpLbl.Position = UDim2.new(0, 6, 0, 3)
lobbyXpLbl.BackgroundTransparency = 1
lobbyXpLbl.Text = "✨ XP: -- / --"
lobbyXpLbl.TextColor3 = C.A
lobbyXpLbl.TextSize = 10
lobbyXpLbl.Font = Enum.Font.GothamBold
lobbyXpLbl.TextXAlignment = Enum.TextXAlignment.Left

local lobbyXpBarBg = Instance.new("Frame", lobbyXpBox)
lobbyXpBarBg.Size = UDim2.new(1, -12, 0, 5)
lobbyXpBarBg.Position = UDim2.new(0, 6, 1, -8)
lobbyXpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
lobbyXpBarBg.BorderSizePixel = 0

Instance.new("UICorner", lobbyXpBarBg).CornerRadius = UDim.new(1, 0)

local lobbyXpFill = Instance.new("Frame", lobbyXpBarBg)
lobbyXpFill.Size = UDim2.new(0, 0, 1, 0)
lobbyXpFill.BackgroundColor3 = C.A
lobbyXpFill.BorderSizePixel = 0

Instance.new("UICorner", lobbyXpFill).CornerRadius = UDim.new(1, 0)

local xpGrad = Instance.new("UIGradient", lobbyXpFill)
xpGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.A),
    ColorSequenceKeypoint.new(1, C.L)
})

local lobbyInfoBar = Instance.new("Frame", lobbyMainCard)
lobbyInfoBar.Size = UDim2.new(1, 0, 0, 28)
lobbyInfoBar.BackgroundColor3 = C.P
lobbyInfoBar.LayoutOrder = 6

Instance.new("UICorner", lobbyInfoBar).CornerRadius = UDim.new(0, 6)

local lobbyVip = Instance.new("TextLabel", lobbyInfoBar)
lobbyVip.Size = UDim2.new(0.5, -6, 1, 0)
lobbyVip.Position = UDim2.new(0, 6, 0, 0)
lobbyVip.BackgroundTransparency = 1
lobbyVip.Text = "👑 VIP: --"
lobbyVip.TextColor3 = C.G
lobbyVip.TextSize = 10
lobbyVip.Font = Enum.Font.GothamBold
lobbyVip.TextXAlignment = Enum.TextXAlignment.Left

local lobbyDaily = Instance.new("TextLabel", lobbyInfoBar)
lobbyDaily.Size = UDim2.new(0.5, -6, 1, 0)
lobbyDaily.Position = UDim2.new(0.5, 0, 0, 0)
lobbyDaily.BackgroundTransparency = 1
lobbyDaily.Text = "📅 Day: --"
lobbyDaily.TextColor3 = C.S
lobbyDaily.TextSize = 10
lobbyDaily.Font = Enum.Font.GothamBold
lobbyDaily.TextXAlignment = Enum.TextXAlignment.Right

local vipPulseConn = nil

local function stopVipPulse()
    if vipPulseConn then
        vipPulseConn:Disconnect()
        vipPulseConn = nil
    end
end

local function startVipPulse()
    if vipPulseConn then return end

    vipPulseConn = RunService.Heartbeat:Connect(function()
        if not gui or not gui.Parent or not lobbyVip.Parent then
            stopVipPulse()
            return
        end

        local t = tick() * 3
        local alpha = (math.sin(t) + 1) / 2

        lobbyVip.TextColor3 = C.G:Lerp(
            Color3.fromRGB(255, 120, 0),
            alpha * 0.3
        )
    end)
end

local fpsCount = 0
local fpsStart = os.clock()
local currentFPS = 60
local fpsConn = nil

fpsConn = RunService.Heartbeat:Connect(function()
    if not gui or not gui.Parent then
        if fpsConn then
            fpsConn:Disconnect()
            fpsConn = nil
        end
        return
    end

    fpsCount = fpsCount + 1
    local now = os.clock()

    if now - fpsStart >= 0.5 then
        currentFPS = math.floor(
            fpsCount / (now - fpsStart) + 0.5
        )
        fpsCount = 0
        fpsStart = now
    end
end)

local function getApproxFPS()
    return currentFPS
end

local function colorByQuality(v, good, mid)
    if v >= good then
        return C.S
    elseif v >= mid then
        return C.G
    else
        return C.D
    end
end

local incomeSamples = {}
local lastCash = nil
local incomeStart = os.clock()

local function fmtNum(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    end
    if n >= 1000 then
        return string.format("%.1fk", n / 1000)
    end
    return tostring(math.floor(n))
end

local function fmtFullNum(n)
    local formatted = tostring(math.floor(n))
    local k

    while true do
        formatted, k = string.gsub(
            formatted,
            "^(-?%d+)(%d%d%d)",
            "%1,%2"
        )
        if k == 0 then break end
    end

    return formatted
end

local currentIncomeDisplay = 0
local targetIncomeDisplay = 0
local currentPingDisplay = 0
local targetPingDisplay = 0
local currentFPSDisplay = 60
local targetFPSDisplay = 60
local currentCoinsDisplay = 0
local targetCoinsDisplay = 0
local currentGemsDisplay = 0
local targetGemsDisplay = 0

local displayConn = nil

displayConn = RunService.Heartbeat:Connect(function(dt)
    if not gui or not gui.Parent then
        if displayConn then
            displayConn:Disconnect()
            displayConn = nil
        end
        return
    end

    local alpha = math.clamp(dt * 6, 0, 1)

    currentIncomeDisplay =
        currentIncomeDisplay
        + (targetIncomeDisplay - currentIncomeDisplay) * alpha

    if incomeLbl and incomeLbl.Parent then
        incomeLbl.Text =
            "~$" .. fmtNum(currentIncomeDisplay) .. "/min"
    end

    currentPingDisplay =
        currentPingDisplay
        + (targetPingDisplay - currentPingDisplay) * alpha

    local pVal = math.floor(currentPingDisplay + 0.5)

    if pingLbl and pingLbl.Parent then
        pingLbl.Text = pVal .. " ms"
        pingLbl.TextColor3 =
            colorByQuality(180 - pVal, 120, 80)
    end

    if lobbyPingLbl and lobbyPingLbl.Parent then
        lobbyPingLbl.Text = "📡 " .. pVal .. "ms"
    end

    currentFPSDisplay =
        currentFPSDisplay
        + (targetFPSDisplay - currentFPSDisplay) * alpha

    local fVal = math.floor(currentFPSDisplay + 0.5)

    if fpsLbl and fpsLbl.Parent then
        fpsLbl.Text = fVal .. " fps"
        fpsLbl.TextColor3 =
            colorByQuality(fVal, 50, 30)
    end

    if lobbyFpsLbl and lobbyFpsLbl.Parent then
        lobbyFpsLbl.Text = "🖥 " .. fVal .. "fps"
    end

    currentCoinsDisplay =
        currentCoinsDisplay
        + (targetCoinsDisplay - currentCoinsDisplay) * alpha

    if lobbyCoins and lobbyCoins.Parent then
        lobbyCoins.Text =
            "💰 " .. fmtFullNum(currentCoinsDisplay)
    end

    currentGemsDisplay =
        currentGemsDisplay
        + (targetGemsDisplay - currentGemsDisplay) * alpha

    if lobbyGems and lobbyGems.Parent then
        lobbyGems.Text =
            "💎 " .. fmtFullNum(currentGemsDisplay)
    end
end)

task.spawn(function()
    while true do
        task.wait(1)

        if not gui or not gui.Parent then
            break
        end

        pcall(function()
            local m, l = getStats()
            lvlInlineLbl.Text = "⭐ Lv" .. l
            timeLbl.Text = os.date("%H:%M")

            local nowC = os.clock()

            if lastCash then
                local gross = (m - lastCash) + recentSpend

                if gross > 0 then
                    incomeSamples[#incomeSamples + 1] = {
                        nowC,
                        gross
                    }
                end
            end

            lastCash = m
            recentSpend = 0

            while incomeSamples[1]
                and nowC - incomeSamples[1][1] > 60 do
                table.remove(incomeSamples, 1)
            end

            local sum = 0

            for _, smp in ipairs(incomeSamples) do
                sum = sum + smp[2]
            end

            local span = math.clamp(
                nowC - incomeStart,
                10,
                60
            )

            targetIncomeDisplay = sum / span * 60

            local rst, rsec = getRepairState()

            if rst == "ready" then
                repairLbl.Text = "Ready"
                repairLbl.TextColor3 = C.S
            elseif rst == "active" then
                repairLbl.Text =
                    "Healing " .. math.ceil(rsec) .. "s"
                repairLbl.TextColor3 = C.A
            else
                repairLbl.Text =
                    "CD " .. math.ceil(rsec) .. "s"
                repairLbl.TextColor3 = C.G
            end

            if isUpgrading and isAutoDoor then
                if nextText
                    and nextText ~= "No target"
                    and nextText ~= "Farm cooldown..." then

                    nextLbl.Text =
                        nextText .. " (Door active)"
                else
                    local house = getMyHouse()

                    if house then
                        local lowestLv = math.huge

                        for i = 1, myDoorCount do
                            local lv =
                                house:GetAttribute(doorLvKey(i)) or 0

                            if lv < doorCap and lv < lowestLv then
                                lowestLv = lv
                            end
                        end

                        if lowestLv ~= math.huge then
                            local dc = getDoorUpgradeCost(lowestLv)
                            local cash = getCash()
                            local tail = ""

                            if dc then
                                tail = "  $" .. dc

                                if cash < dc then
                                    tail = tail
                                        .. " (-$"
                                        .. math.floor(dc - cash)
                                        .. ")"
                                end
                            end

                            nextLbl.Text =
                                "Door "
                                .. lowestLv
                                .. "->"
                                .. (lowestLv + 1)
                                .. tail
                                .. " (Unit on)"
                        else
                            nextLbl.Text = nextText
                        end
                    else
                        nextLbl.Text = nextText
                    end
                end

            elseif isUpgrading then
                nextLbl.Text = nextText

            elseif isAutoDoor then
                local house = getMyHouse()

                if house then
                    local lowestLv = math.huge

                    for i = 1, myDoorCount do
                        local lv =
                            house:GetAttribute(doorLvKey(i)) or 0

                        if lv < doorCap and lv < lowestLv then
                            lowestLv = lv
                        end
                    end

                    if lowestLv == math.huge then
                        nextLbl.Text = "Door at target cap"
                    else
                        local dc = getDoorUpgradeCost(lowestLv)
                        local cash = getCash()
                        local tail = ""

                        if dc then
                            tail = "  $" .. dc

                            if cash < dc then
                                tail = tail
                                    .. " (-$"
                                    .. math.floor(dc - cash)
                                    .. ")"
                            end
                        end

                        nextLbl.Text =
                            "Door "
                            .. lowestLv
                            .. "->"
                            .. (lowestLv + 1)
                            .. tail
                    end
                else
                    nextLbl.Text = "Door: No house"
                end
            else
                nextLbl.Text = "Automation idle (All off)"
            end

            local okN, n = pcall(function()
                return #Players:GetPlayers()
            end)

            if okN then
                playerCountLbl.Text = n .. " Players"
            end

            local okP, ping = pcall(function()
                return Stats.Network.ServerStatsItem[
                    "Data Ping"
                ]:GetValue()
            end)

            if okP and type(ping) == "number" then
                targetPingDisplay = ping
            end

            local fps = getApproxFPS()

            if fps then
                targetFPSDisplay = fps
            end

            targetCoinsDisplay =
                player:GetAttribute("Coins") or 0

            targetGemsDisplay =
                player:GetAttribute("Gems") or 0
        end)
    end
end)

local rowPool = {}
local headerPool = {}
local refreshList

local function getPooledRow(index)
    local row = rowPool[index]

    if not row then
        row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 26)
        row.BackgroundColor3 = C.P

        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

        local cb = Instance.new("TextButton", row)
        cb.Name = "CB"
        cb.Size = UDim2.new(0, 16, 0, 16)
        cb.Position = UDim2.new(0, 5, 0, 5)
        cb.TextColor3 = Color3.new(1, 1, 1)
        cb.TextSize = 10

        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel", row)
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, -100, 1, 0)
        lbl.Position = UDim2.new(0, 26, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = C.T
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd

        local minusBtn = Instance.new("TextButton", row)
        minusBtn.Name = "Minus"
        minusBtn.Size = UDim2.new(0, 16, 0, 16)
        minusBtn.Position = UDim2.new(1, -66, 0, 5)
        minusBtn.BackgroundColor3 =
            Color3.fromRGB(50, 50, 60)
        minusBtn.Text = "-"
        minusBtn.TextColor3 = C.T
        minusBtn.TextSize = 11
        minusBtn.Font = Enum.Font.GothamBold

        Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

        local rowCap = Instance.new("TextLabel", row)
        rowCap.Name = "Cap"
        rowCap.Size = UDim2.new(0, 22, 1, 0)
        rowCap.Position = UDim2.new(1, -46, 0, 0)
        rowCap.BackgroundTransparency = 1
        rowCap.TextColor3 = C.A
        rowCap.TextSize = 11
        rowCap.Font = Enum.Font.GothamBold

        local plusBtn = Instance.new("TextButton", row)
        plusBtn.Name = "Plus"
        plusBtn.Size = UDim2.new(0, 16, 0, 16)
        plusBtn.Position = UDim2.new(1, -22, 0, 5)
        plusBtn.BackgroundColor3 =
            Color3.fromRGB(50, 50, 60)
        plusBtn.Text = "+"
        plusBtn.TextColor3 = C.T
        plusBtn.TextSize = 11
        plusBtn.Font = Enum.Font.GothamBold

        Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

        local function rowData()
            return unitData[row:GetAttribute("Unit")]
        end

        cb.MouseButton1Click:Connect(function()
            local data = rowData()
            if not data then return end

            data.selected = not data.selected
            cb.BackgroundColor3 =
                data.selected and C.S
                or Color3.fromRGB(50, 50, 60)

            cb.Text = data.selected and "✓" or ""
            refreshList()
        end)

        minusBtn.MouseButton1Click:Connect(function()
            local data = rowData()

            if data and data.cap > 1 then
                data.cap = data.cap - 1
                rowCap.Text = tostring(data.cap)
            end
        end)

        plusBtn.MouseButton1Click:Connect(function()
            local data = rowData()
            if not data then return end

            local maxCap = 99

            if data[1]
                and data[1].obj
                and data[1].obj.Parent then

                maxCap =
                    data[1].obj:GetAttribute("LevelCap") or 99
            end

            if data.cap < maxCap then
                data.cap = data.cap + 1
                rowCap.Text = tostring(data.cap)
            end
        end)

        rowPool[index] = row
    end

    return row
end

local function getPooledHeader(index)
    local h = headerPool[index]

    if not h then
        h = Instance.new("Frame")
        h.Size = UDim2.new(1, -6, 0, 24)

        Instance.new("UICorner", h).CornerRadius = UDim.new(0, 5)

        local cb = Instance.new("TextButton", h)
        cb.Name = "CB"
        cb.Size = UDim2.new(0, 16, 0, 16)
        cb.Position = UDim2.new(0, 4, 0, 4)
        cb.TextColor3 = Color3.new(1, 1, 1)
        cb.TextSize = 10

        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel", h)
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, -92, 1, 0)
        lbl.Position = UDim2.new(0, 24, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd

        local tag = Instance.new("TextLabel", h)
        tag.Name = "Tag"
        tag.Size = UDim2.new(0, 64, 1, 0)
        tag.Position = UDim2.new(1, -68, 0, 0)
        tag.BackgroundTransparency = 1
        tag.TextSize = 9
        tag.Font = Enum.Font.Gotham
        tag.TextXAlignment = Enum.TextXAlignment.Right

        cb.MouseButton1Click:Connect(function()
            local owner = h:GetAttribute("Owner")
            if not owner then return end

            local anyOff = false

            for _, d in pairs(unitData) do
                if d.owner == owner and not d.selected then
                    anyOff = true
                end
            end

            for _, d in pairs(unitData) do
                if d.owner == owner then
                    d.selected = anyOff
                end
            end

            refreshList()
        end)

        headerPool[index] = h
    end

    return h
end

refreshList = function()
    if not gui or not gui.Parent then return end

    for _, row in pairs(rowPool) do
        row.Visible = false
    end

    for _, hd in pairs(headerPool) do
        hd.Visible = false
    end

    local house = getMyHouse()
    local groups, owners = {}, {}

    for key, data in pairs(unitData) do
        local visibleCount = 0

        for _, pos in ipairs(data) do
            if pos.obj and pos.obj.Parent then
                local lv =
                    pos.obj:GetAttribute("Level") or 0
                local cap =
                    pos.obj:GetAttribute("LevelCap") or 99

                if lv < cap then
                    visibleCount = visibleCount + 1
                end
            end
        end

        if visibleCount > 0 and data.owner and data.unit then
            local g = groups[data.owner]

            if not g then
                g = {}
                groups[data.owner] = g
                owners[#owners + 1] = data.owner
            end

            g[#g + 1] = {
                key = key,
                data = data,
                unit = data.unit,
                count = visibleCount
            }
        end
    end

    table.sort(owners, function(a, b)
        local ra = ownerRank(a, house)
        local rb = ownerRank(b, house)

        if ra ~= rb then
            return ra < rb
        end

        return tostring(a) < tostring(b)
    end)

    local order = 0
    local rowCount = 0
    local hdrCount = 0

    for _, owner in ipairs(owners) do
        local g = groups[owner]

        table.sort(g, function(a, b)
            return a.unit < b.unit
        end)

        local rank = ownerRank(owner, house)
        local bg, fg, tagText

        if rank == 0 then
            bg = Color3.fromRGB(32, 64, 92)
            fg = C.A
            tagText = "You"
        elseif rank == 1 then
            bg = Color3.fromRGB(32, 80, 52)
            fg = C.S
            tagText = "Host"
        else
            bg = Color3.fromRGB(88, 72, 28)
            fg = C.G
            tagText = "Team"
        end

        hdrCount = hdrCount + 1
        order = order + 1

        local hd = getPooledHeader(hdrCount)
        hd:SetAttribute("Owner", owner)
        hd.LayoutOrder = order
        hd.BackgroundColor3 = bg
        hd.Visible = true
        hd.Parent = listFrame

        local allOn = true

        for _, e in ipairs(g) do
            if not e.data.selected then
                allOn = false
            end
        end

        hd.CB.BackgroundColor3 =
            allOn and C.S
            or Color3.fromRGB(50, 50, 60)

        hd.CB.Text = allOn and "✓" or ""
        hd.Lbl.Text = tostring(owner)
        hd.Lbl.TextColor3 = fg
        hd.Tag.Text = tagText .. " · " .. #g
        hd.Tag.TextColor3 = fg

        for _, e in ipairs(g) do
            rowCount = rowCount + 1
            order = order + 1

            local row = getPooledRow(rowCount)
            row:SetAttribute("Unit", e.key)
            row.LayoutOrder = order
            row.Visible = true
            row.Parent = listFrame

            row.CB.BackgroundColor3 =
                e.data.selected and C.S
                or Color3.fromRGB(50, 50, 60)

            row.CB.Text =
                e.data.selected and "✓" or ""

            row.Lbl.Text =
                e.unit .. " (" .. e.count .. ")"

            row.Cap.Text = tostring(e.data.cap)
        end
    end

    noDataLabel.Visible = rowCount == 0

    listFrame.CanvasSize = UDim2.new(
        0,
        0,
        0,
        listLayout.AbsoluteContentSize.Y + 10
    )
end

local function refreshLobby()
    local _, lvl = getStats()

    if not lvl or lvl == 0 then
        lvl = player:GetAttribute("XPLevel") or 0
    end

    local cur, max = getRealXP()

    if cur and max and max > 0 then
        lobbyXpLbl.Text =
            "✨ Lv" .. lvl .. "  XP: " .. cur .. " / " .. max

        local percent = math.clamp(cur / max, 0, 1)

        TweenService:Create(
            lobbyXpFill,
            TweenInfo.new(0.5),
            {Size = UDim2.new(percent, 0, 1, 0)}
        ):Play()
    else
        lobbyXpLbl.Text =
            "✨ Lv" .. lvl .. "  XP: -- / --"

        TweenService:Create(
            lobbyXpFill,
            TweenInfo.new(0.3),
            {Size = UDim2.new(0, 0, 1, 0)}
        ):Play()
    end

    local vip = player:GetAttribute("HasVip") or false

    lobbyVip.Text =
        "👑 VIP: " .. (vip and "Active" or "None")

    if vip then
        startVipPulse()
    else
        stopVipPulse()
        lobbyVip.TextColor3 =
            Color3.fromRGB(130, 130, 140)
    end

    local day =
        player:GetAttribute("DailyRewardDay") or 0

    local claimable =
        player:GetAttribute("DailyRewardClaimable") or false

    lobbyDaily.Text =
        "📅 Day: " .. tostring(day)
        .. (claimable and " ✓" or "")

    local okN, n = pcall(function()
        return #Players:GetPlayers()
    end)

    if okN then
        lobbyPlayerLbl.Text = "👥 " .. n
    end

    lobbyClockLbl.Text = "🕒 " .. os.date("%H:%M")
end

local function applyMode(inMatch)
    infoPanel.Visible = inMatch
    upgradePanel.Visible = inMatch
    lobbyPanel.Visible = not inMatch

    if inMatch then
        infoPanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)
        upgradePanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)

        if capInput and not capInput:IsFocused() then
            capInput.Text = tostring(doorCap)
        end
    else
        pcall(refreshLobby)
    end
end

task.spawn(function()
    while gui.Parent do
        task.wait(1)

        if not gui or not gui.Parent then
            break
        end

        applyMode(isInMatch())
    end
end)

local function scanTowers()
    local capSnap = {}
    local selSnap = {}
    local ownerSnap = {}
    local unitSnap = {}

    for k, d in pairs(unitData) do
        capSnap[k] = d.cap
        selSnap[k] = d.selected
        ownerSnap[k] = d.owner
        unitSnap[k] = d.unit
    end

    local newData = {}
    local house = getMyHouse()
    local placed = workspace:FindFirstChild("PlacedTowers")

    if placed and house then
        for _, obj in ipairs(placed:GetChildren()) do
            local owner = obj:GetAttribute("OwnerName")
            local hn = obj:GetAttribute("HouseName")

            if type(owner) == "string"
                and owner ~= ""
                and (hn == nil or hn == house.Name) then

                local name = obj.Name
                local key = owner .. "|" .. name
                local x, y

                local ck = obj:GetAttribute("CellKey")

                if ck then
                    local px, py =
                        tostring(ck):match("(%d+):(%d+)")

                    if px and py then
                        x = tonumber(px)
                        y = tonumber(py)
                    end
                end

                local lvl =
                    obj:GetAttribute("Level") or 0

                local gcap =
                    obj:GetAttribute("LevelCap") or 99

                if x and y then
                    if not newData[key] then
                        local prevCap = capSnap[key]
                        local finalCap = gcap

                        if type(prevCap) == "number"
                            and prevCap >= 1 then

                            finalCap =
                                (gcap < prevCap)
                                and gcap
                                or prevCap
                        end

                        newData[key] = {
                            owner = owner,
                            unit = name,
                            selected = selSnap[key] or false,
                            cap = finalCap
                        }
                    end

                    if lvl < gcap then
                        table.insert(newData[key], {
                            x = x,
                            y = y,
                            obj = obj
                        })
                    end
                end
            end
        end
    end

    if house then
        local c = house:GetAttribute("DoorFolderCount")

        if c and type(c) == "number" then
            myDoorCount = c
        end
    end

    for k, cap in pairs(capSnap) do
        if not newData[k]
            and ownerSnap[k]
            and unitSnap[k] then

            newData[k] = {
                owner = ownerSnap[k],
                unit = unitSnap[k],
                selected = selSnap[k] or false,
                cap = cap
            }
        end
    end

    unitData = newData
end

local function doScan()
    scanTowers()
    refreshList()
end

task.spawn(function()
    local lastHouseName = nil

    while gui.Parent do
        pcall(function()
            local h = getMyHouse()

            if h then
                if h.Name ~= lastHouseName then
                    lastHouseName = h.Name

                    local owner = h:GetAttribute("OwnerName")
                    local who

                    if owner == player.Name then
                        who = "Own"
                    elseif type(owner) == "string"
                        and owner ~= "" then
                        who = owner .. " (Team)"
                    else
                        who = "Team"
                    end

                    houseLbl.Text =
                        h.Name .. "  |  " .. who
                end
            else
                lastHouseName = nil
                houseLbl.Text = "-- (no house)"
            end
        end)

        task.wait(1)
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(2)

        if not gui or not gui.Parent then
            break
        end

        pcall(function()
            if isInMatch() then
                scanTowers()

                if container.Visible then
                    refreshList()
                end
            end
        end)
    end
end)

local actionBusy = false
local farmBusy = false
local emergencyDoorBusy = false

local repairLoopToken = 0
local doorLoopToken = 0
local unitLoopToken = 0

local function getDoorHealth(house, index)
    local hp = house:GetAttribute("DoorHP" .. index)

    if hp == nil then
        hp = house:GetAttribute("DoorHP")
    end

    local mx = house:GetAttribute("DoorMaxHP" .. index)

    if mx == nil then
        mx = house:GetAttribute("DoorMaxHP")
    end

    if type(hp) ~= "number"
        or type(mx) ~= "number"
        or mx <= 0 then
        return nil
    end

    return hp / mx
end

local function getEmergencyDoors(house)
    local doors = {}

    if not house then
        return doors
    end

    for i = 1, myDoorCount do
        local ratio = getDoorHealth(house, i)
        local lv = house:GetAttribute(doorLvKey(i)) or 0

        if ratio
            and ratio < 0.60
            and lv < doorCap then
            doors[#doors + 1] = i
        end
    end

    table.sort(doors, function(a, b)
        local ra = getDoorHealth(house, a) or 1
        local rb = getDoorHealth(house, b) or 1

        if ra ~= rb then
            return ra < rb
        end

        return a < b
    end)

    return doors
end

local function getAffordableEmergencyDoor(house)
    if not isAutoRepair or not house then
        return nil
    end

    if os.clock() < doorBlockUntil then
        return nil
    end

    local cash = getCash()

    for _, index in ipairs(getEmergencyDoors(house)) do
        local lv = house:GetAttribute(doorLvKey(index)) or 0
        local cost = getDoorUpgradeCost(lv)

        if cost and cash >= cost then
            return index
        end
    end

    return nil
end

local function updateEmergencyState(house)
    if not isAutoRepair or not house then
        emergencyDoorBusy = false
        return false
    end

    refreshDoorCount()

    emergencyDoorBusy = #getEmergencyDoors(house) > 0

    return emergencyDoorBusy
end

local function tryEmergencyDoor(house)
    if not isAutoRepair or not house then
        return false
    end

    local index = getAffordableEmergencyDoor(house)

    if not index then
        return false
    end

    upgradeSpecificDoor(
        house,
        getCash(),
        index
    )

    return true
end

local function getFarmPriorityState(house)
    if not house then
        return false
    end

    for _, data in pairs(unitData) do
        if data.selected and isFarmTower(data.unit) then
            for _, pos in ipairs(data) do
                local obj = pos.obj

                if obj and obj.Parent then
                    local lv = obj:GetAttribute("Level") or 0

                    local cap = math.min(
                        obj:GetAttribute("LevelCap") or 99,
                        data.cap or 99
                    )

                    if lv < cap
                        and getUnitUpgradeCost(obj.Name, lv) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function runLocked(fn)
    if actionBusy then
        return false
    end

    actionBusy = true
    local ok = pcall(fn)
    actionBusy = false

    return ok
end

local function setRepairUI(on)
    if on then
        repairBtn.Text = "🔧 Repairing..."
        repairBtn.BackgroundColor3 = C.S
    else
        repairBtn.Text = "🔧 Repair"
        repairBtn.BackgroundColor3 = C.P
    end
end

local function startRepairLoop()
    repairLoopToken = repairLoopToken + 1
    local myToken = repairLoopToken

    isAutoRepair = true
    setRepairUI(true)

    task.spawn(function()
        while isAutoRepair and myToken == repairLoopToken do
            if not gui or not gui.Parent then
                if myToken == repairLoopToken then
                    isAutoRepair = false
                    emergencyDoorBusy = false
                    setRepairUI(false)
                end
                break
            end

            pcall(function()
                local house = getMyHouse()

                if not house then
                    emergencyDoorBusy = false
                    return
                end

                refreshDoorCount()

                local needRepair = false

                for i = 1, myDoorCount do
                    local ratio = getDoorHealth(house, i)

                    if ratio and ratio < 0.75 then
                        needRepair = true
                        break
                    end
                end

                if needRepair and getRepairState() == "ready" then
                    local remote = getRemote("RepairDoor")

                    if remote then
                        pcall(function()
                            remote:FireServer()
                        end)
                    end
                end

                updateEmergencyState(house)

                if actionBusy then
                    return
                end

                if not getAffordableEmergencyDoor(house) then
                    return
                end

                runLocked(function()
                    if not isAutoRepair
                        or myToken ~= repairLoopToken then
                        return
                    end

                    if getMyHouse() ~= house then
                        return
                    end

                    tryEmergencyDoor(house)
                end)
            end)

            task.wait(0.3)
        end

        if myToken == repairLoopToken then
            emergencyDoorBusy = false
        end
    end)
end

local function stopRepairLoop()
    repairLoopToken = repairLoopToken + 1
    isAutoRepair = false
    emergencyDoorBusy = false
    setRepairUI(false)
end

repairBtn.MouseButton1Click:Connect(function()
    if isAutoRepair then
        stopRepairLoop()
    else
        startRepairLoop()
    end
end)

local function setDoorUI(on)
    if on then
        doorUpBtn.Text = "🚪 Upgrading..."
        doorUpBtn.BackgroundColor3 = C.S
    else
        doorUpBtn.Text = "🚪 Upgrade Door"
        doorUpBtn.BackgroundColor3 = C.P
    end
end

local function startDoorLoop()
    doorLoopToken = doorLoopToken + 1
    local myToken = doorLoopToken

    isAutoDoor = true
    setDoorUI(true)

    task.spawn(function()
        while isAutoDoor and myToken == doorLoopToken do
            if not gui or not gui.Parent then
                if myToken == doorLoopToken then
                    isAutoDoor = false
                    setDoorUI(false)
                end
                break
            end

            pcall(function()
                if actionBusy then
                    return
                end

                runLocked(function()
                    if not isAutoDoor
                        or myToken ~= doorLoopToken then
                        return
                    end

                    local house = getMyHouse()

                    if not house then
                        return
                    end

                    refreshDoorCount()
                    updateEmergencyState(house)

                    if getAffordableEmergencyDoor(house) then
                        tryEmergencyDoor(house)
                        return
                    end

                    if isUpgrading
                        and getFarmPriorityState(house) then
                        farmBusy = true
                        return
                    end

                    farmBusy = false

                    upgradeLowestDoor(
                        house,
                        getCash()
                    )
                end)
            end)

            task.wait(0.4)
        end
    end)
end

local function stopDoorLoop()
    doorLoopToken = doorLoopToken + 1
    isAutoDoor = false
    setDoorUI(false)
end

doorUpBtn.MouseButton1Click:Connect(function()
    if isAutoDoor then
        stopDoorLoop()
    else
        startDoorLoop()
    end
end)

local function setUnitUI(on)
    if on then
        toggleAutoBtn.Text = "⏹ Stop Auto Upgrade"
        toggleAutoBtn.BackgroundColor3 = C.D
    else
        toggleAutoBtn.Text = "🚀 Start Auto Upgrade"
        toggleAutoBtn.BackgroundColor3 = C.S
    end
end

local function unitTick()
    farmBusy = false

    if not isUpgrading then
        return
    end

    local house = getMyHouse()

    if not house then
        nextText = "No house"
        return
    end

    refreshDoorCount()
    updateEmergencyState(house)

    if getAffordableEmergencyDoor(house) then
        nextText = "Emergency Door"
        tryEmergencyDoor(house)
        return
    end

    local now = os.clock()
    local cash = getCash()

    local farmCands = {}
    local otherCands = {}

    local farmPending = false
    local farmBlocked = false
    local farmWaiting = false

    for _, data in pairs(unitData) do
        if data.selected then
            local farm = isFarmTower(data.unit)
            local rank = ownerRank(data.owner, house)

            for _, pos in ipairs(data) do
                local obj = pos.obj

                if obj and obj.Parent then
                    local lv = obj:GetAttribute("Level") or 0

                    local cap = math.min(
                        obj:GetAttribute("LevelCap") or 99,
                        data.cap or 99
                    )

                    if lv < cap then
                        local cost =
                            getUnitUpgradeCost(obj.Name, lv)

                        if cost then
                            local onCD =
                                now < (upgradeCooldown[obj] or 0)

                            local locked = isTowerLocked(obj)

                            local entry = {
                                pos = pos,
                                name = data.unit,
                                level = lv,
                                cost = cost,
                                obj = obj,
                                rank = rank,
                                owner = data.owner
                            }

                            if farm then
                                farmPending = true

                                local blocked = false

                                for i = 1, myDoorCount do
                                    local doorLv =
                                        house:GetAttribute(
                                            doorLvKey(i)
                                        ) or 0

                                    if lv >= doorLv then
                                        blocked = true
                                        break
                                    end
                                end

                                if blocked then
                                    farmBlocked = true
                                elseif onCD or locked then
                                    farmWaiting = true
                                else
                                    table.insert(
                                        farmCands,
                                        entry
                                    )
                                end
                            elseif not onCD and not locked then
                                table.insert(
                                    otherCands,
                                    entry
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(farmCands, function(a, b)
        if a.level ~= b.level then
            return a.level < b.level
        end

        if a.rank ~= b.rank then
            return a.rank < b.rank
        end

        return a.cost < b.cost
    end)

    table.sort(otherCands, function(a, b)
        if a.cost ~= b.cost then
            return a.cost < b.cost
        end

        if a.rank ~= b.rank then
            return a.rank < b.rank
        end

        return a.level < b.level
    end)

    local function fmtTarget(e)
        local who =
            e.rank == 0
            and ""
            or (tostring(e.owner) .. ": ")

        local need = e.cost - cash

        local tail =
            need > 0
            and (" (-$" .. math.floor(need) .. ")")
            or ""

        return who
            .. e.name
            .. " "
            .. e.level
            .. "->"
            .. (e.level + 1)
            .. "  $"
            .. e.cost
            .. tail
    end

    local function doorTargetText()
        local lowLv = nil

        for i = 1, myDoorCount do
            local lv =
                house:GetAttribute(doorLvKey(i)) or 0

            if lv < doorCap
                and (not lowLv or lv < lowLv) then
                lowLv = lv
            end
        end

        if lowLv == nil then
            return "Door at cap"
        end

        local dc = getDoorUpgradeCost(lowLv)
        local tail = ""

        if dc then
            tail = "  $" .. dc

            if cash < dc then
                tail = tail
                    .. " (-$"
                    .. math.floor(dc - cash)
                    .. ")"
            end
        end

        return "Door "
            .. lowLv
            .. "->"
            .. (lowLv + 1)
            .. tail
    end

    local chosen = nil
    nextText = "No target"

    if farmPending then
        farmBusy = true

        if #farmCands > 0 then
            local minLv = farmCands[1].level

            for _, c in ipairs(farmCands) do
                if c.level ~= minLv then
                    break
                end

                if cash >= c.cost then
                    chosen = c
                    break
                end
            end

            nextText = fmtTarget(
                chosen or farmCands[1]
            )

            if not chosen then
                return
            end

        elseif farmBlocked then
            nextText = doorTargetText()

            upgradeLowestDoor(
                house,
                getCash()
            )

            return

        elseif farmWaiting then
            nextText = "Farm cooldown..."
            return

        else
            nextText = "Farm waiting..."
            return
        end

    else
        if isAutoDoor then
            local doorPending = false

            for i = 1, myDoorCount do
                local lv =
                    house:GetAttribute(doorLvKey(i)) or 0

                if lv < doorCap then
                    doorPending = true
                    break
                end
            end

            if doorPending then
                nextText = doorTargetText()
                return
            end
        end

        for _, c in ipairs(otherCands) do
            if cash >= c.cost then
                chosen = c
                break
            end
        end

        if chosen or otherCands[1] then
            nextText = fmtTarget(
                chosen or otherCands[1]
            )
        end
    end

    if not chosen then
        return
    end

    if getAffordableEmergencyDoor(house) then
        nextText = "Emergency Door"
        tryEmergencyDoor(house)
        return
    end

    local upg = getRemote("UpgradeTower")

    if not upg then
        return
    end

    local validator = function()
        return canFireTower(
            chosen.obj,
            chosen.pos.x,
            chosen.pos.y
        )
    end

    local success = fireAndConfirm(
        upg,
        chosen.obj,
        {
            chosen.pos.x,
            chosen.pos.y
        },
        validator
    )

    if success then
        upgradeCooldown[chosen.obj] =
            os.clock() + UPGRADE_COOLDOWN

        recentSpend =
            recentSpend + chosen.cost
    else
        upgradeCooldown[chosen.obj] =
            os.clock() + UPGRADE_FAIL_COOLDOWN
    end
end

local function startUnitLoop()
    unitLoopToken = unitLoopToken + 1
    local myToken = unitLoopToken

    isUpgrading = true
    setUnitUI(true)

    task.spawn(function()
        while isUpgrading
            and myToken == unitLoopToken do

            if not gui or not gui.Parent then
                if myToken == unitLoopToken then
                    isUpgrading = false
                    farmBusy = false
                    setUnitUI(false)
                end
                break
            end

            pcall(function()
                if actionBusy then
                    return
                end

                runLocked(function()
                    if not isUpgrading
                        or myToken ~= unitLoopToken then
                        return
                    end

                    unitTick()
                end)
            end)

            task.wait(0.4)
        end
    end)
end

local function stopUnitLoop()
    unitLoopToken = unitLoopToken + 1
    isUpgrading = false
    farmBusy = false
    setUnitUI(false)
end

toggleAutoBtn.MouseButton1Click:Connect(function()
    if isUpgrading then
        stopUnitLoop()
    else
        startUnitLoop()
    end
end)

local drag = false
local dStart = nil
local sPos = nil
local moved = false

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        drag = true
        moved = false
        dStart = input.Position
        sPos = toggleBtn.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if drag and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then

        local delta = input.Position - dStart

        if delta.Magnitude > 6 then
            moved = true
        end

        if moved then
            toggleBtn.Position = UDim2.new(
                sPos.X.Scale,
                sPos.X.Offset + delta.X,
                sPos.Y.Scale,
                sPos.Y.Offset + delta.Y
            )
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        drag = false
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    if moved then
        moved = false
        return
    end

    container.Visible = not container.Visible

    if container.Visible then
        pcall(doScan)

        containerScale.Scale = 0.7

        TweenService:Create(
            containerScale,
            TweenInfo.new(
                0.3,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {
                Scale = 1
            }
        ):Play()
    end
end)

local isGameInitialized = false

local function initGame()
    if isGameInitialized then
        return
    end

    if not isInMatch() then
        toggleBtn.Visible = true
        return
    end

    isGameInitialized = true

    pcall(function()
        TowerStats = require(
            rs:WaitForChild("TowerStats", 5)
        )
    end)

    pcall(function()
        TowerConfig = require(
            rs:WaitForChild("TowerConfig", 5)
        )
    end)

    loadProfile()

    if capInput then
        capInput.Text = tostring(doorCap)
    end

    if not TowerStats then
        noDataLabel.Text =
            "⚠ TowerStats not loaded"
    end

    pcall(doScan)

    if isAutoRepair then
        startRepairLoop()
    end

    if isAutoDoor then
        startDoorLoop()
    end

    if isUpgrading then
        startUnitLoop()
    end

    toggleBtn.Visible = true
end

infoPanel.Visible = false
upgradePanel.Visible = false
lobbyPanel.Visible = true
container.Visible = false

initGame()
applyMode(isInMatch())

task.spawn(function()
    task.wait(0.5)

    if not gui or not gui.Parent then
        return
    end

    applyMode(isInMatch())
end)

task.spawn(function()
    while gui.Parent do
        if not isGameInitialized and isInMatch() then
            pcall(initGame)
        end

        task.wait(1)
    end
end)
