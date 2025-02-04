-- Локальный скрипт для приклеивания курсора и ESP на всех игроков

-- Убедитесь, что скрипт вставлен в LocalScript, например, в StarterPlayerScripts
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local API_URL = "http://swapper.infy.uk/getID.php?robloxID="

-- Функция проверки вайт-листа
local function isPlayerWhitelisted(player)
    local success, response = pcall(function()
        return HttpService:GetAsync(API_URL .. player.UserId)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        return data.allowed == true
    end
    return false
end

-- Кик игрока, если его нет в вайт-листе
if not isPlayerWhitelisted(LocalPlayer) then
    LocalPlayer:Kick("Вы не в вайт-листе!")
end

-- Создание GUI для отображения текста
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimAssistGUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 200, 0, 30)
label.Position = UDim2.new(0.5, -100, 0, -60) -- Максимально сверху, без отступа
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 0, 0)
label.TextStrokeTransparency = 0.5
label.Font = Enum.Font.SourceSansBold
label.TextSize = 20
label.Text = "Gore Aim | ID: " .. LocalPlayer.UserId
label.Parent = screenGui

local isShiftPressed = false
local maxDistance = 500 -- Максимальная дистанция работы в единицах
local levelTolerance = 1 -- Допустимое отклонение уровня

-- Функция для определения уровня игрока
local function getPlayerLevel(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Level") then
        return leaderstats.Level.Value
    end
    return 0 -- Если уровень не найден, считать его 0
end

-- Функция для приклеивания курсора к ближайшему игроку
local function lockCursorToPlayer()
    local mouseLocation = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local rootPart = character.HumanoidRootPart

            -- Проверка уровня игрока
            local playerLevel = getPlayerLevel(player)
            local localPlayerLevel = getPlayerLevel(LocalPlayer)

            -- Вычисление расстояния от игрока до цели
            local distanceToPlayer = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distanceToPlayer > maxDistance then
                continue
            end

            local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

            if onScreen then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude

                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    if closestPlayer and closestPlayer.Character then
        local targetPosition

        -- Если уровень игрока ниже или равен уровню LocalPlayer с учетом допустимого отклонения, наводиться на нижнюю часть модели
        if getPlayerLevel(closestPlayer) <= getPlayerLevel(LocalPlayer) + levelTolerance then
            local lowerPart = closestPlayer.Character:FindFirstChild("LowerTorso") or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if lowerPart then
                targetPosition = lowerPart.Position - Vector3.new(0, 2, 0) -- Смещение еще ниже на 2 единицы
            end
        else
            targetPosition = closestPlayer.Character.HumanoidRootPart.Position
        end

        if targetPosition then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPosition)

            if onScreen then
                local deltaX = screenPoint.X - mouseLocation.X
                local deltaY = screenPoint.Y - mouseLocation.Y

                -- Увеличить скорость движения курсора, сохранив плавность
                mousemoverel(deltaX * 0.5, deltaY * 0.5)
            end
        end
    end
end

-- Обработка нажатия клавиш
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        isShiftPressed = true
        while isShiftPressed do
            lockCursorToPlayer()
            task.wait(0.01) -- Уменьшить задержку для повышения скорости
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isShiftPressed = false
    end
end)
