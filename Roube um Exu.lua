-- Rayfield Position Saver & Teleporter + Misc Features
-- Script Name: Roube um Exu
-- Developed by: pedrox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local SavedCFrame = nil
local currentCharacter = nil
local humanoidRootPart = nil
local humanoid = nil
local originalWalkSpeed = 16

local InfiniteJumpConnection = nil
local AntiAFKConnection = nil
local ProximityConnection = nil
local AFKTimer = 0

local function updateCharacterReferences()
	currentCharacter = player.Character
	if currentCharacter then
		humanoidRootPart = currentCharacter:WaitForChild("HumanoidRootPart", 5)
		humanoid = currentCharacter:WaitForChild("Humanoid", 5)
		if humanoid then
			originalWalkSpeed = humanoid.WalkSpeed
		end
	end
end

updateCharacterReferences()
player.CharacterAdded:Connect(function(char)
	currentCharacter = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
	humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		originalWalkSpeed = humanoid.WalkSpeed
	end
end)

local Window = Rayfield:CreateWindow({
	Name = "Roube um Exu",
	LoadingTitle = "Roube um Exu",
	LoadingSubtitle = "desenvolvido por pedrox",
	ConfigurationSaving = {
		Enabled = false,
		FolderName = "PositionSaver",
		FileName = "Config"
	},
	Discord = {
		Enabled = false,
		Invite = "",
		RememberJoins = false
	},
	KeySystem = false
})

local MainTab = Window:CreateTab("Teleport", "map")

local SaveButton = MainTab:CreateButton({
	Name = "Save Position",
	Callback = function()
		if not currentCharacter then
			Rayfield:Notify({Title = "Error", Content = "Character not loaded!", Duration = 3, Image = "alert-triangle"})
			return
		end
		if not humanoidRootPart then
			humanoidRootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				Rayfield:Notify({Title = "Error", Content = "HumanoidRootPart not found!", Duration = 3, Image = "alert-triangle"})
				return
			end
		end
		SavedCFrame = humanoidRootPart.CFrame
		local pos = SavedCFrame.Position
		Rayfield:Notify({Title = "Position Saved!", Content = string.format("X: %.3f, Y: %.3f, Z: %.3f", pos.X, pos.Y, pos.Z), Duration = 4, Image = "check-circle"})
	end,
})

local TeleportButton = MainTab:CreateButton({
	Name = "Go To Position",
	Callback = function()
		if SavedCFrame == nil then
			Rayfield:Notify({Title = "No Position Saved", Content = "Click 'Save Position' first!", Duration = 3, Image = "info"})
			return
		end
		if not currentCharacter then
			Rayfield:Notify({Title = "Error", Content = "Character not loaded!", Duration = 3, Image = "alert-triangle"})
			return
		end
		if not humanoidRootPart then
			humanoidRootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				Rayfield:Notify({Title = "Error", Content = "HumanoidRootPart not available!", Duration = 3, Image = "alert-triangle"})
				return
			end
		end
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
			task.wait(0.1)
		end
		humanoidRootPart.CFrame = SavedCFrame
		Rayfield:Notify({Title = "Teleported!", Content = "Position and rotation restored.", Duration = 3, Image = "navigation"})
	end,
})

local PositionLabel = MainTab:CreateParagraph({
	Title = "Status",
	Content = "No position saved yet. Click 'Save Position' to store your current location."
})

local originalSaveCallback = SaveButton.Callback
SaveButton.Callback = function()
	originalSaveCallback()
	if SavedCFrame then
		local pos = SavedCFrame.Position
		PositionLabel:Set({Title = "Saved Position", Content = string.format("Position: (%.2f, %.2f, %.2f)\nRotation: Available\nClick 'Go To Position' to teleport back.", pos.X, pos.Y, pos.Z)})
	end
end

local originalTeleportCallback = TeleportButton.Callback
TeleportButton.Callback = function()
	originalTeleportCallback()
	if SavedCFrame then
		PositionLabel:Set({Title = "Last Action", Content = "Teleported to saved position. Position data still stored."})
	end
end

local MiscTab = Window:CreateTab("Misc", "settings")

MiscTab:CreateSection("Movement")

local WalkSpeedSlider = MiscTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {16, 200},
	Increment = 1,
	Suffix = "Studs/s",
	CurrentValue = 16,
	Flag = "WalkSpeedSlider",
	Callback = function(Value)
		if humanoid then
			humanoid.WalkSpeed = Value
		end
	end,
})

MiscTab:CreateButton({
	Name = "Reset WalkSpeed",
	Callback = function()
		if humanoid then
			humanoid.WalkSpeed = originalWalkSpeed
			WalkSpeedSlider:Set(originalWalkSpeed)
			Rayfield:Notify({Title = "WalkSpeed Reset", Content = "Returned to default: " .. originalWalkSpeed, Duration = 2, Image = "refresh-cw"})
		else
			Rayfield:Notify({Title = "Error", Content = "Humanoid not found!", Duration = 2, Image = "alert-triangle"})
		end
	end,
})

local InfiniteJumpToggle = MiscTab:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Flag = "InfiniteJump",
	Callback = function(Value)
		if Value then
			InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
				if humanoid then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
			Rayfield:Notify({Title = "Infinite Jump", Content = "Enabled - Jump anytime!", Duration = 2, Image = "check"})
		else
			if InfiniteJumpConnection then
				InfiniteJumpConnection:Disconnect()
				InfiniteJumpConnection = nil
			end
			Rayfield:Notify({Title = "Infinite Jump", Content = "Disabled", Duration = 2, Image = "x"})
		end
	end,
})

MiscTab:CreateSection("Anti Systems")

local AntiAFKToggle = MiscTab:CreateToggle({
	Name = "Anti-AFK",
	CurrentValue = false,
	Flag = "AntiAFK",
	Callback = function(Value)
		if Value then
			AntiAFKConnection = RunService.Heartbeat:Connect(function(deltaTime)
				AFKTimer = AFKTimer + deltaTime
				if AFKTimer >= 900 then -- 15 minutes
					AFKTimer = 0
					local camera = Workspace.CurrentCamera
					if camera then
						local currentCFrame = camera.CFrame
						camera.CFrame = currentCFrame * CFrame.Angles(0.01, 0, 0)
						task.wait()
						camera.CFrame = currentCFrame
					end
				end
			end)
			Rayfield:Notify({Title = "Anti-AFK", Content = "Enabled - Camera will micro-move every 15 min", Duration = 3, Image = "shield"})
		else
			if AntiAFKConnection then
				AntiAFKConnection:Disconnect()
				AntiAFKConnection = nil
			end
			AFKTimer = 0
			Rayfield:Notify({Title = "Anti-AFK", Content = "Disabled", Duration = 2, Image = "shield-off"})
		end
	end,
})

local ProximityToggle = MiscTab:CreateToggle({
	Name = "Instant Proximity Prompts",
	CurrentValue = false,
	Flag = "InstantProximity",
	Callback = function(Value)
		if Value then
			for _, prompt in ipairs(Workspace:GetDescendants()) do
				if prompt:IsA("ProximityPrompt") then
					prompt.HoldDuration = 0
				end
			end
			ProximityConnection = Workspace.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("ProximityPrompt") then
					descendant.HoldDuration = 0
				end
			end)
			Rayfield:Notify({Title = "Instant Proximity", Content = "Prompts now complete instantly on click!", Duration = 3, Image = "zap"})
		else
			if ProximityConnection then
				ProximityConnection:Disconnect()
				ProximityConnection = nil
			end
			Rayfield:Notify({Title = "Instant Proximity", Content = "Disabled - Prompts back to normal", Duration = 2, Image = "x"})
		end
	end,
})

MiscTab:CreateSection("Performance")

MiscTab:CreateButton({
	Name = "FPS Booster",
	Callback = function()
		local improvements = 0
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		improvements += 1
		pcall(function()
			settings().Rendering.QualityLevel = 1
			improvements += 1
		end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
				v.Enabled = false
				improvements += 1
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 1
				improvements += 1
			elseif v:IsA("BasePart") and v.Material == Enum.Material.Glass then
				v.Material = Enum.Material.Plastic
				improvements += 1
			end
		end
		if Lighting.Technology then
			Lighting.Technology = Enum.Technology.Compatibility
			improvements += 1
		end
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CastShadow = false
					end
				end
			end
		end
		Rayfield:Notify({Title = "FPS Booster", Content = "Applied " .. improvements .. " optimizations!", Duration = 3, Image = "cpu"})
	end,
})

MiscTab:CreateButton({
	Name = "Reset Graphics (Restore)",
	Callback = function()
		Lighting.GlobalShadows = true
		pcall(function()
			settings().Rendering.QualityLevel = 7
		end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
				v.Enabled = true
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 0
			end
		end
		Rayfield:Notify({Title = "Graphics Restored", Content = "Restored default settings", Duration = 3, Image = "image"})
	end,
})

game:GetService("CoreGui").ChildRemoved:Connect(function(child)
	if child.Name == "Rayfield" then
		if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
		if AntiAFKConnection then AntiAFKConnection:Disconnect() end
		if ProximityConnection then ProximityConnection:Disconnect() end
	end
end)