local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Dev Suite | Tactical Testing",
   LoadingTitle = "Initializing Engine",
   LoadingSubtitle = "Testing & Debugging Suite",
   ConfigurationSaving = { Enabled = false }
})

local VisualsTab = Window:CreateTab("Visuals (ESP)", 4483362458)
local CombatTab = Window:CreateTab("Combat (Aimbot)", 4483362458)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

_G.ESPEnabled = false
_G.AimbotEnabled = false
_G.AimFOV = 150
_G.AimSmoothness = 0.5 -- Default smoothness factor (0.1 to 1.0)

-- --- VISUALS TAB (ESP) ---
VisualsTab:CreateToggle({
   Name = "Player Highlights (ESP)",
   CurrentValue = false,
   Flag = "ESP_Toggle",
   Callback = function(Value)
      _G.ESPEnabled = Value
      task.spawn(function()
          while _G.ESPEnabled do
              for _, player in ipairs(Players:GetPlayers()) do
                  if player ~= LocalPlayer and player.Character then
                      local char = player.Character
                      if not char:FindFirstChild("DevHighlight") then
                          local hl = Instance.new("Highlight")
                          hl.Name = "DevHighlight"
                          hl.Adornee = char
                          hl.FillColor = Color3.fromRGB(255, 50, 50)
                          hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                          hl.FillTransparency = 0.4
                          hl.Parent = char
                      end
                  end
              end
              task.wait(1)
          end
          -- Clean up highlights when turned off
          for _, player in ipairs(Players:GetPlayers()) do
              if player.Character and player.Character:FindFirstChild("DevHighlight") then
                  player.Character.DevHighlight:Destroy()
              end
          end
      end)
   end,
})

-- --- COMBAT TAB (AIMBOT) ---
CombatTab:CreateToggle({
   Name = "Target Lock (Aimbot)",
   CurrentValue = false,
   Flag = "Aimbot_Toggle",
   Callback = function(Value)
      _G.AimbotEnabled = Value
   end,
})

CombatTab:CreateSlider({
   Name = "Aimbot FOV Radius",
   Range = {50, 400},
   Increment = 10,
   CurrentValue = 150,
   Flag = "FOV_Slider",
   Callback = function(Value)
      _G.AimFOV = Value
   end,
})

CombatTab:CreateSlider({
   Name = "Aimbot Strength / Smoothness",
   Range = {1, 10},
   Increment = 1,
   CurrentValue = 5,
   Flag = "Smoothness_Slider",
   Callback = function(Value)
      -- Convert 1-10 range into a smooth interpolation factor (0.1 to 1.0)
      _G.AimSmoothness = Value / 10
   end,
})

-- Main Target Loop with Hold-to-Aim (Right Click)
RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled then
        -- Check if the user is holding down the Right Mouse Button (Mouse2)
        local isHoldingAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if isHoldingAim then
            local closestTarget = nil
            local shortestDist = math.huge
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = player.Character.HumanoidRootPart
                        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            
                            if dist < shortestDist and dist < _G.AimFOV then
                                shortestDist = dist
                                closestTarget = hrp
                            end
                        end
                    end
                end
            end
            
            if closestTarget then
                local targetCF = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
                -- Smoothly interpolate camera rotation based on the smoothness slider
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, _G.AimSmoothness)
            end
        end
    end
end)

Rayfield:Notify({
   Title = "Dev Suite Loaded",
   Content = "Rayfield UI initialized with Hold-to-Aim & Smoothness settings.",
   Duration = 5,
})
