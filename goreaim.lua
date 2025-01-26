-- Локальный скрипт для приклеивания курсора к ближайшему игроку при удерживании Shift

-- Убедитесь, что скрипт вставлен в LocalScript, например, в StarterPlayerScripts
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local isShiftPressed = false
local maxDistance = 400 -- Максимальная дистанция работы скрипта
local lastAttacker = nil -- Последний игрок, который бил LocalPlayer

-- Отслеживание урона по LocalPlayer
LocalPlayer.Character.Humanoid.TakingDamage:Connect(function(damage, attacker)
    if attacker and Players:GetPlayerFromCharacter(attacker) then
        lastAttacker = Players:GetPlayerFromCharacter(attacker)
    end
end)

-- Функция для вычисления приоритетного игрока
local function calculatePriority(player, distanceToCursor, distanceToPlayer)
    local priority = 0

    -- Приоритет для последнего атакующего (высший приоритет)
    if player == lastAttacker then
        priority = priority + 150
    end

    -- Приоритет для меньшего здоровья
    local health = player.Character.Humanoid.Health
    local maxHealth = player.Character.Humanoid.MaxHealth
    priority = priority + math.max(0, 100 * (1 - health / maxHealth))

    -- Приоритет для близкого физического расстояния
    priority = priority + math.max(0, 50 - distanceToPlayer)

    -- Приоритет для близкого расстояния к курсору (наименьший приоритет)
    priority = priority + math.max(0, 25 - distanceToCursor / 2)

    return priority
end

-- Функция для нахождения игрока с наивысшим приоритетом
local function getClosestPlayerToCursor()
    local mouseLocation = UserInputService:GetMouseLocation()
    local bestPlayer = nil
    local highestPriority = -math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local character = player.Character
            local rootPart = character.HumanoidRootPart

            -- Проверяем дистанцию до игрока
            local distanceToPlayer = (rootPart.Position - Camera.CFrame.Position).Magnitude
            if distanceToPlayer > maxDistance then
                continue
            end

            -- Проецируем позицию HumanoidRootPart игрока на экран
            local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

            if onScreen then
                local distanceToCursor = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude

                -- Вычисляем приоритет игрока
                local priority = calculatePriority(player, distanceToCursor, distanceToPlayer)
                if priority > highestPriority then
                    highestPriority = priority
                    bestPlayer = player
                end
            end
        end
    end

    return bestPlayer
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
