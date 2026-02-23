--!strict

-- PlayerDataManager.luau
-- Система управления данными игрока

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Модуль для хранения данных игрока
local PlayerData = {}
PlayerData.__index = PlayerData

-- Стандартные данные игрока
local DEFAULT_DATA = {
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

-- Создание нового экземпляра данных игрока
function PlayerData.new(player: Player)
	local self = setmetatable({}, PlayerData)
	
	self.Player = player
	self.UserId = player.UserId
	self.DataStore = DataStoreService:GetDataStore("PlayerData")
	self.Data = table.clone(DEFAULT_DATA)
	
	return self
end

-- Загрузка данных из DataStore
function PlayerData:Load()
	local success, result = pcall(function()
		return self.DataStore:GetAsync(tostring(self.UserId))
	end)
	
	if success and result then
		-- Объединяем сохраненные данные с дефолтными
		for key, value in pairs(result) do
			if type(value) == "table" and type(DEFAULT_DATA[key]) == "table" then
				for subKey, subValue in pairs(value) do
					self.Data[key][subKey] = subValue
				end
			else
				self.Data[key] = value
			end
		end
	else
		warn("Failed to load data for player " .. self.Player.Name .. ": " .. tostring(result))
	end
	
	return self.Data
end

-- Сохранение данных в DataStore
function PlayerData:Save()
	local success, result = pcall(function()
		self.DataStore:SetAsync(tostring(self.UserId), self.Data)
	end)
	
	if not success then
		warn("Failed to save data for player " .. self.Player.Name .. ": " .. tostring(result))
	end
end

-- Обновление конкретного значения
function PlayerData:Update(key: string, value: any)
	self.Data[key] = value
	self:Save()
end

-- Получение значения
function PlayerData:Get(key: string): any
	return self.Data[key]
end

-- Добавление опыта
function PlayerData:AddExperience(amount: number)
	self.Data.Experience += amount
	
	-- Проверка на повышение уровня
	local expNeeded = self.Data.Level * 100
	if self.Data.Experience >= expNeeded then
		self.Data.Level += 1
		self.Data.Experience -= expNeeded
		self.Data.Coins += 50 -- Бонус за уровень
	end
	
	self:Save()
end

-- Добавление монет
function PlayerData:AddCoins(amount: number)
	self.Data.Coins += amount
	self:Save()
end

-- Добавление предмета в инвентарь
function PlayerData:AddItem(itemId: string, quantity: number)
	if not self.Data.Inventory[itemId] then
		self.Data.Inventory[itemId] = 0
	end
	self.Data.Inventory[itemId] += quantity
	self:Save()
end

-- Удаление предмета из инвентаря
function PlayerData:RemoveItem(itemId: string, quantity: number)
	if self.Data.Inventory[itemId] then
		self.Data.Inventory[itemId] -= quantity
		if self.Data.Inventory[itemId] <= 0 then
			self.Data.Inventory[itemId] = nil
		end
		self:Save()
	end
end

-- Серверный менеджер для управления всеми игроками
local PlayerDataManager = {}
PlayerDataManager.__index = PlayerDataManager

function PlayerDataManager.new()
	local self = setmetatable({}, PlayerDataManager)
	self.PlayersData = {}
	
	-- Подписка на события игроков
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
	
	-- Загрузка уже подключенных игроков
	for _, player in Players:GetPlayers() do
		self:OnPlayerAdded(player)
	end
	
	return self
end

function PlayerDataManager:OnPlayerAdded(player: Player)
	local data = PlayerData.new(player)
	data:Load()
	self.PlayersData[player] = data
end

function PlayerDataManager:OnPlayerRemoving(player: Player)
	local data = self.PlayersData[player]
	if data then
		data:Save()
		self.PlayersData[player] = nil
	end
end

function PlayerDataManager:GetPlayerData(player: Player)
	return self.PlayersData[player]
end

-- Создаем и возвращаем менеджер
return PlayerDataManager.new()