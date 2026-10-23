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
