--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.CharacterAdded:Wait() or player.Character
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Global variables
local goalHologram = nil

-- Enhanced configuration with advanced parkour tricks
local CONFIG = {
    FOLLOW_DISTANCE = 5,
    RECALCULATION_INTERVAL = 0.5,
    STUCK_TIME_THRESHOLD = 3,
    PARKOUR_SCAN_HEIGHT = 500,
    PREDICTION_TIME = 0.8,
    
    PRIMARY_COLOR = Color3.fromRGB(0, 50, 150),
    SECONDARY_COLOR = Color3.fromRGB(20, 20, 20),
    ACCENT_COLOR = Color3.fromRGB(100, 150, 255),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    FONT = Enum.Font.RobotoMono,
    
    PATH_COLORS = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 100, 255),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(150, 0, 255),
    },
    
    MEMORY_RETENTION_TIME = 300,
    MAX_FAILED_ATTEMPTS = 3,
    OBSTACLE_SCAN_DISTANCE = 15,
    PARKOUR_CHECKPOINT_DISTANCE = 20,
    
    MOBILE_SCALE = 1.5,
    TOUCH_TARGET_SIZE = 50,
    
    MAX_PATH_CACHE_SIZE = 50,
    MEMORY_CLEANUP_INTERVAL = 60,
    PERFORMANCE_MONITOR_INTERVAL = 10,
    
    MAX_DELTA_TIME = 0.1,
    SMOOTH_FACTOR = 0.2,
    
    -- Advanced Parkour Settings
    LADDER_FLICK_JUMP_POWER = 1.8,
    WALLHOP_JUMP_POWER = 1.5,
    WRAP_AROUND_JUMP_POWER = 1.6,
    TRICK_COOLDOWN = 1.0,
    WALL_DETECTION_DISTANCE = 8,
    LADDER_DETECTION_DISTANCE = 12,
    TRICK_AGGRESSION = 0.7, -- 0 to 1, higher = more likely to use tricks
}

-- Device detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isTablet = UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and GuiService:GetScreenResolution().Y < 1000

-- UI State Management
local UIState = {
    isInitialized = false,
    isVisible = true,
    isResponsive = true,
    lastRefreshTime = 0,
    refreshInterval = 5,
    elements = {},
}

-- Performance monitoring
local performanceMonitor = {
    frameCount = 0,
    lastFrameTime = tick(),
    averageFrameTime = 0,
    memoryUsage = 0,
    lastMemoryCheck = tick(),
}

-- Enhanced AI State with advanced parkour
local aiState = {
    isRunning = false,
    currentCommand = "Idle",
    targetPlayer = nil,
    goalPosition = nil,
    currentPath = {},
    pathPreviewModels = {},
    trickPreviewModels = {},
    lastWaypointIndex = 0,
    stuckTimer = 0,
    lastPosition = humanoidRootPart.Position,
    pathCache = {},
    lastPathCalculation = 0,
    
    pathMemory = {
        successfulPaths = {},
        failedWaypoints = {},
        efficientWaypoints = {},
        compressedPaths = {},
    },
    
    currentManeuver = "None",
    maneuverData = {},
    maneuverCooldowns = {},
    
    predictedPositions = {},
    
    state = "idle",
    stateHistory = {},
    
    -- Advanced Parkour State
    lastTrickTime = 0,
    isPerformingTrick = false,
    currentTrick = "None",
    trickProgress = 0,
    wallDetectionData = {
        leftWall = nil,
        rightWall = nil,
        frontWall = nil,
        ladderNearby = nil
    },
    
    -- Trick statistics
    trickUsage = {
        ladderFlick = 0,
        wallHop = 0,
        wrapAround = 0
    }
}

-- Fixed ErrorHandler to avoid nil indexing
local ErrorHandler = {
    maxLogEntries = 100,
    
    log = function(level: string, message: string, ...: any)
        local formattedMessage = string.format(message, ...)
        local timestamp = os.date("%H:%M:%S", tick())
        
        print(string.format("[%s][%s] %s", timestamp, level, formattedMessage))
        
        if level == "ERROR" then
            ErrorHandler.attemptRecovery()
        end
    end,
    
    attemptRecovery = function()
        ErrorHandler.log("INFO", "Attempting error recovery")
        
        if aiState and aiState.isRunning then
            aiState.isRunning = false
            task.wait(0.5)
            aiState.isRunning = true
        end
        
        if not UIState.isResponsive then
            UIState.lastRefreshTime = 0
        end
    end,
}

-- Delta time management
local DeltaTimeManager = {
    lastTime = tick(),
    
    getDelta = function(): number
        local currentTime = tick()
        local delta = currentTime - DeltaTimeManager.lastTime
        DeltaTimeManager.lastTime = currentTime
        return math.min(delta, CONFIG.MAX_DELTA_TIME)
    end,
}

-- Advanced Parkour Trick System
local TrickSystem = {
    canPerformTrick = function(): boolean
        return aiState and tick() - (aiState.lastTrickTime or 0) > CONFIG.TRICK_COOLDOWN and not aiState.isPerformingTrick
    end,
    
    detectWalls = function()
        if not humanoidRootPart then return end
        
        local origin = humanoidRootPart.Position
        local lookVector = humanoidRootPart.CFrame.LookVector
        local rightVector = humanoidRootPart.CFrame.RightVector
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        -- Front wall detection
        local frontResult = Workspace:Raycast(origin, lookVector * CONFIG.WALL_DETECTION_DISTANCE, raycastParams)
        aiState.wallDetectionData.frontWall = frontResult
        
        -- Left wall detection
        local leftResult = Workspace:Raycast(origin, -rightVector * CONFIG.WALL_DETECTION_DISTANCE, raycastParams)
        aiState.wallDetectionData.leftWall = leftResult
        
        -- Right wall detection
        local rightResult = Workspace:Raycast(origin, rightVector * CONFIG.WALL_DETECTION_DISTANCE, raycastParams)
        aiState.wallDetectionData.rightWall = rightResult
        
        -- Ladder/Truss detection
        local ladderParts = {}
        for _, part in ipairs(Workspace:GetPartsInRegion3(
            Region3.new(
                origin - Vector3.new(CONFIG.LADDER_DETECTION_DISTANCE, CONFIG.LADDER_DETECTION_DISTANCE, CONFIG.LADDER_DETECTION_DISTANCE),
                origin + Vector3.new(CONFIG.LADDER_DETECTION_DISTANCE, CONFIG.LADDER_DETECTION_DISTANCE, CONFIG.LADDER_DETECTION_DISTANCE)
            )
        )) do
            if part.Name:lower():find("ladder") or part.Name:lower():find("truss") or part:IsA("TrussPart") then
                table.insert(ladderParts, part)
            end
        end
        aiState.wallDetectionData.ladderNearby = #ladderParts > 0
    end,
    
    -- Ladder Flick: Quick jump from ladder/truss with momentum
    executeLadderFlick = function(direction: Vector3)
        if not TrickSystem.canPerformTrick() or not humanoid then return false end
        
        aiState.isPerformingTrick = true
        aiState.currentTrick = "LadderFlick"
        aiState.lastTrickTime = tick()
        aiState.trickUsage.ladderFlick = aiState.trickUsage.ladderFlick + 1
        
        updateStatus("Trick", "Executing Ladder Flick!")
        
        -- Enhanced jump from ladder
        humanoid.Jump = true
        local originalJumpPower = humanoid.JumpPower
        humanoid.JumpPower = originalJumpPower * CONFIG.LADDER_FLICK_JUMP_POWER
        
        -- Add forward momentum
        local flickDirection = (direction + Vector3.new(0, 0.3, 0)).Unit
        humanoid:Move(flickDirection * 2.0)
        
        -- Create visual effect
        TrickSystem.createTrickPreview("LadderFlick", humanoidRootPart.Position, flickDirection)
        
        task.wait(0.3)
        
        -- Reset jump power
        humanoid.JumpPower = originalJumpPower
        aiState.isPerformingTrick = false
        aiState.currentTrick = "None"
        
        return true
    end,
    
    -- Wall Hop: Rapid hopping between two walls/surfaces
    executeWallHop = function()
        if not TrickSystem.canPerformTrick() or not humanoid then return false end
        
        aiState.isPerformingTrick = true
        aiState.currentTrick = "WallHop"
        aiState.lastTrickTime = tick()
        aiState.trickUsage.wallHop = aiState.trickUsage.wallHop + 1
        
        updateStatus("Trick", "Executing Wall Hop!")
        
        local origin = humanoidRootPart.Position
        local rightVector = humanoidRootPart.CFrame.RightVector
        
        -- Determine which walls are available
        local hasLeftWall = aiState.wallDetectionData.leftWall ~= nil
        local hasRightWall = aiState.wallDetectionData.rightWall ~= nil
        
        if hasLeftWall and hasRightWall then
            local originalJumpPower = humanoid.JumpPower
            humanoid.JumpPower = originalJumpPower * CONFIG.WALLHOP_JUMP_POWER
            
            -- Alternate between walls for rapid hopping
            for i = 1, 3 do
                if i % 2 == 1 then
                    -- Hop to right
                    humanoid.Jump = true
                    humanoid:Move(rightVector * 1.5)
                    TrickSystem.createTrickPreview("WallHop", origin, rightVector)
                else
                    -- Hop to left
                    humanoid.Jump = true
                    humanoid:Move(-rightVector * 1.5)
                    TrickSystem.createTrickPreview("WallHop", origin, -rightVector)
                end
                task.wait(0.2)
            end
            
            -- Reset jump power
            humanoid.JumpPower = originalJumpPower
        end
        
        aiState.isPerformingTrick = false
        aiState.currentTrick = "None"
        return true
    end,
    
    -- Wrap Around: Circular jump around wall/pillar
    executeWrapAround = function(direction: Vector3)
        if not TrickSystem.canPerformTrick() or not humanoid then return false end
        
        aiState.isPerformingTrick = true
        aiState.currentTrick = "WrapAround"
        aiState.lastTrickTime = tick()
        aiState.trickUsage.wrapAround = aiState.trickUsage.wrapAround + 1
        
        updateStatus("Trick", "Executing Wrap Around!")
        
        local origin = humanoidRootPart.Position
        local rightVector = humanoidRootPart.CFrame.RightVector
        
        -- Determine wrap direction based on available space
        local leftSpace = TrickSystem.checkClearance(-rightVector)
        local rightSpace = TrickSystem.checkClearance(rightVector)
        
        local wrapDirection = rightSpace > leftSpace and rightVector or -rightVector
        
        -- Execute circular motion
        humanoid.Jump = true
        local originalJumpPower = humanoid.JumpPower
        humanoid.JumpPower = originalJumpPower * CONFIG.WRAP_AROUND_JUMP_POWER
        
        -- Combine forward and sideways motion for circular path
        local wrapVector = (direction * 0.7 + wrapDirection * 0.8).Unit
        humanoid:Move(wrapVector * 1.8)
        
        -- Create visual effect showing circular path
        TrickSystem.createTrickPreview("WrapAround", origin, wrapVector)
        
        task.wait(0.4)
        
        -- Reset jump power
        humanoid.JumpPower = originalJumpPower
        aiState.isPerformingTrick = false
        aiState.currentTrick = "None"
        
        return true
    end,
    
    checkClearance = function(direction: Vector3): number
        if not humanoidRootPart then return 10 end
        
        local origin = humanoidRootPart.Position
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = Workspace:Raycast(origin, direction * 10, raycastParams)
        if result then
            return (result.Position - origin).Magnitude
        end
        return 10
    end,
    
    createTrickPreview = function(trickType: string, position: Vector3, direction: Vector3)
        -- Clear previous trick previews
        for _, model in ipairs(aiState.trickPreviewModels) do
            if model and model.Parent then
                model:Destroy()
            end
        end
        aiState.trickPreviewModels = {}
        
        local previewModel = Instance.new("Model")
        previewModel.Name = trickType .. "Preview"
        previewModel.Parent = Workspace
        
        local color = Color3.new(1, 0.5, 0) -- Orange for tricks
        
        if trickType == "LadderFlick" then
            -- Create momentum lines
            for i = 1, 5 do
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.BrickColor = BrickColor.new(color)
                part.Transparency = 0.3
                part.Size = Vector3.new(0.2, 0.2, 2)
                part.CFrame = CFrame.new(position + direction * i * 3) * CFrame.Angles(0, math.rad(i * 30), 0)
                part.Parent = previewModel
            end
            
        elseif trickType == "WallHop" then
            -- Create alternating wall markers
            local rightVector = humanoidRootPart.CFrame.RightVector
            for i = 1, 3 do
                local side = i % 2 == 1 and rightVector or -rightVector
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.BrickColor = BrickColor.new(color)
                part.Transparency = 0.4
                part.Size = Vector3.new(3, 3, 0.1)
                part.CFrame = CFrame.new(position + side * 4 + Vector3.new(0, 2, 0), position + side * 4)
                part.Parent = previewModel
            end
            
        elseif trickType == "WrapAround" then
            -- Create circular path
            local center = position + direction * 3
            for angle = 0, 360, 30 do
                local rad = math.rad(angle)
                local x = math.cos(rad) * 3
                local z = math.sin(rad) * 3
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.BrickColor = BrickColor.new(color)
                part.Transparency = 0.5
                part.Size = Vector3.new(0.3, 0.3, 0.3)
                part.CFrame = CFrame.new(center + Vector3.new(x, 2, z))
                part.Parent = previewModel
            end
        end
        
        table.insert(aiState.trickPreviewModels, previewModel)
        
        -- Auto-cleanup after 3 seconds
        task.delay(3, function()
            if previewModel and previewModel.Parent then
                previewModel:Destroy()
            end
        end)
    end,
    
    attemptTrick = function(direction: Vector3): boolean
        TrickSystem.detectWalls()
        
        local frontWall = aiState.wallDetectionData.frontWall
        local leftWall = aiState.wallDetectionData.leftWall
        local rightWall = aiState.wallDetectionData.rightWall
        local ladderNearby = aiState.wallDetectionData.ladderNearby
        
        -- Add some randomness based on aggression setting
        local shouldUseTrick = math.random() < CONFIG.TRICK_AGGRESSION
        
        if shouldUseTrick then
            -- Priority: Ladder Flick > Wrap Around > Wall Hop
            if ladderNearby and TrickSystem.canPerformTrick() then
                return TrickSystem.executeLadderFlick(direction)
            elseif frontWall and (leftWall or rightWall) and TrickSystem.canPerformTrick() then
                return TrickSystem.executeWrapAround(direction)
            elseif leftWall and rightWall and TrickSystem.canPerformTrick() then
                return TrickSystem.executeWallHop()
            end
        end
        
        return false
    end,
    
    getTrickStatistics = function(): string
        local total = aiState.trickUsage.ladderFlick + aiState.trickUsage.wallHop + aiState.trickUsage.wrapAround
        if total == 0 then
            return "No tricks used yet"
        end
        
        return string.format("Ladder Flicks: %d | Wall Hops: %d | Wrap Arounds: %d | Total: %d",
            aiState.trickUsage.ladderFlick,
            aiState.trickUsage.wallHop,
            aiState.trickUsage.wrapAround,
            total
        )
    end
}

-- Enhanced Memory System
local MemorySystem = {
    hashWaypoint = function(waypoint: Vector3): string
        return string.format("%d,%d,%d", 
            math.floor(waypoint.X/5), 
            math.floor(waypoint.Y/5), 
            math.floor(waypoint.Z/5)
        )
    end,
    
    compressPath = function(waypoints: {any}): string
        if not waypoints or #waypoints == 0 then return "" end
        
        local compressed = {}
        for _, waypoint in ipairs(waypoints) do
            table.insert(compressed, MemorySystem.hashWaypoint(waypoint.Position))
        end
        return table.concat(compressed, ";")
    end,
    
    decompressPath = function(compressedPath: string): {Vector3}
        local waypoints = {}
        if not compressedPath or compressedPath == "" then return waypoints end
        
        for waypointStr in string.gmatch(compressedPath, "[^;]+") do
            local x, y, z = string.match(waypointStr, "(%d+),(%d+),(%d+)")
            if x and y and z then
                table.insert(waypoints, Vector3.new(tonumber(x)*5, tonumber(y)*5, tonumber(z)*5))
            end
        end
        return waypoints
    end,
    
    updatePathMemory = function(waypoint: Vector3, success: boolean)
        local key = MemorySystem.hashWaypoint(waypoint)
        
        if success then
            aiState.pathMemory.efficientWaypoints[key] = tick()
            
            if aiState.pathMemory.failedWaypoints[key] then
                aiState.pathMemory.failedWaypoints[key] = nil
            end
        else
            if not aiState.pathMemory.failedWaypoints[key] then
                aiState.pathMemory.failedWaypoints[key] = 1
            else
                aiState.pathMemory.failedWaypoints[key] = aiState.pathMemory.failedWaypoints[key] + 1
            end
            
            if aiState.pathMemory.failedWaypoints[key] >= CONFIG.MAX_FAILED_ATTEMPTS then
                aiState.pathMemory.failedWaypoints[key] = "dangerous"
            end
        end
    end,
    
    cleanOldMemory = function()
        local currentTime = tick()
        
        for key, timestamp in pairs(aiState.pathMemory.successfulPaths) do
            if currentTime - timestamp > CONFIG.MEMORY_RETENTION_TIME then
                aiState.pathMemory.successfulPaths[key] = nil
            end
        end
        
        for key, timestamp in pairs(aiState.pathMemory.efficientWaypoints) do
            if currentTime - timestamp > CONFIG.MEMORY_RETENTION_TIME then
                aiState.pathMemory.efficientWaypoints[key] = nil
            end
        end
        
        local pathCacheSize = 0
        for _ in pairs(aiState.pathCache) do
            pathCacheSize = pathCacheSize + 1
        end
        
        if pathCacheSize > CONFIG.MAX_PATH_CACHE_SIZE then
            local entriesToRemove = {}
            for key, pathData in pairs(aiState.pathCache) do
                table.insert(entriesToRemove, {key = key, timestamp = pathData.timestamp})
            end
            
            table.sort(entriesToRemove, function(a, b)
                return a.timestamp < b.timestamp
            end)
            
            for i = 1, pathCacheSize - CONFIG.MAX_PATH_CACHE_SIZE do
                aiState.pathCache[entriesToRemove[i].key] = nil
            end
        end
    end,
    
    validateMemory = function(): boolean
        for key, value in pairs(aiState.pathMemory.failedWaypoints) do
            if type(value) ~= "number" and value ~= "dangerous" then
                aiState.pathMemory.failedWaypoints[key] = nil
                ErrorHandler.log("WARN", "Removed corrupted memory entry: %s", key)
            end
        end
        return true
    end,
}

-- State machine for AI behavior
local StateMachine = {
    states = {
        idle = {
            enter = function()
                aiState.currentCommand = "Idle"
                updateStatus("Idle", "Waiting for command...")
            end,
            update = function(deltaTime) end,
            exit = function() end
        },
        
        following = {
            enter = function()
                aiState.currentCommand = "Following"
            end,
            update = function(deltaTime)
                if not aiState.targetPlayer or not aiState.targetPlayer.Character or not aiState.targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    StateMachine.transitionTo("idle")
                    return
                end
                
                local predictedPos = predictPlayerPosition(aiState.targetPlayer)
                local direction = (humanoidRootPart.Position - predictedPos).Unit
                aiState.goalPosition = predictedPos + direction * CONFIG.FOLLOW_DISTANCE
                
                if not aiState.currentPath or #aiState.currentPath == 0 or tick() - (aiState.lastPathCalculation or 0) > CONFIG.RECALCULATION_INTERVAL then
                    moveToGoal()
                    aiState.lastPathCalculation = tick()
                end
            end,
            exit = function()
                aiState.targetPlayer = nil
                aiState.goalPosition = nil
            end
        },
        
        parkour = {
            enter = function()
                aiState.currentCommand = "Parkour"
            end,
            update = function(deltaTime) end,
            exit = function() end
        },
        
        maneuvering = {
            enter = function()
                aiState.currentCommand = "Maneuvering"
            end,
            update = function(deltaTime)
                if aiState.currentManeuver ~= "None" then
                    local timeSinceManeuver = tick() - aiState.maneuverData.startTime
                    if timeSinceManeuver > 2 then
                        aiState.currentManeuver = "None"
                        aiState.maneuverData = {}
                        StateMachine.transitionTo("idle")
                    end
                end
            end,
            exit = function()
                aiState.currentManeuver = "None"
                aiState.maneuverData = {}
            end
        },
        
        performing_trick = {
            enter = function()
                aiState.currentCommand = "Performing Trick"
            end,
            update = function(deltaTime)
                if not aiState.isPerformingTrick then
                    StateMachine.transitionTo("idle")
                end
            end,
            exit = function()
                aiState.isPerformingTrick = false
                aiState.currentTrick = "None"
            end
        }
    },
    
    currentState = "idle",
    
    transitionTo = function(newState: string)
        if not StateMachine.states[newState] then
            ErrorHandler.log("ERROR", "Invalid state transition: %s", newState)
            return
        end
        
        if StateMachine.states[StateMachine.currentState] and StateMachine.states[StateMachine.currentState].exit then
            StateMachine.states[StateMachine.currentState].exit()
        end
        
        table.insert(aiState.stateHistory, {
            from = StateMachine.currentState,
            to = newState,
            timestamp = tick()
        })
        
        if #aiState.stateHistory > 10 then
            table.remove(aiState.stateHistory, 1)
        end
        
        StateMachine.currentState = newState
        if StateMachine.states[newState].enter then
            StateMachine.states[newState].enter()
        end
        
        ErrorHandler.log("INFO", "State transition: %s -> %s", StateMachine.currentState, newState)
    end,
    
    update = function(deltaTime)
        if StateMachine.states[StateMachine.currentState] and StateMachine.states[StateMachine.currentState].update then
            StateMachine.states[StateMachine.currentState].update(deltaTime)
        end
    end
}

-- Fixed UI System with proper error handling
local UISystem = {
    initialize = function()
        if not CoreGui then
            ErrorHandler.log("ERROR", "CoreGui service is not available")
            return
        end
        
        local success, errorMessage = pcall(function()
            UISystem.createIntroGUI()
        end)
        
        if not success then
            ErrorHandler.log("ERROR", "Failed to create intro GUI: %s", errorMessage)
            task.spawn(function()
                UISystem.createMainGUI()
                UIState.isInitialized = true
                UIState.lastRefreshTime = tick()
                aiState.isRunning = true
                StateMachine.transitionTo("idle")
            end)
            return
        end
        
        UIState.isInitialized = true
        UIState.lastRefreshTime = tick()
        
        task.spawn(function()
            while UIState.isInitialized do
                task.wait(1)
                if tick() - UIState.lastRefreshTime > UIState.refreshInterval or not UIState.isResponsive then
                    UISystem.refresh()
                end
            end
        end)
    end,
    
    createIntroGUI = function()
        if CoreGui:FindFirstChild("KYNEXIntro") then
            CoreGui:FindFirstChild("KYNEXIntro"):Destroy()
        end
        
        local introGui = Instance.new("ScreenGui")
        introGui.Name = "KYNEXIntro"
        introGui.Parent = CoreGui
        introGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        UIState.elements.introGui = introGui

        local loadingFrame = Instance.new("Frame")
        loadingFrame.Size = UDim2.new(1, 0, 1, 0)
        loadingFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        loadingFrame.Parent = introGui
        
        local loadingText = Instance.new("TextLabel")
        loadingText.Size = UDim2.new(0, 200, 0, 50)
        loadingText.Position = UDim2.new(0.5, -100, 0.5, -25)
        loadingText.BackgroundTransparency = 1
        loadingText.Text = "Loading Modules..."
        loadingText.TextColor3 = CONFIG.PRIMARY_COLOR
        loadingText.TextScaled = true
        loadingText.Font = CONFIG.FONT
        loadingText.Parent = loadingFrame
        
        TweenService:Create(loadingText, TweenInfo.new(1), {TextTransparency = 0}):Play()
        
        -- Simulate loading sequence
        local loadingSteps = {
            "Initializing AI Core...",
            "Calibrating Pathfinding...",
            "Loading Memory System...",
            "Analyzing Obstacle Patterns...",
            "Loading Advanced Parkour..."
        }
        
        for _, step in ipairs(loadingSteps) do
            task.wait(1.5)
            loadingText.Text = step
        end
        
        task.wait(1)
        loadingFrame:Destroy()
        
        local welcomeFrame = Instance.new("Frame")
        welcomeFrame.Size = UDim2.new(1, 0, 1, 0)
        welcomeFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        welcomeFrame.Parent = introGui
        
        local welcomeText = Instance.new("TextLabel")
        welcomeText.Size = UDim2.new(1, 0, 0, 100)
        welcomeText.Position = UDim2.new(0, 0, 0.5, -50)
        welcomeText.BackgroundTransparency = 1
        welcomeText.Text = ""
        welcomeText.TextColor3 = CONFIG.PRIMARY_COLOR
        welcomeText.TextScaled = true
        welcomeText.Font = CONFIG.FONT
        welcomeText.Parent = welcomeFrame
        
        local welcomeString = "WELCOME TO KYNEX AI"
        for i = 1, #welcomeString do
            welcomeText.Text = string.sub(welcomeString, 1, i)
            task.wait(0.05)
        end
        task.wait(1.5)
        
        TweenService:Create(welcomeFrame, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(welcomeText, TweenInfo.new(1.5), {TextTransparency = 1}):Play()
        task.wait(1.5)
        
        welcomeFrame:Destroy()
        
        local injectFrame = Instance.new("Frame")
        injectFrame.Size = UDim2.new(0, 400, 0, 250)
        injectFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
        injectFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        injectFrame.BorderSizePixel = 0
        injectFrame.Parent = introGui
        
        local injectTitle = Instance.new("TextLabel")
        injectTitle.Size = UDim2.new(1, 0, 0, 50)
        injectTitle.Position = UDim2.new(0, 0, 0, 20)
        injectTitle.BackgroundTransparency = 1
        injectTitle.Text = "Welcome to KYNEX AI"
        injectTitle.TextColor3 = CONFIG.PRIMARY_COLOR
        injectTitle.TextScaled = true
        injectTitle.Font = CONFIG.FONT
        injectTitle.Parent = injectFrame
        
        local injectDesc = Instance.new("TextLabel")
        injectDesc.Size = UDim2.new(1, -20, 0, 80)
        injectDesc.Position = UDim2.new(0, 10, 0, 80)
        injectDesc.BackgroundTransparency = 1
        injectDesc.Text = "An adaptive AI with advanced parkour: Ladder Flicks, Wallhops, and Wrap Arounds!"
        injectDesc.TextColor3 = CONFIG.TEXT_COLOR
        injectDesc.TextWrapped = true
        injectDesc.Font = CONFIG.FONT
        injectDesc.TextSize = 18
        injectDesc.Parent = injectFrame

        local injectButton = Instance.new("TextButton")
        injectButton.Size = UDim2.new(0, 150, 0, 50)
        injectButton.Position = UDim2.new(0.5, -75, 1, -70)
        injectButton.BackgroundColor3 = CONFIG.PRIMARY_COLOR
        injectButton.BorderSizePixel = 0
        injectButton.Text = "INJECT"
        injectButton.TextColor3 = CONFIG.TEXT_COLOR
        injectButton.Font = CONFIG.FONT
        injectButton.TextScaled = true
        injectButton.Parent = injectFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = injectButton
        
        injectButton.MouseButton1Click:Connect(function()
            introGui:Destroy()
            UISystem.createMainGUI()
            aiState.isRunning = true
            StateMachine.transitionTo("idle")
            
            task.spawn(function()
                while aiState.isRunning do
                    task.wait(CONFIG.MEMORY_CLEANUP_INTERVAL)
                    MemorySystem.cleanOldMemory()
                end
            end)
            
            task.spawn(function()
                while aiState.isRunning do
                    task.wait(CONFIG.PERFORMANCE_MONITOR_INTERVAL)
                    PerformanceMonitor.checkPerformance()
                end
            end)
        end)
    end,
    
    createMainGUI = function()
        if CoreGui:FindFirstChild("KYNEXMain") then
            CoreGui:FindFirstChild("KYNEXMain"):Destroy()
        end
        
        local mainGui = Instance.new("ScreenGui")
        mainGui.Name = "KYNEXMain"
        mainGui.Parent = CoreGui
        mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        mainGui.ResetOnSpawn = false
        UIState.elements.mainGui = mainGui

        local statusSidebar = Instance.new("Frame")
        statusSidebar.Name = "StatusSidebar"
        
        if isMobile then
            statusSidebar.Size = UDim2.new(0, 250 * CONFIG.MOBILE_SCALE, 1, 0)
            statusSidebar.Position = UDim2.new(1, -250 * CONFIG.MOBILE_SCALE, 0, 0)
        else
            statusSidebar.Size = UDim2.new(0, 250, 1, 0)
            statusSidebar.Position = UDim2.new(1, -250, 0, 0)
        end
        
        statusSidebar.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        statusSidebar.BorderSizePixel = 0
        statusSidebar.Parent = mainGui
        UIState.elements.statusSidebar = statusSidebar
        
        local sidebarList = Instance.new("UIListLayout")
        sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
        sidebarList.Padding = UDim.new(0, 10)
        sidebarList.Parent = statusSidebar
        
        local sidebarPadding = Instance.new("UIPadding")
        sidebarPadding.PaddingTop = UDim.new(0, 20)
        sidebarPadding.PaddingLeft = UDim.new(0, 10)
        sidebarPadding.PaddingRight = UDim.new(0, 10)
        sidebarPadding.Parent = statusSidebar

        local title = UISystem.createStyledTextLabel("KYNEX AI", UDim2.new(1, 0, 0, 40), 1)
        title.TextColor3 = CONFIG.PRIMARY_COLOR
        title.Parent = statusSidebar

        local statusTitle = UISystem.createStyledTextLabel("STATUS", UDim2.new(1, 0, 0, 30), 2)
        statusTitle.TextXAlignment = Enum.TextXAlignment.Left
        statusTitle.Parent = statusSidebar
        
        local statusValue = UISystem.createStyledTextLabel("Idle", UDim2.new(1, 0, 0, 30), 3)
        statusValue.Name = "StatusValue"
        statusValue.TextXAlignment = Enum.TextXAlignment.Left
        statusValue.Parent = statusSidebar

        local commandTitle = UISystem.createStyledTextLabel("COMMAND", UDim2.new(1, 0, 0, 30), 4)
        commandTitle.TextXAlignment = Enum.TextXAlignment.Left
        commandTitle.Parent = statusSidebar

        local commandValue = UISystem.createStyledTextLabel("None", UDim2.new(1, 0, 0, 30), 5)
        commandValue.Name = "CommandValue"
        commandValue.TextXAlignment = Enum.TextXAlignment.Left
        commandValue.Parent = statusSidebar
        
        local maneuverTitle = UISystem.createStyledTextLabel("MANEUVER", UDim2.new(1, 0, 0, 30), 6)
        maneuverTitle.TextXAlignment = Enum.TextXAlignment.Left
        maneuverTitle.Parent = statusSidebar
        
        local maneuverValue = UISystem.createStyledTextLabel("None", UDim2.new(1, 0, 0, 30), 7)
        maneuverValue.Name = "ManeuverValue"
        maneuverValue.TextXAlignment = Enum.TextXAlignment.Left
        maneuverValue.Parent = statusSidebar
        
        local trickTitle = UISystem.createStyledTextLabel("CURRENT TRICK", UDim2.new(1, 0, 0, 30), 8)
        trickTitle.TextXAlignment = Enum.TextXAlignment.Left
        trickTitle.Parent = statusSidebar
        
        local trickValue = UISystem.createStyledTextLabel("None", UDim2.new(1, 0, 0, 30), 9)
        trickValue.Name = "TrickValue"
        trickValue.TextXAlignment = Enum.TextXAlignment.Left
        trickValue.Parent = statusSidebar
        
        local toggleButton = UISystem.createStyledTextButton("Hide", UDim2.new(1, 0, 0, 40), 10)
        toggleButton.Parent = statusSidebar
        
        local isVisible = true
        toggleButton.MouseButton1Click:Connect(function()
            isVisible = not isVisible
            UIState.isVisible = isVisible
            
            local targetPosition = isVisible and 
                (isMobile and UDim2.new(1, -250 * CONFIG.MOBILE_SCALE, 0, 0) or UDim2.new(1, -250, 0, 0)) or 
                UDim2.new(1, 0, 0, 0)
                
            TweenService:Create(statusSidebar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                Position = targetPosition
            }):Play()
            toggleButton.Text = isVisible and "Hide" or "Show"
        end)

        local commandFrame = Instance.new("Frame")
        commandFrame.Name = "CommandFrame"
        
        if isMobile then
            commandFrame.Size = UDim2.new(0, 400 * CONFIG.MOBILE_SCALE, 0, 60 * CONFIG.MOBILE_SCALE)
            commandFrame.Position = UDim2.new(0.5, -200 * CONFIG.MOBILE_SCALE, 1, -80 * CONFIG.MOBILE_SCALE)
        else
            commandFrame.Size = UDim2.new(0, 400, 0, 60)
            commandFrame.Position = UDim2.new(0.5, -200, 1, -80)
        end
        
        commandFrame.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        commandFrame.BorderSizePixel = 0
        commandFrame.Parent = mainGui
        UIState.elements.commandFrame = commandFrame
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 8)
        frameCorner.Parent = commandFrame

        local commandTextBox = Instance.new("TextBox")
        commandTextBox.Size = UDim2.new(1, -20, 1, -10)
        commandTextBox.Position = UDim2.new(0, 10, 0, 5)
        commandTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        commandTextBox.BorderSizePixel = 0
        commandTextBox.PlaceholderText = "Enter command (e.g., /follow PlayerName, /smartparkour, /trickstats)"
        commandTextBox.Text = ""
        commandTextBox.TextColor3 = CONFIG.TEXT_COLOR
        commandTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        commandTextBox.Font = CONFIG.FONT
        commandTextBox.TextSize = isMobile and 18 * CONFIG.MOBILE_SCALE or 18
        commandTextBox.Parent = commandFrame
        UIState.elements.commandTextBox = commandTextBox
        
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 6)
        boxCorner.Parent = commandTextBox

        commandTextBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                processCommand(commandTextBox.Text)
                commandTextBox.Text = ""
            end
        end)
        
        if isMobile then
            UISystem.createMobileControls(mainGui)
        end
    end,
    
    createMobileControls = function(parent: Instance)
        local controlFrame = Instance.new("Frame")
        controlFrame.Name = "MobileControls"
        controlFrame.Size = UDim2.new(0, 200 * CONFIG.MOBILE_SCALE, 0, 200 * CONFIG.MOBILE_SCALE)
        controlFrame.Position = UDim2.new(0, 20, 1, -220 * CONFIG.MOBILE_SCALE)
        controlFrame.BackgroundTransparency = 1
        controlFrame.Parent = parent
        UIState.elements.mobileControls = controlFrame
        
        local buttonSize = UDim2.new(0, 60 * CONFIG.MOBILE_SCALE, 0, 60 * CONFIG.MOBILE_SCALE)
        local centerOffset = 70 * CONFIG.MOBILE_SCALE
        
        local upButton = UISystem.createStyledTextButton("↑", buttonSize, 1)
        upButton.Position = UDim2.new(0, centerOffset, 0, 0)
        upButton.Parent = controlFrame
        
        upButton.MouseButton1Click:Connect(function()
            processCommand("/smartparkour")
        end)
        
        local downButton = UISystem.createStyledTextButton("↓", buttonSize, 2)
        downButton.Position = UDim2.new(0, centerOffset, 0, centerOffset * 2)
        downButton.Parent = controlFrame
        
        downButton.MouseButton1Click:Connect(function()
            processCommand("/unfollow")
        end)
        
        local leftButton = UISystem.createStyledTextButton("←", buttonSize, 3)
        leftButton.Position = UDim2.new(0, 0, 0, centerOffset)
        leftButton.Parent = controlFrame
        
        leftButton.MouseButton1Click:Connect(function()
            processCommand("/parkourrun")
        end)
        
        local rightButton = UISystem.createStyledTextButton("→", buttonSize, 4)
        rightButton.Position = UDim2.new(0, centerOffset * 2, 0, centerOffset)
        rightButton.Parent = controlFrame
        
        rightButton.MouseButton1Click:Connect(function()
            processCommand("/rungoal")
        end)
    end,
    
    createStyledTextLabel = function(text: string, size: UDim2, layoutOrder: number): TextLabel
        local label = Instance.new("TextLabel")
        label.Size = size
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.TEXT_COLOR
        label.TextScaled = true
        label.Font = CONFIG.FONT
        label.LayoutOrder = layoutOrder
        return label
    end,
    
    createStyledTextButton = function(text: string, size: UDim2, layoutOrder: number): TextButton
        local button = Instance.new("TextButton")
        button.Size = size
        button.BackgroundColor3 = CONFIG.PRIMARY_COLOR
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = CONFIG.TEXT_COLOR
        button.TextScaled = true
        button.Font = CONFIG.FONT
        button.LayoutOrder = layoutOrder
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        return button
    end,
    
    refresh = function()
        if not UIState.isInitialized then return end
        
        ErrorHandler.log("INFO", "Refreshing UI")
        
        UIState.isResponsive = true
        UIState.lastRefreshTime = tick()
        
        updateStatus(aiState.currentCommand, "System refreshed")
        
        for name, element in pairs(UIState.elements) do
            if not element or not element.Parent then
                ErrorHandler.log("WARN", "UI element missing: %s", name)
                UIState.isResponsive = false
                return
            end
        end
    end,
}

-- Performance monitoring system
local PerformanceMonitor = {
    checkPerformance = function()
        local currentTime = tick()
        local deltaTime = currentTime - performanceMonitor.lastFrameTime
        performanceMonitor.averageFrameTime = performanceMonitor.averageFrameTime * 0.9 + deltaTime * 0.1
        performanceMonitor.lastFrameTime = currentTime
        
        if currentTime - performanceMonitor.lastMemoryCheck > 10 then
            performanceMonitor.memoryUsage = collectgarbage("count")
            performanceMonitor.lastMemoryCheck = currentTime
            
            if performanceMonitor.memoryUsage > 50000 then
                ErrorHandler.log("WARN", "High memory usage: %.2f KB", performanceMonitor.memoryUsage)
                MemorySystem.cleanOldMemory()
                collectgarbage("collect")
            end
        end
        
        if performanceMonitor.averageFrameTime > 0.05 then
            ErrorHandler.log("WARN", "Low frame rate detected: %.2f ms", performanceMonitor.averageFrameTime * 1000)
            CONFIG.RECALCULATION_INTERVAL = math.min(CONFIG.RECALCULATION_INTERVAL * 1.5, 2.0)
        else
            CONFIG.RECALCULATION_INTERVAL = 0.5
        end
    end
}

-- Obstacle Analysis Functions with advanced trick detection
local function analyzeObstacle(direction: Vector3): string
    if not humanoidRootPart then return "none" end
    
    local origin = humanoidRootPart.Position
    local lookDirection = direction.Unit
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    -- First, check for advanced trick opportunities
    TrickSystem.detectWalls()
    
    local frontWall = aiState.wallDetectionData.frontWall
    local leftWall = aiState.wallDetectionData.leftWall
    local rightWall = aiState.wallDetectionData.rightWall
    local ladderNearby = aiState.wallDetectionData.ladderNearby
    
    -- Check for trick opportunities first
    if ladderNearby and TrickSystem.canPerformTrick() then
        return "ladder_flick_opportunity"
    elseif frontWall and (leftWall or rightWall) and TrickSystem.canPerformTrick() then
        return "wrap_around_opportunity"
    elseif leftWall and rightWall and TrickSystem.canPerformTrick() then
        return "wallhop_opportunity"
    end
    
    -- Then check for basic obstacles
    local downResult = Workspace:Raycast(origin + lookDirection * 5, Vector3.new(0, -10, 0), raycastParams)
    if not downResult then
        return "gap"
    end
    
    local forwardResult = Workspace:Raycast(origin, lookDirection * CONFIG.OBSTACLE_SCAN_DISTANCE, raycastParams)
    if forwardResult then
        local upResult = Workspace:Raycast(forwardResult.Position, Vector3.new(0, 10, 0), raycastParams)
        if upResult then
            return "wall"
        end
    end
    
    if forwardResult and forwardResult.Instance then
        local part = forwardResult.Instance
        if part.Velocity.Magnitude > 0.1 or part.AssemblyAngularVelocity.Magnitude > 0.1 then
            return "moving_platform"
        end
    end
    
    return "none"
end

local function executeManeuver(maneuverType: string, direction: Vector3)
    if not humanoid then return end
    
    if aiState.maneuverCooldowns[maneuverType] and tick() - aiState.maneuverCooldowns[maneuverType] < 2 then
        return
    end
    
    aiState.currentManeuver = maneuverType
    aiState.maneuverData = {direction = direction, startTime = tick()}
    aiState.maneuverCooldowns[maneuverType] = tick()
    
    StateMachine.transitionTo("maneuvering")
    
    if maneuverType == "gap" then
        updateStatus("Maneuver", "Executing long jump")
        humanoid.Jump = true
        humanoid:Move(direction * 1.5)
    elseif maneuverType == "wall" then
        updateStatus("Maneuver", "Attempting wall jump")
        humanoid.Jump = true
        local sideDirection = Vector3.new(direction.Z, 0, -direction.X).Unit
        humanoid:Move(sideDirection)
    elseif maneuverType == "moving_platform" then
        updateStatus("Maneuver", "Timing jump to moving platform")
    elseif maneuverType == "ladder_flick_opportunity" then
        TrickSystem.executeLadderFlick(direction)
    elseif maneuverType == "wrap_around_opportunity" then
        TrickSystem.executeWrapAround(direction)
    elseif maneuverType == "wallhop_opportunity" then
        TrickSystem.executeWallHop()
    end
end

-- Predictive Following Functions
local function predictPlayerPosition(targetPlayer: Player): Vector3
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return Vector3.new(0, 0, 0)
    end
    
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHumanoid then
        return targetPlayer.Character.HumanoidRootPart.Position
    end
    
    local currentPosition = targetPlayer.Character.HumanoidRootPart.Position
    local moveDirection = targetHumanoid.MoveDirection
    local walkSpeed = targetHumanoid.WalkSpeed
    
    local deltaTime = DeltaTimeManager.getDelta()
    local predictedPosition = currentPosition + moveDirection * walkSpeed * CONFIG.PREDICTION_TIME
    
    return predictedPosition
end

-- Enhanced Parkour Functions with trick integration
local function analyzeParkourChain(): {Vector3}
    if not humanoidRootPart then return {} end
    
    local checkpoints = {}
    local origin = humanoidRootPart.Position
    
    table.insert(checkpoints, origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local lastCheckpoint = origin
    local foundNewCheckpoint = true
    
    while foundNewCheckpoint and #checkpoints < 10 do
        foundNewCheckpoint = false
        
        for angle = 0, 360, 45 do
            local rad = math.rad(angle)
            local direction = Vector3.new(math.cos(rad), 0.5, math.sin(rad)).Unit
            
            local result = Workspace:Raycast(
                lastCheckpoint, 
                direction * CONFIG.PARKOUR_CHECKPOINT_DISTANCE, 
                raycastParams
            )
            
            if result and result.Position.Y > lastCheckpoint.Y + 2 then
                local isNew = true
                for _, checkpoint in ipairs(checkpoints) do
                    if (result.Position - checkpoint).Magnitude < 5 then
                        isNew = false
                        break
                    end
                end
                
                if isNew then
                    table.insert(checkpoints, result.Position)
                    lastCheckpoint = result.Position
                    foundNewCheckpoint = true
                    break
                end
            end
        end
    end
    
    return checkpoints
end

local function clearPathPreview()
    for _, model in ipairs(aiState.pathPreviewModels) do
        if model and model.Parent then
            model:Destroy()
        end
    end
    aiState.pathPreviewModels = {}
end

local function showPathPreview(paths: {any})
    clearPathPreview()
    for i, path in ipairs(paths) do
        local waypoints = path:GetWaypoints()
        local color = CONFIG.PATH_COLORS[i] or CONFIG.PRIMARY_COLOR
        local previewModel = Instance.new("Model")
        previewModel.Name = "PathPreview_" .. i
        previewModel.Parent = Workspace

        for j = 1, #waypoints - 1 do
            local wp1, wp2 = waypoints[j], waypoints[j+1]
            local distance = (wp1.Position - wp2.Position).Magnitude
            local beam = Instance.new("Part")
            beam.Anchored = true
            beam.CanCollide = false
            beam.Material = Enum.Material.Neon
            beam.BrickColor = BrickColor.new(color)
            beam.Transparency = 0.5
            beam.Size = Vector3.new(0.5, 0.5, distance)
            beam.CFrame = CFrame.new(wp1.Position, wp2.Position) * CFrame.new(0, 0, -distance / 2)
            beam.Parent = previewModel
        end
        table.insert(aiState.pathPreviewModels, previewModel)
    end
end

local function calculatePath(goal: Vector3): {any}?
    if not humanoidRootPart then return nil end
    
    local paths = {}
    local baseGoal = goal
    
    local cacheKey = MemorySystem.hashWaypoint(goal)
    if aiState.pathCache[cacheKey] then
        local cachedPath = aiState.pathCache[cacheKey].path
        if cachedPath.Status == Enum.PathStatus.Success then
            ErrorHandler.log("INFO", "Using cached path")
            return {cachedPath}
        end
    end
    
    local path = PathfindingService:CreatePath({
        AgentHeight = 5,
        AgentRadius = 2,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {}
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(humanoidRootPart.Position, baseGoal)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local hasDangerousWaypoint = false
        
        for _, waypoint in ipairs(waypoints) do
            local key = MemorySystem.hashWaypoint(waypoint.Position)
            if aiState.pathMemory.failedWaypoints[key] == "dangerous" then
                hasDangerousWaypoint = true
                break
            end
        end
        
        if not hasDangerousWaypoint then
            table.insert(paths, path)
            
            aiState.pathCache[cacheKey] = {
                path = path,
                timestamp = tick()
            }
        end
    end

    local offsets = {
        Vector3.new(10, 0, 0),
        Vector3.new(-10, 0, 0),
        Vector3.new(0, 0, 10),
        Vector3.new(0, 0, -10),
    }
    
    for _, offset in ipairs(offsets) do
        local dummyPath = PathfindingService:CreatePath({
            AgentHeight = 5,
            AgentRadius = 2,
            AgentCanJump = true,
            WaypointSpacing = 4
        })
        local success = pcall(function()
            dummyPath:ComputeAsync(humanoidRootPart.Position, baseGoal + offset)
        end)
        if success and dummyPath.Status == Enum.PathStatus.Success then
            local waypoints = dummyPath:GetWaypoints()
            local hasDangerousWaypoint = false
            
            for _, waypoint in ipairs(waypoints) do
                local key = MemorySystem.hashWaypoint(waypoint.Position)
                if aiState.pathMemory.failedWaypoints[key] == "dangerous" then
                    hasDangerousWaypoint = true
                    break
                end
            end
            
            if not hasDangerousWaypoint then
                table.insert(paths, dummyPath)
            end
        end
    end
    
    if #paths > 0 then
        table.sort(paths, function(a, b)
            local aEfficiency = 0
            local bEfficiency = 0
            
            local aWaypoints = a:GetWaypoints()
            local bWaypoints = b:GetWaypoints()
            
            for _, waypoint in ipairs(aWaypoints) do
                local key = MemorySystem.hashWaypoint(waypoint.Position)
                if aiState.pathMemory.efficientWaypoints[key] then
                    aEfficiency = aEfficiency + 1
                end
            end
            
            for _, waypoint in ipairs(bWaypoints) do
                local key = MemorySystem.hashWaypoint(waypoint.Position)
                if aiState.pathMemory.efficientWaypoints[key] then
                    bEfficiency = bEfficiency + 1
                end
            end
            
            return aEfficiency > bEfficiency
        end)
        
        showPathPreview(paths)
        return paths
    end
    
    return nil
end

-- Enhanced moveToGoal function with aggressive trick usage for rungoal
local function moveToGoal()
    if not aiState.goalPosition or not aiState.isRunning or not humanoidRootPart then return end
    
    local paths = calculatePath(aiState.goalPosition)
    if not paths then
        updateStatus("Error", "No path found!")
        humanoid:MoveTo(humanoidRootPart.Position)
        return
    end
    
    local bestPath = paths[1]
    local waypoints = bestPath:GetWaypoints()
    aiState.currentPath = waypoints
    aiState.lastWaypointIndex = 0
    
    for i, waypoint in ipairs(waypoints) do
        if not aiState.isRunning then break end
        
        if aiState.goalPosition ~= (aiState.targetPlayer and predictPlayerPosition(aiState.targetPlayer) or aiState.goalPosition) then
            moveToGoal()
            return
        end
        
        local direction = (waypoint.Position - humanoidRootPart.Position).Unit
        local obstacleType = analyzeObstacle(direction)
        
        -- Enhanced trick system for rungoal - more aggressive trick usage
        if aiState.currentCommand == "Running" then
            -- For rungoal, use tricks more aggressively
            CONFIG.TRICK_AGGRESSION = 0.8 -- Higher aggression for rungoal
        else
            CONFIG.TRICK_AGGRESSION = 0.7 -- Normal aggression for other commands
        end
        
        -- Attempt tricks before basic maneuvers
        if obstacleType:find("opportunity") and TrickSystem.canPerformTrick() then
            if TrickSystem.attemptTrick(direction) then
                task.wait(0.3) -- Allow trick to complete
                moveToGoal() -- Recalculate after trick
                return
            end
        elseif obstacleType ~= "none" and aiState.currentManeuver == "None" then
            executeManeuver(obstacleType, direction)
            task.wait(1)
            aiState.currentManeuver = "None"
            
            moveToGoal()
            return
        end
        
        humanoid:MoveTo(waypoint.Position)
        humanoid.MoveToFinished:Wait()
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        
        MemorySystem.updatePathMemory(waypoint.Position, true)
        
        aiState.lastWaypointIndex = i
    end
end

local function processCommand(input: string)
    if not input or input == "" then return end
    
    local args = string.split(string.lower(input), " ")
    local command = args[1]
    
    updateStatus("Processing", "Executing: " .. input)
    
    if command == "/follow" and args[2] then
        local targetName = args[2]
        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            aiState.targetPlayer = targetPlayer
            StateMachine.transitionTo("following")
            updateStatus("Following", "Target: " .. targetPlayer.Name)
        else
            updateStatus("Error", "Player '" .. targetName .. "' not found.")
            StateMachine.transitionTo("idle")
        end
        
    elseif command == "/unfollow" then
        if aiState.targetPlayer then
            updateStatus("Unfollow", "Stopped following " .. aiState.targetPlayer.Name)
            StateMachine.transitionTo("idle")
        else
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "[KYNEX] AI is not following anyone.";
                Color = Color3.new(1, 0.5, 0.25);
            })
        end
        
    elseif command == "/parkourrun" then
        updateStatus("Parkour Run", "Scanning for highest point...")
        StateMachine.transitionTo("parkour")
        aiState.goalPosition = nil
        
        if not humanoidRootPart then return end
        
        local origin = humanoidRootPart.Position
        local direction = Vector3.new(0, 1, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local highestPoint = origin
        for i = 1, CONFIG.PARKOUR_SCAN_HEIGHT, 10 do
            local result = Workspace:Raycast(origin + Vector3.new(0, i, 0), direction * 10, raycastParams)
            if result and result.Instance and result.Instance.CanCollide then
                highestPoint = result.Position
            end
        end
        
        aiState.goalPosition = highestPoint
        updateStatus("Parkour Run", "Goal set. Moving...")
        moveToGoal()
        
    elseif command == "/smartparkour" then
        updateStatus("Smart Parkour", "Analyzing parkour chain...")
        StateMachine.transitionTo("parkour")
        
        local checkpoints = analyzeParkourChain()
        if #checkpoints > 1 then
            updateStatus("Smart Parkour", "Found " .. #checkpoints .. " checkpoints")
            
            for i = 2, #checkpoints do
                if not aiState.isRunning or aiState.currentCommand ~= "Smart Parkour" then break end
                
                aiState.goalPosition = checkpoints[i]
                updateStatus("Smart Parkour", "Moving to checkpoint " .. (i-1) .. "/" .. (#checkpoints-1))
                moveToGoal()
                
                local reachedCheckpoint = false
                local timeout = tick() + 10
                
                while not reachedCheckpoint and tick() < timeout do
                    if humanoidRootPart and (humanoidRootPart.Position - checkpoints[i]).Magnitude < 5 then
                        reachedCheckpoint = true
                    end
                    task.wait(0.5)
                end
                
                if not reachedCheckpoint then
                    updateStatus("Smart Parkour", "Failed to reach checkpoint, aborting")
                    break
                end
            end
            
            if aiState.currentCommand == "Smart Parkour" then
                updateStatus("Smart Parkour", "Parkour chain completed!")
                StateMachine.transitionTo("idle")
            end
        else
            updateStatus("Smart Parkour", "No parkour chain found")
            StateMachine.transitionTo("idle")
        end
        
    elseif command == "/setgoal" then
        if goalHologram then
            goalHologram:Destroy()
        end
        
        if not humanoidRootPart then return end
        
        aiState.goalPosition = humanoidRootPart.Position
        StateMachine.transitionTo("idle")
        updateStatus("Goal Set", "Position: " .. math.floor(aiState.goalPosition.X) .. ", " .. math.floor(aiState.goalPosition.Y) .. ", " .. math.floor(aiState.goalPosition.Z))
        
        goalHologram = Instance.new("Part")
        goalHologram.Size = Vector3.new(8, 0.5, 8)
        goalHologram.Material = Enum.Material.Neon
        goalHologram.BrickColor = BrickColor.new("Bright blue")
        goalHologram.Anchored = true
        goalHologram.CanCollide = false
        goalHologram.Transparency = 0.5
        goalHologram.Position = aiState.goalPosition
        goalHologram.Parent = Workspace
        
        local beam = Instance.new("Beam")
        beam.Attachment0 = Instance.new("Attachment", goalHologram)
        beam.Attachment1 = Instance.new("Attachment", goalHologram)
        beam.Attachment1.Position = Vector3.new(0, 20, 0)
        beam.Color = ColorSequence.new(Color3.new(0, 1, 1))
        beam.Width0 = 1
        beam.Width1 = 0.1
        beam.FaceCamera = true
        beam.Parent = goalHologram
        
    elseif command == "/rungoal" then
        if aiState.goalPosition then
            StateMachine.transitionTo("idle")
            updateStatus("Running", "Moving to set goal with advanced parkour...")
            
            -- Enhanced path calculation for rungoal with trick optimization
            if humanoidRootPart then
                local directDistance = (humanoidRootPart.Position - aiState.goalPosition).Magnitude
                
                -- If goal is relatively close, use more aggressive trick approach
                if directDistance < 50 then
                    updateStatus("Running", "Using aggressive parkour approach")
                    CONFIG.TRICK_AGGRESSION = 0.9 -- Very high aggression for short distances
                else
                    CONFIG.TRICK_AGGRESSION = 0.8 -- High aggression for normal distances
                end
                
                moveToGoal()
            end
        else
            updateStatus("Error", "No goal set. Use /setgoal first.")
        end
        
    elseif command == "/trickstats" then
        local stats = TrickSystem.getTrickStatistics()
        updateStatus("Trick Stats", stats)
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[KYNEX] " .. stats;
            Color = Color3.new(0, 1, 1);
        })
        
    elseif command == "/clearmemory" then
        aiState.pathMemory.successfulPaths = {}
        aiState.pathMemory.failedWaypoints = {}
        aiState.pathMemory.efficientWaypoints = {}
        aiState.pathCache = {}
        updateStatus("Memory Cleared", "All path memory has been reset")
    else
        updateStatus("Error", "Unknown command.")
    end
end

-- Fixed updateStatus function to properly handle UI elements
local function updateStatus(status: string, details: string)
    -- First, update the aiState
    aiState.currentCommand = status
    
    -- Then, try to update the UI elements
    if UIState.elements.statusSidebar then
        local statusValue = UIState.elements.statusSidebar:FindFirstChild("StatusValue")
        local commandValue = UIState.elements.statusSidebar:FindFirstChild("CommandValue")
        local maneuverValue = UIState.elements.statusSidebar:FindFirstChild("ManeuverValue")
        local trickValue = UIState.elements.statusSidebar:FindFirstChild("TrickValue")
        
        if statusValue then 
            statusValue.Text = status 
        end
        
        if commandValue then 
            commandValue.Text = details 
        end
        
        if maneuverValue then 
            maneuverValue.Text = aiState.currentManeuver or "None"
        end
        
        if trickValue then 
            trickValue.Text = aiState.currentTrick or "None"
        end
    end
    
    -- Also log the status update
    ErrorHandler.log("INFO", "Status: %s - %s", status, details)
end

-- Main game loop with trick integration
RunService.Heartbeat:Connect(function()
    if not aiState.isRunning then return end
    
    local deltaTime = DeltaTimeManager.getDelta()
    
    StateMachine.update(deltaTime)
    
    -- Update trick detection continuously
    TrickSystem.detectWalls()
    
    if humanoidRootPart then
        local currentPosition = humanoidRootPart.Position
        local distanceMoved = (currentPosition - aiState.lastPosition).Magnitude
        
        if distanceMoved < 0.5 then
            aiState.stuckTimer += deltaTime
            if aiState.stuckTimer > CONFIG.STUCK_TIME_THRESHOLD then
                updateStatus("Stuck", "Recalculating path...")
                aiState.stuckTimer = 0
                
                if aiState.lastWaypointIndex > 0 and aiState.currentPath[aiState.lastWaypointIndex] then
                    MemorySystem.updatePathMemory(aiState.currentPath[aiState.lastWaypointIndex].Position, false)
                end
                
                if humanoid then
                    humanoid.Jump = true
                    task.wait(0.5)
                    moveToGoal()
                end
            end
        else
            aiState.stuckTimer = 0
        end
        
        aiState.lastPosition = currentPosition
    end
    
    performanceMonitor.frameCount += 1
    if performanceMonitor.frameCount % 60 == 0 then
        PerformanceMonitor.checkPerformance()
    end
end)

-- Initialize systems
UISystem.initialize()
