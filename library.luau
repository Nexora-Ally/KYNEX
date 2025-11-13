local KynexFind = {
    Version = "V2.0.0 - NEURAL PARKOUR MASTER",
    Author = "Kynex Team",
    _initialized = false,
    _stabilityLevel = "maximum",
    _performanceMetrics = {
        totalSearches = 0,
        cacheHits = 0,
        failedSearches = 0,
        averageSearchTime = 0,
        peakSearchTime = 0,
        recoveryAttempts = 0,
        stabilityScore = 100,
        neuralPredictions = 0,
        neuralAccuracy = 0,
        smallObjectDetectionCount = 0,
        smallObjectAccuracy = 0,
        movingObjectsTracked = 0,
        memoryCleanupCount = 0,
        circuitBreakerTrips = 0,
        rateLimitHits = 0,
        deferredOperations = 0,
        parkourManeuvers = 0,
        obstaclesDetected = 0,
        advancedTechniques = {
            ladderFlicks = 0,
            wallhops = 0,
            wrapArounds = 0,
            cornerClimbs = 0,
            techniqueChains = 0,
            failedAdvancedManeuvers = 0,
            stylePoints = 0,
            flowStateDuration = 0,
            momentumPreservation = 0
        }
    }
}

local CONFIG = {
    MAX_NODES = 15000,
    CACHE_SIZE = 300,
    MAX_SMOOTHING_ITERATIONS = 5,
    PATH_REUSE_DISTANCE = 15,
    PREDICTION_LOOKAHEAD = 8,
    LEARNING_SAMPLE_SIZE = 200,
    PARALLEL_PROCESSORS = 5,
    NEURAL_HIDDEN_LAYERS = 3,
    NEURAL_LEARNING_RATE = 0.015,
    
    MAX_SEARCH_TIME = 15,
    MEMORY_CLEANUP_INTERVAL = 20,
    ERROR_RETRY_ATTEMPTS = 3,
    GRACE_PERIOD_AFTER_ERROR = 2,
    MAX_RECURSION_DEPTH = 2000,
    RESOURCE_MONITORING = true,
    AUTOMATIC_RECOVERY = true,
    STATE_CONSISTENCY_CHECKS = true,
    FALLBACK_MECHANISMS = true,
    
    MAX_MEMORY_USAGE_MB = 75,
    MEMORY_CLEANUP_THRESHOLD = 0.8,
    CACHE_PRUNING_INTERVAL = 30,
    
    CIRCUIT_BREAKER_THRESHOLD = 10,
    CIRCUIT_BREAKER_TIMEOUT = 30,
    CIRCUIT_BREAKER_HALF_OPEN_TIMEOUT = 10,
    
    RATE_LIMIT_REQUESTS_PER_MINUTE = 150,
    RATE_LIMIT_WINDOW_SIZE = 60,
    
    MAX_REQUESTS_PER_FRAME = 8,
    FRAME_BUDGET_MS = 8,
    
    DEFAULT_AGENT_PROFILES = {
        humanoid = { radius = 2, height = 5, jumpHeight = 3, maxSlope = 45 },
        vehicle = { radius = 3, height = 2, jumpHeight = 0, maxSlope = 30 },
        flying = { radius = 2, height = 2, jumpHeight = math.huge, maxSlope = 90 },
        parkour = { 
            radius = 2, 
            height = 5, 
            jumpHeight = 12, 
            maxSlope = 85,
            specialAbilities = {
                wallRun = true,
                ledgeGrab = true,
                vault = true,
                roll = true,
                climb = true,
                ladderFlick = true,
                wallhop = true,
                wrapAround = true,
                cornerClimb = true
            }
        },
        parkour_master = {
            radius = 1.5,
            height = 5,
            jumpHeight = 15,
            maxSlope = 90,
            specialAbilities = {
                wallRun = true,
                ledgeGrab = true,
                vault = true,
                roll = true,
                climb = true,
                ladderFlick = true,
                wallhop = true,
                wrapAround = true,
                cornerClimb = true,
                momentumPreservation = 0.85,
                styleMastery = 0.9,
                techniqueChaining = 5
            }
        }
    },
    
    MULTI_RES_GRID = {
        fine = { size = 0.5, use_for = "small_objects" },
        medium = { size = 2, use_for = "normal_navigation" },
        coarse = { size = 5, use_for = "long_distance" }
    },
    
    PARKOUR_CONFIG = {
        JUMP_VELOCITY = 50,
        CLIMB_VELOCITY = 25,
        VAULT_HEIGHT = 6,
        LEDGE_GRAB_HEIGHT = 8,
        WALL_RUN_DURATION = 2,
        ROLL_DISTANCE = 10,
        
        LEDGE_DETECTION_RANGE = 8,
        WALL_DETECTION_RANGE = 6,
        VAULT_DETECTION_RANGE = 5,
        
        JUMP_COOLDOWN = 0.5,
        CLIMB_COOLDOWN = 1.0,
        WALL_RUN_COOLDOWN = 1.5,
        
        GRAVITY = 196.2,
        TERMINAL_VELOCITY = 100,
        
        PARKOUR_MOVEMENT_SPEED = 24,
        ARRIVAL_DISTANCE = 3,
        WAYPOINT_TOLERANCE = 4,
        
        -- Advanced Techniques V2.0
        LADDER_FLICK_VELOCITY = 35,
        WALLHOP_VELOCITY = 28,
        WRAP_AROUND_VELOCITY = 32,
        CORNER_CLIMB_VELOCITY = 18,
        
        MOMENTUM_PRESERVATION_THRESHOLD = 0.75,
        ENERGY_EXPENDITURE_CAPACITY = 0.4,
        FLOW_STATE_THRESHOLD = 0.8,
        STYLE_SCORE_THRESHOLD = 8.0,
        
        TECHNIQUE_SUCCESS_PROBABILITY = 0.9,
        CHAIN_LENGTH_TARGET = 3,
        VELOCITY_RETENTION_TARGET = 0.85,
        CORNER_CLIMB_TIME_TARGET = 2.0
    },
    
    ADVANCED_TECHNIQUES = {
        LADDER_FLICK = {
            MIN_LADDER_HEIGHT = 8,
            REQUIRED_CLEARANCE = 5,
            OPTIMAL_ASCENT_ANGLE = 75,
            MOMENTUM_TRANSFER_EFFICIENCY = 0.9,
            STYLE_POINTS = 3
        },
        
        WALLHOP = {
            MAX_WALL_SPACING = 10,
            CHAIN_LENGTH_TARGET = 3,
            SIDE_HOP_ANGLE = 45,
            UPWARD_HOP_ANGLE = 70,
            MOMENTUM_TRANSFER = 0.85,
            STYLE_POINTS = 4
        },
        
        WRAP_AROUND = {
            MAX_CORNER_ANGLE = 100,
            MIN_VELOCITY = 15,
            CENTRIFUGAL_FORCE_FACTOR = 1.2,
            VELOCITY_PRESERVATION_TARGET = 0.85,
            STYLE_POINTS = 2
        },
        
        CORNER_CLIMB = {
            MIN_CORNER_DEPTH = 3,
            REQUIRED_ADJACENT_SUPPORT = true,
            DIAGONAL_ENGAGEMENT_ANGLE = 45,
            GRIP_STABILITY_THRESHOLD = 0.8,
            STYLE_POINTS = 3
        }
    }
}

-- Helper functions (made local to avoid global pollution)
local function EuclideanDistance(a, b)
    if not a or not b or typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then 
        return math.huge 
    end
    return (a - b).Magnitude
end

local function Lerp(a, b, t)
    if a ~= a or b ~= b or t ~= t then return a end
    return a + (b - a) * math.clamp(t, 0, 1)
end

local function Vector3ToKey(vec, gridSize)
    if not vec or typeof(vec) ~= "Vector3" then return "0,0,0" end
    if not gridSize or gridSize <= 0 then gridSize = 1 end
    
    local x, y, z = vec.X, vec.Y, vec.Z
    if x ~= x then x = 0 end
    if y ~= y then y = 0 end
    if z ~= z then z = 0 end
    
    if math.abs(x) == math.huge then x = 0 end
    if math.abs(y) == math.huge then y = 0 end
    if math.abs(z) == math.huge then z = 0 end
    
    return string.format("%d,%d,%d", 
        math.floor(x / gridSize), 
        math.floor(y / gridSize), 
        math.floor(z / gridSize)
    )
end

local function SafeDivide(numerator, denominator, default)
    if denominator == 0 or denominator ~= denominator then
        return default or 0
    end
    return numerator / denominator
end

local ParkourSystem = {
    _activeManeuvers = {},
    _characterStates = {},
    _obstacleCache = {},
    _lastManeuverTime = 0,
    _environmentScanCooldown = 0,
    _autoMovementCharacters = {},
    _techniqueHistory = {},
    _flowStateStartTime = 0,
    _currentFlowState = 0,
    _momentumTracker = {},
    _styleScore = 0,
    _techniqueChain = {},
    _advancedOpportunities = {},
    _lastFlowUpdate = 0
}

-- Safe Region3 creation function
function ParkourSystem:CreateSafeRegion3(center, size)
    local min = center - size/2
    local max = center + size/2
    return Region3.new(
        Vector3.new(math.min(min.X, max.X), math.min(min.Y, max.Y), math.min(min.Z, max.Z)),
        Vector3.new(math.max(min.X, max.X), math.max(min.Y, max.Y), math.max(min.Z, max.Z))
    )
end

-- Safe RaycastParams creation
function ParkourSystem:CreateRaycastParams(ignoreList)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = ignoreList or {}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.RespectCanCollide = true
    return params
end

-- Safe character component access
function ParkourSystem:GetCharacterHumanoid(character)
    if not character or not character.Parent then return nil end
    return character:FindFirstChild("Humanoid")
end

function ParkourSystem:GetCharacterRootPart(character)
    if not character or not character.Parent then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

-- Enhanced movement philosophy implementation
function ParkourSystem:GetMovementPhilosophy()
    return {
        philosophy = "Movement is not just reaching the destination - it's the art of how you get there. Every surface is an opportunity, every obstacle is an invitation for creativity.",
        corePrinciples = {
            "Velocity preservation is paramount",
            "Energy efficiency enables sustained performance", 
            "Style emerges from flawless execution",
            "Flow state is the ultimate goal",
            "Every obstacle is a creative opportunity"
        }
    }
end

-- Advanced technique detection and analysis
function ParkourSystem:ScanForAdvancedOpportunities(character, goalPosition)
    local opportunities = {
        ladderFlicks = {},
        wallhops = {},
        wrapArounds = {},
        cornerClimbs = {}
    }
    
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    if not abdomenPos then return opportunities end
    
    -- Ladder Flick Detection
    opportunities.ladderFlicks = self:DetectLadderFlickOpportunities(abdomenPos, goalPosition)
    
    -- Wallhop Detection  
    opportunities.wallhops = self:DetectWallhopOpportunities(abdomenPos, goalPosition)
    
    -- Wrap Around Detection
    opportunities.wrapArounds = self:DetectWrapAroundOpportunities(abdomenPos, goalPosition)
    
    -- Corner Climb Detection
    opportunities.cornerClimbs = self:DetectCornerClimbOpportunities(abdomenPos, goalPosition)
    
    self._advancedOpportunities[character] = opportunities
    return opportunities
end

function ParkourSystem:DetectLadderFlickOpportunities(position, goal)
    local ladders = {}
    
    -- Find ladder parts in workspace using safe region
    local region = self:CreateSafeRegion3(position, Vector3.new(40, 30, 40))
    local ladderParts = workspace:FindPartsInRegion3(region, nil, 50)
    
    for _, part in ipairs(ladderParts) do
        -- Multiple ways to identify ladders
        local isLadder = part.Name:lower():find("ladder") or 
                        part:IsA("TrussPart") or
                        part.Material == Enum.Material.Plastic or
                        part.BrickColor == BrickColor.new("Bright blue")
        
        if isLadder then
            local ladderTop = part.Position + Vector3.new(0, part.Size.Y/2, 0)
            local ladderHeight = part.Size.Y
            
            if ladderHeight >= CONFIG.ADVANCED_TECHNIQUES.LADDER_FLICK.MIN_LADDER_HEIGHT then
                -- Check for clear landing zone with safe raycast
                local params = self:CreateRaycastParams()
                local landingCheck = workspace:Raycast(
                    ladderTop + Vector3.new(0, 2, 0),
                    Vector3.new(0, 5, 0),
                    params
                )
                
                if not landingCheck then
                    local goalDirection = (goal - position).Unit
                    local upwardComponent = math.abs(goalDirection.Y)
                    
                    if upwardComponent > 0.3 then -- Goal is upward
                        table.insert(ladders, {
                            type = "ladder_flick",
                            position = part.Position,
                            topPosition = ladderTop,
                            height = ladderHeight,
                            efficiencyScore = self:CalculateLadderFlickEfficiency(position, goal, ladderTop),
                            styleBonus = CONFIG.ADVANCED_TECHNIQUES.LADDER_FLICK.STYLE_POINTS,
                            priority = 9
                        })
                    end
                end
            end
        end
    end
    
    return ladders
end

function ParkourSystem:DetectWallhopOpportunities(position, goal)
    local wallhops = {}
    
    local scanRadius = 15
    local region = self:CreateSafeRegion3(position, Vector3.new(scanRadius * 2, scanRadius * 2, scanRadius * 2))
    local wallParts = workspace:FindPartsInRegion3(region, nil, 100)
    
    local walls = {}
    for _, part in ipairs(wallParts) do
        if part.Size.Y > part.Size.X * 1.5 and part.Size.Y > part.Size.Z * 1.5 then
            table.insert(walls, part)
        end
    end
    
    -- Find wall chains for consecutive hops
    for i, wall1 in ipairs(walls) do
        for j, wall2 in ipairs(walls) do
            if i ~= j then
                local distance = (wall1.Position - wall2.Position).Magnitude
                if distance <= CONFIG.ADVANCED_TECHNIQUES.WALLHOP.MAX_WALL_SPACING then
                    local chainPotential = self:CalculateWallhopChainPotential(wall1, wall2, position, goal)
                    if chainPotential > 0.7 then
                        table.insert(wallhops, {
                            type = "wallhop_chain",
                            walls = {wall1, wall2},
                            chainLength = 2,
                            efficiencyScore = chainPotential,
                            styleBonus = CONFIG.ADVANCED_TECHNIQUES.WALLHOP.STYLE_POINTS,
                            priority = 8
                        })
                    end
                end
            end
        end
    end
    
    return wallhops
end

function ParkourSystem:DetectWrapAroundOpportunities(position, goal)
    local wrapArounds = {}
    
    local currentVelocity = self:GetCharacterVelocity(position)
    if currentVelocity.Magnitude < CONFIG.ADVANCED_TECHNIQUES.WRAP_AROUND.MIN_VELOCITY then
        return wrapArounds
    end
    
    -- Detect sharp corners in the environment
    local cornerDetectionRange = 20
    local corners = self:FindSharpCorners(position, goal, cornerDetectionRange)
    
    for _, corner in ipairs(corners) do
        if corner.angle <= CONFIG.ADVANCED_TECHNIQUES.WRAP_AROUND.MAX_CORNER_ANGLE then
            local preservationScore = self:CalculateVelocityPreservation(position, goal, corner)
            if preservationScore > CONFIG.ADVANCED_TECHNIQUES.WRAP_AROUND.VELOCITY_PRESERVATION_TARGET then
                table.insert(wrapArounds, {
                    type = "wrap_around",
                    corner = corner,
                    velocityPreservation = preservationScore,
                    efficiencyScore = preservationScore * 1.2, -- Bonus for speed
                    styleBonus = CONFIG.ADVANCED_TECHNIQUES.WRAP_AROUND.STYLE_POINTS,
                    priority = 7
                })
            end
        end
    end
    
    return wrapArounds
end

function ParkourSystem:DetectCornerClimbOpportunities(position, goal)
    local cornerClimbs = {}
    
    -- Find deep corners (L-shaped geometry)
    local deepCorners = self:FindDeepCorners(position, 15)
    
    for _, corner in ipairs(deepCorners) do
        local verticalGain = goal.Y - position.Y
        if verticalGain > 3 then -- Only if we need upward movement
            local adjacentSupport = self:CheckAdjacentWallSupport(corner.position, 5)
            
            if adjacentSupport and CONFIG.ADVANCED_TECHNIQUES.CORNER_CLIMB.REQUIRED_ADJACENT_SUPPORT then
                local efficiency = self:CalculateCornerClimbEfficiency(position, goal, corner)
                if efficiency > 0.6 then
                    table.insert(cornerClimbs, {
                        type = "corner_climb",
                        corner = corner,
                        verticalGain = verticalGain,
                        efficiencyScore = efficiency,
                        styleBonus = CONFIG.ADVANCED_TECHNIQUES.CORNER_CLIMB.STYLE_POINTS,
                        priority = 7
                    })
                end
            end
        end
    end
    
    return cornerClimbs
end

-- Technique efficiency calculations
function ParkourSystem:CalculateLadderFlickEfficiency(startPos, goalPos, ladderTop)
    local directDistance = (goalPos - startPos).Magnitude
    local viaLadderDistance = (ladderTop - startPos).Magnitude + (goalPos - ladderTop).Magnitude
    
    local distanceEfficiency = SafeDivide(directDistance, viaLadderDistance, 1.0)
    local heightAdvantage = SafeDivide((ladderTop.Y - startPos.Y), 20, 0)
    local goalAlignment = (goalPos - ladderTop).Unit:Dot((goalPos - startPos).Unit)
    
    return (distanceEfficiency * 0.4 + heightAdvantage * 0.4 + goalAlignment * 0.2)
end

function ParkourSystem:CalculateWallhopChainPotential(wall1, wall2, position, goal)
    local chainVector = (wall2.Position - wall1.Position)
    local goalDirection = (goal - position).Unit
    
    local alignment = chainVector.Unit:Dot(goalDirection)
    local distanceEfficiency = 1 - SafeDivide(chainVector.Magnitude, CONFIG.ADVANCED_TECHNIQUES.WALLHOP.MAX_WALL_SPACING, 1)
    
    return alignment * 0.6 + distanceEfficiency * 0.4
end

function ParkourSystem:CalculateVelocityPreservation(position, goal, corner)
    local currentVel = self:GetCharacterVelocity(position)
    local cornerExitDir = (goal - corner.position).Unit
    local velocityAlignment = currentVel.Unit:Dot(cornerExitDir)
    
    local centrifugalBonus = math.min(1.0, currentVel.Magnitude / 30) * CONFIG.ADVANCED_TECHNIQUES.WRAP_AROUND.CENTRIFUGAL_FORCE_FACTOR
    
    return math.clamp(velocityAlignment * centrifugalBonus, 0, 1)
end

function ParkourSystem:CalculateCornerClimbEfficiency(startPos, goalPos, corner)
    local verticalEfficiency = math.min(1.0, SafeDivide((goalPos.Y - startPos.Y), 20, 0))
    local diagonalEngagement = math.abs((corner.normal1 + corner.normal2).Unit.Y)
    local gripStability = self:CalculateGripStability(corner.position)
    
    return verticalEfficiency * 0.5 + diagonalEngagement * 0.3 + gripStability * 0.2
end

-- Core decision matrix for technique selection
function ParkourSystem:SelectOptimalTechnique(character, goalPosition)
    local opportunities = self:ScanForAdvancedOpportunities(character, goalPosition)
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    
    if not abdomenPos then return nil end
    
    local allTechniques = {}
    
    -- Compile all available techniques
    for _, flick in ipairs(opportunities.ladderFlicks) do
        table.insert(allTechniques, flick)
    end
    
    for _, hop in ipairs(opportunities.wallhops) do
        table.insert(allTechniques, hop)
    end
    
    for _, wrap in ipairs(opportunities.wrapArounds) do
        table.insert(allTechniques, wrap)
    end
    
    for _, climb in ipairs(opportunities.cornerClimbs) do
        table.insert(allTechniques, climb)
    end
    
    -- Decision matrix analysis
    local bestTechnique = nil
    local bestScore = -math.huge
    
    for _, technique in ipairs(allTechniques) do
        local score = self:CalculateTechniqueScore(technique, character, goalPosition)
        
        if score > bestScore then
            bestScore = score
            bestTechnique = technique
        end
    end
    
    -- Consider technique chaining
    if bestTechnique and #self._techniqueChain > 0 then
        local chainBonus = self:CalculateChainBonus(bestTechnique.type)
        bestScore = bestScore + chainBonus
    end
    
    -- Success probability check
    local successProb = self:PredictTechniqueSuccess(bestTechnique, character)
    if successProb < CONFIG.PARKOUR_CONFIG.TECHNIQUE_SUCCESS_PROBABILITY then
        -- Fall back to next best technique with adequate success probability
        for _, technique in ipairs(allTechniques) do
            local altSuccessProb = self:PredictTechniqueSuccess(technique, character)
            local altScore = self:CalculateTechniqueScore(technique, character, goalPosition)
            
            if altSuccessProb >= CONFIG.PARKOUR_CONFIG.TECHNIQUE_SUCCESS_PROBABILITY and altScore > bestScore * 0.8 then
                bestTechnique = technique
                bestScore = altScore
                break
            end
        end
    end
    
    return bestTechnique, bestScore, successProb
end

function ParkourSystem:CalculateTechniqueScore(technique, character, goalPosition)
    local baseScore = technique.efficiencyScore or 0
    local styleBonus = technique.styleBonus or 0
    local priorityBonus = (technique.priority or 5) * 0.5
    
    -- Momentum preservation consideration
    local momentumScore = self:CalculateMomentumPreservation(technique, character)
    
    -- Energy efficiency consideration
    local energyScore = self:CalculateEnergyEfficiency(technique)
    
    -- Flow state consideration
    local flowBonus = self._currentFlowState * 0.3
    
    -- Style mastery consideration
    local styleMastery = self:GetCharacterStyleMastery(character)
    
    local finalScore = baseScore * 0.4 +
                     styleBonus * 0.2 +
                     priorityBonus * 0.1 +
                     momentumScore * 0.15 +
                     energyScore * 0.1 +
                     flowBonus * 0.05
    
    return finalScore * styleMastery
end

function ParkourSystem:PredictTechniqueSuccess(technique, character)
    if not technique then return 0 end
    
    local baseSuccess = 0.9
    local characterSkill = self:GetCharacterSkillLevel(character)
    local flowStateBonus = self._currentFlowState * 0.1
    
    -- Technique-specific success modifiers
    local techniqueModifiers = {
        ladder_flick = 0.95,
        wallhop_chain = 0.85,
        wrap_around = 0.88,
        corner_climb = 0.82
    }
    
    local techniqueModifier = techniqueModifiers[technique.type] or 0.9
    
    return math.min(0.98, baseSuccess * techniqueModifier * characterSkill + flowStateBonus)
end

-- Advanced technique execution
function ParkourSystem:ExecuteLadderFlick(character, ladderData)
    local humanoid = self:GetCharacterHumanoid(character)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoid or not humanoidRootPart then
        return false
    end
    
    -- Safety check for anchored parts
    if humanoidRootPart.Anchored then
        return false
    end
    
    -- Calculate optimal flick direction and velocity
    local flickDirection = (ladderData.topPosition - humanoidRootPart.Position).Unit
    flickDirection = Vector3.new(flickDirection.X, 0.7, flickDirection.Z).Unit
    
    local flickVelocity = flickDirection * CONFIG.PARKOUR_CONFIG.LADDER_FLICK_VELOCITY
    flickVelocity = flickVelocity + Vector3.new(0, CONFIG.PARKOUR_CONFIG.JUMP_VELOCITY * 0.8, 0)
    
    -- Execute the flick
    humanoid.PlatformStand = true
    humanoidRootPart.Velocity = flickVelocity
    
    -- Record technique execution
    self:RecordTechniqueExecution(character, "ladder_flick", ladderData)
    KynexFind._performanceMetrics.advancedTechniques.ladderFlicks = KynexFind._performanceMetrics.advancedTechniques.ladderFlicks + 1
    
    -- Reset platform stand after maneuver with safety check
    KynexFind:ProtectedDelay(1.0, function()
        if character and character.Parent then
            local currentHumanoid = character:FindFirstChild("Humanoid")
            if currentHumanoid then
                currentHumanoid.PlatformStand = false
            end
        end
    end)
    
    return true
end

function ParkourSystem:ExecuteWallhopChain(character, wallhopData)
    local humanoid = self:GetCharacterHumanoid(character)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoid or not humanoidRootPart then
        return false
    end
    
    -- Safety check for anchored parts
    if humanoidRootPart.Anchored then
        return false
    end
    
    local walls = wallhopData.walls
    
    if not walls or #walls < 2 then return false end
    
    -- Calculate hop sequence
    local hopVectors = {}
    for i = 1, #walls - 1 do
        local hopDir = (walls[i+1].Position - walls[i].Position).Unit
        table.insert(hopVectors, hopDir)
    end
    
    -- Execute first hop
    local firstHopVelocity = hopVectors[1] * CONFIG.PARKOUR_CONFIG.WALLHOP_VELOCITY
    firstHopVelocity = firstHopVelocity + Vector3.new(0, 8, 0) -- Upward component
    
    humanoidRootPart.Velocity = firstHopVelocity
    
    -- Schedule subsequent hops with safety checks
    for i = 2, #hopVectors do
        KynexFind:ProtectedDelay(i * 0.3, function()
            if character and character.Parent then
                local currentRootPart = character:FindFirstChild("HumanoidRootPart")
                if currentRootPart and not currentRootPart.Anchored then
                    local nextHopVelocity = hopVectors[i] * CONFIG.PARKOUR_CONFIG.WALLHOP_VELOCITY * 0.9
                    nextHopVelocity = nextHopVelocity + Vector3.new(0, 6, 0)
                    currentRootPart.Velocity = nextHopVelocity
                end
            end
        end)
    end
    
    self:RecordTechniqueExecution(character, "wallhop_chain", wallhopData)
    KynexFind._performanceMetrics.advancedTechniques.wallhops = KynexFind._performanceMetrics.advancedTechniques.wallhops + 1
    
    return true
end

function ParkourSystem:ExecuteWrapAround(character, wrapData)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoidRootPart then
        return false
    end
    
    -- Safety check for anchored parts
    if humanoidRootPart.Anchored then
        return false
    end
    
    local corner = wrapData.corner
    
    -- Calculate wrap trajectory using centrifugal force
    local currentVel = humanoidRootPart.Velocity
    local cornerNormal = (corner.normal1 + corner.normal2).Unit
    local centrifugalForce = currentVel - cornerNormal * currentVel:Dot(cornerNormal) * 2
    
    local wrapVelocity = centrifugalForce * CONFIG.ADVANCED_TECHNIQUES.WRAP_AROUND.CENTRIFUGAL_FORCE_FACTOR
    wrapVelocity = Vector3.new(wrapVelocity.X, math.max(5, wrapVelocity.Y), wrapVelocity.Z)
    
    humanoidRootPart.Velocity = wrapVelocity
    
    self:RecordTechniqueExecution(character, "wrap_around", wrapData)
    KynexFind._performanceMetrics.advancedTechniques.wrapArounds = KynexFind._performanceMetrics.advancedTechniques.wrapArounds + 1
    
    return true
end

function ParkourSystem:ExecuteCornerClimb(character, climbData)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoidRootPart then
        return false
    end
    
    -- Safety check for anchored parts
    if humanoidRootPart.Anchored then
        return false
    end
    
    local corner = climbData.corner
    
    -- Calculate diagonal climb vector
    local climbDirection = (corner.normal1 + corner.normal2).Unit
    climbDirection = Vector3.new(climbDirection.X, 0.8, climbDirection.Z).Unit
    
    local climbVelocity = climbDirection * CONFIG.PARKOUR_CONFIG.CORNER_CLIMB_VELOCITY
    climbVelocity = climbVelocity + Vector3.new(0, CONFIG.PARKOUR_CONFIG.CLIMB_VELOCITY * 0.6, 0)
    
    humanoidRootPart.Velocity = climbVelocity
    
    self:RecordTechniqueExecution(character, "corner_climb", climbData)
    KynexFind._performanceMetrics.advancedTechniques.cornerClimbs = KynexFind._performanceMetrics.advancedTechniques.cornerClimbs + 1
    
    return true
end

-- Flow state management
function ParkourSystem:UpdateFlowState(character, techniqueSuccess, momentumPreserved)
    local currentTime = os.clock()
    
    if techniqueSuccess and momentumPreserved then
        if self._currentFlowState == 0 then
            self._flowStateStartTime = currentTime
        end
        
        self._currentFlowState = math.min(1.0, self._currentFlowState + 0.1)
        
        -- Calculate style points
        local stylePoints = 0
        if techniqueSuccess then
            stylePoints = stylePoints + 2
        end
        if momentumPreserved > CONFIG.PARKOUR_CONFIG.MOMENTUM_PRESERVATION_THRESHOLD then
            stylePoints = stylePoints + 1
        end
        if #self._techniqueChain >= CONFIG.PARKOUR_CONFIG.CHAIN_LENGTH_TARGET then
            stylePoints = stylePoints + 2
        end
        
        self._styleScore = self._styleScore + stylePoints
        KynexFind._performanceMetrics.advancedTechniques.stylePoints = KynexFind._performanceMetrics.advancedTechniques.stylePoints + stylePoints
    else
        self._currentFlowState = math.max(0, self._currentFlowState - 0.2)
    end
    
    -- Update flow duration
    if self._currentFlowState > CONFIG.PARKOUR_CONFIG.FLOW_STATE_THRESHOLD then
        KynexFind._performanceMetrics.advancedTechniques.flowStateDuration = 
            KynexFind._performanceMetrics.advancedTechniques.flowStateDuration + (currentTime - self._lastFlowUpdate)
    end
    
    self._lastFlowUpdate = currentTime
end

function ParkourSystem:RecordTechniqueExecution(character, techniqueType, techniqueData)
    local executionRecord = {
        type = techniqueType,
        timestamp = os.clock(),
        position = self:GetCharacterAbdomenPosition(character),
        success = true,
        stylePoints = techniqueData.styleBonus or 0,
        efficiency = techniqueData.efficiencyScore or 0
    }
    
    table.insert(self._techniqueHistory, executionRecord)
    
    -- Maintain technique chain
    table.insert(self._techniqueChain, techniqueType)
    if #self._techniqueChain > 10 then
        table.remove(self._techniqueChain, 1)
    end
    
    -- Update chain metrics
    if #self._techniqueChain >= CONFIG.PARKOUR_CONFIG.CHAIN_LENGTH_TARGET then
        KynexFind._performanceMetrics.advancedTechniques.techniqueChains = 
            KynexFind._performanceMetrics.advancedTechniques.techniqueChains + 1
    end
end

-- Enhanced movement decision making
function ParkourSystem:ShouldUseAdvancedTechnique(character, goalPosition)
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    if not abdomenPos then return false end
    
    -- Check if we're in optimal flow state for advanced techniques
    if self._currentFlowState < CONFIG.PARKOUR_CONFIG.FLOW_STATE_THRESHOLD then
        return false
    end
    
    -- Check for advanced opportunities
    local opportunities = self:ScanForAdvancedOpportunities(character, goalPosition)
    local totalOpportunities = #opportunities.ladderFlicks + #opportunities.wallhops + 
                              #opportunities.wrapArounds + #opportunities.cornerClimbs
    
    return totalOpportunities > 0
end

function ParkourSystem:GetOptimalAdvancedManeuver(character, goalPosition)
    local bestTechnique, score, successProb = self:SelectOptimalTechnique(character, goalPosition)
    
    if bestTechnique and successProb >= CONFIG.PARKOUR_CONFIG.TECHNIQUE_SUCCESS_PROBABILITY then
        return bestTechnique, score, successProb
    end
    
    return nil, 0, 0
end

-- Utility functions for advanced techniques
function ParkourSystem:FindSharpCorners(position, goal, range)
    local corners = {}
    
    -- This is a simplified implementation - in practice, you'd use more sophisticated geometry analysis
    local region = self:CreateSafeRegion3(position, Vector3.new(range * 2, range * 2, range * 2))
    local parts = workspace:FindPartsInRegion3(region, nil, 50)
    
    -- Look for L-shaped geometry (simplified corner detection)
    for _, part in ipairs(parts) do
        if part.Size.X > 4 and part.Size.Z > 4 then
            -- Check if this could be part of a corner
            local adjacentRegion = self:CreateSafeRegion3(part.Position, part.Size + Vector3.new(2, 2, 2))
            local adjacentParts = workspace:FindPartsInRegion3(adjacentRegion, nil, 10)
            
            if #adjacentParts >= 2 then
                table.insert(corners, {
                    position = part.Position,
                    angle = 90, -- Typical corner angle
                    normal1 = Vector3.new(1, 0, 0),
                    normal2 = Vector3.new(0, 0, 1)
                })
            end
        end
    end
    
    return corners
end

function ParkourSystem:FindDeepCorners(position, range)
    -- Similar to sharp corners but with more depth requirements
    return self:FindSharpCorners(position, position, range) -- Simplified
end

function ParkourSystem:CheckAdjacentWallSupport(cornerPos, range)
    local region = self:CreateSafeRegion3(cornerPos, Vector3.new(range * 2, range * 2, range * 2))
    local supportParts = workspace:FindPartsInRegion3(region, nil, 10)
    
    local verticalWalls = 0
    for _, part in ipairs(supportParts) do
        if part.Size.Y > part.Size.X * 1.5 and part.Size.Y > part.Size.Z * 1.5 then
            verticalWalls = verticalWalls + 1
        end
    end
    
    return verticalWalls >= 2
end

function ParkourSystem:GetCharacterVelocity(position)
    -- Simplified - in practice, track character velocity over time
    return Vector3.new(15, 0, 15) -- Default forward velocity
end

function ParkourSystem:CalculateMomentumPreservation(technique, character)
    local basePreservation = 0.8
    
    -- Technique-specific momentum preservation
    local techniquePreservation = {
        ladder_flick = 0.9,
        wallhop_chain = 0.7,
        wrap_around = 0.85,
        corner_climb = 0.6
    }
    
    return techniquePreservation[technique.type] or basePreservation
end

function ParkourSystem:CalculateEnergyEfficiency(technique)
    -- Simplified energy calculation
    local baseEfficiency = 0.7
    
    local techniqueEfficiency = {
        ladder_flick = 0.8,
        wallhop_chain = 0.6,
        wrap_around = 0.9,
        corner_climb = 0.5
    }
    
    return techniqueEfficiency[technique.type] or baseEfficiency
end

function ParkourSystem:GetCharacterSkillLevel(character)
    -- In practice, track character skill over time
    return 0.9 -- Expert level for parkour master
end

function ParkourSystem:GetCharacterStyleMastery(character)
    -- Calculate based on historical performance
    local baseMastery = 0.8
    local styleBonus = math.min(1.0, self._styleScore / 100)
    return math.min(0.98, baseMastery + styleBonus * 0.2)
end

function ParkourSystem:CalculateGripStability(position)
    -- Simplified grip calculation
    return 0.85
end

function ParkourSystem:CalculateChainBonus(techniqueType)
    if #self._techniqueChain == 0 then return 0 end
    
    local lastTechnique = self._techniqueChain[#self._techniqueChain]
    
    -- Bonus for chaining similar techniques
    if lastTechnique == techniqueType then
        return 0.3
    end
    
    -- Bonus for varied technique chains
    return 0.1
end

-- Enhanced character movement with advanced techniques
function ParkourSystem:MoveCharacterToGoal(character, goalPosition, options)
    options = options or {}
    local movementSpeed = options.movementSpeed or CONFIG.PARKOUR_CONFIG.PARKOUR_MOVEMENT_SPEED
    local useAdvancedTechniques = options.useAdvancedTechniques or true
    
    local humanoid = self:GetCharacterHumanoid(character)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoid or not humanoidRootPart then
        return false
    end
    
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    local distanceToGoal = (goalPosition - abdomenPos).Magnitude
    
    if distanceToGoal < (options.arrivalDistance or CONFIG.PARKOUR_CONFIG.ARRIVAL_DISTANCE) then
        humanoid:MoveTo(humanoidRootPart.Position)
        return true
    end
    
    -- Advanced technique decision making
    if useAdvancedTechniques and self:ShouldUseAdvancedTechnique(character, goalPosition) then
        local bestTechnique, score, successProb = self:GetOptimalAdvancedManeuver(character, goalPosition)
        
        if bestTechnique and successProb >= CONFIG.PARKOUR_CONFIG.TECHNIQUE_SUCCESS_PROBABILITY then
            local success = false
            
            -- Execute the appropriate advanced technique
            if bestTechnique.type == "ladder_flick" then
                success = self:ExecuteLadderFlick(character, bestTechnique)
            elseif bestTechnique.type == "wallhop_chain" then
                success = self:ExecuteWallhopChain(character, bestTechnique)
            elseif bestTechnique.type == "wrap_around" then
                success = self:ExecuteWrapAround(character, bestTechnique)
            elseif bestTechnique.type == "corner_climb" then
                success = self:ExecuteCornerClimb(character, bestTechnique)
            end
            
            if success then
                -- Update flow state and metrics
                local momentumPreserved = self:CalculateMomentumPreservation(bestTechnique, character)
                self:UpdateFlowState(character, true, momentumPreserved)
                
                KynexFind._performanceMetrics.advancedTechniques.momentumPreservation = 
                    KynexFind._performanceMetrics.advancedTechniques.momentumPreservation + (momentumPreserved * 100)
                
                return false -- Technique executed, don't use normal movement this frame
            else
                KynexFind._performanceMetrics.advancedTechniques.failedAdvancedManeuvers = 
                    KynexFind._performanceMetrics.advancedTechniques.failedAdvancedManeuvers + 1
                self:UpdateFlowState(character, false, 0)
            end
        end
    end
    
    -- Fall back to normal parkour movement
    if useAdvancedTechniques and self:ShouldUseParkour(character, goalPosition) then
        local bestManeuver = self:GetOptimalParkourManeuver(character, goalPosition)
        if bestManeuver then
            local success = self:ExecuteParkourManeuver(character, bestManeuver.type, bestManeuver)
            if success then
                return false
            end
        end
    end
    
    -- Basic movement
    local moveDirection = (goalPosition - humanoidRootPart.Position).Unit
    local targetPosition = humanoidRootPart.Position + moveDirection * movementSpeed
    
    humanoid:MoveTo(targetPosition)
    
    return false
end

-- Existing functions from original Kynex system (maintained for compatibility)
function ParkourSystem:GetCharacterAbdomenPosition(character)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoidRootPart then return nil end
    
    local abdomenOffset = Vector3.new(0, -1.5, 0)
    return humanoidRootPart.Position + abdomenOffset
end

function ParkourSystem:ScanForParkourObstacles(character, goalPosition)
    local currentTime = os.clock()
    if currentTime - self._environmentScanCooldown < 0.1 then
        return self._obstacleCache
    end
    
    self._environmentScanCooldown = currentTime
    self._obstacleCache = {}
    
    if not character then return self._obstacleCache end
    
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    if not abdomenPos then return self._obstacleCache end
    
    local obstacleTypes = {
        {
            name = "ledge",
            detectionRange = CONFIG.PARKOUR_CONFIG.LEDGE_DETECTION_RANGE,
            checkFunction = function(self, pos, goal, range)
                return self:CheckForLedge(pos, goal, range)
            end
        },
        {
            name = "wall",
            detectionRange = CONFIG.PARKOUR_CONFIG.WALL_DETECTION_RANGE,
            checkFunction = function(self, pos, goal, range)
                return self:CheckForWall(pos, goal, range)
            end
        },
        {
            name = "vault",
            detectionRange = CONFIG.PARKOUR_CONFIG.VAULT_DETECTION_RANGE,
            checkFunction = function(self, pos, goal, range)
                return self:CheckForVault(pos, goal, range)
            end
        }
    }
    
    for _, obstacleType in ipairs(obstacleTypes) do
        local obstacles = obstacleType.checkFunction(self, abdomenPos, goalPosition, obstacleType.detectionRange)
        for _, obstacle in ipairs(obstacles) do
            table.insert(self._obstacleCache, obstacle)
        end
    end
    
    KynexFind._performanceMetrics.obstaclesDetected = KynexFind._performanceMetrics.obstaclesDetected + #self._obstacleCache
    
    return self._obstacleCache
end

function ParkourSystem:CheckForLedge(position, goal, range)
    local ledges = {}
    
    local rayOrigin = position + Vector3.new(0, 2, 0)
    local rayDirection = (goal - position).Unit * range
    rayDirection = Vector3.new(rayDirection.X, 0, rayDirection.Z)
    
    local params = self:CreateRaycastParams({workspace.Terrain})
    
    local hit = workspace:Raycast(rayOrigin, rayDirection, params)
    if hit and hit.Normal.Y < 0.3 then
        local ledgeRayOrigin = hit.Position + Vector3.new(0, CONFIG.PARKOUR_CONFIG.LEDGE_GRAB_HEIGHT, 0)
        local ledgeRayDirection = Vector3.new(0, -CONFIG.PARKOUR_CONFIG.LEDGE_GRAB_HEIGHT * 2, 0)
        
        local ledgeHit = workspace:Raycast(ledgeRayOrigin, ledgeRayDirection, params)
        if not ledgeHit then
            table.insert(ledges, {
                type = "ledge",
                position = hit.Position + Vector3.new(0, CONFIG.PARKOUR_CONFIG.LEDGE_GRAB_HEIGHT - 1, 0),
                normal = hit.Normal,
                height = CONFIG.PARKOUR_CONFIG.LEDGE_GRAB_HEIGHT
            })
        end
    end
    
    return ledges
end

function ParkourSystem:CheckForWall(position, goal, range)
    local walls = {}
    
    local rayDirection = (goal - position).Unit * range
    local params = self:CreateRaycastParams({workspace.Terrain})
    
    for i = 0, 2 do
        local rayOrigin = position + Vector3.new(0, i * 2, 0)
        local hit = workspace:Raycast(rayOrigin, rayDirection, params)
        
        if hit and math.abs(hit.Normal.Y) < 0.3 then
            table.insert(walls, {
                type = "wall",
                position = hit.Position,
                normal = hit.Normal,
                height = i * 2
            })
        end
    end
    
    return walls
end

function ParkourSystem:CheckForVault(position, goal, range)
    local vaults = {}
    
    local rayDirection = (goal - position).Unit * range
    local params = self:CreateRaycastParams({workspace.Terrain})
    
    local rayOrigin = position + Vector3.new(0, 1, 0)
    local hit = workspace:Raycast(rayOrigin, rayDirection, params)
    
    if hit and hit.Normal.Y > 0.7 then
        local height = hit.Position.Y - position.Y
        if height > 1 and height < CONFIG.PARKOUR_CONFIG.VAULT_HEIGHT then
            table.insert(vaults, {
                type = "vault",
                position = hit.Position,
                normal = hit.Normal,
                height = height
            })
        end
    end
    
    return vaults
end

function ParkourSystem:ExecuteParkourManeuver(character, maneuverType, obstacle)
    local humanoid = self:GetCharacterHumanoid(character)
    local humanoidRootPart = self:GetCharacterRootPart(character)
    if not humanoid or not humanoidRootPart then
        return false
    end
    
    local currentTime = os.clock()
    if currentTime - self._lastManeuverTime < 0.2 then
        return false
    end
    
    self._lastManeuverTime = currentTime
    
    local maneuverHandlers = {
        ledge = function()
            if humanoidRootPart.Anchored then return false end
            humanoid.PlatformStand = true
            humanoidRootPart.Velocity = Vector3.new(0, CONFIG.PARKOUR_CONFIG.CLIMB_VELOCITY, 0)
            
            KynexFind:ProtectedDelay(1.0, function()
                if character and character.Parent then
                    local currentHumanoid = character:FindFirstChild("Humanoid")
                    if currentHumanoid then
                        currentHumanoid.PlatformStand = false
                    end
                end
            end)
            
            return true
        end,
        
        wall = function()
            if humanoidRootPart.Anchored then return false end
            local runDirection = Vector3.new(-obstacle.normal.X, 0.5, -obstacle.normal.Z).Unit
            humanoidRootPart.Velocity = runDirection * 25 + Vector3.new(0, 5, 0)
            
            return true
        end,
        
        vault = function()
            if humanoidRootPart.Anchored then return false end
            local vaultDirection = (obstacle.position - humanoidRootPart.Position).Unit
            vaultDirection = Vector3.new(vaultDirection.X, 0.7, vaultDirection.Z).Unit
            
            humanoidRootPart.Velocity = vaultDirection * 30 + Vector3.new(0, CONFIG.PARKOUR_CONFIG.JUMP_VELOCITY * 0.7, 0)
            
            return true
        end
    }
    
    local handler = maneuverHandlers[maneuverType]
    if handler then
        self._activeManeuvers[character] = {
            type = maneuverType,
            startTime = currentTime,
            obstacle = obstacle
        }
        
        KynexFind._performanceMetrics.parkourManeuvers = KynexFind._performanceMetrics.parkourManeuvers + 1
        
        return handler()
    end
    
    return false
end

function ParkourSystem:ShouldUseParkour(character, goalPosition, currentPath)
    if not character then return false end
    
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    if not abdomenPos then return false end
    
    local params = self:CreateRaycastParams()
    local directRay = workspace:Raycast(
        abdomenPos,
        (goalPosition - abdomenPos).Unit * (goalPosition - abdomenPos).Magnitude,
        params
    )
    
    if directRay then
        local obstacles = self:ScanForParkourObstacles(character, goalPosition)
        return #obstacles > 0
    end
    
    return false
end

function ParkourSystem:GetOptimalParkourManeuver(character, goalPosition)
    local obstacles = self:ScanForParkourObstacles(character, goalPosition)
    local abdomenPos = self:GetCharacterAbdomenPosition(character)
    
    if not abdomenPos or #obstacles == 0 then
        return nil
    end
    
    local bestManeuver = nil
    local bestScore = -math.huge
    
    for _, obstacle in ipairs(obstacles) do
        local score = 0
        
        local currentDistance = (goalPosition - abdomenPos).Magnitude
        local projectedPosition = obstacle.position + obstacle.normal * 3
        local newDistance = (goalPosition - projectedPosition).Magnitude
        local distanceImprovement = currentDistance - newDistance
        
        score = score + distanceImprovement * 2
        
        if obstacle.position.Y > abdomenPos.Y then
            score = score + (obstacle.position.Y - abdomenPos.Y) * 3
        end
        
        local typeWeights = { ledge = 3, vault = 2, wall = 1 }
        score = score + (typeWeights[obstacle.type] or 1) * 5
        
        if score > bestScore then
            bestScore = score
            bestManeuver = obstacle
        end
    end
    
    return bestManeuver
end

function ParkourSystem:UpdateCharacterState(character, state)
    if not character then return end
    self._characterStates[character] = state
end

function ParkourSystem:GetCharacterState(character)
    return self._characterStates[character] or "idle"
end

local MemoryManager = {
    _memoryUsage = 0,
    _lastCleanupTime = os.clock(),
    _cleanupScheduled = false,
    _objectRegistry = {
        nodes = {},
        paths = {},
        caches = {},
        neural = {},
        temporary = {},
        parkour = {},
        advanced = {}
    }
}

function MemoryManager:RegisterObject(obj, category, sizeEstimate)
    if not self._objectRegistry[category] then
        self._objectRegistry[category] = {}
    end
    
    local id = tostring(obj) .. "_" .. tostring(os.clock()) .. "_" .. tostring(math.random(1, 1000000))
    self._objectRegistry[category][id] = {
        object = obj,
        size = sizeEstimate or 1,
        created = os.clock(),
        lastAccessed = os.clock()
    }
    
    self._memoryUsage = self._memoryUsage + (sizeEstimate or 1)
    self:CheckMemoryPressure()
end

function MemoryManager:UnregisterObject(obj, category)
    if not self._objectRegistry[category] then return end
    
    for id, data in pairs(self._objectRegistry[category]) do
        if data.object == obj then
            self._memoryUsage = self._memoryUsage - data.size
            self._objectRegistry[category][id] = nil
            break
        end
    end
end

function MemoryManager:UpdateAccessTime(obj, category)
    if not self._objectRegistry[category] then return end
    
    for id, data in pairs(self._objectRegistry[category]) do
        if data.object == obj then
            data.lastAccessed = os.clock()
            break
        end
    end
end

function MemoryManager:CheckMemoryPressure()
    local currentMemory = self:GetCurrentMemoryUsage()
    local memoryPressure = currentMemory / CONFIG.MAX_MEMORY_USAGE_MB
    
    if memoryPressure > CONFIG.MEMORY_CLEANUP_THRESHOLD and not self._cleanupScheduled then
        self._cleanupScheduled = true
        self:ScheduleCleanup()
    end
end

function MemoryManager:GetCurrentMemoryUsage()
    local estimated = self._memoryUsage
    local count = 0
    for _, category in pairs(self._objectRegistry) do
        for _ in pairs(category) do
            count = count + 1
        end
    end
    estimated = estimated + (count * 0.1)
    return math.min(estimated, CONFIG.MAX_MEMORY_USAGE_MB)
end

function MemoryManager:ScheduleCleanup()
    KynexFind:RunSafeCoroutine(function()
        task.wait(0.1)
        self:PerformPrioritizedCleanup()
        self._cleanupScheduled = false
    end, "MemoryCleanup")
end

function MemoryManager:PerformPrioritizedCleanup()
    local cleanupStart = os.clock()
    local cleanedCount = 0
    local targetMemory = CONFIG.MAX_MEMORY_USAGE_MB * 0.5
    
    local cleanupOrder = {"temporary", "caches", "paths", "nodes", "neural", "parkour", "advanced"}
    
    for _, category in ipairs(cleanupOrder) do
        if self:GetCurrentMemoryUsage() <= targetMemory then
            break
        end
        cleanedCount = cleanedCount + self:CleanupCategory(category, true)
    end
    
    KynexFind._performanceMetrics.memoryCleanupCount = KynexFind._performanceMetrics.memoryCleanupCount + 1
    
    if cleanedCount > 0 then
        print(string.format("[MemoryManager] Cleaned %d objects, memory usage: %.2f MB", 
              cleanedCount, self:GetCurrentMemoryUsage()))
    end
end

function MemoryManager:CleanupCategory(category, prioritizeOld)
    if not self._objectRegistry[category] then return 0 end
    
    local cleaned = 0
    local currentTime = os.clock()
    local maxAge = 300
    
    -- Collect keys first to avoid modification during iteration
    local keysToRemove = {}
    for id, data in pairs(self._objectRegistry[category]) do
        local shouldClean = false
        
        if prioritizeOld then
            shouldClean = (currentTime - data.lastAccessed) > maxAge
        else
            shouldClean = true
        end
        
        if shouldClean then
            table.insert(keysToRemove, id)
        end
    end
    
    -- Remove collected items
    for _, id in ipairs(keysToRemove) do
        self._memoryUsage = self._memoryUsage - (self._objectRegistry[category][id].size or 0)
        self._objectRegistry[category][id] = nil
        cleaned = cleaned + 1
    end
    
    return cleaned
end

function MemoryManager:EmergencyCleanup()
    local cleaned = 0
    for category, _ in pairs(self._objectRegistry) do
        cleaned = cleaned + self:CleanupCategory(category, false)
    end
    
    task.wait()
    
    KynexFind._performanceMetrics.memoryCleanupCount = KynexFind._performanceMetrics.memoryCleanupCount + 1
    print(string.format("[MemoryManager] Emergency cleanup completed, removed %d objects", cleaned))
end

local CircuitBreaker = {
    state = "CLOSED",
    failureCount = 0,
    lastFailureTime = 0,
    lastSuccessTime = os.clock(),
    nextAttemptTime = 0
}

function CircuitBreaker:Execute(operationName, operation, fallback)
    if self.state == "OPEN" then
        if os.clock() < self.nextAttemptTime then
            KynexFind._performanceMetrics.circuitBreakerTrips = KynexFind._performanceMetrics.circuitBreakerTrips + 1
            return fallback and fallback() or nil
        else
            self.state = "HALF_OPEN"
        end
    end
    
    local success, result = pcall(operation)
    
    if success then
        self:RecordSuccess()
        return result
    else
        self:RecordFailure()
        return fallback and fallback() or nil
    end
end

function CircuitBreaker:RecordSuccess()
    self.failureCount = 0
    self.lastSuccessTime = os.clock()
    
    if self.state == "HALF_OPEN" then
        self.state = "CLOSED"
    end
end

function CircuitBreaker:RecordFailure()
    self.failureCount = self.failureCount + 1
    self.lastFailureTime = os.clock()
    
    if self.failureCount >= CONFIG.CIRCUIT_BREAKER_THRESHOLD then
        self.state = "OPEN"
        self.nextAttemptTime = os.clock() + CONFIG.CIRCUIT_BREAKER_TIMEOUT
    end
end

function CircuitBreaker:GetHealth()
    return {
        state = self.state,
        failureCount = self.failureCount,
        lastFailureTime = self.lastFailureTime,
        lastSuccessTime = self.lastSuccessTime
    }
end

local RateLimiter = {
    _requestCounts = {},
    _windowStart = os.clock()
}

function RateLimiter:CheckLimit(identifier)
    local currentTime = os.clock()
    
    if currentTime - self._windowStart > CONFIG.RATE_LIMIT_WINDOW_SIZE then
        self._requestCounts = {}
        self._windowStart = currentTime
    end
    
    self._requestCounts[identifier] = self._requestCounts[identifier] or 0
    
    if self._requestCounts[identifier] >= CONFIG.RATE_LIMIT_REQUESTS_PER_MINUTE then
        KynexFind._performanceMetrics.rateLimitHits = KynexFind._performanceMetrics.rateLimitHits + 1
        return false
    end
    
    self._requestCounts[identifier] = self._requestCounts[identifier] + 1
    return true
end

function RateLimiter:GetRemainingRequests(identifier)
    local currentCount = self._requestCounts[identifier] or 0
    return math.max(0, CONFIG.RATE_LIMIT_REQUESTS_PER_MINUTE - currentCount)
end

local WorkloadBalancer = {
    _requestsThisFrame = 0,
    _lastFrameReset = os.clock(),
    _frameStartTime = os.clock(),
    _deferredOperations = {}
}

function WorkloadBalancer:CanProcessRequest()
    local currentTime = os.clock()
    
    if currentTime - self._lastFrameReset > (1/60) then
        self._requestsThisFrame = 0
        self._lastFrameReset = currentTime
        self._frameStartTime = currentTime
    end
    
    local frameTimeElapsed = (currentTime - self._frameStartTime) * 1000
    if frameTimeElapsed > CONFIG.FRAME_BUDGET_MS then
        return false
    end
    
    if self._requestsThisFrame >= CONFIG.MAX_REQUESTS_PER_FRAME then
        return false
    end
    
    self._requestsThisFrame = self._requestsThisFrame + 1
    return true
end

function WorkloadBalancer:DeferOperation(operation, ...)
    local args = {...}
    table.insert(self._deferredOperations, {
        operation = operation,
        args = args,
        scheduledTime = os.clock()
    })
    KynexFind._performanceMetrics.deferredOperations = KynexFind._performanceMetrics.deferredOperations + 1
end

function WorkloadBalancer:ProcessDeferred()
    local currentTime = os.clock()
    local processed = 0
    
    for i = #self._deferredOperations, 1, -1 do
        if processed >= CONFIG.MAX_REQUESTS_PER_FRAME then break end
        
        local op = self._deferredOperations[i]
        if currentTime - op.scheduledTime >= 0 then
            local success, result = pcall(op.operation, table.unpack(op.args))
            table.remove(self._deferredOperations, i)
            processed = processed + 1
        end
    end
end

local HealthMonitor = {
    _componentHealth = {},
    _lastHealthCheck = os.clock(),
    _healthCheckInterval = 10
}

function HealthMonitor:RegisterComponent(name, healthCheckFunc)
    self._componentHealth[name] = {
        checkFunction = healthCheckFunc,
        lastStatus = "unknown",
        lastCheck = 0,
        consecutiveFailures = 0
    }
end

function HealthMonitor:CheckAllComponents()
    local currentTime = os.clock()
    if currentTime - self._lastHealthCheck < self._healthCheckInterval then
        return "healthy"
    end
    
    self._lastHealthCheck = currentTime
    local overallHealth = "healthy"
    
    for name, data in pairs(self._componentHealth) do
        local success, status = pcall(data.checkFunction)
        
        if success then
            if status == "healthy" then
                data.consecutiveFailures = 0
                data.lastStatus = "healthy"
            else
                data.consecutiveFailures = data.consecutiveFailures + 1
                data.lastStatus = status
                
                if data.consecutiveFailures > 3 then
                    overallHealth = "degraded"
                end
            end
        else
            data.consecutiveFailures = data.consecutiveFailures + 1
            data.lastStatus = "error"
            overallHealth = "unhealthy"
        end
        
        data.lastCheck = currentTime
    end
    
    return overallHealth
end

function HealthMonitor:GetComponentStatus(componentName)
    local component = self._componentHealth[componentName]
    if not component then return "unknown" end
    return component.lastStatus
end

local ErrorHandler = {
    LastError = nil,
    ErrorCount = 0,
    LastErrorTime = 0,
    RecoveryMode = false,
    _recoveryStrategies = {},
    _errorPatterns = {}
}

function ErrorHandler.SafeExecute(func, context, fallback, recoveryStrategy)
    local success, result = pcall(func)
    
    if not success then
        ErrorHandler.LastError = result
        ErrorHandler.ErrorCount = ErrorHandler.ErrorCount + 1
        ErrorHandler.LastErrorTime = os.clock()
        
        ErrorHandler:_AnalyzeErrorPattern(context, result)
        
        if recoveryStrategy then
            local recoverySuccess = ErrorHandler:_AttemptRecovery(recoveryStrategy, context)
            if recoverySuccess and fallback then
                return fallback()
            end
        end
        
        warn(string.format("[KynexFind Error] %s: %s", context, result))
        if fallback then return fallback() end
        return nil
    end
    
    if os.clock() - ErrorHandler.LastErrorTime > 60 then
        ErrorHandler.ErrorCount = math.max(0, ErrorHandler.ErrorCount - 1)
    end
    
    return result
end

function ErrorHandler:_AnalyzeErrorPattern(context, errorMsg)
    local errorKey = context .. ":" .. tostring(errorMsg):sub(1, 50)
    ErrorHandler._errorPatterns[errorKey] = (ErrorHandler._errorPatterns[errorKey] or 0) + 1
    
    if ErrorHandler._errorPatterns[errorKey] > 5 then
        ErrorHandler.RecoveryMode = true
        print(string.format("[ErrorHandler] Frequent error detected: %s. Entering recovery mode.", context))
    end
end

function ErrorHandler:_AttemptRecovery(strategy, context)
    print(string.format("[ErrorHandler] Attempting recovery for: %s", context))
    
    local strategies = {
        memory_cleanup = function()
            MemoryManager:EmergencyCleanup()
            return true
        end,
        reset_neural_network = function()
            if KynexFind.ResetNeuralNetwork then
                KynexFind.ResetNeuralNetwork()
                return true
            end
            return false
        end,
        clear_caches = function()
            if PerformanceManager then
                PerformanceManager.PathCache = {}
                return true
            end
            return false
        end,
        full_restart = function()
            KynexFind._initialized = false
            return KynexFind.Initialize()
        end
    }
    
    local recoveryFunc = strategies[strategy]
    if recoveryFunc then
        local success = pcall(recoveryFunc)
        if success then
            ErrorHandler.RecoveryMode = false
            ErrorHandler.ErrorCount = 0
            return true
        end
    end
    
    return false
end

function ErrorHandler.ResetErrorState()
    ErrorHandler.LastError = nil
    ErrorHandler.RecoveryMode = false
    ErrorHandler.ErrorCount = math.floor(ErrorHandler.ErrorCount * 0.5)
end

local ResourceMonitor = {
    MemoryUsage = 0,
    CPULoad = 0,
    LastCleanup = os.clock(),
    ObjectCounts = { nodes = 0, paths = 0, obstacles = 0, advanced = 0 },
    _performanceHistory = {},
    _predictionModel = {}
}

function ResourceMonitor.CheckResourceHealth()
    local currentTime = os.clock()
    
    if currentTime - ResourceMonitor.LastCleanup > CONFIG.MEMORY_CLEANUP_INTERVAL then
        MemoryManager:PerformPrioritizedCleanup()
        ResourceMonitor.LastCleanup = currentTime
    end
    
    local memoryPressure = ResourceMonitor.CalculateMemoryPressure()
    if memoryPressure > 0.9 then
        MemoryManager:EmergencyCleanup()
    end
    
    ResourceMonitor:_RecordPerformanceSnapshot()
    ResourceMonitor:_PredictResourceNeeds()
end

function ResourceMonitor.CalculateMemoryPressure()
    local currentMemory = MemoryManager:GetCurrentMemoryUsage()
    return currentMemory / CONFIG.MAX_MEMORY_USAGE_MB
end

function ResourceMonitor:_RecordPerformanceSnapshot()
    local snapshot = {
        timestamp = os.clock(),
        memoryUsage = MemoryManager:GetCurrentMemoryUsage(),
        objectCounts = ResourceMonitor.ObjectCounts,
        errorCount = ErrorHandler.ErrorCount,
        searchVolume = KynexFind._performanceMetrics.totalSearches,
        advancedTechniques = KynexFind._performanceMetrics.advancedTechniques
    }
    
    table.insert(ResourceMonitor._performanceHistory, snapshot)
    
    if #ResourceMonitor._performanceHistory > 100 then
        table.remove(ResourceMonitor._performanceHistory, 1)
    end
end

function ResourceMonitor:_PredictResourceNeeds()
    if #ResourceMonitor._performanceHistory < 10 then return end
    
    local recent = {}
    for i = math.max(1, #ResourceMonitor._performanceHistory - 5), #ResourceMonitor._performanceHistory do
        table.insert(recent, ResourceMonitor._performanceHistory[i])
    end
    
    local memoryTrend = 0
    for i = 2, #recent do
        memoryTrend = memoryTrend + (recent[i].memoryUsage - recent[i-1].memoryUsage)
    end
    memoryTrend = memoryTrend / (#recent - 1)
    
    if memoryTrend > 1.0 then
        MemoryManager:ScheduleCleanup()
    end
end

local ProgressMonitor = {
    ActiveSearches = {},
    SearchTimeouts = {},
    _searchHistory = {}
}

function ProgressMonitor.StartSearch(searchId, start, goal)
    ProgressMonitor.ActiveSearches[searchId] = {
        startTime = os.clock(),
        startPos = start,
        goalPos = goal,
        nodesExplored = 0,
        lastProgress = os.clock(),
        timeout = CONFIG.MAX_SEARCH_TIME
    }
    
    ProgressMonitor.SearchTimeouts[searchId] = os.clock() + CONFIG.MAX_SEARCH_TIME
end

function ProgressMonitor.EndSearch(searchId)
    local search = ProgressMonitor.ActiveSearches[searchId]
    if search then
        local duration = os.clock() - search.startTime
        table.insert(ProgressMonitor._searchHistory, {
            duration = duration,
            nodes = search.nodesExplored,
            success = true
        })
        
        if #ProgressMonitor._searchHistory > 50 then
            table.remove(ProgressMonitor._searchHistory, 1)
        end
    end
    
    ProgressMonitor.ActiveSearches[searchId] = nil
    ProgressMonitor.SearchTimeouts[searchId] = nil
end

function ProgressMonitor.CheckTimeouts()
    local currentTime = os.clock()
    local timedOut = {}
    
    for searchId, timeoutTime in pairs(ProgressMonitor.SearchTimeouts) do
        if currentTime > timeoutTime then
            table.insert(timedOut, searchId)
        end
    end
    
    for _, searchId in ipairs(timedOut) do
        ProgressMonitor.ActiveSearches[searchId] = nil
        ProgressMonitor.SearchTimeouts[searchId] = nil
        warn(string.format("[ProgressMonitor] Search %s timed out", searchId))
    end
    
    return #timedOut
end

function ProgressMonitor.GetAverageSearchTime()
    if #ProgressMonitor._searchHistory == 0 then return 0 end
    
    local total = 0
    for _, search in ipairs(ProgressMonitor._searchHistory) do
        total = total + search.duration
    end
    
    return total / #ProgressMonitor._searchHistory
end

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new()
    return setmetatable({
        _elements = {},
        _count = 0,
        _itemToIndex = {}
    }, PriorityQueue)
end

function PriorityQueue:Enqueue(item, priority)
    if not item or priority ~= priority then return end
    self._count = self._count + 1
    self._elements[self._count] = {item = item, priority = priority}
    self._itemToIndex[item] = self._count
    self:_siftUp(self._count)
end

function PriorityQueue:Dequeue()
    if self._count == 0 then return nil end
    local result = self._elements[1].item
    self._itemToIndex[result] = nil
    
    if self._count > 1 then
        self._elements[1] = self._elements[self._count]
        self._itemToIndex[self._elements[1].item] = 1
        self:_siftDown(1)
    end
    
    -- FIXED: Decrement count before clearing element
    self._count = self._count - 1
    self._elements[self._count + 1] = nil
    
    if self._count == 0 then
        self._itemToIndex = {}
        self._elements = {}
    end
    
    return result
end

function PriorityQueue:_siftUp(index)
    while index > 1 do
        local parent = math.floor(index / 2)
        if self._elements[parent].priority <= self._elements[index].priority then break end
        self:_swap(index, parent)
        index = parent
    end
end

function PriorityQueue:_siftDown(index)
    while true do
        local left = index * 2
        local right = index * 2 + 1
        local smallest = index
        if left <= self._count and self._elements[left].priority < self._elements[smallest].priority then
            smallest = left
        end
        if right <= self._count and self._elements[right].priority < self._elements[smallest].priority then
            smallest = right
        end
        if smallest == index then break end
        self:_swap(index, smallest)
        index = smallest
    end
end

function PriorityQueue:_swap(i, j)
    self._elements[i], self._elements[j] = self._elements[j], self._elements[i]
    self._itemToIndex[self._elements[i].item] = i
    self._itemToIndex[self._elements[j].item] = j
end

function PriorityQueue:IsEmpty() return self._count == 0 end

function PriorityQueue:Clear()
    self._elements = {}
    self._count = 0
    self._itemToIndex = {}
end

local NeuralNetwork = {}
NeuralNetwork.__index = NeuralNetwork

function NeuralNetwork.new(inputSize, hiddenLayers, outputSize)
    local network = {
        layers = {},
        learningRate = CONFIG.NEURAL_LEARNING_RATE
    }
    
    local prevSize = inputSize
    for i = 1, hiddenLayers do
        local layerSize = math.floor((inputSize + outputSize) / 2)
        local layer = {
            weights = {},
            biases = {}
        }
        for j = 1, layerSize do
            layer.weights[j] = {}
            for k = 1, prevSize do
                layer.weights[j][k] = (math.random() * 2 - 1) * 0.1
            end
            layer.biases[j] = 0
        end
        table.insert(network.layers, layer)
        prevSize = layerSize
    end
    
    local outputLayer = {
        weights = {},
        biases = {}
    }
    for i = 1, outputSize do
        outputLayer.weights[i] = {}
        for j = 1, prevSize do
            outputLayer.weights[i][j] = (math.random() * 2 - 1) * 0.1
        end
        outputLayer.biases[i] = 0
    end
    table.insert(network.layers, outputLayer)
    
    return setmetatable(network, { __index = NeuralNetwork })
end

function NeuralNetwork:forward(input)
    if not input or #input == 0 then
        return {}
    end
    
    local current = input
    for _, layer in ipairs(self.layers) do
        local nextLayer = {}
        for i = 1, #layer.weights do
            local sum = layer.biases[i]
            for j = 1, #current do
                sum = sum + current[j] * layer.weights[i][j]
            end
            nextLayer[i] = 1 / (1 + math.exp(-sum))
        end
        current = nextLayer
    end
    return current
end

function NeuralNetwork:train(inputs, targets, iterations)
    if not inputs or not targets or #inputs == 0 or #inputs ~= #targets then
        warn("NeuralNetwork: Invalid training data")
        return
    end
    
    for iter = 1, iterations do
        for i, input in ipairs(inputs) do
            local target = targets[i]
            if not target then
                warn("NeuralNetwork: Missing target for input " .. tostring(i))
                continue
            end
            
            local activations = { input }
            for _, layer in ipairs(self.layers) do
                local nextActivation = {}
                for j = 1, #layer.weights do
                    local sum = layer.biases[j]
                    for k = 1, #activations[#activations] do
                        sum = sum + activations[#activations][k] * layer.weights[j][k]
                    end
                    nextActivation[j] = 1 / (1 + math.exp(-sum))
                end
                table.insert(activations, nextActivation)
            end
            
            local errors = {}
            local output = activations[#activations]
            for j = 1, #output do
                local targetVal = type(target) == "table" and target[j] or target
                errors[j] = (targetVal or 0) - output[j]
            end
            
            for l = #self.layers, 1, -1 do
                local layer = self.layers[l]
                local activation = activations[l]
                local nextActivation = activations[l+1]
                local nextErrors = {}
                
                if l < #self.layers then
                    for j = 1, #self.layers[l+1].weights do
                        nextErrors[j] = 0
                        for k = 1, #errors do
                            nextErrors[j] = nextErrors[j] + errors[k] * self.layers[l+1].weights[k][j]
                        end
                    end
                    errors = nextErrors
                end
                
                for j = 1, #layer.weights do
                    local delta = errors[j] * nextActivation[j] * (1 - nextActivation[j])
                    for k = 1, #activation do
                        layer.weights[j][k] = layer.weights[j][k] + self.learningRate * delta * activation[k]
                    end
                    layer.biases[j] = layer.biases[j] + self.learningRate * delta
                end
            end
        end
    end
end

function NeuralNetwork:predict(input)
    return self:forward(input)
end

local PathSmoother = {}

function PathSmoother.SmoothPath(path, gridSize)
    if #path <= 2 then return path end
    local smoothed = {path[1]}
    for i = 3, #path do
        local prevPoint = smoothed[#smoothed]
        local currentPoint = path[i]
        if i < #path then
            local nextPoint = path[i + 1]
            local dir1 = (currentPoint - prevPoint).Unit
            local dir2 = (nextPoint - currentPoint).Unit
            local dot = dir1:Dot(dir2)
            if dot < 0.9 then
                table.insert(smoothed, currentPoint)
            end
        else
            table.insert(smoothed, currentPoint)
        end
    end
    if smoothed[#smoothed] ~= path[#path] then
        table.insert(smoothed, path[#path])
    end
    return smoothed
end

local AdaptiveAStar = {}
AdaptiveAStar.__index = AdaptiveAStar

function AdaptiveAStar.new()
    return setmetatable({
        OpenSet = PriorityQueue.new(),
        ClosedSet = {},
        CameFrom = {},
        GScore = {},
        FScore = {},
        HeuristicWeight = 1.0,
        GridSize = 4
    }, AdaptiveAStar)
end

function AdaptiveAStar:IsWalkable(position, options)
    local agentHeight = options.agentHeight or 5
    if agentHeight ~= agentHeight then agentHeight = 5 end
    if agentHeight <= 0 then agentHeight = 5 end
    if agentHeight > 100 then agentHeight = 100 end
    
    local rayOrigin = position + Vector3.new(0, agentHeight, 0)
    local rayDirection = Vector3.new(0, -agentHeight * 2, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = options.ignoreList or {}
    local hit = workspace:Raycast(rayOrigin, rayDirection, params)
    if hit then
        local normal = hit.Normal
        local slope = math.deg(math.acos(normal.Y))
        return slope <= (options.MaxSlope or 45)
    end
    return false
end

function AdaptiveAStar:GetNeighbors(position, gridSize)
    local neighbors = {}
    local directions = {
        Vector3.new(gridSize, 0, 0), Vector3.new(-gridSize, 0, 0),
        Vector3.new(0, 0, gridSize), Vector3.new(0, 0, -gridSize),
        Vector3.new(gridSize, 0, gridSize), Vector3.new(-gridSize, 0, gridSize),
        Vector3.new(gridSize, 0, -gridSize), Vector3.new(-gridSize, 0, -gridSize),
        Vector3.new(0, gridSize, 0), Vector3.new(0, -gridSize, 0)
    }
    for _, dir in ipairs(directions) do
        table.insert(neighbors, position + dir)
    end
    return neighbors
end

function AdaptiveAStar:FindPath(start, goal, options, terrainProfile, agentProfile)
    local startTime = os.clock()
    self.GridSize = terrainProfile and terrainProfile.GridSize or 4
    
    local startKey = Vector3ToKey(start, self.GridSize)
    local goalKey = Vector3ToKey(goal, self.GridSize)
    
    self.OpenSet:Enqueue(start, 0)
    self.GScore[startKey] = 0
    self.FScore[startKey] = EuclideanDistance(start, goal) * self.HeuristicWeight

    local nodesExplored = 0
    
    while not self.OpenSet:IsEmpty() do
        local current = self.OpenSet:Dequeue()
        if not current then break end
        
        local currentKey = Vector3ToKey(current, self.GridSize)
        nodesExplored = nodesExplored + 1
        
        ResourceMonitor.ObjectCounts.nodes = ResourceMonitor.ObjectCounts.nodes + 1
        
        if nodesExplored > CONFIG.MAX_NODES then
            return nil, { status = "timeout", nodesExplored = nodesExplored }
        end
        
        if currentKey == goalKey then
            local path = self:ReconstructPath(current)
            ResourceMonitor.ObjectCounts.paths = ResourceMonitor.ObjectCounts.paths + 1
            return path, { 
                status = "success", 
                nodesExplored = nodesExplored,
                searchTime = os.clock() - startTime 
            }
        end
        
        self.ClosedSet[currentKey] = true
        
        local neighbors = self:GetNeighbors(current, self.GridSize)
        for _, neighbor in ipairs(neighbors) do
            if self:IsWalkable(neighbor, options) then
                local neighborKey = Vector3ToKey(neighbor, self.GridSize)
                if not self.ClosedSet[neighborKey] then
                    local moveCost = EuclideanDistance(current, neighbor)
                    local tentativeG = (self.GScore[currentKey] or math.huge) + moveCost
                    if not self.GScore[neighborKey] or tentativeG < self.GScore[neighborKey] then
                        self.CameFrom[neighborKey] = current
                        self.GScore[neighborKey] = tentativeG
                        local fScore = tentativeG + (EuclideanDistance(neighbor, goal) * self.HeuristicWeight)
                        self.FScore[neighborKey] = fScore
                        self.OpenSet:Enqueue(neighbor, fScore)
                    end
                end
            end
        end
    end
    
    return nil, { status = "no_path", nodesExplored = nodesExplored }
end

function AdaptiveAStar:ReconstructPath(current)
    local path = {current}
    local currentKey = Vector3ToKey(current, self.GridSize)
    local safetyCounter = 0
    local maxPathLength = 5000 -- More reasonable limit
    
    while self.CameFrom[currentKey] and safetyCounter < maxPathLength do
        current = self.CameFrom[currentKey]
        currentKey = Vector3ToKey(current, self.GridSize)
        table.insert(path, 1, current)
        safetyCounter = safetyCounter + 1
    end
    
    if safetyCounter >= maxPathLength then
        warn("[AdaptiveAStar] Path reconstruction hit safety limit")
    end
    
    return PathSmoother.SmoothPath(path, self.GridSize)
end

local ParallelProcessor = {}
ParallelProcessor.__index = ParallelProcessor

function ParallelProcessor.new()
    local processor = {
        processors = {
            { name = "AStar_Fast", algorithm = "AStar", config = { heuristicWeight = 1.1, gridSize = 4 } },
            { name = "AStar_Accurate", algorithm = "AStar", config = { heuristicWeight = 1.0, gridSize = 2 } },
            { name = "ThetaStar", algorithm = "ThetaStar", config = { smoothing = true } },
            { name = "JPS", algorithm = "JPS", config = { jumpDistance = 10 } },
            { name = "HPAStar", algorithm = "HPAStar", config = { clusterSize = 8 } }
        },
        neuralNetwork = NeuralNetwork.new(15, CONFIG.NEURAL_HIDDEN_LAYERS, CONFIG.PARALLEL_PROCESSORS),
        trainingData = {}
    }
    return setmetatable(processor, ParallelProcessor)
end

function ParallelProcessor:executeParallel(start, goal, options, terrainProfile, agentProfile)
    local paths = {}
    local metrics = {}
    local searchId = string.format("parallel_%f", os.clock())
    
    ProgressMonitor.StartSearch(searchId, start, goal)
    
    for i, processor in ipairs(self.processors) do
        local path, metric = self:executeSingleProcessor(processor, start, goal, options, terrainProfile, agentProfile)
        paths[processor.name] = path
        metrics[processor.name] = metric
    end
    
    ProgressMonitor.EndSearch(searchId)
    
    return paths, metrics
end

function ParallelProcessor:executeSingleProcessor(processor, start, goal, options, terrainProfile, agentProfile)
    if processor.algorithm == "AStar" then
        local astar = AdaptiveAStar.new()
        astar.HeuristicWeight = processor.config.heuristicWeight
        astar.GridSize = processor.config.gridSize
        return astar:FindPath(start, goal, options, terrainProfile, agentProfile)
    else
        local astar = AdaptiveAStar.new()
        return astar:FindPath(start, goal, options, terrainProfile, agentProfile)
    end
end

function ParallelProcessor:extractPathFeatures(path, metrics, start, goal, terrainProfile)
    if not path or #path == 0 then
        return {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    end
    
    local features = {}
    
    table.insert(features, #path / 100)
    
    local totalDistance = 0
    for i = 1, #path - 1 do
        totalDistance = totalDistance + (path[i] - path[i+1]).Magnitude
    end
    table.insert(features, totalDistance / 500)
    
    table.insert(features, (metrics and metrics.searchTime or 0) / 10)
    table.insert(features, (metrics and metrics.nodesExplored or 0) / 10000)
    
    local straightDistance = (start - goal).Magnitude
    table.insert(features, SafeDivide(totalDistance, straightDistance, 1))
    
    table.insert(features, 0.5)
    table.insert(features, 0.5)
    table.insert(features, 0.5)
    
    table.insert(features, terrainProfile.ObstacleDensity or 0)
    table.insert(features, 0.5)
    
    local elevationChange = math.abs(start.Y - goal.Y)
    table.insert(features, elevationChange / 50)
    
    table.insert(features, straightDistance / 500)
    table.insert(features, os.clock() % 1)
    table.insert(features, (metrics and metrics.status == "success" and 1) or 0)
    table.insert(features, ErrorHandler.ErrorCount / 10)
    
    return features
end

function ParallelProcessor:selectBestPath(paths, metrics, start, goal, terrainProfile)
    if not paths or not next(paths) then
        return nil, "no_paths_available"
    end
    
    local featuresList = {}
    local pathNames = {}
    local index = 1
    
    for name, path in pairs(paths) do
        local featureVector = self:extractPathFeatures(path, metrics[name], start, goal, terrainProfile)
        featuresList[index] = featureVector
        pathNames[index] = name
        index = index + 1
    end
    
    local predictions = self.neuralNetwork:predict(self:getContextFeatures(start, goal, terrainProfile)) or {}
    
    local bestScore = -math.huge
    local bestPathName = nil
    local bestPath = nil
    
    for i, name in ipairs(pathNames) do
        local score = predictions[i] or 0
        
        if metrics[name] and metrics[name].status == "success" then
            score = score + 2.0
        end
        
        if paths[name] and #paths[name] > 0 then
            local efficiency = SafeDivide(#paths[name], (start - goal).Magnitude, 1)
            score = score + (1.0 / math.max(efficiency, 0.1))
        end
        
        if score > bestScore then
            bestScore = score
            bestPathName = name
            bestPath = paths[name]
        end
    end
    
    if bestPath then
        KynexFind._performanceMetrics.neuralPredictions = KynexFind._performanceMetrics.neuralPredictions + 1
        return bestPath, bestPathName
    end
    
    for name, path in pairs(paths) do
        if path and #path > 0 then
            return path, name
        end
    end
    
    return nil, "no_path_found"
end

function ParallelProcessor:getContextFeatures(start, goal, terrainProfile)
    local context = {}
    
    table.insert(context, SafeDivide((start - goal).Magnitude, 500, 1))
    table.insert(context, SafeDivide(math.abs(start.Y - goal.Y), 50, 0))
    table.insert(context, terrainProfile.ObstacleDensity or 0)
    table.insert(context, 0.5)
    table.insert(context, 0)
    table.insert(context, 0)
    table.insert(context, 0)
    table.insert(context, os.clock() % 1)
    table.insert(context, SafeDivide(ErrorHandler.ErrorCount, 10, 0))
    table.insert(context, SafeDivide(KynexFind._performanceMetrics.stabilityScore, 100, 1))
    
    table.insert(context, SafeDivide((terrainProfile.GridSize or 4), 10, 0.4))
    table.insert(context, 0)
    table.insert(context, math.random() * 0.1)
    table.insert(context, (start.X + start.Z) / 1000)
    table.insert(context, (goal.X + goal.Z) / 1000)
    
    return context
end

local PerformanceManager = {
    PathCache = {},
    CacheSize = CONFIG.CACHE_SIZE
}

function PerformanceManager.GetCachedPath(start, goal, options)
    local cacheKey = PerformanceManager._generateCacheKey(start, goal, options)
    for i, cached in ipairs(PerformanceManager.PathCache) do
        if cached.key == cacheKey and os.clock() - cached.timestamp < 30 then
            table.remove(PerformanceManager.PathCache, i)
            table.insert(PerformanceManager.PathCache, cached)
            KynexFind._performanceMetrics.cacheHits = KynexFind._performanceMetrics.cacheHits + 1
            return cached.path
        end
    end
    return nil
end

function PerformanceManager._generateCacheKey(start, goal, options)
    return string.format("%s|%s|%d|%d|%s", 
        Vector3ToKey(start, 1), 
        Vector3ToKey(goal, 1),
        options.AgentSize or 2,
        options.MaxSlope or 45,
        options.AgentType or "humanoid"
    )
end

function PerformanceManager.CachePath(start, goal, options, path)
    if not path or #path == 0 then return end
    local cacheKey = PerformanceManager._generateCacheKey(start, goal, options)
    
    while #PerformanceManager.PathCache >= CONFIG.CACHE_SIZE do
        table.remove(PerformanceManager.PathCache, 1)
    end
    
    table.insert(PerformanceManager.PathCache, {
        key = cacheKey,
        path = path,
        timestamp = os.clock()
    })
end

local DataSanitizer = {}

function DataSanitizer.SanitizeVector3(vec, default)
    if typeof(vec) ~= "Vector3" then
        return default or Vector3.new()
    end
    
    if vec.X ~= vec.X or vec.Y ~= vec.Y or vec.Z ~= vec.Z then -- NaN check
        return default or Vector3.new()
    end
    
    if math.abs(vec.X) == math.huge or math.abs(vec.Y) == math.huge or math.abs(vec.Z) == math.huge then
        return default or Vector3.new()
    end
    
    -- Additional bounds checking
    local maxComponent = 1000000
    if math.abs(vec.X) > maxComponent or math.abs(vec.Y) > maxComponent or math.abs(vec.Z) > maxComponent then
        return default or Vector3.new()
    end
    
    return vec
end

function DataSanitizer.SanitizeOptions(options)
    local sanitized = options or {}
    sanitized.AgentSize = sanitized.AgentSize or 2
    sanitized.MaxSlope = sanitized.MaxSlope or 45
    sanitized.AllowSwimming = sanitized.AllowSwimming or false
    sanitized.AllowClimbing = sanitized.AllowClimbing or true
    sanitized.AgentType = sanitized.AgentType or "humanoid"
    sanitized.Priority = sanitized.Priority or "balanced"
    sanitized.useAdvancedTechniques = sanitized.useAdvancedTechniques or true
    
    sanitized.agentHeight = sanitized.agentHeight or 5
    if sanitized.agentHeight ~= sanitized.agentHeight then sanitized.agentHeight = 5 end
    if sanitized.agentHeight <= 0 then sanitized.agentHeight = 5 end
    if sanitized.agentHeight > 100 then sanitized.agentHeight = 100 end
    
    sanitized.AgentSize = math.clamp(sanitized.AgentSize, 0.1, 50)
    sanitized.MaxSlope = math.clamp(sanitized.MaxSlope, 0, 90)
    return sanitized
end

local ConnectionMonitor = {
    LastHeartbeat = os.clock(),
    HeartbeatInterval = 5,
    IsConnected = true,
    _connectionQuality = "excellent",
    _latencyHistory = {}
}

function ConnectionMonitor.EnsureConnected()
    if not ConnectionMonitor.CheckConnectionHealth() then
        return false, "disconnected"
    end
    return true, ConnectionMonitor._connectionQuality
end

function ConnectionMonitor.CheckConnectionHealth()
    local currentTime = os.clock()
    if currentTime - ConnectionMonitor.LastHeartbeat > ConnectionMonitor.HeartbeatInterval then
        ConnectionMonitor.LastHeartbeat = currentTime
        
        local startTime = os.clock()
        local success = pcall(function()
            return workspace:GetChildren()
        end)
        local endTime = os.clock()
        
        ConnectionMonitor.IsConnected = success
        
        local latency = (endTime - startTime) * 1000
        table.insert(ConnectionMonitor._latencyHistory, latency)
        
        if #ConnectionMonitor._latencyHistory > 10 then
            table.remove(ConnectionMonitor._latencyHistory, 1)
        end
        
        local avgLatency = 0
        for _, lat in ipairs(ConnectionMonitor._latencyHistory) do
            avgLatency = avgLatency + lat
        end
        avgLatency = SafeDivide(avgLatency, #ConnectionMonitor._latencyHistory, 0)
        
        if avgLatency < 10 then
            ConnectionMonitor._connectionQuality = "excellent"
        elseif avgLatency < 30 then
            ConnectionMonitor._connectionQuality = "good"
        elseif avgLatency < 100 then
            ConnectionMonitor._connectionQuality = "poor"
        else
            ConnectionMonitor._connectionQuality = "unstable"
        end
    end
    
    return ConnectionMonitor.IsConnected
end

local MapAnalyzer = {}

function MapAnalyzer.ScanEnvironment(workspace, center, radius, agentProfile)
    local analysis = {
        TerrainType = "unknown",
        GridSize = 4,
        ObstacleDensity = 0.0,
        Verticality = "low"
    }
    
    local success, parts = pcall(function()
        local region = ParkourSystem:CreateSafeRegion3(center, Vector3.new(radius * 2, radius * 2, radius * 2))
        return workspace:FindPartsInRegion3(region, nil, 500)
    end)
    
    if not success or not parts then return analysis end
    
    local totalParts = #parts
    local verticalParts = 0
    local obstacleCount = 0
    
    for _, part in ipairs(parts) do
        if not part:IsA("BasePart") then continue end
        local size = part.Size
        if size.Y > size.X * 1.5 and size.Y > size.Z * 1.5 then
            verticalParts = verticalParts + 1
        end
        if size.Y < (agentProfile and agentProfile.height or 5) then
            obstacleCount = obstacleCount + 1
        end
    end
    
    analysis.ObstacleDensity = SafeDivide(obstacleCount, math.max(totalParts, 1), 0)
    local verticalityRatio = SafeDivide(verticalParts, totalParts, 0)
    analysis.Verticality = verticalityRatio > 0.4 and "high" or 
                          verticalityRatio > 0.2 and "medium" or "low"
    
    if analysis.ObstacleDensity > 0.7 then
        analysis.TerrainType = "urban"
        analysis.GridSize = 2
    elseif analysis.ObstacleDensity > 0.4 then
        analysis.TerrainType = "hilly"
        analysis.GridSize = 3
    else
        analysis.TerrainType = "flat"
        analysis.GridSize = 5
    end
    
    ResourceMonitor.ObjectCounts.obstacles = ResourceMonitor.ObjectCounts.obstacles + obstacleCount
    
    return analysis
end

local parallelProcessor = ParallelProcessor.new()

-- Safe coroutine and delay functions
function KynexFind:RunSafeCoroutine(func, errorContext)
    coroutine.wrap(function()
        local success, err = pcall(func)
        if not success then
            warn(string.format("[KynexFind] Coroutine error in %s: %s", errorContext or "unknown", err))
        end
    end)()
end

function KynexFind:ProtectedDelay(delayTime, callback)
    task.delay(delayTime, function()
        local success, err = pcall(callback)
        if not success then
            warn("[KynexFind] Protected delay error: " .. tostring(err))
        end
    end)
end

function KynexFind:_UpdateStabilityScore(searchTime, success)
    local baseScore = KynexFind._performanceMetrics.stabilityScore
    
    local timeFactor = math.max(0, 1 - SafeDivide(searchTime, CONFIG.MAX_SEARCH_TIME, 1))
    local successFactor = success and 1.0 or 0.7
    local errorFactor = math.max(0.1, 1 - SafeDivide(ErrorHandler.ErrorCount, 100, 1))
    local memoryFactor = math.max(0.1, 1 - ResourceMonitor.CalculateMemoryPressure())
    
    local newScore = baseScore * 0.95 + (100 * timeFactor * successFactor * errorFactor * memoryFactor) * 0.05
    KynexFind._performanceMetrics.stabilityScore = math.clamp(newScore, 0, 100)
end

function KynexFind._FindPathInternal(startPos, endPos, options)
    startPos = DataSanitizer.SanitizeVector3(startPos)
    endPos = DataSanitizer.SanitizeVector3(endPos)
    options = DataSanitizer.SanitizeOptions(options)
    
    local connectionOk, quality = ConnectionMonitor.EnsureConnected()
    if not connectionOk then
        return nil, {status = "system_unavailable", quality = quality}
    end
    
    local systemHealth = HealthMonitor:CheckAllComponents()
    if systemHealth == "unhealthy" then
        return nil, {status = "system_unhealthy", message = "System components degraded"}
    end
    
    KynexFind._performanceMetrics.totalSearches = KynexFind._performanceMetrics.totalSearches + 1
    local searchStartTime = os.clock()
    
    local timedOut = ProgressMonitor.CheckTimeouts()
    if timedOut > 0 then
        warn(string.format("[KynexFind] %d searches timed out, system may be under heavy load", timedOut))
    end
    
    local cachedPath = PerformanceManager.GetCachedPath(startPos, endPos, options)
    if cachedPath then
        local searchTime = os.clock() - searchStartTime
        KynexFind._performanceMetrics.averageSearchTime = 
            Lerp(KynexFind._performanceMetrics.averageSearchTime, searchTime, 0.1)
        return cachedPath, {fromCache = true, searchTime = searchTime}
    end
    
    local agentProfile = CONFIG.DEFAULT_AGENT_PROFILES[options.AgentType] or CONFIG.DEFAULT_AGENT_PROFILES.humanoid
    agentProfile.allowSwimming = options.AllowSwimming
    agentProfile.allowClimbing = options.AllowClimbing
    agentProfile.priority = options.Priority
    
    local center = (startPos + endPos) / 2
    local radius = EuclideanDistance(startPos, endPos) / 2
    local terrainProfile = MapAnalyzer.ScanEnvironment(workspace, center, radius, agentProfile)
    
    local searchId = string.format("search_%f", os.clock())
    ProgressMonitor.StartSearch(searchId, startPos, endPos)
    
    local paths, metrics = parallelProcessor:executeParallel(startPos, endPos, options, terrainProfile, agentProfile)
    
    local bestPath, bestProcessor = parallelProcessor:selectBestPath(paths, metrics, startPos, endPos, terrainProfile)
    
    if bestPath then
        PerformanceManager.CachePath(startPos, endPos, options, bestPath)
    else
        KynexFind._performanceMetrics.failedSearches = KynexFind._performanceMetrics.failedSearches + 1
    end
    
    ProgressMonitor.EndSearch(searchId)
    
    local totalSearchTime = os.clock() - searchStartTime
    local resultMetrics = {
        searchTime = totalSearchTime,
        status = bestPath and "success" or "no_path",
        processorUsed = bestProcessor,
        neuralPrediction = true,
        memoryUsage = MemoryManager:GetCurrentMemoryUsage(),
        systemHealth = systemHealth
    }
    
    KynexFind._performanceMetrics.averageSearchTime = 
        Lerp(KynexFind._performanceMetrics.averageSearchTime, totalSearchTime, 0.1)
    KynexFind._performanceMetrics.peakSearchTime = 
        math.max(KynexFind._performanceMetrics.peakSearchTime, totalSearchTime)
    
    KynexFind:_UpdateStabilityScore(totalSearchTime, bestPath ~= nil)
    
    return bestPath, resultMetrics
end

function KynexFind.FindPath(startPos, endPos, options)
    local identifier = tostring(startPos) .. tostring(endPos)
    if not RateLimiter:CheckLimit(identifier) then
        return nil, {status = "rate_limited", message = "Too many requests"}
    end
    
    if not WorkloadBalancer:CanProcessRequest() then
        WorkloadBalancer:DeferOperation(KynexFind.FindPath, startPos, endPos, options)
        return nil, {status = "deferred", message = "Request queued for next frame"}
    end
    
    local result = CircuitBreaker:Execute("FindPath", function()
        return KynexFind._FindPathInternal(startPos, endPos, options)
    end, function()
        return nil, {status = "circuit_breaker_open", message = "System recovering from errors"}
    end)
    
    return result
end

function KynexFind.FindPathAsync(startPos, endPos, options, callback)
    if not WorkloadBalancer:CanProcessRequest() then
        WorkloadBalancer:DeferOperation(KynexFind.FindPathAsync, startPos, endPos, options, callback)
        return {status = "deferred"}
    end
    
    KynexFind:RunSafeCoroutine(function()
        local path, metrics = KynexFind.FindPath(startPos, endPos, options)
        if callback then 
            callback(path, metrics) 
        end
    end, "FindPathAsync")
    
    return {status = "processing"}
end

-- NEW V2.0 ADVANCED FUNCTIONS
function KynexFind.FindPathWithAdvancedParkour(startPos, endPos, character, options)
    options = options or {}
    options.AgentType = "parkour_master"
    options.useAdvancedTechniques = true
    
    local path, metrics = KynexFind.FindPath(startPos, endPos, options)
    
    if path and character then
        ParkourSystem:UpdateCharacterState(character, {
            currentPath = path,
            pathIndex = 1,
            goalPosition = endPos,
            options = options,
            advancedTechniquesEnabled = true
        })
    end
    
    return path, metrics
end

function KynexFind.ExecuteAdvancedTechnique(character, techniqueType, targetData)
    local success = false
    
    if techniqueType == "ladder_flick" then
        success = ParkourSystem:ExecuteLadderFlick(character, targetData)
    elseif techniqueType == "wallhop_chain" then
        success = ParkourSystem:ExecuteWallhopChain(character, targetData)
    elseif techniqueType == "wrap_around" then
        success = ParkourSystem:ExecuteWrapAround(character, targetData)
    elseif techniqueType == "corner_climb" then
        success = ParkourSystem:ExecuteCornerClimb(character, targetData)
    end
    
    return success
end

function KynexFind.ScanForAdvancedOpportunities(character, goalPosition)
    return ParkourSystem:ScanForAdvancedOpportunities(character, goalPosition)
end

function KynexFind.GetOptimalAdvancedTechnique(character, goalPosition)
    return ParkourSystem:GetOptimalAdvancedManeuver(character, goalPosition)
end

function KynexFind.GetFlowStateMetrics()
    return {
        currentFlowState = ParkourSystem._currentFlowState,
        styleScore = ParkourSystem._styleScore,
        techniqueChain = ParkourSystem._techniqueChain,
        flowDuration = KynexFind._performanceMetrics.advancedTechniques.flowStateDuration
    }
end

function KynexFind.GetAdvancedTechniqueMetrics()
    return KynexFind._performanceMetrics.advancedTechniques
end

-- Update existing functions with advanced features
function KynexFind.GetCharacterAbdomenPosition(character)
    return ParkourSystem:GetCharacterAbdomenPosition(character)
end

function KynexFind.MoveToGoal(character, goalPosition, options)
    return ParkourSystem:MoveCharacterToGoal(character, goalPosition, options)
end

function KynexFind.EnableParkourForCharacter(character, enabled)
    if not character then return false end
    ParkourSystem:UpdateCharacterState(character, enabled and "parkour_enabled" or "parkour_disabled")
    return true
end

function KynexFind.GetParkourObstacles(character, goalPosition)
    return ParkourSystem:ScanForParkourObstacles(character, goalPosition)
end

function KynexFind.ExecuteParkourManeuver(character, maneuverType, obstacle)
    return ParkourSystem:ExecuteParkourManeuver(character, maneuverType, obstacle)
end

function KynexFind.FindPathWithParkour(startPos, endPos, character, options)
    options = options or {}
    options.AgentType = "parkour"
    options.useParkour = true
    options.useAdvancedTechniques = options.useAdvancedTechniques or true
    
    local path, metrics = KynexFind.FindPath(startPos, endPos, options)
    
    if path and character then
        ParkourSystem:UpdateCharacterState(character, {
            currentPath = path,
            pathIndex = 1,
            goalPosition = endPos,
            options = options
        })
    end
    
    return path, metrics
end

function KynexFind.StartAutoMovement(character, goalPosition, options)
    if not character then return false end
    
    options = options or {}
    local abdomenPos = ParkourSystem:GetCharacterAbdomenPosition(character)
    
    if not abdomenPos then return false end
    
    local path, metrics = KynexFind.FindPathWithAdvancedParkour(abdomenPos, goalPosition, character, options)
    
    if not path then
        warn("[KynexFind] No path found for auto movement")
        return false
    end
    
    ParkourSystem:UpdateCharacterState(character, {
        mode = "auto_movement",
        path = path,
        currentWaypoint = 1,
        goalPosition = goalPosition,
        options = options,
        startTime = os.clock()
    })
    
    ParkourSystem._autoMovementCharacters[character] = true
    
    KynexFind:RunSafeCoroutine(function()
        local state = ParkourSystem:GetCharacterState(character)
        while state and state.mode == "auto_movement" and state.currentWaypoint <= #state.path do
            local waypoint = state.path[state.currentWaypoint]
            local reached = ParkourSystem:MoveCharacterToGoal(character, waypoint, state.options)
            
            local currentPos = ParkourSystem:GetCharacterAbdomenPosition(character)
            if currentPos and (waypoint - currentPos).Magnitude < CONFIG.PARKOUR_CONFIG.WAYPOINT_TOLERANCE then
                state.currentWaypoint = state.currentWaypoint + 1
            end
            
            task.wait(0.1)
            state = ParkourSystem:GetCharacterState(character)
            
            if currentPos and (goalPosition - currentPos).Magnitude < CONFIG.PARKOUR_CONFIG.ARRIVAL_DISTANCE then
                break
            end
        end
        
        if character and character.Parent then
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart then
                humanoid:MoveTo(rootPart.Position)
            end
        end
        
        ParkourSystem._autoMovementCharacters[character] = nil
        ParkourSystem:UpdateCharacterState(character, "idle")
        
        print("[KynexFind] Auto movement completed")
    end, "AutoMovement")
    
    return true
end

function KynexFind.StopAutoMovement(character)
    if not character then return false end
    
    ParkourSystem:UpdateCharacterState(character, "idle")
    ParkourSystem._autoMovementCharacters[character] = nil
    
    if character and character.Parent then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart then
            humanoid:MoveTo(rootPart.Position)
        end
    end
    
    return true
end

function KynexFind.IsCharacterMoving(character)
    if not character then return false end
    local state = ParkourSystem:GetCharacterState(character)
    return state and state.mode == "auto_movement"
end

-- Update performance metrics to include advanced techniques
function KynexFind.GetPerformanceMetrics()
    local totalSearches = math.max(KynexFind._performanceMetrics.totalSearches, 1)
    local metrics = {
        totalSearches = KynexFind._performanceMetrics.totalSearches,
        cacheHits = KynexFind._performanceMetrics.cacheHits,
        failedSearches = KynexFind._performanceMetrics.failedSearches,
        cacheHitRate = SafeDivide(KynexFind._performanceMetrics.cacheHits, totalSearches, 0),
        averageSearchTime = KynexFind._performanceMetrics.averageSearchTime,
        peakSearchTime = KynexFind._performanceMetrics.peakSearchTime,
        neuralPredictions = KynexFind._performanceMetrics.neuralPredictions,
        stabilityScore = KynexFind._performanceMetrics.stabilityScore,
        smallObjectDetectionCount = KynexFind._performanceMetrics.smallObjectDetectionCount,
        smallObjectAccuracy = KynexFind._performanceMetrics.smallObjectAccuracy,
        movingObjectsTracked = KynexFind._performanceMetrics.movingObjectsTracked,
        memoryCleanupCount = KynexFind._performanceMetrics.memoryCleanupCount,
        circuitBreakerTrips = KynexFind._performanceMetrics.circuitBreakerTrips,
        rateLimitHits = KynexFind._performanceMetrics.rateLimitHits,
        deferredOperations = KynexFind._performanceMetrics.deferredOperations,
        parkourManeuvers = KynexFind._performanceMetrics.parkourManeuvers,
        obstaclesDetected = KynexFind._performanceMetrics.obstaclesDetected,
        currentMemoryUsage = MemoryManager:GetCurrentMemoryUsage(),
        memoryPressure = ResourceMonitor.CalculateMemoryPressure(),
        circuitBreakerState = CircuitBreaker.state,
        systemHealth = HealthMonitor:CheckAllComponents(),
        averageSearchTimeHistorical = ProgressMonitor.GetAverageSearchTime(),
        activeAutoMovements = 0,
        advancedTechniques = KynexFind._performanceMetrics.advancedTechniques
    }
    
    for _ in pairs(ParkourSystem._autoMovementCharacters) do
        metrics.activeAutoMovements = metrics.activeAutoMovements + 1
    end
    
    return metrics
end

function KynexFind.GetNeuralNetworkInfo()
    return {
        inputSize = 15,
        hiddenLayers = CONFIG.NEURAL_HIDDEN_LAYERS,
        outputSize = CONFIG.PARALLEL_PROCESSORS,
        learningRate = CONFIG.NEURAL_LEARNING_RATE,
        parallelProcessors = CONFIG.PARALLEL_PROCESSORS
    }
end

function KynexFind.GetParkourMetrics()
    local activeCount = 0
    for _ in pairs(ParkourSystem._activeManeuvers) do
        activeCount = activeCount + 1
    end
    
    local stateCount = 0
    for _ in pairs(ParkourSystem._characterStates) do
        stateCount = stateCount + 1
    end
    
    local obstacleCount = 0
    for _ in pairs(ParkourSystem._obstacleCache) do
        obstacleCount = obstacleCount + 1
    end
    
    local autoCount = 0
    for _ in pairs(ParkourSystem._autoMovementCharacters) do
        autoCount = autoCount + 1
    end
    
    return {
        activeManeuvers = activeCount,
        characterStates = stateCount,
        cachedObstacles = obstacleCount,
        lastManeuverTime = ParkourSystem._lastManeuverTime,
        autoMovementCharacters = autoCount,
        flowState = ParkourSystem._currentFlowState,
        styleScore = ParkourSystem._styleScore,
        techniqueChainLength = #ParkourSystem._techniqueChain
    }
end

function KynexFind.ResetNeuralNetwork()
    parallelProcessor = ParallelProcessor.new()
    print("[KynexFind] Neural network reset completed")
    return true
end

function KynexFind.ForceCleanup()
    MemoryManager:EmergencyCleanup()
    return "Cleanup completed"
end

function KynexFind.ResetSystem()
    ErrorHandler.ResetErrorState()
    CircuitBreaker.state = "CLOSED"
    CircuitBreaker.failureCount = 0
    MemoryManager:EmergencyCleanup()
    KynexFind.ResetNeuralNetwork()
    
    ParkourSystem._activeManeuvers = {}
    ParkourSystem._characterStates = {}
    ParkourSystem._obstacleCache = {}
    ParkourSystem._autoMovementCharacters = {}
    ParkourSystem._techniqueHistory = {}
    ParkourSystem._flowStateStartTime = os.clock()
    ParkourSystem._currentFlowState = 0
    ParkourSystem._styleScore = 0
    ParkourSystem._techniqueChain = {}
    ParkourSystem._advancedOpportunities = {}
    
    return "System reset completed"
end

function KynexFind.GetSystemStatus()
    local activeSearches = 0
    for _ in pairs(ProgressMonitor.ActiveSearches) do
        activeSearches = activeSearches + 1
    end
    
    local autoMovements = 0
    for _ in pairs(ParkourSystem._autoMovementCharacters) do
        autoMovements = autoMovements + 1
    end
    
    return {
        initialized = KynexFind._initialized,
        stabilityScore = KynexFind._performanceMetrics.stabilityScore,
        circuitBreaker = CircuitBreaker:GetHealth(),
        memoryUsage = MemoryManager:GetCurrentMemoryUsage(),
        connectionQuality = ConnectionMonitor._connectionQuality,
        activeSearches = activeSearches,
        deferredOperations = #WorkloadBalancer._deferredOperations,
        parkourEnabled = true,
        autoMovementsActive = autoMovements,
        advancedTechniquesEnabled = true,
        flowState = ParkourSystem._currentFlowState,
        styleMastery = ParkourSystem:GetCharacterStyleMastery(nil)
    }
end

-- Initialize the enhanced system
function KynexFind.InitializeAdvancedParkour()
    if not KynexFind._initialized then
        KynexFind.Initialize()
    end
    
    -- Additional initialization for advanced techniques
    ParkourSystem._flowStateStartTime = os.clock()
    ParkourSystem._currentFlowState = 0
    ParkourSystem._styleScore = 0
    ParkourSystem._techniqueChain = {}
    ParkourSystem._lastFlowUpdate = os.clock()
    
    print("KynexFind Neural Parkour v2.0 - Advanced Techniques Initialized")
    print("Movement Philosophy: 'Every surface is an opportunity, every obstacle is an invitation for creativity'")
    
    return true
end

function KynexFind.Initialize()
    if KynexFind._initialized then return true end
    
    local success = ErrorHandler.SafeExecute(function()
        HealthMonitor:RegisterComponent("MemoryManager", function()
            local memoryPressure = ResourceMonitor.CalculateMemoryPressure()
            return memoryPressure < 0.9 and "healthy" or "degraded"
        end)
        
        HealthMonitor:RegisterComponent("NeuralNetwork", function()
            return parallelProcessor and parallelProcessor.neuralNetwork and "healthy" or "degraded"
        end)
        
        HealthMonitor:RegisterComponent("PathCache", function()
            return PerformanceManager.PathCache and #PerformanceManager.PathCache < CONFIG.CACHE_SIZE * 2 and "healthy" or "degraded"
        end)
        
        HealthMonitor:RegisterComponent("ParkourSystem", function()
            return ParkourSystem and "healthy" or "degraded"
        end)
        
        HealthMonitor:RegisterComponent("AdvancedTechniques", function()
            return ParkourSystem._currentFlowState > 0 and "healthy" or "degraded"
        end)
        
        KynexFind:RunSafeCoroutine(function()
            while true do
                ErrorHandler.ResetErrorState()
                ResourceMonitor.CheckResourceHealth()
                ConnectionMonitor.CheckConnectionHealth()
                HealthMonitor:CheckAllComponents()
                WorkloadBalancer:ProcessDeferred()
                task.wait(5)
            end
        end, "SystemMonitor")
        
        KynexFind:RunSafeCoroutine(function()
            while true do
                ProgressMonitor.CheckTimeouts()
                task.wait(1)
            end
        end, "TimeoutMonitor")
        
        KynexFind._initialized = true
        KynexFind.InitializeAdvancedParkour()
        print("KynexFind Neural SUPER STABLE PRODUCTION with Advanced Parkour System v2.0 initialized successfully")
        return true
    end, "System initialization", function()
        warn("[KynexFind] Initialization failed, system will operate in fallback mode")
        return false
    end)
    
    return success
end

local initSuccess = KynexFind.Initialize()
if not initSuccess then
    warn("[KynexFind] Auto-initialization failed, system will initialize on first use")
end

return KynexFind
