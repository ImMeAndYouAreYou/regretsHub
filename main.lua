--[[
    Rayfield Hub Script – Hitbox Extender, ESP, Aimbot, Local Mods
    Fixed: Lighting service typo, Rayfield loader with retry.
--]]

repeat wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")  -- FIXED: was "Lightning"
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- ========== CONFIG FOLDER ==========
local ConfigFolder = "RayfieldHubConfig"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

-- ========== LOAD RAYFIELD (with retry) ==========
local Rayfield = nil
local function LoadRayfield()
    local RayfieldUrl = "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"
    for attempt = 1, 3 do
        local success, content = pcall(game.HttpGet, game, RayfieldUrl)
        if success and content then
            local func, err = loadstring(content)
            if func then
                local ok, result = pcall(func)
                if ok and result then
                    return result
                else
                    warn("Rayfield execution failed: ", err or result)
                end
            else
                warn("Rayfield loadstring failed: ", err)
            end
        else
            warn("Rayfield download attempt ", attempt, " failed: ", content)
        end
        task.wait(1)
    end
    return nil
end

Rayfield = LoadRayfield()

if not Rayfield then
    -- Fallback notification
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Error",
        Text = "Failed to load Rayfield. Check internet or use a different executor.",
        Duration = 5
    })
    return
end

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

-- ========== RAYFIELD UI ==========
local Window = Rayfield:CreateWindow({
    Name = "Custom Script Hub",
    Icon = nil,
    LoadingTitle = "Loading Hub",
    LoadingSubtitle = "by ScriptHub",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = ConfigFolder,
        FileName = "Settings"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Key Required",
        Note = "No key needed",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"nil"}
    }
})

-- Hitbox Tab
local HitboxTab = Window:CreateTab("Hitbox Extender", nil)

HitboxTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Flag = "HitboxEnabled",
    Callback = function(v) HitboxEnabled = v end
})

HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {1, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 13,
    Flag = "HitboxSize",
    Callback = function(v) HitboxSize = v end
})

HitboxTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "HitboxTransparency",
    Callback = function(v) HitboxTransparency = v end
})

HitboxTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = HitboxColor,
    Flag = "HitboxColor",
    Callback = function(c) HitboxColor = c end
})

HitboxTab:CreateToggle({
    Name = "Head Dot (ESP style)",
    CurrentValue = false,
    Flag = "HitboxHeadDot",
    Callback = function(v) HitboxHeadDot = v end
})

-- ESP Tab
local ESPTab = Window:CreateTab("ESP", nil)

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v)
        ESPEnabled = v
        if not v then ClearESP() else UpdateESP() end
    end
})

ESPTab:CreateToggle({
    Name = "Skeleton",
    CurrentValue = false,
    Flag = "ESPSkeleton",
    Callback = function(v) ESPSettings.Skeleton = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Head Box",
    CurrentValue = false,
    Flag = "ESPHeadBox",
    Callback = function(v) ESPSettings.HeadBox = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Body Box",
    CurrentValue = false,
    Flag = "ESPBodyBox",
    Callback = function(v) ESPSettings.BodyBox = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Name",
    CurrentValue = false,
    Flag = "ESPName",
    Callback = function(v) ESPSettings.Name = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Health",
    CurrentValue = false,
    Flag = "ESPHealth",
    Callback = function(v) ESPSettings.Health = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = false,
    Flag = "ESPDistance",
    Callback = function(v) ESPSettings.Distance = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Tracer",
    CurrentValue = false,
    Flag = "ESPTracer",
    Callback = function(v) ESPSettings.Tracer = v; UpdateESP() end
})

ESPTab:CreateToggle({
    Name = "Head Dot",
    CurrentValue = false,
    Flag = "ESPHeadDot",
    Callback = function(v) ESPSettings.HeadDot = v; UpdateESP() end
})

ESPTab:CreateColorPicker({
    Name = "Skeleton Color",
    Color = ESPColors.Skeleton,
    Flag = "SkeletonColor",
    Callback = function(c) ESPColors.Skeleton = c; UpdateESP() end
})

ESPTab:CreateColorPicker({
    Name = "Head Box Color",
    Color = ESPColors.HeadBox,
    Flag = "HeadBoxColor",
    Callback = function(c) ESPColors.HeadBox = c; UpdateESP() end
})

ESPTab:CreateColorPicker({
    Name = "Body Box Color",
    Color = ESPColors.BodyBox,
    Flag = "BodyBoxColor",
    Callback = function(c) ESPColors.BodyBox = c; UpdateESP() end
})

ESPTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = ESPColors.Tracer,
    Flag = "TracerColor",
    Callback = function(c) ESPColors.Tracer = c; UpdateESP() end
})

-- Aimbot Tab
local AimbotTab = Window:CreateTab("Aimbot", nil)

AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(v)
        AimbotEnabled = v
        if not v then AimbotTarget = nil end
        UpdateAimbotFOVCircle()
    end
})

AimbotTab:CreateDropdown({
    Name = "Aimbot Key",
    Options = {"Q", "E", "LeftShift", "Tab", "RightMouseButton", "X", "C", "F"},
    CurrentOption = "Q",
    Flag = "AimbotKey",
    Callback = function(opt)
        local map = {
            Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, LeftShift = Enum.KeyCode.LeftShift,
            Tab = Enum.KeyCode.Tab, RightMouseButton = Enum.UserInputType.MouseButton2,
            X = Enum.KeyCode.X, C = Enum.KeyCode.C, F = Enum.KeyCode.F
        }
        AimbotKey = map[opt]
    end
})

AimbotTab:CreateDropdown({
    Name = "Lock Part",
    Options = {"Head", "Torso"},
    CurrentOption = "Head",
    Flag = "LockPart",
    Callback = function(opt) AimbotLockPart = opt end
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    Suffix = " px",
    CurrentValue = 200,
    Flag = "AimbotFOV",
    Callback = function(v) AimbotFOV = v; UpdateAimbotFOVCircle() end
})

AimbotTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "ShowFOVCircle",
    Callback = function(v) AimbotShowFOV = v; UpdateAimbotFOVCircle() end
})

AimbotTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.3,
    Flag = "AimbotSmoothness",
    Callback = function(v) AimbotSmoothness = v end
})

-- Local Player Tab
local LocalTab = Window:CreateTab("Local Player", nil)

LocalTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v) WalkSpeedValue = v; ApplyLocalStats() end
})

LocalTab:CreateSlider({
    Name = "Jump Power",
    Range = {7.2, 100},
    Increment = 0.5,
    Suffix = "",
    CurrentValue = 7.2,
    Flag = "JumpPower",
    Callback = function(v) JumpPowerValue = v; ApplyLocalStats() end
})

LocalTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        FlyEnabled = v
        ToggleFly(v)
    end
})

LocalTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20, 200},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(v)
        FlySpeed = v
        if FlyEnabled then ToggleFly(true) end
    end
})

LocalTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(v)
        NoClipEnabled = v
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, not v) end
        end
    end
})

-- Initialize
task.wait(1)
ApplyLocalStats()
UpdateESP()
UpdateAimbotFOVCircle()

Rayfield:Notify({
    Title = "Custom Hub",
    Content = "Loaded successfully!",
    Duration = 3
})
