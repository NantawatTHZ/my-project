local currentFPS = 60
local fpsElapsed = 0
local fpsFrames = 0

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
    if dt > 0 then
        fpsElapsed = fpsElapsed + dt
        fpsFrames = fpsFrames + 1

        if fpsElapsed >= 0.5 then
            currentFPS = math.floor(
                fpsFrames / fpsElapsed + 0.5
            )
            fpsElapsed = 0
            fpsFrames = 0
        end
    end

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

