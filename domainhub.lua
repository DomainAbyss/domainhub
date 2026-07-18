--[[
    🦖 DOMAIN HUB v5.1 — BLOX FRUIT (Delta-safe)
    Fixed: no 'continue' keyword, no 'math.clamp', pcall-wrapped
]]

local OK, ERR = pcall(function()

-- ===== CONFIG =====
local Config = {
    PlayerESP = true,
    FruitESP  = true,
    Tracers   = false,
    HealthBar = true,
    MaxDist   = 999999,
    FlySpeed  = 250,
    Tab       = "ESP",
    AutoGacha = false,
}

-- ===== SERVICES =====
local Players = game:GetService("Players")
local Ws      = game:GetService("Workspace")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local CG      = game:GetService("CoreGui")
local TS      = game:GetService("TweenService")
local LP      = Players.LocalPlayer
local Cam     = Ws.CurrentCamera

-- ===== DRAWING POOLS =====
local ESPool = {}
local FruitP = {}

-- ===== FLY STATE =====
local flying = false
local flyTarget = nil
local flyPhase = "idle"
local flyLV = nil
local flyBG = nil
local flyDeathCon = nil

local function StopFly()
    flying = false
    flyTarget = nil
    flyPhase = "idle"
    if flyLV then
        pcall(function() flyLV:Destroy() end)
        flyLV = nil
    end
    if flyBG then
        pcall(function() flyBG:Destroy() end)
        flyBG = nil
    end
    if flyDeathCon then
        flyDeathCon:Disconnect()
        flyDeathCon = nil
    end
end

-- ===== UTILITY =====
local function NewDrawing(kind, props)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

local function ClearPool(pool)
    for _, v in pairs(pool) do
        pcall(function() v:Remove() end)
    end
    for k in pairs(pool) do
        pool[k] = nil
    end
end

local function GetDistance(pos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and pos then
        return (root.Position - pos).Magnitude
    end
    return math.huge
end

-- =============================================
-- WORLD DETECTION (Level-first, reliable)
-- =============================================
local CurrentSea = nil

local function DetectSea()
    -- Method 1: Player Level (most reliable for Blox Fruit)
    pcall(function()
        local ls = LP:FindFirstChild("leaderstats")
        if ls then
            local lv = ls:FindFirstChild("Level") or ls:FindFirstChild("level")
            if lv then
                local v = lv.Value
                if v >= 1500 then
                    CurrentSea = 3
                    return
                elseif v >= 700 then
                    CurrentSea = 2
                    return
                else
                    CurrentSea = 1
                    return
                end
            end
        end
    end)
    if CurrentSea then return CurrentSea end

    -- Method 2: Map folder name
    pcall(function()
        local map = Ws:FindFirstChild("Map") or Ws:FindFirstChild("World")
        if map then
            local mn = map.Name:lower()
            if mn:find("third") or mn:find("3") then CurrentSea = 3 return end
            if mn:find("second") or mn:find("2") then CurrentSea = 2 return end
            if mn:find("first") or mn:find("1") then CurrentSea = 1 return end
        end
    end)
    if CurrentSea then return CurrentSea end

    -- Method 3: Workspace landmarks (fallback)
    local landmarks3 = {"GreatTree", "PortTown", "HydraIsland", "CastleOnTheSea", "SeaOfTreats", "Tiki"}
    for _, n in ipairs(landmarks3) do
        if Ws:FindFirstChild(n, true) then CurrentSea = 3 return CurrentSea end
    end
    local landmarks2 = {"KingdomOfRose", "Rose", "UsoppsIsland", "Mansion", "Factory", "IceCastle"}
    for _, n in ipairs(landmarks2) do
        if Ws:FindFirstChild(n, true) then CurrentSea = 2 return CurrentSea end
    end
    local landmarks1 = {"MarineTown", "MarineStart", "PirateStart", "Jungle", "PirateVillage"}
    for _, n in ipairs(landmarks1) do
        if Ws:FindFirstChild(n, true) then CurrentSea = 1 return CurrentSea end
    end

    -- Method 4: Coordinate range
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local x = math.abs(root.Position.X)
        local z = math.abs(root.Position.Z)
        if x < 20000 and z < 20000 then CurrentSea = 1 end
        if x > 5000 and z > 5000 then CurrentSea = 2 end
    end

    return CurrentSea
end

CurrentSea = DetectSea()

-- =============================================
-- COORDINATE DATABASE
-- =============================================
local COORDS_DB = {
    -- First Sea
    MarineStart    = Vector3.new(0, 70, 0),
    PirateStart    = Vector3.new(120, 70, 80),
    Jungle         = Vector3.new(50, 70, 2200),
    PirateVillage  = Vector3.new(2200, 70, 50),
    Desert         = Vector3.new(-2400, 70, 50),
    FrozenVillage  = Vector3.new(50, 70, -2400),
    MarineFortress = Vector3.new(3400, 70, 1400),
    Sky1           = Vector3.new(50, 1200, 3200),
    Prison         = Vector3.new(-1200, 70, 2600),
    Colosseum      = Vector3.new(-2700, 70, -1200),
    Magma          = Vector3.new(4200, 70, 50),
    Fishman        = Vector3.new(50, -400, 4200),
    SkyUpper       = Vector3.new(50, 2200, 4200),
    -- Second Sea
    KingdomOfRose  = Vector3.new(50, 70, -9500),
    UsoppsIsland   = Vector3.new(2200, 70, -9500),
    Shank          = Vector3.new(1200, 70, -8500),
    Mansion        = Vector3.new(-2200, 70, -9500),
    Factory        = Vector3.new(50, 70, -12000),
    HotAndCold     = Vector3.new(-3200, 70, -11000),
    CursedShip     = Vector3.new(3200, 70, -12000),
    IceCastle      = Vector3.new(50, 70, -14000),
    FloatingTurtle = Vector3.new(5500, 150, -9500),
    -- Third Sea
    GreatTree      = Vector3.new(50, 150, 22000),
    CastleOnTheSea = Vector3.new(50, 150, 20000),
    PortTown       = Vector3.new(-2500, 70, 22000),
    HydraIsland    = Vector3.new(2500, 150, 24000),
    HauntedCastle  = Vector3.new(-2500, 150, 20000),
    CakeIsland     = Vector3.new(2500, 150, 20000),
    PeanutIsland   = Vector3.new(0, 70, 25000),
    TikiIsland     = Vector3.new(3000, 150, 18000),
    SeaTreats      = Vector3.new(-3000, 150, 24000),
}

local IslandCache = {}
local ScanFailCache = {} -- remember failed tags

local function NormalizeName(n)
    if not n then return "" end
    return n:lower():gsub("[%p_]", " "):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
end

local function FuzzyMatch(name, pattern)
    local n = NormalizeName(name)
    local p = NormalizeName(pattern)
    if n == p then return true end
    if n:find(p, 1, true) or p:find(n, 1, true) then return true end
    -- word match
    local words = {}
    for w in p:gmatch("%S+") do words[w] = true end
    local count = 0
    local total = 0
    for w in pairs(words) do
        total = total + 1
        if n:find(w, 1, true) then count = count + 1 end
    end
    if total > 0 and count >= math.ceil(total * 0.5) then return true end
    return false
end

local function ScanWorkspaceForIsland(tag, name)
    if ScanFailCache[tag] then return nil end

    local cleanName = name:gsub("[^%w%s]", ""):gsub("^%s*(.-)%s*$", "%1")
    local patterns = {tag, name, cleanName}

    -- Strategy 1: BasePart with fuzzy match
    for _, v in pairs(Ws:GetDescendants()) do
        if v:IsA("BasePart") and v.Size.Magnitude > 5 then
            for _, p in ipairs(patterns) do
                if p and #p > 0 and FuzzyMatch(v.Name, p) then
                    local pos = v.Position + Vector3.new(0, math.max(v.Size.Y / 2, 20) + 15, 0)
                    IslandCache[tag] = pos
                    return pos
                end
            end
        end
    end

    -- Strategy 2: Model with fuzzy match
    for _, v in pairs(Ws:GetDescendants()) do
        if v:IsA("Model") then
            local found = false
            for _, p in ipairs(patterns) do
                if p and #p > 0 and FuzzyMatch(v.Name, p) then
                    found = true
                    break
                end
            end
            if found then
                local ok, pivot = pcall(function() return v:GetPivot() end)
                if ok and pivot then
                    local pos = pivot.Position + Vector3.new(0, 50, 0)
                    IslandCache[tag] = pos
                    return pos
                end
                local big = v:FindFirstChildWhichIsA("BasePart")
                if big then
                    local pos = big.Position + Vector3.new(0, big.Size.Y / 2 + 30, 0)
                    IslandCache[tag] = pos
                    return pos
                end
            end
        end
    end

    ScanFailCache[tag] = true
    return nil
end

local function GetIslandPos(tag, name)
    if COORDS_DB[tag] then
        return COORDS_DB[tag], "database"
    end
    if IslandCache[tag] then
        return IslandCache[tag], "cache"
    end
    local pos = ScanWorkspaceForIsland(tag, name)
    if pos then
        return pos, "scan"
    end
    return nil, "none"
end

-- ===== ISLAND DATA FOR UI =====
local ISLAND_DB = {
    [1] = {
        {N = "🏝 Marine Start", T = "MarineStart"},
        {N = "🏝 Pirate Start", T = "PirateStart"},
        {N = "🌴 Jungle", T = "Jungle"},
        {N = "🏘 Pirate Village", T = "PirateVillage"},
        {N = "🏜 Desert", T = "Desert"},
        {N = "❄️ Frozen Village", T = "FrozenVillage"},
        {N = "🏰 Marine Fortress", T = "MarineFortress"},
        {N = "☁️ Sky Island", T = "Sky1"},
        {N = "⛓ Prison", T = "Prison"},
        {N = "🏛 Colosseum", T = "Colosseum"},
        {N = "🌋 Magma Village", T = "Magma"},
        {N = "🌊 Underwater", T = "Fishman"},
        {N = "☁️ Upper Sky", T = "SkyUpper"},
    },
    [2] = {
        {N = "🌹 Kingdom of Rose", T = "KingdomOfRose"},
        {N = "🎯 Usopp's Island", T = "UsoppsIsland"},
        {N = "🍺 Shank's Room", T = "Shank"},
        {N = "🏚 Mansion", T = "Mansion"},
        {N = "🏭 Factory", T = "Factory"},
        {N = "❄️🔥 Hot & Cold", T = "HotAndCold"},
        {N = "⛵️ Cursed Ship", T = "CursedShip"},
        {N = "🏰 Ice Castle", T = "IceCastle"},
        {N = "🐢 Floating Turtle", T = "FloatingTurtle"},
    },
    [3] = {
        {N = "🌳 Great Tree", T = "GreatTree"},
        {N = "🏯 Castle on Sea", T = "CastleOnTheSea"},
        {N = "⚓️ Port Town", T = "PortTown"},
        {N = "🐉 Hydra Island", T = "HydraIsland"},
        {N = "👻 Haunted Castle", T = "HauntedCastle"},
        {N = "🎂 Cake Island", T = "CakeIsland"},
        {N = "🥜 Peanut Island", T = "PeanutIsland"},
        {N = "🏝 Tiki Island", T = "TikiIsland"},
        {N = "🌊 Sea of Treats", T = "SeaTreats"},
    },
}
local ALL_ISLANDS = {}
for s = 1, 3 do
    for _, v in ipairs(ISLAND_DB[s]) do
        table.insert(ALL_ISLANDS, v)
    end
end

-- =============================================
-- FLIGHT SYSTEM
-- =============================================
local FLY_ALTITUDE = 300

local function GetAdaptiveSpeed(dist)
    if dist > 10000 then return Config.FlySpeed * 1.5 end
    if dist > 5000  then return Config.FlySpeed end
    if dist > 1000  then return Config.FlySpeed * 0.7 end
    if dist > 300   then return Config.FlySpeed * 0.5 end
    if dist > 100   then return Config.FlySpeed * 0.3 end
    return math.max(Config.FlySpeed * 0.15, 30)
end

local function FlyTo(targetPos)
    StopFly()

    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    flying = true
    flyTarget = targetPos
    flyPhase = "CLIMB"

    -- LinearVelocity (modern, smooth)
    flyLV = Instance.new("LinearVelocity")
    flyLV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyLV.VectorVelocity = Vector3.new(0, 0, 0)
    flyLV.Parent = root

    -- BodyGyro to stay upright
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root

    -- Death/drown detection
    flyDeathCon = hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.FallingDown
            or newState == Enum.HumanoidStateType.Dead then
            StopFly()
        end
    end)

    -- Raycast params
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char}

    -- Main flight loop
    task.spawn(function()
        while flying and flyTarget and flyLV and flyLV.Parent do
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then
                StopFly()
                break
            end

            local currentPos = root.Position
            local direction = flyTarget - currentPos
            local dist = direction.Magnitude
            local dirUnit = direction.Unit

            -- Check if arrived
            if dist < 20 and flyPhase == "DESCEND" then
                -- Land
                flyLV.VectorVelocity = Vector3.new(0, -2, 0)
                task.wait(0.1)
                StopFly()
                break
            end
            if dist < 50 and flyPhase == "CRUISE" then
                flyPhase = "DESCEND"
            end

            -- PHASE: CLIMB
            if flyPhase == "CLIMB" then
                local targetAlt = math.max(currentPos.Y + 200, FLY_ALTITUDE)
                targetAlt = math.max(targetAlt, flyTarget.Y + 50)
                if currentPos.Y >= targetAlt - 10 then
                    flyPhase = "CRUISE"
                else
                    local flatDir = Vector3.new(dirUnit.X, 0, dirUnit.Z).Unit
                    local climbSpeed = math.min(Config.FlySpeed * 0.6, (targetAlt - currentPos.Y) * 1.5 + 30)
                    flyLV.VectorVelocity = flatDir * (climbSpeed * 0.5) + Vector3.new(0, climbSpeed, 0)
                    if flyBG then
                        flyBG.CFrame = CFrame.lookAt(currentPos, currentPos + flatDir)
                    end
                end
                task.wait(0.03)
            end

            -- PHASE: CRUISE
            if flyPhase == "CRUISE" then
                -- Maintain minimum altitude
                local minAlt = math.max(FLY_ALTITUDE, 200)
                if currentPos.Y < minAlt then
                    dirUnit = Vector3.new(dirUnit.X, 0.3, dirUnit.Z).Unit
                end

                -- Collision detection
                local lookAhead = math.min(dist, 200)
                local hit = Ws:Raycast(currentPos, dirUnit * lookAhead, rayParams)
                if hit and hit.Instance then
                    local obs = hit.Instance
                    if obs:IsA("BasePart") and obs.Size.Magnitude > 8 then
                        flyPhase = "CLIMB"
                        FLY_ALTITUDE = currentPos.Y + 200
                        task.wait(0.03)
                    end
                end

                local speed = GetAdaptiveSpeed(dist)
                flyLV.VectorVelocity = dirUnit * speed
                if flyBG then
                    flyBG.CFrame = CFrame.lookAt(currentPos, currentPos + dirUnit)
                end
                task.wait(0.03)
            end

            -- PHASE: DESCEND
            if flyPhase == "DESCEND" then
                local groundCheck = Ws:Raycast(currentPos, Vector3.new(0, -500, 0), rayParams)
                local groundY = groundCheck and groundCheck.Position.Y or (flyTarget.Y - 20)
                local targetY = groundY + 20
                local descendSpeed = math.min(Config.FlySpeed * 0.3, (currentPos.Y - targetY) * 0.5 + 20)

                local flatDist = Vector3.new(direction.X, 0, direction.Z).Magnitude
                if flatDist > 5 then
                    local flatDir = Vector3.new(dirUnit.X, 0, dirUnit.Z).Unit
                    local speed = math.max(GetAdaptiveSpeed(flatDist), 20)
                    local vy = currentPos.Y > targetY and -descendSpeed or descendSpeed
                    flyLV.VectorVelocity = flatDir * speed + Vector3.new(0, vy, 0)
                    if flyBG then
                        flyBG.CFrame = CFrame.lookAt(currentPos, currentPos + flatDir)
                    end
                else
                    local vy = currentPos.Y > targetY and -descendSpeed or descendSpeed
                    if math.abs(currentPos.Y - targetY) < 5 then
                        flyLV.VectorVelocity = Vector3.new(0, -2, 0)
                        task.wait(0.1)
                        StopFly()
                        break
                    end
                    flyLV.VectorVelocity = Vector3.new(0, vy, 0)
                end
                task.wait(0.03)
            end
        end

        -- Cleanup if loop exits
        if flying then
            StopFly()
        end
    end)
end

-- =============================================
-- AUTO GACHA FRUIT
-- =============================================
local function FindGachaDealer()
    -- Common Blox Fruit Dealer NPC names
    local dealerNames = {
        "Blox Fruit Dealer",
        "Blox Fruit Dealer 2",
        "BloxFruitDealer",
        "FruitDealer",
        "Fruit Dealer",
    }
    for _, name in ipairs(dealerNames) do
        local npc = Ws:FindFirstChild(name, true)
        if npc then
            return npc
        end
    end
    -- Search by keyword
    for _, v in pairs(Ws:GetDescendants()) do
        if v:IsA("Model") then
            local mn = v.Name:lower()
            if mn:find("blox") and mn:find("fruit") and mn:find("dealer") then
                return v
            end
        end
    end
    return nil
end

local function AutoGacha()
    local dealer = FindGachaDealer()
    if not dealer then
        return "❌ No Blox Fruit Dealer found nearby"
    end

    -- Teleport to dealer
    local ok, pivot = pcall(function() return dealer:GetPivot() end)
    local targetPos
    if ok and pivot then
        targetPos = pivot.Position + Vector3.new(0, 30, 5)
    else
        local part = dealer:FindFirstChildWhichIsA("BasePart")
        if part then
            targetPos = part.Position + Vector3.new(0, part.Size.Y / 2 + 10, 5)
        else
            return "❌ Can't find dealer position"
        end
    end

    FlyTo(targetPos)

    -- After flying, look for dialog/interact
    task.spawn(function()
        -- Wait for arrival
        task.wait(3)

        -- Try to find proximity prompt or dialog
        for _, v in pairs(dealer:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                -- Fire the prompt
                pcall(function()
                    v:InputHoldBegin()
                end)
                task.wait(0.5)
                pcall(function()
                    v:InputHoldEnd()
                end)
                return "🎲 Teleported to dealer! Interact manually to roll."
            end
        end

        -- Try clicking the dealer
        pcall(function()
            local part = dealer:FindFirstChildWhichIsA("BasePart")
            if part then
                -- Simulate mouse click (limited)
                fireclickdetector and fireclickdetector(part)
            end
        end)

        return "🎲 Teleported to dealer! Interact manually to roll."
    end)

    return "🎲 Flying to Blox Fruit Dealer..."
end

-- =============================================
-- UI CREATION
-- =============================================

-- Cleanup previous instance
if CG:FindFirstChild("DomainHub") then
    CG:FindFirstChild("DomainHub"):Destroy()
    ClearPool(ESPool)
    ClearPool(FruitP)
    StopFly()
end

-- Create ScreenGui
local Hub = Instance.new("ScreenGui")
Hub.Name = "DomainHub"
Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Hub.DisplayOrder = 999
Hub.ResetOnSpawn = false

-- Inject into CoreGui
if gethui then
    Hub.Parent = gethui()
elseif cloneref then
    Hub.Parent = cloneref(CG)
else
    Hub.Parent = CG
end

-- Colors
local C = {
    BG = Color3.fromRGB(10, 10, 18),
    ACCENT = Color3.fromRGB(0, 200, 80),
    ACCENT2 = Color3.fromRGB(0, 160, 60),
    SURFACE = Color3.fromRGB(18, 20, 22),
    TEXT = Color3.fromRGB(220, 220, 230),
    TEXT_DIM = Color3.fromRGB(140, 140, 150),
    RED = Color3.fromRGB(220, 60, 60),
    TAB_INACTIVE = Color3.fromRGB(20, 25, 22),
}

-- ============ MAIN FRAME ============
local MainF = Instance.new("ImageLabel")
MainF.Name = "Main"
MainF.Size = UDim2.new(0, 350, 0, 460)
MainF.Position = UDim2.new(0.5, -175, 0.5, -230)
MainF.BackgroundColor3 = C.BG
MainF.BackgroundTransparency = 0.03
MainF.Image = "rbxassetid://13160433535"
MainF.ImageColor3 = C.BG
MainF.ScaleType = Enum.ScaleType.Slice
MainF.SliceCenter = Rect.new(12, 12, 12, 12)
MainF.Active = true
MainF.Draggable = true
MainF.Parent = Hub

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainF

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C.ACCENT
MainStroke.Thickness = 1.5
MainStroke.Parent = MainF

-- ============ HEADER ============
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = C.ACCENT
Header.BackgroundTransparency = 0.12
Header.Text = "  🦖 DOMAIN HUB"
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.TextSize = 18
Header.Font = Enum.Font.GothamBold
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.Parent = MainF

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -68, 0, 6)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "🦖"
MinBtn.TextSize = 16
MinBtn.Parent = MainF

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0, 6)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainF

-- ============ TAB BAR ============
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 48)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainF

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Padding = UDim.new(0, 8)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

local TabData = {
    {Key = "ESP", Label = "⚔️ ESP"},
    {Key = "TP", Label = "🌍 Teleport"},
    {Key = "SETTINGS", Label = "⚙️ Settings"},
}
local TabButtons = {}

-- Tab content container
local TabContent = Instance.new("Frame")
TabContent.Size = UDim2.new(1, -20, 1, -98)
TabContent.Position = UDim2.new(0, 10, 0, 84)
TabContent.BackgroundTransparency = 1
TabContent.Parent = MainF

-- Placeholder for tab pages
local ESPPage = nil
local TPPage = nil
local SettingsPage = nil

local function SwitchTab(key)
    Config.Tab = key
    for _, tb in ipairs(TabButtons) do
        if tb.Key == key then
            tb.Btn.BackgroundColor3 = C.ACCENT
            tb.Line.Visible = true
        else
            tb.Btn.BackgroundColor3 = C.TAB_INACTIVE
            tb.Line.Visible = false
        end
    end
    if ESPPage then ESPPage.Visible = (key == "ESP") end
    if TPPage then TPPage.Visible = (key == "TP") end
    if SettingsPage then SettingsPage.Visible = (key == "SETTINGS") end
end

for _, td in ipairs(TabData) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 30)
    btn.BackgroundColor3 = (td.Key == "ESP" and C.ACCENT or C.TAB_INACTIVE)
    btn.Text = td.Label
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TabBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.8, 0, 0, 2)
    line.Position = UDim2.new(0.1, 0, 1, -3)
    line.BackgroundColor3 = C.ACCENT2
    line.Visible = (td.Key == "ESP")
    line.Parent = btn

    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(0, 1)
    lineCorner.Parent = line

    table.insert(TabButtons, {Key = td.Key, Btn = btn, Line = line})

    btn.MouseButton1Click:Connect(function()
        SwitchTab(td.Key)
    end)
end

-- =============================================
-- TAB 1: ESP
-- =============================================
do
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = C.ACCENT
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = TabContent
    ESPPage = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local function AddSection(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 26)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = C.ACCENT
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = scroll
    end

    local function AddToggle(label, configKey, defaultVal)
        Config[configKey] = defaultVal
        local state = defaultVal

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = C.SURFACE
        row.Parent = scroll
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -54, 1, 0)
        textLabel.Position = UDim2.new(0, 12, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = label
        textLabel.TextColor3 = C.TEXT
        textLabel.TextSize = 13
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 44, 0, 22)
        track.Position = UDim2.new(1, -52, 0, 8)
        track.BackgroundColor3 = (state and C.ACCENT or Color3.fromRGB(60, 60, 70))
        track.Parent = row
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 11)
        trackCorner.Parent = track

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = (state and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2))
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Parent = track
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 9)
        knobCorner.Parent = knob

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size = UDim2.new(1, 0, 1, 0)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text = ""
        hitBtn.Parent = row

        hitBtn.MouseButton1Click:Connect(function()
            state = not state
            Config[configKey] = state
            track.BackgroundColor3 = (state and C.ACCENT or Color3.fromRGB(60, 60, 70))
            local targetPos = (state and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2))
            knob:TweenPosition(targetPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            if not state then
                if configKey == "PlayerESP" then ClearPool(ESPool) end
                if configKey == "FruitESP" then ClearPool(FruitP) end
            end
        end)
    end

    AddSection("⚔️ PLAYER ESP")
    AddToggle("Player ESP", "PlayerESP", true)
    AddToggle("Tracers", "Tracers", false)
    AddToggle("Health Bar", "HealthBar", true)

    AddSection("🍎 FRUIT ESP")
    AddToggle("Fruit ESP", "FruitESP", true)
end

-- =============================================
-- TAB 2: TELEPORT
-- =============================================
do
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = C.ACCENT
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = TabContent
    TPPage = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    -- Sea label
    local seaLabel = Instance.new("TextLabel")
    seaLabel.Size = UDim2.new(1, 0, 0, 22)
    seaLabel.BackgroundTransparency = 1
    if CurrentSea then
        seaLabel.Text = "📍 World " .. CurrentSea .. " detected"
    else
        seaLabel.Text = "📍 Auto-detect: scanning..."
    end
    seaLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    seaLabel.TextSize = 12
    seaLabel.Font = Enum.Font.Gotham
    seaLabel.Parent = scroll

    -- Sea tab row
    local seaTabRow = Instance.new("Frame")
    seaTabRow.Size = UDim2.new(1, 0, 0, 32)
    seaTabRow.BackgroundTransparency = 1
    seaTabRow.Parent = scroll
    local seaTabLayout = Instance.new("UIListLayout")
    seaTabLayout.FillDirection = Enum.FillDirection.Horizontal
    seaTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    seaTabLayout.Padding = UDim.new(0, 6)
    seaTabLayout.Parent = seaTabRow

    local seaView = CurrentSea or 0
    local seaTabBtns = {}
    local seaData = {
        {V = 0, L = "🗺 All"},
        {V = 1, L = "🌊 1st"},
        {V = 2, L = "🌊 2nd"},
        {V = 3, L = "🌊 3rd"},
    }

    local function UpdateSeaTabs()
        for _, tb in ipairs(seaTabBtns) do
            tb.BackgroundColor3 = (seaView == tb._V) and C.ACCENT or C.TAB_INACTIVE
        end
    end

    -- Destination display
    local destLabel = Instance.new("TextLabel")
    destLabel.Size = UDim2.new(1, 0, 0, 24)
    destLabel.BackgroundTransparency = 1
    destLabel.Text = "🌍 Select destination..."
    destLabel.TextColor3 = C.TEXT
    destLabel.TextSize = 14
    destLabel.Font = Enum.Font.GothamBold
    destLabel.Parent = scroll

    -- Source info
    local sourceLabel = Instance.new("TextLabel")
    sourceLabel.Size = UDim2.new(1, 0, 0, 16)
    sourceLabel.BackgroundTransparency = 1
    sourceLabel.Text = ""
    sourceLabel.TextColor3 = C.TEXT_DIM
    sourceLabel.TextSize = 10
    sourceLabel.Font = Enum.Font.Gotham
    sourceLabel.Parent = scroll

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 18)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = scroll

    -- Phase indicator
    local phaseLabel = Instance.new("TextLabel")
    phaseLabel.Size = UDim2.new(1, 0, 0, 16)
    phaseLabel.BackgroundTransparency = 1
    phaseLabel.Text = ""
    phaseLabel.TextColor3 = C.ACCENT
    phaseLabel.TextSize = 10
    phaseLabel.Font = Enum.Font.Gotham
    phaseLabel.Parent = scroll

    -- Speed row
    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, 0, 0, 30)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = scroll

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.5, -4, 1, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "✈️ Fly Speed:"
    speedLabel.TextColor3 = C.TEXT
    speedLabel.TextSize = 13
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = speedRow

    local speedInput = Instance.new("TextBox")
    speedInput.Size = UDim2.new(0.5, -4, 1, 0)
    speedInput.Position = UDim2.new(0.5, 4, 0, 0)
    speedInput.BackgroundColor3 = C.SURFACE
    speedInput.Text = tostring(Config.FlySpeed)
    speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput.TextSize = 13
    speedInput.Font = Enum.Font.GothamBold
    speedInput.TextXAlignment = Enum.TextXAlignment.Center
    speedInput.Parent = speedRow
    local speedInputCorner = Instance.new("UICorner")
    speedInputCorner.CornerRadius = UDim.new(0, 6)
    speedInputCorner.Parent = speedInput
    speedInput.FocusLost:Connect(function()
        local n = tonumber(speedInput.Text)
        Config.FlySpeed = n and math.max(50, math.min(2000, n)) or 250
        speedInput.Text = tostring(Config.FlySpeed)
    end)

    -- Stop button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(1, 0, 0, 30)
    stopBtn.BackgroundColor3 = C.RED
    stopBtn.Text = "⏹ STOP FLYING"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.TextSize = 13
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.Parent = scroll
    local stopBtnCorner = Instance.new("UICorner")
    stopBtnCorner.CornerRadius = UDim.new(0, 8)
    stopBtnCorner.Parent = stopBtn
    stopBtn.Visible = false
    stopBtn.MouseButton1Click:Connect(function()
        StopFly()
        stopBtn.Visible = false
        destLabel.Text = "🌍 Select destination..."
        statusLabel.Text = ""
        sourceLabel.Text = ""
        phaseLabel.Text = ""
    end)

    -- Island list container
    local islandCont = Instance.new("Frame")
    islandCont.Size = UDim2.new(1, 0, 0, 0)
    islandCont.BackgroundTransparency = 1
    islandCont.Parent = scroll
    local islandLayout = Instance.new("UIListLayout")
    islandLayout.Padding = UDim.new(0, 4)
    islandLayout.SortOrder = Enum.SortOrder.LayoutOrder
    islandLayout.Parent = islandCont

    local function BuildIslandList()
        for _, c in pairs(islandCont:GetChildren()) do
            if c:IsA("TextButton") then
                c:Destroy()
            end
        end

        local islands = (seaView == 0 and ALL_ISLANDS) or ISLAND_DB[seaView] or {}
        islandCont.Size = UDim2.new(1, 0, 0, #islands * 33 + 4)

        for _, island in ipairs(islands) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = C.SURFACE
            btn.Text = island.N
            btn.TextColor3 = C.TEXT
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = islandCont
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(30, 40, 35)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = C.SURFACE
            end)

            btn.MouseButton1Click:Connect(function()
                destLabel.Text = "✈ " .. island.N .. "..."
                statusLabel.Text = "🔍 Looking up position..."
                sourceLabel.Text = ""

                local pos, source = GetIslandPos(island.T, island.N)
                if pos then
                    local srcNames = {database = "📀 DB", cache = "💾 Cache", scan = "🔍 Scan"}
                    local srcName = srcNames[source] or source
                    sourceLabel.Text = "Source: " .. srcName

                    local dist = math.floor(GetDistance(pos))
                    statusLabel.Text = "📍 Target: " .. dist .. " m away"
                    task.wait(0.2)
                    FlyTo(pos)
                    stopBtn.Visible = true
                    destLabel.Text = "✈ " .. island.N
                    statusLabel.Text = "✅ Flying (" .. srcName .. ")"
                else
                    statusLabel.Text = "❌ Island not found in DB/Cache/Workspace"
                    sourceLabel.Text = "Tip: Coordinates may need updating"
                    destLabel.Text = "🌍 " .. island.N
                end
            end)
        end
    end

    -- Build sea tab buttons
    for _, sd in ipairs(seaData) do
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(0, 78, 0, 28)
        tb.BackgroundColor3 = (seaView == sd.V) and C.ACCENT or C.TAB_INACTIVE
        tb.Text = sd.L
        tb.TextColor3 = C.TEXT
        tb.TextSize = 12
        tb.Font = Enum.Font.GothamBold
        tb.Parent = seaTabRow
        tb._V = sd.V

        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 6)
        tbCorner.Parent = tb

        tb.MouseButton1Click:Connect(function()
            seaView = sd.V
            UpdateSeaTabs()
            BuildIslandList()
        end)

        table.insert(seaTabBtns, tb)
    end

    BuildIslandList()

    -- Flight status updater
    task.spawn(function()
        while true do
            task.wait(0.2)
            if flying and flyTarget then
                local char = LP.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (flyTarget - root.Position).Magnitude
                    local phaseIcons = {
                        CLIMB = "⬆️ Climbing",
                        CRUISE = "✈️ Cruising",
                        DESCEND = "⬇️ Descending",
                    }
                    local pText = phaseIcons[flyPhase] or flyPhase
                    statusLabel.Text = "✈ " .. pText .. " — " .. math.floor(d) .. " m left"
                    phaseLabel.Text = pText
                end
            elseif not flying and stopBtn.Visible then
                stopBtn.Visible = false
                phaseLabel.Text = ""
                destLabel.Text = "🌍 Select destination..."
                statusLabel.Text = ""
                sourceLabel.Text = ""
            end
        end
    end)

    -- Auto Gacha button
    local gachaBtn = Instance.new("TextButton")
    gachaBtn.Size = UDim2.new(1, 0, 0, 34)
    gachaBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 200) -- purple for gacha
    gachaBtn.Text = "🎲 BLox Fruit Gacha"
    gachaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    gachaBtn.TextSize = 14
    gachaBtn.Font = Enum.Font.GothamBold
    gachaBtn.Parent = scroll
    local gachaCorner = Instance.new("UICorner")
    gachaCorner.CornerRadius = UDim.new(0, 8)
    gachaCorner.Parent = gachaBtn
    gachaBtn.MouseButton1Click:Connect(function()
        destLabel.Text = "🎲 Auto Gacha..."
        statusLabel.Text = "🔍 Searching for Blox Fruit Dealer..."
        sourceLabel.Text = ""
        local result = AutoGacha()
        statusLabel.Text = result
        destLabel.Text = "🎲 Gacha"
    end)
end

-- =============================================
-- TAB 3: SETTINGS
-- =============================================
do
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = C.ACCENT
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = TabContent
    SettingsPage = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local function AddSection(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 26)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = C.ACCENT
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = scroll
    end

    -- Max Distance slider
    AddSection("📏 MAX DISTANCE")

    local distRow = Instance.new("Frame")
    distRow.Size = UDim2.new(1, 0, 0, 42)
    distRow.BackgroundColor3 = C.SURFACE
    distRow.Parent = scroll
    local distRowCorner = Instance.new("UICorner")
    distRowCorner.CornerRadius = UDim.new(0, 8)
    distRowCorner.Parent = distRow

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 12, 0, 4)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Max Distance"
    distLabel.TextColor3 = C.TEXT
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.Parent = distRow

    local distVal = Instance.new("TextLabel")
    distVal.Size = UDim2.new(1, 0, 0, 16)
    distVal.Position = UDim2.new(0, 12, 0, 22)
    distVal.BackgroundTransparency = 1
    distVal.Text = "∞"
    distVal.TextColor3 = C.ACCENT
    distVal.TextSize = 11
    distVal.Font = Enum.Font.Gotham
    distVal.TextXAlignment = Enum.TextXAlignment.Left
    distVal.Parent = distRow

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0, 140, 0, 5)
    sliderBg.Position = UDim2.new(1, -152, 0, 18)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderBg.Parent = distRow
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 2)
    sliderBgCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0.95, 0, 1, 0)
    sliderFill.BackgroundColor3 = C.ACCENT
    sliderFill.Parent = sliderBg
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 2)
    sliderFillCorner.Parent = sliderFill

    local sliderHit = Instance.new("TextButton")
    sliderHit.Size = UDim2.new(1, 0, 1, 0)
    sliderHit.BackgroundTransparency = 1
    sliderHit.Text = ""
    sliderHit.Parent = distRow

    local smin = 50000
    local smax = 1000000
    local dragging = false

    sliderHit.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UIS.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local mx = UIS:GetMouseLocation().X
            local ax = sliderBg.AbsolutePosition.X
            local aw = sliderBg.AbsoluteSize.X
            local ratio = math.max(0, math.min(1, (mx - ax) / aw))
            Config.MaxDist = math.floor(smin + (smax - smin) * ratio)
            distVal.Text = (Config.MaxDist >= 1000000 and "∞" or tostring(Config.MaxDist))
            sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        end
    end)

    -- Fly Speed
    AddSection("✈️ FLY SPEED")

    local speedRow2 = Instance.new("Frame")
    speedRow2.Size = UDim2.new(1, 0, 0, 38)
    speedRow2.BackgroundColor3 = C.SURFACE
    speedRow2.Parent = scroll
    local speedRow2Corner = Instance.new("UICorner")
    speedRow2Corner.CornerRadius = UDim.new(0, 8)
    speedRow2Corner.Parent = speedRow2

    local speedLabel2 = Instance.new("TextLabel")
    speedLabel2.Size = UDim2.new(0.6, -8, 1, 0)
    speedLabel2.Position = UDim2.new(0, 12, 0, 0)
    speedLabel2.BackgroundTransparency = 1
    speedLabel2.Text = "✈️ Fly Speed"
    speedLabel2.TextColor3 = C.TEXT
    speedLabel2.TextSize = 13
    speedLabel2.Font = Enum.Font.Gotham
    speedLabel2.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel2.Parent = speedRow2

    local speedInput2 = Instance.new("TextBox")
    speedInput2.Size = UDim2.new(0.35, -8, 0, 28)
    speedInput2.Position = UDim2.new(0.62, 0, 0, 5)
    speedInput2.BackgroundColor3 = Color3.fromRGB(25, 30, 28)
    speedInput2.Text = tostring(Config.FlySpeed)
    speedInput2.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput2.TextSize = 13
    speedInput2.Font = Enum.Font.GothamBold
    speedInput2.TextXAlignment = Enum.TextXAlignment.Center
    speedInput2.Parent = speedRow2
    local speedInput2Corner = Instance.new("UICorner")
    speedInput2Corner.CornerRadius = UDim.new(0, 6)
    speedInput2Corner.Parent = speedInput2
    speedInput2.FocusLost:Connect(function()
        local n = tonumber(speedInput2.Text)
        Config.FlySpeed = n and math.max(50, math.min(2000, n)) or 250
        speedInput2.Text = tostring(Config.FlySpeed)
    end)

    -- Cache Info
    AddSection("🛡️ CACHE INFO")

    local cacheLabel = Instance.new("TextLabel")
    cacheLabel.Size = UDim2.new(1, 0, 0, 36)
    cacheLabel.BackgroundColor3 = C.SURFACE
    cacheLabel.Parent = scroll
    local cacheLabelCorner = Instance.new("UICorner")
    cacheLabelCorner.CornerRadius = UDim.new(0, 8)
    cacheLabelCorner.Parent = cacheLabel

    local dbCount = 0
    for _ in pairs(COORDS_DB) do dbCount = dbCount + 1 end
    local cacheCount = 0
    for _ in pairs(IslandCache) do cacheCount = cacheCount + 1 end

    cacheLabel.Text = "📀 DB: " .. dbCount .. " islands\n💾 Cache: " .. cacheCount .. " scanned"
    cacheLabel.TextColor3 = C.TEXT_DIM
    cacheLabel.TextSize = 11
    cacheLabel.Font = Enum.Font.Gotham
end

-- =============================================
-- APPLY INITIAL TAB
-- =============================================
SwitchTab("ESP")

-- ============ ICON BUTTON (minimized state) ============
local IconBtn = Instance.new("TextButton")
IconBtn.Name = "Icon"
IconBtn.Size = UDim2.new(0, 50, 0, 50)
IconBtn.Position = UDim2.new(0, 20, 0.5, -25)
IconBtn.BackgroundColor3 = C.ACCENT
IconBtn.Text = "🦖"
IconBtn.TextSize = 24
IconBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
IconBtn.Active = true
IconBtn.Draggable = true
IconBtn.Visible = false
IconBtn.Parent = Hub

local IconBtnCorner = Instance.new("UICorner")
IconBtnCorner.CornerRadius = UDim.new(0, 14)
IconBtnCorner.Parent = IconBtn

local IconBtnStroke = Instance.new("UIStroke")
IconBtnStroke.Color = C.ACCENT2
IconBtnStroke.Thickness = 2
IconBtnStroke.Parent = IconBtn

-- ============ BUTTON CONNECTIONS ============
MinBtn.MouseButton1Click:Connect(function()
    MainF.Visible = false
    IconBtn.Visible = true
end)

IconBtn.MouseButton1Click:Connect(function()
    IconBtn.Visible = false
    MainF.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    ClearPool(ESPool)
    ClearPool(FruitP)
    StopFly()
    Hub:Destroy()
end)

-- =============================================
-- NOTIFICATION
-- =============================================
do
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 320, 0, 40)
    notif.Position = UDim2.new(0.5, -160, 0, 20)
    notif.BackgroundColor3 = C.BG
    notif.Parent = Hub
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notif
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = C.ACCENT
    notifStroke.Thickness = 1
    notifStroke.Parent = notif
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, 0)
    notifText.Position = UDim2.new(0, 10, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = "🦖 DOMAIN HUB v5 — World " .. (CurrentSea or "?")
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.TextSize = 13
    notifText.Font = Enum.Font.Gotham
    notifText.Parent = notif

    task.delay(3, function()
        TS:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.5, function()
            notif:Destroy()
        end)
    end)
end

-- =============================================
-- PLAYER ESP
-- =============================================
local frameTick = 0
local playerList = {}

RS.RenderStepped:Connect(function()
    frameTick = frameTick + 1
    if frameTick >= 30 then
        frameTick = 0
        playerList = Players:GetPlayers()
    end

    -- Create/remove ESP objects based on Config.PlayerESP
    if Config.PlayerESP then
        local active = {}
        for _, p in pairs(playerList) do
            if p ~= LP then
                active[p] = true
                if not ESPool[p] then
                    local box = NewDrawing("Square", {Thickness = 1, Color = C.ACCENT, Filled = false})
                    local nameTag = NewDrawing("Text", {Color = C.TEXT, Size = 14, Center = true, Outline = true})
                    local distTag = NewDrawing("Text", {Color = Color3.fromRGB(200, 200, 200), Size = 11, Center = true, Outline = true})
                    local hpBg = NewDrawing("Square", {Color = Color3.fromRGB(40, 40, 40), Filled = true})
                    local hpFill = NewDrawing("Square", {Color = Color3.fromRGB(0, 200, 80), Filled = true})
                    local tracer = NewDrawing("Line", {Color = C.ACCENT, Thickness = 1})
                    ESPool[p] = {Box = box, Name = nameTag, Dist = distTag, HpBg = hpBg, HpFill = hpFill, Tracer = tracer}
                end
            end
        end
        -- Remove inactive
        for p, objs in pairs(ESPool) do
            if not active[p] then
                objs.Box:Remove()
                objs.Name:Remove()
                objs.Dist:Remove()
                objs.HpBg:Remove()
                objs.HpFill:Remove()
                objs.Tracer:Remove()
                ESPool[p] = nil
            end
        end
    else
        -- ESP disabled: clear all
        for _, objs in pairs(ESPool) do
            objs.Box.Visible = false
            objs.Name.Visible = false
            objs.Dist.Visible = false
            objs.HpBg.Visible = false
            objs.HpFill.Visible = false
            objs.Tracer.Visible = false
        end
    end

    -- Update ESP positions
    for plr, objs in pairs(ESPool) do
        if Config.PlayerESP then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local dist = GetDistance(root.Position)
                if dist <= Config.MaxDist then
                    -- SHOW ESP
                    local sp = Cam:WorldToViewportPoint(root.Position)
                    local spH = Cam:WorldToViewportPoint(root.Position + Vector3.new(0, 4.5, 0))
                    local spF = Cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
                    local height = math.abs(spH.Y - spF.Y)
                    local width = height * 0.7
                    local x = sp.X - width / 2
                    local y = spH.Y
                    objs.Box.Visible = true
                    objs.Box.Size = Vector2.new(width, height)
                    objs.Box.Position = Vector2.new(x, y)
                    objs.Box.Color = C.ACCENT
                    objs.Name.Visible = true
                    objs.Name.Position = Vector2.new(sp.X, spH.Y - 18)
                    objs.Name.Text = plr.Name
                    local distColor = (dist < 500 and Color3.fromRGB(0, 255, 100)) or (dist < 50000 and Color3.fromRGB(255, 200, 50)) or C.RED
                    objs.Dist.Visible = true
                    objs.Dist.Position = Vector2.new(sp.X, spF.Y + 4)
                    objs.Dist.Text = (dist >= 1000000 and "∞" or math.floor(dist) .. " m")
                    objs.Dist.Color = distColor
                    if Config.HealthBar then
                        local hp = hum.Health / hum.MaxHealth
                        objs.HpBg.Visible = true
                        objs.HpBg.Size = Vector2.new(width + 4, 3)
                        objs.HpBg.Position = Vector2.new(x - 2, y - 5)
                        objs.HpFill.Visible = true
                        objs.HpFill.Size = Vector2.new((width + 4) * hp, 3)
                        objs.HpFill.Position = Vector2.new(x - 2, y - 5)
                        objs.HpFill.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 50)
                    else
                        objs.HpBg.Visible = false
                        objs.HpFill.Visible = false
                    end
                    objs.Tracer.Visible = Config.Tracers
                    if Config.Tracers then
                        objs.Tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                        objs.Tracer.To = Vector2.new(sp.X, sp.Y)
                    end
                else
                    -- Hide: beyond max distance
                    objs.Box.Visible = false
                    objs.Name.Visible = false
                    objs.Dist.Visible = false
                    objs.HpBg.Visible = false
                    objs.HpFill.Visible = false
                    objs.Tracer.Visible = false
                end
            else
                -- Hide: no character or dead
                objs.Box.Visible = false
                objs.Name.Visible = false
                objs.Dist.Visible = false
                objs.HpBg.Visible = false
                objs.HpFill.Visible = false
                objs.Tracer.Visible = false
            end
        else
            -- Hide: ESP feature disabled
            objs.Box.Visible = false
            objs.Name.Visible = false
            objs.Dist.Visible = false
            objs.HpBg.Visible = false
            objs.HpFill.Visible = false
            objs.Tracer.Visible = false
        end
    end
end)

-- =============================================
-- FRUIT ESP
-- =============================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.FruitESP then
            local fruits = {}
        local seen = {}

        -- Scan common fruit containers
        for _, containerName in ipairs({"_WorldOrigin", "World", "DroppedFruits"}) do
            local container = Ws:FindFirstChild(containerName)
            if container then
                for _, v in pairs(container:GetChildren()) do
                    if v:IsA("Model") and not seen[v] then
                        seen[v] = true
                        local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            table.insert(fruits, {Model = v, Part = handle, Name = v.Name})
                        end
                    end
                end
            end
        end

        -- If nothing found, scan workspace with keywords
        if #fruits == 0 then
            local keywords = {"fruit", "apple", "bomb", "chop", "diamond", "door", "dough", "flame", "gravity", "ice",
                "kilo", "light", "magma", "pain", "quake", "revive", "rubber", "sand", "shadow", "smoke", "spike",
                "spring", "venom", "dark", "barrier", "blizzard", "buddha", "control", "dragon", "ghost", "human",
                "leopard", "love", "phoenix", "rumble", "soul", "spirit", "string", "trex", "yeti", "gas", "mammoth", "kitsune"}
            for _, v in pairs(Ws:GetDescendants()) do
                if v:IsA("Model") and not seen[v] then
                    seen[v] = true
                    local nm = v.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if nm:find(kw, 1, true)
                            and not nm:find("npc")
                            and not nm:find("boss")
                            and not nm:find("dealer") then
                            local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                            if handle then
                                table.insert(fruits, {Model = v, Part = handle, Name = v.Name})
                                break
                            end
                        end
                    end
                end
            end
        end

        -- Track active fruits
        local active = {}
        for _, f in ipairs(fruits) do
            active[f.Model] = true
            if not FruitP[f.Model] then
                FruitP[f.Model] = {
                    Label = NewDrawing("Text", {Text = "🍎 " .. f.Name, Color = Color3.fromRGB(255, 215, 0), Size = 14, Center = true, Outline = true}),
                    Dist = NewDrawing("Text", {Color = Color3.fromRGB(255, 215, 0), Size = 11, Center = true, Outline = true}),
                    Part = f.Part,
                }
            end
        end

        -- Remove inactive
        for m, objs in pairs(FruitP) do
            if not active[m] then
                objs.Label:Remove()
                objs.Dist:Remove()
                FruitP[m] = nil
            end
        end
    else
        ClearPool(FruitP)
    end
    end
end)

RS.RenderStepped:Connect(function()
    local enabled = Config.FruitESP
    for _, objs in pairs(FruitP) do
        if enabled then
            local p = objs.Part
            if p and p.Parent then
                local sp = Cam:WorldToViewportPoint(p.Position)
                if sp.Z > 0 then
                    local d = GetDistance(p.Position)
                    if d <= Config.MaxDist then
                        objs.Label.Visible = true
                        objs.Label.Position = Vector2.new(sp.X, sp.Y - 26)
                        objs.Dist.Visible = true
                        objs.Dist.Position = Vector2.new(sp.X, sp.Y - 10)
                        objs.Dist.Text = (d >= 1000000 and "∞" or math.floor(d) .. " m")
                    else
                        objs.Label.Visible = false
                        objs.Dist.Visible = false
                    end
                else
                    objs.Label.Visible = false
                    objs.Dist.Visible = false
                end
            else
                objs.Label.Visible = false
                objs.Dist.Visible = false
            end
        else
            objs.Label.Visible = false
            objs.Dist.Visible = false
        end
    end
end)

-- =============================================
-- CLEANUP
-- =============================================
Hub.Destroying:Connect(function()
    StopFly()
    ClearPool(ESPool)
    ClearPool(FruitP)
end)

print("🦖 DOMAIN HUB v5.1 — Loaded! (World " .. (CurrentSea or "?") .. ")")

end) -- end pcall

if not OK then
    warn("🦖 DOMAIN HUB ERROR: " .. tostring(ERR))
    print("🦖 DOMAIN HUB ERROR: " .. tostring(ERR))
end
