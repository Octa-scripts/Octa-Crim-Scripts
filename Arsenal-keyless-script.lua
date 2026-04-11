-- ==========================================
-- 1. UI LOADER (AMETHYST)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Config = {
    Aimbot = false,
    ESP = false,
    Smoothness = 0.15,
    Prediction = 0.12,
    FOV = 150,
}

local Window = Rayfield:CreateWindow({
    Name = "Octa Hub | Arsenal Official",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Combat", 4483362458)

-- ==========================================
-- 2. THE ULTIMATE X-RAY ENGINE (TEAM-ONLY)
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Folder for ESP to live in (Bypasses Arsenal's Workspace Cleaning)
local ESPFolder = CoreGui:FindFirstChild("OctaESP_Arsenal") or Instance.new("Folder")
ESPFolder.Name = "OctaESP_Arsenal"
ESPFolder.Parent = CoreGui

local function ApplyChams(plr)
    -- 1. Ensure it's a valid enemy
    if not plr or plr == LocalPlayer or plr.Team == LocalPlayer.Team then return end
    
    local char = plr.Character
    if not char then return end

    -- 2. Create or Update Highlight in CoreGui
    local hlName = plr.Name .. "_ESP"
    local hl = ESPFolder:FindFirstChild(hlName) or Instance.new("Highlight")
    
    hl.Name = hlName
    hl.Parent = ESPFolder
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(163, 73, 164)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = Config.ESP
end

-- LISTENERS: Update ESP when someone joins or respawns
local function MonitorPlayer(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5) -- Wait for character to fully load
        if Config.ESP then ApplyChams(plr) end
    end)
    
    -- Update if they switch teams
    plr:GetPropertyChangedSignal("Team"):Connect(function()
        local hl = ESPFolder:FindFirstChild(plr.Name .. "_ESP")
        if hl then hl:Destroy() end -- Wipe old ESP to re-check team status
        if Config.ESP then ApplyChams(plr) end
    end)
end

for _, p in pairs(Players:GetPlayers()) do MonitorPlayer(p) end
Players.PlayerAdded:Connect(MonitorPlayer)

-- Cleanup when they leave
Players.PlayerRemoving:Connect(function(plr)
    local hl = ESPFolder:FindFirstChild(plr.Name .. "_ESP")
    if hl then hl:Destroy() end
end)

-- Constant Refresh Loop (Safety Net)
task.spawn(function()
    while task.wait(1) do
        if Config.ESP then
            for _, p in pairs(Players:GetPlayers()) do
                ApplyChams(p)
            end
        end
    end
end)

-- ==========================================
-- 3. COMBAT ENGINE
-- ==========================================
local function GetClosestEnemy()
    local target = nil
    local dist = Config.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        -- Only target living enemies
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") then
            if p.Character.Humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist then
                        target = p.Character
                        dist = mag
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestEnemy()
        if target and target:FindFirstChild("Head") and target:FindFirstChild("HumanoidRootPart") then
            local velocity = target.HumanoidRootPart.Velocity
            local predictedPos = target.Head.Position + (velocity * Config.Prediction)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPos), Config.Smoothness)
        end
    end
end)

-- ==========================================
-- 4. INTERFACE
-- ==========================================
MainTab:CreateSection("Combat Settings")

MainTab:CreateToggle({
    Name = "Aimbot Enabled",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot = v end,
})

MainTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v) Config.Smoothness = (101 - v) / 100 end,
})

MainTab:CreateSlider({
    Name = "Prediction Amount",
    Range = {0, 30},
    Increment = 1,
    CurrentValue = 12,
    Callback = function(v) Config.Prediction = v / 100 end,
})

MainTab:CreateSection("Visual Enhancements")

MainTab:CreateToggle({
    Name = "Amethyst Enemy Chams",
    CurrentValue = false,
    Callback = function(v) 
        Config.ESP = v 
        if not v then
            for _, hl in pairs(ESPFolder:GetChildren()) do hl.Enabled = false end
        else
            for _, p in pairs(Players:GetPlayers()) do ApplyChams(p) end
        end
    end,
})

Rayfield:Notify({Title = "Octa Hub", Content = "Arsenal Ultimate Build v4.0", Duration = 5})
