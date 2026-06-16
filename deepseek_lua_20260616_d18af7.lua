-- XodinqHUB - Grow a Garden 2 (EVENT SEED COLLECTOR - GOLD & RAINBOW)
-- PROJECT BY LAN
-- Auto Collect Gold Seed (Midas Event) & Rainbow Seed (Rainbow Event)
-- Deteksi notifikasi "Gold Seed Spawn" / "Rainbow Seed Spawn", teleport & instant collect

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

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

-- === INSTANT COLLECT (0.02 DETIK) ===
local function instantCollect(obj)
    if not obj or not obj.Parent then return end
    pcall(function()
        RootPart.CFrame = CFrame.new(obj.Position.X, obj.Position.Y + 1.5, obj.Position.Z)
        task.wait(0.02)
    end)

    -- Method 1: ProximityPrompt (prioritas utama untuk seed yang jatuh dari langit)
    local prompt = obj:FindFirstChild("ProximityPrompt")
    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
            -- Jika ada prompt, biasanya langsung collect tanpa perlu E
            return
        end)
    end

    -- Method 2: ClickDetector (fallback)
    local click = obj:FindFirstChild("ClickDetector")
    if click then
        pcall(function() fireclickdetector(click) end)
        return
    end

    -- Method 3: RemoteEvent
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local name = v.Name:lower()
            if name:find("collect") or name:find("pick") or name:find("claim") then
                pcall(function() v:FireServer(obj) end)
            end
        end
    end

    -- Method 4: Simulate E key (fallback terakhir)
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, "E", false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, "E", false, game)
        end)
    end
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
    task.wait(0.25)
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

-- === DETEKSI GOLD & RAINBOW SEED (YANG JATUH DARI LANGIT) ===
-- Berdasarkan hasil search:
-- Gold Seed: muncul saat Midas Event, jatuh dari langit, ada notifikasi "Gold Seed Spawn" [citation:2][citation:4][citation:7]
-- Rainbow Seed: muncul saat Rainbow Event, jatuh dari langit, ada notifikasi "Rainbow Seed Spawn" [citation:1][citation:4][citation:6]
-- Kedua event durasi 2 menit [citation:5][citation:7][citation:9]

local function findGoldSeeds()
    local seeds = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position then
            local name = obj.Name:lower()
            -- Deteksi seed yang jatuh dari langit (bukan tanaman)
            if (name:find("gold") or name:find("midas")) and not name:find("plant") and not name:find("garden") then
                -- Cek posisi: seed biasanya di tanah (Y rendah) dan bukan di dalam garden
                local dist = (obj.Position - RootPart.Position).Magnitude
                if dist > 5 then -- Skip yang terlalu dekat (mungkin milik sendiri)
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

local function findRainbowSeeds()
    local seeds = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position then
            local name = obj.Name:lower()
            if (name:find("rainbow") or name:find("spectrum")) and not name:find("plant") and not name:find("garden") then
                local dist = (obj.Position - RootPart.Position).Magnitude
                if dist > 5 then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

-- === DETEKSI EVENT DARI NOTIFIKASI ===
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
    -- Cek juga dari Lighting (moon jadi emas saat Midas event) [citation:2][citation:4]
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

-- === AUTO GOLD SEED LOOP (DETEKSI NOTIFIKASI + INSTANT COLLECT) ===
coroutine.wrap(function()
    while true do
        task.wait(0.2)
        if AutoGoldSeedEnabled then
            -- Cek apakah Midas Event aktif (dari notifikasi)
            if isMidasEventActive() then
                local seeds = findGoldSeeds()
                for _, seed in ipairs(seeds) do
                    if not AutoGoldSeedEnabled then break end
                    -- Teleport langsung ke posisi seed dan collect
                    instantCollect(seed)
                    task.wait(0.03)
                end
            else
                -- Tetap scan seed yang mungkin terlewat
                local seeds = findGoldSeeds()
                for _, seed in ipairs(seeds) do
                    if not AutoGoldSeedEnabled then break end
                    instantCollect(seed)
                    task.wait(0.03)
                end
            end
        else
            resetMovement()
        end
        task.wait(0.2)
    end
end)()

-- === AUTO RAINBOW SEED LOOP (DETEKSI NOTIFIKASI + INSTANT COLLECT) ===
coroutine.wrap(function()
    while true do
        task.wait(0.2)
        if AutoRainbowSeedEnabled then
            if isRainbowEventActive() then
                local seeds = findRainbowSeeds()
                for _, seed in ipairs(seeds) do
                    if not AutoRainbowSeedEnabled then break end
                    instantCollect(seed)
                    task.wait(0.03)
                end
            else
                local seeds = findRainbowSeeds()
                for _, seed in ipairs(seeds) do
                    if not AutoRainbowSeedEnabled then break end
                    instantCollect(seed)
                    task.wait(0.03)
                end
            end
        else
            resetMovement()
        end
        task.wait(0.2)
    end
end)()

-- === AUTO STEAL LOOP (SKIP OWNER + INSTANT COLLECT) ===
local function isGardenOwned(gardenPos)
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

coroutine.wrap(function()
    while true do
        task.wait(0.3)
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
                for _, fruit in ipairs(validTargets) do
                    if not AutoStealEnabled then break end
                    for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        if otherPlayer ~= Player then flingPlayer(otherPlayer) end
                    end
                    task.wait(0.05)
                    if AutoStealEnabled then
                        instantCollect(fruit)
                        task.wait(0.03)
                    end
                end
                if AutoStealEnabled then
                    teleportToOwnGarden()
                    task.wait(0.2)
                end
            end
        else
            resetMovement()
        end
        task.wait(0.3)
    end
end)()

-- === AUTO COLLECT LOOP ===
coroutine.wrap(function()
    while true do
        task.wait(0.3)
        if AutoCollectEnabled then
            local fruits = findMyFruits()
            for _, fruit in ipairs(fruits) do
                if not AutoCollectEnabled then break end
                instantCollect(fruit)
                task.wait(0.05)
            end
        else
            resetMovement()
        end
    end
end)()

-- === AUTO PLANT LOOP ===
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
                    task.wait(0.1)
                    local success = plantSeed(seed.name, plot)
                    if success then
                        if seed.object:IsA("IntValue") or seed.object:IsA("NumberValue") then
                            seed.object.Value = math.max(0, seed.object.Value - 1)
                        end
                        table.remove(emptyPlots, table.find(emptyPlots, plot))
                        task.wait(0.15)
                        break
                    end
                end
                task.wait(0.1)
            end
        else
            resetMovement()
        end
        task.wait(0.5)
    end
end)()

-- === AUTO WATER LOOP ===
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
                task.wait(0.1)
            end
        else
            resetMovement()
        end
    end
end)()

-- === AUTO HARVEST LOOP ===
coroutine.wrap(function()
    while true do
        task.wait(0.5)
        if AutoHarvestEnabled then
            local fruits = findMyFruits()
            for _, fruit in ipairs(fruits) do
                if not AutoHarvestEnabled then break end
                instantCollect(fruit)
                task.wait(0.05)
            end
        else
            resetMovement()
        end
    end
end)()

-- === AUTO SELL ALL INVENTORY ===
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
                table.insert(fruits, {
                    name = item.Name,
                    count = count,
                    object = item
                })
            end
        end
    end
    return fruits
end

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
                        task.wait(0.05)
                    end
                end
                totalSold = totalSold + fruit.count
                if fruit.object:IsA("IntValue") or fruit.object:IsA("NumberValue") then
                    fruit.object.Value = 0
                end
            end)
            task.wait(0.1)
        end
    end

    if totalSold > 0 then
        print("[XodinqHUB] Sold " .. totalSold .. " fruits/items!")
    end
end

coroutine.wrap(function()
    while true do
        task.wait(2)
        if AutoSellEnable
