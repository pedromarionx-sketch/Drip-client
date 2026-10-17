--[[
    Project Life.lua
    Prison Life testing UI using Rayfield.

    Notes:
    - Intended for private/authorized testing only.
    - The targeting section selects a target and optionally provides camera-lock
      assistance. It does NOT intercept or redirect weapon shots, so it is not a
      complete Silent Aim implementation.
    - Drawing is executor-specific and is not part of standard Roblox Luau.
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
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
        Noclip = false,
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
    Noclip = nil,
    InfiniteJump = nil,
    Fly = nil,
    CharacterAdded = nil,
    PlayerAdded = nil,
    PlayerRemoving = nil,
    PlayerEvents = {},
}

local FlyBodyGyro, FlyBodyVelocity
local Unloaded = false
local OriginalCollision = setmetatable({}, { __mode = "k" })

-- Helpers
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

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character or not isCharacterAlive(player.Character) then return false end
    if States.Combat.TargetTeam ~= "All" and getTeamName(player) ~= States.Combat.TargetTeam then
        return false
    end
    return true
end

local function getTargetPart(character)
    if not character then return nil end
    local partName = States.Combat.TargetPart
    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then return part end
    if partName == "UpperTorso" or partName == "LowerTorso" or partName == "HumanoidRootPart" then
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
    for player in pairs(Drawings.ESPLines) do playersToClear[player] = true end
    for player in pairs(Drawings.ESPBoxes) do playersToClear[player] = true end
    for player in pairs(Drawings.Chams) do playersToClear[player] = true end
    for player in pairs(playersToClear) do clearPlayerDrawings(player) end
end

local function disconnect(connection)
    if connection then
        pcall(function() connection:Disconnect() end)
    end
end

local function disconnectPlayerEvents(player)
    local list = Connections.PlayerEvents[player]
    if list then
        for _, connection in ipairs(list) do disconnect(connection) end
        Connections.PlayerEvents[player] = nil
    end
end

local function disconnectAll()
    for key, connection in pairs(Connections) do
        if typeof(connection) == "RBXScriptConnection" then
            disconnect(connection)
            Connections[key] = nil
        elseif key == "PlayerEvents" then
            for player in pairs(connection) do disconnectPlayerEvents(player) end
        end
    end
end

-- FOV / target selection
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
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local radius = States.Combat.FOV * 3
    local closestPlayer, closestDistance = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local part = getTargetPart(player.Character)
            if part then
                local screenPosition, onScreen, depth = worldToScreen(part.Position)
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

    -- Apply hit chance only after a valid in-FOV target has been selected.
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
            Drawings.FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        end

        local target = getClosestTargetInFOV()
        States.Combat.CurrentTarget = target
        if target and States.Combat.CameraLock then
            local part = target.Character and getTargetPart(target.Character)
            if part then
                camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
            end
        end
    end)
end

-- Chams / ESP
local function createChams(player, character)
    local existing = Drawings.Chams[player]
    if existing then
        pcall(function() existing:Destroy() end)
        Drawings.Chams[player] = nil
    end
    if not States.Visuals.Master or not States.Visuals.TeamChams or not character or not isCharacterAlive(character) then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ProjectLifeTeamHighlight"
    highlight.Adornee = character
    highlight.FillColor = getTeamColor(player)
    highlight.OutlineColor = getTeamColor(player)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.15
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    Drawings.Chams[player] = highlight
end

local function drawESPLine(player, character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not root then
        if Drawings.ESPLines[player] then Drawings.ESPLines[player].Visible = false end
        return
    end

    local position, onScreen = worldToScreen(root.Position)
    if not Drawings.ESPLines[player] then
        local ok, line = pcall(function() return Drawing.new("Line") end)
        if not ok or not line then return end
        line.Thickness = 1
        line.Transparency = 0.8
        Drawings.ESPLines[player] = line
    end

    local line = Drawings.ESPLines[player]
    local camera = getCamera()
    line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    line.To = position
    line.Color = getTeamColor(player)
    line.Visible = onScreen
end

local function drawESPBox(player, character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    local head = character:FindFirstChild("Head")
    if not root or not head then
        if Drawings.ESPBoxes[player] then Drawings.ESPBoxes[player].Visible = false end
        return
    end

    local rootPosition, rootOnScreen = worldToScreen(root.Position)
    local headPosition, headOnScreen = worldToScreen(head.Position)
    if not rootOnScreen or not headOnScreen then
        if Drawings.ESPBoxes[player] then Drawings.ESPBoxes[player].Visible = false end
        return
    end

    local height = math.max(8, math.abs(rootPosition.Y - headPosition.Y) * 2.4)
    local width = height * 0.6
    if not Drawings.ESPBoxes[player] then
        local ok, box = pcall(function() return Drawing.new("Square") end)
        if not ok or not box then return end
        box.Thickness = 1
        box.Filled = false
        box.Transparency = 0.8
        Drawings.ESPBoxes[player] = box
    end

    local box = Drawings.ESPBoxes[player]
    box.Size = Vector2.new(width, height)
    box.Position = Vector2.new(rootPosition.X - width / 2, rootPosition.Y - height / 2)
    box.Color = getTeamColor(player)
    box.Visible = true
end

local function updateVisuals()
    disconnect(Connections.Visuals)
    Connections.Visuals = nil

    if not States.Visuals.Master then
        for _, line in pairs(Drawings.ESPLines) do if line then line.Visible = false end end
        for _, box in pairs(Drawings.ESPBoxes) do if box then box.Visible = false end end
        for player in pairs(Drawings.Chams) do
            local highlight = Drawings.Chams[player]
            if highlight then highlight.Enabled = false end
        end
        return
    end

    Connections.Visuals = RunService.RenderStepped:Connect(function()
        if Unloaded then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character and isCharacterAlive(character) then
                    if States.Visuals.ESPLines then
                        drawESPLine(player, character)
                    elseif Drawings.ESPLines[player] then
                        Drawings.ESPLines[player].Visible = false
                    end

                    if States.Visuals.ESPBoxes then
                        drawESPBox(player, character)
                    elseif Drawings.ESPBoxes[player] then
                        Drawings.ESPBoxes[player].Visible = false
                    end

                    if States.Visuals.TeamChams then
                        local highlight = Drawings.Chams[player]
                        if not highlight or highlight.Parent == nil or highlight.Adornee ~= character then
                            createChams(player, character)
                        elseif highlight then
                            highlight.Enabled = true
                            highlight.FillColor = getTeamColor(player)
                            highlight.OutlineColor = getTeamColor(player)
                        end
                    elseif Drawings.Chams[player] then
                        Drawings.Chams[player]:Destroy()
                        Drawings.Chams[player] = nil
                    end
                else
                    if Drawings.ESPLines[player] then Drawings.ESPLines[player].Visible = false end
                    if Drawings.ESPBoxes[player] then Drawings.ESPBoxes[player].Visible = false end
                    if Drawings.Chams[player] then
                        Drawings.Chams[player]:Destroy()
                        Drawings.Chams[player] = nil
                    end
                end
            end
        end
    end)
end

-- Movement features
local function setNoclip(enabled)
    disconnect(Connections.Noclip)
    Connections.Noclip = nil
    States.Misc.Noclip = enabled

    local character = LocalPlayer.Character
    if not enabled then
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local original = OriginalCollision[part]
                    if original ~= nil then part.CanCollide = original end
                    OriginalCollision[part] = nil
                end
            end
        end
        return
    end

    local function applyNoclip()
        local currentCharacter = LocalPlayer.Character
        if not currentCharacter then return end
        for _, part in ipairs(currentCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                if OriginalCollision[part] == nil then OriginalCollision[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end

    Connections.Noclip = RunService.Stepped:Connect(applyNoclip)
    applyNoclip()
end

local function setInfiniteJump(enabled)
    disconnect(Connections.InfiniteJump)
    Connections.InfiniteJump = nil
    States.Misc.InfiniteJump = enabled
    if enabled then
        Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

local function updateWalkSpeed()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if States.Misc.WalkSpeed.Enabled then
        humanoid.WalkSpeed = States.Misc.WalkSpeed.Value
    else
        humanoid.WalkSpeed = States.Misc.WalkSpeed.Original
    end
end

local function setFly(enabled)
    disconnect(Connections.Fly)
    Connections.Fly = nil
    if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end
    if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
    States.Misc.Fly.Enabled = enabled
    if not enabled then return end

    local character = LocalPlayer.Character
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
    if not root then return end

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyGyro.CFrame = root.CFrame
    FlyBodyGyro.Parent = root

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyVelocity.Parent = root

    Connections.Fly = RunService.RenderStepped:Connect(function()
        if not FlyBodyGyro or not FlyBodyVelocity or not LocalPlayer.Character then return end
        local camera = getCamera()
        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0, 1, 0) end
        FlyBodyGyro.CFrame = camera.CFrame
        FlyBodyVelocity.Velocity = (direction.Magnitude > 0 and direction.Unit or Vector3.zero) * States.Misc.Fly.Speed
    end)
end

-- Character/player lifecycle
local function onLocalCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    task.delay(0.25, function()
        if Unloaded or LocalPlayer.Character ~= character then return end
        if States.Misc.WalkSpeed.Enabled then updateWalkSpeed() end
        if States.Misc.Noclip then setNoclip(true) end
        if States.Misc.Fly.Enabled then setFly(true) end
    end)
    humanoid.Died:Connect(function()
        if States.Misc.Fly.Enabled then setFly(false) end
    end)
end

local function trackPlayer(player)
    if player == LocalPlayer then return end
    disconnectPlayerEvents(player)
    local list = {}
    Connections.PlayerEvents[player] = list
    table.insert(list, player.CharacterAdded:Connect(function(character)
        task.delay(0.15, function()
            if not Unloaded and States.Visuals.Master and States.Visuals.TeamChams and player.Character == character then
                createChams(player, character)
            end
        end)
    end))
    table.insert(list, player:GetPropertyChangedSignal("Team"):Connect(function()
        local highlight = Drawings.Chams[player]
        if highlight then
            highlight.FillColor = getTeamColor(player)
            highlight.OutlineColor = getTeamColor(player)
        end
    end))
    if player.Character and States.Visuals.Master and States.Visuals.TeamChams then
        createChams(player, player.Character)
    end
end

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
if LocalPlayer.Character then task.spawn(onLocalCharacterAdded, LocalPlayer.Character) end
for _, player in ipairs(Players:GetPlayers()) do trackPlayer(player) end
Connections.PlayerAdded = Players.PlayerAdded:Connect(trackPlayer)
Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
    clearPlayerDrawings(player)
    disconnectPlayerEvents(player)
end)

-- Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Project Life",
    LoadingTitle = "Project Life",
    LoadingSubtitle = "Prison Life testing tools",
    ConfigurationSaving = { Enabled = true, FolderName = "ProjectLife", FileName = "Config" },
    Discord = { Enabled = false, Invite = "", RememberJoins = false },
    KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

createFOVCircle()

-- Combat controls
CombatTab:CreateSection("Targeting")
CombatTab:CreateToggle({ Name = "Enable Target Selection", CurrentValue = false, Callback = function(value)
    States.Combat.SilentAim = value
    updateSilentAim()
end })
CombatTab:CreateToggle({ Name = "Camera Lock Assist", CurrentValue = false, Callback = function(value)
    States.Combat.CameraLock = value
end })
CombatTab:CreateDropdown({ Name = "Target Team", Options = { "All", "Guards", "Prisoners", "Criminals" }, CurrentOption = "All", Callback = function(value)
    States.Combat.TargetTeam = value
end })
CombatTab:CreateSlider({ Name = "FOV Radius", Range = { 10, 100 }, Increment = 1, Suffix = "%", CurrentValue = 50, Callback = function(value)
    States.Combat.FOV = value
    if Drawings.FOVCircle then Drawings.FOVCircle.Radius = value * 3 end
end })
CombatTab:CreateSlider({ Name = "Hit Chance", Range = { 0, 100 }, Increment = 1, Suffix = "%", CurrentValue = 100, Callback = function(value)
    States.Combat.HitChance = value
end })
CombatTab:CreateDropdown({ Name = "Target Body Part", Options = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" }, CurrentOption = "Head", Callback = function(value)
    States.Combat.TargetPart = value
end })

-- Visual controls
VisualTab:CreateSection("ESP and Chams")
VisualTab:CreateToggle({ Name = "Master Visuals", CurrentValue = false, Callback = function(value)
    States.Visuals.Master = value
    updateVisuals()
end })
VisualTab:CreateToggle({ Name = "ESP Lines", CurrentValue = false, Callback = function(value)
    States.Visuals.ESPLines = value
end })
VisualTab:CreateToggle({ Name = "ESP Boxes", CurrentValue = false, Callback = function(value)
    States.Visuals.ESPBoxes = value
end })
VisualTab:CreateToggle({ Name = "Team Chams", CurrentValue = false, Callback = function(value)
    States.Visuals.TeamChams = value
    if not value then
        for player, highlight in pairs(Drawings.Chams) do
            if highlight then highlight:Destroy() end
            Drawings.Chams[player] = nil
        end
    elseif States.Visuals.Master then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then createChams(player, player.Character) end
        end
    end
end })

-- Misc controls
MiscTab:CreateSection("Movement")
MiscTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(value)
    setNoclip(value)
end })
MiscTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(value)
    setInfiniteJump(value)
end })
MiscTab:CreateToggle({ Name = "Custom Walk Speed", CurrentValue = false, Callback = function(value)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if value and humanoid then States.Misc.WalkSpeed.Original = humanoid.WalkSpeed end
    States.Misc.WalkSpeed.Enabled = value
    updateWalkSpeed()
end })
MiscTab:CreateSlider({ Name = "Walk Speed Value", Range = { 16, 200 }, Increment = 1, Suffix = " studs/sec", CurrentValue = 50, Callback = function(value)
    States.Misc.WalkSpeed.Value = value
    if States.Misc.WalkSpeed.Enabled then updateWalkSpeed() end
end })
MiscTab:CreateToggle({ Name = "Fly", CurrentValue = false, Callback = function(value)
    setFly(value)
end })
MiscTab:CreateSlider({ Name = "Fly Speed", Range = { 10, 500 }, Increment = 10, Suffix = " studs/sec", CurrentValue = 50, Callback = function(value)
    States.Misc.Fly.Speed = value
end })

-- Settings / cleanup
SettingsTab:CreateSection("Cleanup")
SettingsTab:CreateButton({ Name = "Cleanup Visual Objects", Callback = function()
    clearAllDrawings()
    if States.Visuals.Master then updateVisuals() end
    Rayfield:Notify({ Title = "Cleanup", Content = "Temporary visual objects cleared.", Duration = 3 })
end })
SettingsTab:CreateButton({ Name = "Safe Unload", Callback = function()
    if Unloaded then return end
    Unloaded = true
    States.Combat.SilentAim = false
    States.Visuals.Master = false
    States.Visuals.TeamChams = false
    States.Misc.WalkSpeed.Enabled = false
    setNoclip(false)
    setInfiniteJump(false)
    setFly(false)
    updateWalkSpeed()
    disconnectAll()
    clearAllDrawings()
    pcall(function() Rayfield:Destroy() end)
end })

Rayfield:Notify({ Title = "Project Life", Content = "Loaded. Target selection does not redirect weapon shots.", Duration = 5 })
print("Project Life loaded")
