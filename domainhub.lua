--[[
    🔥 ADIT'S HUB — BLOX FRUIT
    Player ESP + Fruit ESP
    Loadstring: loadstring(game:HttpGet("raw_url_here"))()
]]

-- ===== CONFIG =====
local Config = {
    PlayerESP = true,
    FruitESP  = true,
    Tracers   = false,
    MaxDist   = 5000,
    BoxColor  = Color3.fromRGB(255, 80, 80),
    TextColor = Color3.fromRGB(255, 255, 255),
    FruitCol  = Color3.fromRGB(255, 215, 0),
    TracerCol = Color3.fromRGB(255, 255, 255),
}

-- ===== SERVICES =====
local Players   = game:GetService("Players")
local Ws        = game:GetService("Workspace")
local RS        = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local CG        = game:GetService("CoreGui")
local TS        = game:GetService("TweenService")
local LP        = Players.LocalPlayer
local Cam       = Ws.CurrentCamera

-- ===== INJECT GUARD =====
if CG:FindFirstChild("AditsHub") then
    CG:FindFirstChild("AditsHub"):Destroy()
    for _, v in pairs(ESPPool) do v:Remove() end
    for _, v in pairs(FruitPool) do v:Remove() end
end
local Hub = Instance.new("ScreenGui")
Hub.Name = "AditsHub"
Hub.Parent = (syn and syn.protect_gui and (syn.protect_gui(Hub) or Hub:SetAttribute("Protected", true))) and CG or
             (gethui and gethui()) and Hub.Parent == nil and (Hub.Parent = gethui()) or CG
Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Hub.DisplayOrder = 999

-- ===== DRAWING POOLS =====
local ESPPool   = {}
local FruitPool = {}

-- ===== UTILITY =====
local function NewDrawing(kind, opts)
    local d = Drawing.new(kind)
    for k, v in pairs(opts) do
        pcall(function() d[k] = v end)
    end
    return d
end

local function ClearPool(pool)
    for _, v in pairs(pool) do
        pcall(function() v:Remove() end)
    end
    table.clear(pool)
end

local function GetDist(pos)
    local mp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if mp and pos then return (mp.Position - pos).Magnitude end
    return math.huge
end

-- ===== BUILD UI =====
do
    -- Main Frame
    local F = Instance.new("ImageLabel")
    F.Name = "Main"
    F.Size = UDim2.new(0, 280, 0, 360)
    F.Position = UDim2.new(0.5, -140, 0.5, -180)
    F.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    F.BackgroundTransparency = 0.05
    F.Image = "rbxassetid://13160433535"
    F.ImageColor3 = Color3.fromRGB(15, 15, 25)
    F.ScaleType = Enum.ScaleType.Slice
    F.SliceCenter = Rect.new(12, 12, 12, 12)
    F.Active = true
    F.Draggable = true
    F.Parent = Hub

    -- Corner
    local UC = Instance.new("UICorner")
    UC.CornerRadius = UDim.new(0, 10)
    UC.Parent = F

    -- Stroke
    local St = Instance.new("UIStroke")
    St.Color = Color3.fromRGB(255, 80, 80)
    St.Thickness = 1.5
    St.Parent = F

    -- Header
    local H = Instance.new("TextLabel")
    H.Size = UDim2.new(1, 0, 0, 40)
    H.Position = UDim2.new(0, 0, 0, 0)
    H.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    H.BackgroundTransparency = 0.15
    H.Text = "🔥 ADIT'S HUB"
    H.TextColor3 = Color3.fromRGB(255, 255, 255)
    H.TextSize = 18
    H.Font = Enum.Font.GothamBold
    H.Parent = F
    -- header corner
    local HUC = Instance.new("UICorner")
    HUC.CornerRadius = UDim.new(0, 10)
    HUC.Parent = H
    -- clip header top corners only
    local Clp = Instance.new("UIClip")
    Clp.Parent = H

    -- Minimize btn
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -34, 0, 6)
    MinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.BackgroundTransparency = 0.9
    MinBtn.Text = "−"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.TextSize = 18
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = F
    MinBtn.MouseButton1Click:Connect(function()
        F.Visible = not F.Visible
        MinBtn.Text = F.Visible and "−" or "+"
    end)

    -- Content area
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, -20, 1, -55)
    Content.Position = UDim2.new(0, 10, 0, 45)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(255, 80, 80)
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Parent = F

    -- Auto layout
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Content
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
    end)

    -- Helper: Section header
    local function AddSection(text)
        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, 0, 0, 24)
        L.BackgroundTransparency = 1
        L.Text = text
        L.TextColor3 = Color3.fromRGB(255, 120, 120)
        L.TextSize = 13
        L.Font = Enum.Font.GothamBold
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = Content
        return L
    end

    -- Helper: Toggle row
    local function AddToggle(label, key, default)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 34)
        Row.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        Row.BackgroundTransparency = 0.3
        Row.Parent = Content
        local RUC = Instance.new("UICorner")
        RUC.CornerRadius = UDim.new(0, 6)
        RUC.Parent = Row

        local Txt = Instance.new("TextLabel")
        Txt.Size = UDim2.new(1, -50, 1, 0)
        Txt.Position = UDim2.new(0, 10, 0, 0)
        Txt.BackgroundTransparency = 1
        Txt.Text = label
        Txt.TextColor3 = Color3.fromRGB(220, 220, 230)
        Txt.TextSize = 13
        Txt.Font = Enum.Font.Gotham
        Txt.TextXAlignment = Enum.TextXAlignment.Left
        Txt.Parent = Row

        local Tok = Instance.new("Frame")
        Tok.Name = "Toggle"
        Tok.Size = UDim2.new(0, 40, 0, 20)
        Tok.Position = UDim2.new(1, -48, 0, 7)
        Tok.BackgroundColor3 = default and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(60, 60, 70)
        Tok.Parent = Row
        local TokUC = Instance.new("UICorner")
        TokUC.CornerRadius = UDim.new(0, 10)
        TokUC.Parent = Tok

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.Parent = Tok
        local KUC = Instance.new("UICorner")
        KUC.CornerRadius = UDim.new(0, 8)
        KUC.Parent = Knob

        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, 0, 1, 0)
        Btn.BackgroundTransparency = 1
        Btn.Text = ""
        Btn.Parent = Row

        local state = default
        Btn.MouseButton1Click:Connect(function()
            state = not state
            Config[key] = state
            Tok.BackgroundColor3 = state and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(60, 60, 70)
            Knob:TweenPosition(
                state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
                Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true
            )
            if not state then
                if key == "PlayerESP" then ClearPool(ESPPool)
                elseif key == "FruitESP" then ClearPool(FruitPool) end
            end
        end)

        return Row
    end

    -- Helper: Slider
    local function AddSlider(label, key, min, max, default)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 34)
        Row.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        Row.BackgroundTransparency = 0.3
        Row.Parent = Content
        local RUC = Instance.new("UICorner")
        RUC.CornerRadius = UDim.new(0, 6)
        RUC.Parent = Row

        local Txt = Instance.new("TextLabel")
        Txt.Size = UDim2.new(1, -50, 0, 16)
        Txt.Position = UDim2.new(0, 10, 0, 2)
        Txt.BackgroundTransparency = 1
        Txt.Text = label
        Txt.TextColor3 = Color3.fromRGB(220, 220, 230)
        Txt.TextSize = 12
        Txt.Font = Enum.Font.Gotham
        Txt.TextXAlignment = Enum.TextXAlignment.Left
        Txt.Parent = Row

        local Val = Instance.new("TextLabel")
        Val.Size = UDim2.new(1, -50, 0, 14)
        Val.Position = UDim2.new(0, 10, 0, 18)
        Val.BackgroundTransparency = 1
        Val.Text = tostring(default)
        Val.TextColor3 = Color3.fromRGB(255, 120, 120)
        Val.TextSize = 11
        Val.Font = Enum.Font.Gotham
        Val.TextXAlignment = Enum.TextXAlignment.Left
        Val.Parent = Row

        local SliderBg = Instance.new("Frame")
        SliderBg.Size = UDim2.new(0, 80, 0, 4)
        SliderBg.Position = UDim2.new(1, -92, 0, 15)
        SliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        SliderBg.Parent = Row
        local SBUC = Instance.new("UICorner")
        SBUC.CornerRadius = UDim.new(0, 2)
        SBUC.Parent = SliderBg

        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
        SliderFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        SliderFill.Parent = SliderBg
        local SFUC = Instance.new("UICorner")
        SFUC.CornerRadius = UDim.new(0, 2)
        SFUC.Parent = SliderFill

        local SliderBtn = Instance.new("TextButton")
        SliderBtn.Size = UDim2.new(1, 0, 1, 0)
        SliderBtn.BackgroundTransparency = 1
        SliderBtn.Text = ""
        SliderBtn.Parent = Row

        local dragging = false
        SliderBtn.MouseButton1Down:Connect(function()
            dragging = true
        end)
        UIS.InputEnded:Connect(function(io)
            if io.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(io)
            if io.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local mx, my = UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y
                local absPos = SliderBg.AbsolutePosition
                local absSize = SliderBg.AbsoluteSize
                local relX = math.clamp((mx - absPos.X) / absSize.X, 0, 1)
                local val = math.floor(min + (max - min) * relX)
                Config[key] = val
                Val.Text = tostring(val)
                SliderFill.Size = UDim2.new(relX, 0, 1, 0)
            end
        end)
    end

    -- === Build Toggles ===
    AddSection("⚔️ PLAYER ESP")
    AddToggle("Player ESP", "PlayerESP", true)
    AddToggle("Tracers", "Tracers", false)
    AddToggle("Health Bar", "HealthBar", true)

    AddSection("🍎 FRUIT ESP")
    AddToggle("Fruit ESP", "FruitESP", true)

    AddSection("⚙️ SETTINGS")
    AddSlider("Max Distance", "MaxDist", 1000, 10000, 5000)
end

-- ===== NOTIFICATION =====
do
    local N = Instance.new("Frame")
    N.Size = UDim2.new(0, 260, 0, 38)
    N.Position = UDim2.new(0.5, -130, 0, 20)
    N.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    N.BackgroundTransparency = 0.1
    N.Parent = Hub
    local NUC = Instance.new("UICorner")
    NUC.CornerRadius = UDim.new(0, 8)
    NUC.Parent = N
    local NS = Instance.new("UIStroke")
    NS.Color = Color3.fromRGB(255, 80, 80)
    NS.Thickness = 1
    NS.Parent = N
    local NT = Instance.new("TextLabel")
    NT.Size = UDim2.new(1, -20, 1, 0)
    NT.Position = UDim2.new(0, 10, 0, 0)
    NT.BackgroundTransparency = 1
    NT.Text = "🔥 ADIT'S HUB loaded successfully!"
    NT.TextColor3 = Color3.fromRGB(255, 255, 255)
    NT.TextSize = 13
    NT.Font = Enum.Font.Gotham
    NT.Parent = N
    task.delay(3.5, function()
        TS:Create(N, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.delay(0.5, function() N:Destroy() end)
    end)
end

-- ===== PLAYER ESP LOOP =====
local lastPlayerCheck = 0
local playersCache = {}

RS.RenderStepped:Connect(function()
    -- Update player list every 30 frames
    lastPlayerCheck = lastPlayerCheck + 1
    if lastPlayerCheck >= 30 then
        lastPlayerCheck = 0
        playersCache = Players:GetPlayers()
    end

    -- Cleanup disconnected players
    if Config.PlayerESP then
        local active = {}
        for _, plr in pairs(playersCache) do
            if plr ~= LP then
                active[plr] = true
                if not ESPPool[plr] then
                    -- Create ESP set for this player
                    local set = {
                        Box = NewDrawing("Square", {Thickness = 1, Color = Config.BoxColor, Filled = false}),
                        NameTag = NewDrawing("Text", {Color = Config.TextColor, Size = 14, Center = true, Outline = true}),
                        DistTag = NewDrawing("Text", {Color = Color3.fromRGB(200, 200, 200), Size = 11, Center = true, Outline = true}),
                        HealthBarBg = NewDrawing("Square", {Color = Color3.fromRGB(40, 40, 40), Filled = true}),
                        HealthBar = NewDrawing("Square", {Color = Color3.fromRGB(0, 200, 80), Filled = true}),
                        Tracer = NewDrawing("Line", {Color = Config.TracerCol, Thickness = 1}),
                        Player = plr,
                    }
                    ESPPool[plr] = set
                end
            end
        end
        -- Remove stale
        for plr, set in pairs(ESPPool) do
            if not active[plr] then
                set.Box:Remove()
                set.NameTag:Remove()
                set.DistTag:Remove()
                set.HealthBarBg:Remove()
                set.HealthBar:Remove()
                set.Tracer:Remove()
                ESPPool[plr] = nil
            end
        end
    end

    -- Update ESP positions
    for plr, set in pairs(ESPPool) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if root and hum and hum.Health > 0 then
            local dist = GetDist(root.Position)
            if dist <= Config.MaxDist then
                local pos = root.Position
                local sp, onScreen = Cam:WorldToViewportPoint(pos)
                local spH, _ = Cam:WorldToViewportPoint(pos + Vector3.new(0, 4.5, 0))
                local spF, _ = Cam:WorldToViewportPoint(pos - Vector3.new(0, 2.5, 0))

                local boxH = math.abs(spH.Y - spF.Y)
                local boxW = boxH * 0.7
                local boxX = sp.X - boxW / 2
                local boxY = spH.Y

                set.Box.Visible = true
                set.Box.Size = Vector2.new(boxW, boxH)
                set.Box.Position = Vector2.new(boxX, boxY)
                set.Box.Color = Config.BoxColor

                -- Name
                set.NameTag.Visible = true
                set.NameTag.Position = Vector2.new(sp.X, spH.Y - 18)
                set.NameTag.Text = plr.Name
                set.NameTag.Color = Config.TextColor

                -- Distance
                set.DistTag.Visible = true
                set.DistTag.Position = Vector2.new(sp.X, spF.Y + 4)
                set.DistTag.Text = string.format("%.0f m", dist)
                local distColor = dist < 500 and Color3.fromRGB(0, 255, 100) or
                                 dist < 2000 and Color3.fromRGB(255, 200, 50) or
                                 Color3.fromRGB(255, 80, 80)
                set.DistTag.Color = distColor

                -- Health bar
                if Config.HealthBar then
                    local hpPct = hum.Health / hum.MaxHealth
                    set.HealthBarBg.Visible = true
                    set.HealthBarBg.Size = Vector2.new(boxW + 4, 3)
                    set.HealthBarBg.Position = Vector2.new(boxX - 2, boxY - 5)
                    set.HealthBar.Visible = true
                    set.HealthBar.Size = Vector2.new((boxW + 4) * hpPct, 3)
                    set.HealthBar.Position = Vector2.new(boxX - 2, boxY - 5)
                    set.HealthBar.Color = Color3.fromRGB(
                        math.floor(255 * (1 - hpPct)),
                        math.floor(255 * hpPct),
                        50
                    )
                else
                    set.HealthBarBg.Visible = false
                    set.HealthBar.Visible = false
                end

                -- Tracer
                set.Tracer.Visible = Config.Tracers
                if Config.Tracers then
                    set.Tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                    set.Tracer.To = Vector2.new(sp.X, sp.Y)
                    set.Tracer.Color = Config.TracerCol
                end
            else
                set.Box.Visible = false
                set.NameTag.Visible = false
                set.DistTag.Visible = false
                set.HealthBarBg.Visible = false
                set.HealthBar.Visible = false
                set.Tracer.Visible = false
            end
        else
            set.Box.Visible = false
            set.NameTag.Visible = false
            set.DistTag.Visible = false
            set.HealthBarBg.Visible = false
            set.HealthBar.Visible = false
            set.Tracer.Visible = false
        end
    end
end)

-- ===== FRUIT ESP =====
local function FindFruits()
    local fruits = {}
    -- Search in workspace for fruit models
    -- Blox Fruit fruit naming patterns
    local fruitNames = {
        "Apple", "Bomb", "Chop", "Diamond", "Door", "Dough",
        "Flame", "Falcon", "Gravity", "Ice", "Kilo", "Light",
        "Magma", "Pain", "Quake", "Revive", "Rubber", "Sand",
        "Shadow", "Smoke", "Spike", "Spring", "Venom", "Dark",
        "Barrier", "Blizzard", "Budha", "Buddha", "Control", "Dragon",
        "Ghost", "Human", "Leopard", "Love", "Phoenix", "Rumble",
        "Soul", "Spirit", "String", "Phoenix", "T-Rex", "Trex",
        "Yeti", "Gas", "Mammoth", "Kitsune"
    }

    -- Common containers for fruits
    local containers = {
        Ws:FindFirstChild("_WorldOrigin"),
        Ws:FindFirstChild("World"),
        Ws:FindFirstChild("DroppedFruits"),
    }

    -- Search containers
    for _, c in pairs(containers) do
        if c then
            for _, v in pairs(c:GetChildren()) do
                local name = v.Name:lower()
                -- Check if name matches a fruit or contains "fruit"
                if v:IsA("Model") and (name:find("fruit") or v:FindFirstChild("Fruit")) then
                    local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("Part")
                    if handle then
                        table.insert(fruits, {Model = v, Part = handle, Name = v.Name})
                    end
                end
            end
        end
    end

    -- Fallback: scan all workspace descendants (costly but comprehensive)
    if #fruits == 0 then
        for _, v in pairs(Ws:GetDescendants()) do
            if v:IsA("Model") then
                local name = v.Name:lower()
                for _, fn in ipairs(fruitNames) do
                    if name:find(fn:lower()) and not name:find("npc") and not name:find("boss") then
                        local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("Part")
                        if handle then
                            table.insert(fruits, {Model = v, Part = handle, Name = v.Name})
                            break
                        end
                    end
                end
            end
        end
    end

    return fruits
end

-- Fruit ESP update loop (separate, lower frequency)
task.spawn(function()
    while task.wait(0.5) do
        if not Config.FruitESP then
            ClearPool(FruitPool)
            continue
        end

        local fruits = FindFruits()
        local activeFruits = {}

        for _, fruit in pairs(fruits) do
            local key = fruit.Model
            activeFruits[key] = true

            if not FruitPool[key] then
                local lbl = NewDrawing("Text", {
                    Text = "🍎 " .. fruit.Name,
                    Color = Config.FruitCol,
                    Size = 14,
                    Center = true,
                    Outline = true,
                })
                local dist = NewDrawing("Text", {
                    Color = Color3.fromRGB(255, 215, 0),
                    Size = 11,
                    Center = true,
                    Outline = true,
                })
                FruitPool[key] = {Label = lbl, Dist = dist, Part = fruit.Part}
            end
        end

        -- Remove stale
        for key, set in pairs(FruitPool) do
            if not activeFruits[key] then
                set.Label:Remove()
                set.Dist:Remove()
                FruitPool[key] = nil
            end
        end
    end
end)

-- Fruit ESP position update (every frame for smoothness)
RS.RenderStepped:Connect(function()
    if not Config.FruitESP then
        for _, set in pairs(FruitPool) do
            set.Label.Visible = false
            set.Dist.Visible = false
        end
        return
    end

    for key, set in pairs(FruitPool) do
        local part = set.Part
        if part and part.Parent then
            local pos = part.Position
            local sp, onScreen = Cam:WorldToViewportPoint(pos)
            if onScreen then
                local dist = GetDist(pos)
                if dist <= Config.MaxDist then
                    set.Label.Visible = true
                    set.Label.Position = Vector2.new(sp.X, sp.Y - 26)
                    set.Dist.Visible = true
                    set.Dist.Position = Vector2.new(sp.X, sp.Y - 10)
                    set.Dist.Text = string.format("%.0f m", dist)
                else
                    set.Label.Visible = false
                    set.Dist.Visible = false
                end
            else
                set.Label.Visible = false
                set.Dist.Visible = false
            end
        else
            set.Label.Visible = false
            set.Dist.Visible = false
        end
    end
end)

-- ===== CLEANUP ON GUI CLOSE =====
Hub.Destroying:Connect(function()
    ClearPool(ESPPool)
    ClearPool(FruitPool)
end)