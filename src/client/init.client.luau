--!strict

-- init.client.luau
-- Главный клиентский скрипт

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerDataEvent = ReplicatedStorage:WaitForChild("PlayerDataEvent")

-- Хранилище данных игрока на клиенте
local PlayerData = {
	Level = 1,
	Experience = 0,
	Coins = 0,
	Inventory = {},
	Stats = {
		Health = 100,
		Mana = 50,
		Stamina = 100
	}
}

-- Получение данных от сервера при подключении
PlayerDataEvent.OnClientEvent:Connect(function(data)
	PlayerData = data
	print("Player data loaded:", PlayerData.Level, "Level", PlayerData.Coins, "Coins")
end)

-- Функции для взаимодействия с сервером
local function SendRequest(action: string, ...)
	PlayerDataEvent:FireServer(action, ...)
end

-- Пример использования системы
local function TestSystem()
	-- Добавляем опыт
	SendRequest("AddExperience", 50)
	task.wait(1)
	
	-- Добавляем монеты
	SendRequest("AddCoins", 100)
	task.wait(1)
	
	-- Добавляем предметы
	SendRequest("AddItem", "Sword", 1)
	SendRequest("AddItem", "Potion", 5)
	task.wait(1)
	
	-- Удаляем предмет
	SendRequest("RemoveItem", "Potion", 2)
	task.wait(1)
	
	-- Обновляем статистику
	SendRequest("UpdateStat", "Health", 150)
	task.wait(1)
	
	-- Запрашиваем все данные
	SendRequest("GetAllData")
end

-- Привязка к клавише для тестирования (например, клавиша T)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.T then
		TestSystem()
	end
end)

-- Инициализация: запрос данных с сервера
SendRequest("GetAllData")

-- Создаем UI
local PixelUI = require(script.Parent:WaitForChild("PixelUI"))
local pixelUI = PixelUI.new()

print("Client loaded successfully")
