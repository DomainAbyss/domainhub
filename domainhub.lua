--[[
    🦖 DOMAIN HUB v3 — BLOX FRUIT (Delta)
    Tab-based UI | Green+Black | ESP + Fly Teleport + World Detect
]]

-- ===== CONFIG =====
local Config = {
    PlayerESP = true, FruitESP  = true, Tracers   = false,
    HealthBar = true, MaxDist   = 999999, FlySpeed  = 250,
    Tab = "ESP", -- "ESP" | "TP" | "SETTINGS"
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
local ESPool   = {}
local FruitP   = {}

-- ===== FLY STATE =====
local flying, flyTarget, bv = false, nil, nil
local function StopFly()
    flying = false; flyTarget = nil
    if bv then pcall(bv.Destroy, bv); bv = nil end
end

-- ===== UTILITY =====
local function NewD(k, o)
    local d = Drawing.new(k)
    for k,v in pairs(o) do pcall(function() d[k]=v end) end
    return d
end
local function ClearP(p)
    for _,v in pairs(p) do pcall(function() v:Remove() end) end
    for k in pairs(p) do p[k]=nil end
end
local function Dist(pos)
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    return r and pos and (r.Position-pos).Magnitude or math.huge
end

-- ===== WORLD DETECT =====
local CurrentSea = nil
local function DetectSea()
    local mk = {
        [3]={"GreatTree","PortTown","HydraIsland","CastleOnTheSea","SeaOfTreats","Tiki"},
        [2]={"KingdomOfRose","Rose","UsoppsIsland","Mansion","Factory","IceCastle","FloatingTurtle"},
        [1]={"MarineTown","MarineStart","PirateStart","Jungle","PirateVillage","Desert","FrozenVillage"},
    }
    for s=3,1,-1 do
        for _,n in ipairs(mk[s]) do
            if Ws:FindFirstChild(n,true) or Ws:FindFirstChild(n:lower(),true) then return s end
        end
    end
    pcall(function()
        local ls=LP:FindFirstChild("leaderstats")
        if ls then
            local lv=ls:FindFirstChild("Level") or ls:FindFirstChild("level")
            if lv then
                if lv.Value>=1500 then CurrentSea=3 elseif lv.Value>=700 then CurrentSea=2 else CurrentSea=1 end
            end
        end
    end)
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r and math.abs(r.Position.X)<20000 then return 1 end
    return nil
end
CurrentSea = DetectSea()

-- ===== ISLAND DB =====
local ISLAND_DB = {
    [1]={ -- First Sea
        {N="🏝 Marine Start",    T="MarineStart"},
        {N="🏝 Pirate Start",    T="PirateStart"},
        {N="🌴 Jungle",          T="Jungle"},
        {N="🏘 Pirate Village",  T="PirateVillage"},
        {N="🏜 Desert",          T="Desert"},
        {N="❄️ Frozen Village",  T="FrozenVillage"},
        {N="🏰 Marine Fortress", T="MarineFortress"},
        {N="☁️ Sky Island",      T="Sky1"},
        {N="⛓ Prison",          T="Prison"},
        {N="🏛 Colosseum",       T="Colosseum"},
        {N="🌋 Magma Village",   T="Magma"},
        {N="🌊 Underwater",      T="Fishman"},
        {N="☁️ Upper Sky",       T="SkyUpper"},
    },
    [2]={ -- Second Sea
        {N="🌹 Kingdom of Rose", T="KingdomOfRose"},
        {N="🎯 Usopp's Island",  T="UsoppsIsland"},
        {N="🍺 Shank's Room",   T="Shank"},
        {N="🏚 Mansion",         T="Mansion"},
        {N="🏭 Factory",         T="Factory"},
        {N="❄️🔥 Hot & Cold",    T="HotAndCold"},
        {N="⛵️ Cursed Ship",    T="CursedShip"},
        {N="🏰 Ice Castle",      T="IceCastle"},
        {N="🐢 Floating Turtle", T="FloatingTurtle"},
    },
    [3]={ -- Third Sea
        {N="🌳 Great Tree",      T="GreatTree"},
        {N="🏯 Castle on Sea",   T="CastleOnTheSea"},
        {N="⚓️ Port Town",      T="PortTown"},
        {N="🐉 Hydra Island",    T="HydraIsland"},
        {N="👻 Haunted Castle",  T="HauntedCastle"},
        {N="🎂 Cake Island",     T="CakeIsland"},
        {N="🥜 Peanut Island",   T="PeanutIsland"},
        {N="🏝 Tiki Island",     T="TikiIsland"},
        {N="🌊 Sea of Treats",   T="SeaTreats"},
    },
}
local ALL_IS = {}
for s=1,3 do for _,v in ipairs(ISLAND_DB[s]) do table.insert(ALL_IS,v) end end

-- ===== FIND ISLAND POSITION (robust) =====
local function FindIslandPos(tag, name)
    local cleanName = name:gsub("[^%w%s]",""):gsub("^%s*(.-)%s*$","%1")
    local patterns = {tag, name, cleanName}

    -- Strategy 1: Find large BasePart with matching name (case insensitive)
    for _,v in pairs(Ws:GetDescendants()) do
        if v:IsA("BasePart") then
            for _,p in ipairs(patterns) do
                if p and #p > 0 then
                    local vn = v.Name:lower()
                    local pn = p:lower()
                    if vn == pn or vn:find(pn,1,true) or pn:find(vn,1,true) then
                        -- Found! Fly above it
                        return v.Position + Vector3.new(0, math.max(v.Size.Y/2, 30) + 10, 0)
                    end
                end
            end
        end
    end

    -- Strategy 2: Find Model with matching name
    for _,v in pairs(Ws:GetDescendants()) do
        if v:IsA("Model") then
            local vn = v.Name:lower()
            for _,p in ipairs(patterns) do
                if p and #p > 0 and (vn == p:lower() or vn:find(p:lower(),1,true)) then
                    local map = v:GetPrimaryPartCFrame()
                    if map then return map.Position + Vector3.new(0, 50, 0) end
                    local big = v:FindFirstChildWhichIsA("BasePart")
                    if big then return big.Position + Vector3.new(0, big.Size.Y/2 + 30, 0) end
                end
            end
        end
    end

    return nil -- not found dynamically
end

-- ===== FLY TO POSITION =====
local function FlyTo(targetPos)
    StopFly()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    flying = true; flyTarget = targetPos

    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0,0,0)
    bv.P = 2500
    bv.Parent = root

    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.FallingDown or new == Enum.HumanoidStateType.Dead then
            StopFly()
        end
    end)

    task.spawn(function()
        while flying and flyTarget and bv and bv.Parent do
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not r then StopFly(); break end
            local d = (flyTarget - r.Position).Magnitude
            if d < 20 then StopFly(); r.CFrame = CFrame.lookAt(r.Position, flyTarget); break end
            local dir = (flyTarget - r.Position).Unit
            bv.Velocity = dir * math.min(Config.FlySpeed, d/2+50)
            r.CFrame = CFrame.lookAt(r.Position, r.Position + dir)
            task.wait(0.03)
        end
        StopFly()
    end)
end

-- ===== INJECTION =====
if CG:FindFirstChild("DomainHub") then
    CG:FindFirstChild("DomainHub"):Destroy()
    ClearP(ESPool); ClearP(FruitP); StopFly()
end
local Hub = Instance.new("ScreenGui")
Hub.Name = "DomainHub"
Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Hub.DisplayOrder = 999
Hub.ResetOnSpawn = false
if gethui then Hub.Parent = gethui()
else Hub.Parent = (cloneref and cloneref(CG)) or CG end

-- =============================================
-- UI COLORS (Green+Black)
-- =============================================
local C = {
    BG       = Color3.fromRGB(10, 10, 18),
    ACCENT   = Color3.fromRGB(0, 200, 80),  -- green
    ACCENT2  = Color3.fromRGB(0, 160, 60),
    SURFACE  = Color3.fromRGB(18, 20, 22),
    TEXT     = Color3.fromRGB(220, 220, 230),
    TEXT_DIM = Color3.fromRGB(140, 140, 150),
    RED      = Color3.fromRGB(220, 60, 60),
    TAB_INACTIVE = Color3.fromRGB(20, 25, 22),
}

-- =============================================
-- BUILD UI
-- =============================================
local MainF, IconBTN, TabContent
local ESPPage, TPPage, SettingsPage

do
    -- MAIN FRAME
    local F = Instance.new("ImageLabel")
    F.Name = "Main"
    F.Size = UDim2.new(0, 350, 0, 460)
    F.Position = UDim2.new(0.5, -175, 0.5, -230)
    F.BackgroundColor3 = C.BG
    F.BackgroundTransparency = 0.03
    F.Image = "rbxassetid://13160433535"
    F.ImageColor3 = C.BG
    F.ScaleType = Enum.ScaleType.Slice
    F.SliceCenter = Rect.new(12,12,12,12)
    F.Active = true; F.Draggable = true
    F.Parent = Hub
    MainF = F
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 12)
    local St = Instance.new("UIStroke", F)
    St.Color = C.ACCENT; St.Thickness = 1.5

    -- HEADER
    local H = Instance.new("TextLabel")
    H.Size = UDim2.new(1,0,0,42)
    H.BackgroundColor3 = C.ACCENT; H.BackgroundTransparency = 0.12
    H.Text = "  🦖 DOMAIN HUB"
    H.TextColor3 = Color3.fromRGB(255,255,255)
    H.TextSize = 18; H.Font = Enum.Font.GothamBold
    H.TextXAlignment = Enum.TextXAlignment.Left
    H.Parent = F
    Instance.new("UICorner", H).CornerRadius = UDim.new(0, 12)

    -- Minimize 🦖
    local MinB = Instance.new("TextButton")
    MinB.Size = UDim2.new(0,30,0,30)
    MinB.Position = UDim2.new(1,-68,0,6)
    MinB.BackgroundTransparency = 1
    MinB.Text = "🦖"
    MinB.TextSize = 16
    MinB.Parent = F
    MinB.MouseButton1Click:Connect(function()
        F.Visible = false
        if IconBTN then IconBTN.Visible = true end
    end)

    -- Close X
    local CloseB = Instance.new("TextButton")
    CloseB.Size = UDim2.new(0,30,0,30)
    CloseB.Position = UDim2.new(1,-36,0,6)
    CloseB.BackgroundTransparency = 1
    CloseB.Text = "✕"
    CloseB.TextColor3 = Color3.fromRGB(255,255,255)
    CloseB.TextSize = 18
    CloseB.Font = Enum.Font.GothamBold
    CloseB.Parent = F
    CloseB.MouseButton1Click:Connect(function()
        ClearP(ESPool); ClearP(FruitP); StopFly()
        Hub:Destroy()
    end)

    -- TAB BAR
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1,-20,0,34)
    TabBar.Position = UDim2.new(0,10,0,48)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = F

    local TabL = Instance.new("UIListLayout")
    TabL.FillDirection = Enum.FillDirection.Horizontal
    TabL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabL.Padding = UDim.new(0,8)
    TabL.SortOrder = Enum.SortOrder.LayoutOrder
    TabL.Parent = TabBar

    local tabs = {}
    local tabData = {
        {Key="ESP", Label="⚔️ ESP"},
        {Key="TP",  Label="🌍 Teleport"},
        {Key="SETTINGS", Label="⚙️ Settings"},
    }

    local function SwitchTab(key)
        Config.Tab = key
        for _,tb in ipairs(tabs) do
            tb.BG.BackgroundColor3 = tb.Key == key and C.ACCENT or C.TAB_INACTIVE
            tb.Line.Visible = tb.Key == key
        end
        if ESPPage then ESPPage.Visible = key == "ESP" end
        if TPPage then TPPage.Visible = key == "TP" end
        if SettingsPage then SettingsPage.Visible = key == "SETTINGS" end
    end

    for _,td in ipairs(tabData) do
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, 100, 0, 30)
        TabBtn.BackgroundColor3 = td.Key == "ESP" and C.ACCENT or C.TAB_INACTIVE
        TabBtn.Text = td.Label
        TabBtn.TextColor3 = Color3.fromRGB(220,220,230)
        TabBtn.TextSize = 13
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.Parent = TabBar
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(0.8,0,0,2)
        Line.Position = UDim2.new(0.1,0,1,-3)
        Line.BackgroundColor3 = C.ACCENT2
        Line.Visible = td.Key == "ESP"
        Line.Parent = TabBtn
        Instance.new("UICorner", Line).CornerRadius = UDim.new(0, 1)

        table.insert(tabs, {Key=td.Key, BG=TabBtn, Line=Line})

        TabBtn.MouseButton1Click:Connect(function() SwitchTab(td.Key) end)
    end

    -- TAB CONTENT container
    TabContent = Instance.new("Frame")
    TabContent.Size = UDim2.new(1,-20,1,-98)
    TabContent.Position = UDim2.new(0,10,0,84)
    TabContent.BackgroundTransparency = 1
    TabContent.Parent = F

    -- =============================================
    -- TAB 1: ESP
    -- =============================================
    do
        local P = Instance.new("ScrollingFrame")
        P.Size = UDim2.new(1,0,1,0)
        P.BackgroundTransparency = 1
        P.ScrollBarThickness = 4
        P.ScrollBarImageColor3 = C.ACCENT
        P.CanvasSize = UDim2.new(0,0,0,0)
        P.Parent = TabContent
        ESPPage = P

        local Lay = Instance.new("UIListLayout", P)
        Lay.Padding = UDim.new(0,8)
        Lay.SortOrder = Enum.SortOrder.LayoutOrder
        Lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            P.CanvasSize = UDim2.new(0,0,0,Lay.AbsoluteContentSize.Y+10)
        end)

        local function Sec(t)
            local L = Instance.new("TextLabel")
            L.Size = UDim2.new(1,0,0,26)
            L.BackgroundTransparency = 1
            L.Text = t
            L.TextColor3 = C.ACCENT
            L.TextSize = 14; L.Font = Enum.Font.GothamBold
            L.TextXAlignment = Enum.TextXAlignment.Left
            L.Parent = P
        end
        local function Tog(label, key, def)
            Config[key] = def
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1,0,0,38)
            Row.BackgroundColor3 = C.SURFACE
            Row.Parent = P
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

            local T = Instance.new("TextLabel")
            T.Size = UDim2.new(1,-54,1,0)
            T.Position = UDim2.new(0,12,0,0)
            T.BackgroundTransparency = 1
            T.Text = label
            T.TextColor3 = C.TEXT
            T.TextSize = 13; T.Font = Enum.Font.Gotham
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.Parent = Row

            local Tok = Instance.new("Frame")
            Tok.Size = UDim2.new(0,44,0,22)
            Tok.Position = UDim2.new(1,-52,0,8)
            Tok.BackgroundColor3 = def and C.ACCENT or Color3.fromRGB(60,60,70)
            Tok.Parent = Row
            Instance.new("UICorner", Tok).CornerRadius = UDim.new(0, 11)

            local Kn = Instance.new("Frame")
            Kn.Size = UDim2.new(0,18,0,18)
            Kn.Position = def and UDim2.new(1,-20,0,2) or UDim2.new(0,2,0,2)
            Kn.BackgroundColor3 = Color3.fromRGB(255,255,255)
            Kn.Parent = Tok
            Instance.new("UICorner", Kn).CornerRadius = UDim.new(0, 9)

            local B = Instance.new("TextButton")
            B.Size = UDim2.new(1,0,1,0)
            B.BackgroundTransparency = 1; B.Text = ""
            B.Parent = Row

            local st = def
            B.MouseButton1Click:Connect(function()
                st = not st; Config[key] = st
                Tok.BackgroundColor3 = st and C.ACCENT or Color3.fromRGB(60,60,70)
                Kn:TweenPosition(
                    st and UDim2.new(1,-20,0,2) or UDim2.new(0,2,0,2),
                    Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true
                )
                if not st then
                    if key=="PlayerESP" then ClearP(ESPool)
                    elseif key=="FruitESP" then ClearP(FruitP) end
                end
            end)
        end

        Sec("⚔️ PLAYER ESP")
        Tog("Player ESP", "PlayerESP", true)
        Tog("Tracers", "Tracers", false)
        Tog("Health Bar", "HealthBar", true)

        Sec("🍎 FRUIT ESP")
        Tog("Fruit ESP", "FruitESP", true)
    end

    -- =============================================
    -- TAB 2: TELEPORT
    -- =============================================
    do
        local P = Instance.new("ScrollingFrame")
        P.Size = UDim2.new(1,0,1,0)
        P.BackgroundTransparency = 1
        P.ScrollBarThickness = 4
        P.ScrollBarImageColor3 = C.ACCENT
        P.CanvasSize = UDim2.new(0,0,0,0)
        P.Parent = TabContent
        TPPage = P

        local Lay = Instance.new("UIListLayout", P)
        Lay.Padding = UDim.new(0,6)
        Lay.SortOrder = Enum.SortOrder.LayoutOrder
        Lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            P.CanvasSize = UDim2.new(0,0,0,Lay.AbsoluteContentSize.Y+10)
        end)

        -- Sea indicator
        local SeaL = Instance.new("TextLabel")
        SeaL.Size = UDim2.new(1,0,0,22)
        SeaL.BackgroundTransparency = 1
        SeaL.Text = CurrentSea and "📍 World "..CurrentSea.." detected" or "📍 Auto-detect: scanning..."
        SeaL.TextColor3 = Color3.fromRGB(100,200,255)
        SeaL.TextSize = 12; SeaL.Font = Enum.Font.Gotham
        SeaL.Parent = P

        -- Sea tabs
        local STabRow = Instance.new("Frame")
        STabRow.Size = UDim2.new(1,0,0,32)
        STabRow.BackgroundTransparency = 1
        STabRow.Parent = P
        local STL = Instance.new("UIListLayout", STabRow)
        STL.FillDirection = Enum.FillDirection.Horizontal
        STL.HorizontalAlignment = Enum.HorizontalAlignment.Center
        STL.Padding = UDim.new(0,6)

        local seaView = CurrentSea or 0
        local stabs = {}
        local sdata = {{V=0,L="🗺 All"},{V=1,L="🌊 1st"},{V=2,L="🌊 2nd"},{V=3,L="🌊 3rd"}}

        local seaTabsRow = STabRow
        -- Destination label + status
        local DestLabel = Instance.new("TextLabel")
        DestLabel.Size = UDim2.new(1,0,0,24)
        DestLabel.BackgroundTransparency = 1
        DestLabel.Text = "🌍 Select destination..."
        DestLabel.TextColor3 = C.TEXT
        DestLabel.TextSize = 14; DestLabel.Font = Enum.Font.GothamBold
        DestLabel.Parent = P

        local StatusL = Instance.new("TextLabel")
        StatusL.Size = UDim2.new(1,0,0,18)
        StatusL.BackgroundTransparency = 1
        StatusL.Text = ""
        StatusL.TextColor3 = Color3.fromRGB(100,200,255)
        StatusL.TextSize = 11; StatusL.Font = Enum.Font.Gotham
        StatusL.Parent = P

        -- Speed row
        local SpdR = Instance.new("Frame")
        SpdR.Size = UDim2.new(1,0,0,30)
        SpdR.BackgroundTransparency = 1
        SpdR.Parent = P
        local SpdT = Instance.new("TextLabel")
        SpdT.Size = UDim2.new(0.5,-4,1,0)
        SpdT.BackgroundTransparency = 1
        SpdT.Text = "✈️ Fly Speed:"
        SpdT.TextColor3 = C.TEXT
        SpdT.TextSize = 13; SpdT.Font = Enum.Font.Gotham
        SpdT.TextXAlignment = Enum.TextXAlignment.Left
        SpdT.Parent = SpdR
        local SpdV = Instance.new("TextBox")
        SpdV.Size = UDim2.new(0.5,-4,1,0)
        SpdV.Position = UDim2.new(0.5,4,0,0)
        SpdV.BackgroundColor3 = C.SURFACE
        SpdV.Text = tostring(Config.FlySpeed)
        SpdV.TextColor3 = Color3.fromRGB(255,255,255)
        SpdV.TextSize = 13; SpdV.Font = Enum.Font.GothamBold
        SpdV.TextXAlignment = Enum.TextXAlignment.Center
        SpdV.Parent = SpdR
        Instance.new("UICorner", SpdV).CornerRadius = UDim.new(0, 6)
        SpdV.FocusLost:Connect(function()
            local n = tonumber(SpdV.Text)
            Config.FlySpeed = n and math.clamp(n,50,2000) or 250
            SpdV.Text = tostring(Config.FlySpeed)
        end)

        -- Stop button
        local StopB = Instance.new("TextButton")
        StopB.Size = UDim2.new(1,0,0,30)
        StopB.BackgroundColor3 = C.RED
        StopB.Text = "⏹ STOP FLYING"
        StopB.TextColor3 = Color3.fromRGB(255,255,255)
        StopB.TextSize = 13; StopB.Font = Enum.Font.GothamBold
        StopB.Parent = P
        Instance.new("UICorner", StopB).CornerRadius = UDim.new(0, 8)
        StopB.Visible = false
        StopB.MouseButton1Click:Connect(function()
            StopFly(); StopB.Visible = false
            DestLabel.Text = "🌍 Select destination..."
            StatusL.Text = ""
        end)

        -- Island list container
        local IsCont = Instance.new("Frame")
        IsCont.Size = UDim2.new(1,0,0,0)
        IsCont.BackgroundTransparency = 1
        IsCont.ClipsDescendants = false
        IsCont.Parent = P
        local IsLay = Instance.new("UIListLayout", IsCont)
        IsLay.Padding = UDim.new(0,4)
        IsLay.SortOrder = Enum.SortOrder.LayoutOrder

        local function BuildIslandList()
            for _,c in pairs(IsCont:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            local islands = (seaView==0 and ALL_IS) or ISLAND_DB[seaView] or {}
            IsCont.Size = UDim2.new(1,0,0,#islands*33+4)

            for _,is in ipairs(islands) do
                local B = Instance.new("TextButton")
                B.Size = UDim2.new(1,0,0,30)
                B.BackgroundColor3 = C.SURFACE
                B.Text = is.N
                B.TextColor3 = C.TEXT
                B.TextSize = 12; B.Font = Enum.Font.Gotham
                B.TextXAlignment = Enum.TextXAlignment.Left
                B.Parent = IsCont
                Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)

                B.MouseEnter:Connect(function()
                    B.BackgroundColor3 = Color3.fromRGB(30,40,35)
                end)
                B.MouseLeave:Connect(function()
                    B.BackgroundColor3 = C.SURFACE
                end)

                B.MouseButton1Click:Connect(function()
                    DestLabel.Text = "✈ "..is.N.."..."
                    StatusL.Text = "🔍 Locating island..."

                    local pos = FindIslandPos(is.T, is.N)
                    if pos then
                        FlyTo(pos)
                        StopB.Visible = true
                        DestLabel.Text = "✈ "..is.N
                        StatusL.Text = "✅ Flying to "..is.N
                    else
                        -- Fallback: fly up + in a direction
                        StatusL.Text = "⚠ Island not found in workspace, trying estimated area..."
                        local char = LP.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then
                            -- Fly upward + in a direction based on island index
                            local angle = (#islands > 0 and (#islands * 0.5) or 1) % 8
                            local dirs = {
                                Vector3.new(1,0.5,0).Unit, Vector3.new(0,0.5,1).Unit,
                                Vector3.new(-1,0.5,0).Unit, Vector3.new(0,0.5,-1).Unit,
                                Vector3.new(1,0.5,1).Unit, Vector3.new(-1,0.5,1).Unit,
                                Vector3.new(1,0.5,-1).Unit, Vector3.new(-1,0.5,-1).Unit,
                            }
                            local idx = math.floor(#islands) % 8 + 1
                            local fallbackPos = root.Position + dirs[idx] * 3000
                            fallbackPos = fallbackPos + Vector3.new(0, 500, 0)
                            DestLabel.Text = "✈ "..is.N.." (est)"
                            FlyTo(fallbackPos)
                            StopB.Visible = true
                            StatusL.Text = "📍 Flying to estimated area..."
                        else
                            StatusL.Text = "❌ Can't fly: no character found"
                            DestLabel.Text = "🌍 "..is.N
                        end
                    end
                end)
            end
        end

        -- Sea tab buttons — clean implementation (no nested recursion)
        local function RefreshSeaTabs()
            for _,tb in ipairs(stabs) do
                tb.BackgroundColor3 = (seaView==tb._V) and C.ACCENT or C.TAB_INACTIVE
            end
        end

        for _,sd in ipairs(sdata) do
            local TB = Instance.new("TextButton")
            TB.Size = UDim2.new(0,78,0,28)
            TB.BackgroundColor3 = (seaView==sd.V) and C.ACCENT or C.TAB_INACTIVE
            TB.Text = sd.L
            TB.TextColor3 = C.TEXT
            TB.TextSize = 12; TB.Font = Enum.Font.GothamBold
            TB.Parent = seaTabsRow
            TB._V = sd.V -- store the value on the instance
            Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 6)
            TB.MouseButton1Click:Connect(function()
                seaView = sd.V
                RefreshSeaTabs()
                BuildIslandList()
            end)
            table.insert(stabs, TB)
        end

        BuildIslandList()

        -- Fly status updater
        task.spawn(function()
            while task.wait(0.2) do
                if flying and flyTarget then
                    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        StatusL.Text = "✈ Flying... "..math.floor((flyTarget-r.Position).Magnitude).." m left"
                    end
                elseif not flying and StopB.Visible then
                    StopB.Visible = false
                    DestLabel.Text = "🌍 Select destination..."
                    StatusL.Text = ""
                end
            end
        end)
    end

    -- =============================================
    -- TAB 3: SETTINGS
    -- =============================================
    do
        local P = Instance.new("ScrollingFrame")
        P.Size = UDim2.new(1,0,1,0)
        P.BackgroundTransparency = 1
        P.ScrollBarThickness = 4
        P.ScrollBarImageColor3 = C.ACCENT
        P.CanvasSize = UDim2.new(0,0,0,0)
        P.Parent = TabContent
        SettingsPage = P

        local Lay = Instance.new("UIListLayout", P)
        Lay.Padding = UDim.new(0,8)
        Lay.SortOrder = Enum.SortOrder.LayoutOrder
        Lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            P.CanvasSize = UDim2.new(0,0,0,Lay.AbsoluteContentSize.Y+10)
        end)

        local function Sec(t)
            local L=Instance.new("TextLabel")
            L.Size=UDim2.new(1,0,0,26); L.BackgroundTransparency=1
            L.Text=t; L.TextColor3=C.ACCENT
            L.TextSize=14; L.Font=Enum.Font.GothamBold
            L.TextXAlignment=Enum.TextXAlignment.Left
            L.Parent=P
        end

        Sec("📏 MAX DISTANCE")
        do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1,0,0,42)
            Row.BackgroundColor3 = C.SURFACE
            Row.Parent = P
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

            local T = Instance.new("TextLabel")
            T.Size = UDim2.new(1,0,0,18)
            T.Position = UDim2.new(0,12,0,4)
            T.BackgroundTransparency = 1
            T.Text = "Max Distance"
            T.TextColor3 = C.TEXT; T.TextSize=12; T.Font=Enum.Font.Gotham
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.Parent = Row

            local Val = Instance.new("TextLabel")
            Val.Size = UDim2.new(1,0,0,16)
            Val.Position = UDim2.new(0,12,0,22)
            Val.BackgroundTransparency = 1
            Val.Text = "∞"
            Val.TextColor3 = C.ACCENT; Val.TextSize=11; Val.Font=Enum.Font.Gotham
            Val.TextXAlignment = Enum.TextXAlignment.Left
            Val.Parent = Row

            local SBg = Instance.new("Frame")
            SBg.Size = UDim2.new(0,140,0,5)
            SBg.Position = UDim2.new(1,-152,0,18)
            SBg.BackgroundColor3 = Color3.fromRGB(60,60,70)
            SBg.Parent = Row
            Instance.new("UICorner", SBg).CornerRadius = UDim.new(0, 2)

            local SFi = Instance.new("Frame")
            SFi.Size = UDim2.new(0.95,0,1,0)
            SFi.BackgroundColor3 = C.ACCENT
            SFi.Parent = SBg
            Instance.new("UICorner", SFi).CornerRadius = UDim.new(0, 2)

            local SB = Instance.new("TextButton")
            SB.Size = UDim2.new(1,0,1,0)
            SB.BackgroundTransparency = 1; SB.Text = ""
            SB.Parent = Row

            local smin, smax = 50000, 1000000
            local drag = false
            SB.MouseButton1Down:Connect(function() drag = true end)
            UIS.InputEnded:Connect(function(io)
                if io.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
            UIS.InputChanged:Connect(function(io)
                if io.UserInputType == Enum.UserInputType.MouseMovement and drag then
                    local mx = UIS:GetMouseLocation().X
                    local ax = SBg.AbsolutePosition.X
                    local aw = SBg.AbsoluteSize.X
                    local r = math.clamp((mx-ax)/aw,0,1)
                    Config.MaxDist = math.floor(smin + (smax-smin)*r)
                    Val.Text = Config.MaxDist >= 1000000 and "∞" or tostring(Config.MaxDist)
                    SFi.Size = UDim2.new(r,0,1,0)
                end
            end)
        end

        Sec("✈️ FLY SPEED")
        do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1,0,0,38)
            Row.BackgroundColor3 = C.SURFACE
            Row.Parent = P
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

            local T = Instance.new("TextLabel")
            T.Size = UDim2.new(0.6,-8,1,0)
            T.Position = UDim2.new(0,12,0,0)
            T.BackgroundTransparency = 1
            T.Text = "✈️ Fly Speed"
            T.TextColor3 = C.TEXT; T.TextSize=13; T.Font=Enum.Font.Gotham
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.Parent = Row

            local Inp = Instance.new("TextBox")
            Inp.Size = UDim2.new(0.35,-8,0,28)
            Inp.Position = UDim2.new(0.62,0,0,5)
            Inp.BackgroundColor3 = Color3.fromRGB(25,30,28)
            Inp.Text = tostring(Config.FlySpeed)
            Inp.TextColor3 = Color3.fromRGB(255,255,255)
            Inp.TextSize = 13; Inp.Font = Enum.Font.GothamBold
            Inp.TextXAlignment = Enum.TextXAlignment.Center
            Inp.Parent = Row
            Instance.new("UICorner", Inp).CornerRadius = UDim.new(0, 6)
            Inp.FocusLost:Connect(function()
                local n = tonumber(Inp.Text)
                Config.FlySpeed = n and math.clamp(n,50,2000) or 250
                Inp.Text = tostring(Config.FlySpeed)
            end)
        end

        Sec("🛡️ ABOUT")
        do
            local L = Instance.new("TextLabel")
            L.Size = UDim2.new(1,0,0,40)
            L.BackgroundColor3 = C.SURFACE
            L.Parent = P
            Instance.new("UICorner", L).CornerRadius = UDim.new(0, 8)
            L.Text = "🦖 DOMAIN HUB v3\nESP + Fly TP + World Detect"
            L.TextColor3 = C.TEXT_DIM
            L.TextSize = 12; L.Font = Enum.Font.Gotham
        end
    end

    -- Show default tab
    SwitchTab("ESP")
end

-- =============================================
-- ICON BUTTON (minimized 🦖)
-- =============================================
do
    local I = Instance.new("TextButton")
    I.Name = "Icon"
    I.Size = UDim2.new(0, 50, 0, 50)
    I.Position = UDim2.new(0, 20, 0.5, -25)
    I.BackgroundColor3 = C.ACCENT
    I.Text = "🦖"
    I.TextSize = 24
    I.TextColor3 = Color3.fromRGB(255,255,255)
    I.Active = true; I.Draggable = true
    I.Visible = false
    I.Parent = Hub
    IconBTN = I
    Instance.new("UICorner", I).CornerRadius = UDim.new(0, 14)
    local IS = Instance.new("UIStroke", I)
    IS.Color = C.ACCENT2; IS.Thickness = 2
    I.MouseButton1Click:Connect(function()
        I.Visible = false
        if MainF then MainF.Visible = true end
    end)
end

-- =============================================
-- NOTIFICATION
-- =============================================
do
    local N = Instance.new("Frame")
    N.Size = UDim2.new(0, 320, 0, 40)
    N.Position = UDim2.new(0.5, -160, 0, 20)
    N.BackgroundColor3 = C.BG
    N.Parent = Hub
    Instance.new("UICorner", N).CornerRadius = UDim.new(0, 10)
    local NS = Instance.new("UIStroke", N)
    NS.Color = C.ACCENT; NS.Thickness = 1
    local NT = Instance.new("TextLabel")
    NT.Size = UDim2.new(1,-20,1,0)
    NT.Position = UDim2.new(0,10,0,0)
    NT.BackgroundTransparency = 1
    NT.Text = "🦖 DOMAIN HUB — World "..(CurrentSea or "?")
    NT.TextColor3 = Color3.fromRGB(255,255,255)
    NT.TextSize = 13; NT.Font = Enum.Font.Gotham
    NT.Parent = N
    task.delay(3, function()
        TS:Create(N, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}):Play()
        task.delay(0.5, N.Destroy, N)
    end)
end

-- =============================================
-- PLAYER ESP
-- =============================================
local tick = 0; local plrL = {}
RS.RenderStepped:Connect(function()
    tick = tick + 1
    if tick >= 30 then tick = 0; plrL = Players:GetPlayers() end

    if Config.PlayerESP then
        local act = {}
        for _,p in pairs(plrL) do if p~=LP then
            act[p]=true
            if not ESPool[p] then
                ESPool[p]={
                    Bx=NewD("Square",{Thickness=1,Color=Config.BoxColor or C.ACCENT,Filled=false}),
                    Nm=NewD("Text",{Color=C.TEXT,Size=14,Center=true,Outline=true}),
                    Ds=NewD("Text",{Color=Color3.fromRGB(200,200,200),Size=11,Center=true,Outline=true}),
                    Hb=NewD("Square",{Color=Color3.fromRGB(40,40,40),Filled=true}),
                    Hf=NewD("Square",{Color=Color3.fromRGB(0,200,80),Filled=true}),
                    Tr=NewD("Line",{Color=C.ACCENT,Thickness=1}),
                }
            end
        end end
        for p,s in pairs(ESPool) do if not act[p] then
            s.Bx:Remove();s.Nm:Remove();s.Ds:Remove();s.Hb:Remove();s.Hf:Remove();s.Tr:Remove()
            ESPool[p]=nil
        end end
    end

    for _,s in pairs(ESPool) do
        if not Config.PlayerESP then
            s.Bx.Visible=false;s.Nm.Visible=false;s.Ds.Visible=false
            s.Hb.Visible=false;s.Hf.Visible=false;s.Tr.Visible=false;continue
        end
        local plr = nil; for k in pairs(ESPool) do if ESPool[k]==s then plr=k;break end end
        if not plr then continue end
        local c = plr.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChild("Humanoid")
        if r and h and h.Health>0 then
            local d = Dist(r.Position)
            if d <= Config.MaxDist then
                local sp=Cam:WorldToViewportPoint(r.Position)
                local spH=Cam:WorldToViewportPoint(r.Position+Vector3.new(0,4.5,0))
                local spF=Cam:WorldToViewportPoint(r.Position-Vector3.new(0,2.5,0))
                local hgt=math.abs(spH.Y-spF.Y); local w=hgt*0.7
                local x=sp.X-w/2; local y=spH.Y
                s.Bx.Visible=true;s.Bx.Size=Vector2.new(w,hgt);s.Bx.Position=Vector2.new(x,y)
                s.Bx.Color = C.ACCENT
                s.Nm.Visible=true;s.Nm.Position=Vector2.new(sp.X,spH.Y-18);s.Nm.Text=plr.Name
                local dc = d<500 and Color3.fromRGB(0,255,100) or d<50000 and Color3.fromRGB(255,200,50) or C.RED
                s.Ds.Visible=true;s.Ds.Position=Vector2.new(sp.X,spF.Y+4)
                s.Ds.Text = d>=1000000 and "∞" or math.floor(d).." m"
                s.Ds.Color=dc
                if Config.HealthBar then
                    local hp=h.Health/h.MaxHealth
                    s.Hb.Visible=true;s.Hb.Size=Vector2.new(w+4,3);s.Hb.Position=Vector2.new(x-2,y-5)
                    s.Hf.Visible=true;s.Hf.Size=Vector2.new((w+4)*hp,3);s.Hf.Position=Vector2.new(x-2,y-5)
                    s.Hf.Color=Color3.fromRGB(255*(1-hp),255*hp,50)
                else s.Hb.Visible=false;s.Hf.Visible=false end
                s.Tr.Visible=Config.Tracers
                if Config.Tracers then
                    s.Tr.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y);s.Tr.To=Vector2.new(sp.X,sp.Y)
                end
            else s.Bx.Visible=false;s.Nm.Visible=false;s.Ds.Visible=false
                s.Hb.Visible=false;s.Hf.Visible=false;s.Tr.Visible=false end
        else s.Bx.Visible=false;s.Nm.Visible=false;s.Ds.Visible=false
            s.Hb.Visible=false;s.Hf.Visible=false;s.Tr.Visible=false end
    end
end)

-- =============================================
-- FRUIT ESP
-- =============================================
task.spawn(function()
    while task.wait(0.5) do
        if not Config.FruitESP then ClearP(FruitP); continue end
        local fr={}; local ch={}
        for _,n in ipairs({"_WorldOrigin","World","DroppedFruits"}) do
            local c=Ws:FindFirstChild(n)
            if c then for _,v in pairs(c:GetChildren()) do
                if v:IsA("Model") and not ch[v] then
                    ch[v]=true
                    local hd=v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                    if hd then table.insert(fr,{M=v,P=hd,N=v.Name}) end
                end
            end end
        end
        if #fr==0 then
            local kw={"fruit","apple","bomb","chop","diamond","door","dough","flame","gravity","ice","kilo","light","magma","pain","quake","revive","rubber","sand","shadow","smoke","spike","spring","venom","dark","barrier","blizzard","buddha","control","dragon","ghost","human","leopard","love","phoenix","rumble","soul","spirit","string","trex","yeti","gas","mammoth","kitsune"}
            for _,v in pairs(Ws:GetDescendants()) do
                if v:IsA("Model") and not ch[v] then
                    ch[v]=true; local nm=v.Name:lower()
                    for _,k in ipairs(kw) do
                        if nm:find(k,1,true) and not nm:find("npc") and not nm:find("boss") then
                            local hd=v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                            if hd then table.insert(fr,{M=v,P=hd,N=v.Name});break end
                        end
                    end
                end
            end
        end
        local act={}
        for _,f in pairs(fr) do
            act[f.M]=true
            if not FruitP[f.M] then
                FruitP[f.M]={
                    Lb=NewD("Text",{Text="🍎 "..f.N,Color=Color3.fromRGB(255,215,0),Size=14,Center=true,Outline=true}),
                    Dt=NewD("Text",{Color=Color3.fromRGB(255,215,0),Size=11,Center=true,Outline=true}),
                    Pt=f.P,
                }
            end
        end
        for k,s in pairs(FruitP) do if not act[k] then s.Lb:Remove();s.Dt:Remove();FruitP[k]=nil end end
    end
end)

RS.RenderStepped:Connect(function()
    local sh = Config.FruitESP
    for _,s in pairs(FruitP) do
        if not sh then s.Lb.Visible=false;s.Dt.Visible=false;continue end
        local p=s.Pt
        if p and p.Parent then
            local sp=Cam:WorldToViewportPoint(p.Position)
            if sp.Z>0 then
                local d=Dist(p.Position)
                if d<=Config.MaxDist then
                    s.Lb.Visible=true;s.Lb.Position=Vector2.new(sp.X,sp.Y-26)
                    s.Dt.Visible=true;s.Dt.Position=Vector2.new(sp.X,sp.Y-10)
                    s.Dt.Text = d>=1000000 and "∞" or math.floor(d).." m"
                else s.Lb.Visible=false;s.Dt.Visible=false end
            else s.Lb.Visible=false;s.Dt.Visible=false end
        else s.Lb.Visible=false;s.Dt.Visible=false end
    end
end)

-- ===== CLEANUP =====
Hub.Destroying:Connect(function() StopFly(); ClearP(ESPool); ClearP(FruitP) end)
print("🦖 DOMAIN HUB v3 — Loaded! (World "..(CurrentSea or "?")..")")
