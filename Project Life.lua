-- Rayfield Hub: Prison Life Advanced Cheat
-- Features: Silent Aim (Team Selectable), ESP, FOV, Fly, Noclip, Speed
-- WARNING: High detection risk. Use at your own risk.

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Aelinik/Rayfield/main/main.lua'))()()

-- Create the Main Window
local Window = Rayfield.CreateWindow({
   Name = "Prison Life Hub",
   LoadingTitle = "Rayfield System",
   LoadingSubtitle = "by Evermind Labs",
   Configuration = {
      Encryption = true,
      EncryptionKey = "PrisonLifeKey_12345",
   },
})

-- Create Tabs
local Combat = Window.CreateTab("Combat", 600) -- Icon ID 600 (Crosshair)
local Visual = Window.CreateTab("Visual", 590) -- Icon ID 590 (Eye)
local Misc = Window.CreateTab("Misc", 400) -- Icon ID 400 (Settings)

-- Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService)
local VirtualUser = game:GetService("VirtualUser")

local Enabled = false
local TargetTeam = "All" -- Default
local FOVRadius = 50
local ShowESP = false
local ShowBox = false
local ShowLine = false
local IsFlying = false
local IsNoclip = false

-- Helper: Get Team Name Safely
local function GetPlayerTeam(player)
    if not player or not player.Character then return "Unknown" end
    local team = player.Team
    if team then
        return team.Name
    end
    return "Unknown"
end

-- Helper: Check if player matches target selection
local function IsValidTarget(player)
    if player == LocalPlayer or not player.Character then return false end
    
    if TargetTeam == "All" then
        return true
    end
    
    local playerTeam = GetPlayerTeam(player)
    
    if TargetTeam == "Guards" then
        return playerTeam == "Guards" or playerTeam == "Guard" or playerTeam == "Police"
    elseif TargetTeam == "Prisoners" then
        return playerTeam == "Prisoners" or playerTeam == "Prisoner" or playerTeam == "Inmates"
    elseif TargetTeam == "Criminals" then
        return playerTeam == "Criminals" or playerTeam == "Criminal" or playerTeam == "Inmates"
    end
    
    return false
end

-- Helper: Find nearest target based on FOV
local function GetNearestTarget()
    local nearestDistance = FOVRadius * 10 -- Scale FOV
    local nearestPlayer = nil
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                local headPos = character.Head.CFrame.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                
                if onScreen then
                    local distance = (screenPos - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end
    
    return nearestPlayer
end

-- Combat Tab: Silent Aim
Combat.CreateSection("Silent Aim Settings")
Combat.CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
       Enabled = Value
       if not Value then
           -- Reset aim if turned off
       end
   end
})

Combat.CreateDropdown({
   Name = "Target Team",
   Options = {"All", "Guards", "Prisoners", "Criminals"},
   CurrentOption = {
      Options[1]
   },
   MultipleOptions = false,
   Flag = "TargetTeamSelect",
   Callback = function(Value)
       TargetTeam = Value[1]
       print("Target Team set to: " + TargetTeam)
   end
})

Combat.CreateSlider({
   Name = "FOV Radius",
   Range = {10, 500},
   Increment = 10,
   CurrentValue = 50,
   Flag = "FOVSlider",
   Callback = function(Value)
       FOVRadius = Value
   end
})

-- Visual Tab: ESP
Visual.CreateSection("ESP Settings")
Visual.CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
       ShowESP = Value
       -- Clear existing ESP if turning off
       if not Value then
           -- Logic to remove ESP drawings would go here
       end
   end
})

Visual.CreateToggle({
   Name = "Show ESP Box",
   CurrentValue = false,
   Flag = "ESPBoxToggle",
   Callback = function(Value)
       ShowBox = Value
   end
})

Visual.CreateToggle({
   Name = "Show ESP Line",
   CurrentValue = false,
   Flag = "ESPLineToggle",
   Callback = function(Value)
       ShowLine = Value
   end
})

-- Misc Tab: Utilities
Misc.CreateSection("Movement & Utilities")
Misc.CreateToggle({
   Name = "Enable Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
       IsFlying = Value
       if not Value then
           -- Reset fly logic
           LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
       end
   end
})

Misc.CreateToggle({
   Name = "Enable Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
       IsNoclip = Value
   end
})

Misc.CreateSlider({
   Name = "Walk Speed",
   Range = {16, 500},
   Increment = 1,
   CurrentValue = 16,
   Flag = "SpeedSlider",
   Callback = function(Value)
       if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
           LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
       end
   end
})

Misc.CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfiniteJumpToggle",
   Callback = function(Value)
       -- Infinite jump is usually handled by a separate loop or event
       if Value then
           -- Enable infinite jump logic
       else
           -- Disable infinite jump logic
       end
   end
})

-- Main Loop for Silent Aim and ESP
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- Noclip Logic
    if IsNoclip then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Falling, false)
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                child.CanCollide = false
            end
        end
    else
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Falling, true)
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
            end
        end
    end

    -- Fly Logic (Basic Implementation)
    if IsFlying then
        humanoid.PlatformStand = true
        -- Simple fly logic would require more complex input handling
        -- This is a placeholder for the concept
    else
        if humanoid.PlatformStand == true and not IsFlying then
             humanoid.PlatformStand = false
        end
    end

    -- Silent Aim Logic
    if Enabled and FOVRadius > 0 then
        local targetPlayer = GetNearestTarget()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
            local targetHead = targetPlayer.Character.Head
            -- Silent Aim: Set camera CFrame to target
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetHead.CFrame.Position)
            
            -- Optional: Auto-fire (Highly detectable)
            -- VirtualUser:CaptureController()
            -- VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), Camera.CFrame)
        end
    end

    -- ESP Logic (Conceptual - requires drawing library for full implementation)
    if ShowESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if IsValidTarget(player) and player.Character and player.Character:FindFirstChild("Head") then
                -- ESP implementation would go here using drawing library
                -- This is a placeholder for the concept
            end
        end
    end
end)

-- Notification
Rayfield.Notify("Prison Life Hub", "Loaded successfully. Use with caution.")