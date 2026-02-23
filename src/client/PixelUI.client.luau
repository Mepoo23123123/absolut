--!strict

-- PixelUI.client.luau
-- Пиксельный интерфейс в стиле олдскульных RPG

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Конфигурация UI
local UI_CONFIG = {
	Colors = {
		Background = Color3.fromRGB(0, 0, 0),
		Stroke = Color3.fromRGB(20, 20, 20),
		Accent = Color3.fromRGB(255, 255, 255),
		Health = Color3.fromRGB(255, 50, 50),
		Mana = Color3.fromRGB(50, 100, 255),
		SlotBorder = Color3.fromRGB(200, 200, 200),
		SlotInner = Color3.fromRGB(80, 80, 80)
	},
	Transparency = {
		Background = 0.6,
		Stroke = 0.2,
		Accent = 0.15,
		Slot = 0.3
	},
	Sizes = {
		MainFrame = UDim2.new(0, 600, 0, 400),
		SearchBar = UDim2.new(1, 0, 0, 30),
		SlotSize = UDim2.new(0, 64, 0, 64),
		PartyIcon = UDim2.new(0, 40, 0, 40),
		HealthBar = UDim2.new(1, 0, 0, 6),
		ManaBar = UDim2.new(1, 0, 0, 4)
	}
}

-- Создание пиксельного UI
local PixelUI = {}
PixelUI.__index = PixelUI

function PixelUI.new()
	local self = setmetatable({}, PixelUI)
	
	-- Создаем основной ScreenGui
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "PixelUI"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
	
	-- Включаем пиксельный рендеринг для всего UI
	-- self.ScreenGui.ResampleMode = Enum.ResamplerMode.Default
	
	print("PixelUI loaded successfully")
	
	-- Создаем главную рамку
	self:CreateMainFrame()
	
	-- Создаем элементы UI
	self:CreateInventoryFrame()
	self:CreateSearchBar()
	self:CreateToolbar()
	self:CreatePartyMenu()
	
	-- Добавляем эффект появления
	self:ShowAnimation()
	
	return self
end

-- Создание главной рамки
function PixelUI:CreateMainFrame()
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "MainFrame"
	self.MainFrame.Size = UI_CONFIG.Sizes.MainFrame
	self.MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	self.MainFrame.BackgroundColor3 = UI_CONFIG.Colors.Background
	self.MainFrame.BackgroundTransparency = UI_CONFIG.Transparency.Background
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Visible = false
	
	-- Добавляем обводку
	local stroke = Instance.new("UIStroke")
	stroke.Color = UI_CONFIG.Colors.Stroke
	stroke.Thickness = 2
	stroke.Transparency = UI_CONFIG.Transparency.Stroke
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = self.MainFrame
	
	-- Добавляем угловые декорации
	self:CreateCornerDecorations()
	
	self.MainFrame.Parent = self.ScreenGui
end

-- Создание угловых декораций
function PixelUI:CreateCornerDecorations()
	-- Верхний левый угол
	local topLeft = Instance.new("Frame")
	topLeft.Name = "TopLeftDecor"
	topLeft.Size = UDim2.new(0, 16, 0, 16)
	topLeft.Position = UDim2.new(0, -8, 0, -8)
	topLeft.BackgroundColor3 = UI_CONFIG.Colors.Accent
	topLeft.BackgroundTransparency = 0.8
	topLeft.BorderSizePixel = 0
	topLeft.Parent = self.MainFrame
	
	-- Верхний правый угол
	local topRight = Instance.new("Frame")
	topRight.Name = "TopRightDecor"
	topRight.Size = UDim2.new(0, 16, 0, 16)
	topRight.Position = UDim2.new(1, -8, 0, -8)
	topRight.BackgroundColor3 = UI_CONFIG.Colors.Accent
	topRight.BackgroundTransparency = 0.8
	topRight.BorderSizePixel = 0
	topRight.Parent = self.MainFrame
	
	-- Нижний левый угол
	local bottomLeft = Instance.new("Frame")
	bottomLeft.Name = "BottomLeftDecor"
	bottomLeft.Size = UDim2.new(0, 16, 0, 16)
	bottomLeft.Position = UDim2.new(0, -8, 1, -8)
	bottomLeft.BackgroundColor3 = UI_CONFIG.Colors.Accent
	bottomLeft.BackgroundTransparency = 0.8
	bottomLeft.BorderSizePixel = 0
	bottomLeft.Parent = self.MainFrame
	
	-- Нижний правый угол
	local bottomRight = Instance.new("Frame")
	bottomRight.Name = "BottomRightDecor"
	bottomRight.Size = UDim2.new(0, 16, 0, 16)
	bottomRight.Position = UDim2.new(1, -8, 1, -8)
	bottomRight.BackgroundColor3 = UI_CONFIG.Colors.Accent
	bottomRight.BackgroundTransparency = 0.8
	bottomRight.BorderSizePixel = 0
	bottomRight.Parent = self.MainFrame
end

-- Создание главного окна инвентаря
function PixelUI:CreateInventoryFrame()
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(1, -20, 1, -20)
	inventoryFrame.Position = UDim2.new(0, 10, 0, 10)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	inventoryFrame.BackgroundTransparency = 0.2
	inventoryFrame.BorderSizePixel = 0
	
	-- Заголовок
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "INVENTORY"
	title.Font = Enum.Font.Code
	title.TextSize = 24
	title.TextColor3 = UI_CONFIG.Colors.Accent
	title.TextTransparency = 0.3
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Parent = inventoryFrame
	
	-- Добавляем обводку к заголовку
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = UI_CONFIG.Colors.Stroke
	titleStroke.Thickness = 1
	titleStroke.Transparency = 0.5
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	titleStroke.Parent = title
	
	inventoryFrame.Parent = self.MainFrame
end

-- Создание строки поиска
function PixelUI:CreateSearchBar()
	local searchBar = Instance.new("Frame")
	searchBar.Name = "SearchBar"
	searchBar.Size = UI_CONFIG.Sizes.SearchBar
	searchBar.Position = UDim2.new(0, 10, 0, 60)
	searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	searchBar.BackgroundTransparency = 0.3
	searchBar.BorderSizePixel = 0
	
	-- Внутренний фон с градиентом
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 40, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60))
	})
	gradient.Rotation = 90
	gradient.Parent = searchBar
	
	-- Текстовое поле
	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Text = "Search..."
	searchBox.Font = Enum.Font.Code
	searchBox.TextSize = 14
	searchBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	searchBox.Size = UDim2.new(0.8, 0, 1, 0)
	searchBox.Position = UDim2.new(0.1, 0, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.TextYAlignment = Enum.TextYAlignment.Center
	searchBox.Parent = searchBar
	
	-- Обводка для текстового поля
	local searchStroke = Instance.new("UIStroke")
	searchStroke.Color = UI_CONFIG.Colors.Stroke
	searchStroke.Thickness = 1
	searchStroke.Transparency = 0.5
	searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	searchStroke.Parent = searchBox
	
	searchBar.Parent = self.MainFrame
end

-- Создание хотбара
function PixelUI:CreateToolbar()
	local toolbar = Instance.new("Frame")
	toolbar.Name = "Toolbar"
	toolbar.Size = UDim2.new(0, 600, 0, 80)
	toolbar.Position = UDim2.new(0, 0, 1, -90)
	toolbar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	toolbar.BackgroundTransparency = 0.4
	toolbar.BorderSizePixel = 0
	
	-- Сетка для слотов
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UI_CONFIG.Sizes.SlotSize
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.Parent = toolbar
	
	-- Создаем 9 слотов
	for i = 1, 9 do
		local slot = Instance.new("TextButton")
		slot.Name = "Slot_" .. i
		slot.Size = UI_CONFIG.Sizes.SlotSize
		slot.BackgroundColor3 = UI_CONFIG.Colors.SlotInner
		slot.BackgroundTransparency = UI_CONFIG.Transparency.Slot
		slot.BorderSizePixel = 0
		slot.Text = ""
		
		-- Обводка слота (серая)
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Name = "SlotStroke"
		slotStroke.Color = UI_CONFIG.Colors.SlotBorder
		slotStroke.Thickness = 2
		slotStroke.Transparency = 0.3
		slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		slotStroke.Parent = slot
		
		-- Градиент внутри слота
		local slotGradient = Instance.new("UIGradient")
		slotGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60))
		})
		slotGradient.Rotation = 90
		slotGradient.Parent = slot
		
		-- Индекс клавиши
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Text = tostring(i)
		keyLabel.Font = Enum.Font.Code
		keyLabel.TextSize = 12
		keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keyLabel.TextTransparency = 0.3
		keyLabel.Size = UDim2.new(0, 16, 0, 16)
		keyLabel.Position = UDim2.new(0, 2, 0, 2)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Parent = slot
		
		-- Иконка предмета
		local itemIcon = Instance.new("ImageLabel")
		itemIcon.Name = "ItemIcon"
		itemIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
		itemIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
		itemIcon.BackgroundTransparency = 1
		itemIcon.ImageTransparency = 1
		itemIcon.ScaleType = Enum.ScaleType.Fit
		itemIcon.Parent = slot
		
		-- Эффект наведения
		slot.MouseEnter:Connect(function()
			TweenService:Create(slot, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
		end)
		
		slot.MouseLeave:Connect(function()
			TweenService:Create(slot, TweenInfo.new(0.2), { BackgroundTransparency = UI_CONFIG.Transparency.Slot }):Play()
		end)
		
		-- Обработка клика по слоту
		slot.MouseButton1Click:Connect(function()
			self:HandleSlotClick(slot, itemIcon)
		end)
		
		slot.Parent = toolbar
	end
	
	toolbar.Parent = self.MainFrame
end

-- Обработка клика по слоту
function PixelUI:HandleSlotClick(slot, itemIcon)
	-- Снимаем выделение со всех слотов
	self:ClearAllSelections()
	
	-- Выделяем текущий слот белой обводкой
	local slotStroke = slot:FindFirstChild("SlotStroke")
	if slotStroke then
		TweenService:Create(slotStroke, TweenInfo.new(0.2), { 
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.1
		}):Play()
	end
	
	-- Показываем название предмета
	if itemIcon and itemIcon.ImageTransparency < 1 then
		self:ShowItemName(itemIcon)
	end
end

-- Снимаем выделение со всех слотов
function PixelUI:ClearAllSelections()
	local toolbar = self.MainFrame:FindFirstChild("Toolbar")
	if toolbar then
		for _, child in pairs(toolbar:GetChildren()) do
			if child:IsA("TextButton") and child.Name:match("Slot_") then
				local slotStroke = child:FindFirstChild("SlotStroke")
				if slotStroke then
					TweenService:Create(slotStroke, TweenInfo.new(0.2), { 
						Color = UI_CONFIG.Colors.SlotBorder,
						Transparency = 0.3
					}):Play()
				end
			end
		end
	end
end

-- Показываем название предмета над персонажем
function PixelUI:ShowItemName(itemIcon)
	-- Удаляем предыдущее название, если есть
	if self.currentNameLabel then
		self.currentNameLabel:Destroy()
		self.currentNameLabel = nil
	end
	
	-- Создаем новое название
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemNameLabel"
	nameLabel.Text = "Sword" -- Временное название, можно сделать динамическим
	nameLabel.Font = Enum.Font.Code
	nameLabel.TextSize = 24
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextTransparency = 0.2
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(0, 200, 0, 40)
	nameLabel.Position = UDim2.new(0.5, -100, 0.3, -20)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.Parent = self.ScreenGui
	
	-- Добавляем обводку к названию
	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Transparency = 0.5
	nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	nameStroke.Parent = nameLabel
	
	self.currentNameLabel = nameLabel
	
	-- Удаляем название через 2 секунды
	task.delay(2, function()
		if nameLabel and nameLabel.Parent then
			TweenService:Create(nameLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			task.delay(0.5, function()
				if nameLabel and nameLabel.Parent then
					nameLabel:Destroy()
				end
				self.currentNameLabel = nil
			end)
		end
	end)
end

-- Заполняем слоты предметами из PlayerItems
function PixelUI:UpdateInventory(playerItems)
	local toolbar = self.MainFrame:FindFirstChild("Toolbar")
	if not toolbar then return end
	
	local slotIndex = 1
	for itemName, itemData in pairs(playerItems) do
		if slotIndex <= 9 then
			local slot = toolbar:FindFirstChild("Slot_" .. slotIndex)
			if slot then
				local itemIcon = slot:FindFirstChild("ItemIcon")
				if itemIcon then
					-- Устанавливаем иконку предмета
					itemIcon.Image = itemData.Icon or ""
					itemIcon.ImageTransparency = 0
					
					-- Добавляем подсказку с названием
					itemIcon.MouseEnter:Connect(function()
						self:ShowItemTooltip(slot, itemName)
					end)
					
					itemIcon.MouseLeave:Connect(function()
						self:HideItemTooltip()
					end)
				end
			end
			slotIndex = slotIndex + 1
		end
	end
end

-- Показываем подсказку с названием предмета
function PixelUI:ShowItemTooltip(slot, itemName)
	if self.tooltipLabel then
		self:HideItemTooltip()
	end
	
	local tooltip = Instance.new("TextLabel")
	tooltip.Name = "Tooltip"
	tooltip.Text = itemName
	tooltip.Font = Enum.Font.Code
	tooltip.TextSize = 14
	tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
	tooltip.TextTransparency = 0.2
	tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	tooltip.BackgroundTransparency = 0.6
	tooltip.BorderSizePixel = 0
	tooltip.Size = UDim2.new(0, 120, 0, 20)
	tooltip.Position = UDim2.new(1, 10, 0.5, -10)
	tooltip.AnchorPoint = Vector2.new(0, 0.5)
	tooltip.Parent = slot
	
	-- Обводка для подсказки
	local tooltipStroke = Instance.new("UIStroke")
	tooltipStroke.Color = Color3.fromRGB(255, 255, 255)
	tooltipStroke.Thickness = 1
	tooltipStroke.Transparency = 0.5
	tooltipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tooltipStroke.Parent = tooltip
	
	self.tooltipLabel = tooltip
end

-- Скрываем подсказку
function PixelUI:HideItemTooltip()
	if self.tooltipLabel then
		self.tooltipLabel:Destroy()
		self.tooltipLabel = nil
	end
end

-- Создание меню группы
function PixelUI:CreatePartyMenu()
	local partyMenu = Instance.new("Frame")
	partyMenu.Name = "PartyMenu"
	partyMenu.Size = UDim2.new(0, 200, 1, -20)
	partyMenu.Position = UDim2.new(1, -210, 0, 10)
	partyMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	partyMenu.BackgroundTransparency = 0.3
	partyMenu.BorderSizePixel = 0
	
	-- Заголовок
	local partyTitle = Instance.new("TextLabel")
	partyTitle.Name = "PartyTitle"
	partyTitle.Text = "PARTY"
	partyTitle.Font = Enum.Font.Code
	partyTitle.TextSize = 16
	partyTitle.TextColor3 = UI_CONFIG.Colors.Accent
	partyTitle.TextTransparency = 0.3
	partyTitle.Size = UDim2.new(1, 0, 0, 30)
	partyTitle.Position = UDim2.new(0, 0, 0, 5)
	partyTitle.BackgroundTransparency = 1
	partyTitle.Parent = partyMenu
	
	-- Список игроков
	local partyList = Instance.new("Frame")
	partyList.Name = "PartyList"
	partyList.Size = UDim2.new(1, 0, 1, -40)
	partyList.Position = UDim2.new(0, 0, 0, 40)
	partyList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	partyList.BackgroundTransparency = 0.4
	partyList.BorderSizePixel = 0
	
	-- Layout для списка
	local partyLayout = Instance.new("UIListLayout")
	partyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	partyLayout.Padding = UDim.new(0, 10)
	partyLayout.Parent = partyList
	
	-- Пример игрока
	self:CreatePartyMember(partyList, "Player1", 80, 60)
	self:CreatePartyMember(partyList, "Player2", 100, 45)
	self:CreatePartyMember(partyList, "Player3", 50, 80)
	
	partyList.Parent = partyMenu
	partyMenu.Parent = self.MainFrame
end

-- Создание элемента игрока в группе
function PixelUI:CreatePartyMember(parent: Frame, name: string, hp: number, mana: number)
	local memberFrame = Instance.new("Frame")
	memberFrame.Name = "Member_" .. name
	memberFrame.Size = UDim2.new(1, 0, 0, 60)
	memberFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	memberFrame.BackgroundTransparency = 0.3
	memberFrame.BorderSizePixel = 0
	
	-- Иконка игрока (ромб)
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.Size = UI_CONFIG.Sizes.PartyIcon
	icon.Position = UDim2.new(0, 10, 0, 10)
	icon.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	icon.BackgroundTransparency = 0.2
	icon.BorderSizePixel = 0
	
	-- Ромбовидная форма через UICorner
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 0)
	iconCorner.Parent = icon
	
	memberFrame.Parent = parent
end

-- Эффект появления
function PixelUI:ShowAnimation()
	self.MainFrame.Visible = true
	
	-- Анимация масштабирования
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(self.MainFrame, tweenInfo, { 
		Position = UDim2.new(0.5, -300, 0.5, -200),
		BackgroundTransparency = UI_CONFIG.Transparency.Background
	})
	tween:Play()
end

-- Привязка к клавише для открытия/закрытия UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then 
		return 
	end
	
	if input.KeyCode == Enum.KeyCode.F then
		-- Проверяем, не существует ли уже UI
		local existingUI = PlayerGui:FindFirstChild("PixelUI")
		
		if not existingUI then
			local pixelUI = PixelUI.new()
		else
			-- Если UI существует, удаляем его
			existingUI:Destroy()
		end
	end
end)

-- Обработчик для обновления инвентаря
local UpdateInventoryEvent = ReplicatedStorage:WaitForChild("UpdateInventory")
UpdateInventoryEvent.OnClientEvent:Connect(function(playerItems)
	local existingUI = PlayerGui:FindFirstChild("PixelUI")
	if existingUI then
		local pixelUI = existingUI:FindFirstChild("MainFrame")
		if pixelUI then
			-- Вызываем метод UpdateInventory у экземпляра PixelUI
			-- Для этого нужно сохранить ссылку на экземпляр
			-- Временное решение: пересоздаем UI с новыми данными
			existingUI:Destroy()
			local newPixelUI = PixelUI.new()
			newPixelUI:UpdateInventory(playerItems)
		end
	end
end)

print("PixelUI loaded successfully")