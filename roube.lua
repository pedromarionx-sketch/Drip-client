-- Rayfield Position Saver & Teleporter + Misc Features
-- Place this in a LocalScript in StarterPlayerScripts or StarterGui

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- Rayfield Library loadstring (using a reliable source)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- State management
local SavedCFrame = nil
local currentCharacter = nil
local humanoidRootPart = nil
local humanoid = nil
local originalWalkSpeed = 16

-- Feature toggles/connections
local InfiniteJumpConnection = nil
local AntiAFKConnection = nil
local InstantProximityConnection = nil
local AFKTimer = 0

-- Update character references when character spawns/respawns
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

-- Initial setup and character respawn handling
updateCharacterReferences()
player.CharacterAdded:Connect(function(char)
	currentCharacter = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
	humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		originalWalkSpeed = humanoid.WalkSpeed
	end
end)

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
	Name = "Position Saver & Tools",
	LoadingTitle = "Position Saver Loading",
	LoadingSubtitle = "by Script Developer",
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

-- ============================================
-- TELEPORT TAB (Original)
-- ============================================
local MainTab = Window:CreateTab("Teleport", "map")

-- Button 1: Save Position
local SaveButton = MainTab:CreateButton({
	Name = "Save Position",
	Callback = function()
		-- Ensure character and HRP exist
		if not currentCharacter then
			Rayfield:Notify({
				Title = "Error",
				Content = "Character not loaded yet!",
				Duration = 3,
				Image = "alert-triangle"
			})
			return
		end
		
		if not humanoidRootPart then
			humanoidRootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				Rayfield:Notify({
					Title = "Error",
					Content = "HumanoidRootPart not found!",
					Duration = 3,
					Image = "alert-triangle"
				})
				return
			end
		end
		
		-- Save the exact CFrame (includes position and rotation)
		SavedCFrame = humanoidRootPart.CFrame
		
		-- Extract coordinates for notification
		local pos = SavedCFrame.Position
		
		Rayfield:Notify({
			Title = "Position Saved!",
			Content = string.format("X: %.3f, Y: %.3f, Z: %.3f", pos.X, pos.Y, pos.Z),
			Duration = 4,
			Image = "check-circle"
		})
	end,
})

-- Button 2: Go To Position
local TeleportButton = MainTab:CreateButton({
	Name = "Go To Position",
	Callback = function()
		-- Check if a position has been saved
		if SavedCFrame == nil then
			Rayfield:Notify({
				Title = "No Position Saved",
				Content = "Click 'Save Position' first!",
				Duration = 3,
				Image = "info"
			})
			return
		end
		
		-- Ensure character and HRP exist
		if not currentCharacter then
			Rayfield:Notify({
				Title = "Error",
				Content = "Character not loaded!",
				Duration = 3,
				Image = "alert-triangle"
			})
			return
		end
		
		if not humanoidRootPart then
			humanoidRootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				Rayfield:Notify({
					Title = "Error",
					Content = "HumanoidRootPart not available!",
					Duration = 3,
					Image = "alert-triangle"
				})
				return
			end
		end
		
		-- Check if seated (optional: unseat the player)
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
			task.wait(0.1)
		end
		
		-- Teleport with exact CFrame (position + rotation)
		humanoidRootPart.CFrame = SavedCFrame
		
		Rayfield:Notify({
			Title = "Teleported!",
			Content = "Position and rotation restored.",
			Duration = 3,
			Image = "navigation"
		})
	end,
})

-- Optional: Display saved position info
local PositionLabel = MainTab:CreateParagraph({
	Title = "Status",
	Content = "No position saved yet. Click 'Save Position' to store your current location."
})

-- Update the label when buttons are clicked
local originalSaveCallback = SaveButton.Callback
SaveButton.Callback = function()
	originalSaveCallback()
	if SavedCFrame then
		local pos = SavedCFrame.Position
		PositionLabel:Set({
			Title = "Saved Position",
			Content = string.format(
				"Position: (%.2f, %.2f, %.2f)\nRotation: Available\nClick 'Go To Position' to teleport back.",
				pos.X, pos.Y, pos.Z
			)
		})
	end
end

local originalTeleportCallback = TeleportButton.Callback
TeleportButton.Callback = function()
	originalTeleportCallback()
	if SavedCFrame then
		PositionLabel:Set({
			Title = "Last Action",
			Content = "Teleported to saved position. Position data still stored."
		})
	end
end

-- ============================================
-- MISC TAB (New Features)
-- ============================================
local MiscTab = Window:CreateTab("Misc", "settings")

-- Walkspeed Section
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
			Rayfield:Notify({
				Title = "WalkSpeed Reset",
				Content = "Returned to default: " .. originalWalkSpeed,
				Duration = 2,
				Image = "refresh-cw"
			})
		else
			Rayfield:Notify({
				Title = "Error",
				Content = "Humanoid not found!",
				Duration = 2,
				Image = "alert-triangle"
			})
		end
	end,
})

-- Infinite Jump
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
			Rayfield:Notify({
				Title = "Infinite Jump",
				Content = "Enabled - Jump anytime!",
				Duration = 2,
				Image = "check"
			})
		else
			if InfiniteJumpConnection then
				InfiniteJumpConnection:Disconnect()
				InfiniteJumpConnection = nil
			end
			Rayfield:Notify({
				Title = "Infinite Jump",
				Content = "Disabled",
				Duration = 2,
				Image = "x"
			})
		end
	end,
})

-- Anti-AFK
MiscTab:CreateSection("Anti Systems")

local AntiAFKToggle = MiscTab:CreateToggle({
	Name = "Anti-AFK",
	CurrentValue = false,
	Flag = "AntiAFK",
	Callback = function(Value)
		if Value then
			AntiAFKConnection = RunService.Heartbeat:Connect(function(deltaTime)
				AFKTimer = AFKTimer + deltaTime
				if AFKTimer >= 300 then
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
			Rayfield:Notify({
				Title = "Anti-AFK",
				Content = "Enabled - Camera will micro-move every 5 min",
				Duration = 3,
				Image = "shield"
			})
		else
			if AntiAFKConnection then
				AntiAFKConnection:Disconnect()
				AntiAFKConnection = nil
			end
			AFKTimer = 0
			Rayfield:Notify({
				Title = "Anti-AFK",
				Content = "Disabled",
				Duration = 2,
				Image = "shield-off"
			})
		end
	end,
})

-- Instant Proximity Prompts
local InstantProximityToggle = MiscTab:CreateToggle({
	Name = "Instant Proximity Prompts",
	CurrentValue = false,
	Flag = "InstantProximity",
	Callback = function(Value)
		if Value then
			InstantProximityConnection = RunService.Heartbeat:Connect(function()
				if currentCharacter and humanoidRootPart then
					for _, prompt in ipairs(Workspace:GetDescendants()) do
						if prompt:IsA("ProximityPrompt") and prompt.Enabled then
							local promptParent = prompt.Parent
							if promptParent and promptParent:IsA("BasePart") then
								local distance = (humanoidRootPart.Position - promptParent.Position).Magnitude
								if distance <= prompt.MaxActivationDistance then
									if prompt.HoldDuration > 0 then
										prompt:InputHoldBegin()
										task.wait(prompt.HoldDuration)
										if prompt then
											prompt:InputHoldEnd()
										end
									else
										prompt:InputHoldBegin()
										prompt:InputHoldEnd()
									end
								end
							end
						end
					end
				end
			end)
			Rayfield:Notify({
				Title = "Instant Proximity",
				Content = "Auto-completing prompts when nearby",
				Duration = 3,
				Image = "zap"
			})
		else
			if InstantProximityConnection then
				InstantProximityConnection:Disconnect()
				InstantProximityConnection = nil
			end
			Rayfield:Notify({
				Title = "Instant Proximity",
				Content = "Disabled",
				Duration = 2,
				Image = "x"
			})
		end
	end,
})

-- FPS Booster
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
		
		Rayfield:Notify({
			Title = "FPS Booster",
			Content = "Applied " .. improvements .. " optimizations!",
			Duration = 3,
			Image = "cpu"
		})
	end,
})

-- Reset Graphics
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
		
		Rayfield:Notify({
			Title = "Graphics Restored",
			Content = "Restored default settings",
			Duration = 3,
			Image = "image"
		})
	end,
})

-- Cleanup on script destroy
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
	if child.Name == "Rayfield" then
		if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
		if AntiAFKConnection then AntiAFKConnection:Disconnect() end
		if InstantProximityConnection then InstantProximityConnection:Disconnect() end
	end
end)