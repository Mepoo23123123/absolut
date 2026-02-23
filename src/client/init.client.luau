--!strict

-- init.client.luau
-- Простой клиентский скрипт для UI инвентаря

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Создаем простой UI инвентаря
local function CreateInventoryUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	local frame = Instance.new("Frame")
	frame.Name = "InventoryFrame"
	frame.Size = UDim2.new(0, 400, 0, 300)
	frame.Position = UDim2.new(0.5, -200, 0.5, -150)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "INVENTORY"
	title.Font = Enum.Font.Code
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Parent = frame
	
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.Code
	closeButton.TextSize = 18
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Parent = frame
	
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)
	
	frame.Parent = screenGui
	
	return screenGui
end

-- Обработчик клавиши для открытия/закрытия UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.I then
		local existingUI = PlayerGui:FindFirstChild("InventoryUI")
		if existingUI then
			existingUI:Destroy()
		else
			CreateInventoryUI()
		end
	end
end)

print("Simple Inventory UI loaded")