local State = {}

function State.Create()
    return {
        isAutoRepair = false,
        isAutoDoor = false,
        isUpgrading = false,

        doorCap = 15,
        oldDoorCap = 15,
        myDoorCount = 1,

        recentSpend = 0,
        nextText = "--",

        unitData = {},
        cachedHouse = nil,

        doorFailCount = 0,
        doorBlockUntil = 0,
    }
end

return State
