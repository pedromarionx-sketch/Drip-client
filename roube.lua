-- Rayfield Position Saver & Teleporter
-- Place this in a LocalScript in StarterPlayerScripts or StarterGui

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Rayfield Library loadstring (using a reliable source)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- State management
local SavedCFrame = nil
local currentCharacter = nil
local humanoidRootPart = nil

-- Update character references when character spawns/respawns
local function updateCharacterReferences()
	currentCharacter = player.Character
	if currentCharacter then
		humanoidRootPart = currentCharacter:WaitForChild("HumanoidRootPart", 5)
	end
end

-- Initial setup and character respawn handling
updateCharacterReferences()
player.CharacterAdded:Connect(function(char)
	currentCharacter = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
end)

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
	Name = "Position Saver",
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

-- Create Main Tab
local MainTab = Window:CreateTab("Teleport", "map") -- "map" is the icon

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
		local rot = SavedCFrame.Rotation
		
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
		local humanoid = currentCharacter:FindFirstChild("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
			task.wait(0.1) -- Small delay to ensure unseat
		end
		
		-- Teleport with exact CFrame (position + rotation)
		humanoidRootPart.CFrame = SavedCFrame
		
		-- Alternative: Use PivotTo for model-based teleportation (includes rotation)
		-- currentCharacter:PivotTo(SavedCFrame)
		
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