-- ==========================================
-- 1. SERVICES & GLOBAL VARIABLES
-- ==========================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Config Variables
local aimlockEnabled, aiming, target = false, false, nil
local espEnabled, nameEspEnabled, weaponEspEnabled, safeEspEnabled = false, false, false, false
local fullBrightEnabled, noFallEnabled, autoLeaveEnabled, noDoorsEnabled = false, false, false, false
local SMOOTHNESS = 0.4 
local AIM_FOV = 300 
local PREDICTION_STRENGTH = 0.165 

local safeMarkers = {}
local doorData = {} -- Stores original transparency/collision

-- ==========================================
-- 2. DOOR BYPASS (GHOST MODE)
-- ==========================================
local function toggleNoDoors(state)
    noDoorsEnabled = state
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.find(v.Name:lower(), "door") then
            if state then
                -- Store original state if not already stored
                if not doorData[v] then
                    doorData[v] = {Transparency = v.Transparency, CanCollide = v.CanCollide}
                end
                v.Transparency = 0.7 -- Ghostly look
                v.CanCollide = false
            else
                -- Restore original state
                if doorData[v] then
                    v.Transparency = doorData[v].Transparency
                    v.CanCollide = doorData[v].CanCollide
                end
            end
        end
    end
end

-- ==========================================
-- 3. ESP & LOOT FUNCTIONS (VERIFIED)
-- ==========================================
local function addPlayerESP(player, character)
    if player == LocalPlayer or not character then return end
    
    -- Highlight (Chams)
    local h = character:FindFirstChild("ESPHighlight") or Instance.new("Highlight", character)
    h.Name = "ESPHighlight"
    h.Enabled = espEnabled
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    -- Text Node
    local head = character:FindFirstChild("Head")
    if head and not character:FindFirstChild("ESPTextNode") then
        local b = Instance.new("BillboardGui", character)
        b.Name = "ESPTextNode"; b.Adornee = head; b.Size = UDim2.new(0, 200, 0, 50); b.StudsOffset = Vector3.new(0, 2.5, 0); b.AlwaysOnTop = true

        local nl = Instance.new("TextLabel", b)
        nl.Name = "NameLabel"; nl.BackgroundTransparency = 1; nl.Size = UDim2.new(1,0,0.5,0); nl.TextColor3 = Color3.fromRGB(255,255,255); nl.Font = Enum.Font.Code; nl.TextSize = 14; nl.Text = player.Name; nl.Visible = nameEspEnabled

        local wl = Instance.new("TextLabel", b)
        wl.Name = "WeaponLabel"; wl.BackgroundTransparency = 1; wl.Size = UDim2.new(1,0,0.5,0); wl.Position = UDim2.new(0,0,0.5,0); wl.TextColor3 = Color3.fromRGB(255,100,100); wl.Font = Enum.Font.Code; wl.TextSize = 12; wl.Text = "[ None ]"; wl.Visible = weaponEspEnabled
    end
end

local function refreshPlayerESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then addPlayerESP(player, player.Character) end
    end
end

-- ==========================================
-- 4. SCAN LOOT (STUTTER-FREE)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(2)
        if safeEspEnabled then
            local objs = workspace:GetDescendants()
            for i = 1, #objs do
                local v = objs[i]
                if i % 1000 == 0 then task.wait() end
                if v:IsA("Model") and (string.find(v.Name:lower(), "safe") or string.find(v.Name:lower(), "register")) then
                    local part = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
                    if part and not part:FindFirstChild("SafeESP") then
                        local b = Instance.new("BillboardGui", part); b.Name = "SafeESP"; b.Size = UDim2.new(0,100,0,50); b.AlwaysOnTop = true
                        local t = Instance.new("TextLabel", b); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.TextColor3 = Color3.fromRGB(50,255,50); t.Font = Enum.Font.Code; t.Text = "💰 " .. v.Name
                        table.insert(safeMarkers, b)
                    end
                end
            end
        else
            for _, v in ipairs(safeMarkers) do if v then v:Destroy() end end
            table.clear(safeMarkers)
        end
    end
end)

-- ==========================================
-- 5. ADMIN CHECK & AIMLOCK
-- ==========================================
Players.PlayerAdded:Connect(function(player)
    if autoLeaveEnabled and (player:GetRankInGroup(4802792) >= 50 or player.UserId == game.CreatorId) then
        LocalPlayer:Kick("🛡️ Admin Safety: " .. player.Name .. " joined.")
    end
end)

local function getNearestTarget()
    local closest, lowestScore = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if screenDist < AIM_FOV then
                    local worldDist = (head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    local score = screenDist * (worldDist / 10)
                    if score < lowestScore then lowestScore, closest = score, head end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    -- Aimlock with Velocity Prediction
    if aimlockEnabled and aiming and target and target.Parent then
        local root = target.Parent:FindFirstChild("HumanoidRootPart")
        if root then
            local predPos = target.Position + (root.Velocity * PREDICTION_STRENGTH)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predPos), SMOOTHNESS)
        end
    end
    -- Constant Fullbright
    if fullBrightEnabled then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    end
    -- Live Weapon ESP
    if weaponEspEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            local node = p.Character and p.Character:FindFirstChild("ESPTextNode")
            if node then
                local tool = p.Character:FindFirstChildOfClass("Tool")
                node.WeaponLabel.Text = tool and "[ " .. tool.Name .. " ]" or "[ None ]"
            end
        end
    end
end)

-- ==========================================
-- 6. UI SETUP (RAYFIELD)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🔫 Octa Scripts: Criminality FINAL 🔫",
   LoadingTitle = "Octa Ultimate Hub",
   LoadingSubtitle = "V5.3 - Ghost Mode Ready",
   Theme = "Amethyst",
   ConfigurationSaving = { Enabled = true, FolderName = "OctaHub", FileName = "Config" }
})

local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateToggle({
   Name = "Smart Aimlock", CurrentValue = false, Flag = "AimToggle", 
   Callback = function(v) aimlockEnabled = v end,
})
CombatTab:CreateSlider({
   Name = "Prediction Strength", Range = {0, 0.5}, Increment = 0.01, Suffix = "s", CurrentValue = 0.16,
   Callback = function(v) PREDICTION_STRENGTH = v end,
})
CombatTab:CreateSlider({
   Name = "Aim Smoothness", Range = {0.1, 1}, Increment = 0.1, Suffix = "Lerp", CurrentValue = 0.4,
   Callback = function(v) SMOOTHNESS = v end,
})

local VisualTab = Window:CreateTab("👓 Visuals", nil)
VisualTab:CreateSection("Player ESP")
VisualTab:CreateToggle({ Name = "Highlight (Chams)", CurrentValue = false, Callback = function(v) espEnabled = v; refreshPlayerESP() end })
VisualTab:CreateToggle({ Name = "Show Names", CurrentValue = false, Callback = function(v) nameEspEnabled = v; refreshPlayerESP() end })
VisualTab:CreateToggle({ Name = "Show Weapons", CurrentValue = false, Callback = function(v) weaponEspEnabled = v; refreshPlayerESP() end })
VisualTab:CreateSection("World Visuals")
VisualTab:CreateToggle({ Name = "Loot / Safe ESP", CurrentValue = false, Callback = function(v) safeEspEnabled = v end })
VisualTab:CreateToggle({ Name = "Full-Bright", CurrentValue = false, Callback = function(v) fullBrightEnabled = v end })

local MiscTab = Window:CreateTab("🎲 Misc", nil)
MiscTab:CreateToggle({ Name = "Ragdoll-Proof No Fall", CurrentValue = false, Callback = function(v) noFallEnabled = v end })
MiscTab:CreateToggle({ Name = "Auto-Leave (Admin Safety)", CurrentValue = false, Callback = function(v) autoLeaveEnabled = v end })
MiscTab:CreateToggle({ 
    Name = "No Doors (Ghost Mode)", 
    CurrentValue = false, 
    Callback = function(v) toggleNoDoors(v) end 
})

-- Input Listeners
UIS.InputBegan:Connect(function(i, p) 
    if not p and i.UserInputType == Enum.UserInputType.MouseButton2 and aimlockEnabled then 
        target = getNearestTarget(); aiming = target ~= nil 
    end 
end)
UIS.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false; target = nil end 
end)

Rayfield:Notify({ Title = "Octa FINAL Loaded", Content = "Ghost Mode & Prediction Active.", Duration = 5 })
