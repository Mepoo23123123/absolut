--!strict

-- QuestClient.client.luau
-- Клиентская часть системы квестов

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local QuestEvent = ReplicatedStorage:WaitForChild("QuestEvent")

-- UI элементы для отображения квестов
local function CreateQuestUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestUI"
	screenGui.ResetOnSpawn = false
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainQuestFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.02, 0, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = true
	
	local uICorner = Instance.new("UICorner")
	uICorner.CornerRadius = UDim.new(0, 10)
	uICorner.Parent = mainFrame
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "Квесты"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "QuestScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -60)
	scrollFrame.Position = UDim2.new(0, 10, 0, 50)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 123, 255)
	
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 10)
	uiListLayout.Parent = scrollFrame
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, 10)
	uiPadding.PaddingBottom = UDim.new(0, 10)
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.Parent = scrollFrame
	
	local questTemplate = Instance.new("Frame")
	questTemplate.Name = "QuestTemplate"
	questTemplate.Size = UDim2.new(1, 0, 0, 80)
	questTemplate.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	questTemplate.BorderSizePixel = 0
	questTemplate.Visible = false
	
	local questCorner = Instance.new("UICorner")
	questCorner.CornerRadius = UDim.new(0, 8)
	questCorner.Parent = questTemplate
	
	local questTitle = Instance.new("TextLabel")
	questTitle.Name = "QuestTitle"
	questTitle.Text = "Название квеста"
	questTitle.Font = Enum.Font.GothamBold
	questTitle.TextSize = 18
	questTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	questTitle.Size = UDim2.new(1, 0, 0, 25)
	questTitle.Position = UDim2.new(0, 10, 0, 5)
	questTitle.BackgroundTransparency = 1
	
	local questDesc = Instance.new("TextLabel")
	questDesc.Name = "QuestDesc"
	questDesc.Text = "Описание квеста"
	questDesc.Font = Enum.Font.Gotham
	questDesc.TextSize = 14
	questDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	questDesc.Size = UDim2.new(1, 0, 0, 20)
	questDesc.Position = UDim2.new(0, 10, 0, 30)
	questDesc.BackgroundTransparency = 1
	
	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(1, 0, 0, 20)
	progressFrame.Position = UDim2.new(0, 10, 0, 55)
	progressFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	progressFrame.BorderSizePixel = 0
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 10)
	progressCorner.Parent = progressFrame
	
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
	progressBar.BorderSizePixel = 0
	
	local progressCorner2 = Instance.new("UICorner")
	progressCorner2.CornerRadius = UDim.new(0, 10)
	progressCorner2.Parent = progressBar
	
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "ProgressLabel"
	progressLabel.Text = "0/0"
	progressLabel.Font = Enum.Font.GothamBold
	progressLabel.TextSize = 12
	progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressLabel.Size = UDim2.new(0, 50, 1, 0)
	progressLabel.Position = UDim2.new(1, -60, 0, 0)
	progressLabel.BackgroundTransparency = 1
	progressLabel.AnchorPoint = Vector2.new(1, 0)
	
	-- Добавляем элементы в иерархию
	questTitle.Parent = questTemplate
	questDesc.Parent = questTemplate
	progressFrame.Parent = questTemplate
	progressBar.Parent = progressFrame
	progressLabel.Parent = progressFrame
	questTemplate.Parent = scrollFrame
	
	title.Parent = mainFrame
	scrollFrame.Parent = mainFrame
	mainFrame.Parent = screenGui
	screenGui.Parent = Player:WaitForChild("PlayerGui")
	
	return {
		MainFrame = mainFrame,
		Title = title,
		ScrollFrame = scrollFrame,
		QuestTemplate = questTemplate,
		QuestsContainer = {}
	}
end

-- Хранилище данных
local UI = CreateQuestUI()
local ActiveQuests = {}
local AvailableQuests = {}

-- Функции для взаимодействия с сервером
local function SendRequest(action: string, ...)
	QuestEvent:FireServer(action, ...)
end

-- Создание элемента квеста
local function CreateQuestElement(questData: table): Instance
	local questElement = UI.QuestTemplate:Clone()
	questElement.Visible = true
	questElement.Name = "Quest_" .. questData.Id
	
	questElement.QuestTitle.Text = questData.Name
	questElement.QuestDesc.Text = questData.Description
	
	-- Обновление прогресса
	local function UpdateProgress()
		if questData.Progress then
			local totalProgress = 0
			local totalRequired = 0
			local objectivesText = ""
			
			for objectiveType, progress in pairs(questData.Progress) do
				totalProgress += progress.Progress
				totalRequired += progress.Required
				
				if objectivesText ~= "" then
					objectivesText ..= ", "
				end
				objectivesText ..= progress.Progress .. "/" .. progress.Required
			end
			
			local progressPercent = if totalRequired > 0 then totalProgress / totalRequired else 0
			questElement.ProgressBar:TweenSize(UDim2.new(progressPercent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3)
			questElement.ProgressLabel.Text = objectivesText
		end
	end
	
	UpdateProgress()
	
	return questElement
end

-- Обновление списка квестов
local function UpdateQuestList()
	-- Очищаем старые элементы
	for _, element in pairs(UI.QuestsContainer) do
		element:Destroy()
	end
	UI.QuestsContainer = {}
	
	-- Добавляем активные квесты
	for _, quest in ipairs(ActiveQuests) do
		local questElement = CreateQuestElement(quest)
		table.insert(UI.QuestsContainer, questElement)
		questElement.Parent = UI.ScrollFrame
	end
	
	-- Если нет активных квестов
	if #ActiveQuests == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Text = "Нет активных квестов"
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 16
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.Position = UDim2.new(0, 10, 0, 10)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Parent = UI.ScrollFrame
		table.insert(UI.QuestsContainer, emptyLabel)
	end
end

-- Обработчик событий от сервера
QuestEvent.OnClientEvent:Connect(function(eventType: string, data: table)
	if eventType == "ActiveQuestsResult" then
		ActiveQuests = data
		UpdateQuestList()
		
	elseif eventType == "AvailableQuestsResult" then
		AvailableQuests = data
		print("Available quests:", #AvailableQuests)
		
	elseif eventType == "QuestAccepted" then
		table.insert(ActiveQuests, {
			Id = data.QuestId,
			Name = data.QuestData.Name,
			Description = data.QuestData.Description,
			Progress = data.Progress
		})
		UpdateQuestList()
		
	elseif eventType == "QuestCompleted" then
		-- Удаляем завершенный квест из активных
		for i, quest in ipairs(ActiveQuests) do
			if quest.Id == data.QuestId then
				table.remove(ActiveQuests, i)
				break
			end
		end
		UpdateQuestList()
		
		-- Показываем анимацию завершения
		local completionGui = Instance.new("ScreenGui")
		completionGui.Name = "QuestCompletion"
		completionGui.ResetOnSpawn = false
		
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 300, 0, 100)
		frame.Position = UDim2.new(0.5, -150, 0.1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
		frame.BorderSizePixel = 0
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame
		
		local label = Instance.new("TextLabel")
		label.Text = "Квест завершен!"
		label.Font = Enum.Font.GothamBold
		label.TextSize = 20
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Size = UDim2.new(1, 0, 0, 40)
		label.Position = UDim2.new(0, 0, 0, 10)
		label.BackgroundTransparency = 1
		
		local rewardLabel = Instance.new("TextLabel")
		rewardLabel.Text = "Награда: " .. data.Reward.Coins .. " монет, " .. data.Reward.Experience .. " опыта"
		rewardLabel.Font = Enum.Font.Gotham
		rewardLabel.TextSize = 14
		rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		rewardLabel.Size = UDim2.new(1, 0, 0, 30)
		rewardLabel.Position = UDim2.new(0, 0, 0, 50)
		rewardLabel.BackgroundTransparency = 1
		
		label.Parent = frame
		rewardLabel.Parent = frame
		frame.Parent = completionGui
		completionGui.Parent = Player:WaitForChild("PlayerGui")
		
		-- Анимация исчезновения
		task.delay(3, function()
			TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { 
				Position = UDim2.new(0.5, -150, 0.1, -100),
				BackgroundTransparency = 1
			}):Play()
			task.delay(0.5, function()
				completionGui:Destroy()
			end)
		end)
		
	elseif eventType == "QuestProgressUpdated" then
		-- Обновляем прогресс конкретного квеста
		for _, quest in ipairs(ActiveQuests) do
			if quest.Id == data.QuestId then
				quest.Progress = data.Progress
				UpdateQuestList()
				break
			end
		end
		
	elseif eventType == "AcceptResult" then
		if data.Success then
			print("Квест принят:", data.QuestId)
		else
			print("Не удалось принять квест:", data.QuestId)
		end
	end
end)

-- Привязка к клавише для открытия UI (например, клавиша Q)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Q then
		UI.MainFrame.Visible = not UI.MainFrame.Visible
		if UI.MainFrame.Visible then
			SendRequest("GetActiveQuests")
			SendRequest("GetAvailableQuests")
		end
	end
end)

-- Инициализация
SendRequest("GetActiveQuests")
SendRequest("GetAvailableQuests")

print("QuestClient loaded successfully")