local function initGame()
    if isGameInitialized then
        return
    end

    if not isInMatch() then
        toggleBtn.Visible = true
        return
    end

    local statsOk, statsResult = pcall(function()
        local module = rs:WaitForChild("TowerStats", 5)

        if not module then
            error("TowerStats module not found")
        end

        return require(module)
    end)

    local configOk, configResult = pcall(function()
        local module = rs:WaitForChild("TowerConfig", 5)

        if not module then
            error("TowerConfig module not found")
        end

        return require(module)
    end)

    TowerStats = statsOk and statsResult or nil
    TowerConfig = configOk and configResult or nil

    if not TowerStats or not TowerConfig then
        noDataLabel.Text = not TowerStats
            and "⚠ TowerStats not loaded; retrying..."
            or "⚠ TowerConfig not loaded; retrying..."

        toggleBtn.Visible = true
        return
    end

    loadProfile()

    if capInput then
        capInput.Text = tostring(doorCap)
    end

    isGameInitialized = true
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
