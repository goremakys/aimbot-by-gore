-- Локальный скрипт для приклеивания курсора к ближайшему игроку при удерживании Shift

-- Убедитесь, что скрипт вставлен в LocalScript, например, в StarterPlayerScripts
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local isShiftPressed = false

-- Функция для нахождения ближайшего игрока к курсору
local function getClosestPlayerToCursor()
    local mouseLocation = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local rootPart = character.HumanoidRootPart

            -- Проецируем позицию HumanoidRootPart игрока на экран
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

    return closestPlayer
end

-- Обновление положения курсора для приклеивания к игроку
local function lockCursorToPlayer()
    local closestPlayer = getClosestPlayerToCursor()
    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
        local screenPoint = Camera:WorldToViewportPoint(targetPosition)

        -- Устанавливаем положение мыши только при значительном отклонении, с порогом
        local mouseLocation = UserInputService:GetMouseLocation()
        local deltaX = screenPoint.X - mouseLocation.X
        local deltaY = screenPoint.Y - mouseLocation.Y

        if math.abs(deltaX) > 5 or math.abs(deltaY) > 5 then -- Увеличенный порог
            mousemoverel(deltaX / 2, deltaY / 2) -- Плавное движение
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
            task.wait() -- Ждем следующий кадр
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isShiftPressed = false
    end
end)
