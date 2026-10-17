-- Recovered from the previous conversation transcript.
-- This is not the original uploaded ProjectLife10.lua.
-- Silent Aim only selects targets / optionally camera-locks; it does not redirect shots.

--[[
Project Life.lua
Prison Life testing UI using Rayfield.
Notes:
- Intended for private/authorized testing only.
- Fixed: Noclip now uses stable while-loop implementation with proper
respawn handling
- Fixed: Silent Aim now includes dynamic Team filtering that detects
actual game teams
]]
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
-- State
local States = {
Combat = {
SilentAim = false,
CameraLock = false,
TargetTeam = "All",
FOV = 50,
HitChance = 100,
TargetPart = "Head",
CurrentTarget = nil,
},
Visuals = {
Master = false,
ESPLines = false,
ESPBoxes = false,
TeamChams = false,


},
Misc = {
Noclip = {Enabled = false, Thread = nil}, -- Fixed: Using threadbased implementation
InfiniteJump = false,
WalkSpeed = { Enabled = false, Value = 50, Original = 16 },
Fly = { Enabled = false, Speed = 50 },
},
}
local Drawings = {
FOVCircle = nil,
ESPLines = {},
ESPBoxes = {},
Chams = {},
}
local Connections = {
SilentAim = nil,
Visuals = nil,
InfiniteJump = nil,
Fly = nil,
CharacterAdded = nil,
TeamChanged = {},
}
local FlyBodyGyro, FlyBodyVelocity
local Unloaded = false
-- Helper Functions
local function getCamera()
Camera = Workspace.CurrentCamera or Camera
return Camera
end
local function worldToScreen(position)
local camera = getCamera()
local point, onScreen = camera:WorldToViewportPoint(position)
return Vector2.new(point.X, point.Y), onScreen, point.Z
end
local function getTeamName(player)
return (player and player.Team and player.Team.Name) or "Neutral"
end


local function getTeamColor(player)
local team = getTeamName(player)
if team == "Guards" then
return Color3.fromRGB(0, 120, 255)
elseif team == "Criminals" then
return Color3.fromRGB(255, 60, 60)
elseif team == "Prisoners" then
return Color3.fromRGB(255, 170, 0)
end
return Color3.fromRGB(235, 235, 235)
end
local function isCharacterAlive(character)
if not character or not character.Parent then return false end
local humanoid = character:FindFirstChildOfClass("Humanoid")
return humanoid ~= nil and humanoid.Health > 0
end
-- FIXED: Team-aware target validation
local function isValidTarget(player)
if not player or player ~= LocalPlayer then return false end
if not player.Character or not isCharacterAlive(player.Character) then
return false end
-- Team filtering logic
if States.Combat.TargetTeam ~= "All" then
local playerTeam = getTeamName(player)
if playerTeam ~= States.Combat.TargetTeam then
return false
end
end
return true
end
local function getTargetPart(character)
if not character then return nil end
local partName = States.Combat.TargetPart
local part = character:FindFirstChild(partName)
if part and part:IsA("BasePart") then return part end
if partName == "UpperTorso" or partName == "LowerTorso" or partName ==
"HumanoidRootPart" then
local torso = character:FindFirstChild("Torso")
if torso and torso:IsA("BasePart") then return torso end
end
return nil


end
local function safeRemoveDrawing(drawing)
if drawing then
pcall(function() drawing:Remove() end)
end
end
local function clearPlayerDrawings(player)
safeRemoveDrawing(Drawings.ESPLines[player])
Drawings.ESPLines[player] = nil
safeRemoveDrawing(Drawings.ESPBoxes[player])
Drawings.ESPBoxes[player] = nil
local highlight = Drawings.Chams[player]
if highlight then
pcall(function() highlight:Destroy() end)
Drawings.Chams[player] = nil
end
end
local function clearAllDrawings()
safeRemoveDrawing(Drawings.FOVCircle)
Drawings.FOVCircle = nil
local playersToClear = {}
for player in pairs(Drawings.ESPLines) do playersToClear[player] = true
end
for player in pairs(Drawings.ESPBoxes) do playersToClear[player] = true
end
for player in pairs(Drawings.Chams) do playersToClear[player] = true end
for player in pairs(playersToClear) do clearPlayerDrawings(player) end
end
local function disconnect(connection)
if connection then
pcall(function() connection:Disconnect() end)
end
end
-- ============================================
-- FIXED: WORKING NOCLIP IMPLEMENTATION
-- ============================================
local function getCharacter()
if LocalPlayer.Character then
return LocalPlayer.Character
else


repeat task.wait(0.1) until LocalPlayer.Character
return LocalPlayer.Character
end
end
local function noclipLoop()
while States.Misc.Noclip.Enabled do
local character = getCharacter()
if character then
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
task.wait()
end
-- Restore collision when disabled
local character = getCharacter()
if character then
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = true
end
end
end
end
local function setNoclip(enabled)
States.Misc.Noclip.Enabled = enabled
if enabled then
-- Prevent duplicate threads
if States.Misc.Noclip.Thread then
States.Misc.Noclip.Enabled = false -- Stop existing
task.wait(0.1)
States.Misc.Noclip.Enabled = true
end
States.Misc.Noclip.Thread = task.spawn(noclipLoop)
else
States.Misc.Noclip.Enabled = false
States.Misc.Noclip.Thread = nil
end
end
-- Handle respawn for noclip


LocalPlayer.CharacterAdded:Connect(function()
if States.Misc.Noclip.Enabled then
-- Restart noclip on new character
task.wait(0.2) -- Wait for character to load
if States.Misc.Noclip.Enabled then
setNoclip(true)
end
end
end)
-- ============================================
-- SILENT AIM WITH DYNAMIC TEAM FILTERING
-- ============================================
local function createFOVCircle()
safeRemoveDrawing(Drawings.FOVCircle)
local ok, circle = pcall(function() return Drawing.new("Circle") end)
if not ok or not circle then
Drawings.FOVCircle = nil
return
end
circle.Visible = false
circle.Thickness = 1.5
circle.Transparency = 0.7
circle.Color = Color3.fromRGB(255, 255, 255)
circle.Filled = false
circle.NumSides = 64
Drawings.FOVCircle = circle
end
local function getClosestTargetInFOV()
local camera = getCamera()
local center = Vector2.new(camera.ViewportSize.X / 2,
camera.ViewportSize.Y / 2)
local radius = States.Combat.FOV * 3
local closestPlayer, closestDistance = nil, math.huge
for _, player in ipairs(Players:GetPlayers()) do
if isValidTarget(player) then -- Includes team check
local part = getTargetPart(player.Character)
if part then
local screenPosition, onScreen, depth =
worldToScreen(part.Position)
if onScreen and depth > 0 then
local distance = (screenPosition - center).Magnitude
if distance <= radius and distance < closestDistance then


closestPlayer = player
closestDistance = distance
end
end
end
end
end
-- Apply hit chance only after selecting closest valid target
if closestPlayer and math.random(1, 100) > States.Combat.HitChance then
return nil
end
return closestPlayer
end
local function updateSilentAim()
disconnect(Connections.SilentAim)
Connections.SilentAim = nil
if not States.Combat.SilentAim then
if Drawings.FOVCircle then Drawings.FOVCircle.Visible = false end
States.Combat.CurrentTarget = nil
return
end
Connections.SilentAim = RunService.RenderStepped:Connect(function()
if Unloaded then return end
local camera = getCamera()
if Drawings.FOVCircle then
Drawings.FOVCircle.Visible = true
Drawings.FOVCircle.Radius = States.Combat.FOV * 3
Drawings.FOVCircle.Position =
Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end
-- Get target with team filtering applied
local target = getClosestTargetInFOV()
States.Combat.CurrentTarget = target
if target and States.Combat.CameraLock then
local part = target.Character and getTargetPart(target.Character)
if part then
camera.CFrame = CFrame.new(camera.CFrame.Position,
part.Position)
end


end
end)
end
-- ============================================
-- DYNAMIC TEAM DETECTION
-- ============================================
local function getAvailableTeams()
local teamList = {"All"}
for _, team in pairs(Teams:GetTeams()) do
if team.Name ~= "Neutral" then -- Exclude neutral if desired
table.insert(teamList, team.Name)
end
end
return teamList
end
-- ============================================
-- VISUALS (ESP/CHAMS)
-- ============================================
local function createChams(player, character)
local existing = Drawings.Chams[player]
if existing then
pcall(function() existing:Destroy() end)
Drawings.Chams[player] = nil
end
if not States.Visuals.Master or not States.Visuals.TeamChams or not
character or not isCharacterAlive(character) then
return
end
local highlight = Instance.new("Highlight")
highlight.Name = "ProjectLifeTeamHighlight"
highlight.Adornee = character
highlight.FillColor = getTeamColor(player)
highlight.OutlineColor = getTeamColor(player)
highlight.FillTransparency = 0.6
highlight.OutlineTransparency = 0.2
highlight.Parent = character
Drawings.Chams[player] = highlight
-- Auto-cleanup on death
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.Died:Connect(function()


if Drawings.Chams[player] then
Drawings.Chams[player]:Destroy()
Drawings.Chams[player] = nil
end
end)
end
end
local function updateVisuals()
disconnect(Connections.Visuals)
Connections.Visuals = nil
if not States.Visuals.Master then
for _, line in pairs(Drawings.ESPLines) do if line then line.Visible
= false end end
for _, box in pairs(Drawings.ESPBoxes) do if box then box.Visible =
false end end
return
end
Connections.Visuals = RunService.RenderStepped:Connect(function()
if Unloaded then return end
-- Cleanup disconnected players
for player, _ in pairs(Drawings.ESPLines) do
if not Players:FindFirstChild(player.Name) then
clearPlayerDrawings(player)
end
end
for _, player in pairs(Players:GetPlayers()) do
if player ~= LocalPlayer and player.Character then
if isCharacterAlive(player.Character) then
local root =
player.Character:FindFirstChild("HumanoidRootPart") or
player.Character:FindFirstChild("Torso")
if root and States.Visuals.ESPLines then
if not Drawings.ESPLines[player] then
local line = Drawing.new("Line")
line.Thickness = 1
line.Transparency = 0.8
Drawings.ESPLines[player] = line
end
local pos, onScreen = worldToScreen(root.Position)
Drawings.ESPLines[player].From =


Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
Drawings.ESPLines[player].To = pos
Drawings.ESPLines[player].Visible = onScreen
Drawings.ESPLines[player].Color =
getTeamColor(player)
end
if States.Visuals.TeamChams and not
Drawings.Chams[player] then
createChams(player, player.Character)
end
else
if Drawings.ESPLines[player] then
Drawings.ESPLines[player].Visible = false end
if Drawings.ESPBoxes[player] then
Drawings.ESPBoxes[player].Visible = false end
end
end
end
end)
end
-- ============================================
-- RAYFIELD UI
-- ============================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
Name = "Prison Life [FIXED]",
LoadingTitle = "Loading Fixed Version...",
LoadingSubtitle = "Noclip & Team Filter Fixed",
ConfigurationSaving = {Enabled = true, FolderName = "ProjectLife",
FileName = "Config"},
KeySystem = false
})
local CombatTab = Window:CreateTab("Combat")
local VisualTab = Window:CreateTab("Visual")
local MiscTab = Window:CreateTab("Misc")
local SettingsTab = Window:CreateTab("Settings")
-- Combat UI with Dynamic Team Selector
createFOVCircle()
CombatTab:CreateToggle({
Name = "Enable Silent Aim",


CurrentValue = false,
Callback = function(v)
States.Combat.SilentAim = v
updateSilentAim()
end
})
CombatTab:CreateToggle({
Name = "Camera Lock Assist",
CurrentValue = false,
Callback = function(v) States.Combat.CameraLock = v end
})
-- FIXED: Dynamic Team Dropdown
local TeamDropdown = CombatTab:CreateDropdown({
Name = "Target Team",
Options = getAvailableTeams(),
CurrentOption = "All",
Callback = function(v)
States.Combat.TargetTeam = v
print("Target team set to:", v)
end
})
-- Refresh teams when players join/leave or teams change
Teams.ChildAdded:Connect(function()
TeamDropdown:Refresh(getAvailableTeams(), "All")
end)
Teams.ChildRemoved:Connect(function()
TeamDropdown:Refresh(getAvailableTeams(), "All")
end)
CombatTab:CreateSlider({
Name = "FOV Radius",
Range = {10, 100},
Increment = 1,
Suffix = "%",
CurrentValue = 50,
Callback = function(v)
States.Combat.FOV = v
if Drawings.FOVCircle then Drawings.FOVCircle.Radius = v * 3 end
end
})
CombatTab:CreateSlider({


Name = "Hit Chance",
Range = {0, 100},
Increment = 1,
Suffix = "%",
CurrentValue = 100,
Callback = function(v) States.Combat.HitChance = v end
})
CombatTab:CreateDropdown({
Name = "Target Body Part",
Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
"Torso"},
CurrentOption = "Head",
Callback = function(v) States.Combat.TargetPart = v end
})
-- Visuals UI
VisualTab:CreateToggle({
Name = "Master Visuals",
CurrentValue = false,
Callback = function(v)
States.Visuals.Master = v
updateVisuals()
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
Name = "Team Chams",
CurrentValue = false,
Callback = function(v)
States.Visuals.TeamChams = v
if not v then
for _, cham in pairs(Drawings.Chams) do
if cham then cham:Destroy() end
end
Drawings.Chams = {}
else


for _, player in pairs(Players:GetPlayers()) do
if player ~= LocalPlayer and player.Character then
createChams(player, player.Character)
end
end
end
end
})
-- FIXED: Working Noclip Toggle
MiscTab:CreateToggle({
Name = "Noclip",
CurrentValue = false,
Callback = function(v)
setNoclip(v)
end
})
MiscTab:CreateToggle({
Name = "Infinite Jump",
CurrentValue = false,
Callback = function(v)
States.Misc.InfiniteJump = v
if Connections.InfiniteJump then
Connections.InfiniteJump:Disconnect() end
if v then
Connections.InfiniteJump =
UserInputService.JumpRequest:Connect(function()
if LocalPlayer.Character then
local hum =
LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end)
end
end
})
-- Settings
SettingsTab:CreateButton({
Name = "Cleanup Visual Objects",
Callback = function()
clearAllDrawings()
Rayfield:Notify({Title = "Cleanup", Content = "Visuals cleared",


Duration = 3})
end
})
SettingsTab:CreateButton({
Name = "Safe Unload",
Callback = function()
Unloaded = true
States.Combat.SilentAim = false
States.Visuals.Master = false
setNoclip(false)
updateSilentAim()
updateVisuals()
clearAllDrawings()
for _, conn in pairs(Connections) do disconnect(conn) end
Rayfield:Destroy()
end
})
-- Handle player joins/leaves for chams
Players.PlayerAdded:Connect(function(player)
player.CharacterAdded:Connect(function(char)
if States.Visuals.TeamChams then
task.wait(0.1)
createChams(player, char)
end
end)
end)
Players.PlayerRemoving:Connect(function(player)
clearPlayerDrawings(player)
end)
print("Project Life [FIXED] Loaded - Noclip and Team Filter Active")
