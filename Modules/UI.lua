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
closeBtn.Text = "×"
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
nextLbl.Size = UDim2.new(0, 0, 1, 0)
nextLbl.Position = UDim2.new(0, 0, 0, 0)
nextLbl.BackgroundTransparency = 1
nextLbl.Text = "--"
nextLbl.TextColor3 = C.T
nextLbl.TextSize = 11
nextLbl.Font = Enum.Font.GothamBold
nextLbl.TextXAlignment = Enum.TextXAlignment.Left
nextLbl.TextTruncate = Enum.TextTruncate.None
nextLbl.TextWrapped = false

do
    local reportScroll = Instance.new("ScrollingFrame", nextBox)
    reportScroll.Name = "ReportScroll"
    reportScroll.Size = UDim2.new(1, -34, 1, 0)
    reportScroll.Position = UDim2.new(0, 28, 0, 0)
    reportScroll.BackgroundTransparency = 1
    reportScroll.BorderSizePixel = 0
    reportScroll.Active = true
    reportScroll.ClipsDescendants = true
    reportScroll.ScrollingDirection = Enum.ScrollingDirection.X
    reportScroll.ScrollBarThickness = 2
    reportScroll.ScrollBarImageColor3 = C.A
    reportScroll.ScrollBarImageTransparency = 0.35
    reportScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    reportScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    nextLbl.Parent = reportScroll
    nextLbl.AutomaticSize = Enum.AutomaticSize.X
end

do
    local matchBox = Instance.new("Frame", infoPanel)
    matchBox.Name = "MatchStatusBox"
    matchBox.Size = UDim2.new(1, 0, 0, 28)
    matchBox.BackgroundColor3 = C.P
    matchBox.BorderSizePixel = 0
    matchBox.LayoutOrder = 7
    matchBox.ClipsDescendants = true

    Instance.new("UICorner", matchBox).CornerRadius =
        UDim.new(0, 6)

    local matchIcon = Instance.new("TextLabel", matchBox)
    matchIcon.Name = "MatchIcon"
    matchIcon.Size = UDim2.new(0, 22, 1, 0)
    matchIcon.Position = UDim2.new(0, 6, 0, 0)
    matchIcon.BackgroundTransparency = 1
    matchIcon.Text = "🎮"
    matchIcon.TextSize = 12
    matchIcon.Font = Enum.Font.Gotham
    matchIcon.TextColor3 = C.A
    matchIcon.TextXAlignment = Enum.TextXAlignment.Center

    local matchScroll = Instance.new("ScrollingFrame", matchBox)
    matchScroll.Name = "MatchStatusScroll"
    matchScroll.Size = UDim2.new(1, -36, 1, 0)
    matchScroll.Position = UDim2.new(0, 30, 0, 0)
    matchScroll.BackgroundTransparency = 1
    matchScroll.BorderSizePixel = 0
    matchScroll.ClipsDescendants = true
    matchScroll.Active = false
    matchScroll.ScrollingDirection = Enum.ScrollingDirection.X
    matchScroll.ScrollBarThickness = 0
    matchScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    matchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local matchStatusLbl = Instance.new("TextLabel", matchScroll)
    matchStatusLbl.Name = "MatchStatus"
    matchStatusLbl.Size = UDim2.new(0, 0, 1, 0)
    matchStatusLbl.AutomaticSize = Enum.AutomaticSize.X
    matchStatusLbl.BackgroundTransparency = 1
    matchStatusLbl.Text = "โหมดไม่ทราบ"
    matchStatusLbl.TextColor3 = C.T
    matchStatusLbl.TextSize = 11
    matchStatusLbl.Font = Enum.Font.GothamBold
    matchStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    matchStatusLbl.TextYAlignment = Enum.TextYAlignment.Center
    matchStatusLbl.TextWrapped = false
    matchStatusLbl.TextTruncate = Enum.TextTruncate.None
end

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
        if not gui
            or not gui.Parent
            or not lobbyVip.Parent
            or not lobbyPanel.Visible
            or not container.Visible then
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
