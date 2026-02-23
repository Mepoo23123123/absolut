--!strict

-- DailyRewardsClient.client.luau
-- Клиентская часть системы ежедневных наград

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local DailyRewardsEvent = ReplicatedStorage:WaitForChild("DailyRewardsEvent")

-- UI элементы для отображения наград
local function CreateRewardUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardsUI"
	screenGui.ResetOnSpawn = false
	
	local frame = Instance.new("Frame")
	frame.Name = "DailyRewardsFrame"
	frame.Size = UDim2.new(0, 300, 0, 200)
	frame.Position = UDim2.new(0.5, -150, 0.5, -100)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Visible = false
	
	local uICorner = Instance.new("UICorner")
	uICorner.CornerRadius = UDim.new(0, 10)
	uICorner.Parent = frame
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "Ежедневная награда"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Text = "Текущая серия: 0 дней"
	streakLabel.Font = Enum.Font.Gotham
	streakLabel.TextSize = 18
	streakLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	streakLabel.Size = UDim2.new(1, 0, 0, 30)
	streakLabel.Position = UDim2.new(0, 0, 0, 60)
	streakLabel.BackgroundTransparency = 1
	
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "RewardLabel"
	rewardLabel.Text = "Награда: 0 монет, 0 опыта"
	rewardLabel.Font = Enum.Font.Gotham
	rewardLabel.TextSize = 16
	rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rewardLabel.Size = UDim2.new(1, 0, 0, 30)
	rewardLabel.Position = UDim2.new(0, 0, 0, 100)
	rewardLabel.BackgroundTransparency = 1
	
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Text = "Доступно через: 00:00:00"
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 16
	timeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	timeLabel.Size = UDim2.new(1, 0, 0, 30)
	timeLabel.Position = UDim2.new(0, 0, 0, 140)
	timeLabel.BackgroundTransparency = 1
	
	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Text = "Получить награду"
	claimButton.Font = Enum.Font.GothamBold
	claimButton.TextSize = 18
	claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimButton.Size = UDim2.new(0.8, 0, 0, 40)
	claimButton.Position = UDim2.new(0.1, 0, 0, 160)
	claimButton.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
	claimButton.BorderSizePixel = 0
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = claimButton
	
	-- Добавляем элементы в иерархию
	title.Parent = frame
	streakLabel.Parent = frame
	rewardLabel.Parent = frame
	timeLabel.Parent = frame
	claimButton.Parent = frame
	frame.Parent = screenGui
	screenGui.Parent = Player:WaitForChild("PlayerGui")
	
	return {
		Frame = frame,
		Title = title,
		StreakLabel = streakLabel,
		RewardLabel = rewardLabel,
		TimeLabel = timeLabel,
		ClaimButton = claimButton
	}
end

-- Хранилище данных
local UI = CreateRewardUI()
local RewardData = {
	Available = false,
	TimeLeft = 0,
	Streak = 0,
	NextReward = nil
}

-- Функции для взаимодействия с сервером
local function SendRequest(action: string, ...)
	DailyRewardsEvent:FireServer(action, ...)
end

-- Обновление UI
local function UpdateUI()
	if RewardData.NextReward then
		UI.StreakLabel.Text = "Текущая серия: " .. RewardData.Streak .. " дней"
		UI.RewardLabel.Text = "Награда: " .. RewardData.NextReward.Coins .. " монет, " .. RewardData.NextReward.Experience .. " опыта"
		
		if RewardData.Available then
			UI.TimeLabel.Text = "Награда доступна!"
			UI.TimeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			UI.ClaimButton.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
			UI.ClaimButton.Text = "Получить награду"
			UI.ClaimButton.Enabled = true
		else
			local hours = math.floor(RewardData.TimeLeft / 3600)
			local minutes = math.floor((RewardData.TimeLeft % 3600) / 60)
			local seconds = math.floor(RewardData.TimeLeft % 60)
			local timeText = string.format("Доступно через: %02d:%02d:%02d", hours, minutes, seconds)
			UI.TimeLabel.Text = timeText
			UI.TimeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			UI.ClaimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			UI.ClaimButton.Text = "Недоступно"
			UI.ClaimButton.Enabled = false
		end
	end
end

-- Анимация получения награды
local function ShowRewardAnimation(reward: table)
	UI.Frame.Visible = true
	UI.ClaimButton.Text = "Получено!"
	UI.ClaimButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	
	-- Анимация увеличения
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(UI.Frame, tweenInfo, { Size = UDim2.new(0, 350, 0, 250) })
	tween:Play()
	
	task.delay(2, function()
		local tweenBack = TweenService:Create(UI.Frame, tweenInfo, { Size = UDim2.new(0, 300, 0, 200) })
		tweenBack:Play()
		
		task.delay(0.5, function()
			UI.Frame.Visible = false
		end)
	end)
end

-- Обработчик событий от сервера
DailyRewardsEvent.OnClientEvent:Connect(function(eventType: string, data: table)
	if eventType == "StatusResult" then
		RewardData = data
		UpdateUI()
		
	elseif eventType == "ClaimResult" then
		if data.Success then
			ShowRewardAnimation(data.Reward)
			RewardData.Streak = data.Streak
			-- Запрашиваем обновленный статус
			SendRequest("GetStatus")
		else
			warn("Failed to claim reward: " .. data.Message)
		end
		
	elseif eventType == "NextRewardResult" then
		RewardData.NextReward = data
		UpdateUI()
	end
end)

-- Обработчик нажатия кнопки
UI.ClaimButton.MouseButton1Click:Connect(function()
	if RewardData.Available then
		SendRequest("ClaimReward")
	end
end)

-- Привязка к клавише для открытия UI (например, клавиша R)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.R then
		SendRequest("GetStatus")
		SendRequest("GetNextReward")
		UI.Frame.Visible = not UI.Frame.Visible
	end
end)

-- Периодическое обновление таймера
game:GetService("RunService").Heartbeat:Connect(function()
	if RewardData.TimeLeft > 0 then
		RewardData.TimeLeft -= 1
		UpdateUI()
	end
end)

-- Инициализация
SendRequest("GetStatus")
SendRequest("GetNextReward")

print("DailyRewardsClient loaded successfully")