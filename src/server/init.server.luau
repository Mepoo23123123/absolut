--!strict

-- init.server.luau
-- Главный серверный скрипт

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Загружаем PlayerDataManager
local PlayerDataManager = require(ReplicatedStorage.Shared.PlayerDataManager)

-- Создаем RemoteEvent для связи с клиентом
local PlayerDataEvent = Instance.new("RemoteEvent")
PlayerDataEvent.Name = "PlayerDataEvent"
PlayerDataEvent.Parent = ReplicatedStorage

-- Обработчик запросов от клиента
PlayerDataEvent.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local dataManager = PlayerDataManager:GetPlayerData(player)
	if not dataManager then
		warn("No data manager found for player: " .. player.Name)
		-- Создаем временную таблицу для игрока
		dataManager = {
			Data = {
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
		}
	end
	
	local args = {...}
	
	-- Обработка различных действий
	if action == "AddExperience" then
		local amount = args[1]
		if amount then
			dataManager:AddExperience(amount)
		end
		
	elseif action == "AddCoins" then
		local amount = args[1]
		if amount then
			dataManager:AddCoins(amount)
		end
		
	elseif action == "AddItem" then
		local itemId = args[1]
		local quantity = args[2]
		if itemId and quantity then
			dataManager:AddItem(itemId, quantity)
		end
		
	elseif action == "RemoveItem" then
		local itemId = args[1]
		local quantity = args[2]
		if itemId and quantity then
			dataManager:RemoveItem(itemId, quantity)
		end
		
	elseif action == "UpdateStat" then
		local statName = args[1]
		local value = args[2]
		if statName and value then
			dataManager.Data.Stats[statName] = value
			dataManager:Save()
		end
		
	elseif action == "GetAllData" then
		-- Отправляем все данные клиенту
		PlayerDataEvent:FireClient(player, dataManager.Data)
		
	else
		warn("Unknown action: " .. action .. " from player: " .. player.Name)
	end
end)

-- Создаем RemoteEvent для обновления инвентаря
local UpdateInventoryEvent = Instance.new("RemoteEvent")
UpdateInventoryEvent.Name = "UpdateInventory"
UpdateInventoryEvent.Parent = ReplicatedStorage

-- Обработка события PlayerAdded
Players.PlayerAdded:Connect(function(player)
	-- Небольшая задержка для загрузки клиента
	task.wait(1)
	
	local dataManager = PlayerDataManager:GetPlayerData(player)
	if dataManager then
		-- Отправляем данные клиенту
		UpdateInventoryEvent:FireClient(player, dataManager.Data.Inventory)
	else
		-- Отправляем пустой инвентарь
		UpdateInventoryEvent:FireClient(player, {})
	end
end)

-- Пример: Добавление опыта при убийстве NPC
game:GetService("Workspace").ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:FindFirstChild("Humanoid") then
		child.Humanoid.Died:Connect(function()
			for _, player in Players:GetPlayers() do
				local character = player.Character or player.CharacterAdded:Wait()
				if character then
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						local dataManager = PlayerDataManager:GetPlayerData(player)
						if dataManager then
							dataManager:AddExperience(10)
						end
					end
				end
			end
		end)
	end
end)

print("Server loaded successfully")