local function getDoorHealth(house, index)
    local hp = house:GetAttribute("DoorHP" .. index)

    if hp == nil and myDoorCount == 1 then
        hp = house:GetAttribute("DoorHP")
    end

    local mx = house:GetAttribute("DoorMaxHP" .. index)

    if mx == nil and myDoorCount == 1 then
        mx = house:GetAttribute("DoorMaxHP")
    end

    if type(hp) ~= "number"
        or type(mx) ~= "number"
        or mx <= 0 then
        return nil
    end

    return hp / mx
end

local matchDoorLost = false

local function automationMatchActive(house)
    if not isInMatch() then
        matchDoorLost = false
        return false
    end

    if matchDoorLost or not house then
        return false
    end

    refreshDoorCount()

    for i = 1, myDoorCount do
        local ratio = getDoorHealth(house, i)

        if ratio ~= nil and ratio <= 0 then
            matchDoorLost = true
            emergencyDoorBusy = false
            farmBusy = false

            warn("[SmartUpgrade] Door HP reached 0. Automation paused until the next match.")

            task.spawn(function()
                while matchDoorLost and gui and gui.Parent do
                    if not isInMatch() then
                        matchDoorLost = false
                        return
                    end

                    task.wait(0.1)
                end
            end)

            return false
        end
    end

    return true
end


local function getEmergencyDoors(house)
    local doors = {}
    local ratios = {}

    if not house then
        return doors
    end
  
    for i = 1, myDoorCount do
        local ratio = getDoorHealth(house, i)
        local lv = house:GetAttribute(doorLvKey(i)) or 0

        if ratio then
            ratios[i] = ratio

            if ratio < 0.3 and lv < doorCap then
                doors[#doors + 1] = i
            end
        end
    end
  
    table.sort(doors, function(a, b)
        local ra = ratios[a] or 1
        local rb = ratios[b] or 1

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

                if not automationMatchActive(house) then
                    emergencyDoorBusy = false
                    farmBusy = false

                    return
                end

                if not house then
                    emergencyDoorBusy = false
                    return
                end

                refreshDoorCount()

                local needRepair = false

                for i = 1, myDoorCount do
                    local ratio = getDoorHealth(house, i)

                    if ratio and ratio < 0.5 then
                        needRepair = true
                        break
                    end
                end

                if actionBusy then
                    return
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

            task.wait(0.1)
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

                    if not automationMatchActive(house) then
                        emergencyDoorBusy = false
                        farmBusy = false
                        return
                    end

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

    local matchActive = automationMatchActive(house)

    if not house then
        nextText = "No house"
        return
    end

    if not matchActive then
        farmBusy = false
        nextText = "Match lost / waiting for next match"
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

local inputChangedConn = UIS.InputChanged:Connect(function(input)
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

local inputEndedConn = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        drag = false
    end
end)

gui.Destroying:Connect(function()
    inputChangedConn:Disconnect()
    inputEndedConn:Disconnect()
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
