--!strict

-- QuestService.server.luau
-- Система квестов для Roblox

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Загружаем PlayerDataManager для интеграции
local PlayerDataManager = require(script.Parent.Parent.Parent.Shared.PlayerDataManager)

-- Конфигурация квестов
local QUESTS_CONFIG = {
	["Tutorial"] = {
		Id = "tutorial_001",
		Name = "Начало пути",
		Description = "Познакомьтесь с базовыми механиками игры",
		Objectives = {
			{
				Type = "ReachArea",
				TargetArea = "SpawnArea",
				Progress = 0,
				Required = 1,
				Description = "Дойдите до зоны старта"
			},
			{
				Type = "KillNPC",
				TargetNPC = "TrainingDummy",
				Progress = 0,
				Required = 3,
				Description = "Победите 3 тренировочных манекена"
			}
		},
		Reward = {
			Coins = 100,
			Experience = 50,
			Items = { { Id = "StarterSword", Quantity = 1 } }
		},
		AutoAccept = true
	},
	
	["Gatherer"] = {
		Id = "gatherer_001",
		Name = "Сборщик ресурсов",
		Description = "Соберите необходимые ресурсы для развития",
		Objectives = {
			{
				Type = "CollectItem",
				ItemId = "Wood",
				Progress = 0,
				Required = 10,
				Description = "Соберите 10 единиц дерева"
			},
			{
				Type = "CollectItem",
				ItemId = "Stone",
				Progress = 0,
				Required = 5,
				Description = "Соберите 5 единиц камня"
			}
		},
		Reward = {
			Coins = 150,
			Experience = 75,
			Items = { { Id = "Axe", Quantity = 1 } }
		},
		AutoAccept = false
	},
	
	["Hunter"] = {
		Id = "hunter_001",
		Name = "Охотник",
		Description = "Охотьтесь на диких существ",
		Objectives = {
			{
				Type = "KillNPC",
				TargetNPC = "Wolf",
				Progress = 0,
				Required = 5,
				Description = "Победите 5 волков"
			},
			{
				Type = "KillNPC",
				TargetNPC = "Bear",
				Progress = 0,
				Required = 2,
				Description = "Победите 2 медведя"
			}
		},
		Reward = {
			Coins = 200,
			Experience = 100,
			Items = { { Id = "Bow", Quantity = 1 } }
		},
		AutoAccept = false
	}
}

-- Создаем RemoteEvent для связи с клиентом
local QuestEvent = Instance.new("RemoteEvent")
QuestEvent.Name = "QuestEvent"
QuestEvent.Parent = ReplicatedStorage

-- Сервис квестов
local QuestService = {}
QuestService.__index = QuestService

function QuestService.new()
	local self = setmetatable({}, QuestService)
	self.PlayersData = {}
	self.ActiveQuests = {} -- player -> questId
	self.QuestAreas = {} -- areaName -> CFrame
	
	-- Инициализация зон
	self:InitializeQuestAreas()
	
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

function QuestService:InitializeQuestAreas()
	-- Создаем зоны для квестов
	local spawnArea = Instance.new("Part")
	spawnArea.Name = "SpawnArea"
	spawnArea.Size = Vector3.new(20, 5, 20)
	spawnArea.Position = Vector3.new(0, 2.5, 0)
	spawnArea.Anchored = true
	spawnArea.CanCollide = false
	spawnArea.Transparency = 1
	spawnArea.Parent = Workspace
	
	self.QuestAreas["SpawnArea"] = spawnArea
	
	-- Добавляем детектор столкновений
	spawnArea.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			self:OnPlayerEnterArea(player, "SpawnArea")
		end
	end)
end

function QuestService:OnPlayerAdded(player: Player)
	local dataManager = PlayerDataManager:GetPlayerData(player)
	if dataManager then
		-- Инициализация данных для квестов
		if not dataManager.Data.Quests then
			dataManager.Data.Quests = {
				ActiveQuests = {},
				CompletedQuests = {},
				Progress = {}
			}
		end
		self.PlayersData[player] = dataManager
		
		-- Автоматическое принятие tutorial квеста
		if dataManager.Data.Level == 1 then
			self:AcceptQuest(player, "Tutorial")
		end
	end
end

function QuestService:OnPlayerRemoving(player: Player)
	local dataManager = self.PlayersData[player]
	if dataManager then
		dataManager:Save()
		self.PlayersData[player] = nil
		self.ActiveQuests[player] = nil
	end
end

-- Принятие квеста
function QuestService:AcceptQuest(player: Player, questId: string): boolean
	local dataManager = self.PlayersData[player]
	if not dataManager then return false end
	
	local quest = QUESTS_CONFIG[questId]
	if not quest then return false end
	
	-- Проверка, не выполняется ли уже этот квест
	if self.ActiveQuests[player] == questId then return false end
	
	-- Проверка, не выполнен ли уже квест
	if dataManager.Data.Quests.CompletedQuests[questId] then return false end
	
	-- Инициализация прогресса
	if not dataManager.Data.Quests.Progress[questId] then
		dataManager.Data.Quests.Progress[questId] = {}
		for _, objective in ipairs(quest.Objectives) do
			dataManager.Data.Quests.Progress[questId][objective.Type] = {
				Progress = 0,
				Required = objective.Required
			}
		end
	end
	
	-- Добавление в активные квесты
	dataManager.Data.Quests.ActiveQuests[questId] = true
	self.ActiveQuests[player] = questId
	dataManager:Save()
	
	-- Уведомление клиента
	QuestEvent:FireClient(player, "QuestAccepted", {
		QuestId = questId,
		QuestData = quest,
		Progress = dataManager.Data.Quests.Progress[questId]
	})
	
	return true
end

-- Завершение квеста
function QuestService:CompleteQuest(player: Player, questId: string): boolean
	local dataManager = self.PlayersData[player]
	if not dataManager then return false end
	
	local quest = QUESTS_CONFIG[questId]
	if not quest then return false end
	
	-- Проверка выполнения всех целей
	local progress = dataManager.Data.Quests.Progress[questId]
	if not progress then return false end
	
	for _, objective in ipairs(quest.Objectives) do
		local objProgress = progress[objective.Type]
		if not objProgress or objProgress.Progress < objProgress.Required then
			return false
		end
	end
	
	-- Выдача наград
	dataManager:AddCoins(quest.Reward.Coins)
	dataManager:AddExperience(quest.Reward.Experience)
	for _, item in ipairs(quest.Reward.Items) do
		dataManager:AddItem(item.Id, item.Quantity)
	end
	
	-- Обновление статуса
	dataManager.Data.Quests.ActiveQuests[questId] = nil
	dataManager.Data.Quests.CompletedQuests[questId] = true
	dataManager:Save()
	
	self.ActiveQuests[player] = nil
	
	-- Уведомление клиента
	QuestEvent:FireClient(player, "QuestCompleted", {
		QuestId = questId,
		Reward = quest.Reward
	})
	
	return true
end

-- Обновление прогресса квеста
function QuestService:UpdateQuestProgress(player: Player, questId: string, objectiveType: string, amount: number)
	local dataManager = self.PlayersData[player]
	if not dataManager then return end
	
	local progress = dataManager.Data.Quests.Progress[questId]
	if not progress or not progress[objectiveType] then return end
	
	progress[objectiveType].Progress += amount
	
	-- Проверка завершения квеста
	local quest = QUESTS_CONFIG[questId]
	local allCompleted = true
	for _, objective in ipairs(quest.Objectives) do
		local objProgress = progress[objective.Type]
		if objProgress.Progress < objProgress.Required then
			allCompleted = false
			break
		end
	end
	
	if allCompleted then
		self:CompleteQuest(player, questId)
	else
		dataManager:Save()
		QuestEvent:FireClient(player, "QuestProgressUpdated", {
			QuestId = questId,
			Progress = progress
		})
	end
end

-- Получение активных квестов
function QuestService:GetActiveQuests(player: Player): table
	local dataManager = self.PlayersData[player]
	if not dataManager then return {} end
	
	local activeQuests = {}
	for questId, _ in pairs(dataManager.Data.Quests.ActiveQuests) do
		local quest = QUESTS_CONFIG[questId]
		if quest then
			table.insert(activeQuests, {
				Id = quest.Id,
				Name = quest.Name,
				Description = quest.Description,
				Objectives = quest.Objectives,
				Progress = dataManager.Data.Quests.Progress[questId]
			})
		end
	end
	
	return activeQuests
end

-- Обработчик событий от клиента
QuestEvent.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local args = {...}
	
	if action == "AcceptQuest" then
		local questId = args[1]
		local success = self:AcceptQuest(player, questId)
		QuestEvent:FireClient(player, "AcceptResult", { Success = success, QuestId = questId })
		
	elseif action == "GetActiveQuests" then
		local quests = self:GetActiveQuests(player)
		QuestEvent:FireClient(player, "ActiveQuestsResult", quests)
		
	elseif action == "GetAvailableQuests" then
		local dataManager = self.PlayersData[player]
		local availableQuests = {}
		
		for questId, quest in pairs(QUESTS_CONFIG) do
			-- Проверка, не выполнен ли квест
			if not dataManager.Data.Quests.CompletedQuests[questId] then
				-- Проверка, не выполняется ли уже квест
				if not dataManager.Data.Quests.ActiveQuests[questId] then
					table.insert(availableQuests, {
						Id = questId,
						Name = quest.Name,
						Description = quest.Description,
						AutoAccept = quest.AutoAccept
					})
				end
			end
		end
		
		QuestEvent:FireClient(player, "AvailableQuestsResult", availableQuests)
		
	else
		warn("Unknown quest action: " .. action .. " from player: " .. player.Name)
	end
end)

-- Обработчики игровых событий
function QuestService:OnPlayerEnterArea(player: Player, areaName: string)
	local activeQuestId = self.ActiveQuests[player]
	if not activeQuestId then return end
	
	local quest = QUESTS_CONFIG[activeQuestId]
	if not quest then return end
	
	for _, objective in ipairs(quest.Objectives) do
		if objective.Type == "ReachArea" and objective.TargetArea == areaName then
			self:UpdateQuestProgress(player, activeQuestId, "ReachArea", 1)
			break
		end
	end
end

-- Интеграция с системой убийств
function QuestService:OnNPCDied(npcName: string, killer: Player?)
	if killer then
		local activeQuestId = self.ActiveQuests[killer]
		if activeQuestId then
			local quest = QUESTS_CONFIG[activeQuestId]
			if quest then
				for _, objective in ipairs(quest.Objectives) do
					if objective.Type == "KillNPC" and objective.TargetNPC == npcName then
						self:UpdateQuestProgress(killer, activeQuestId, "KillNPC", 1)
						break
					end
				end
			end
		end
	end
end

-- Интеграция с системой сбора ресурсов
function QuestService:OnItemCollected(player: Player, itemId: string, quantity: number)
	local activeQuestId = self.ActiveQuests[player]
	if activeQuestId then
		local quest = QUESTS_CONFIG[activeQuestId]
		if quest then
			for _, objective in ipairs(quest.Objectives) do
				if objective.Type == "CollectItem" and objective.ItemId == itemId then
					self:UpdateQuestProgress(player, activeQuestId, "CollectItem", quantity)
					break
				end
			end
		end
	end
end

-- Автоматическая проверка для тестирования
game:GetService("RunService").Heartbeat:Connect(function()
	-- Можно добавить логику для периодических проверок
end)

print("QuestService loaded successfully")

return QuestService