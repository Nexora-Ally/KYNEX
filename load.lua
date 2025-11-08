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

-- Enhanced configuration with advanced maneuvers
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
    
    -- Advanced maneuver settings
    LADDER_FLICK_JUMP_FORCE = 75,
    WALLHOP_JUMP_FORCE = 50,
    WRAP_AROUND_JUMP_FORCE = 60,
    WALL_DETECTION_DISTANCE = 8,
    LADDER_DETECTION_DISTANCE = 6,
    PILLAR_DETECTION_ANGLE = 45,
    
    MANEUVER_COOLDOWNS = {
        ladder_flick = 2,
        wallhop = 1.5,
        wrap_around = 2,
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

-- Enhanced AI State with maneuver tracking
local aiState = {
    isRunning = false,
    currentCommand = "Idle",
    targetPlayer = nil,
    goalPosition = nil,
    currentPath = {},
    pathPreviewModels = {},
    lastWaypointIndex = 0,
    stuckTimer = 0,
    lastPosition = humanoidRootPart.Position,
    pathCache = {},
    lastPathCalculation = 0,
    
    -- Advanced maneuver state
    currentManeuver = "None",
    maneuverData = {},
    maneuverCooldowns = {},
    maneuverPreview = nil,
    
    -- Environment detection
    nearbyLadders = {},
    nearbyWalls = {},
    nearbyPillars = {},
    
    pathMemory = {
        successfulPaths = {},
        failedWaypoints = {},
        efficientWaypoints = {},
        compressedPaths = {},
    },
    
    predictedPositions = {},
    
    state = "idle",
    stateHistory = {},
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
        
        if aiState.isRunning then
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
        local compressed = {}
        for _, waypoint in ipairs(waypoints) do
            table.insert(compressed, MemorySystem.hashWaypoint(waypoint.Position))
        end
        return table.concat(compressed, ";")
    end,
    
    decompressPath = function(compressedPath: string): {Vector3}
        local waypoints = {}
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

-- Advanced Parkour Maneuver System
local ParkourManeuvers = {
    -- Ladder Flick: Quick jump from ladder/truss with directional flick
    ladderFlick = {
        name = "Ladder Flick",
        color = Color3.fromRGB(255, 100, 0),
        cooldown = CONFIG.MANEUVER_COOLDOWNS.ladder_flick,
        
        canExecute = function(): boolean
            -- Check if near ladder/truss
            local origin = humanoidRootPart.Position
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            -- Check for vertical structures (ladders/trusses)
            for angle = 0, 360, 45 do
                local rad = math.rad(angle)
                local direction = Vector3.new(math.cos(rad), 0, math.sin(rad))
                local result = Workspace:Raycast(origin, direction * CONFIG.LADDER_DETECTION_DISTANCE, raycastParams)
                
                if result and result.Instance then
                    local part = result.Instance
                    -- Check if it's a ladder-like structure (thin vertical part)
                    if part.Size.Y > part.Size.X * 3 and part.Size.Y > part.Size.Z * 3 then
                        return true
                    end
                end
            end
            return false
        end,
        
        execute = function(targetDirection: Vector3?)
            local direction = targetDirection or humanoidRootPart.CFrame.LookVector
            aiState.currentManeuver = "ladder_flick"
            
            -- Apply powerful jump with directional flick
            humanoid.Jump = true
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                direction.X * CONFIG.LADDER_FLICK_JUMP_FORCE,
                CONFIG.LADDER_FLICK_JUMP_FORCE * 0.8,
                direction.Z * CONFIG.LADDER_FLICK_JUMP_FORCE
            )
            
            updateStatus("Maneuver", "Executing Ladder Flick")
            ParkourManeuvers.showManeuverPreview("ladder_flick", humanoidRootPart.Position, direction)
            
            return true
        end,
        
        getPreviewPoints = function(startPos: Vector3, direction: Vector3): {Vector3}
            local points = {}
            local steps = 10
            
            for i = 1, steps do
                local t = i / steps
                local height = math.sin(t * math.pi) * 8
                local forward = t * 15
                
                local point = startPos + 
                    direction * forward + 
                    Vector3.new(0, height, 0)
                
                table.insert(points, point)
            end
            
            return points
        end
    },
    
    -- Wall Hop: Rapid hopping between two walls
    wallHop = {
        name = "Wall Hop",
        color = Color3.fromRGB(0, 200, 255),
        cooldown = CONFIG.MANEUVER_COOLDOWNS.wallhop,
        
        canExecute = function(): boolean
            local origin = humanoidRootPart.Position
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local wallCount = 0
            local wallDirections = {}
            
            -- Check for walls in cardinal directions
            local directions = {
                Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
                Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
            }
            
            for _, dir in ipairs(directions) do
                local result = Workspace:Raycast(origin, dir * CONFIG.WALL_DETECTION_DISTANCE, raycastParams)
                if result and result.Instance then
                    wallCount += 1
                    table.insert(wallDirections, dir)
                end
            end
            
            return wallCount >= 2
        end,
        
        execute = function(): boolean
            aiState.currentManeuver = "wall_hop"
            aiState.maneuverData = {
                startTime = tick(),
                hopCount = 0,
                maxHops = 4
            }
            
            updateStatus("Maneuver", "Starting Wall Hop Sequence")
            ParkourManeuvers.showManeuverPreview("wall_hop", humanoidRootPart.Position)
            
            -- Start wall hop coroutine
            task.spawn(function()
                while aiState.currentManeuver == "wall_hop" and 
                      aiState.maneuverData.hopCount < aiState.maneuverData.maxHops do
                    
                    humanoid.Jump = true
                    
                    -- Alternate between left and right wall push
                    local sideForce = aiState.maneuverData.hopCount % 2 == 0 and 1 or -1
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                        sideForce * CONFIG.WALLHOP_JUMP_FORCE * 0.6,
                        CONFIG.WALLHOP_JUMP_FORCE,
                        0
                    )
                    
                    aiState.maneuverData.hopCount += 1
                    updateStatus("Maneuver", string.format("Wall Hop %d/%d", aiState.maneuverData.hopCount, aiState.maneuverData.maxHops))
                    
                    task.wait(0.3)
                end
                
                aiState.currentManeuver = "None"
            end)
            
            return true
        end,
        
        getPreviewPoints = function(startPos: Vector3): {Vector3}
            local points = {}
            local hops = 4
            
            for i = 1, hops do
                local side = i % 2 == 0 and 1 or -1
                local height = i * 3
                local sideOffset = side * 2
                
                local point = startPos + Vector3.new(sideOffset, height, 0)
                table.insert(points, point)
            end
            
            return points
        end
    },
    
    -- Wrap Around: Circular jump around pillars/walls
    wrapAround = {
        name = "Wrap Around",
        color = Color3.fromRGB(150, 0, 255),
        cooldown = CONFIG.MANEUVER_COOLDOWNS.wrap_around,
        
        canExecute = function(targetDirection: Vector3?): boolean
            local origin = humanoidRootPart.Position
            local direction = targetDirection or humanoidRootPart.CFrame.LookVector
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            -- Check for obstacle in front
            local frontResult = Workspace:Raycast(origin, direction * CONFIG.WALL_DETECTION_DISTANCE, raycastParams)
            if not frontResult then return false end
            
            -- Check if we can go around (side clearance)
            local sideDirections = {
                Vector3.new(direction.Z, 0, -direction.X),  -- Right
                Vector3.new(-direction.Z, 0, direction.X)   -- Left
            }
            
            for _, sideDir in ipairs(sideDirections) do
                local sideResult = Workspace:Raycast(origin, sideDir * 6, raycastParams)
                if not sideResult then
                    return true
                end
            end
            
            return false
        end,
        
        execute = function(targetDirection: Vector3?): boolean
            local direction = targetDirection or humanoidRootPart.CFrame.LookVector
            aiState.currentManeuver = "wrap_around"
            
            -- Determine wrap direction (prefer right side)
            local rightDir = Vector3.new(direction.Z, 0, -direction.X)
            local leftDir = Vector3.new(-direction.Z, 0, direction.X)
            
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local wrapDirection = rightDir
            if Workspace:Raycast(humanoidRootPart.Position, rightDir * 6, raycastParams) then
                wrapDirection = leftDir
            end
            
            -- Execute wrap around jump
            humanoid.Jump = true
            humanoidRootPart.AssemblyLinearVelocity = 
                wrapDirection * CONFIG.WRAP_AROUND_JUMP_FORCE + 
                Vector3.new(0, CONFIG.WRAP_AROUND_JUMP_FORCE * 0.7, 0)
            
            updateStatus("Maneuver", "Executing Wrap Around")
            ParkourManeuvers.showManeuverPreview("wrap_around", humanoidRootPart.Position, wrapDirection)
            
            return true
        end,
        
        getPreviewPoints = function(startPos: Vector3, direction: Vector3): {Vector3}
            local points = {}
            local steps = 12
            
            for i = 1, steps do
                local t = i / steps
                local angle = t * math.pi  -- 180 degree arc
                
                -- Circular motion around obstacle
                local x = math.cos(angle) * 4
                local z = math.sin(angle) * 4
                local height = math.sin(t * math.pi) * 5
                
                local point = startPos + 
                    Vector3.new(x, height, z) +
                    direction * 2
                
                table.insert(points, point)
            end
            
            return points
        end
    }
}

-- Maneuver Preview System
ParkourManeuvers.showManeuverPreview = function(maneuverType: string, startPos: Vector3, direction: Vector3?)
    -- Clear previous preview
    ParkourManeuvers.clearManeuverPreview()
    
    local maneuver = ParkourManeuvers[maneuverType:gsub("_", "")]
    if not maneuver then return end
    
    local points = maneuver.getPreviewPoints(startPos, direction or Vector3.new(0, 0, 1))
    
    local previewModel = Instance.new("Model")
    previewModel.Name = "ManeuverPreview_" .. maneuverType
    previewModel.Parent = Workspace
    
    -- Create trail of parts showing maneuver path
    for i = 1, #points do
        if i < #points then
            local point1, point2 = points[i], points[i+1]
            local distance = (point1 - point2).Magnitude
            
            local beam = Instance.new("Part")
            beam.Anchored = true
            beam.CanCollide = false
            beam.Material = Enum.Material.Neon
            beam.BrickColor = BrickColor.new(maneuver.color)
            beam.Transparency = 0.3
            beam.Size = Vector3.new(0.3, 0.3, distance)
            beam.CFrame = CFrame.new(point1, point2) * CFrame.new(0, 0, -distance / 2)
            beam.Parent = previewModel
            
            -- Add glow effect
            local pointLight = Instance.new("PointLight")
            pointLight.Brightness = 2
            pointLight.Range = 4
            pointLight.Color = maneuver.color
            pointLight.Parent = beam
        end
        
        -- Create position markers
        local marker = Instance.new("Part")
        marker.Anchored = true
        marker.CanCollide = false
        marker.Material = Enum.Material.Neon
        marker.BrickColor = BrickColor.new(maneuver.color)
        marker.Shape = Enum.PartType.Ball
        marker.Size = Vector3.new(0.8, 0.8, 0.8)
        marker.Position = points[i]
        marker.Parent = previewModel
    end
    
    aiState.maneuverPreview = previewModel
    
    -- Auto-cleanup after 5 seconds
    task.delay(5, function()
        if previewModel and previewModel.Parent then
            previewModel:Destroy()
        end
    end)
end

ParkourManeuvers.clearManeuverPreview = function()
    if aiState.maneuverPreview and aiState.maneuverPreview.Parent then
        aiState.maneuverPreview:Destroy()
    end
    aiState.maneuverPreview = nil
end

ParkourManeuvers.attemptManeuver = function(targetDirection: Vector3?): boolean
    -- Check cooldowns
    for maneuverName, cooldown in pairs(aiState.maneuverCooldowns) do
        if tick() - cooldown < CONFIG.MANEUVER_COOLDOWNS[maneuverName] then
            return false
        end
    end
    
    -- Try maneuvers in priority order
    if ParkourManeuvers.wrapAround.canExecute(targetDirection) then
        aiState.maneuverCooldowns.wrap_around = tick()
        return ParkourManeuvers.wrapAround.execute(targetDirection)
    elseif ParkourManeuvers.ladderFlick.canExecute(targetDirection) then
        aiState.maneuverCooldowns.ladder_flick = tick()
        return ParkourManeuvers.ladderFlick.execute(targetDirection)
    elseif ParkourManeuvers.wallHop.canExecute() then
        aiState.maneuverCooldowns.wallhop = tick()
        return ParkourManeuvers.wallHop.execute()
    end
    
    return false
end

-- State machine for AI behavior
local StateMachine = {
    states = {
        idle = {
            enter = function()
                aiState.currentCommand = "Idle"
                updateStatus("Idle", "Waiting for command...")
                ParkourManeuvers.clearManeuverPreview()
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
                ParkourManeuvers.clearManeuverPreview()
            end
        },
        
        advanced_parkour = {
            enter = function()
                aiState.currentCommand = "Advanced Parkour"
                updateStatus("Advanced Parkour", "Executing parkour maneuvers")
            end,
            update = function(deltaTime)
                -- In advanced parkour mode, actively look for maneuver opportunities
                if ParkourManeuvers.attemptManeuver() then
                    updateStatus("Advanced Parkour", "Executing: " .. aiState.currentManeuver)
                end
            end,
            exit = function()
                ParkourManeuvers.clearManeuverPreview()
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
            "Loading Advanced Maneuvers..."
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
        injectDesc.Text = "An adaptive AI who can complete parkour, learn from the environment, and predict player movements! Now with advanced maneuvers: Ladder Flicks, Wall Hops, and Wrap Arounds!"
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
        
        local toggleButton = UISystem.createStyledTextButton("Hide", UDim2.new(1, 0, 0, 40), 8)
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
        commandTextBox.PlaceholderText = "Enter command (e.g., /follow PlayerName, /smartparkour, /advanced)"
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
        
        -- Advanced maneuver buttons
        local advancedFrame = Instance.new("Frame")
        advancedFrame.Name = "AdvancedControls"
        advancedFrame.Size = UDim2.new(0, 150 * CONFIG.MOBILE_SCALE, 0, 50 * CONFIG.MOBILE_SCALE)
        advancedFrame.Position = UDim2.new(0, 20, 1, -280 * CONFIG.MOBILE_SCALE)
        advancedFrame.BackgroundTransparency = 1
        advancedFrame.Parent = parent
        
        local ladderButton = UISystem.createStyledTextButton("Ladder", UDim2.new(0, 70 * CONFIG.MOBILE_SCALE, 1, 0), 1)
        ladderButton.Position = UDim2.new(0, 0, 0, 0)
        ladderButton.BackgroundColor3 = ParkourManeuvers.ladderFlick.color
        ladderButton.Parent = advancedFrame
        
        ladderButton.MouseButton1Click:Connect(function()
            ParkourManeuvers.ladderFlick.execute()
        end)
        
        local wallhopButton = UISystem.createStyledTextButton("WallHop", UDim2.new(0, 70 * CONFIG.MOBILE_SCALE, 1, 0), 2)
        wallhopButton.Position = UDim2.new(0, 80 * CONFIG.MOBILE_SCALE, 0, 0)
        wallhopButton.BackgroundColor3 = ParkourManeuvers.wallHop.color
        wallhopButton.Parent = advancedFrame
        
        wallhopButton.MouseButton1Click:Connect(function()
            ParkourManeuvers.wallHop.execute()
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

-- Obstacle Analysis Functions
local function analyzeObstacle(direction: Vector3): string
    local origin = humanoidRootPart.Position
    local lookDirection = direction.Unit
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
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

-- Enhanced Parkour Functions
local function analyzeParkourChain(): {Vector3}
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

local function moveToGoal()
    if not aiState.goalPosition or not aiState.isRunning then return end
    
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
        
        -- Check for advanced maneuvers first
        if ParkourManeuvers.attemptManeuver(direction) then
            task.wait(1)
            moveToGoal()
            return
        end
        
        if obstacleType ~= "none" and aiState.currentManeuver == "None" then
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
                    if (humanoidRootPart.Position - checkpoints[i]).Magnitude < 5 then
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
            updateStatus("Running", "Moving to set goal...")
            moveToGoal()
        else
            updateStatus("Error", "No goal set. Use /setgoal first.")
        end
        
    elseif command == "/advanced" then
        StateMachine.transitionTo("advanced_parkour")
        updateStatus("Advanced Parkour", "Activated - will use advanced maneuvers")
        
    elseif command == "/ladderflick" then
        if ParkourManeuvers.ladderFlick.execute() then
            updateStatus("Maneuver", "Executing Ladder Flick")
        else
            updateStatus("Maneuver", "Cannot execute Ladder Flick - conditions not met")
        end
        
    elseif command == "/wallhop" then
        if ParkourManeuvers.wallHop.execute() then
            updateStatus("Maneuver", "Executing Wall Hop")
        else
            updateStatus("Maneuver", "Cannot execute Wall Hop - conditions not met")
        end
        
    elseif command == "/wraparound" then
        if ParkourManeuvers.wrapAround.execute() then
            updateStatus("Maneuver", "Executing Wrap Around")
        else
            updateStatus("Maneuver", "Cannot execute Wrap Around - conditions not met")
        end
        
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

local function updateStatus(status: string, details: string)
    if UIState.elements.statusSidebar then
        local statusValue = UIState.elements.statusSidebar:FindFirstChild("StatusValue")
        local commandValue = UIState.elements.statusSidebar:FindFirstChild("CommandValue")
        local maneuverValue = UIState.elements.statusSidebar:FindFirstChild("ManeuverValue")
        
        if statusValue then statusValue.Text = status end
        if commandValue then commandValue.Text = details end
        if maneuverValue then maneuverValue.Text = aiState.currentManeuver end
    end
end

-- Main game loop
RunService.Heartbeat:Connect(function()
    if not aiState.isRunning then return end
    
    local deltaTime = DeltaTimeManager.getDelta()
    
    StateMachine.update(deltaTime)
    
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
            
            humanoid.Jump = true
            task.wait(0.5)
            moveToGoal()
        end
    else
        aiState.stuckTimer = 0
    end
    
    aiState.lastPosition = currentPosition
    
    performanceMonitor.frameCount += 1
    if performanceMonitor.frameCount % 60 == 0 then
        PerformanceMonitor.checkPerformance()
    end
end)

-- Initialize systems
UISystem.initialize()
