local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local player = Player
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local function GetChar()
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")
		return char, root, hum
	end
	return nil, nil, nil
end

local function EquipToolByName(toolNameKeyword)
	local char = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not char then return end
	local equipped = char:FindFirstChildOfClass("Tool")
	if equipped and string.find(string.lower(equipped.Name), string.lower(toolNameKeyword)) then
		return
	end
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and string.find(string.lower(tool.Name), string.lower(toolNameKeyword)) then
				char.Humanoid:EquipTool(tool)
				break
			end
		end
	end
end

local TimerGui = Instance.new("ScreenGui")
TimerGui.Name = "DripFarmTimer"
TimerGui.ResetOnSpawn = false
TimerGui.IgnoreGuiInset = true
TimerGui.Parent = PlayerGui
local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "TimerLabel"
TimerLabel.Size = UDim2.new(0, 320, 0, 28)
TimerLabel.Position = UDim2.new(0.5, -160, 0, 12)
TimerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TimerLabel.BackgroundTransparency = 0.25
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.TextSize = 13
TimerLabel.Font = Enum.Font.GothamMedium
TimerLabel.Text = ""
TimerLabel.Visible = false
TimerLabel.Parent = TimerGui
Instance.new("UICorner", TimerLabel).CornerRadius = UDim.new(0, 6)

local IMAGE_ID = "rbxassetid://109067754925630"

local WHITE = Color3.fromRGB(255, 255, 255)
local LIGHT_WHITE = Color3.fromRGB(220, 220, 220)
local GRAY = Color3.fromRGB(150, 150, 150)

local Blur = Instance.new("BlurEffect")
Blur.Name = "LoadingBlur"
Blur.Size = 0
Blur.Parent = Lighting

TweenService:Create(
	Blur,
	TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Size = 18}
):Play()

local Gui = Instance.new("ScreenGui")
Gui.Name = "DripLoadingScreen"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui

local Background = Instance.new("Frame")
Background.Name = "Background"
Background.Size = UDim2.fromScale(1, 1)
Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Background.BorderSizePixel = 0
Background.Parent = Gui

local HubImage = Instance.new("ImageLabel")
HubImage.Name = "BackgroundImage"
HubImage.Size = UDim2.fromScale(1.08, 1.08)
HubImage.Position = UDim2.fromScale(-0.04, -0.04)
HubImage.BackgroundTransparency = 1
HubImage.Image = IMAGE_ID
HubImage.ImageTransparency = 0.12
HubImage.ScaleType = Enum.ScaleType.Crop
HubImage.ImageColor3 = WHITE
HubImage.Parent = Background

task.spawn(function()
	while HubImage.Parent do
		TweenService:Create(
			HubImage,
			TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{
				Size = UDim2.fromScale(1.12, 1.12),
				Position = UDim2.fromScale(-0.06, -0.06)
			}
		):Play()

		task.wait(6)

		TweenService:Create(
			HubImage,
			TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{
				Size = UDim2.fromScale(1.08, 1.08),
				Position = UDim2.fromScale(-0.04, -0.04)
			}
		):Play()

		task.wait(6)
	end
end)

local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.48
Overlay.BorderSizePixel = 0
Overlay.Parent = Background

local BackgroundGradient = Instance.new("UIGradient")
BackgroundGradient.Rotation = 35
BackgroundGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 20, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})
BackgroundGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.15),
	NumberSequenceKeypoint.new(0.5, 0.45),
	NumberSequenceKeypoint.new(1, 0.15)
})
BackgroundGradient.Parent = Overlay

local ParticleFolder = Instance.new("Folder")
ParticleFolder.Name = "Particles"
ParticleFolder.Parent = Background

local RNG = Random.new()

for i = 1, 45 do
	local Particle = Instance.new("Frame")
	local Size = RNG:NextNumber(1.5, 4.5)

	Particle.Size = UDim2.fromOffset(Size, Size)
	Particle.Position = UDim2.fromScale(
		RNG:NextNumber(0, 1),
		RNG:NextNumber(0, 1)
	)
	Particle.BackgroundColor3 = WHITE:Lerp(
		GRAY,
		RNG:NextNumber(0, 1)
	)
	Particle.BackgroundTransparency = RNG:NextNumber(0.35, 0.8)
	Particle.BorderSizePixel = 0
	Particle.Parent = ParticleFolder

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = Particle

	task.spawn(function()
		while Particle.Parent do
			local NewX = RNG:NextNumber(0, 1)
			local NewY = RNG:NextNumber(0, 1)
			local Duration = RNG:NextNumber(3, 7)

			local Move = TweenService:Create(
				Particle,
				TweenInfo.new(
					Duration,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Position = UDim2.fromScale(NewX, NewY),
					BackgroundTransparency = RNG:NextNumber(0.25, 0.8)
				}
			)

			Move:Play()
			Move.Completed:Wait()
		end
	end)
end

local Main = Instance.new("Frame")
Main.Name = "LoadingCard"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.56)
Main.Size = UDim2.fromOffset(310, 185)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.Parent = Background

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 17)
CardCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = WHITE
Stroke.Transparency = 0.55
Stroke.Thickness = 1
Stroke.Parent = Main

local Glow = Instance.new("Frame")
Glow.Name = "TitleGlow"
Glow.AnchorPoint = Vector2.new(0.5, 0.5)
Glow.Position = UDim2.fromScale(0.5, 0.28)
Glow.Size = UDim2.fromOffset(125, 48)
Glow.BackgroundColor3 = WHITE
Glow.BackgroundTransparency = 0.91
Glow.BorderSizePixel = 0
Glow.Parent = Main

local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(1, 0)
GlowCorner.Parent = Glow

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.AnchorPoint = Vector2.new(0.5, 0)
Title.Position = UDim2.fromScale(0.5, 0.12)
Title.Size = UDim2.fromOffset(280, 38)
Title.BackgroundTransparency = 1
Title.Text = "Carregando..."
Title.TextColor3 = WHITE
Title.TextSize = 25
Title.Font = Enum.Font.GothamBold
Title.TextTransparency = 1
Title.Parent = Main

local By = Instance.new("TextLabel")
By.Name = "Creator"
By.AnchorPoint = Vector2.new(0.5, 0)
By.Position = UDim2.fromScale(0.5, 0.34)
By.Size = UDim2.fromOffset(200, 20)
By.BackgroundTransparency = 1
By.Text = "By Willz"
By.TextColor3 = Color3.fromRGB(180, 180, 180)
By.TextSize = 12
By.Font = Enum.Font.GothamMedium
By.TextTransparency = 1
By.Parent = Main

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.AnchorPoint = Vector2.new(0.5, 0)
Status.Position = UDim2.fromScale(0.5, 0.53)
Status.Size = UDim2.fromOffset(270, 20)
Status.BackgroundTransparency = 1
Status.Text = "Inicializando..."
Status.TextColor3 = Color3.fromRGB(205, 205, 205)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextTransparency = 1
Status.Parent = Main

local BarBackground = Instance.new("Frame")
BarBackground.Name = "BarBackground"
BarBackground.AnchorPoint = Vector2.new(0.5, 0)
BarBackground.Position = UDim2.fromScale(0.5, 0.68)
BarBackground.Size = UDim2.fromOffset(245, 5)
BarBackground.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
BarBackground.BorderSizePixel = 0
BarBackground.Parent = Main

local BarBgCorner = Instance.new("UICorner")
BarBgCorner.CornerRadius = UDim.new(1, 0)
BarBgCorner.Parent = BarBackground

local Bar = Instance.new("Frame")
Bar.Name = "Progress"
Bar.Size = UDim2.fromScale(0, 1)
Bar.BackgroundColor3 = WHITE
Bar.BorderSizePixel = 0
Bar.Parent = BarBackground

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(1, 0)
BarCorner.Parent = Bar

local BarGradient = Instance.new("UIGradient")
BarGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 90, 90)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 220, 220)),
	ColorSequenceKeypoint.new(1, WHITE)
})
BarGradient.Parent = Bar

local Percent = Instance.new("TextLabel")
Percent.Name = "Percent"
Percent.AnchorPoint = Vector2.new(0.5, 0)
Percent.Position = UDim2.fromScale(0.5, 0.76)
Percent.Size = UDim2.fromOffset(100, 18)
Percent.BackgroundTransparency = 1
Percent.Text = "0%"
Percent.TextColor3 = Color3.fromRGB(230, 230, 230)
Percent.TextSize = 10
Percent.Font = Enum.Font.GothamMedium
Percent.TextTransparency = 1
Percent.Parent = Main

TweenService:Create(
	Main,
	TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0.08
	}
):Play()

for _, Object in ipairs({Title, By, Status, Percent}) do
	TweenService:Create(
		Object,
		TweenInfo.new(0.7),
		{TextTransparency = 0}
	):Play()
end

task.spawn(function()
	while Title.Parent do
		TweenService:Create(
			Title,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextSize = 27}
		):Play()

		TweenService:Create(
			Glow,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 0.78}
		):Play()

		task.wait(1.2)

		TweenService:Create(
			Title,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextSize = 25}
		):Play()

		TweenService:Create(
			Glow,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 0.91}
		):Play()

		task.wait(1.2)
	end
end)

local Stages = {
	{10, "Iniciando..."},
	{25, "Carregando interface..."},
	{40, "Preparando módulos..."},
	{55, "Carregando funções..."},
	{70, "Verificando configurações..."},
	{85, "Finalizando..."},
	{100, "Tudo pronto!"}
}

for _, Stage in ipairs(Stages) do
	local Value = Stage[1]
	local Text = Stage[2]

	Status.Text = Text

	TweenService:Create(
		Bar,
		TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromScale(Value / 100, 1)
		}
	):Play()

	local Current = tonumber(Percent.Text:match("%d+")) or 0

	for i = Current, Value do
		Percent.Text = i .. "%"
		task.wait(0.01)
	end

	task.wait(0.2)
end

task.wait(0.6)

TweenService:Create(
	Blur,
	TweenInfo.new(0.8, Enum.EasingStyle.Quint),
	{Size = 0}
):Play()

TweenService:Create(
	HubImage,
	TweenInfo.new(0.7),
	{ImageTransparency = 1}
):Play()

TweenService:Create(
	Overlay,
	TweenInfo.new(0.7),
	{BackgroundTransparency = 1}
):Play()

TweenService:Create(
	Background,
	TweenInfo.new(0.7),
	{BackgroundTransparency = 1}
):Play()

TweenService:Create(
	Main,
	TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{
		Position = UDim2.fromScale(0.5, 0.45),
		BackgroundTransparency = 1
	}
):Play()

for _, Object in ipairs({Title, By, Status, Percent}) do
	TweenService:Create(
		Object,
		TweenInfo.new(0.45),
		{TextTransparency = 1}
	):Play()
end

task.wait(0.8)

Blur:Destroy()
Gui:Destroy()

local WindUI_Source = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua")
local WindUI_Func = loadstring(WindUI_Source)
if not WindUI_Func then
	error("Falha ao carregar WindUI")
end
local WindUI = WindUI_Func()
if not WindUI then
	error("Falha ao iniciar WindUI")
end

local Window = WindUI:CreateWindow({
    Title = "Drip Menu",
    Icon = "crown",
    Theme = "Sky",

    Background = "rbxassetid://9614015066",
    BackgroundImageTransparency = 0.15,

    Transparent = true,
})

local ConfigTab = Window:Tab({
    Title = "Config",
    Icon = "settings",
})

ConfigTab:Section({
    Title = "Utilidades"
})

ConfigTab:Button({
    Title = "Restore Chat",
    Desc = "Restaura a janela e entrada do chat",
    Icon = "message-circle",

    Callback = function()

        local TextChatService = game:GetService("TextChatService")
        local StarterGui = game:GetService("StarterGui")

        local ChatWindow
        local ChatInput

        pcall(function()
            ChatWindow = TextChatService:WaitForChild(
                "ChatWindowConfiguration",
                5
            )
        end)

        pcall(function()
            ChatInput = TextChatService:WaitForChild(
                "ChatInputBarConfiguration",
                5
            )
        end)

        if ChatWindow then
            pcall(function()
                ChatWindow.Enabled = true
            end)
        end

        if ChatInput then
            pcall(function()
                ChatInput.Enabled = true
            end)
        end

        pcall(function()
            StarterGui:SetCoreGuiEnabled(
                Enum.CoreGuiType.Chat,
                true
            )
        end)

        pcall(function()
            StarterGui:SetCore(
                "ChatActive",
                true
            )
        end)

        WindUI:Notify({
            Title = "Restore Chat",
            Content = "Chat restaurado com sucesso!",
            Icon = "message-circle",
            Duration = 3,
        })
    end,
})

ConfigTab:Section({
    Title = "Performance"
})

ConfigTab:Button({
    Title = "Anti-Lag Potato Mode",
    Desc = "Reduz efeitos visuais para melhorar o desempenho",
    Icon = "zap",

    Callback = function()

        local Lighting = game:GetService("Lighting")
        local Workspace = game:GetService("Workspace")
        local Terrain = Workspace:FindFirstChildOfClass("Terrain")

        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            Lighting.ClockTime = 12

            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect")
                    or v:IsA("BloomEffect")
                    or v:IsA("BlurEffect")
                    or v:IsA("ColorCorrectionEffect")
                    or v:IsA("SunRaysEffect")
                    or v:IsA("Atmosphere") then

                    v:Destroy()
                end
            end
        end)

        pcall(function()
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0

                if sethiddenproperty then
                    sethiddenproperty(
                        Terrain,
                        "Decoration",
                        false
                    )
                end
            end
        end)

        pcall(function()
            settings().Rendering.QualityLevel =
                Enum.QualityLevel.Level01
        end)

        pcall(function()
            settings().Rendering.GraphicsMode =
                Enum.GraphicsMode.NoGraphics
        end)

        pcall(function()
            local UserGameSettings =
                UserSettings():GetService(
                    "UserGameSettings"
                )

            UserGameSettings.SavedQualityLevel =
                Enum.SavedQualityLevel.Level1

            UserGameSettings.MasterVolume = 0.5
        end)

        local function optimizePart(obj)

            pcall(function()

                if obj:IsA("BasePart") then

                    obj.Material =
                        Enum.Material.SmoothPlastic

                    obj.Reflectance = 0
                    obj.CastShadow = false

                elseif obj:IsA("Decal")
                    or obj:IsA("Texture") then

                    obj:Destroy()

                elseif obj:IsA("ParticleEmitter")
                    or obj:IsA("Trail")
                    or obj:IsA("Fire")
                    or obj:IsA("Smoke")
                    or obj:IsA("Sparkles") then

                    obj:Destroy()

                elseif obj:IsA("Explosion") then

                    obj:Destroy()

                end

            end)
        end

        for _, obj in ipairs(
            Workspace:GetDescendants()
        ) do
            optimizePart(obj)
        end

        if not _G.DripAntiLagConnection then

            _G.DripAntiLagConnection =
                Workspace.DescendantAdded:Connect(
                    function(obj)

                        task.spawn(function()
                            optimizePart(obj)
                        end)

                    end
                )

        end

        pcall(function()
            if setfpscap then
                setfpscap(999)
            end
        end)

        WindUI:Notify({
            Title = "Anti-Lag",
            Content = "Potato Mode ativado!",
            Icon = "zap",
            Duration = 4,
        })

        print(
            "[Drip Menu] Modo batata"
        )
    end,
})

local MacroTab = Window:Tab({
    Title = "Parkour",
    Icon = "video",
})

MacroTab:Section({
    Title = "Rotas de Parkour"
})

MacroTab:Paragraph({
    Title = "Rotas prontas",
    Desc = "Aqui estão rotas de parkour já feitas. Selecione o sistema abaixo para acessar e executar as rotas disponíveis."
})

MacroTab:Button({
    Title = "Rotas Prontas",
    Desc = "Abrir rotas de parkour já gravadas",
    Icon = "route",
    Callback = function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/SpaceXecho/0000/refs/heads/main/obfuscated_script-1787435003096.lua.txt"
        ))()
    end,
})

MacroTab:Section({
    Title = "Gravador"
})

MacroTab:Button({
    Title = "Gravar Parkour",
    Desc = "Abrir o gravador de parkour",
    Icon = "video",
    Callback = function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/SpaceXecho/MiniHub/refs/heads/main/mini%20huh%20ZX.lua%20(1).txt"
        ))()
    end,
})

local FarmTab = Window:Tab({
	Title = "Fazenda",
	Icon = "leaf",
})

FarmTab:Section({ Title = "Gerenciador de Missões" })

local FarmConfig = { Enabled = false, SelectedMission = "Lixo" }
local collectedTrash = {}
local hasBoughtScythe = false
local ignoredGrass = {}
local activeVisualHighlights = {}

local function ClearActiveHighlights()
	for _, hl in pairs(activeVisualHighlights) do
		if hl and hl.Parent then hl:Destroy() end
	end
	activeVisualHighlights = {}
end

local function GetClosestPromptByAction(actionText, ignoreTable)
	local char, root, hum = GetChar()
	if not root then return nil end
	local closestPrompt, shortestDist = nil, math.huge
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.ActionText == actionText then
			local parentPart = obj.Parent
			if parentPart and parentPart:IsA("BasePart") then
				local skip = false
				if ignoreTable then
					for _, oldPart in pairs(ignoreTable) do
						if oldPart == parentPart then skip = true; break end
					end
				end
				if not skip then
					local dist = (root.Position - parentPart.Position).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						closestPrompt = obj
					end
				end
			end
		end
	end
	return closestPrompt
end

FarmTab:Dropdown({
	Title = "Escolher Missão",
	Desc = "Selecione Lixo, Grama ou Caixa",
	Values = { "Lixo", "Grama", "Caixa" },
	Value = "Lixo",
	Callback = function(opt)
		FarmConfig.SelectedMission = opt
		WindUI:Notify({
			Title = "Missão",
			Content = "Selecionado: " .. tostring(opt),
			Icon = "check",
			Duration = 2,
		})
	end,
})

FarmTab:Toggle({
	Title = "Ativar Auto Missões",
	Desc = "Liga/desliga o farm automático",
	Value = false,
	Callback = function(Value)
		FarmConfig.Enabled = Value
		if not Value then
			TimerLabel.Visible = false
			ClearActiveHighlights()
		end
	end,
})

task.spawn(function()
	while true do
		task.wait(0.5)
		if FarmConfig.Enabled then
			pcall(function()
				ClearActiveHighlights()
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("ProximityPrompt") then
						local isTarget = false
						if FarmConfig.SelectedMission == "Lixo" and (obj.ActionText == "Recolher" or obj.ActionText == "Jogar Lixo") then
							isTarget = true
						elseif FarmConfig.SelectedMission == "Grama" and (obj.ActionText == "Comprar [2500$]" or obj.ActionText == "Cortar [Requer Foice]") then
							isTarget = true
						elseif FarmConfig.SelectedMission == "Caixa" and (string.find(string.lower(obj.ActionText), "caixa") or string.find(string.lower(obj.ActionText), "pegar") or string.find(string.lower(obj.Name), "caixa")) then
							isTarget = true
						end
						if isTarget and obj.Parent and obj.Parent:IsA("BasePart") then
							local part = obj.Parent
							local highlight = Instance.new("Highlight")
							highlight.Name = "ProdigizxGreenESP"
							highlight.Adornee = part
							highlight.FillColor = Color3.fromRGB(0, 255, 0)
							highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
							highlight.FillTransparency = 0.4
							highlight.OutlineTransparency = 0
							highlight.Parent = part
							table.insert(activeVisualHighlights, highlight)
						end
					end
				end

				local char, root, hum = GetChar()
				if root and hum then
					if FarmConfig.SelectedMission == "Lixo" then
						TimerLabel.Visible = false
						local collectPrompt = GetClosestPromptByAction("Recolher", collectedTrash)
						if collectPrompt and collectPrompt.Parent and FarmConfig.Enabled then
							local part = collectPrompt.Parent
							if part:IsA("BasePart") then
								table.insert(collectedTrash, part)
								if #collectedTrash > 20 then table.remove(collectedTrash, 1) end
								root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
								task.wait(0.3)
								pcall(function() fireproximityprompt(collectPrompt) end)
							end
						end
						task.wait(0.3)
						local dropPrompt = GetClosestPromptByAction("Jogar Lixo", nil)
						if dropPrompt and dropPrompt.Parent and FarmConfig.Enabled then
							local part = dropPrompt.Parent
							if part:IsA("BasePart") then
								root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
								task.wait(0.3)
								pcall(function() fireproximityprompt(dropPrompt) end)
							end
						end
					elseif FarmConfig.SelectedMission == "Grama" then
						TimerLabel.Visible = false
						EquipToolByName("Foice")
						if not hasBoughtScythe then
							local buyPrompt = GetClosestPromptByAction("Comprar [2500$]", nil)
							if buyPrompt and buyPrompt.Parent and FarmConfig.Enabled then
								local part = buyPrompt.Parent
								if part:IsA("BasePart") then
									root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
									task.wait(0.4)
									pcall(function() fireproximityprompt(buyPrompt) end)
									task.wait(1)
									hasBoughtScythe = true
								end
							end
						else
							local cutPrompt = GetClosestPromptByAction("Cortar [Requer Foice]", ignoredGrass)
							if cutPrompt and cutPrompt.Parent and FarmConfig.Enabled then
								local part = cutPrompt.Parent
								if part:IsA("BasePart") then
									table.insert(ignoredGrass, part)
									if #ignoredGrass > 15 then table.remove(ignoredGrass, 1) end
									root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
									task.wait(0.3)
									pcall(function() fireproximityprompt(cutPrompt) end)
								end
							end
						end
					elseif FarmConfig.SelectedMission == "Caixa" then
						TimerLabel.Visible = true
						TimerLabel.Text = "Status: Buscando caixa..."
						local boxPrompt = nil
						for _, obj in ipairs(workspace:GetDescendants()) do
							if obj:IsA("ProximityPrompt") then
								local actionLower = string.lower(obj.ActionText)
								local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
								if string.find(actionLower, "caixa") or string.find(actionLower, "pegar") or string.find(parentName, "caixa") then
									boxPrompt = obj
									break
								end
							end
						end

						if boxPrompt and boxPrompt.Parent and boxPrompt.Parent:IsA("BasePart") and FarmConfig.Enabled then
							local part = boxPrompt.Parent
							root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
							task.wait(0.4)
							pcall(function() fireproximityprompt(boxPrompt) end)
							task.wait(0.5)

							if not FarmConfig.Enabled then return end

							root.CFrame = CFrame.new(442, 4, -224)
							task.wait(1)

							if not FarmConfig.Enabled then return end

							root.CFrame = CFrame.new(-595, 8, -13973)
							
							WindUI:Notify({
								Title = "Missão Caixa",
								Content = "Caixa entregue com sucesso!",
								Icon = "check",
								Duration = 3,
							})
							
							local waitTime = 30
							while waitTime > 0 and FarmConfig.Enabled do
								TimerLabel.Text = "Próximo reinício em: " .. waitTime .. "s"
								task.wait(1)
								waitTime = waitTime - 1
							end
						else
							TimerLabel.Text = "Status: Nenhuma caixa encontrada..."
							task.wait(1)
						end
					end
				end
			end)
		else
			TimerLabel.Visible = false
		end
	end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--==================================================
-- CHARACTERS TAB
--==================================================

local CharactersTab = Window:Tab({
    Title = "Characters",
    Icon = "user"
})

--==================================================
-- INVISÍVEL FE
--==================================================

CharactersTab:Section({
    Title = "Invisível FE"
})

CharactersTab:Paragraph({
    Title = "Invisível FE",
    Desc = "Deixa apenas um clone visual totalmente imóvel no lugar do seu corpo real. Seu personagem real fica oculto e separado do clone."
})

local InvisibleEnabled = false

local UNDERGROUND_DISTANCE = 75
local MOVE_SPEED = 16
local JUMP_POWER = 50

local character
local humanoid
local root

local visualCharacter
local visualHumanoid
local visualRoot

local undergroundPosition
local visualPosition

local verticalVelocity = 0
local grounded = true

local renderConnection
local characterAddedConnection

local originalParts = {}

--==================================================
-- UTILIDADES
--==================================================

local function saveOriginalCharacter()
    originalParts = {}

    if not character then
        return
    end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            originalParts[obj] = {
                Transparency = obj.Transparency,
                CanCollide = obj.CanCollide,
                CanTouch = obj.CanTouch,
                CanQuery = obj.CanQuery,
                Massless = obj.Massless
            }

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            originalParts[obj] = {
                Transparency = obj.Transparency
            }
        end
    end
end

local function restoreCharacter()
    for obj, data in pairs(originalParts) do
        if obj and obj.Parent then
            if obj:IsA("BasePart") then
                obj.Transparency = data.Transparency
                obj.CanCollide = data.CanCollide
                obj.CanTouch = data.CanTouch
                obj.CanQuery = data.CanQuery
                obj.Massless = data.Massless

            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = data.Transparency
            end
        end
    end

    originalParts = {}
end

local function hideRealCharacter()
    if not character then
        return
    end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.Massless = true

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
    end

    if humanoid then
        humanoid.AutoRotate = false
    end
end

local function destroyVisualCharacter()
    if visualCharacter then
        visualCharacter:Destroy()
        visualCharacter = nil
    end

    visualHumanoid = nil
    visualRoot = nil
end

--==================================================
-- CRIA CLONE VISUAL
--==================================================

local function createVisualCharacter()
    if not character or not root then
        return false
    end

    character.Archivable = true

    destroyVisualCharacter()

    visualCharacter = character:Clone()

    if not visualCharacter then
        return false
    end

    visualCharacter.Name = "VisualCharacter"

    for _, obj in ipairs(visualCharacter:GetDescendants()) do

        if obj:IsA("Script")
        or obj:IsA("LocalScript")
        or obj:IsA("ModuleScript") then

            obj:Destroy()

        elseif obj:IsA("BasePart") then
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.Massless = true
            obj.Anchored = false

        elseif obj:IsA("Decal")
        or obj:IsA("Texture") then
            obj.Transparency = 0
        end
    end

    visualHumanoid = visualCharacter:FindFirstChildOfClass("Humanoid")
    visualRoot = visualCharacter:FindFirstChild("HumanoidRootPart")

    if not visualRoot then
        visualCharacter:Destroy()
        visualCharacter = nil
        return false
    end

    if visualHumanoid then
        visualHumanoid.AutoRotate = false
        visualHumanoid.DisplayDistanceType =
            Enum.HumanoidDisplayDistanceType.None

        visualHumanoid.WalkSpeed = MOVE_SPEED
        visualHumanoid.JumpPower = JUMP_POWER
        visualHumanoid.UseJumpPower = true
    end

    visualCharacter.Parent = workspace

    visualPosition = root.Position

    visualCharacter:PivotTo(
        root.CFrame
    )

    return true
end

--==================================================
-- CONFIGURA PERSONAGEM
--==================================================

local function setupCharacter(newCharacter)
    if not InvisibleEnabled then
        return
    end

    character = newCharacter

    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")

    saveOriginalCharacter()

    undergroundPosition =
        root.Position - Vector3.new(
            0,
            UNDERGROUND_DISTANCE,
            0
        )

    visualPosition = root.Position

    verticalVelocity = 0
    grounded = true

    if not createVisualCharacter() then
        return
    end

    task.wait()

    hideRealCharacter()

    local camera = workspace.CurrentCamera

    if camera and visualHumanoid then
        camera.CameraSubject = visualHumanoid
    end
end

--==================================================
-- ATIVA
--==================================================

local function enableInvisible()
    if InvisibleEnabled then
        return
    end

    InvisibleEnabled = true

    character =
        player.Character
        or player.CharacterAdded:Wait()

    humanoid =
        character:FindFirstChildOfClass("Humanoid")

    root =
        character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        InvisibleEnabled = false
        return
    end

    setupCharacter(character)

    -- Evita criar conexão duplicada
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    renderConnection = RunService.RenderStepped:Connect(function(deltaTime)

        if not InvisibleEnabled then
            return
        end

        if not character
        or not character.Parent
        or not humanoid
        or not root
        or not visualCharacter
        or not visualCharacter.Parent
        or not visualHumanoid
        or not visualRoot then
            return
        end

        --==========================================
        -- CORPO REAL
        --==========================================

        root.CFrame =
            CFrame.new(undergroundPosition)

        root.AssemblyLinearVelocity =
            Vector3.zero

        root.AssemblyAngularVelocity =
            Vector3.zero

        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = false
                obj.CanTouch = false
                obj.CanQuery = false
                obj.Transparency = 1
            end
        end

        --==========================================
        -- MOVIMENTO DO CLONE
        --==========================================

        local moveDirection =
            humanoid.MoveDirection

        if moveDirection.Magnitude > 0 then

            local direction = Vector3.new(
                moveDirection.X,
                0,
                moveDirection.Z
            )

            if direction.Magnitude > 0 then

                direction = direction.Unit

                visualPosition +=
                    direction *
                    MOVE_SPEED *
                    deltaTime

                visualCharacter:PivotTo(
                    CFrame.lookAt(
                        visualPosition,
                        visualPosition + direction
                    )
                )
            end
        end

        --==========================================
        -- PULO
        --==========================================

        if humanoid.Jump and grounded then

            verticalVelocity = JUMP_POWER
            grounded = false

            humanoid.Jump = false
        end

        --==========================================
        -- GRAVIDADE
        --==========================================

        if not grounded then

            verticalVelocity -=
                workspace.Gravity *
                deltaTime

            visualPosition += Vector3.new(
                0,
                verticalVelocity * deltaTime,
                0
            )

            local groundY =
                undergroundPosition.Y +
                UNDERGROUND_DISTANCE

            if visualPosition.Y <= groundY then

                visualPosition = Vector3.new(
                    visualPosition.X,
                    groundY,
                    visualPosition.Z
                )

                verticalVelocity = 0
                grounded = true
            end
        end

        --==========================================
        -- MANTÉM CLONE NA POSIÇÃO
        --==========================================

        local currentPivot =
            visualCharacter:GetPivot()

        local rotationOnly =
            currentPivot -
            currentPivot.Position

        visualCharacter:PivotTo(
            CFrame.new(visualPosition) *
            rotationOnly
        )

        --==========================================
        -- CÂMERA
        --==========================================

        local camera =
            workspace.CurrentCamera

        if camera
        and camera.CameraSubject ~= visualHumanoid then

            camera.CameraSubject =
                visualHumanoid
        end
    end)

    --==============================================
    -- RESPAWN
    --==============================================

    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end

    characterAddedConnection =
        player.CharacterAdded:Connect(function(newCharacter)

            if not InvisibleEnabled then
                return
            end

            task.wait(0.2)

            if InvisibleEnabled then
                setupCharacter(newCharacter)
            end
        end)
end

--==================================================
-- DESATIVA
--==================================================

local function disableInvisible()

    InvisibleEnabled = false

    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end

    destroyVisualCharacter()

    if character and character.Parent then

        restoreCharacter()

        if humanoid then
            humanoid.AutoRotate = true
        end
    end

    character = nil
    humanoid = nil
    root = nil

    undergroundPosition = nil
    visualPosition = nil

    verticalVelocity = 0
    grounded = true

    -- Devolve a câmera para o personagem real
    local currentCharacter = player.Character

    if currentCharacter then
        local currentHumanoid =
            currentCharacter:FindFirstChildOfClass("Humanoid")

        if currentHumanoid then
            local camera =
                workspace.CurrentCamera

            if camera then
                camera.CameraSubject =
                    currentHumanoid
            end
        end
    end
end

CharactersTab:Toggle({
    Title = "Invisível FE",
    Desc = "Esconde seu corpo real e mantém um clone visual no local original.",
    Value = false,

    Callback = function(Value)

        if Value then
            enableInvisible()
        else
            disableInvisible()
        end

    end
})

CharactersTab:Section({
    Title = "Fly"
})

CharactersTab:Button({
    Title = "Fly",
    Desc = "Ativa o Fly.",
    Callback = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/SpaceXecho/Voar/refs/heads/main/FlyGuiV3.txt"
            ))()
        end)

        if not success then
            warn("Erro ao executar o Fly: " .. tostring(err))
        end
    end
})

CharactersTab:Section({
    Title = "Movement"
})

local NoclipEnabled = false
local NoclipConnection

local function setNoclip(enabled)
    local character = player.Character
    if not character then return end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = not enabled
        end
    end
end

CharactersTab:Toggle({
    Title = "Noclip",
    Desc = "Permite atravessar objetos e paredes.",
    Value = false,

    Callback = function(Value)
        NoclipEnabled = Value

        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end

        if Value then
            NoclipConnection = RunService.Stepped:Connect(function()
                setNoclip(true)
            end)
        else
            setNoclip(false)
        end
    end
})

local EspTab = Window:Tab({ 
	Title = "ESP", 
	Icon = "eye", 
})
EspTab:Section({ Title = "Configurações do ESP" })

local ESP = { 
	Enabled = false, 
	Boxes = false, 
	Lines = false, 
	Names = false, 
	Distance = false, 
	Ranks = false, 
	MaxDistance = 1000, 
	MaxPlayers = 10, 
	Color = Color3.fromRGB(255, 140, 0) 
} 
local ESP_LinesPool = {} 

local function GetOrCreateLine(index)
	if not ESP_LinesPool[index] then
		if not Drawing or not Drawing.new then
			return nil
		end
		local ok, line = pcall(function()
			return Drawing.new("Line")
		end)
		if not ok or not line then
			return nil
		end
		line.Visible = false
		line.Color = ESP.Color
		line.Thickness = 1
		line.Transparency = 1
		ESP_LinesPool[index] = line
	end
	return ESP_LinesPool[index]
end

local function CleanESP(char) 
	if not char then return end 
	local hl = char:FindFirstChild("PRDG_Highlight") 
	local bb = char:FindFirstChild("PRDG_Billboard") 
	if hl then hl:Destroy() end 
	if bb then bb:Destroy() end 
end

local function ApplyESP(targetPlayer) 
	if targetPlayer == player then return end 
	local function SetupCharacter(char) 		
		if not char then return end 		
		CleanESP(char) 		
		local root = char:WaitForChild("HumanoidRootPart", 5) 		
		if not root then return end 		
		local hl = Instance.new("Highlight") 		
		hl.Name = "PRDG_Highlight" 		
		hl.FillColor = ESP.Color 		
		hl.OutlineColor = Color3.fromRGB(255, 255, 255) 		
		hl.FillTransparency = 0.5 		
		hl.Enabled = false 		
		hl.Parent = char 		
		local bb = Instance.new("BillboardGui") 		
		bb.Name = "PRDG_Billboard" 		
		bb.Adornee = root 		
		bb.Size = UDim2.new(0, 200, 0, 50) 		
		bb.StudsOffset = Vector3.new(0, 3.5, 0) 		
		bb.AlwaysOnTop = true 		
		bb.Enabled = false 		
		local txt = Instance.new("TextLabel") 		
		txt.Name = "InfoText" 		
		txt.Size = UDim2.new(1, 0, 1, 0) 		
		txt.BackgroundTransparency = 1 		
		txt.TextColor3 = ESP.Color 		
		txt.TextSize = 13 		
		txt.Font = Enum.Font.SourceSansBold 		
		txt.Parent = bb 		
		bb.Parent = char 	
	end 	
	if targetPlayer.Character then SetupCharacter(targetPlayer.Character) end 	
	targetPlayer.CharacterAdded:Connect(SetupCharacter) 
end

for _, p in ipairs(Players:GetPlayers()) do ApplyESP(p) end 
Players.PlayerAdded:Connect(ApplyESP)

RunService.RenderStepped:Connect(function() 	
	local myChar = player.Character 	
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart") 	
	local cam = workspace.CurrentCamera 	
	local sortedPlayers = {} 	
	for _, line in pairs(ESP_LinesPool) do line.Visible = false end 	
	if myRoot then 
		for _, p in ipairs(Players:GetPlayers()) do 
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then 
				local hum = p.Character:FindFirstChildOfClass("Humanoid") 
				if hum and hum.Health > 0 then 
					local root = p.Character.HumanoidRootPart 
					local dist = (myRoot.Position - root.Position).Magnitude 
					if dist <= ESP.MaxDistance then 
						table.insert(sortedPlayers, {player = p, Distance = dist}) 
					end 
				end 
			end 
		end 
		table.sort(sortedPlayers, function(a, b) return a.Distance < b.Distance end) 
	end 	
	for _, p in ipairs(Players:GetPlayers()) do 
		if p ~= player and p.Character then 
			local char = p.Character 
			local hl = char:FindFirstChild("PRDG_Highlight") 
			local bb = char:FindFirstChild("PRDG_Billboard") 
			if hl then hl.Enabled = false end 
			if bb then bb.Enabled = false end 
		end 
	end 	
	if ESP.Enabled and #sortedPlayers > 0 then 
		local limit = math.min(ESP.MaxPlayers, #sortedPlayers) 
		for i = 1, limit do 
			local entry = sortedPlayers[i] 
			local p = entry.player 
			if p and p.Character then 
				local char = p.Character 
				local hl = char:FindFirstChild("PRDG_Highlight") 
				local bb = char:FindFirstChild("PRDG_Billboard") 
				if hl then hl.Enabled = ESP.Boxes end 
				if bb then bb.Enabled = (ESP.Names or ESP.Distance or ESP.Ranks) end 
				if ESP.Lines then 
					local root = char:FindFirstChild("HumanoidRootPart") 
					if root then 
						local screenPos, onScreen = cam:WorldToViewportPoint(root.Position) 
						if onScreen then 
							local line = GetOrCreateLine(i)
							if line then
								line.Visible = true
								line.Color = ESP.Color
								line.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
								line.To = Vector2.new(screenPos.X, screenPos.Y)
							end 
						end 
					end 
				end 
				if myRoot then 
					local root = char:FindFirstChild("HumanoidRootPart") 
					if root then 
						local dist = entry.Distance 
						local txt = bb and bb:FindFirstChild("InfoText") 
						if txt then 
							local str = "" 
							if ESP.Names then str = str .. p.Name end 
							if ESP.Ranks then 
								local leaderstats = p:FindFirstChild("leaderstats") 
								local rankVal = leaderstats and (leaderstats:FindFirstChild("Patente") or leaderstats:FindFirstChild("Rank") or leaderstats:FindFirstChild("Level")) 
								local rankText = rankVal and tostring(rankVal.Value) or "Sem Patente" 
								str = str .. " [" .. rankText .. "]" 
							end 
							if ESP.Distance then str = str .. " (" .. math.floor(dist) .. "m)" end 
							txt.Text = str 
						end 
					end 
				end 
			end 
		end 
	end 
end)

EspTab:Input({ 
	Title = "Qtd de Jogadores no ESP", 
	Desc = "Máximo de jogadores exibidos", 
	Placeholder = "Ex: 10", 
	Value = "10", 
	Callback = function(Text) 
		ESP.MaxPlayers = tonumber(Text) or 10 
	end, 
})
EspTab:Toggle({ 
	Title = "Ativar ESP Geral", 
	Desc = "Liga/desliga o ESP", 
	Value = false, 
	Callback = function(Value) ESP.Enabled = Value end, 
})
EspTab:Toggle({ 
	Title = "Caixas / Highlight", 
	Desc = "Mostra highlight nos jogadores", 
	Value = false, 
	Callback = function(Value) ESP.Boxes = Value end, 
})
EspTab:Toggle({ 
	Title = "Linhas (ESP Lines)", 
	Desc = "Linhas do centro da tela até o jogador", 
	Value = false, 
	Callback = function(Value) ESP.Lines = Value end, 
})
EspTab:Toggle({ 
	Title = "Mostrar Nomes", 
	Desc = "Exibe o nome do jogador", 
	Value = false, 
	Callback = function(Value) ESP.Names = Value end, 
})
EspTab:Toggle({ 
	Title = "Mostrar Distância", 
	Desc = "Exibe a distância em metros", 
	Value = false, 
	Callback = function(Value) ESP.Distance = Value end, 
})
EspTab:Toggle({ 
	Title = "Ver Patentes / Ranks", 
	Desc = "Exibe patente/rank do leaderstats", 
	Value = false, 
	Callback = function(Value) ESP.Ranks = Value end, 
})

local MusicTab = Window:Tab({ 
	Title = "Rádio", 
	Icon = "music", 
})
MusicTab:Section({ Title = "Tocador de Música" })

local Music_System = { SoundId = "9043887091", Volume = 1, Instance = nil }

MusicTab:Input({ 
	Title = "ID do Áudio", 
	Desc = "Cole o ID do áudio do Roblox", 
	Placeholder = "Cole o ID aqui", 
	Value = "9043887091", 
	Callback = function(Text) 
		if Text ~= "" then Music_System.SoundId = Text end 
	end, 
})
MusicTab:Button({ 
	Title = "Tocar Música", 
	Desc = "Reproduz o áudio em loop", 
	Icon = "play", 
	Callback = function() 
		if Music_System.Instance then Music_System.Instance:Destroy() end 
		local cleanID = string.match(tostring(Music_System.SoundId), "%d+") 
		if cleanID then 
			local sound = Instance.new("Sound") 
			sound.SoundId = "rbxassetid://" .. cleanID 
			sound.Volume = Music_System.Volume 
			sound.Looped = true 
			sound.Parent = SoundService 
			sound:Play() 
			Music_System.Instance = sound 
			WindUI:Notify({ 
				Title = "Rádio", 
				Content = "Tocando!", 
				Icon = "music", 
				Duration = 2, 
			}) 
		end 
	end, 
})
MusicTab:Button({ 
	Title = "Parar Música", 
	Desc = "Para e remove o som atual", 
	Icon = "square", 
	Callback = function() 
		if Music_System.Instance then 
			Music_System.Instance:Destroy() 
			Music_System.Instance = nil 
			WindUI:Notify({ 
				Title = "Rádio", 
				Content = "Parado", 
				Icon = "check", 
				Duration = 2, 
			}) 
		end 
	end, 
})

local AutoJJSTab = Window:Tab({ 
	Title = "Auto JJS", 
	Icon = "settings", 
})
AutoJJSTab:Section({ Title = "Função Automática" })
AutoJJSTab:Button({ 
	Title = "Executar Auto JJS", 
	Desc = "Carrega o script de Auto JJs", 
	Icon = "play", 
	Callback = function() 
		loadstring(game:HttpGet("https://rawscripts.net/raw/Brazilian-Army-Auto-JJs-EB-do-Delta-sem-key-224236"))() 
		WindUI:Notify({ 
			Title = "Auto JJS", 
			Content = "Script executado!", 
			Icon = "check", 
			Duration = 3, 
		}) 
	end, 
})

local ParkourTab = Window:Tab({ 
	Title = "Auxílios", 
	Icon = "footprints", 
})
ParkourTab:Section({ Title = "PRODIGIZX MINI HUB ⛩️" })

local ParkourEnabled = false 
local Hitboxes = {} 
local data = { 
	{pos = Vector3.new(185.03, 5.04, -661.62), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.39, 13.26, -661.39), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.11, 21.28, -661.68), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.30, 29.29, -661.72), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(186.08, 37.36, -661.76), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(186.08, 45.36, -661.76), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(186.25, 53.36, -661.86), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.82, 61.36, -662.00), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.60, 69.40, -661.98), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.71, 77.42, -661.90), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(185.28, 85.44, -662.14), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.42, 93.48, -662.05), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.08, 5.26, -618.66), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.36, 13.28, -618.65), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(185.32, 21.29, -618.70), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.65, 29.34, -618.67), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(186.12, 37.36, -618.43), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(186.30, 45.34, -617.87), size = Vector3.new(5.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.41, 53.36, -618.05), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(185.62, 61.40, -617.79), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.58, 69.40, -617.79), size = Vector3.new(4.00, 0.50, 17.00)}, 
	{pos = Vector3.new(185.87, 77.42, -618.33), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(185.73, 85.44, -618.62), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(185.68, 93.48, -618.49), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(270.22, 4.24, -661.72), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(277.86, 4.24, -655.56), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(269.80, 4.24, -649.96), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(284.45, 4.24, -660.72), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(284.59, 4.24, -650.23), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(267.14, 5.04, -627.94), size = Vector3.new(4.00, 0.50, 32.00)}, 
	{pos = Vector3.new(288.33, 5.04, -627.86), size = Vector3.new(4.00, 0.50, 31.00)}, 
	{pos = Vector3.new(277.48, 7.63, -591.97), size = Vector3.new(4.00, 0.50, 27.00)}, 
	{pos = Vector3.new(271.76, 7.64, -569.98), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(279.08, 7.64, -567.95), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(265.48, 7.64, -564.93), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(271.34, 7.64, -559.70), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(259.46, 7.64, -561.92), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(260.50, 7.64, -554.72), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(250.93, 7.64, -561.91), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(248.66, 7.64, -554.60), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(243.06, 7.64, -565.74), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(235.96, 7.64, -560.93), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(240.08, 7.64, -592.47), size = Vector3.new(4.00, 0.50, 27.00)}, 
	{pos = Vector3.new(394.19, 5.06, -850.78), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(389.19, 7.45, -855.82), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(392.91, 5.06, -861.09), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(384.07, 10.15, -855.95), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(377.51, 12.94, -855.73), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(370.87, 14.68, -855.83), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(365.12, 16.20, -856.03), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(358.50, 17.61, -855.96), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(351.76, 19.27, -856.05), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(345.37, 20.53, -855.83), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(339.00, 21.54, -855.95), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(334.51, 21.54, -850.11), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(328.83, 21.54, -855.97), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(335.00, 21.54, -861.70), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(324.43, 21.54, -861.35), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(324.69, 21.54, -850.36), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(318.73, 21.54, -855.70), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(313.47, 21.54, -861.90), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(308.27, 21.54, -855.88), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(314.49, 21.54, -850.04), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(303.58, 21.54, -861.59), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(303.61, 21.54, -850.61), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(298.50, 21.54, -856.16), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(393.87, 2.87, -892.93), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(394.65, 2.87, -902.16), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(389.37, 5.04, -892.40), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(389.57, 5.04, -903.24), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(383.37, 7.79, -892.63), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(383.64, 7.79, -903.27), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(378.64, 9.35, -892.48), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(378.64, 9.35, -903.24), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(373.27, 11.53, -892.90), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(372.82, 11.53, -903.33), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(368.47, 11.53, -892.69), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(367.91, 11.53, -903.02), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(362.88, 11.53, -894.04), size = Vector3.new(4.00, 0.50, 7.00)}, 
	{pos = Vector3.new(358.03, 11.53, -901.74), size = Vector3.new(4.00, 0.50, 6.00)}, 
	{pos = Vector3.new(352.36, 11.53, -894.75), size = Vector3.new(4.00, 0.50, 6.00)}, 
	{pos = Vector3.new(347.47, 11.53, -899.21), size = Vector3.new(4.00, 0.50, 6.00)}, 
	{pos = Vector3.new(333.21, 11.53, -897.81), size = Vector3.new(5.00, 0.50, 12.00)}, 
	{pos = Vector3.new(325.73, 11.53, -898.53), size = Vector3.new(5.00, 0.50, 12.00)}, 
	{pos = Vector3.new(318.25, 11.53, -897.79), size = Vector3.new(5.00, 0.50, 11.00)}, 
	{pos = Vector3.new(310.71, 11.53, -898.95), size = Vector3.new(5.00, 0.50, 12.00)}, 
	{pos = Vector3.new(303.10, 11.53, -898.29), size = Vector3.new(5.00, 0.50, 12.00)}, 
	{pos = Vector3.new(295.54, 11.53, -898.01), size = Vector3.new(5.00, 0.50, 12.00)}, 
	{pos = Vector3.new(288.21, 11.53, -898.79), size = Vector3.new(5.00, 0.50, 12.00)}, 
	{pos = Vector3.new(149.54, 1.04, -856.00), size = Vector3.new(3.00, 0.50, 13.00)}, 
	{pos = Vector3.new(148.21, 7.50, -855.93), size = Vector3.new(4.00, 0.50, 13.00)}, 
	{pos = Vector3.new(148.27, 13.38, -856.27), size = Vector3.new(4.00, 0.50, 13.00)}, 
	{pos = Vector3.new(162.71, 13.70, -859.82), size = Vector3.new(8.00, 0.50, 5.00)}, 
	{pos = Vector3.new(170.73, 13.70, -852.89), size = Vector3.new(8.00, 0.50, 5.00)}, 
	{pos = Vector3.new(181.41, 13.70, -859.17), size = Vector3.new(8.00, 0.50, 5.00)}, 
	{pos = Vector3.new(190.97, 13.70, -853.25), size = Vector3.new(8.00, 0.50, 5.00)}, 
	{pos = Vector3.new(217.92, 12.53, -848.28), size = Vector3.new(32.00, 0.50, 4.00)}, 
	{pos = Vector3.new(217.99, 13.04, -863.62), size = Vector3.new(29.00, 0.50, 4.00)}, 
	{pos = Vector3.new(243.52, 12.04, -855.57), size = Vector3.new(14.00, 0.50, 3.00)}, 
	{pos = Vector3.new(150.43, 5.27, -897.87), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(150.71, 13.28, -898.27), size = Vector3.new(4.00, 0.50, 17.00)}, 
	{pos = Vector3.new(150.28, 21.29, -898.42), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(150.45, 29.30, -898.11), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(150.52, 37.31, -898.44), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(150.56, 45.32, -897.73), size = Vector3.new(4.00, 0.50, 15.00)}, 
	{pos = Vector3.new(150.95, 53.33, -898.02), size = Vector3.new(4.00, 0.50, 16.00)}, 
	{pos = Vector3.new(167.23, 53.26, -903.84), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(172.90, 53.26, -900.06), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(167.09, 53.26, -890.73), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(181.65, 53.26, -902.00), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(180.48, 53.26, -893.06), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(201.10, 53.33, -897.28), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(212.50, 53.33, -897.85), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(225.52, 53.33, -898.25), size = Vector3.new(5.00, 0.50, 5.00)}, 
	{pos = Vector3.new(237.61, 53.33, -897.82), size = Vector3.new(5.00, 0.50, 5.00)}, 
}

local function CreateHitboxes() 
	for _, v in ipairs(data) do 
		local p = Instance.new("Part", workspace) 
		p.Name = "VAKHA_Hitbox" 
		p.Size = v.size 
		p.Position = v.pos 
		p.Anchored = true 
		p.Transparency = 1 
		local Box = Instance.new("SelectionBox", p) 
		Box.Adornee = p 
		Box.Color3 = Color3.fromRGB(150, 60, 0) 
		Box.SurfaceColor3 = Color3.fromRGB(255, 140, 0) 
		Box.SurfaceTransparency = 0.5 
		Box.LineThickness = 0.08 
		table.insert(Hitboxes, p) 
	end 
end

ParkourTab:Toggle({ 
	Title = "Drip menu auxiliares ⛩️ (Parkours)", 
	Desc = "Ativa/desativa as hitboxes de parkour", 
	Value = false, 
	Callback = function(Value) 
		ParkourEnabled = Value 
		if ParkourEnabled then 
			CreateHitboxes() 
			WindUI:Notify({ 
				Title = "Parkour", 
				Content = "Hitboxes ativados!", 
				Icon = "check", 
				Duration = 2, 
			}) 
		else 
			for _, v in ipairs(Hitboxes) do 
				if v and v.Parent then v:Destroy() end 
			end 
			Hitboxes = {} 
			WindUI:Notify({ 
				Title = "Parkour", 
				Content = "Hitboxes removidos!", 
				Icon = "check", 
				Duration = 2, 
			}) 
		end 
	end, 
})

RunService.Heartbeat:Connect(function() 
	if not ParkourEnabled then return end 
	local char = player.Character 
	local hrp = char and char:FindFirstChild("HumanoidRootPart") 
	if not hrp then return end 
	local velY = hrp.AssemblyLinearVelocity.Y 
	for _, part in ipairs(Hitboxes) do 
		if part and part.Parent then 
			part.CanCollide = (velY <= 0.5 and hrp.Position.Y > (part.Position.Y + part.Size.Y / 2 - 1)) 
		end 
	end 
end)

local CombatTab = Window:Tab({ Title = "Combat", Icon = "swords", })
CombatTab:Section({ Title = "Hitbox Expander" })

local HitboxConfig = { Enabled = false, Size = 5, Transparency = 0.5, Color = Color3.fromRGB(255, 140, 0) } 
local OriginalSizes = {} 

local function RestoreHitboxes() 
    for p, originalSize in pairs(OriginalSizes) do 
        if p and p.Character then 
            local root = p.Character:FindFirstChild("HumanoidRootPart") 
            if root then 
                root.Size = originalSize 
                root.Transparency = 1 
                local box = root:FindFirstChild("ProdigizxHitboxVisual") 
                if box then box:Destroy() end 
            end 
        end 
    end 
    OriginalSizes = {} 
end

CombatTab:Toggle({ 
    Title = "Ativar Hitbox Expander", 
    Desc = "Aumenta o tamanho da hitbox dos jogadores", 
    Value = false, 
    Callback = function(Value) 
        HitboxConfig.Enabled = Value 
        if not Value then RestoreHitboxes() end 
    end 
})
CombatTab:Input({ 
    Title = "Tamanho da Hitbox", 
    Desc = "Valor entre 2 e 50", 
    Placeholder = "Ex: 5", 
    Value = "5", 
    Callback = function(Text) 
        local num = tonumber(Text) 
        if num then HitboxConfig.Size = math.clamp(num, 2, 50) end 
    end 
})
CombatTab:Input({ 
    Title = "Transparência", 
    Desc = "Valor entre 0 e 1", 
    Placeholder = "Ex: 0.5", 
    Value = "0.5", 
    Callback = function(Text) 
        local num = tonumber(Text) 
        if num then HitboxConfig.Transparency = math.clamp(num, 0, 1) end 
    end 
})

RunService.RenderStepped:Connect(function() 
    if not HitboxConfig.Enabled then return end 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= player and p.Character then 
            local root = p.Character:FindFirstChild("HumanoidRootPart") 
            local hum = p.Character:FindFirstChildOfClass("Humanoid") 
            if root and hum and hum.Health > 0 then 
                if not OriginalSizes[p] then OriginalSizes[p] = root.Size end 
                local targetSize = Vector3.new(HitboxConfig.Size, HitboxConfig.Size, HitboxConfig.Size) 
                if root.Size ~= targetSize then 
                    root.Size = targetSize 
                    root.CanCollide = false 
                end 
                local visualBox = root:FindFirstChild("ProdigizxHitboxVisual") 
                if not visualBox then 
                    visualBox = Instance.new("SelectionBox") 
                    visualBox.Name = "ProdigizxHitboxVisual" 
                    visualBox.Adornee = root 
                    visualBox.Parent = root 
                end 
                visualBox.Color3 = HitboxConfig.Color 
                visualBox.SurfaceColor3 = HitboxConfig.Color 
                visualBox.SurfaceTransparency = HitboxConfig.Transparency 
                visualBox.LineThickness = 0.05 
            end 
        end 
    end 
end)

Players.PlayerRemoving:Connect(function(p) OriginalSizes[p] = nil end)

CombatTab:Section({
    Title = "Loja"
})

CombatTab:Paragraph({
    Title = "Script de Loja",
    Desc = "Abre uma loja com opções de compra/equipamento de itens."
})

CombatTab:Button({
    Title = "Abrir Loja",
    Desc = "Executa o script da loja",
    Callback = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SpaceXecho/Gun/refs/heads/main/obfuscated_script-1787610239075.lua.txt"))()
        end)

        if not success then
            warn("Erro ao abrir a loja: " .. tostring(err))
        end
    end
})

local CharsTab = Window:Tab({ Title = "Chars", Icon = "user", })

local function CopyCharCommand(charName) 
    local command = ";char me " .. charName 
    if setclipboard then 
        setclipboard(command) 
    elseif toclipboard then 
        toclipboard(command) 
    end 
    WindUI:Notify({ 
        Title = "Chars", 
        Content = "Comando copiado: " .. command, 
        Duration = 2 
    }) 
end

CharsTab:Button({ Title = "NEMOKJK", Description = "Copiar ;char me NEMOKJK", Callback = function() CopyCharCommand("NEMOKJK") end })
CharsTab:Button({ Title = "Mk_luluhh", Description = "Copiar ;char me Mk_luluhh", Callback = function() CopyCharCommand("Mk_luluhh") end })
CharsTab:Button({ Title = "Gabriel_USSF", Description = "Copiar ;char me Gabriel_USSF", Callback = function() CopyCharCommand("Gabriel_USSF") end })
CharsTab:Button({ Title = "Poug", Description = "Copiar ;char me Poug", Callback = function() CopyCharCommand("Poug") end })
CharsTab:Button({ Title = "therealtoddyx", Description = "Copiar ;char me therealtoddyx", Callback = function() CopyCharCommand("therealtoddyx") end })
CharsTab:Button({ Title = "Zscoupz_00", Description = "Copiar ;char me Zscoupz_00", Callback = function() CopyCharCommand("Zscoupz_00") end })
CharsTab:Button({ Title = "OIIILUKAZ", Description = "Copiar ;char me OIIILUKAZ", Callback = function() CopyCharCommand("OIIILUKAZ") end })
CharsTab:Button({ Title = "oboina05", Description = "Copiar ;char me oboina05", Callback = function() CopyCharCommand("oboina05") end })
CharsTab:Button({ Title = "Futuro_marechal", Description = " Somente Marechal | Copiar ;char me Futuro_marechal", Callback = function() CopyCharCommand("Futuro_marechal") end })
CharsTab:Button({ Title = "Murilo_ms1", Description = "Copiar ;char me Murilo_ms1", Callback = function() CopyCharCommand("Murilo_ms1") end })
CharsTab:Button({ Title = "Feiquinbr", Description = "Copiar ;char me Feiquinbr", Callback = function() CopyCharCommand("Feiquinbr") end })
CharsTab:Button({ Title = "Brasil2020p", Description = "Copiar ;char me Brasil2020p", Callback = function() CopyCharCommand("Brasil2020p") end })
CharsTab:Button({ Title = "s4enrique", Description = "Copiar ;char me s4enrique", Callback = function() CopyCharCommand("s4enrique") end })
CharsTab:Button({ Title = "admdorminhoco", Description = "Copiar ;char me admdorminhoco", Callback = function() CopyCharCommand("admdorminhoco") end })
CharsTab:Button({ Title = "fazerftw", Description = "Copiar ;char me fazerftw", Callback = function() CopyCharCommand("fazerftw") end })
CharsTab:Button({ Title = "danielgamer8464", Description = "Copiar ;char me danielgamer8464", Callback = function() CopyCharCommand("danielgamer8464") end })
CharsTab:Button({ Title = "marasawfan", Description = "Copiar ;char me marasawfan", Callback = function() CopyCharCommand("marasawfan") end })
CharsTab:Button({ Title = "apoiata", Description = "Copiar ;char me apoiata", Callback = function() CopyCharCommand("apoiata") end })
CharsTab:Button({ Title = "tommacena975", Description = "Copiar ;char me tommacena975", Callback = function() CopyCharCommand("tommacena975") end })

local TafTab = Window:Tab({
    Title = "Tools",
    Icon = "clipboard",
})

TafTab:Section({
    Title = "Ferramentas"
})

TafTab:Button({
    Title = "TAFs",
    Desc = "Abrir Cola TAFs",
    Icon = "clipboard",
    Callback = function()

        local success, err = pcall(function()

            local Players = game:GetService("Players")
            local UserInputService = game:GetService("UserInputService")
            local TweenService = game:GetService("TweenService")

            local player = Players.LocalPlayer
            local playerGui = player:WaitForChild("PlayerGui")

            -- Evita criar a GUI duas vezes
            local oldGui = playerGui:FindFirstChild("DripTAF")
            if oldGui then
                oldGui:Destroy()
            end

            -- Paleta de Cores
            local C = {
                Background = Color3.fromRGB(15, 17, 23),
                Sidebar = Color3.fromRGB(20, 23, 30),
                Card = Color3.fromRGB(26, 30, 40),
                CardHover = Color3.fromRGB(35, 40, 52),
                Accent = Color3.fromRGB(0, 122, 255),
                AccentHover = Color3.fromRGB(50, 150, 255),
                Text = Color3.fromRGB(240, 243, 246),
                TextDim = Color3.fromRGB(115, 125, 140),
                Success = Color3.fromRGB(46, 204, 113),
                Border = Color3.fromRGB(40, 46, 60)
            }

            -- GUI
            local ScreenGui = Instance.new("ScreenGui")
            ScreenGui.Name = "DripTAF"
            ScreenGui.ResetOnSpawn = false
            ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            ScreenGui.Parent = playerGui

            -- Botão de alternar
            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Name = "Toggle"
            ToggleBtn.Size = UDim2.new(0, 180, 0, 46)
            ToggleBtn.Position = UDim2.new(0, 25, 0.5, -23)
            ToggleBtn.BackgroundColor3 = C.Accent
            ToggleBtn.Text = "☰ DRIP TAF"
            ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
            ToggleBtn.TextSize = 13
            ToggleBtn.Font = Enum.Font.SourceSansBold
            ToggleBtn.AutoButtonColor = false
            ToggleBtn.Parent = ScreenGui

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 12)
            ToggleCorner.Parent = ToggleBtn

            -- Janela principal
            local MainFrame = Instance.new("Frame")
            MainFrame.Name = "MainFrame"
            MainFrame.Size = UDim2.new(0, 640, 0, 460)
            MainFrame.Position = UDim2.new(0.5, -320, 0.5, -230)
            MainFrame.BackgroundColor3 = C.Background
            MainFrame.Visible = false
            MainFrame.ClipsDescendants = true
            MainFrame.Parent = ScreenGui

            local MainCorner = Instance.new("UICorner")
            MainCorner.CornerRadius = UDim.new(0, 16)
            MainCorner.Parent = MainFrame

            -- Cabeçalho
            local Header = Instance.new("Frame")
            Header.Size = UDim2.new(1, 0, 0, 65)
            Header.BackgroundColor3 = C.Sidebar
            Header.BorderSizePixel = 0
            Header.Parent = MainFrame

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -140, 1, 0)
            Title.Position = UDim2.new(0, 24, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = "DRIP TAF"
            Title.TextColor3 = C.Text
            Title.TextSize = 15
            Title.Font = Enum.Font.SourceSansBold
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Header

            local CloseBtn = Instance.new("TextButton")
            CloseBtn.Size = UDim2.new(0, 34, 0, 34)
            CloseBtn.Position = UDim2.new(1, -45, 0.5, -17)
            CloseBtn.BackgroundColor3 = C.Card
            CloseBtn.Text = "✕"
            CloseBtn.TextColor3 = C.Text
            CloseBtn.TextSize = 14
            CloseBtn.Font = Enum.Font.SourceSansBold
            CloseBtn.AutoButtonColor = false
            CloseBtn.Parent = Header

            local CloseCorner = Instance.new("UICorner")
            CloseCorner.CornerRadius = UDim.new(0, 10)
            CloseCorner.Parent = CloseBtn

            -- Sidebar
            local Sidebar = Instance.new("ScrollingFrame")
            Sidebar.Size = UDim2.new(0, 200, 1, -65)
            Sidebar.Position = UDim2.new(0, 0, 0, 65)
            Sidebar.BackgroundColor3 = C.Sidebar
            Sidebar.BorderSizePixel = 0
            Sidebar.CanvasSize = UDim2.new(0, 0, 0, 500)
            Sidebar.ScrollBarThickness = 2
            Sidebar.ScrollBarImageColor3 = C.Accent
            Sidebar.Parent = MainFrame

            local SidebarList = Instance.new("UIListLayout")
            SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
            SidebarList.Padding = UDim.new(0, 6)
            SidebarList.Parent = Sidebar

            local SidebarPadding = Instance.new("UIPadding")
            SidebarPadding.PaddingTop = UDim.new(0, 12)
            SidebarPadding.PaddingLeft = UDim.new(0, 10)
            SidebarPadding.PaddingRight = UDim.new(0, 10)
            SidebarPadding.Parent = Sidebar

            -- Área de conteúdo
            local ContentArea = Instance.new("Frame")
            ContentArea.Size = UDim2.new(1, -200, 1, -65)
            ContentArea.Position = UDim2.new(0, 200, 0, 65)
            ContentArea.BackgroundColor3 = C.Background
            ContentArea.ClipsDescendants = true
            ContentArea.Parent = MainFrame

            local PagesFolder = Instance.new("Folder")
            PagesFolder.Parent = ContentArea

            local currentTab = nil
            local tabData = {}

            -- Card
            local function createCard(parent, text, copy)
                local Card = Instance.new("Frame")
                Card.Size = UDim2.new(1, 0, 0, 55)
                Card.BackgroundColor3 = C.Card
                Card.Parent = parent

                local CardCorner = Instance.new("UICorner")
                CardCorner.CornerRadius = UDim.new(0, 10)
                CardCorner.Parent = Card

                local TextLabel = Instance.new("TextLabel")
                TextLabel.Size = UDim2.new(1, -90, 1, 0)
                TextLabel.Position = UDim2.new(0, 15, 0, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.Text = text
                TextLabel.TextColor3 = C.Text
                TextLabel.TextSize = 13
                TextLabel.Font = Enum.Font.SourceSans
                TextLabel.TextWrapped = true
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.Parent = Card

                local CopyBtn = Instance.new("TextButton")
                CopyBtn.Size = UDim2.new(0, 75, 0, 28)
                CopyBtn.Position = UDim2.new(1, -83, 0.5, -14)
                CopyBtn.BackgroundColor3 = C.Accent
                CopyBtn.Text = "Copiar"
                CopyBtn.TextColor3 = Color3.new(1, 1, 1)
                CopyBtn.TextSize = 11
                CopyBtn.Font = Enum.Font.SourceSansBold
                CopyBtn.AutoButtonColor = false
                CopyBtn.Parent = Card

                local CopyCorner = Instance.new("UICorner")
                CopyCorner.CornerRadius = UDim.new(0, 8)
                CopyCorner.Parent = CopyBtn

                CopyBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        if setclipboard then
                            setclipboard(copy)
                        end
                    end)

                    CopyBtn.Text = "✔ Copiado"
                    CopyBtn.BackgroundColor3 = C.Success

                    task.wait(1.5)

                    if CopyBtn and CopyBtn.Parent then
                        CopyBtn.Text = "Copiar"
                        CopyBtn.BackgroundColor3 = C.Accent
                    end
                end)

                return Card
            end

            -- Seleção de abas
            local function selectTab(name, btn, label, icon, page)
                if currentTab == name then
                    return
                end

                if currentTab then
                    local prev = tabData[currentTab]

                    if prev then
                        TweenService:Create(
                            prev.btn,
                            TweenInfo.new(0.2),
                            {BackgroundTransparency = 1}
                        ):Play()

                        prev.label.TextColor3 = C.TextDim
                        prev.icon.TextColor3 = C.TextDim
                    end

                    local prevPage = PagesFolder:FindFirstChild(currentTab .. "_Page")

                    if prevPage then
                        prevPage.Visible = false
                    end
                end

                currentTab = name

                TweenService:Create(
                    btn,
                    TweenInfo.new(0.2),
                    {BackgroundTransparency = 0}
                ):Play()

                btn.BackgroundColor3 = C.Card
                label.TextColor3 = C.Text
                icon.TextColor3 = C.Accent

                if page then
                    page.Visible = true
                end
            end

            -- Criar aba
            local function createTab(name, icon)
                local TabBtn = Instance.new("TextButton")
                TabBtn.Size = UDim2.new(1, 0, 0, 40)
                TabBtn.BackgroundTransparency = 1
                TabBtn.Text = ""
                TabBtn.AutoButtonColor = false
                TabBtn.Parent = Sidebar

                local TabCorner = Instance.new("UICorner")
                TabCorner.CornerRadius = UDim.new(0, 8)
                TabCorner.Parent = TabBtn

                local TabLayout = Instance.new("UIListLayout")
                TabLayout.FillDirection = Enum.FillDirection.Horizontal
                TabLayout.Padding = UDim.new(0, 12)
                TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                TabLayout.Parent = TabBtn

                local TabPadding = Instance.new("UIPadding")
                TabPadding.PaddingLeft = UDim.new(0, 12)
                TabPadding.Parent = TabBtn

                local IconLabel = Instance.new("TextLabel")
                IconLabel.Size = UDim2.new(0, 20, 1, 0)
                IconLabel.BackgroundTransparency = 1
                IconLabel.Text = icon
                IconLabel.TextSize = 15
                IconLabel.TextColor3 = C.TextDim
                IconLabel.Parent = TabBtn

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Size = UDim2.new(1, -35, 1, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = name
                NameLabel.TextColor3 = C.TextDim
                NameLabel.TextSize = 12
                NameLabel.Font = Enum.Font.SourceSans
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                NameLabel.Parent = TabBtn

                local Page = Instance.new("Frame")
                Page.Name = name .. "_Page"
                Page.Size = UDim2.new(1, -20, 1, -20)
                Page.Position = UDim2.new(0, 10, 0, 10)
                Page.BackgroundTransparency = 1
                Page.Visible = false
                Page.Parent = PagesFolder

                local Scroll = Instance.new("ScrollingFrame")
                Scroll.Size = UDim2.new(1, 0, 1, 0)
                Scroll.BackgroundTransparency = 1
                Scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
                Scroll.ScrollBarThickness = 3
                Scroll.ScrollBarImageColor3 = C.Accent
                Scroll.Parent = Page

                local PageLayout = Instance.new("UIListLayout")
                PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
                PageLayout.Padding = UDim.new(0, 8)
                PageLayout.Parent = Scroll

                PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    Scroll.CanvasSize = UDim2.new(
                        0,
                        0,
                        0,
                        PageLayout.AbsoluteContentSize.Y + 20
                    )
                end)

                -- Conteúdo
                if name == "BFE" then

                    createCard(Scroll, "👻 BFE = Fantasma.", "BFE = Fantasma.")
                    createCard(Scroll, "👤 Criador: MaxTheJp1. Criado: 1983.", "MaxTheJp1")
                    createCard(Scroll, "🛡️ O escudo do BFE possui fundo preto com bordas amarelas.", "O escudo do BFE possui fundo preto com bordas amarelas.")
                    createCard(Scroll, "🎖️ Comandante: NATANHMELLO4.", "NATANHMELLO4")
                    createCard(Scroll, "🎖️ Subcomandante: RenanFoxiy.", "RenanFoxiy")
                    createCard(Scroll, "👻 Lema BFE:\n⚔️ Qualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.", "Qualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.")
                    createCard(Scroll, "🫡 Saudações, senhores Agentes.", "Saudações, senhores Agentes.")
                    createCard(Scroll, "🫡 Saudações, senhores Fantasmas.", "Saudações, senhores Fantasmas.")
                    createCard(Scroll, "🫡 Saudações, senhor Agente.", "Saudações, senhor Agente.")
                    createCard(Scroll, "🫡 Saudações, senhor Fantasma.", "Saudações, senhor Fantasma.")
                    createCard(Scroll, "📜 Com licença, senhor Agente.", "Com licença, senhor Agente.")
                    createCard(Scroll, "📜 Com licença, senhor Fantasma.", "Com licença, senhor Fantasma.")
                    createCard(Scroll, "📜 Licença, senhor Agente.", "Licença, senhor Agente.")
                    createCard(Scroll, "📜 Licença, senhor Fantasma.", "Licença, senhor Fantasma.")

                elseif name == "BPE" then

                    createCard(Scroll, "👮 BPE = Policial.", "BPE = Policial.")
                    createCard(Scroll, "🎖️ Comandante: zCostasz.", "zCostasz")
                    createCard(Scroll, "🎖️ Subcomandante: Matheuslindo587.", "Matheuslindo587")
                    createCard(Scroll, "📜 Lema:\nOrientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.", "Orientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.")
                    createCard(Scroll, "🗣️ PRONOMES;", "")
                    createCard(Scroll, "🫡 Saudações, senhores Policiais.", "Saudações, senhores Policiais.")
                    createCard(Scroll, "🫡 Saudação, senhor Policial.", "Saudação, senhor Policial.")

                elseif name == "BAC" then

                    createCard(Scroll, "💀 BAC = INFORMAÇÕES", "BAC = INFORMAÇÕES")
                    createCard(Scroll, "👤 Dono: MateusHgz.", "MateusHgz")
                    createCard(Scroll, "🎖️ Comandante: SasukeePro202.", "SasukeePro202")
                    createCard(Scroll, "🎖️ Subcomandante: DanielSxS2.", "DanielSxS2")
                    createCard(Scroll, "⚔️ Lema da BAC:\nO máximo de confusão, morte e destruição na retaguarda do inimigo.", "O máximo de confusão, morte e destruição na retaguarda do inimigo.")
                    createCard(Scroll, "🐎 Lema REC-MEC:\nHaverá sempre uma Cavalaria! & Aço na mente, motor no peito e honra na missão!", "Haverá sempre uma Cavalaria! & Aço na mente, motor no peito e honra na missão!")
                    createCard(Scroll, "👮 Lema BPE:\nOrientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.", "Orientar o Responsável, Corrigir o Irresponsável, Prender o Incorrigível.")
                    createCard(Scroll, "🫡 SAUDAÇÕES:\nSaudações, senhor Comando.", "Saudações, senhor Comando.")
                    createCard(Scroll, "🫡 Saudações, senhores Comandos.", "Saudações, senhores Comandos.")
                    createCard(Scroll, "🫡 Saudações, senhores Policiais.", "Saudações, senhores Policiais.")
                    createCard(Scroll, "🫡 Saudações, senhor Policial.", "Saudações, senhor Policial.")

                elseif name == "CIE" then

                    createCard(Scroll, "🕵️ CIE = Agente.", "CIE = Agente.")
                    createCard(Scroll, "👤 Criador: vicofjgfhf.", "vicofjgfhf")
                    createCard(Scroll, "👤 Sub criador: RIP_dabfj8w.", "RIP_dabfj8w")
                    createCard(Scroll, "🎖️ Comandante: eriqurrr.", "eriqurrr")
                    createCard(Scroll, "🎖️ Subcomandante: nohanrtop.", "nohanrtop")
                    createCard(Scroll, "🧠 Lema CIE:\nInteligência para Vitória & Saber para Prever.", "Inteligência para Vitória & Saber para Prever.")
                    createCard(Scroll, "👻 Lema BFE:\nQualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.", "Qualquer missão, em qualquer lugar, a qualquer hora, de qualquer maneira.")
                    createCard(Scroll, "🫡 Saudações, senhores Agentes.", "Saudações, senhores Agentes.")
                    createCard(Scroll, "🫡 Saudações, senhores Fantasmas.", "Saudações, senhores Fantasmas.")
                    createCard(Scroll, "🫡 Saudações, senhor Agente.", "Saudações, senhor Agente.")
                    createCard(Scroll, "🫡 Saudações, senhor Fantasma.", "Saudações, senhor Fantasma.")

                elseif name == "CYBER" then

                    createCard(Scroll, "💻 CYBER = Analista.", "CYBER = Analista.")
                    createCard(Scroll, "👤 Criador: wAnTee16j5156.", "wAnTee16j5156")
                    createCard(Scroll, "👑 Dono: MaxTheJp1.", "MaxTheJp1")
                    createCard(Scroll, "👑 Dono: ItsMeLyrio.", "ItsMeLyrio")
                    createCard(Scroll, "👑 Dono: Gabriel2444q.", "Gabriel2444q")
                    createCard(Scroll, "🎖️ Comandante: highhandry98.", "highhandry98")
                    createCard(Scroll, "🛡️ Lema:\nSegurança no ciberespaço, soberania para a Nação.", "Segurança no ciberespaço, soberania para a Nação.")
                    createCard(Scroll, "🤝 Saudações, senhores Analistas.", "Saudações, senhores Analistas.")
                    createCard(Scroll, "🔒 JURO:\nGUARDAR SIGILO SOBRE TUDO QUE VER E OUVIR NO COMDCIBER!", "GUARDAR SIGILO SOBRE TUDO QUE VER E OUVIR NO COMDCIBER!")

                elseif name == "Caat" then

                    createCard(Scroll, "🌵 CAATINGA = Guardiões da Caatinga.", "CAATINGA = Guardiões da Caatinga.")
                    createCard(Scroll, "🎖️ Subcomandante: gabrielcm04.", "gabrielcm04")
                    createCard(Scroll, "🌵 Lema:\nO pai cria, a mãe educa e a Caatinga elimina.", "O pai cria, a mãe educa e a Caatinga elimina.")
                    createCard(Scroll, "🫡 Saudações, senhores Guardiões.", "Saudações, senhores Guardiões.")

                elseif name == "Rec-Mec" then

                    createCard(Scroll, "🐎 REC-MEC = Cavaleiros.", "REC-MEC = Cavaleiros.")
                    createCard(Scroll, "🎖️ Comandante: terro_2433.", "terro_2433")
                    createCard(Scroll, "🎖️ Subcomandante: Contanum5bl.", "Contanum5bl")
                    createCard(Scroll, "⚔️ Lema:\nHaverá sempre uma Cavalaria!", "Haverá sempre uma Cavalaria!")
                    createCard(Scroll, "🫡 Saudações, senhores Cavaleiros.", "Saudações, senhores Cavaleiros.")
                    createCard(Scroll, "📢 ATENÇÃO PELOTÃO, MARCHEM!", "ATENÇÃO PELOTÃO, MARCHEM!")

                elseif name == "AMAN" then

                    createCard(Scroll, "🎓 AMAN = Academia Militar.", "AMAN = Academia Militar.")
                    createCard(Scroll, "⭐ Lema:\nCasa de Valores, Escola de Líderes.", "Casa de Valores, Escola de Líderes.")
                    createCard(Scroll, "🫡 Saudações, senhores Cadetes.", "Saudações, senhores Cadetes.")

                end

                tabData[name] = {
                    btn = TabBtn,
                    label = NameLabel,
                    icon = IconLabel,
                    page = Page
                }

                TabBtn.MouseButton1Click:Connect(function()
                    selectTab(name, TabBtn, NameLabel, IconLabel, Page)
                end)
            end

            local tabList = {
                {"BFE", "👻"},
                {"BPE", "👮"},
                {"BAC", "💀"},
                {"CIE", "🕵️"},
                {"CYBER", "💻"},
                {"Caat", "🌵"},
                {"Rec-Mec", "🐎"},
                {"AMAN", "🎓"},
            }

            for _, info in ipairs(tabList) do
                createTab(info[1], info[2])
            end

            if tabData["BFE"] then
                local t = tabData["BFE"]
                selectTab("BFE", t.btn, t.label, t.icon, t.page)
            end

            CloseBtn.MouseButton1Click:Connect(function()
                MainFrame.Visible = false
            end)

            ToggleBtn.MouseButton1Click:Connect(function()
                MainFrame.Visible = not MainFrame.Visible
            end)

            local dragging = false
            local dragStart = nil
            local startPos = nil

            Header.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = MainFrame.Position
                end
            end)

            Header.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - dragStart
                    MainFrame.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)

            MainFrame.Visible = true
        end)

        if not success then
            warn("Erro ao abrir a Cola TAFs:", err)
        end
    end,
})

TafTab:Button({
    Title = "Auto Gramática",
    Desc = "Abrir o Auto Gramática e corrigir automaticamente a gramática",
    Icon = "spell-check",
    Callback = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SpaceXecho/AutoGramatic/refs/heads/main/obfuscated_script-1787614685489.lua.txt"))()
        end)
        if not success then
            warn("Erro ao abrir o Auto Gramática:", err)
        end
    end,
})

local CreditTab = Window:Tab({ 
    Title = "Créditos", 
    Icon = "info", 
})

CreditTab:Section({ Title = "Desenvolvedor" })

CreditTab:Button({ 
    Title = "TikTok: @prdgzx071", 
    Desc = "Siga no TikTok", 
    Icon = "user", 
    Callback = function() 
        WindUI:Notify({ 
            Title = "Créditos", 
            Content = "TikTok: @prdgzx071", 
            Icon = "info", 
            Duration = 3, 
        }) 
    end, 
})

CreditTab:Button({ 
    Title = "Dev: willz and prodigiozx", 
    Desc = "Desenvolvido por prodigiozx e willz", 
    Icon = "code", 
    Callback = function() 
        WindUI:Notify({ 
            Title = "Créditos", 
            Content = "Desenvolvido por willz e prodigiozx.", 
            Icon = "info", 
            Duration = 3, 
        }) 
    end, 
})


WindUI:Notify({ 
	Title = "Willz lindo", 
	Content = "Molezinha aqui tiox", 
	Icon = "check", 
	Duration = 5, 
})
