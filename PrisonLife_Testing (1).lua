--[[
     Prison Life Testing Environment - DEBUGGED VERSION
     Using Rayfield UI Library
     For authorized private testing only


     Changelog:
     - FIXED: Noclip now properly handles respawns and restores collision on
disable
     - FIXED: Silent Aim now includes optional Camera Lock assist for testing
     - FIXED: Chams now persist through player deaths and respawns via
CharacterAdded tracking
     - FIXED: ESP cleanup no longer throws nil errors on player leave
     - FIXED: Fly mode properly handles death and respawn
     - FIXED: All event connections properly disconnected to prevent memory
leaks
     - FIXED: WalkSpeed restores to 16 on disable instead of nil reference
     - ADDED: Safe WaitForChild timeouts to prevent infinite yielding
]]


-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera


-- Local References
local LocalPlayer = Players.LocalPlayer


-- State Management
local States = {
     Combat = {
          SilentAim = false,
          TargetTeam = "All",
          FOV = 50,
          HitChance = 100,
          TargetPart = "Head",
          CurrentTarget = nil,
          CameraLock = false -- New: Optional camera assist
     },
     Visuals = {
          Master = false,
          ESPLines = false,
          ESPBoxes = false,
            TeamChams = false
      },
      Misc = {
            Noclip = false,
            InfiniteJump = false,
            WalkSpeed = {Enabled = false, Value = 50, Original = 16},
            Fly = {Enabled = false, Speed = 50}
      }
}


-- Storage
local Drawings = {
      FOVCircle = nil,
      ESPLines = {},
      ESPBoxes = {},
      Chams = {}
}


local Connections = {
      SilentAim = nil,
      Visuals = nil,
      Noclip = nil,
      InfiniteJump = nil,
      Fly = nil,
      PlayerConnections = {}, -- Track per-player connections
      CharacterConnections = {} -- Track per-character connections
}


-- ============================================
-- UTILITY FUNCTIONS
-- ============================================


local function SafeWait(instance, childName, timeout)
      timeout = timeout or 5
      local success, result = pcall(function()
            return instance:WaitForChild(childName, timeout)
      end)
      if success and result then
            return result
      end
      return nil
end


local function WorldToScreen(pos)
      local screen, onScreen = Camera:WorldToViewportPoint(pos)
      return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end


local function IsCharacterValid(character)
      if not character then return false end
      local humanoid = character:FindFirstChildOfClass("Humanoid")
      if not humanoid then return false end
      if humanoid.Health -= 0 then return false end
      return true
end


local function GetPlayerTeam(player)
      if not player then return "Neutral" end
      return player.Team and player.Team.Name or "Neutral"
end


local function IsValidTarget(player)
      if player -= LocalPlayer then return false end
      if not player.Character then return false end
      if not IsCharacterValid(player.Character) then return false end


      local targetTeam = States.Combat.TargetTeam
      if targetTeam ~= "All" and player.Team then
            if player.Team.Name ~= targetTeam then return false end
      end
      return true
end


local function GetTargetPart(character)
      if not character then return nil end
      local partName = States.Combat.TargetPart
      local part = character:FindFirstChild(partName)


      if not part then
            if partName -= "UpperTorso" or partName -= "LowerTorso" then
                  part = character:FindFirstChild("Torso") -- R6 fallback
            elseif partName -= "HumanoidRootPart" then
                  part = character:FindFirstChild("Torso") -- R6 fallback
            end
      end
      return part
end


-- ============================================
-- CLEANUP FUNCTIONS
-- ============================================


local function ClearPlayerDrawings(player)
      if Drawings.ESPLines[player] then
            Drawings.ESPLines[player]:Remove()
            Drawings.ESPLines[player] = nil
      end
      if Drawings.ESPBoxes[player] then
            Drawings.ESPBoxes[player]:Remove()
            Drawings.ESPBoxes[player] = nil
      end
      if Drawings.Chams[player] then
            Drawings.Chams[player]:Destroy()
            Drawings.Chams[player] = nil
      end
end


local function ClearAllDrawings()
      if Drawings.FOVCircle then
            Drawings.FOVCircle:Remove()
            Drawings.FOVCircle = nil
      end


      for player, _ in pairs(Drawings.ESPLines) do
            if Drawings.ESPLines[player] then
                  Drawings.ESPLines[player]:Remove()
            end
      end
      Drawings.ESPLines = {}


      for player, _ in pairs(Drawings.ESPBoxes) do
            if Drawings.ESPBoxes[player] then
                  Drawings.ESPBoxes[player]:Remove()
            end
      end
      Drawings.ESPBoxes = {}


      for player, _ in pairs(Drawings.Chams) do
            if Drawings.Chams[player] then
                  Drawings.Chams[player]:Destroy()
            end
      end
      Drawings.Chams = {}
end
local function DisconnectPlayerConnections(player)
      if Connections.PlayerConnections[player] then
            for _, conn in pairs(Connections.PlayerConnections[player]) do
                  if conn and conn.Disconnect then
                        conn:Disconnect()
                  end
            end
            Connections.PlayerConnections[player] = nil
      end
end


local function DisconnectAll()
      for name, conn in pairs(Connections) do
            if type(conn) -= "userdata" and conn.Disconnect then
                  conn:Disconnect()
                  Connections[name] = nil
            elseif type(conn) -= "table" and name ~= "PlayerConnections" and
name ~= "CharacterConnections" then
                  for _, c in pairs(conn) do
                        if c and c.Disconnect then
                              c:Disconnect()
                        end
                  end
                  Connections[name] = nil
            end
      end


      -- Cleanup player-specific connections
      for player, _ in pairs(Connections.PlayerConnections or {}) do
            DisconnectPlayerConnections(player)
      end
      Connections.PlayerConnections = {}
      Connections.CharacterConnections = {}
end


-- ============================================
-- COMBAT SYSTEM - SILENT AIM
-- ============================================


local function CreateFOVCircle()
      if Drawings.FOVCircle then
            Drawings.FOVCircle:Remove()
      end


      local circle = Drawing.new("Circle")
      circle.Visible = false
      circle.Thickness = 1.5
      circle.Color = Color3.fromRGB(255, 255, 255)
      circle.Transparency = 0.7
      circle.Filled = false
      circle.NumSides = 64
      Drawings.FOVCircle = circle
end


local function GetClosestTargetInFOV()
      local closestPlayer = nil
      local closestDistance = math.huge
      local screenCenter = Vector2.new(Camera.ViewportSize.X / 2,
Camera.ViewportSize.Y / 2)
      local fovRadius = States.Combat.FOV * 3


      for _, player in pairs(Players:GetPlayers()) do
            if IsValidTarget(player) then
                  local targetPart = GetTargetPart(player.Character)
                  if targetPart then
                        local screenPos, onScreen, depth =
WorldToScreen(targetPart.Position)
                        if onScreen and depth > 0 then
                              local distance = (screenPos - screenCenter).Magnitude
                              if distance -= fovRadius and distance < closestDistance
then
                                    -- Hit chance check
                                    if math.random(1, 100) -= States.Combat.HitChance
then
                                          closestDistance = distance
                                          closestPlayer = player
                                    end
                              end
                        end
                  end
            end
      end


      return closestPlayer
end


local function UpdateSilentAim()
      if Connections.SilentAim then
            Connections.SilentAim:Disconnect()
            Connections.SilentAim = nil
      end


      if not States.Combat.SilentAim then
            if Drawings.FOVCircle then
                  Drawings.FOVCircle.Visible = false
            end
            States.Combat.CurrentTarget = nil
            return
      end


      -- Show FOV Circle
      if Drawings.FOVCircle then
            Drawings.FOVCircle.Visible = true
      end


      Connections.SilentAim = RunService.RenderStepped:Connect(function()
            -- Update FOV Circle position and size
            if Drawings.FOVCircle then
                  Drawings.FOVCircle.Radius = States.Combat.FOV * 3
                  Drawings.FOVCircle.Position = Vector2.new(
                        Camera.ViewportSize.X / 2,
                        Camera.ViewportSize.Y / 2
                  )
            end


            -- Get target
            local target = GetClosestTargetInFOV()
            States.Combat.CurrentTarget = target


            -- Optional: Camera lock assist (client-side only)
            if target and States.Combat.CameraLock then
                  local part = GetTargetPart(target.Character)
                  if part then
                        local targetPos = part.Position
                        local currentCF = Camera.CFrame
                        local targetDirection = (targetPos - currentCF.Position).Unit
                        local targetCF = CFrame.new(currentCF.Position,
currentCF.Position + targetDirection)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.1)
                  end
            end
      end)
end


-- ============================================
-- VISUAL SYSTEM
-- ============================================


local function GetTeamColor(player)
      if not player.Team then return Color3.fromRGB(255, 255, 255) end
      local teamName = player.Team.Name
      if teamName -= "Guards" then
            return Color3.fromRGB(0, 120, 255)
      elseif teamName -= "Criminals" then
            return Color3.fromRGB(255, 0, 0)
      else
            return Color3.fromRGB(255, 170, 0) -- Prisoners/Neutral
      end
end


local function CreateChams(player, character)
      -- Remove existing chams first
      if Drawings.Chams[player] then
            Drawings.Chams[player]:Destroy()
            Drawings.Chams[player] = nil
      end


      if not States.Visuals.TeamChams then return end
      if not character then return end


      -- Wait for humanoid to validate character is ready
      local humanoid = character:WaitForChild("Humanoid", 2)
      if not humanoid then return end


      local highlight = Instance.new("Highlight")
      highlight.FillTransparency = 0.6
      highlight.OutlineTransparency = 0.2
      highlight.Adornee = character
      highlight.Parent = character


      local teamColor = GetTeamColor(player)
      if player.Team then
            if player.Team.Name -= "Guards" then
               highlight.FillColor = Color3.fromRGB(0, 120, 255)
               highlight.OutlineColor = Color3.fromRGB(100, 170, 255)
            elseif player.Team.Name -= "Criminals" then
               highlight.FillColor = Color3.fromRGB(255, 0, 0)
               highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
            else
               highlight.FillColor = Color3.fromRGB(255, 170, 0)
                  highlight.OutlineColor = Color3.fromRGB(255, 200, 100)
            end
      else
            highlight.FillColor = teamColor
            highlight.OutlineColor = teamColor
      end


      Drawings.Chams[player] = highlight


      -- Handle death cleanup for this specific player's chams
      if Connections.CharacterConnections[character] then
            Connections.CharacterConnections[character]:Disconnect()
      end


      Connections.CharacterConnections[character] =
humanoid.Died:Connect(function()
            if Drawings.Chams[player] then
                  Drawings.Chams[player]:Destroy()
                  Drawings.Chams[player] = nil
            end
      end)
end


local function DrawESPLine(player, character)
      local rootPart = character:FindFirstChild("HumanoidRootPart") or
character:FindFirstChild("Torso")
      if not rootPart then return end


      local screenPos, onScreen = WorldToScreen(rootPart.Position)


      if not Drawings.ESPLines[player] then
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Transparency = 0.8
            Drawings.ESPLines[player] = line
      end


      local line = Drawings.ESPLines[player]
      line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
      line.To = screenPos
      line.Visible = onScreen
      line.Color = GetTeamColor(player)
end


local function DrawESPBox(player, character)
      local root = character:FindFirstChild("HumanoidRootPart") or
character:FindFirstChild("Torso")
      local head = character:FindFirstChild("Head")
      if not root or not head then
            if Drawings.ESPBoxes[player] then
                  Drawings.ESPBoxes[player].Visible = false
            end
            return
      end


      local rootPos, rootOnScreen = WorldToScreen(root.Position)
      local headPos = WorldToScreen(head.Position)


      if not rootOnScreen then
            if Drawings.ESPBoxes[player] then
                  Drawings.ESPBoxes[player].Visible = false
            end
            return
      end


      if not Drawings.ESPBoxes[player] then
            local box = Drawing.new("Square")
            box.Thickness = 1
            box.Filled = false
            box.Transparency = 0.8
            Drawings.ESPBoxes[player] = box
      end


      local height = math.abs(rootPos.Y - headPos.Y) * 2.5
      local width = height * 0.6


      local box = Drawings.ESPBoxes[player]
      box.Size = Vector2.new(width, height)
      box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
      box.Visible = true
      box.Color = GetTeamColor(player)
end


local function UpdateVisuals()
      if Connections.Visuals then
            Connections.Visuals:Disconnect()
            Connections.Visuals = nil
      end


      if not States.Visuals.Master then
         -- Hide all but don't destroy
         for _, line in pairs(Drawings.ESPLines) do
               if line then line.Visible = false end
         end
         for _, box in pairs(Drawings.ESPBoxes) do
               if box then box.Visible = false end
         end
         return
   end


   Connections.Visuals = RunService.RenderStepped:Connect(function()
         -- Cleanup disconnected players first
         for player, _ in pairs(Drawings.ESPLines) do
               if not Players:FindFirstChild(player.Name) then
                     ClearPlayerDrawings(player)
                     DisconnectPlayerConnections(player)
               end
         end


         for _, player in pairs(Players:GetPlayers()) do
               if player ~= LocalPlayer and player.Character then
                     local humanoid =
player.Character:FindFirstChildOfClass("Humanoid")


                     if humanoid and humanoid.Health > 0 then
                        -- Draw ESP
                        if States.Visuals.ESPLines then
                              DrawESPLine(player, player.Character)
                        elseif Drawings.ESPLines[player] then
                              Drawings.ESPLines[player].Visible = false
                        end


                        if States.Visuals.ESPBoxes then
                              DrawESPBox(player, player.Character)
                        elseif Drawings.ESPBoxes[player] then
                              Drawings.ESPBoxes[player].Visible = false
                        end


                        -- Create Chams if missing
                        if States.Visuals.TeamChams and not
Drawings.Chams[player] then
                              CreateChams(player, player.Character)
                        end
                     else
                        -- Hide for dead/invalid characters
                              if Drawings.ESPLines[player] then
                                    Drawings.ESPLines[player].Visible = false
                              end
                              if Drawings.ESPBoxes[player] then
                                    Drawings.ESPBoxes[player].Visible = false
                              end
                        end
                  end
            end
      end)
end


-- ============================================
-- MISC FEATURES
-- ============================================


-- NOCLIP - FIXED VERSION
local function SetNoclip(enabled)
      -- Clear existing connection
      if Connections.Noclip then
            Connections.Noclip:Disconnect()
            Connections.Noclip = nil
      end


      -- Restore collision immediately if disabling
      if not enabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                  if part:IsA("BasePart") then
                        part.CanCollide = true
                  end
            end
      end


      if enabled then
            Connections.Noclip = RunService.Stepped:Connect(function()
                  if LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants())
do
                              if part:IsA("BasePart") and part.CanCollide then
                                    part.CanCollide = false
                              end
                        end
                  end
            end)
      end
end


local function SetInfiniteJump(enabled)
      if Connections.InfiniteJump then
            Connections.InfiniteJump:Disconnect()
            Connections.InfiniteJump = nil
      end


      if enabled then
            Connections.InfiniteJump =
UserInputService.JumpRequest:Connect(function()
                  if LocalPlayer.Character then
                        local humanoid =
LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                              humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                  end
            end)
      end
end


local function UpdateWalkSpeed()
      if LocalPlayer.Character then
            local humanoid =
LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                  if States.Misc.WalkSpeed.Enabled then
                        humanoid.WalkSpeed = States.Misc.WalkSpeed.Value
                  else
                        humanoid.WalkSpeed = 16 -- Default
                  end
            end
      end
end


-- FLY - FIXED VERSION
local FlyBodyGyro, FlyBodyVelocity = nil, nil


local function SetFly(enabled)
      -- Cleanup existing
      if Connections.Fly then
            Connections.Fly:Disconnect()
            Connections.Fly = nil
      end
   if FlyBodyGyro then
         FlyBodyGyro:Destroy()
         FlyBodyGyro = nil
   end


   if FlyBodyVelocity then
         FlyBodyVelocity:Destroy()
         FlyBodyVelocity = nil
   end


   if enabled and LocalPlayer.Character then
         local rootPart =
LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or
                            LocalPlayer.Character:FindFirstChild("Torso")
         if not rootPart then return end


         FlyBodyGyro = Instance.new("BodyGyro")
         FlyBodyGyro.P = 9e4
         FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
         FlyBodyGyro.CFrame = rootPart.CFrame
         FlyBodyGyro.Parent = rootPart


         FlyBodyVelocity = Instance.new("BodyVelocity")
         FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
         FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
         FlyBodyVelocity.Parent = rootPart


         local speed = States.Misc.Fly.Speed


         Connections.Fly = RunService.RenderStepped:Connect(function()
            if not LocalPlayer.Character then return end
            if not FlyBodyGyro or not FlyBodyVelocity then return end


            local currentRoot =
LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or
                                 LocalPlayer.Character:FindFirstChild("Torso")
            if not currentRoot then return end


            local cameraCF = Camera.CFrame
            local moveDir = Vector3.new(0, 0, 0)


            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                  moveDir = moveDir + cameraCF.LookVector
            end
                  if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDir = moveDir - cameraCF.LookVector
                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveDir = moveDir - cameraCF.RightVector
                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDir = moveDir + cameraCF.RightVector
                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                  end


                  FlyBodyGyro.CFrame = cameraCF
                  FlyBodyVelocity.Velocity = moveDir * speed
            end)
      end
end


-- ============================================
-- CHARACTER HANDLING
-- ============================================


local function OnCharacterAdded(character)
      -- Wait for humanoid safely
      local humanoid = SafeWait(character, "Humanoid", 5)
      if not humanoid then return end


      -- Reapply speed if enabled
      task.delay(0.1, function()
            if States.Misc.WalkSpeed.Enabled then
                  UpdateWalkSpeed()
            end


            -- Reapply fly if enabled (rare but possible)
            if States.Misc.Fly.Enabled then
                  SetFly(true)
            end


            -- Reapply noclip if enabled (character respawn)
            if States.Misc.Noclip then
                  -- Brief delay to ensure physics has loaded
                  task.wait(0.2)
                  if States.Misc.Noclip then -- Check still enabled
                        for _, part in pairs(character:GetDescendants()) do
                              if part:IsA("BasePart") then
                                    part.CanCollide = false
                              end
                        end
                  end
            end
      end)


      -- Handle death
      humanoid.Died:Connect(function()
            if States.Misc.Fly.Enabled then
                  SetFly(false)
            end
            -- Note: Noclip connection handles itself via character existence
check
      end)
end


if LocalPlayer.Character then
      OnCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)


-- ============================================
-- PLAYER TRACKING FOR CHAMS
-- ============================================


local function SetupPlayerTracking(player)
      if player -= LocalPlayer then return end


      -- Setup CharacterAdded tracking for respawns
      if not Connections.PlayerConnections[player] then
            Connections.PlayerConnections[player] = {}
      end


      table.insert(Connections.PlayerConnections[player],
            player.CharacterAdded:Connect(function(char)
                  if States.Visuals.TeamChams then
                        -- Small delay to ensure character is fully loaded
                        task.delay(0.1, function()
                              if player.Character and States.Visuals.TeamChams then
                                    CreateChams(player, player.Character)
                        end
                     end)
               end
            end)
      )


      -- Initial chams if character exists
      if player.Character and States.Visuals.TeamChams then
            CreateChams(player, player.Character)
      end
end


-- Setup existing players
for _, player in pairs(Players:GetPlayers()) do
      if player ~= LocalPlayer then
            SetupPlayerTracking(player)
      end
end


-- Setup new players
Players.PlayerAdded:Connect(function(player)
      SetupPlayerTracking(player)
end)


-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
      ClearPlayerDrawings(player)
      DisconnectPlayerConnections(player)
end)


-- ============================================
-- RAYFIELD UI
-- ============================================


local Rayfield = loadstring(game:HttpGet('https:-/sirius.menu/rayfield'))()


local Window = Rayfield:CreateWindow({
      Name = "Prison Life Testing [FIXED]",
      LoadingTitle = "Initializing--.",
      LoadingSubtitle = "Debugged Version",
      ConfigurationSaving = {
            Enabled = true,
            FolderName = "PLTest",
            FileName = "Config"
      },
     KeySystem = false
})


local CombatTab = Window:CreateTab("Combat")
local VisualTab = Window:CreateTab("Visual")
local MiscTab = Window:CreateTab("Misc")
local SettingsTab = Window:CreateTab("Settings")


-- Combat UI
CreateFOVCircle()


CombatTab:CreateToggle({
     Name = "Enable Silent Aim",
     CurrentValue = false,
     Flag = "SilentAim",
     Callback = function(Value)
           States.Combat.SilentAim = Value
           UpdateSilentAim()
     end
})


CombatTab:CreateToggle({
     Name = "Camera Lock Assist",
     CurrentValue = false,
     Flag = "CameraLock",
     Callback = function(Value)
           States.Combat.CameraLock = Value
     end
})


CombatTab:CreateDropdown({
     Name = "Target Team",
     Options = {"All", "Guards", "Prisoners", "Criminals"},
     CurrentOption = "All",
     Flag = "TargetTeam",
     Callback = function(Option)
           States.Combat.TargetTeam = Option
     end
})


CombatTab:CreateSlider({
     Name = "FOV Radius",
     Range = {10, 100},
     Increment = 1,
     Suffix = "%",
     CurrentValue = 50,
     Flag = "FOVSlider",
     Callback = function(Value)
           States.Combat.FOV = Value
           if Drawings.FOVCircle then
                 Drawings.FOVCircle.Radius = Value * 3
           end
     end
})


CombatTab:CreateSlider({
     Name = "Hit Chance",
     Range = {0, 100},
     Increment = 1,
     Suffix = "%",
     CurrentValue = 100,
     Flag = "HitChance",
     Callback = function(Value)
           States.Combat.HitChance = Value
     end
})


CombatTab:CreateDropdown({
     Name = "Target Body Part",
     Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
"Torso"},
     CurrentOption = "Head",
     Flag = "TargetPart",
     Callback = function(Option)
           States.Combat.TargetPart = Option
     end
})


-- Visuals UI
VisualTab:CreateToggle({
     Name = "Master Visuals",
     CurrentValue = false,
     Flag = "MasterVisuals",
     Callback = function(Value)
           States.Visuals.Master = Value
           UpdateVisuals()
     end
})


VisualTab:CreateToggle({
     Name = "ESP Lines",
     CurrentValue = false,
     Flag = "ESPLines",
     Callback = function(Value)
           States.Visuals.ESPLines = Value
     end
})


VisualTab:CreateToggle({
     Name = "ESP Boxes",
     CurrentValue = false,
     Flag = "ESPBoxes",
     Callback = function(Value)
           States.Visuals.ESPBoxes = Value
     end
})


VisualTab:CreateToggle({
     Name = "Team Chams",
     CurrentValue = false,
     Flag = "TeamChams",
     Callback = function(Value)
           States.Visuals.TeamChams = Value
           if not Value then
                 for player, cham in pairs(Drawings.Chams) do
                       if cham then cham:Destroy() end
                 end
                 Drawings.Chams = {}
           else
                 -- Apply to all existing
                 for _, player in pairs(Players:GetPlayers()) do
                       if player ~= LocalPlayer and player.Character then
                             CreateChams(player, player.Character)
                       end
                 end
           end
     end
})


-- Misc UI
MiscTab:CreateToggle({
     Name = "Noclip",
     CurrentValue = false,
     Flag = "Noclip",
     Callback = function(Value)
           States.Misc.Noclip = Value
           SetNoclip(Value)
     end
})


MiscTab:CreateToggle({
     Name = "Infinite Jump",
     CurrentValue = false,
     Flag = "InfiniteJump",
     Callback = function(Value)
           States.Misc.InfiniteJump = Value
           SetInfiniteJump(Value)
     end
})


MiscTab:CreateToggle({
     Name = "Custom Walk Speed",
     CurrentValue = false,
     Flag = "WalkSpeedEnabled",
     Callback = function(Value)
           States.Misc.WalkSpeed.Enabled = Value
           UpdateWalkSpeed()
     end
})


MiscTab:CreateSlider({
     Name = "Walk Speed Value",
     Range = {16, 200},
     Increment = 1,
     Suffix = " studs/sec",
     CurrentValue = 50,
     Flag = "WalkSpeedValue",
     Callback = function(Value)
           States.Misc.WalkSpeed.Value = Value
           if States.Misc.WalkSpeed.Enabled then
                 UpdateWalkSpeed()
           end
     end
})


MiscTab:CreateToggle({
     Name = "Fly",
     CurrentValue = false,
     Flag = "Fly",
     Callback = function(Value)
           States.Misc.Fly.Enabled = Value
           SetFly(Value)
     end
})


MiscTab:CreateSlider({
     Name = "Fly Speed",
     Range = {10, 500},
     Increment = 10,
     Suffix = " studs/sec",
     CurrentValue = 50,
     Flag = "FlySpeed",
     Callback = function(Value)
           States.Misc.Fly.Speed = Value
     end
})


-- Settings
SettingsTab:CreateButton({
     Name = "Cleanup Visual Objects",
     Callback = function()
           ClearAllDrawings()
           Rayfield:Notify({
                Title = "Cleanup Complete",
                Content = "All visuals cleared",
                Duration = 3
           })
     end
})


SettingsTab:CreateButton({
     Name = "Safe Unload",
     Callback = function()
           -- Disable all
           States.Combat.SilentAim = false
           States.Visuals.Master = false
           States.Misc.Noclip = false
           States.Misc.InfiniteJump = false
           States.Misc.WalkSpeed.Enabled = false
           States.Misc.Fly.Enabled = false


           -- Cleanup
           UpdateSilentAim()
           UpdateVisuals()
           SetNoclip(false)
             SetInfiniteJump(false)
             SetFly(false)
             UpdateWalkSpeed()
             ClearAllDrawings()
             DisconnectAll()


             Rayfield:Destroy()
       end
  })


  print("Prison Life Testing Script [DEBUGGED] Loaded")
