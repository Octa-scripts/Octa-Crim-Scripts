-- ==========================================
-- 1. UI LOADER (AMETHYST)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Config = {
    Aimbot = false,
    Triggerbot = false,
    ESP = false,
    Smoothness = 1, -- Initial Strength Value
    Prediction = 0.1,
    FOV = 150
}

local Window = Rayfield:CreateWindow({
    Name = "Octa Hub | Hitmark",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Combat", 4483362458)

-- ==========================================
-- 2. THE ENGINE
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ESP APPLIER
local function ApplyGlow(char)
    if not char or not char:IsA("Model") then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if plr == LocalPlayer then return end

    local hl = char:FindFirstChild("OctaHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "OctaHighlight"
        hl.Parent = char
        hl.FillColor = Color3.fromRGB(163, 73, 164)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    hl.Enabled = Config.ESP
end

-- TARGET FINDER
local function GetClosestTarget()
    local target = nil
    local dist = Config.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local aimPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if aimPart then
                local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist then
                        target = {Character = p.Character, Part = aimPart}
                        dist = mag
                    end
                end
            end
        end
    end
    return target
end

-- MAIN COMBAT & VISUAL LOOP
RunService.RenderStepped:Connect(function()
    -- 1. AIMBOT (DYNAMIC STRENGTH)
    if Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local data = GetClosestTarget()
        if data and mousemoverel then
            local root = data.Character:FindFirstChild("HumanoidRootPart")
            local velocity = root and root.Velocity or Vector3.new(0,0,0)
            local predictedPos = data.Part.Position + (velocity * Config.Prediction)
            local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                
                -- Strength Logic: 
                -- If Strength is 20, divisor is 1 (Hard Lock). 
                -- If Strength is 1, divisor is 20 (Smooth Assist).
                local sensitivity = (21 - Config.Smoothness)
                
                local moveX = (screenPos.X - mousePos.X) / sensitivity
                local moveY = (screenPos.Y - mousePos.Y) / sensitivity
                
                mousemoverel(moveX, moveY)
            end
        end
    end

    -- 2. ESP REFRESH
    if Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then ApplyGlow(p.Character) end
        end
    end
end)

-- TRIGGERBOT (Separate Task for Speed)
task.spawn(function()
    while task.wait() do
        if Config.Triggerbot then
            local target = LocalPlayer:GetMouse().Target
            if target and target.Parent then
                local hitPlr = Players:GetPlayerFromCharacter(target.Parent)
                if hitPlr and hitPlr ~= LocalPlayer then
                    mouse1press()
                    task.wait(0.02)
                    mouse1release()
                end
            end
        end
    end
end)

-- ==========================================
-- 3. INTERFACE
-- ==========================================
MainTab:CreateSection("Targeting")

MainTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot = v end,
})

MainTab:CreateSlider({
    Name = "Strength",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v) Config.Smoothness = v end,
})

MainTab:CreateSlider({
    Name = "Aim Prediction",
    Range = {0, 30},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(v) Config.Prediction = v / 100 end,
})

MainTab:CreateSection("Visuals & Automatics")

MainTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v) 
        Config.ESP = v 
        if not v then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("OctaHighlight") then
                    p.Character.OctaHighlight.Enabled = false
                end
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = "Auto Triggerbot",
    CurrentValue = false,
    Callback = function(v) Config.Triggerbot = v end,
})

Rayfield:Notify({Title = "Octa Hub", Content = "Hitmark System Rebooted", Duration = 5})
