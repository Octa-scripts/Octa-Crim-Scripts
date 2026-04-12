-- ==========================================
-- 1. STABILITY & UI (Amethyst Theme)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Config = {
    AutoFarm = false,
    ChestFarm = false,
    FruitFarm = false,
    FarmDistance = 8,
    TargetMob = "Bandit",
    WeaponName = "Combat",
    AttackSpeed = 0.15,
    CollectPause = 0.5,
    Keybind = Enum.KeyCode.F4
}

local Window = Rayfield:CreateWindow({
    Name = "Octa Hub | Final Stabilized V14",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = false }
})

local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- ==========================================
-- 2. UTILITY FUNCTIONS
-- ==========================================

local function SafeServerHop()
    local PlaceID = game.PlaceId
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and result.data then
        for _, server in pairs(result.data) do
            if server.id ~= game.JobId and tonumber(server.playing) < tonumber(server.maxPlayers) then
                TeleportService:TeleportToPlaceInstance(PlaceID, server.id, LP)
                break
            end
        end
    end
end

local function GetNearestMob()
    local target = nil
    local dist = 1000
    local folders = {workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("NPCs"), workspace}
    for _, folder in pairs(folders) do
        if folder then
            for _, v in pairs(folder:GetChildren()) do
                if v.Name == Config.TargetMob and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    local mag = (LP.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if mag < dist then dist = mag; target = v end
                end
            end
        end
    end
    return target
end

-- ==========================================
-- 3. INTERFACE (With Sections & Dividers)
-- ==========================================

-- --- NPC FARM TAB ---
local Tab1 = Window:CreateTab("Combat", 4483362458)

Tab1:CreateSection("Target Settings")
Tab1:CreateInput({
    Name = "NPC Name",
    PlaceholderText = "Example: Bandit",
    Callback = function(T) Config.TargetMob = T end
})
Tab1:CreateInput({
    Name = "Weapon Name",
    PlaceholderText = "Combat / Katana",
    Callback = function(T) Config.WeaponName = T end
})

Tab1:CreateDivider()

Tab1:CreateSection("Farm Controls")
Tab1:CreateToggle({
    Name = "Start Auto Farm",
    CurrentValue = false,
    Callback = function(v) 
        Config.AutoFarm = v 
        if v then Config.ChestFarm = false; Config.FruitFarm = false end 
    end
})
Tab1:CreateSlider({
    Name = "Hover Height",
    Range = {5, 20},
    Increment = 1,
    CurrentValue = 8,
    Callback = function(v) Config.FarmDistance = v end
})

-- --- MONEY TAB ---
local Tab2 = Window:CreateTab("Economy", 4483362458)

Tab2:CreateSection("Chest Farming")
Tab2:CreateToggle({
    Name = "Instant Chest Teleport",
    CurrentValue = false,
    Callback = function(v) 
        Config.ChestFarm = v 
        if v then Config.AutoFarm = false; Config.FruitFarm = false end 
    end
})
Tab2:CreateSlider({
    Name = "Collection Delay",
    Range = {0.1, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v) Config.CollectPause = v end
})

Tab2:CreateDivider()

Tab2:CreateSection("World Tools")
Tab2:CreateButton({
    Name = "Server Hop (Safe)",
    Callback = function() SafeServerHop() end
})

-- --- FRUIT TAB ---
local Tab3 = Window:CreateTab("Items", 4483362458)

Tab3:CreateSection("Fruit Notifier & Snatcher")
Tab3:CreateToggle({
    Name = "Auto Collect Fruit",
    CurrentValue = false,
    Callback = function(v) 
        Config.FruitFarm = v 
        if v then Config.AutoFarm = false; Config.ChestFarm = false end 
    end
})
Tab3:CreateButton({
    Name = "Manual Fruit Scan",
    Callback = function() 
        local f = 0
        for _, v in pairs(workspace:GetChildren()) do if v.Name:find("Fruit") then f = f + 1 end end
        Rayfield:Notify({Title = "Scan", Content = "Found " .. f .. " fruit(s)"}) 
    end
})

-- ==========================================
-- 4. THE MASTER LOOP (STABILIZED)
-- ==========================================

task.spawn(function()
    while task.wait(Config.AttackSpeed) do
        if Config.AutoFarm and not UIS:GetFocusedTextBox() then
            local char = LP.Character
            if char and char:FindFirstChild(Config.WeaponName) then
                char[Config.WeaponName]:Activate()
                VIM:SendMouseButtonEvent(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 0, true, game, 1)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 0, false, game, 1)
            end
        end
    end
end)

RS.Stepped:Connect(function()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    if Config.FruitFarm then
        for _, v in pairs(workspace:GetChildren()) do
            if v.Name:find("Fruit") then
                local handle = v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart", true) or v
                if handle then hrp.CFrame = handle.CFrame end
                break
            end
        end
    elseif Config.ChestFarm then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v:FindFirstChild("TouchInterest") and (v.Name:find("Chest") or v.Name:find("Gold")) then
                hrp.CFrame = v.CFrame
                task.wait(Config.CollectPause)
                break
            end
        end
    elseif Config.AutoFarm then
        local mob = GetNearestMob()
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            hrp.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, Config.FarmDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            hrp.Velocity = Vector3.new(0,0,0)
        end
    end

    if Config.AutoFarm or Config.ChestFarm or Config.FruitFarm then
        for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
end)

Rayfield:Notify({Title = "Octa Hub", Content = "V14 Loaded with Organization!"})
