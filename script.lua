-- ==========================================
-- 1. SERVICES & CONFIG
-- ==========================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Global Guard
if _G.OctaScriptRunning then _G.OctaScriptRunning = false task.wait(0.1) end
_G.OctaScriptRunning = true

local Config = {
    Aim = { Enabled = false, Aiming = false, Target = nil, Smooth = 0.4, Predict = 0.165, FOV = 300 },
    ESP = { Chams = false, Names = false, Weapons = false, Loot = false, Bright = false },
    Misc = { NoFall = false, AutoLeave = false }
}

local safeMarkers = {}

-- ==========================================
-- 2. PLAYER ESP LOGIC (FIXED)
-- ==========================================
local function createPlayerESP(player)
    if player == LocalPlayer then return end
    
    local function setup(char)
        if not char then return end
        task.wait(0.5) -- Essential for Crim character loading

        -- Highlight (Chams)
        if not char:FindFirstChild("OctaH") then
            local h = Instance.new("Highlight")
            h.Name = "OctaH"; h.Parent = char
            h.FillColor = Color3.fromRGB(255, 0, 0); h.OutlineColor = Color3.fromRGB(255, 255, 255)
            h.FillTransparency = 0.5; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled = Config.ESP.Chams
        end

        -- Billboard (Names/Weapons)
        local head = char:WaitForChild("Head", 10)
        if head and not char:FindFirstChild("OctaUI") then
            local b = Instance.new("BillboardGui", char); b.Name = "OctaUI"; b.Adornee = head
            b.Size = UDim2.new(0, 200, 0, 50); b.StudsOffset = Vector3.new(0, 3, 0); b.AlwaysOnTop = true
            
            local n = Instance.new("TextLabel", b); n.Name = "N"; n.BackgroundTransparency = 1; n.Size = UDim2.new(1,0,0.5,0); n.TextColor3 = Color3.fromRGB(255,255,255); n.Font = Enum.Font.Code; n.TextSize = 14; n.TextStrokeTransparency = 0; n.Text = player.Name
            local w = Instance.new("TextLabel", b); w.Name = "W"; w.BackgroundTransparency = 1; w.Size = UDim2.new(1,0,0.5,0); w.Position = UDim2.new(0,0,0.5,0); w.TextColor3 = Color3.fromRGB(255,100,100); w.Font = Enum.Font.Code; w.TextSize = 12; w.TextStrokeTransparency = 0
            
            n.Visible = Config.ESP.Names
            w.Visible = Config.ESP.Weapons
        end
    end

    player.CharacterAdded:Connect(setup)
    if player.Character then setup(player.Character) end
end

-- Start listeners
for _, p in pairs(Players:GetPlayers()) do createPlayerESP(p) end
Players.PlayerAdded:Connect(createPlayerESP)

-- ==========================================
-- 3. WORLD UTILITIES (LOOT UNTOUCHED)
-- ==========================================
local function refreshLoot()
    if #safeMarkers == 0 then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and (v.Name:find("Safe") or v.Name:find("Register")) then
                local p = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
                if p then
                    local txt = v.Name:find("Safe") and "🔒 Safe" or "💵 Register"
                    local b = Instance.new("BillboardGui", p); b.Name = "OctaLoot"; b.Size = UDim2.new(0,100,0,40); b.AlwaysOnTop = true
                    local t = Instance.new("TextLabel", b); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.TextColor3 = Color3.fromRGB(0,255,150); t.Text = txt; t.Font = Enum.Font.Code; t.TextSize = 12
                    b.Enabled = false; table.insert(safeMarkers, b)
                end
            end
        end
    end
    for _, m in pairs(safeMarkers) do if m then m.Enabled = Config.ESP.Loot end end
end

-- ==========================================
-- 4. ENGINE LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
    -- Aimlock (Untouched)
    if Config.Aim.Enabled and Config.Aim.Aiming and Config.Aim.Target and Config.Aim.Target.Parent then
        local root = Config.Aim.Target.Parent:FindFirstChild("HumanoidRootPart")
        if root then
            local pred = Config.Aim.Target.Position + (root.Velocity * Config.Aim.Predict)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pred), Config.Aim.Smooth)
        end
    end

    -- Update Player ESP Visibility
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("OctaH")
            local b = p.Character:FindFirstChild("OctaUI")
            if h then h.Enabled = Config.ESP.Chams end
            if b then
                b.N.Visible = Config.ESP.Names
                b.W.Visible = Config.ESP.Weapons
                if Config.ESP.Weapons then
                    local tool = p.Character:FindFirstChildOfClass("Tool")
                    b.W.Text = tool and "[" .. tool.Name .. "]" or "[ Unarmed ]"
                end
            end
        end
    end

    -- Misc
    if Config.Misc.NoFall and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        local s = hum:GetState()
        if s == Enum.HumanoidStateType.Freefall or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    if Config.ESP.Bright then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false end
end)

-- ==========================================
-- 5. GUI SETUP (UNTOUCHED)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({ 
    Name = "🔫Criminality Script┃ Octa Hub", 
    Theme = "Amethyst", 
    ConfigurationSaving = { Enabled = false }
})

local Tab1 = Window:CreateTab("Combat", 4483362458)
Tab1:CreateSection("Targeting")
Tab1:CreateToggle({ Name = "Enable Aimlock", CurrentValue = false, Callback = function(v) Config.Aim.Enabled = v end })
Tab1:CreateSection("Calibration")
Tab1:CreateSlider({ Name = "Prediction", Range = {0, 0.5}, Increment = 0.01, CurrentValue = 0.16, Callback = function(v) Config.Aim.Predict = v end })
Tab1:CreateSlider({ Name = "Smoothness", Range = {0.1, 1}, Increment = 0.1, CurrentValue = 0.4, Callback = function(v) Config.Aim.Smooth = v end })

local Tab2 = Window:CreateTab("Visuals", 4483362458)
Tab2:CreateSection("Player Tracking")
Tab2:CreateToggle({ Name = "Chams", CurrentValue = false, Callback = function(v) Config.ESP.Chams = v end })
Tab2:CreateToggle({ Name = "Names", CurrentValue = false, Callback = function(v) Config.ESP.Names = v end })
Tab2:CreateToggle({ Name = "Weapons", CurrentValue = false, Callback = function(v) Config.ESP.Weapons = v end })
Tab2:CreateSection("World & Utility")
Tab2:CreateToggle({ Name = "Loot (Safes & Registers)", CurrentValue = false, Callback = function(v) Config.ESP.Loot = v; refreshLoot() end })
Tab2:CreateToggle({ Name = "Fullbright", CurrentValue = false, Callback = function(v) Config.ESP.Bright = v end })

local Tab3 = Window:CreateTab("Misc", 4483362458)
Tab3:CreateSection("Character")
Tab3:CreateToggle({ Name = "No Fall Damage", CurrentValue = false, Callback = function(v) Config.Misc.NoFall = v end })
Tab3:CreateSection("Safety")
Tab3:CreateToggle({ Name = "Auto-Leave (Admin)", CurrentValue = false, Callback = function(v) Config.Misc.AutoLeave = v end })

-- Inputs
UIS.InputBegan:Connect(function(i,p) 
    if not p and i.UserInputType == Enum.UserInputType.MouseButton2 and Config.Aim.Enabled then 
        Config.Aim.Aiming = true; Config.Aim.Target = nil; 
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2); local low = math.huge
        for _, player in pairs(Players:GetPlayers()) do 
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then 
                local head = player.Character.Head; local pos, on = Camera:WorldToViewportPoint(head.Position)
                if on then 
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < Config.Aim.FOV and dist < low then low = dist; Config.Aim.Target = head end 
                end 
            end 
        end 
    end 
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Config.Aim.Aiming = false end end)

Rayfield:Notify({ Title = "Octa Hub", Content = "ESP fixed and stabilized.", Duration = 5 })
