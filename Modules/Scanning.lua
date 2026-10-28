local function refreshLobby()
    local coins, lvl = getStats()

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
    targetCoinsDisplay = player:GetAttribute("Coins") or coins or 0
    targetGemsDisplay = player:GetAttribute("Gems") or 0
end

local function applyMode(inMatch)
    local modeChanged = infoPanel.Visible ~= inMatch

    infoPanel.Visible = inMatch
    upgradePanel.Visible = inMatch
    lobbyPanel.Visible = not inMatch

    if inMatch and modeChanged then
        infoPanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)
        upgradePanel.Size = UDim2.new(0, CONTAINER_W, 0, 0)

        if capInput and not capInput:IsFocused() then
            capInput.Text = tostring(doorCap)
        end
    elseif not inMatch and modeChanged and container.Visible then
        pcall(refreshLobby)
    end
end

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

if isMatchSession then
    task.spawn(function()
        local lastHouseName = nil

        while gui and gui.Parent do
            task.wait(2)

            if not gui or not gui.Parent then
                break
            end

            pcall(function()
                if container.Visible or isUpgrading then
                    scanTowers()
                end

                if container.Visible then
                    refreshList()
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
                end
            end)
        end
    end)
else
    task.spawn(function()
        while gui and gui.Parent do
            task.wait(10)

            if container.Visible then
                pcall(refreshLobby)
            end
        end
    end)
end

local actionBusy = false
local farmBusy = false
local emergencyDoorBusy = false

local repairLoopToken = 0
local doorLoopToken = 0
local unitLoopToken = 0
