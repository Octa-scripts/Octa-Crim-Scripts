-- ==========================================
-- 1. UI LOADER (AMETHYST)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Config = {
    FullBright = false,
    ESP = false,
    Aimbot = false,
    FOV = 150,
    Prediction = 0.165,
    Smoothness = 0.1
}

local Window = Rayfield:CreateWindow({
    Name = "Octa Hub | Town",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458) -- Added home icon

-- ==========================================
-- 2. THE COMBAT ENGINE (WITH TARGET LOCK)
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LockedTarget = nil 

local function GetClosestPlayer()
    local target = nil
    local dist = Config.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
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
    return target
end

RunService.RenderStepped:Connect(function()
    if Config.Aimbot then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if not LockedTarget then
                LockedTarget = GetClosestPlayer()
            end
            
            if LockedTarget and LockedTarget:FindFirstChild("Head") and LockedTarget.Humanoid.Health > 0 then
                local head = LockedTarget.Head
                local velocity = LockedTarget.HumanoidRootPart.Velocity
                local predictedPos = head.Position + (velocity * Config.Prediction)
                local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
                
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Config.Smoothness)
            else
                LockedTarget = nil
            end
        else
            LockedTarget = nil
        end
    end
end)

-- ==========================================
-- 3. THE PERMA-VISION ENGINE
-- ==========================================
local Lighting = game:GetService("Lighting")

RunService.RenderStepped:Connect(function()
    if Config.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 999999
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end

    if Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local highlight = p.Character:FindFirstChild("OctaHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "OctaHighlight"
                    highlight.Parent = p.Character
                    highlight.FillColor = Color3.fromRGB(163, 73, 164)
                    highlight.FillTransparency = 0.4
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("OctaHighlight") then
                p.Character.OctaHighlight:Destroy()
            end
        end
    end
end)

-- ==========================================
-- 4. INTERFACE (BEAUTIFIED)
-- ==========================================

MainTab:CreateSection("Combat Modules")

MainTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot = v end,
})

MainTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v) Config.Smoothness = (101 - v) / 100 end,
})

MainTab:CreateSlider({
    Name = "Aim Prediction",
    Range = {0, 30},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v) Config.Prediction = v / 100 end,
})

-- Visual Divider for cleanliness
MainTab:CreateSection("Visual Enhancements")

MainTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v) Config.ESP = v end,
})

MainTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Callback = function(v) Config.FullBright = v end,
})

MainTab:CreateSection("Information")
MainTab:CreateLabel("Octa Hub | Town Edition")
MainTab:CreateParagraph({Title = "Instructions", Content = "Hold Right-Click to lock onto players. Prediction works best with Low-velocity weapons."})

Rayfield:Notify({Title = "Octa Hub", Content = "GUI Beautification Complete", Duration = 3})
