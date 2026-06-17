-- XodinqHUB - Grow a Garden 2 (PREMIUM GUI + ALL FEATURES WORK)
-- PROJECT BY LAN
-- GUI KEREN: Glassmorphism, Gradient, Glow, Animasi

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local AutoWaterEnabled = false
local AutoHarvestEnabled = false
local AutoSellEnabled = false
local AutoBuyEnabled = false
local AntiAFKEnabled = false
local AutoGoldSeedEnabled = false
local AutoRainbowSeedEnabled = false
local MyGardenPosition = nil

task.wait(0.5)
MyGardenPosition = RootPart.Position

-- === RESET MOVEMENT ===
local function resetMovement()
    Humanoid.WalkSpeed = SpeedValue
    Humanoid.JumpPower = JumpValue
    pcall(function()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
    end)
end

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

-- === INSTANT COLLECT ===
local function instantCollect(obj)
    if not obj or not obj.Parent then return false end
    pcall(function()
        RootPart.CFrame = CFrame.new(obj.Position.X, obj.Position.Y + 1.5, obj.Position.Z)
        task.wait(0.01)
    end)
    local prompt = obj:FindFirstChild("ProximityPrompt")
    if prompt then pcall(function() fireproximityprompt(prompt) end) return true end
    local click = obj:FindFirstChild("ClickDetector")
    if click then pcall(function() fireclickdetector(click) end) return true end
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local name = v.Name:lower()
            if name:find("collect") or name:find("pick") or name:find("claim") or name:find("harvest") then
                pcall(function() v:FireServer(obj) end)
                return true
            end
        end
    end
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, "E", false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, "E", false, game)
        end)
        return true
    end
    return false
end

-- === FLING ===
local function flingTarget(targetChar)
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500))
    bv.Parent = targetRoot
    task.wait(0.15)
    bv:Destroy()
end

local function flingPlayer(targetPlayer)
    if targetPlayer == Player then return end
    local targetChar = targetPlayer.Character
    if targetChar then flingTarget(targetChar) end
end

-- === NIGHT DETECTION ===
local function isNightTime()
    local hour = tonumber(Lighting.TimeOfDay:match("^(%d+)")) or 12
    return (hour >= 18 or hour <= 5)
end

-- === FIND OBJECTS ===
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

local function findPlots()
    local plots = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("plot") or obj.Name:lower():find("garden") or obj.Name:lower():find("farm")) then
            table.insert(plots, obj)
        end
    end
    return plots
end

local function findMyPlants()
    local plants = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position then
            local name = obj.Name:lower()
            if name:find("plant") or name:find("growing") or name:find("seedling") or name:find("sprout") then
                local dist = (obj.Position - RootPart.Position).Magnitude
                if dist < 25 then table.insert(plants, obj) end
            end
        end
    end
    return plants
end

-- === DETEKSI GOLD & RAINBOW SEED ===
local function findGoldSeeds()
    local seeds = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("Model")) and obj.Position then
            local name = obj.Name:lower()
            local parent = obj.Parent
            local isSeed = name:find("seed")
            local isGold = name:find("gold") or name:find("midas")
            local isPlant = name:find("plant") or name:find("growing") or name:find("crop")
            local isInGarden = false
            if parent then
                local parentName = parent.Name:lower()
                if parentName:find("plant") or parentName:find("garden") or parentName:find("plot") or parentName:find("farm") then
                    isInGarden = true
                end
            end
            if isSeed and isGold and not isPlant and not isInGarden then
                table.insert(seeds, obj)
            end
        end
    end
    return seeds
end

local function findRainbowSeeds()
    local seeds = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("Model")) and obj.Position then
            local name = obj.Name:lower()
            local parent = obj.Parent
            local isSeed = name:find("seed")
            local isRainbow = name:find("rainbow")
            local isPlant = name:find("plant") or name:find("growing") or name:find("crop")
            local isInGarden = false
            if parent then
                local parentName = parent.Name:lower()
                if parentName:find("plant") or parentName:find("garden") or parentName:find("plot") or parentName:find("farm") then
                    isInGarden = true
                end
            end
            if isSeed and isRainbow and not isPlant and not isInGarden then
                table.insert(seeds, obj)
            end
        end
    end
    return seeds
end

-- === DETEKSI EVENT ===
local function isMidasEventActive()
    local playerGui = Player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, v in ipairs(playerGui:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                local text = v.Text:lower()
                if text:find("midas") or text:find("gold seed spawn") or text:find("golden seed") then
                    return true
                end
            end
        end
    end
    return false
end

local function isRainbowEventActive()
    local playerGui = Player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, v in ipairs(playerGui:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                local text = v.Text:lower()
                if text:find("rainbow event") or text:find("rainbow seed spawn") then
                    return true
                end
            end
        end
    end
    return false
end

-- === DETEKSI OWNER ===
local function isGardenOwned(gardenPos)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position then
            local dist = (obj.Position - gardenPos).Magnitude
            if dist < 30 then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("BillboardGui") then
                        local text = (child.Text or ""):lower()
                        if text:find("owner") or text:find("milik") or text:find("owned by") then
                            return true, nil
                        end
                    end
                end
            end
        end
    end
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                local dist = (otherChar.HumanoidRootPart.Position - gardenPos).Magnitude
                if dist < 20 then
                    return true, otherPlayer
                end
            end
        end
    end
    return false, nil
end

-- === INVENTORY ===
local function getInventory()
    local inventory = Player:FindFirstChild("Inventory")
    if not inventory then
        for _, child in ipairs(Player:GetChildren()) do
            if child.Name:lower():find("inventory") or child.Name:lower():find("backpack") then
                inventory = child
                break
            end
        end
    end
    return inventory
end

local function getSeedsFromInventory()
    local seeds = {}
    local inventory = getInventory()
    if not inventory then return seeds end
    for _, item in ipairs(inventory:GetChildren()) do
        local name = item.Name:lower()
        if name:find("seed") or name:find("benih") then
            local count = 1
            if item:IsA("IntValue") or item:IsA("NumberValue") then
                count = item.Value
            end
            if count > 0 then
                table.insert(seeds, {name = item.Name, count = count, object = item})
            end
        end
    end
    return seeds
end

local function getFruitsFromInventory()
    local fruits = {}
    local inventory = getInventory()
    if not inventory then return fruits end
    local fruitKeywords = {"fruit", "crop", "harvest", "carrot", "tomato", "wheat", "berry", "apple", "corn", 
                          "pumpkin", "melon", "grape", "banana", "mango", "coconut", "dragon", "pepper", "sunflower"}
    for _, item in ipairs(inventory:GetChildren()) do
        local name = item.Name:lower()
        local isFruit = false
        for _, keyword in ipairs(fruitKeywords) do
            if name:find(keyword) and not name:find("seed") then
                isFruit = true
                break
            end
        end
        if isFruit then
            local count = 1
            if item:IsA("IntValue") or item:IsA("NumberValue") then
                count = item.Value
            end
            if count > 0 then
                table.insert(fruits, {name = item.Name, count = count, object = item})
            end
        end
    end
    return fruits
end

-- === AUTO LOOPS ===
coroutine.wrap(function()
    while true do
        task.wait(0.2)
        if AutoStealEnabled and isNightTime() then
            local targets = findFruitsToSteal()
            local validTargets = {}
            for _, fruit in ipairs(targets) do
                local hasOwner = isGardenOwned(fruit.Position)
                if not hasOwner then
                    table.insert(validTargets, fruit)
                end
            end
            if #validTargets > 0 then
                local successCount = 0
                for _, fruit in ipairs(validTargets) do
                    if not AutoStealEnabled then break end
                    for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        if otherPlayer ~= Player then flingPlayer(otherPlayer) end
                    end
                    task.wait(0.02)
                    if AutoStealEnabled then
                        local success = instantCollect(fruit)
                        if success then successCount = successCount + 1 end
                        task.wait(0.02)
                    end
                end
                if AutoStealEnabled and successCount > 0 then
                    teleportToOwnGarden()
                    task.wait(0.1)
                end
            end
        else
            resetMovement()
        end
        task.wait(0.2)
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(0.2)
        if AutoGoldSeedEnabled and isMidasEventActive() then
            local seeds = findGoldSeeds()
            for _, seed in ipairs(seeds) do
                if not AutoGoldSeedEnabled then break end
                instantCollect(seed)
                task.wait(0.03)
            end
        else
            resetMovement()
        end
        task.wait(0.2)
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(0.2)
        if AutoRainbowSeedEnabled and isRainbowEventActive() then
            local seeds = findRainbowSeeds()
            for _, seed in ipairs(seeds) do
                if not AutoRainbowSeedEnabled then break end
                instantCollect(seed)
                task.wait(0.03)
            end
        else
            resetMovement()
        end
        task.wait(0.2)
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(0.2)
        if AutoCollectEnabled then
            local fruits = findMyFruits()
            for _, fruit in ipairs(fruits) do
                if not AutoCollectEnabled then break end
                instantCollect(fruit)
                task.wait(0.02)
            end
        else
            resetMovement()
        end
    end
end)()

local function plantSeed(seedName, plot)
    pcall(function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("plant") or v.Name:lower():find("grow")) then
                v:FireServer(plot, seedName)
                return true
            end
        end
        local click = plot:FindFirstChild("ClickDetector")
        if click then fireclickdetector(click) return true end
    end)
    return false
end

coroutine.wrap(function()
    while true do
        task.wait(0.5)
        if AutoPlantEnabled then
            local seeds = getSeedsFromInventory()
            if #seeds == 0 then task.wait(2) continue end
            local plots = findPlots()
            local emptyPlots = {}
            for _, plot in ipairs(plots) do
                local isOccupied = false
                for _, plant in ipairs(plot:GetDescendants()) do
                    if plant:IsA("BasePart") and (plant.Name:lower():find("plant") or plant.Name:lower():find("growing")) then
                        isOccupied = true
                        break
                    end
                end
                if not isOccupied then table.insert(emptyPlots, plot) end
            end
            table.sort(emptyPlots, function(a, b)
                return (a.Position - RootPart.Position).Magnitude < (b.Position - RootPart.Position).Magnitude
            end)
            for _, seed in ipairs(seeds) do
                if not AutoPlantEnabled then break end
                if #emptyPlots == 0 then break end
                for _, plot in ipairs(emptyPlots) do
                    if not AutoPlantEnabled then break end
                    teleportTo(plot.Position)
                    task.wait(0.05)
                    local success = plantSeed(seed.name, plot)
                    if success then
                        if seed.object:IsA("IntValue") or seed.object:IsA("NumberValue") then
                            seed.object.Value = math.max(0, seed.object.Value - 1)
                        end
                        table.remove(emptyPlots, table.find(emptyPlots, plot))
                        task.wait(0.1)
                        break
                    end
                end
                task.wait(0.05)
            end
        else
            resetMovement()
        end
        task.wait(0.5)
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(2)
        if AutoWaterEnabled then
            local plants = findMyPlants()
            for _, plant in ipairs(plants) do
                if not AutoWaterEnabled then break end
                pcall(function()
                    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and v.Name:lower():find("water") then
                            v:FireServer(plant)
                        end
                    end
                end)
                task.wait(0.05)
            end
        else
            resetMovement()
        end
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(0.3)
        if AutoHarvestEnabled then
            local fruits = findMyFruits()
            for _, fruit in ipairs(fruits) do
                if not AutoHarvestEnabled then break end
                instantCollect(fruit)
                task.wait(0.02)
            end
        else
            resetMovement()
        end
    end
end)()

local function sellAllFruits()
    local fruits = getFruitsFromInventory()
    local totalSold = 0
    for _, fruit in ipairs(fruits) do
        if fruit.count > 0 then
            pcall(function()
                local sold = false
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") and (v.Name:lower():find("sell") or v.Name:lower():find("market") or v.Name:lower():find("shop")) then
                        v:FireServer(fruit.name, fruit.count)
                        sold = true
                        break
                    end
                end
                if not sold then
                    for i = 1, fruit.count do
                        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") and (v.Name:lower():find("sell") or v.Name:lower():find("market")) then
                                v:FireServer(fruit.name, 1)
                                break
                            end
                        end
                        task.wait(0.02)
                    end
                end
                totalSold = totalSold + fruit.count
                if fruit.object:IsA("IntValue") or fruit.object:IsA("NumberValue") then
                    fruit.object.Value = 0
                end
            end)
            task.wait(0.05)
        end
    end
    if totalSold > 0 then
        print("[XodinqHUB] Sold " .. totalSold .. " fruits/items!")
    end
end

coroutine.wrap(function()
    while true do
        task.wait(2)
        if AutoSellEnabled then
            sellAllFruits()
        else
            resetMovement()
        end
        task.wait(2)
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(5)
        if AutoBuyEnabled then
            for _, shop in ipairs(workspace:GetDescendants()) do
                if shop:IsA("Model") and shop.Name:lower():find("shop") then
                    pcall(function()
                        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") and v.Name:lower():find("buy") then
                                v:FireServer("Seed", "Carrot", 1)
                            end
                        end
                    end)
                end
            end
        else
            resetMovement()
        end
    end
end)()

coroutine.wrap(function()
    while true do
        task.wait(60)
        if AntiAFKEnabled then
            pcall(function()
                Humanoid:MoveTo(RootPart.Position + Vector3.new(0, 0, 1))
                task.wait(0.05)
                Humanoid:MoveTo(RootPart.Position + Vector3.new(0, 0, -1))
            end)
        end
    end
end)()

UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    setSpeed(SpeedValue)
    setJump(JumpValue)
    MyGardenPosition = RootPart.Position
    resetMovement()
end)

-- === PREMIUM GUI (GLASSMORPHISM) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XodinqHUB"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame dengan Glassmorphism
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.92, 0, 0.88, 0)
MainFrame.Position = UDim2.new(0.04, 0, 0.06, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 20) c.Parent = MainFrame end)

-- Glass blur effect
local glassBlur = Instance.new("Frame")
glassBlur.Size = UDim2.new(1, 0, 1, 0)
glassBlur.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassBlur.BackgroundTransparency = 0.03
glassBlur.BorderSizePixel = 0
glassBlur.Parent = MainFrame
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 20) c.Parent = glassBlur end)

-- Glowing border
local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Color3.fromRGB(150, 100, 255)
glowStroke.Thickness = 1.5
glowStroke.Transparency = 0.3
glowStroke.Parent = MainFrame

-- Gradient overlay
local gradientOverlay = Instance.new("UIGradient")
gradientOverlay.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 40, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 25, 70))
}
gradientOverlay.Rotation = 45
gradientOverlay.Parent = MainFrame

-- Header Premium
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Color3.fromRGB(45, 35, 90)
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel = 0
Header.Parent = MainFrame
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 20) c.Parent = Header end)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 30, 120))
}
headerGradient.Parent = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 0, 30)
Title.Position = UDim2.new(0, 16, 0, 6)
Title.Text = "⚡ XODINQ HUB"
Title.TextColor3 = Color3.fromRGB(255, 210, 100)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Subtitle with glow
local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -70, 0, 18)
SubTitle.Position = UDim2.new(0, 18, 0, 38)
SubTitle.Text = "PROJECT BY LAN ✦ GROW A GARDEN 2"
SubTitle.TextColor3 = Color3.fromRGB(180, 160, 230)
SubTitle.BackgroundTransparency = 1
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -44, 0, 12)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 80)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = Header
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = CloseBtn end)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
end)

-- Glow Line
local glowLine = Instance.new("Frame")
glowLine.Size = UDim2.new(0.85, 0, 0, 2)
glowLine.Position = UDim2.new(0.075, 0, 0, 58)
glowLine.BackgroundColor3 = Color3.fromRGB(255, 180, 80)
glowLine.BackgroundTransparency = 0.4
glowLine.BorderSizePixel = 0
glowLine.Parent = Header
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = glowLine end)

-- Scrolling Frame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -72)
Scroll.Position = UDim2.new(0, 8, 0, 64)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 200)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 900)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- Card Helper
local function createCard(parent, order, title, icon)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(35, 30, 65)
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = card end)
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(100, 70, 180)
    cardStroke.Thickness = 0.5
    cardStroke.Transparency = 0.6
    cardStroke.Parent = card
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 0, 22)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.Text = icon .. " " .. title
    label.TextColor3 = Color3.fromRGB(220, 210, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card
    return card
end

-- Speed Card
local speedCard = createCard(Scroll, 1, "WALK SPEED (16-400)", "🏃")
local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0.35, 0, 0, 30)
SpeedBox.Position = UDim2.new(0, 8, 0, 26)
SpeedBox.Text = "16"
SpeedBox.TextColor3 = Color3.fromRGB(255, 220, 150)
SpeedBox.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
SpeedBox.Font = Enum.Font.GothamBold
SpeedBox.TextSize = 16
SpeedBox.Parent = speedCard
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = SpeedBox end)

local speedHint = Instance.new("TextLabel")
speedHint.Size = UDim2.new(0.25, 0, 0, 30)
speedHint.Position = UDim2.new(0.4, 5, 0, 26)
speedHint.Text = "MAX 400"
speedHint.TextColor3 = Color3.fromRGB(140, 130, 180)
speedHint.BackgroundTransparency = 1
speedHint.Font = Enum.Font.Gotham
speedHint.TextSize = 11
speedHint.TextXAlignment = Enum.TextXAlignment.Left
speedHint.Parent = speedCard

-- Jump Card
local jumpCard = createCard(Scroll, 2, "JUMP POWER (7.2-200)", "🦘")
local JumpBox = Instance.new("TextBox")
JumpBox.Size = UDim2.new(0.35, 0, 0, 30)
JumpBox.Position = UDim2.new(0, 8, 0, 26)
JumpBox.Text = "50"
JumpBox.TextColor3 = Color3.fromRGB(255, 220, 150)
JumpBox.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
JumpBox.Font = Enum.Font.GothamBold
JumpBox.TextSize = 16
JumpBox.Parent = jumpCard
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = JumpBox end)

local jumpHint = Instance.new("TextLabel")
jumpHint.Size = UDim2.new(0.25, 0, 0, 30)
jumpHint.Position = UDim2.new(0.4, 5, 0, 26)
jumpHint.Text = "MAX 200"
jumpHint.TextColor3 = Color3.fromRGB(140, 130, 180)
jumpHint.BackgroundTransparency = 1
jumpHint.Font = Enum.Font.Gotham
jumpHint.TextSize = 11
jumpHint.TextXAlignment = Enum.TextXAlignment.Left
jumpHint.Parent = jumpCard

-- Toggle Helper
local function createToggle(parent, order, text, icon, baseColor)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = Color3.fromRGB(35, 30, 65)
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = card end)
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(100, 70, 180)
    cardStroke.Thickness = 0.5
    cardStroke.Transparency = 0.6
    cardStroke.Parent = card
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.Position = UDim2.new(0, 6, 0, 5)
    btn.Text = icon .. " " .. text .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(240, 235, 255)
    btn.BackgroundColor3 = baseColor or Color3.fromRGB(55, 45, 85)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = card
    pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn end)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(75, 60, 120)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = baseColor or Color3.fromRGB(55, 45, 85)}):Play()
    end)
    
    return btn
end

-- Toggles
local infBtn = createToggle(Scroll, 3, "INFINITE JUMP", "🌀", Color3.fromRGB(55, 40, 90))
local stealBtn = createToggle(Scroll, 4, "AUTO STEAL (SKIP OWNER)", "🌙", Color3.fromRGB(90, 45, 80))
local collectBtn = createToggle(Scroll, 5, "AUTO COLLECT", "🧺", Color3.fromRGB(55, 45, 75))
local plantBtn = createToggle(Scroll, 6, "AUTO PLANT (SMART)", "🌱", Color3.fromRGB(55, 40, 90))
local waterBtn = createToggle(Scroll, 7, "AUTO WATER", "💧", Color3.fromRGB(40, 70, 120))
local harvestBtn = createToggle(Scroll, 8, "AUTO HARVEST", "🌾", Color3.fromRGB(80, 120, 60))
local sellBtn = createToggle(Scroll, 9, "AUTO SELL ALL", "💰", Color3.fromRGB(55, 45, 75))
local buyBtn = createToggle(Scroll, 10, "AUTO BUY", "🛒", Color3.fromRGB(70, 50, 100))
local afkBtn = createToggle(Scroll, 11, "ANTI AFK", "🛡️", Color3.fromRGB(60, 60, 100))
local goldBtn = createToggle(Scroll, 12, "GOLD SEED (EVENT)", "✨", Color3.fromRGB(200, 170, 50))
local rainbowBtn = createToggle(Scroll, 13, "RAINBOW SEED (EVENT)", "🌈", Color3.fromRGB(255, 100, 200))

-- Info Panel
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 90)
infoCard.BackgroundColor3 = Color3.fromRGB(35, 30, 65)
infoCard.BackgroundTransparency = 0.4
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 14
infoCard.Parent = Scroll
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = infoCard end)

local infoStroke = Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(100, 70, 180)
infoStroke.Thickness = 0.5
infoStroke.Transparency = 0.6
infoStroke.Parent = infoCard

local nightLabel = Instance.new("TextLabel")
nightLabel.Size = UDim2.new(1, -12, 0, 20)
nightLabel.Position = UDim2.new(0, 8, 0, 4)
nightLabel.Text = "🌞 Day Time — Stealing Not Available"
nightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
nightLabel.BackgroundTransparency = 1
nightLabel.Font = Enum.Font.GothamBold
nightLabel.TextSize = 11
nightLabel.TextXAlignment = Enum.TextXAlignment.Left
nightLabel.Parent = infoCard

local statusLabel1 = Instance.new("TextLabel")
statusLabel1.Size = UDim2.new(1, -12, 0, 18)
statusLabel1.Position = UDim2.new(0, 8, 0, 26)
statusLabel1.Text = "✅ Auto Steal: Skip garden with 'owner' text"
statusLabel1.TextColor3 = Color3.fromRGB(180, 220, 180)
statusLabel1.BackgroundTransparency = 1
statusLabel1.Font = Enum.Font.Gotham
statusLabel1.TextSize = 10
statusLabel1.TextXAlignment = Enum.TextXAlignment.Left
statusLabel1.Parent = infoCard

local statusLabel2 = Instance.new("TextLabel")
statusLabel2.Size = UDim2.new(1, -12, 0, 18)
statusLabel2.Position = UDim2.new(0, 8, 0, 46)
statusLabel2.Text = "✨ Gold & Rainbow: Hanya ambil SEED EVENT (bukan tanaman)"
statusLabel2.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel2.BackgroundTransparency = 1
statusLabel2.Font = Enum.Font.Gotham
statusLabel2.TextSize = 10
statusLabel2.TextXAlignment = Enum.TextXAlignment.Left
statusLabel2.Parent = infoCard

local statusLabel3 = Instance.new("TextLabel")
statusLabel3.Size = UDim2.new(1, -12, 0, 18)
statusLabel3.Position = UDim2.new(0, 8, 0, 66)
statusLabel3.Text = "⚡ OFF = stop + normal movement"
statusLabel3.TextColor3 = Color3.fromRGB(180, 160, 220)
statusLabel3.BackgroundTransparency = 1
statusLabel3.Font = Enum.Font.Gotham
statusLabel3.TextSize = 10
statusLabel3.TextXAlignment = Enum.TextXAlignment.Left
statusLabel3.Parent = infoCard

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 30)
footer.LayoutOrder = 15
footer.Text = "💎 Drag header to move | ✕ to close"
footer.TextColor3 = Color3.fromRGB(120, 110, 165)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.Gotham
footer.TextSize = 9
footer.Parent = Scroll

-- Floating Button
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 50, 0, 50)
FloatBtn.Position = UDim2.new(1, -60, 0, 20)
FloatBtn.Text = "⚡"
FloatBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
FloatBtn.TextSize = 28
FloatBtn.BackgroundColor3 = Color3.fromRGB(60, 45, 110)
FloatBtn.BackgroundTransparency = 0.15
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.Visible = false
FloatBtn.Parent = ScreenGui
pcall(function() local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = FloatBtn end)

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(255, 200, 100)
floatStroke.Thickness = 1.5
floatStroke.Transparency = 0.5
floatStroke.Parent = FloatBtn

-- Glow pulse animation untuk FloatBtn
coroutine.wrap(function()
    while true do
        task.wait(0.5)
        if FloatBtn.Visible then
            TweenService:Create(floatStroke, TweenInfo.new(0.8), {Transparency = 0.2}):Play()
            task.wait(0.8)
            TweenService:Create(floatStroke, TweenInfo.new(0.8), {Transparency = 0.6}):Play()
        end
    end
end)()

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
    FloatBtn:TweenSize(UDim2.new(0, 55, 0, 55), "Out", "Quad", 0.3)
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatBtn.Visible = false
end)

-- Night Status Update
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

infBtn.MouseButton1Click:Connect(function()
    InfJumpEnabled = not InfJumpEnabled
    infBtn.Text = "🌀 INFINITE JUMP: " .. (InfJumpEnabled and "ON ✓" or "OFF")
    infBtn.BackgroundColor3 = InfJumpEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 40, 90)
end)

stealBtn.MouseButton1Click:Connect(function()
    AutoStealEnabled = not AutoStealEnabled
    stealBtn.Text = "🌙 AUTO STEAL: " .. (AutoStealEnabled and "ON ✓" or "OFF")
    stealBtn.BackgroundColor3 = AutoStealEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(90, 45, 80)
    if not AutoStealEnabled then
        resetMovement()
        teleportToOwnGarden()
    end
end)

collectBtn.MouseButton1Click:Connect(function()
    AutoCollectEnabled = not AutoCollectEnabled
    collectBtn.Text = "🧺 AUTO COLLECT: " .. (AutoCollectEnabled and "ON ✓" or "OFF")
    collectBtn.BackgroundColor3 = AutoCollectEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 45, 75)
    if not AutoCollectEnabled then resetMovement() end
end)

plantBtn.MouseButton1Click:Connect(function()
    AutoPlantEnabled = not AutoPlantEnabled
    plantBtn.Text = "🌱 AUTO PLANT: " .. (AutoPlantEnabled and "ON ✓" or "OFF")
    plantBtn.BackgroundColor3 = AutoPlantEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 40, 90)
    if not AutoPlantEnabled then resetMovement() end
end)

waterBtn.MouseButton1Click:Connect(function()
    AutoWaterEnabled = not AutoWaterEnabled
    waterBtn.Text = "💧 AUTO WATER: " .. (AutoWaterEnabled and "ON ✓" or "OFF")
    waterBtn.BackgroundColor3 = AutoWaterEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(40, 70, 120)
    if not AutoWaterEnabled then resetMovement() end
end)

harvestBtn.MouseButton1Click:Connect(function()
    AutoHarvestEnabled = not AutoHarvestEnabled
    harvestBtn.Text = "🌾 AUTO HARVEST: " .. (AutoHarvestEnabled and "ON ✓" or "OFF")
    harvestBtn.BackgroundColor3 = AutoHarvestEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(80, 120, 60)
    if not AutoHarvestEnabled then resetMovement() end
end)

sellBtn.MouseButton1Click:Connect(function()
    AutoSellEnabled = not AutoSellEnabled
    sellBtn.Text = "💰 AUTO SELL ALL: " .. (AutoSellEnabled and "ON ✓" or "OFF")
    sellBtn.BackgroundColor3 = AutoSellEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(55, 45, 75)
    if not AutoSellEnabled then resetMovement() end
end)

buyBtn.MouseButton1Click:Connect(function()
    AutoBuyEnabled = not AutoBuyEnabled
    buyBtn.Text = "🛒 AUTO BUY: " .. (AutoBuyEnabled and "ON ✓" or "OFF")
    buyBtn.BackgroundColor3 = AutoBuyEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(70, 50, 100)
    if not AutoBuyEnabled then resetMovement() end
end)

afkBtn.MouseButton1Click:Connect(function()
    AntiAFKEnabled = not AntiAFKEnabled
    afkBtn.Text = "🛡️ ANTI AFK: " .. (AntiAFKEnabled and "ON ✓" or "OFF")
    afkBtn.BackgroundColor3 = AntiAFKEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(60, 60, 100)
end)

goldBtn.MouseButton1Click:Connect(function()
    AutoGoldSeedEnabled = not AutoGoldSeedEnabled
    goldBtn.Text = "✨ GOLD SEED: " .. (AutoGoldSeedEnabled and "ON ✓" or "OFF")
    goldBtn.BackgroundColor3 = AutoGoldSeedEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(200, 170, 50)
    if not AutoGoldSeedEnabled then resetMovement() end
end)

rainbowBtn.MouseButton1Click:Connect(function()
    AutoRainbowSeedEnabled = not AutoRainbowSeedEnabled
    rainbowBtn.Text = "🌈 RAINBOW SEED: " .. (AutoRainbowSeedEnabled and "ON ✓" or "OFF")
    rainbowBtn.BackgroundColor3 = AutoRainbowSeedEnabled and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(255, 100, 200)
    if not AutoRainbowSeedEnabled then resetMovement() end
end)

print("✅ XodinqHUB | PROJECT BY LAN | PREMIUM GUI")
print("✅ Auto Steal: Skip garden with 'owner' text")
print("✅ Auto Gold & Rainbow: AMBIL SEED EVENT (bukan tanaman)")
print("✅ OFF = stop + normal movement")
