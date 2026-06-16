-- XodinqHUB - Grow a Garden 2 (FULL FIXED)
-- PROJECT BY LAN
-- Auto Steal: Matiin beneran berhenti | Floating button di kanan atas | GUI lebih bagus | Auto return after steal

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- === SETTINGS ===
local SpeedValue = 16
local JumpValue = 50
local InfJumpEnabled = false
local AutoStealEnabled = false
local AutoCollectEnabled = false
local AutoPlantEnabled = false
local AutoSellEnabled = false
local isStealingActive = false
local MyGardenPosition = nil

task.wait(0.5)
MyGardenPosition = RootPart.Position

-- === CORE FUNCTIONS ===
local function setSpeed(s)
    SpeedValue = math.clamp(s, 16, 400)
    Humanoid.WalkSpeed = SpeedValue
end

local function setJump(j)
    JumpValue = math.clamp(j, 7.2, 200)
    Humanoid.JumpPower = JumpValue
end

local function teleportTo(pos)
    pcall(function() RootPart.CFrame = CFrame.new(pos.X, pos.Y + 1.5, pos.Z) end)
end

local function teleportToOwnGarden()
    if MyGardenPosition then
        pcall(function()
            RootPart.CFrame = CFrame.new(MyGardenPosition.X, MyGardenPosition.Y + 2, MyGardenPosition.Z)
        end)
    end
end

local function collectObject(obj)
    if not obj or not obj.Parent then return end
    pcall(function() RootPart.CFrame = CFrame.new(obj.Position.X, obj.Position.Y + 1.5, obj.Position.Z) end)
    task.wait(0.05)
    local click = obj:FindFirstChild("ClickDetector")
    if click then pcall(function() fireclickdetector(click) end) return end
    local prompt = obj:FindFirstChild("ProximityPrompt")
    if prompt then pcall(function() fireproximityprompt(prompt) end) return end
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local name = v.Name:lower()
            if name:find("collect") or name:find("pick") or name:find("claim") or name:find("harvest") then
                pcall(function() v:FireServer(obj) end)
            end
        end
    end
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, "E", false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, "E", false, game)
        end)
    end
end

local function flingTarget(targetChar)
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500))
    bv.Parent = targetRoot
    task.wait(0.25)
    bv:Destroy()
end

local function flingPlayer(targetPlayer)
    if targetPlayer == Player then return end
    local targetChar = targetPlayer.Character
    if targetChar then flingTarget(targetChar) end
end

local function isNightTime()
    local hour = tonumber(Lighting.TimeOfDay:match("^(%d+)")) or 12
    return (hour >= 18 or hour <= 5)
end

local function findFruitsToSteal()
    local fruits = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position then
            local name = obj.Name:lower()
            if name:find("fruit") or name:find("crop") or name:find("harvest") or name:find("ready") then
                local dist = (obj.Position - RootPart.Position).Magnitude
                if dist > 25 then table.insert(fruits, obj) end
            end
        end
    end
    return fruits
end

local function findMyFruits()
    local fruits = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position then
            local name = obj.Name:lower()
            if name:find("fruit") or name:find("crop") or name:find("harvest") or name:find("ready") then
                local dist = (obj.Position - RootPart.Position).Magnitude
                if dist < 25 then table.insert(fruits, obj) end
            end
        end
    end
    return fruits
end

-- === AUTO STEAL LOOP (FIXED - BERHENTI PAS DIMATIIN) ===
local stealCoroutine = nil

local function startStealLoop()
    if stealCoroutine then return end
    stealCoroutine = coroutine.wrap(function()
        while AutoStealEnabled do
            if isNightTime() then
                if not isStealingActive then
                    isStealingActive = true
                end
                local targets = findFruitsToSteal()
                if #targets > 0 then
                    for _, fruit in ipairs(targets) do
                        if not AutoStealEnabled then break end
                        for _, otherPlayer in ipairs(Players:GetPlayers()) do
                            if otherPlayer ~= Player then flingPlayer(otherPlayer) end
                        end
                        task.wait(0.2)
                        if AutoStealEnabled then
                            collectObject(fruit)
                            task.wait(0.08)
                        end
                    end
                    -- BALIK KE GARDEN SENDIRI SETELAH AMBIL BUAH
                    if AutoStealEnabled then
                        teleportToOwnGarden()
                        task.wait(0.3)
                    end
                end
            else
                if isStealingActive then
                    isStealingActive = false
                end
            end
            task.wait(1)
        end
        -- KELUAR DARI LOOP, RESET STATUS
        isStealingActive = false
        stealCoroutine = nil
        print("[XodinqHUB] Auto Steal fully stopped")
    end)
    stealCoroutine()
end

-- === AUTO COLLECT LOOP ===
coroutine.wrap(function()
    while true do
        task.wait(0.5)
        if AutoCollectEnabled then
            local fruits = findMyFruits()
            for _, fruit in ipairs(fruits) do
                collectObject(fruit)
                task.wait(0.08)
            end
        end
    end
end)()

-- === INFINITE JUMP ===
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- === RESPAWN ===
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    setSpeed(SpeedValue)
    setJump(JumpValue)
    MyGardenPosition = RootPart.Position
end)

-- === PREMIUM GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XodinqHUB"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.85, 0, 0.8, 0)
MainFrame.Position = UDim2.new(0.075, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 35)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 16) c.Parent = MainFrame end)

-- Glass effect
local glass = Instance.new("Frame")
glass.Size = UDim2.new(1, 0, 1, 0)
glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glass.BackgroundTransparency = 0.03
glass.BorderSizePixel = 0
glass.Parent = MainFrame
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 16) c.Parent = glass end)

-- Border glow
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(150, 100, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = MainFrame

-- Header dengan gradient
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Color3.fromRGB(45, 35, 90)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 16) c.Parent = Header end)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 40, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 25, 80))
}
headerGradient.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 30)
Title.Position = UDim2.new(0, 14, 0, 4)
Title.Text = "⚡ XODINQ HUB"
Title.TextColor3 = Color3.fromRGB(255, 200, 100)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -60, 0, 18)
SubTitle.Position = UDim2.new(0, 16, 0, 34)
SubTitle.Text = "PROJECT BY LAN | GROW A GARDEN 2"
SubTitle.TextColor3 = Color3.fromRGB(170, 150, 210)
SubTitle.BackgroundTransparency = 1
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 70)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = Header
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = CloseBtn end)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
end)

-- Glow line under header
local glowLine = Instance.new("Frame")
glowLine.Size = UDim2.new(0.8, 0, 0, 2)
glowLine.Position = UDim2.new(0.1, 0, 0, 54)
glowLine.BackgroundColor3 = Color3.fromRGB(255, 180, 80)
glowLine.BackgroundTransparency = 0.3
glowLine.BorderSizePixel = 0
glowLine.Parent = Header
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = glowLine end)

-- Scrolling Frame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -12, 1, -63)
Scroll.Position = UDim2.new(0, 6, 0, 60)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 200)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 520)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- Card helper
local function createCard(parent, order, title, icon)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 65)
    card.BackgroundColor3 = Color3.fromRGB(30, 26, 55)
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = card end)
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(80, 60, 140)
    cardStroke.Thickness = 0.5
    cardStroke.Transparency = 0.6
    cardStroke.Parent = card
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 0, 22)
    label.Position = UDim2.new(0, 8, 0, 5)
    label.Text = icon .. " " .. title
    label.TextColor3 = Color3.fromRGB(220, 210, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card
    return card
end

-- Speed
local speedCard = createCard(Scroll, 1, "WALK SPEED (16-400)", "🏃")
local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0.35, 0, 0, 32)
SpeedBox.Position = UDim2.new(0, 8, 0, 28)
SpeedBox.Text = "16"
SpeedBox.TextColor3 = Color3.fromRGB(255, 220, 150)
SpeedBox.BackgroundColor3 = Color3.fromRGB(22, 20, 45)
SpeedBox.Font = Enum.Font.GothamBold
SpeedBox.TextSize = 16
SpeedBox.Parent = speedCard
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = SpeedBox end)

local speedHint = Instance.new("TextLabel")
speedHint.Size = UDim2.new(0.25, 0, 0, 32)
speedHint.Position = UDim2.new(0.4, 5, 0, 28)
speedHint.Text = "MAX 400"
speedHint.TextColor3 = Color3.fromRGB(140, 130, 180)
speedHint.BackgroundTransparency = 1
speedHint.Font = Enum.Font.Gotham
speedHint.TextSize = 11
speedHint.TextXAlignment = Enum.TextXAlignment.Left
speedHint.Parent = speedCard

-- Jump
local jumpCard = createCard(Scroll, 2, "JUMP POWER (7.2-200)", "🦘")
local JumpBox = Instance.new("TextBox")
JumpBox.Size = UDim2.new(0.35, 0, 0, 32)
JumpBox.Position = UDim2.new(0, 8, 0, 28)
JumpBox.Text = "50"
JumpBox.TextColor3 = Color3.fromRGB(255, 220, 150)
JumpBox.BackgroundColor3 = Color3.fromRGB(22, 20, 45)
JumpBox.Font = Enum.Font.GothamBold
JumpBox.TextSize = 16
JumpBox.Parent = jumpCard
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = JumpBox end)

local jumpHint = Instance.new("TextLabel")
jumpHint.Size = UDim2.new(0.25, 0, 0, 32)
jumpHint.Position = UDim2.new(0.4, 5, 0, 28)
jumpHint.Text = "MAX 200"
jumpHint.TextColor3 = Color3.fromRGB(140, 130, 180)
jumpHint.BackgroundTransparency = 1
jumpHint.Font = Enum.Font.Gotham
jumpHint.TextSize = 11
jumpHint.TextXAlignment = Enum.TextXAlignment.Left
jumpHint.Parent = jumpCard

-- Toggle helper
local function createToggle(parent, order, text, icon, baseColor)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 45)
    card.BackgroundColor3 = Color3.fromRGB(30, 26, 55)
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = card end)
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(80, 60, 140)
    cardStroke.Thickness = 0.5
    cardStroke.Transparency = 0.6
    cardStroke.Parent = card
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 35)
    btn.Position = UDim2.new(0, 6, 0, 5)
    btn.Text = icon .. " " .. text .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(240, 235, 255)
    btn.BackgroundColor3 = baseColor or Color3.fromRGB(55, 45, 85)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = card
    pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn end)
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 55, 110)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = baseColor or Color3.fromRGB(55, 45, 85)}):Play()
    end)
    
    return btn
end

local TweenService = game:GetService("TweenService")

local infBtn = createToggle(Scroll, 3, "INFINITE JUMP", "🌀", Color3.fromRGB(55, 40, 90))
local stealBtn = createToggle(Scroll, 4, "AUTO STEAL (NIGHT)", "🌙", Color3.fromRGB(90, 45, 80))
local collectBtn = createToggle(Scroll, 5, "AUTO COLLECT", "🧺", Color3.fromRGB(55, 45, 75))
local plantBtn = createToggle(Scroll, 6, "AUTO PLANT", "🌱", Color3.fromRGB(55, 40, 90))
local sellBtn = createToggle(Scroll, 7, "AUTO SELL", "💰", Color3.fromRGB(55, 45, 75))

-- Info Card
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 55)
infoCard.BackgroundColor3 = Color3.fromRGB(30, 26, 55)
infoCard.BackgroundTransparency = 0.4
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 8
infoCard.Parent = Scroll
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = infoCard end)

local nightLabel = Instance.new("TextLabel")
nightLabel.Size = UDim2.new(1, -12, 0, 22)
nightLabel.Position = UDim2.new(0, 8, 0, 4)
nightLabel.Text = "🌞 Day Time — Stealing Not Available"
nightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
nightLabel.BackgroundTransparency = 1
nightLabel.Font = Enum.Font.GothamBold
nightLabel.TextSize = 11
nightLabel.TextXAlignment = Enum.TextXAlignment.Left
nightLabel.Parent = infoCard

local eventLabel = Instance.new("TextLabel")
eventLabel.Size = UDim2.new(1, -12, 0, 22)
eventLabel.Position = UDim2.new(0, 8, 0, 28)
eventLabel.Text = "⏳ No Active Event — Waiting"
eventLabel.TextColor3 = Color3.fromRGB(200, 180, 250)
eventLabel.BackgroundTransparency = 1
eventLabel.Font = Enum.Font.Gotham
eventLabel.TextSize = 10
eventLabel.TextXAlignment = Enum.TextXAlignment.Left
eventLabel.Parent = infoCard

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 28)
footer.LayoutOrder = 9
footer.Text = "💎 Drag header | ✕ Close | Auto return to garden after steal"
footer.TextColor3 = Color3.fromRGB(120, 110, 165)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.Gotham
footer.TextSize = 9
footer.Parent = Scroll

-- === FLOATING BUTTON (POJOK KANAN ATAS) ===
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 48, 0, 48)
FloatBtn.Position = UDim2.new(1, -58, 0, 15)
FloatBtn.Text = "⚡"
FloatBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
FloatBtn.TextSize = 26
FloatBtn.BackgroundColor3 = Color3.fromRGB(60, 45, 110)
FloatBtn.BackgroundTransparency = 0.15
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.Visible = false
FloatBtn.Parent = ScreenGui
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = FloatBtn end)

-- Float button glow border
local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(255, 200, 100)
floatStroke.Thickness = 1.5
floatStroke.Transparency = 0.5
floatStroke.Parent = FloatBtn

-- Drag System
local dragActive = false
local dragStart, frameStart

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = true
        dragStart = input.Position
        frameStart = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = false
    end
end)

-- Close & Open
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatBtn.Visible = true
    -- Animasi muncul
    FloatBtn:TweenSize(UDim2.new(0, 55, 0, 55), "Out", "Quad", 0.3)
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatBtn.Visible = false
end)

-- Status Updates
coroutine.wrap(function()
    while true do
        task.wait(0.5)
        if isNightTime() then
            nightLabel.Text = "🌙 NIGHT TIME — Stealing Available"
            nightLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        else
            nightLabel.Text = "🌞 DAY TIME — Stealing Not Available"
            nightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
end)()

-- Initialize
setSpeed(16)
setJump(50)

SpeedBox.FocusLost:Connect(function() setSpeed(tonumber(SpeedBox.Text) or 16) end)
JumpBox.FocusLost:Connect(function() setJump(tonumber(JumpBox.Text) or 50) end)

-- Toggle Connections
infBtn.MouseButton1Click:Connect(function()
    InfJumpEnabled = not InfJumpEnabled
    infBtn.Text = "🌀 INFINITE JUMP: " .. (InfJumpEnabled and "ON ✓" or "OFF")
    infBtn.BackgroundColor3 = InfJumpEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 40, 90)
end)

stealBtn.MouseButton1Click:Connect(function()
    AutoStealEnabled = not AutoStealEnabled
    stealBtn.Text = "🌙 AUTO STEAL (NIGHT): " .. (AutoStealEnabled and "ON ✓" or "OFF")
    stealBtn.BackgroundColor3 = AutoStealEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(90, 45, 80)
    
    if AutoStealEnabled then
        startStealLoop()
        print("[XodinqHUB] Auto Steal STARTED")
    else
        if stealCoroutine then
            stealCoroutine = nil -- Hentikan loop
            print("[XodinqHUB] Auto Steal STOPPED")
        end
        isStealingActive = false
        -- Teleport balik ke garden sendiri
        teleportToOwnGarden()
    end
end)

collectBtn.MouseButton1Click:Connect(function()
    AutoCollectEnabled = not AutoCollectEnabled
    collectBtn.Text = "🧺 AUTO COLLECT: " .. (AutoCollectEnabled and "ON ✓" or "OFF")
    collectBtn.BackgroundColor3 = AutoCollectEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 45, 75)
end)

plantBtn.MouseButton1Click:Connect(function()
    AutoPlantEnabled = not AutoPlantEnabled
    plantBtn.Text = "🌱 AUTO PLANT: " .. (AutoPlantEnabled and "ON ✓" or "OFF")
    plantBtn.BackgroundColor3 = AutoPlantEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 40, 90)
end)

sellBtn.MouseButton1Click:Connect(function()
    AutoSellEnabled = not AutoSellEnabled
    sellBtn.Text = "💰 AUTO SELL: " .. (AutoSellEnabled and "ON ✓" or "OFF")
    sellBtn.BackgroundColor3 = AutoSellEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 45, 75)
end)

print("✅ XodinqHUB | PROJECT BY LAN | LOADED")
print("✅ Auto Steal: Matiin = langsung berhenti + teleport balik")
print("✅ Floating button di pojok kanan atas")
