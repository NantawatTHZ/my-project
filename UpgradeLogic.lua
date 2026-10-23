local UpgradeLogic = {}
UpgradeLogic.__index = UpgradeLogic

function UpgradeLogic.New(state, config)
    local self = setmetatable({}, UpgradeLogic)
    self.state = state
    self.config = config
    return self
end

function UpgradeLogic:RunLoop()
    while true do
        if self.state.isUpgrading then
            -- logic here
        end

        task.wait(1)
    end
end

return UpgradeLogic
