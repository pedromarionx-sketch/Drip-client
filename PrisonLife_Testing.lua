-- Prison Life Testing script extracted from the final code in the supplied PDF.
-- Review before use: the Silent Aim section only selects/stores a target; it does not
-- hook weapon firing, so it is not a complete working Silent Aim implementation.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- State Management
local States = {
      Combat = {
            SilentAim = false, TargetTeam = "All", FOV = 50,
            HitChance = 100, TargetPart = "Head"
      },
      Visuals = {Master = false, ESPLines = false, ESPBoxes = false, TeamChams = false},
      Misc = {
            Noclip = false, InfiniteJump = false,
            WalkSpeed = {Enabled = false, Value = 50, Original = 16},
            Fly = {Enabled = false, Speed = 50}
      }
}

-- Storage
local Drawings = {FOVCircle = nil, ESPLines = {}, ESPBoxes = {}, Chams = {}}
local Connections = {}

-- Utility Functions
local function WorldToScreen(pos)
      local screen, onScreen = Camera:WorldToViewportPoint(pos)
      return Vector2.new(screen.X, screen.Y), onScreen
end

local function IsValidTarget(plr)
      if plr == LocalPlayer or not plr.Character then return false end
      local hum = plr.Character:FindFirstChildOfClass("Humanoid")
      if not hum or hum.Health <= 0 then return false end
      if States.Combat.TargetTeam ~= "All" and plr.Team then
            return plr.Team.Name == States.Combat.TargetTeam
      end
      return true
end

local function GetTargetPart(char)
      local part = char:FindFirstChild(States.Combat.TargetPart)
      if not part then part = char:FindFirstChild("Torso") end
      return part
end

-- Cleanup Functions
local function ClearDrawings()
      if Drawings.FOVCircle then
            Drawings.FOVCircle:Remove()
            Drawings.FOVCircle = nil
      end
      for _, d in pairs(Drawings.ESPLines) do
            if d then d:Remove() end
      end
      for _, d in pairs(Drawings.ESPBoxes) do
            if d then d:Remove() end
      end
      for _, c in pairs(Drawings.Chams) do
            if c then c:Destroy() end
      end
      Drawings.ESPLines = {}
      Drawings.ESPBoxes = {}
      Drawings.Chams = {}
end

local function DisconnectAll()
      for name, c in pairs(Connections) do
            if c and c.Disconnect then
                  c:Disconnect()
            end
            Connections[name] = nil
      end
end

-- Combat System
local function CreateFOV()
      local c = Drawing.new("Circle")
      c.Visible = false
      c.Thickness = 1.5
      c.Transparency = 0.7
      c.Color = Color3.fromRGB(255,255,255)
      c.NumSides = 64
      Drawings.FOVCircle = c
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
         return
   end

   if Drawings.FOVCircle then
         Drawings.FOVCircle.Visible = true
   end

   Connections.SilentAim = RunService.RenderStepped:Connect(function()
         if Drawings.FOVCircle then
               Drawings.FOVCircle.Radius = States.Combat.FOV * 3
               Drawings.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/
2, Camera.ViewportSize.Y/2)
         end

         local target, closest = nil, math.huge
         local center = Vector2.new(Camera.ViewportSize.X/2,
Camera.ViewportSize.Y/2)

         for _, p in pairs(Players:GetPlayers()) do
               if IsValidTarget(p) then
                     local part = GetTargetPart(p.Character)
                     if part then
                           local pos, onScreen = WorldToScreen(part.Position)
                           if onScreen then
                                 local dist = (pos - center).Magnitude
                                 if dist <= States.Combat.FOV * 3 and dist < closest
then
                                       closest = dist
                                       target = p
                                 end
                           end
                     end
               end
         end

      end)
end

-- Visual System - ESP Lines
local function DrawESP(p, char)
      local root = char:FindFirstChild("HumanoidRootPart") or
char:FindFirstChild("Torso")
      if not root then return end
      local pos, onScreen = WorldToScreen(root.Position)

      if States.Visuals.ESPLines then
            if not Drawings.ESPLines[p] then
                  local l = Drawing.new("Line")
                  l.Thickness = 1
                  l.Transparency = 0.8
                  Drawings.ESPLines[p] = l
            end
            Drawings.ESPLines[p].From = Vector2.new(Camera.ViewportSize.X/2,
Camera.ViewportSize.Y)
            Drawings.ESPLines[p].To = pos
            Drawings.ESPLines[p].Visible = onScreen

            local teamColor = Color3.fromRGB(255,255,255)
            if p.Team then
                  if p.Team.Name == "Guards" then
                        teamColor = Color3.fromRGB(0,120,255)
                  elseif p.Team.Name == "Criminals" then
                        teamColor = Color3.fromRGB(255,0,0)
                  else
                        teamColor = Color3.fromRGB(255,170,0)
                  end
            end
            Drawings.ESPLines[p].Color = teamColor
      end
end

-- Visual System - ESP Boxes
local function DrawBox(p, char)
      local root = char:FindFirstChild("HumanoidRootPart") or
char:FindFirstChild("Torso")
      local head = char:FindFirstChild("Head")
      if not root or not head then return end

      local rootPos, onScreen = WorldToScreen(root.Position)
      if not onScreen then

            if Drawings.ESPBoxes[p] then
                  Drawings.ESPBoxes[p].Visible = false
            end
            return
      end

      local headPos = WorldToScreen(head.Position)
      local height = math.abs(rootPos.Y - headPos.Y) * 2.5
      local width = height * 0.6

      if not Drawings.ESPBoxes[p] then
            local box = Drawing.new("Square")
            box.Thickness = 1
            box.Filled = false
            box.Transparency = 0.8
            Drawings.ESPBoxes[p] = box
      end

      Drawings.ESPBoxes[p].Size = Vector2.new(width, height)
      Drawings.ESPBoxes[p].Position = Vector2.new(rootPos.X - width/2,
rootPos.Y - height/2)
      Drawings.ESPBoxes[p].Visible = true

      local teamColor = Color3.fromRGB(255,255,255)
      if p.Team then
            if p.Team.Name == "Guards" then
                  teamColor = Color3.fromRGB(0,120,255)
            elseif p.Team.Name == "Criminals" then
                  teamColor = Color3.fromRGB(255,0,0)
            else
                  teamColor = Color3.fromRGB(255,170,0)
            end
      end
      Drawings.ESPBoxes[p].Color = teamColor
end

-- Visual System - Team Chams
local function CreateChams(p, char)
      if Drawings.Chams[p] then
            Drawings.Chams[p]:Destroy()
      end

      local highlight = Instance.new("Highlight")
      highlight.FillTransparency = 0.6
      highlight.OutlineTransparency = 0.2

      highlight.Adornee = char

      local fillColor = Color3.fromRGB(255,170,0)
      local outlineColor = Color3.fromRGB(255,200,100)

      if p.Team then
            if p.Team.Name == "Guards" then
                  fillColor = Color3.fromRGB(0,120,255)
                  outlineColor = Color3.fromRGB(100,170,255)
            elseif p.Team.Name == "Criminals" then
                  fillColor = Color3.fromRGB(255,0,0)
                  outlineColor = Color3.fromRGB(255,100,100)
            end
      end

      highlight.FillColor = fillColor
      highlight.OutlineColor = outlineColor
      highlight.Parent = char
      Drawings.Chams[p] = highlight
end

local function UpdateVisuals()
      if Connections.Visuals then
            Connections.Visuals:Disconnect()
            Connections.Visuals = nil
      end

      if not States.Visuals.Master then
            for _, d in pairs(Drawings.ESPLines) do
                  if d then d.Visible = false end
            end
            for _, d in pairs(Drawings.ESPBoxes) do
                  if d then d.Visible = false end
            end
            return
      end

      Connections.Visuals = RunService.RenderStepped:Connect(function()
            for _, p in pairs(Players:GetPlayers()) do
                  if p ~= LocalPlayer and p.Character then
                     local hum = p.Character:FindFirstChildOfClass("Humanoid")
                     if hum and hum.Health > 0 then
                         if States.Visuals.ESPLines then
                               DrawESP(p, p.Character)
                         end

                              if States.Visuals.ESPBoxes then
                                    DrawBox(p, p.Character)
                              end
                              if States.Visuals.TeamChams and not Drawings.Chams[p]
then
                                    CreateChams(p, p.Character)
                              end
                        else
                              if Drawings.ESPLines[p] then
                                    Drawings.ESPLines[p].Visible = false
                              end
                              if Drawings.ESPBoxes[p] then
                                    Drawings.ESPBoxes[p].Visible = false
                              end
                        end
                  end
            end
      end)
end

-- Misc Features - Noclip
local function SetNoclip(v)
      if Connections.Noclip then
            Connections.Noclip:Disconnect()
            Connections.Noclip = nil
      end

      if v then
            Connections.Noclip = RunService.Stepped:Connect(function()
                  if LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants())
do
                              if part:IsA("BasePart") then
                                    part.CanCollide = false
                              end
                        end
                  end
            end)
      else
            if LocalPlayer.Character then
                  for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                              part.CanCollide = true
                        end
                  end

            end
      end
end

-- Misc Features - Infinite Jump
local function SetInfiniteJump(v)
      if Connections.InfiniteJump then
            Connections.InfiniteJump:Disconnect()
            Connections.InfiniteJump = nil
      end

      if v then
            Connections.InfiniteJump =
UserInputService.JumpRequest:Connect(function()
                  if LocalPlayer.Character then
                        local h =
LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if h then
                              h:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                  end
            end)
      end
end

-- Misc Features - Walk Speed
local function UpdateWalkSpeed()
      if LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then
                  if States.Misc.WalkSpeed.Enabled then
                        h.WalkSpeed = States.Misc.WalkSpeed.Value
                  else
                        h.WalkSpeed = 16
                  end
            end
      end
end

-- Misc Features - Fly
local FlyBodyGyro, FlyBodyVelocity = nil, nil

local function SetFly(enabled)
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
         local root =
LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or
LocalPlayer.Character:FindFirstChild("Torso")
         if not root then return end

         FlyBodyGyro = Instance.new("BodyGyro")
         FlyBodyGyro.P = 9e4
         FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
         FlyBodyGyro.CFrame = root.CFrame
         FlyBodyGyro.Parent = root

         FlyBodyVelocity = Instance.new("BodyVelocity")
         FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
         FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
         FlyBodyVelocity.Parent = root

         Connections.Fly = RunService.RenderStepped:Connect(function()
            if not LocalPlayer.Character or not FlyBodyGyro or not
FlyBodyVelocity then return end

            local camCF = Camera.CFrame
            local move = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                  move = move + camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                  move = move - camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                  move = move - camCF.RightVector

                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        move = move + camCF.RightVector
                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        move = move + Vector3.new(0, 1, 0)
                  end
                  if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        move = move - Vector3.new(0, 1, 0)
                  end

                  FlyBodyGyro.CFrame = camCF
                  FlyBodyVelocity.Velocity = move * States.Misc.Fly.Speed
            end)
      end
end

-- Character Handler
local function OnCharacterAdded(char)
      task.wait(0.1)
      if States.Misc.WalkSpeed.Enabled then
            UpdateWalkSpeed()
      end
      if States.Misc.Fly.Enabled then
            SetFly(true)
      end

      local hum = char:WaitForChild("Humanoid")
      hum.Died:Connect(function()
            if States.Misc.Fly.Enabled then
                  SetFly(false)
            end
      end)
end

if LocalPlayer.Character then
      OnCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
      Name = "Prison Life Testing",
      LoadingTitle = "Initializing--.",

     LoadingSubtitle = "Testing Environment",
     ConfigurationSaving = {Enabled = true, FolderName = "PLTest", FileName =
"Config"},
     KeySystem = false
})

local CombatTab = Window:CreateTab("Combat")
local VisualTab = Window:CreateTab("Visual")
local MiscTab = Window:CreateTab("Misc")
local SettingsTab = Window:CreateTab("Settings")

-- Combat UI
CreateFOV()
CombatTab:CreateToggle({
     Name = "Enable Silent Aim",
     CurrentValue = false,
     Callback = function(v)
           States.Combat.SilentAim = v
           UpdateSilentAim()
     end
})

CombatTab:CreateDropdown({
     Name = "Target Team",
     Options = {"All", "Guards", "Prisoners", "Criminals"},
     CurrentOption = "All",
     Callback = function(v)
           States.Combat.TargetTeam = v
     end
})

CombatTab:CreateSlider({
     Name = "FOV",
     Range = {10, 100},
     Increment = 1,
     Suffix = "%",
     CurrentValue = 50,
     Callback = function(v)
           States.Combat.FOV = v
           if Drawings.FOVCircle then
                 Drawings.FOVCircle.Radius = v * 3
           end
     end
})

CombatTab:CreateSlider({
     Name = "Hit Chance",
     Range = {0, 100},
     Increment = 1,
     Suffix = "%",
     CurrentValue = 100,
     Callback = function(v)
           States.Combat.HitChance = v
     end
})

CombatTab:CreateDropdown({
     Name = "Target Body Part",
     Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
"Torso"},
     CurrentOption = "Head",
     Callback = function(v)
           States.Combat.TargetPart = v
     end
})

-- Visuals UI
VisualTab:CreateToggle({
     Name = "Master Visuals",
     CurrentValue = false,
     Callback = function(v)
           States.Visuals.Master = v
           UpdateVisuals()
     end
})

VisualTab:CreateToggle({
     Name = "ESP Lines",
     CurrentValue = false,
     Callback = function(v)
           States.Visuals.ESPLines = v
     end
})

VisualTab:CreateToggle({
     Name = "ESP Boxes",
     CurrentValue = false,
     Callback = function(v)
           States.Visuals.ESPBoxes = v
     end

})

VisualTab:CreateToggle({
     Name = "Team Chams",
     CurrentValue = false,
     Callback = function(v)
           States.Visuals.TeamChams = v
           if not v then
                 for _, cham in pairs(Drawings.Chams) do
                       if cham then cham:Destroy() end
                 end
                 Drawings.Chams = {}
           end
     end
})

-- Misc UI
MiscTab:CreateToggle({
     Name = "Noclip",
     CurrentValue = false,
     Callback = function(v)
           States.Misc.Noclip = v
           SetNoclip(v)
     end
})

MiscTab:CreateToggle({
     Name = "Infinite Jump",
     CurrentValue = false,
     Callback = function(v)
           States.Misc.InfiniteJump = v
           SetInfiniteJump(v)
     end
})

MiscTab:CreateToggle({
     Name = "Custom Walk Speed",
     CurrentValue = false,
     Callback = function(v)
           States.Misc.WalkSpeed.Enabled = v
           UpdateWalkSpeed()
     end
})

MiscTab:CreateSlider({

     Name = "Walk Speed",
     Range = {16, 200},
     Increment = 1,
     Suffix = " studs/sec",
     CurrentValue = 50,
     Callback = function(v)
           States.Misc.WalkSpeed.Value = v
           if States.Misc.WalkSpeed.Enabled then
                 UpdateWalkSpeed()
           end
     end
})

MiscTab:CreateToggle({
     Name = "Fly",
     CurrentValue = false,
     Callback = function(v)
           States.Misc.Fly.Enabled = v
           SetFly(v)
     end
})

MiscTab:CreateSlider({
     Name = "Fly Speed",
     Range = {10, 500},
     Increment = 10,
     Suffix = " studs/sec",
     CurrentValue = 50,
     Callback = function(v)
           States.Misc.Fly.Speed = v
     end
})

-- Settings UI
SettingsTab:CreateButton({
     Name = "Cleanup Visuals",
     Callback = function()
           ClearDrawings()
           Rayfield:Notify({
                 Title = "Cleanup",
                 Content = "All visuals cleared",
                 Duration = 3
           })
     end
})

  SettingsTab:CreateButton({
       Name = "Safe Unload",
       Callback = function()
             -- Disable all features
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
             ClearDrawings()
             DisconnectAll()

             Rayfield:Destroy()
       end
  })

  -- Team Change Detection
  Players.PlayerAdded:Connect(function(p)
       p:GetPropertyChangedSignal("Team"):Connect(function()
             if Drawings.Chams[p] then
                   Drawings.Chams[p]:Destroy()
                   Drawings.Chams[p] = nil
                   if p.Character and States.Visuals.TeamChams then
                         CreateChams(p, p.Character)
                   end
             end
       end)
  end)

  print("Prison Life Testing Script Loaded")
