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
local doorData = {}

-- ==========================================
-- 2. DYNAMIC ESP HANDLER (THE FIX)
-- ==========================================
local function applyESP(character, player)
    if not character or player == LocalPlayer then return end
    
    -- 1. Highlight (Chams)
    local highlight = character:FindFirstChild("OctaHighlight") or Instance.new("Highlight")
    highlight.Name = "OctaHighlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = espEnabled

    -- 2. Text Node (Names/Weapons)
    local head = character:WaitForChild("Head", 5)
    if head and not character:FindFirstChild("OctaText") then
        local b = Instance.new("BillboardGui", character)
        b.Name = "OctaText"; b.Adornee = head; b.Size = UDim2.new(0, 200, 0, 50); b.StudsOffset = Vector3.new(0, 3, 0); b.AlwaysOnTop = true

        local nl = Instance.new("TextLabel", b)
        nl.Name = "NameLabel"; nl.BackgroundTransparency = 1; nl.Size = UDim2.new(1,0,0.5,0); nl.TextColor3 = Color3.fromRGB(255,255,255); nl.TextStrokeTransparency = 0; nl.Font = Enum.Font.Code; nl.TextSize = 14; nl.Text = player.Name; nl.Visible = nameEspEnabled

        local wl = Instance.new("TextLabel", b)
        wl.Name = "WeaponLabel"; wl.BackgroundTransparency = 1; wl.Size = UDim2.new(1,0,0.5,0); wl.Position = UDim2.new(0,0,0.5,0); wl.TextColor3 = Color3.fromRGB(255,100,100); wl.TextStrokeTransparency = 0; wl.Font = Enum.Font.Code; wl.TextSize = 12; wl.Text = "[ None ]"; wl.Visible = weaponEspEnabled
    end
end

-- Listener for existing and new players
local function setupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5) -- Wait for character to fully load
        applyESP(char, player)
    end)
    if player.Character then applyESP(player.Character, player) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in pairs(Players:GetPlayers()) do setupPlayer(p) end

-- Refresh Toggles
local function updateAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("OctaHighlight")
            local t = p.Character:FindFirstChild("OctaText")
            if h then h.Enabled = espEnabled end
            if t then
                t.NameLabel.Visible = nameEspEnabled
                t.WeaponLabel.Visible = weaponEspEnabled
            end
        end
    end
end

-- ==========================================
-- 3. BYPASSES (DOORS, LOOT, ADMINS)
-- ==========================================
local function toggleNoDoors(state)
    noDoorsEnabled = state
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.find(v.Name:lower(), "door") then
            if state then
                if not doorData[v] then doorData[v] = {t = v.Transparency, c = v.CanCollide} end
                v.Transparency = 0.7; v.CanCollide = false
            elseif doorData[v] then
                v.Transparency = doorData[v].t; v.CanCollide = doorData[v].c
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        if safeEspEnabled then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and (v.Name:find("Safe") or v.Name:find("Register")) then
                    local p = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
                    if p and not p:FindFirstChild("SafeESP") then
                        local b = Instance.new("BillboardGui", p); b.Name = "SafeESP"; b.Size = UDim2.new(0,80,0,40); b.AlwaysOnTop = true
                        local t = Instance.new("TextLabel", b); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.TextColor3 = Color3.fromRGB(0,255,0); t.Text = "💰"
                        table.insert(safeMarkers, b)
                    end
                end
            end
        else
            for _, v in pairs(safeMarkers) do if v then v:Destroy() end end
            table.clear(safeMarkers)
        end
    end
end)

-- ==========================================
-- 4. MAIN LOOP (AIM & LIGHTING)
-- ==========================================
RunService.RenderStepped:Connect(function()
    if aimlockEnabled and aiming and target and target.Parent then
        local root = target.Parent:FindFirstChild("HumanoidRootPart")
        if root then
            local predPos = target.Position + (root.Velocity * PREDICTION_STRENGTH)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predPos), SMOOTHNESS)
        end
    end
    if fullBrightEnabled then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    end
    if weaponEspEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            local char = p.Character
            local node = char and char:FindFirstChild("OctaText")
            if node then
                local tool = char:FindFirstChildOfClass("Tool")
                node.WeaponLabel.Text = tool and "[" .. tool.Name .. "]" or "[None]"
            end
        end
    end
end)

-- ==========================================
-- 5. UI SETUP
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🔫 Octa Scripts: FINAL FIX 🔫",
   Theme = "Amethyst",
   ConfigurationSaving = { Enabled = true, FolderName = "OctaHub" }
})

local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateToggle({ Name = "Smart Aimlock", CurrentValue = false, Callback = function(v) aimlockEnabled = v end })
CombatTab:CreateSlider({ Name = "Prediction", Range = {0, 0.5}, Increment = 0.01, CurrentValue = 0.16, Callback = function(v) PREDICTION_STRENGTH = v end })
CombatTab:CreateSlider({ Name = "Smoothness", Range = {0.1, 1}, Increment = 0.1, CurrentValue = 0.4, Callback = function(v) SMOOTHNESS = v end })

local VisualTab = Window:CreateTab("👓 Visuals", nil)
VisualTab:CreateToggle({ Name = "Highlights", CurrentValue = false, Callback = function(v) espEnabled = v; updateAllESP() end })
VisualTab:CreateToggle({ Name = "Names", CurrentValue = false, Callback = function(v) nameEspEnabled = v; updateAllESP() end })
VisualTab:CreateToggle({ Name = "Weapons", CurrentValue = false, Callback = function(v) weaponEspEnabled = v; updateAllESP() end })
VisualTab:CreateToggle({ Name = "Loot ESP", CurrentValue = false, Callback = function(v) safeEspEnabled = v end })
VisualTab:CreateToggle({ Name = "Full-Bright", CurrentValue = false, Callback = function(v) fullBrightEnabled = v end })

local MiscTab = Window:CreateTab("🎲 Misc", nil)
MiscTab:CreateToggle({ Name = "Ragdoll No Fall", CurrentValue = false, Callback = function(v) noFallEnabled = v end })
MiscTab:CreateToggle({ Name = "Auto-Leave (Admin)", CurrentValue = false, Callback = function(v) autoLeaveEnabled = v end })
MiscTab:CreateToggle({ Name = "No Doors", CurrentValue = false, Callback = function(v) toggleNoDoors(v) end })

-- Input listeners
UIS.InputBegan:Connect(function(i,p) if not p and i.UserInputType == Enum.UserInputType.MouseButton2 and aimlockEnabled then aiming = true; target = nil; local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2); local low = math.huge; for _, player in pairs(Players:GetPlayers()) do if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then local head = player.Character.Head; local pos, on = Camera:WorldToViewportPoint(head.Position); if on then local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude; if dist < AIM_FOV and dist < low then low = dist; target = head end end end end end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end end)

Rayfield:Notify({ Title = "Octa FIX Loaded", Content = "ESP Auto-Update is now LIVE.", Duration = 5 })
