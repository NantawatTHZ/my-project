local UI = {}
UI.__index = UI

function UI.Create(state)
    local self = setmetatable({}, UI)
    self.state = state
    self.gui = nil
    self.callback = nil
    return self
end

function UI:Show()
    if self.gui then
        self.gui.Visible = true
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SmartUpgradeUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = game:GetService("CoreGui")

    self.gui = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 220, 0, 30)
    title.Position = UDim2.new(0.5, -110, 0.18, 0)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.Text = "Smart Upgrade"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = gui

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 120, 0, 36)
    toggle.Position = UDim2.new(0.5, -60, 0.28, 0)
    toggle.Text = "Toggle"
    toggle.BackgroundColor3 = Color3.fromRGB(74, 158, 255)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.Parent = gui

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 200, 0, 24)
    status.Position = UDim2.new(0.5, -100, 0.4, 0)
    status.Text = "Ready"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = gui

    toggle.MouseButton1Click:Connect(function()
        self.state.isUpgrading = not self.state.isUpgrading
        status.Text = self.state.isUpgrading and "Running" or "Paused"
    end)
end

function UI:BindActions(callback)
    self.callback = callback
end

return UI
