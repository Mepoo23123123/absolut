--!strict

-- EconomyService.server.luau
-- Система экономики и ежедневных наград

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Загружаем PlayerDataManager для интеграции
local PlayerDataManager = require(script.Parent.Shared.PlayerDataManager)

-- Конфигурация наград
local DAILY_REWARDS_CONFIG = {
	[1] = { Coins = 50, Experience = 25, Items = { { Id = "Potion", Quantity = 1 } } },
	[2] = { Coins = 75, Experience = 35, Items = { { Id = "Sword", Quantity = 1 } } },
	[3] = { Coins = 100, Experience = 50, Items = { { Id = "Potion", Quantity = 3 } } },
	[4] = { Coins = 125, Experience = 60, Items = { { Id = "Shield", Quantity = 1 } } },
	[5] = { Coins = 150, Experience = 75, Items = { { Id = "Potion", Quantity = 5 } } },
	[6] = { Coins = 200, Experience = 100, Items = { { Id = "Sword", Quantity = 1 } } },
	[7] = { Coins = 300, Experience = 150, Items = { { Id = "Potion", Quantity = 10 } } }
}

-- Создаем RemoteEvent для связи с клиентом
local DailyRewardsEvent = Instance.new("RemoteEvent")
DailyRewardsEvent.Name = "DailyRewardsEvent"
DailyRewardsEvent.Parent = ReplicatedStorage

-- Сервис экономики
local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new()
	local self = setmetatable({}, EconomyService)
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

function EconomyService:OnPlayerAdded(player: Player)
	local dataManager = PlayerDataManager:GetPlayerData(player)
	if dataManager then
		-- Инициализация данных для ежедневных наград
		if not dataManager.Data.DailyRewards then
			dataManager.Data.DailyRewards = {
				LastClaimed = 0,
				CurrentStreak = 0
			}
		end
		self.PlayersData[player] = dataManager
	end
end

function EconomyService:OnPlayerRemoving(player: Player)
	local dataManager = self.PlayersData[player]
	if dataManager then
		dataManager:Save()
		self.PlayersData[player] = nil
	end
end

-- Проверка доступности награды
function EconomyService:IsRewardAvailable(playerData: table): boolean
	local lastClaimed = playerData.DailyRewards.LastClaimed
	local now = os.time()
	
	-- Проверяем, прошло ли 24 часа с последней награды
	return (now - lastClaimed) >= 86400 -- 24 часа в секундах
end

-- Получение текущей награды по статусу
function EconomyService:GetCurrentReward(playerData: table): table
	local streak = playerData.DailyRewards.CurrentStreak
	local day = math.min(streak + 1, #DAILY_REWARDS_CONFIG)
	return DAILY_REWARDS_CONFIG[day]
end

-- Выдача ежедневной награды
function EconomyService:ClaimDailyReward(player: Player): table
	local dataManager = self.PlayersData[player]
	if not dataManager then
		return { Success = false, Message = "Player data not found" }
	end
	
	local playerData = dataManager.Data
	local dailyData = playerData.DailyRewards
	
	-- Проверка доступности награды
	if not self:IsRewardAvailable(playerData) then
		return { Success = false, Message = "Reward not available yet" }
	end
	
	-- Получение награды
	local reward = self:GetCurrentReward(playerData)
	
	-- Выдача наград
	dataManager:AddCoins(reward.Coins)
	dataManager:AddExperience(reward.Experience)
	
	-- Выдача предметов
	for _, item in ipairs(reward.Items) do
		dataManager:AddItem(item.Id, item.Quantity)
	end
	
	-- Обновление статистики
	dailyData.CurrentStreak += 1
	dailyData.LastClaimed = os.time()
	dataManager:Save()
	
	return {
		Success = true,
		Reward = reward,
		Streak = dailyData.CurrentStreak,
		Message = "Daily reward claimed successfully"
	}
end

-- Получение статуса наград
function EconomyService:GetRewardStatus(player: Player): table
	local dataManager = self.PlayersData[player]
	if not dataManager then
		return { Available = false, TimeLeft = 0, Streak = 0 }
	end
	
	local playerData = dataManager.Data
	local dailyData = playerData.DailyRewards
	local lastClaimed = dailyData.LastClaimed
	local now = os.time()
	local timeLeft = 86400 - (now - lastClaimed)
	
	return {
		Available = self:IsRewardAvailable(playerData),
		TimeLeft = math.max(0, timeLeft),
		Streak = dailyData.CurrentStreak,
		NextReward = self:GetCurrentReward(playerData)
	}
end

-- Обработчик событий от клиента
DailyRewardsEvent.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local economyService = EconomyService.new()
	local args = {...}
	
	if action == "ClaimReward" then
		local result = economyService:ClaimDailyReward(player)
		DailyRewardsEvent:FireClient(player, "ClaimResult", result)
		
	elseif action == "GetStatus" then
		local status = economyService:GetRewardStatus(player)
		DailyRewardsEvent:FireClient(player, "StatusResult", status)
		
	elseif action == "GetNextReward" then
		local dataManager = economyService.PlayersData[player]
		if dataManager then
			local reward = economyService:GetCurrentReward(dataManager.Data)
			DailyRewardsEvent:FireClient(player, "NextRewardResult", reward)
		end
		
	else
		warn("Unknown daily rewards action: " .. action .. " from player: " .. player.Name)
	end
end)

-- Функция для начисления вознаграждения за убийство
function EconomyService:GiveKillReward(player: Player, killType: string)
	local dataManager = self.PlayersData[player]
	if not dataManager then return end
	
	if killType == "NPC" then
		dataManager:AddCoins(10)
		dataManager:AddExperience(20)
	elseif killType == "Player" then
		dataManager:AddCoins(25)
		dataManager:AddExperience(50)
	end
end

-- Автоматическая проверка для всех игроков (для тестирования)
game:GetService("RunService").Heartbeat:Connect(function()
	for player, dataManager in pairs(EconomyService.PlayersData or {}) do
		-- Можно добавить логику для периодических проверок
	end
end)

print("EconomyService loaded successfully")

return EconomyService