--[[
    Custom Script Hub – Fully Self-Contained
    No external dependencies. Works on any executor.
--]]

repeat wait() until game:IsLoaded()

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- ========== UI CREATION (no external libs) ==========
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomHub"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner").Parent = MainFrame

    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TitleBar.Parent = MainFrame
    Instance.new("UICorner").Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Custom Script Hub"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 1, 0)
    CloseBtn.Position = UDim2.new(1, -30, 0, 0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, 0, 0, 40)
    TabBar.Position = UDim2.new(0, 0, 0, 35)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = MainFrame

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -20, 1, -85)
    ContentContainer.Position = UDim2.new(0, 10, 0, 80)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 6
    ScrollingFrame.Parent = ContentContainer

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ScrollingFrame

    local tabs = {}
    local function AddTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, -6)
        btn.Position = UDim2.new(#tabs * 0.19 + 0.02, 0, 0, 3)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.Parent = TabBar
        Instance.new("UICorner").Parent = btn

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 0, 0)
        content.BackgroundTransparency = 1
        content.Visible = false
        content.Parent = ScrollingFrame

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 6)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content

        table.insert(tabs, {btn = btn, content = content})

        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(tabs) do
                t.content.Visible = false
                t.btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            end
            content.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)

            -- Update canvas size
            local totalHeight = 0
            for _, child in pairs(content:GetChildren()) do
                if child:IsA("Frame") then
                    totalHeight = totalHeight + child.Size.Y.Offset + contentLayout.Padding.Offset
                end
            end
            ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        end)

        if #tabs == 1 then btn.MouseButton1Click() end
        return content
    end

    -- UI element builders
    local function AddToggle(parent, name, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner").Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 26)
        btn.Position = UDim2.new(1, -70, 0.5, -13)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.Parent = frame
        Instance.new("UICorner").Parent = btn

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
            btn.Text = state and "ON" or "OFF"
            if callback then callback(state) end
        end)
        return frame
    end

    local function AddSlider(parent, name, min, max, default, suffix, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 55)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner").Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 22)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = name .. ": " .. tostring(default) .. suffix
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(0.9, 0, 0, 4)
        sliderFrame.Position = UDim2.new(0.05, 0, 0.7, 0)
        sliderFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
        sliderFrame.BorderSizePixel = 0
        sliderFrame.Parent = frame

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
        fill.BorderSizePixel = 0
        fill.Parent = sliderFrame

        local value = default
        local dragging = false

        local function update(x)
            local rel = math.clamp((x - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            value = min + (max - min) * rel
            value = math.floor(value * 100) / 100
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = name .. ": " .. tostring(value) .. suffix
            if callback then callback(value) end
        end

        sliderFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input.Position.X)
            end
        end)
        return frame
    end

    local function AddColorPicker(parent, name, defaultColor, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 42)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner").Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local colorDisplay = Instance.new("Frame")
        colorDisplay.Size = UDim2.new(0, 50, 0, 26)
        colorDisplay.Position = UDim2.new(1, -60, 0.5, -13)
        colorDisplay.BackgroundColor3 = defaultColor
        colorDisplay.BorderSizePixel = 1
        colorDisplay.BorderColor3 = Color3.fromRGB(255, 255, 255)
        colorDisplay.Parent = frame
        Instance.new("UICorner").Parent = colorDisplay

        local colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255)
        }
        local idx = 1
        colorDisplay.MouseButton1Click:Connect(function()
            idx = idx % #colors + 1
            local newColor = colors[idx]
            colorDisplay.BackgroundColor3 = newColor
            if callback then callback(newColor) end
        end)
        return frame
    end

    local function AddDropdown(parent, name, options, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 42)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner").Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.4, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 28)
        btn.Position = UDim2.new(1, -130, 0.5, -14)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Text = default
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.Parent = frame
        Instance.new("UICorner").Parent = btn

        local isOpen = false
        local optionList = nil
        btn.MouseButton1Click:Connect(function()
            if isOpen then
                if optionList then optionList:Destroy() end
                isOpen = false
                return
            end
            optionList = Instance.new("Frame")
            optionList.Size = UDim2.new(0, 120, 0, #options * 28)
            optionList.Position = UDim2.new(1, -130, 0, 30)
            optionList.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            optionList.BorderSizePixel = 0
            optionList.Parent = frame
            Instance.new("UICorner").Parent = optionList

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 2)
            layout.Parent = optionList

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                optBtn.Text = opt
                optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                optBtn.TextSize = 12
                optBtn.Font = Enum.Font.Gotham
                optBtn.Parent = optionList
                optBtn.MouseButton1Click:Connect(function()
                    btn.Text = opt
                    if callback then callback(opt) end
                    optionList:Destroy()
                    isOpen = false
                end)
            end
            isOpen = true
        end)
        return frame
    end

    -- Make window draggable
    local dragging = false
    local dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                           startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return {
        AddTab = AddTab,
        AddToggle = AddToggle,
        AddSlider = AddSlider,
        AddColorPicker = AddColorPicker,
        AddDropdown = AddDropdown
    }
end

local UI = CreateUI()

-- ========== FEATURE VARIABLES ==========
-- Hitbox
local HitboxEnabled = false
local HitboxSize = 13
local HitboxTransparency = 0.5
local HitboxColor = Color3.fromRGB(255, 0, 0)
local HitboxHeadDot = false

-- ESP
local ESPEnabled = false
local ESPObjects = {}
local ESPSettings = {
    Skeleton = false, HeadBox = false, BodyBox = false,
    Distance = false, Health = false, Name = false,
    Tracer = false, HeadDot = false
}
local ESPColors = {
    Skeleton = Color3.fromRGB(255,255,255), HeadBox = Color3.fromRGB(255,50,50),
    BodyBox = Color3.fromRGB(50,255,50), Tracer = Color3.fromRGB(255,255,255),
    Name = Color3.fromRGB(255,255,255), Health = Color3.fromRGB(255,80,80),
    Distance = Color3.fromRGB(80,200,255), HeadDot = Color3.fromRGB(255,0,0)
}

-- Aimbot
local AimbotEnabled = false
local AimbotKey = Enum.KeyCode.Q
local AimbotFOV = 200
local AimbotShowFOV = true
local AimbotSmoothness = 0.3
local AimbotTarget = nil
local AimbotFOVCircle = nil
local AimbotLockPart = "Head"

-- Local Player
local WalkSpeedValue = 16
local JumpPowerValue = 7.2
local FlyEnabled = false
local FlySpeed = 50
local FlyBodyVelocity = nil
local NoClipEnabled = false

-- ========== HELPER FUNCTIONS ==========
function ApplyLocalStats()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = WalkSpeedValue
            humanoid.JumpPower = JumpPowerValue
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    ApplyLocalStats()
    if FlyEnabled then ToggleFly(true) end
    if NoClipEnabled then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end
    end
end)

function ToggleFly(state)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    if state then
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        FlyBodyVelocity.P = 1e5
        FlyBodyVelocity.Parent = rootPart
        humanoid.PlatformStand = true
        local flyConnection
        flyConnection = RunService.RenderStepped:Connect(function()
            if not FlyEnabled or not char or not char.Parent then
                flyConnection:Disconnect()
                if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
                if humanoid then humanoid.PlatformStand = false end
                return
            end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
            FlyBodyVelocity.Velocity = move.Unit * FlySpeed
        end)
    else
        if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
        if humanoid then humanoid.PlatformStand = false end
    end
end

-- ========== HITBOX LOOP ==========
coroutine.wrap(function()
    while task.wait(0.1) do
        if HitboxEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local char = player.Character
                    for _, partName in pairs({"HumanoidRootPart","Head","Torso","UpperTorso","LowerTorso","RightUpperLeg","LeftUpperLeg"}) do
                        local part = char:FindFirstChild(partName)
                        if part then
                            part.CanCollide = false
                            part.Transparency = HitboxTransparency
                            part.Color = HitboxColor
                            part.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        end
                    end
                    if HitboxHeadDot then
                        local head = char:FindFirstChild("Head")
                        if head and not head:FindFirstChild("HeadDot") then
                            local dot = Instance.new("BillboardGui")
                            dot.Name = "HeadDot"
                            dot.Size = UDim2.new(0,10,0,10)
                            dot.AlwaysOnTop = true
                            dot.Adornee = head
                            local frame = Instance.new("Frame")
                            frame.Size = UDim2.new(1,0,1,0)
                            frame.BackgroundColor3 = Color3.fromRGB(255,0,0)
                            frame.BorderSizePixel = 0
                            frame.Parent = dot
                            dot.Parent = head
                        end
                    else
                        local head = char:FindFirstChild("Head")
                        if head and head:FindFirstChild("HeadDot") then head.HeadDot:Destroy() end
                    end
                end
            end
        end
    end
end)()

-- ========== ESP FUNCTIONS ==========
function ClearESP()
    for player, objects in pairs(ESPObjects) do
        for _, obj in pairs(objects) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    ESPObjects = {}
end

function CreateESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local char = player.Character
    local rootPart = char.HumanoidRootPart
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do if obj and obj.Parent then obj:Destroy() end end
    end
    ESPObjects[player] = {}

    local espGui = Instance.new("BillboardGui")
    espGui.Name = "ESP_Gui"
    espGui.Size = UDim2.new(0, 250, 0, 120)
    espGui.StudsOffset = Vector3.new(0, 3, 0)
    espGui.AlwaysOnTop = true
    espGui.Adornee = rootPart
    espGui.Parent = rootPart
    table.insert(ESPObjects[player], espGui)

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1,0,1,0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = espGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1,-4,0,20)
    nameLabel.Position = UDim2.new(0,2,0,2)
    nameLabel.BackgroundTransparency = 0.7
    nameLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = ESPColors.Name
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = mainFrame
    table.insert(ESPObjects[player], nameLabel)

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "Health"
    healthLabel.Size = UDim2.new(1,-4,0,18)
    healthLabel.Position = UDim2.new(0,2,0,24)
    healthLabel.BackgroundTransparency = 0.7
    healthLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
    healthLabel.TextColor3 = ESPColors.Health
    healthLabel.TextSize = 13
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left
    healthLabel.Parent = mainFrame
    table.insert(ESPObjects[player], healthLabel)

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1,-4,0,18)
    distanceLabel.Position = UDim2.new(0,2,0,44)
    distanceLabel.BackgroundTransparency = 0.7
    distanceLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
    distanceLabel.TextColor3 = ESPColors.Distance
    distanceLabel.TextSize = 13
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Parent = mainFrame
    table.insert(ESPObjects[player], distanceLabel)

    if head then
        local headBox = Instance.new("BoxHandleAdornment")
        headBox.Name = "ESP_HeadBox"
        headBox.Size = head.Size + Vector3.new(0.2,0.2,0.2)
        headBox.Transparency = 0.6
        headBox.Color3 = ESPColors.HeadBox
        headBox.AlwaysOnTop = true
        headBox.Adornee = head
        headBox.Parent = head
        table.insert(ESPObjects[player], headBox)

        local headOutline = Instance.new("SelectionBox")
        headOutline.Name = "ESP_HeadOutline"
        headOutline.Adornee = head
        headOutline.Transparency = 0.7
        headOutline.Color3 = ESPColors.HeadBox
        headOutline.Thickness = 0.15
        headOutline.Parent = head
        table.insert(ESPObjects[player], headOutline)
    end

    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if torso then
        local bodyBox = Instance.new("BoxHandleAdornment")
        bodyBox.Name = "ESP_BodyBox"
        bodyBox.Size = torso.Size + Vector3.new(0.2,0.2,0.2)
        bodyBox.Transparency = 0.6
        bodyBox.Color3 = ESPColors.BodyBox
        bodyBox.AlwaysOnTop = true
        bodyBox.Adornee = torso
        bodyBox.Parent = torso
        table.insert(ESPObjects[player], bodyBox)

        local bodyOutline = Instance.new("SelectionBox")
        bodyOutline.Name = "ESP_BodyOutline"
        bodyOutline.Adornee = torso
        bodyOutline.Transparency = 0.7
        bodyOutline.Color3 = ESPColors.BodyBox
        bodyOutline.Thickness = 0.15
        bodyOutline.Parent = torso
        table.insert(ESPObjects[player], bodyOutline)
    end

    if head then
        local headDot = Instance.new("BillboardGui")
        headDot.Name = "ESP_HeadDot"
        headDot.Size = UDim2.new(0,8,0,8)
        headDot.AlwaysOnTop = true
        headDot.Adornee = head
        local dotFrame = Instance.new("Frame")
        dotFrame.Size = UDim2.new(1,0,1,0)
        dotFrame.BackgroundColor3 = ESPColors.HeadDot
        dotFrame.BorderSizePixel = 0
        dotFrame.Parent = headDot
        headDot.Parent = head
        table.insert(ESPObjects[player], headDot)
    end

    local function createLine(partA, partB)
        if not partA or not partB then return end
        local attA = Instance.new("Attachment", partA)
        local attB = Instance.new("Attachment", partB)
        local beam = Instance.new("Beam")
        beam.Color = ColorSequence.new(ESPColors.Skeleton)
        beam.Transparency = NumberSequence.new(0.3)
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.Attachment0 = attA
        beam.Attachment1 = attB
        beam.Parent = partA
        table.insert(ESPObjects[player], attA)
        table.insert(ESPObjects[player], attB)
        table.insert(ESPObjects[player], beam)
    end
    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
    local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    if torso then
        createLine(torso, rootPart)
        if leftArm then createLine(torso, leftArm) end
        if rightArm then createLine(torso, rightArm) end
        if leftLeg then createLine(rootPart, leftLeg) end
        if rightLeg then createLine(rootPart, rightLeg) end
        if head then createLine(torso, head) end
    end

    local tracer = Instance.new("LineHandleAdornment")
    tracer.Name = "ESP_Tracer"
    tracer.AlwaysOnTop = true
    tracer.Thickness = 0.1
    tracer.Color3 = ESPColors.Tracer
    tracer.Transparency = 0.5
    tracer.Parent = rootPart
    table.insert(ESPObjects[player], tracer)
end

function UpdateESP()
    ClearESP()
    if not ESPEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
        end
    end
end

coroutine.wrap(function()
    while task.wait(0.1) do
        if ESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local objects = ESPObjects[player]
                    if objects then
                        local rootPart = player.Character.HumanoidRootPart
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                        local distance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                                       (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 0
                        for _, obj in pairs(objects) do
                            if obj and obj.Parent then
                                if obj.Name == "Distance" then
                                    obj.Visible = ESPSettings.Distance
                                    if ESPSettings.Distance then obj.Text = string.format("Distance: %.1f", distance) end
                                elseif obj.Name == "Health" then
                                    obj.Visible = ESPSettings.Health
                                    if ESPSettings.Health and humanoid then obj.Text = string.format("Health: %d/%d", humanoid.Health, humanoid.MaxHealth) end
                                elseif obj.Name == "Name" then
                                    obj.Visible = ESPSettings.Name
                                elseif obj.Name == "ESP_HeadBox" or obj.Name == "ESP_HeadOutline" then
                                    obj.Visible = ESPSettings.HeadBox
                                elseif obj.Name == "ESP_BodyBox" or obj.Name == "ESP_BodyOutline" then
                                    obj.Visible = ESPSettings.BodyBox
                                elseif obj.Name == "ESP_HeadDot" then
                                    obj.Visible = ESPSettings.HeadDot
                                elseif obj.ClassName == "Beam" then
                                    obj.Visible = ESPSettings.Skeleton
                                elseif obj.Name == "ESP_Tracer" then
                                    obj.Visible = ESPSettings.Tracer
                                    if ESPSettings.Tracer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        obj.PointA = Camera.CFrame.Position
                                        obj.PointB = rootPart.Position
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)()

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() task.wait(1); if ESPEnabled then CreateESP(player) end end)
    if ESPEnabled then task.wait(1); CreateESP(player) end
end)
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do if obj and obj.Parent then obj:Destroy() end end
        ESPObjects[player] = nil
    end
end)

-- ========== AIMBOT ==========
function UpdateAimbotFOVCircle()
    if AimbotShowFOV and AimbotEnabled then
        if not AimbotFOVCircle then
            local circle = Instance.new("Frame")
            circle.Name = "AimbotFOV"
            circle.Size = UDim2.new(0, AimbotFOV*2, 0, AimbotFOV*2)
            circle.Position = UDim2.new(0.5, -AimbotFOV, 0.5, -AimbotFOV)
            circle.BackgroundTransparency = 0.9
            circle.BackgroundColor3 = Color3.fromRGB(255,0,0)
            circle.BorderSizePixel = 2
            circle.BorderColor3 = Color3.fromRGB(255,255,255)
            local corner = Instance.new("UICorner", circle)
            corner.CornerRadius = UDim.new(1,0)
            circle.Parent = CoreGui
            AimbotFOVCircle = circle
        else
            AimbotFOVCircle.Size = UDim2.new(0, AimbotFOV*2, 0, AimbotFOV*2)
            AimbotFOVCircle.Position = UDim2.new(0.5, -AimbotFOV, 0.5, -AimbotFOV)
            AimbotFOVCircle.Visible = true
        end
    elseif AimbotFOVCircle then
        AimbotFOVCircle.Visible = false
    end
end

function GetClosestPlayerInFOV()
    local closest, closestDist = nil, AimbotFOV
    local center = Vector2.new(Mouse.X, Mouse.Y)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = player.Character:FindFirstChild(AimbotLockPart)
            if part then
                local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not AimbotEnabled then return end
    local pressed = (AimbotKey.EnumType == Enum.KeyCode and input.KeyCode == AimbotKey) or
                    (AimbotKey.EnumType == Enum.UserInputType and input.UserInputType == AimbotKey)
    if pressed then AimbotTarget = GetClosestPlayerInFOV() end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not AimbotEnabled then return end
    local released = (AimbotKey.EnumType == Enum.KeyCode and input.KeyCode == AimbotKey) or
                     (AimbotKey.EnumType == Enum.UserInputType and input.UserInputType == AimbotKey)
    if released then AimbotTarget = nil end
end)

RunService.RenderStepped:Connect(function()
    if AimbotEnabled and AimbotTarget and AimbotTarget.Character then
        local targetPart = AimbotTarget.Character:FindFirstChild(AimbotLockPart)
        if targetPart and LocalPlayer.Character then
            local newCF = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
            if AimbotSmoothness > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(newCF, AimbotSmoothness)
            else
                Camera.CFrame = newCF
            end
        end
    end
end)

-- ========== BUILD UI TABS ==========
-- Hitbox Tab
local hitboxTab = UI.AddTab("Hitbox Extender")
UI.AddToggle(hitboxTab, "Enable Hitbox", false, function(v) HitboxEnabled = v end)
UI.AddSlider(hitboxTab, "Hitbox Size", 1, 50, 13, " studs", function(v) HitboxSize = v end)
UI.AddSlider(hitboxTab, "Hitbox Transparency", 0, 1, 0.5, "", function(v) HitboxTransparency = v end)
UI.AddColorPicker(hitboxTab, "Hitbox Color", HitboxColor, function(c) HitboxColor = c end)
UI.AddToggle(hitboxTab, "Head Dot (ESP style)", false, function(v) HitboxHeadDot = v end)

-- ESP Tab
local espTab = UI.AddTab("ESP")
UI.AddToggle(espTab, "Enable ESP", false, function(v) ESPEnabled = v; if not v then ClearESP() else UpdateESP() end end)
UI.AddToggle(espTab, "Skeleton", false, function(v) ESPSettings.Skeleton = v; UpdateESP() end)
UI.AddToggle(espTab, "Head Box", false, function(v) ESPSettings.HeadBox = v; UpdateESP() end)
UI.AddToggle(espTab, "Body Box", false, function(v) ESPSettings.BodyBox = v; UpdateESP() end)
UI.AddToggle(espTab, "Name", false, function(v) ESPSettings.Name = v; UpdateESP() end)
UI.AddToggle(espTab, "Health", false, function(v) ESPSettings.Health = v; UpdateESP() end)
UI.AddToggle(espTab, "Distance", false, function(v) ESPSettings.Distance = v; UpdateESP() end)
UI.AddToggle(espTab, "Tracer", false, function(v) ESPSettings.Tracer = v; UpdateESP() end)
UI.AddToggle(espTab, "Head Dot", false, function(v) ESPSettings.HeadDot = v; UpdateESP() end)
UI.AddColorPicker(espTab, "Skeleton Color", ESPColors.Skeleton, function(c) ESPColors.Skeleton = c; UpdateESP() end)
UI.AddColorPicker(espTab, "Head Box Color", ESPColors.HeadBox, function(c) ESPColors.HeadBox = c; UpdateESP() end)
UI.AddColorPicker(espTab, "Body Box Color", ESPColors.BodyBox, function(c) ESPColors.BodyBox = c; UpdateESP() end)
UI.AddColorPicker(espTab, "Tracer Color", ESPColors.Tracer, function(c) ESPColors.Tracer = c; UpdateESP() end)

-- Aimbot Tab
local aimbotTab = UI.AddTab("Aimbot")
UI.AddToggle(aimbotTab, "Enable Aimbot", false, function(v) AimbotEnabled = v; if not v then AimbotTarget = nil end; UpdateAimbotFOVCircle() end)
UI.AddDropdown(aimbotTab, "Aimbot Key", {"Q","E","LeftShift","Tab","RightMouseButton","X","C","F"}, "Q", function(opt)
    local map = {Q=Enum.KeyCode.Q, E=Enum.KeyCode.E, LeftShift=Enum.KeyCode.LeftShift, Tab=Enum.KeyCode.Tab,
                 RightMouseButton=Enum.UserInputType.MouseButton2, X=Enum.KeyCode.X, C=Enum.KeyCode.C, F=Enum.KeyCode.F}
    AimbotKey = map[opt]
end)
UI.AddDropdown(aimbotTab, "Lock Part", {"Head","Torso"}, "Head", function(opt) AimbotLockPart = opt end)
UI.AddSlider(aimbotTab, "FOV Radius", 50, 500, 200, " px", function(v) AimbotFOV = v; UpdateAimbotFOVCircle() end)
UI.AddToggle(aimbotTab, "Show FOV Circle", true, function(v) AimbotShowFOV = v; UpdateAimbotFOVCircle() end)
UI.AddSlider(aimbotTab, "Smoothness", 0, 1, 0.3, "", function(v) AimbotSmoothness = v end)

-- Local Player Tab
local localTab = UI.AddTab("Local Player")
UI.AddSlider(localTab, "Walk Speed", 16, 100, 16, " studs/s", function(v) WalkSpeedValue = v; ApplyLocalStats() end)
UI.AddSlider(localTab, "Jump Power", 7.2, 100, 7.2, "", function(v) JumpPowerValue = v; ApplyLocalStats() end)
UI.AddToggle(localTab, "Fly", false, function(v) FlyEnabled = v; ToggleFly(v) end)
UI.AddSlider(localTab, "Fly Speed", 20, 200, 50, " studs/s", function(v) FlySpeed = v; if FlyEnabled then ToggleFly(true) end end)
UI.AddToggle(localTab, "No Clip", false, function(v)
    NoClipEnabled = v
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, not v) end
    end
end)

-- Initialize
task.wait(1)
ApplyLocalStats()
UpdateESP()
UpdateAimbotFOVCircle()
