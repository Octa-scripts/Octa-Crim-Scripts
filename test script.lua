-- [[ OCTA HUB V16 - THE FINAL PRODUCT ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 1. Configuration & Variables
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

local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()

-- 2. Create Window with Key System (TEST KEY REMOVED)
local Window = Rayfield:CreateWindow({
    Name = "Octa Hub | Supreme V16",
    Theme = "Amethyst",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "OctaHub_V16",
        FileName = "Config"
    },
    KeySystem = true,
    KeySettings = {
        Title = "Octa Hub Authentication",
        Subtitle = "ID: " .. string.sub(HWID, 1, 10),
        Note = "Enter your unique access key below.",
        FileName = "OctaKeyData",
        SaveKey = true, -- Remember Key Enabled
        GrabKeyFromSite = false,
        Key = {"YOUR_PRIVATE_KEY_HERE", "Admin_Access_99"} -- Replace with your generated keys
    }
})

-- 3. Advanced Search Engines
local function GetFruits()
    local fruits = {}
    for _, v in pairs(workspace:GetDescendants()) do
        -- Blox Fruits spawned items are usually Models/Tools with a Handle
        if (v:IsA("Model") or v:IsA("Tool")) and v.Name:find("Fruit") then
            local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart", true)
            if handle then
                table.insert(fruits, handle)
            end
        end
    end
    return fruits
end

local function GetNearestMob()
    local target, dist = nil, 1000
    local folders = {workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("NPCs"), workspace}
    for _, folder in pairs(folders) do
        if folder then
            for _, v in pairs(folder:GetChildren()) do
                if v.Name == Config.TargetMob and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local mag = (LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if mag < dist then dist = mag; target = v end
                    end
                end
            end
        end
    end
    return target
end

local function SafeServerHop()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and result.data then
        for _, server in pairs(result.data) do
            if server.id ~= game.JobId and tonumber(server.playing) < tonumber(server.maxPlayers) then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                break
            end
        end
    end
end

-- 4. GUI Setup

-- COMBAT TAB
local Tab1 = Window:CreateTab("Combat", 4483362458)
Tab1:CreateSection("Target Configuration")
Tab1:CreateInput({Name = "Mob Name", PlaceholderText = "Bandit", Callback = function(t) Config.TargetMob = t end})
Tab1:CreateInput({Name = "Weapon Name", PlaceholderText = "Combat", Callback = function(t) Config.WeaponName = t end})
Tab1:CreateDivider()
Tab1:CreateSection("Farming Controls")
local FarmTog = Tab1:CreateToggle({Name = "Auto Farm NPCs", CurrentValue = false, Callback = function(v) Config.AutoFarm = v; if v then Config.ChestFarm = false; Config.FruitFarm = false end end})
Tab1:CreateSlider({Name = "Hover Distance", Range = {5, 20}, Increment = 1, CurrentValue = 8, Callback = function(v) Config.FarmDistance = v end})

-- ECONOMY TAB
local Tab2 = Window:CreateTab("Economy", 4483362458)
Tab2:CreateSection("Chest Raider")
Tab2:CreateToggle({Name = "Instant Chest Teleport", CurrentValue = false, Callback = function(v) Config.ChestFarm = v; if v then Config.AutoFarm = false; Config.FruitFarm = false end end})
Tab2:CreateSlider({Name = "Collect Delay", Range = {0.1, 2}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) Config.CollectPause = v end})
Tab2:CreateDivider()
Tab2:CreateSection("Server Tools")
Tab2:CreateButton({Name = "Jump to New Server", Callback = function() SafeServerHop() end})

-- ITEMS TAB
local Tab3 = Window:CreateTab("Items", 4483362458)
Tab3:CreateSection("Fruit Snatcher")
Tab3:CreateToggle({Name = "Auto Collect Fruit", CurrentValue = false, Callback = function(v) Config.FruitFarm = v; if v then Config.AutoFarm = false; Config.ChestFarm = false end end})
Tab3:CreateButton({Name = "Manual Fruit Scan", Callback = function() 
    local found = GetFruits()
    if #found > 0 then
        Rayfield:Notify({Title = "Fruit Found!", Content = "Found " .. #found .. " fruit(s) in the workspace."})
    else
        Rayfield:Notify({Title = "Scanner", Content = "No fruits currently spawned."})
    end
end})

-- 5. Independent Execution Loops (No Interruption)

-- Auto-Punch Logic
task.spawn(function()
    while task.wait(Config.AttackSpeed) do
        if Config.AutoFarm and LP.Character then
            local tool = LP.Character:FindFirstChild(Config.WeaponName) or LP.Backpack:FindFirstChild(Config.WeaponName)
            if tool then
                if tool.Parent == LP.Backpack then LP.Character.Humanoid:EquipTool(tool) end
                tool:Activate()
                VIM:SendMouseButtonEvent(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 0, true, game, 1)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 0, false, game, 1)
            end
        end
    end
end)

-- Fruit & Chest Teleport Logic
task.spawn(function()
    while task.wait(0.1) do
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            
            if Config.FruitFarm then
                local fruits = GetFruits()
                if #fruits > 0 then
                    hrp.CFrame = fruits[1].CFrame
                    task.wait(1) -- Time to pick up
                end
            elseif Config.ChestFarm then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v:FindFirstChild("TouchInterest") and (v.Name:find("Chest") or v.Name:find("Gold")) then
                        hrp.CFrame = v.CFrame
                        task.wait(Config.CollectPause)
                        break
                    end
                end
            end
        end
    end
end)

-- NPC Positioning & Noclip
RS.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LP.Character.HumanoidRootPart
        
        if Config.AutoFarm then
            local mob = GetNearestMob()
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, Config.FarmDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                hrp.Velocity = Vector3.new(0,0,0)
            end
        end

        -- General Noclip
        if Config.AutoFarm or Config.ChestFarm or Config.FruitFarm then
            for _, p in pairs(LP.Character:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end
    end
end)

Rayfield:Notify({Title = "Octa Hub", Content = "V16 Fully Deployed!"})
