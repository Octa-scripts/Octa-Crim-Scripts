-- ==========================================
-- [ SERVICES ]
-- ==========================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [ CONFIGURATION ]
local aimlockEnabled, aiming, target = false, false, nil
local espEnabled, nameEspEnabled, weaponEspEnabled, safeEspEnabled = false, false, false, false
local fullBrightEnabled, noFallEnabled, autoLeaveEnabled, noDoorsEnabled = false, false, false, false

local SMOOTHNESS = 0.4 
local AIM_FOV = 300 
local PREDICTION_STRENGTH = 0.165 

local safeMarkers = {}
local doorData = {}

-- ==========================================
-- [ ESP CORE MODULE ]
-- ==========================================
local function applyESP(character, player)
    if not character or player == LocalPlayer then return end
    
    -- Highlight / Chams
    local highlight = character:FindFirstChild("OctaHighlight") or Instance.new("Highlight")
    highlight.Name = "OctaHighlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = espEnabled

    -- Info Labels
    local head = character:WaitForChild("Head", 10)
    if head and not character:FindFirstChild("OctaText") then
        local billboard = Instance.new("BillboardGui", character)
        billboard.Name = "OctaText"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true

        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Name = "NameLabel"
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.Code
        nameLabel.TextSize = 14
        nameLabel.Text = player.Name
        nameLabel.Visible = nameEspEnabled

        local weaponLabel = Instance.new("TextLabel", billboard)
        weaponLabel.Name = "WeaponLabel"
        weaponLabel.BackgroundTransparency = 1
        weaponLabel.Size = UDim2.new(1, 0, 0.5, 0)
        weaponLabel.Position = UDim2.new(0, 0, 0.5, 0)
        weaponLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        weaponLabel.TextStrokeTransparency = 0
        weaponLabel.Font = Enum.Font.Code
        weaponLabel.TextSize = 12
        weaponLabel.Text = "[ None ]"
        weaponLabel.Visible = weaponEspEnabled
    end
end

-- Force Update Loop (Ensures no one is missed)
task.spawn(function()
    while true do
        task.wait(1)
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                applyESP(p.Character, p)
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
end)

-- ==========================================
-- [ WORLD MODULES ]
-- ==========================================
local function toggleNoDoors(state)
    noDoorsEnabled = state
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.find(v.Name:lower(), "door") then
            if state then
                if not doorData[v] then doorData[v] = {t = v.Transparency, c = v.CanCollide} end
                v.Transparency = 0.7
                v.CanCollide = false
            elseif doorData[v] then
                v.Transparency = doorData[v].t
                v.CanCollide = doorData[v].c
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
                        local t = Instance.new("TextLabel", b); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.TextColor3 = Color3.fromRGB(0,255,0); t.Text = "💰 Safe"
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
-- [ COMBAT CORE ]
-- ==========================================
local function getNearestTarget()
    local closest, lowestScore = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if dist < AIM_FOV and dist < lowestScore then
                    lowestScore = dist
                    target = head
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    -- Aimlock & Prediction
    if aimlockEnabled and aiming and target and target.Parent then
        local root = target.Parent:FindFirstChild("HumanoidRootPart")
        if root then
            local predPos = target.Position + (root.Velocity * PREDICTION_STRENGTH)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predPos), SMOOTHNESS)
        end
    end
    -- Visuals
    if fullBrightEnabled then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    end
    if weaponEspEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            local char = p.Character
            local node = char and char:FindFirstChild("OctaText")
            if node then
                local tool = char:FindFirstChildOfClass("Tool")
                node.WeaponLabel.Text = tool and "[" .. tool.Name .. "]" or "[ None ]"
            end
        end
    end
end)

-- ==========================================
-- [ UI CONSTRUCTION ]
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🔫 Octa Scripts | Key-less Crim Hub 🔫",
   LoadingTitle = "Initializing Octa Precision",
   LoadingSubtitle = "Undetected Criminality Script",
   Theme = "Amethyst",
   ConfigurationSaving = { Enabled = true, FolderName = "OctaHub" }
})

-- COMBAT TAB
local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateSection("Aimbot Settings")
CombatTab:CreateToggle({
   Name = "Enable Aimlock",
   CurrentValue = false,
   Callback = function(v) aimlockEnabled = v end
})
CombatTab:CreateSlider({
   Name = "Smoothness (Speed)",
   Range = {0.1, 1},
   Increment = 0.1,
   CurrentValue = 0.4,
   Callback = function(v) SMOOTHNESS = v end
})
CombatTab:CreateSlider({
   Name = "Bullet Prediction",
   Range = {0, 0.5},
   Increment = 0.01,
   CurrentValue = 0.16,
   Callback = function(v) PREDICTION_STRENGTH = v end
})

-- VISUALS TAB
local VisualTab = Window:CreateTab("Visuals", 4483362458)
VisualTab:CreateSection("Player ESP")
VisualTab:CreateToggle({ Name = "Box Highlights", CurrentValue = false, Callback = function(v) espEnabled = v end })
VisualTab:CreateToggle({ Name = "Show Player Names", CurrentValue = false, Callback = function(v) nameEspEnabled = v end })
VisualTab:CreateToggle({ Name = "Show Held Weapons", CurrentValue = false, Callback = function(v) weaponEspEnabled = v end })
VisualTab:CreateSection("World ESP")
VisualTab:CreateToggle({ Name = "Show Safes & Registers", CurrentValue = false, Callback = function(v) safeEspEnabled = v end })
VisualTab:CreateToggle({ Name = "Full-Bright / No Shadows", CurrentValue = false, Callback = function(v) fullBrightEnabled = v end })

-- MISC TAB
local MiscTab = Window:CreateTab("Miscellaneous", 4483362458)
MiscTab:CreateSection("Utilities")
MiscTab:CreateToggle({ Name = "Anti-Fall Ragdoll", CurrentValue = false, Callback = function(v) noFallEnabled = v end })
MiscTab:CreateToggle({ Name = "No-Collide Doors", CurrentValue = false, Callback = function(v) toggleNoDoors(v) end })
MiscTab:CreateSection("Security")
MiscTab:CreateToggle({ Name = "Auto-Disconnect on Admin", CurrentValue = false, Callback = function(v) autoLeaveEnabled = v end })

-- [ INPUT HANDLERS ]
UIS.InputBegan:Connect(function(i,p) 
    if not p and i.UserInputType == Enum.UserInputType.MouseButton2 and aimlockEnabled then 
        aiming = true
        target = getNearestTarget()
    end 
end)
UIS.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end 
end)

Players.PlayerAdded:Connect(function(p)
    if autoLeaveEnabled and (p:GetRankInGroup(4802792) >= 50 or p.UserId == game.CreatorId) then
        LocalPlayer:Kick("Security Trigger: Staff member " .. p.Name .. " has joined.")
    end
end)

Rayfield:Notify({
   Title = "Octa Hub Active",
   Content = "Welcome to the premium Crim experience.",
   Duration = 5
})
