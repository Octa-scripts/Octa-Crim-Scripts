-- [[ OCTA HUB - DIVE DOWN ]] --
-- [[ VERSION: V6.6 | 4000 STUD DEPTH UPDATE ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local LP = game:GetService("Players").LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Octa Hub | Dive Down 🌊",
    LoadingTitle = "Calibrating to 4,000 Studs...",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Movement", 4483362458)
local SavedAquariumCFrame = nil

-- [[ THE "STABLE" ENGINES ]]

local function RelativeMove(yOffset, anchorTime)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Anchored = true
        root.CFrame = root.CFrame * CFrame.new(0, yOffset, 0)
        task.wait(anchorTime or 2)
        root.Anchored = false
    end
end

local function AbsoluteMove(targetCFrame, anchorTime)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Anchored = true
        root.CFrame = targetCFrame
        task.wait(anchorTime or 2)
        root.Anchored = false
    end
end

-- [[ INSTRUCTIONS SECTION ]]
MainTab:CreateSection("⚠️ HOW TO USE")
MainTab:CreateLabel("1. Stand ABOVE the water at the surface first.")
MainTab:CreateLabel("2. Align yourself over the open ocean area.")
MainTab:CreateLabel("3. Use 'Bottom Floor' for the -4k deep jump.")

-- [[ 1. OXYGEN REFILL ]]
MainTab:CreateSection("Survival")

MainTab:CreateButton({
    Name = "Instant Oxygen Refill",
    Callback = function()
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local startPos = root.CFrame
            -- TP to Y: 5000 (Safe Sky) to force oxygen reset
            root.CFrame = CFrame.new(root.Position.X, 5000, root.Position.Z)
            task.wait(1.5)
            AbsoluteMove(startPos, 1.5)
            Rayfield:Notify({Title = "Refilled", Content = "Air tank is back to 100%"})
        end
    end
})

-- [[ 2. DEPTH JUMPS ]]
MainTab:CreateSection("Depth Jumps")

MainTab:CreateButton({
    Name = "Shallow Jump (-1,000 Studs)",
    Callback = function()
        RelativeMove(-1000, 2)
    end
})

MainTab:CreateButton({
    Name = "Bottom Floor (-4,000 Studs)",
    Callback = function()
        Rayfield:Notify({
            Title = "Diving to Bottom",
            Content = "Dropping to the 4,000 stud limit.",
            Duration = 3
        })
        -- Updated to exactly 4,000 as requested
        RelativeMove(-4000, 2.5) 
    end
})

-- [[ 3. AQUARIUM ]]
MainTab:CreateSection("Aquarium")

MainTab:CreateButton({
    Name = "Set Aquarium Waypoint",
    Callback = function()
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            SavedAquariumCFrame = LP.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Saved!", Content = "Waypoint set successfully."})
        end
    end
})

MainTab:CreateButton({
    Name = "Teleport to Aquarium",
    Callback = function()
        if SavedAquariumCFrame then
            AbsoluteMove(SavedAquariumCFrame, 2)
        else
            Rayfield:Notify({Title = "Error", Content = "No waypoint saved. Click 'Set' while at your base!"})
        end
    end
})
