print("🦖 TEST: Script started")
local ok, err = pcall(function()
    print("🦖 TEST: Inside pcall")
    
    local CG = game:GetService("CoreGui")
    local Hub = Instance.new("ScreenGui")
    Hub.Name = "TestHub"
    Hub.ResetOnSpawn = false
    Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    print("🦖 TEST: Gui created, finding parent...")
    
    local parent = nil
    if gethui then
        parent = gethui()
        print("🦖 TEST: Using gethui")
    elseif cloneref then
        parent = cloneref(CG)
        print("🦖 TEST: Using cloneref")
    else
        parent = CG
        print("🦖 TEST: Using CG directly")
    end
    
    if not parent then
        print("🦖 TEST ERROR: parent is nil!")
        parent = CG
    end
    
    Hub.Parent = parent
    print("🦖 TEST: Parent set: " .. tostring(Hub.Parent))
    
    local F = Instance.new("Frame")
    F.Size = UDim2.new(0, 300, 0, 200)
    F.Position = UDim2.new(0.5, -150, 0.5, -100)
    F.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    F.Active = true
    F.Draggable = true
    F.Parent = Hub
    
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 12)
    
    local T = Instance.new("TextLabel")
    T.Size = UDim2.new(1, 0, 1, 0)
    T.BackgroundTransparency = 1
    T.Text = "🦖 TEST GUI"
    T.TextColor3 = Color3.fromRGB(0, 200, 80)
    T.TextSize = 24
    T.Font = Enum.Font.GothamBold
    T.Parent = F
    
    print("🦖 TEST: GUI created at " .. tostring(F.AbsolutePosition))
end)

if not ok then
    warn("🦖 TEST FAILED: " .. tostring(err))
    print("🦖 TEST FAILED: " .. tostring(err))
end
print("🦖 TEST: Script finished, ok=" .. tostring(ok))
