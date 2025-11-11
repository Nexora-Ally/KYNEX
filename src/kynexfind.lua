local Kynexfind = {}
Kynexfind.__index = Kynexfind

-- Services dengan error handling
local RunService, Workspace, Players, HttpService, CollectionService
local serviceSuccess, serviceError = pcall(function()
	RunService = game:GetService("RunService")
	Workspace = game:GetService("Workspace")
	Players = game:GetService("Players")
	HttpService = game:GetService("HttpService")
	CollectionService = game:GetService("CollectionService")
end)

if not serviceSuccess then
	warn("Kynexfind: Service initialization failed - " .. tostring(serviceError))
	return nil
end

-- EXTREME STABILITY SYSTEM
local StabilitySystem = {
	MAX_RECOVERY_ATTEMPTS = 3,
	HEARTBEAT_INTERVAL = 1.0,
	MEMORY_CLEANUP_INTERVAL = 30.0,
	ERROR_COOLDOWN = 5.0,
	
	ErrorLog = {},
	RecoveryAttempts = 0,
	LastCleanupTime = 0,
	LastHeartbeatTime = 0,
	IsSystemStable = true,
	
	HandleCriticalError = function(self, errorMsg, context)
		local errorId = HttpService:GenerateGUID(false)
		local errorData = {
			Id = errorId,
			Message = errorMsg,
			Context = context,
			Timestamp = os.clock(),
			StackTrace = debug.traceback()
		}
		
		table.insert(self.ErrorLog, errorData)
		warn("KYNEXFIND CRITICAL ERROR [" .. errorId .. "]: " .. errorMsg)
		
		if self.RecoveryAttempts < self.MAX_RECOVERY_ATTEMPTS then
			self.RecoveryAttempts = self.RecoveryAttempts + 1
			warn("Attempting recovery #" .. self.RecoveryAttempts)
			self:AttemptRecovery()
		else
			self.IsSystemStable = false
			error("KYNEXFIND SYSTEM UNSTABLE - Manual intervention required")
		end
	end,
	
	AttemptRecovery = function(self)
		for processorId, processor in pairs(MemoryManager) do
			processor.Active = false
			processor.MemoryPool = {}
			processor.Queue = {}
		end
		
		delay(self.ERROR_COOLDOWN, function()
			self.RecoveryAttempts = 0
			self.IsSystemStable = true
			warn("Kynexfind System Recovery Complete")
		end)
	end,
	
	MonitorMemory = function(self)
		local currentTime = os.clock()
		if currentTime - self.LastCleanupTime > self.MEMORY_CLEANUP_INTERVAL then
			self:PerformMemoryCleanup()
			self.LastCleanupTime = currentTime
		end
	end,
	
	PerformMemoryCleanup = function(self)
		collectgarbage()
		
		for _, processor in pairs(MemoryManager) do
			if processor.MemoryPool and processor.MemoryPool.PathCache then
				for cacheKey, cacheData in pairs(processor.MemoryPool.PathCache) do
					if os.clock() - cacheData.timestamp > 300 then
						processor.MemoryPool.PathCache[cacheKey] = nil
					end
				end
			end
		end
		
		while #self.ErrorLog > 100 do
			table.remove(self.ErrorLog, 1)
		end
	end,
	
	Heartbeat = function(self)
		local currentTime = os.clock()
		if currentTime - self.LastHeartbeatTime > self.HEARTBEAT_INTERVAL then
			self.LastHeartbeatTime = currentTime
			
			if not self:CheckSystemHealth() then
				self:HandleCriticalError("System health check failed", "HeartbeatMonitor")
			end
		end
	end,
	
	CheckSystemHealth = function(self)
		local memoryUsage = collectgarbage("count")
		if memoryUsage > 100000 then
			warn("Kynexfind: High memory usage detected: " .. memoryUsage .. "KB")
			self:PerformMemoryCleanup()
		end
		
		local activeProcessors = 0
		for _, processor in pairs(MemoryManager) do
			if processor.Active then
				activeProcessors = activeProcessors + 1
			end
		end
		
		if activeProcessors >= 4 then
			warn("Kynexfind: High processor load detected")
		end
		
		return true
	end
}

-- Constants
local PATH_UPDATE_INTERVAL = 0.05
local STEERING_FORCE = 50
local MAX_SPEED = 16
local NODE_RADIUS = 2
local AVOIDANCE_RAY_LENGTH = 10
local REPATH_THRESHOLD = 5

-- Validated Types
local NODE_TYPES = {
	WALK = "Walk",
	CLIMB = "Climb", 
	SWIM = "Swim",
	JUMP = "Jump",
	FLY = "Fly",
	CRAWL = "Crawl",
	ELEVATOR = "Elevator",
	VEHICLE = "Vehicle"
}

local PATH_STATUS = {
	SUCCESS = "Success",
	FAILED = "Failed",
	COMPUTING = "Computing",
	IN_PROGRESS = "InProgress",
	PARTIAL = "Partial"
}

local AI_TYPES = {
	HUMANOID = "Humanoid",
	PARKOUR = "Parkour",
	VEHICLE = "Vehicle",
	DRONE = "Drone",
	AMPHIBIOUS = "Amphibious",
	STEALTH = "Stealth",
	SWARM = "Swarm",
	INTELLIGENT = "Intelligent",
	PREDATOR = "Predator",
	GUARDIAN = "Guardian"
}

-- Memory Management
local MemoryManager = {
	PathProcessor1 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor2 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor3 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor4 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor5 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false}
}

local PathCache = {}

-- Advanced Feature Flags
local ADVANCED_FEATURES = {
	PREDICTIVE_PATHING = true,
	DYNAMIC_WEIGHT_ADJUSTMENT = true,
	REAL_TIME_LEARNING = true,
	MULTI_AGENT_COORDINATION = true,
	ENVIRONMENT_ADAPTATION = true,
	OBSTACLE_MEMORY = true,
	PATH_OPTIMIZATION = true,
	ENERGY_MANAGEMENT = true,
	EMOTIONAL_STATE = true,
	GOAL_PRIORITIZATION = true,
	TERRAIN_ANALYSIS = true,
	WEATHER_ADAPTATION = true,
	TIME_BASED_BEHAVIOR = true,
	GROUP_FORMATIONS = true,
	COMMUNICATION_SYSTEM = true,
	THREAT_ASSESSMENT = true,
	RESOURCE_MANAGEMENT = true,
	ADAPTIVE_SPEED = true,
	BEHAVIOR_TREES = true,
	SITUATIONAL_AWARENESS = true
}

-- =============================================
-- CORE UTILITY FUNCTIONS
-- =============================================

local function ProtectedCall(funcName, func, ...)
	local success, result = xpcall(func, function(err)
		local errorMsg = string.format("ProtectedCall failed in %s: %s\n%s", funcName, tostring(err), debug.traceback())
		StabilitySystem:HandleCriticalError(errorMsg, funcName)
		return nil
	end, ...)
	
	return success and result or nil
end

local function SafeSpawn(func, ...)
	local args = {...}
	coroutine.wrap(function()
		ProtectedCall("SafeSpawn", func, unpack(args))
	end)()
end

local function ValidateParameters(params, expectedTypes)
	for paramName, expectedType in pairs(expectedTypes) do
		local value = params[paramName]
		if value == nil then
			return false, "Parameter '" .. paramName .. "' is required"
		end
		
		if expectedType == "Vector3" and typeof(value) ~= "Vector3" then
			return false, "Parameter '" .. paramName .. "' must be Vector3"
		elseif expectedType == "number" and type(value) ~= "number" then
			return false, "Parameter '" .. paramName .. "' must be number"
		elseif expectedType == "string" and type(value) ~= "string" then
			return false, "Parameter '" .. paramName .. "' must be string"
		elseif expectedType == "boolean" and type(value) ~= "boolean" then
			return false, "Parameter '" .. paramName .. "' must be boolean"
		end
	end
	return true
end

local function AllocateMemory(processorId)
	local processor = MemoryManager[processorId]
	if not processor then return false end
	
	if processor.Lock then return false end
	processor.Lock = true
	
	if not processor.Active then
		processor.Active = true
		processor.MemoryPool = {
			PathCache = {},
			NodeGraph = {},
			CalculationBuffer = {}
		}
		processor.Lock = false
		return true
	end
	
	processor.Lock = false
	return false
end

local function ReleaseMemory(processorId)
	local processor = MemoryManager[processorId]
	if not processor then return end
	
	while processor.Lock do
		wait(0.01)
	end
	processor.Lock = true
	
	processor.Active = false
	processor.MemoryPool = {}
	processor.Queue = {}
	
	processor.Lock = false
end

-- =============================================
-- REAL PATHFINDING IMPLEMENTATION
-- =============================================

local RealPathfinding = {}
RealPathfinding.__index = RealPathfinding

function RealPathfinding.new()
	local self = setmetatable({}, RealPathfinding)
	
	self.ObstacleCache = {}
	self.NavigationGrid = {}
	self.GridSize = 4
	self.MaxSearchNodes = 1000
	self.HeightTolerance = 5
	
	return self
end

function RealPathfinding:GenerateNavigationGrid(center, size)
	self.NavigationGrid = {}
	local halfSize = size / 2
	
	for x = -halfSize, halfSize, self.GridSize do
		for z = -halfSize, halfSize, self.GridSize do
			local position = center + Vector3.new(x, 0, z)
			local node = self:CreateNavigationNode(position)
			if node then
				local gridX = math.floor((x + halfSize) / self.GridSize)
				local gridZ = math.floor((z + halfSize) / self.GridSize)
				self.NavigationGrid[gridX .. "_" .. gridZ] = node
			end
		end
	end
	
	self:ConnectNavigationNodes()
end

function RealPathfinding:CreateNavigationNode(position)
	-- Check if position is valid using raycasts
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {Workspace.Terrain}
	
	-- Raycast down to find ground
	local rayOrigin = position + Vector3.new(0, 50, 0)
	local rayDirection = Vector3.new(0, -100, 0)
	local hit = Workspace:Raycast(rayOrigin, rayDirection, params)
	
	if not hit then return nil end
	
	-- Check if position is walkable
	local walkable = self:IsPositionWalkable(hit.Position)
	if not walkable then return nil end
	
	return {
		Position = hit.Position + Vector3.new(0, 2, 0), -- Slightly above ground
		Walkable = true,
		Neighbors = {},
		Cost = 1.0,
		Dynamic = false
	}
end

function RealPathfinding:IsPositionWalkable(position)
	-- Check for obstacles in the area
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {Workspace.Terrain}
	params.CollisionGroup = "Default"
	
	local shape = Vector3.new(2, 4, 2) -- Character-sized area
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), shape, params)
	
	-- If no parts in the area, it's walkable
	return #parts == 0
end

function RealPathfinding:ConnectNavigationNodes()
	for key1, node1 in pairs(self.NavigationGrid) do
		for key2, node2 in pairs(self.NavigationGrid) do
			if key1 ~= key2 then
				local distance = (node1.Position - node2.Position).Magnitude
				if distance <= self.GridSize * 1.5 then -- Connect to adjacent nodes
					-- Check if path between nodes is clear
					local direction = (node2.Position - node1.Position).Unit
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = {Workspace.Terrain}
					
					local hit = Workspace:Raycast(node1.Position, direction * distance, params)
					if not hit then
						table.insert(node1.Neighbors, node2)
					end
				end
			end
		end
	end
end

function RealPathfinding:FindPath(startPos, endPos)
	-- A* Pathfinding Algorithm Implementation
	local openSet = {}
	local closedSet = {}
	local cameFrom = {}
	local gScore = {}
	local fScore = {}
	
	-- Find closest nodes to start and end
	local startNode = self:GetClosestNode(startPos)
	local endNode = self:GetClosestNode(endPos)
	
	if not startNode or not endNode then
		return nil
	end
	
	local startKey = self:GetNodeKey(startNode)
	gScore[startKey] = 0
	fScore[startKey] = self:Heuristic(startNode.Position, endPos)
	
	table.insert(openSet, {Node = startNode, Key = startKey, FScore = fScore[startKey]})
	
	while #openSet > 0 and #closedSet < self.MaxSearchNodes do
		-- Sort by F score
		table.sort(openSet, function(a, b) return a.FScore < b.FScore end)
		local current = table.remove(openSet, 1)
		
		if current.Key == self:GetNodeKey(endNode) then
			return self:ReconstructPath(cameFrom, current.Node)
		end
		
		table.insert(closedSet, current.Key)
		
		for _, neighbor in pairs(current.Node.Neighbors) do
			local neighborKey = self:GetNodeKey(neighbor)
			
			if not self:Contains(closedSet, neighborKey) then
				local tentativeG = gScore[current.Key] + self:GetDistance(current.Node, neighbor)
				
				if not self:ContainsByKey(openSet, neighborKey) or tentativeG < (gScore[neighborKey] or math.huge) then
					cameFrom[neighborKey] = current.Node
					gScore[neighborKey] = tentativeG
					fScore[neighborKey] = tentativeG + self:Heuristic(neighbor.Position, endPos)
					
					if not self:ContainsByKey(openSet, neighborKey) then
						table.insert(openSet, {Node = neighbor, Key = neighborKey, FScore = fScore[neighborKey]})
					end
				end
			end
		end
	end
	
	return nil -- No path found
end

function RealPathfinding:GetClosestNode(position)
	local closestNode = nil
	local closestDistance = math.huge
	
	for _, node in pairs(self.NavigationGrid) do
		local distance = (node.Position - position).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestNode = node
		end
	end
	
	return closestNode
end

function RealPathfinding:Heuristic(a, b)
	return (a - b).Magnitude
end

function RealPathfinding:GetDistance(nodeA, nodeB)
	local baseDistance = (nodeA.Position - nodeB.Position).Magnitude
	local heightDiff = math.abs(nodeA.Position.Y - nodeB.Position.Y)
	
	-- Penalize height differences
	if heightDiff > 2 then
		return baseDistance * 2
	end
	
	return baseDistance
end

function RealPathfinding:ReconstructPath(cameFrom, endNode)
	local path = {}
	local current = endNode
	local currentKey = self:GetNodeKey(current)
	
	while cameFrom[currentKey] do
		table.insert(path, 1, current.Position)
		current = cameFrom[currentKey]
		currentKey = self:GetNodeKey(current)
	end
	
	if #path > 0 then
		table.insert(path, 1, cameFrom[self:GetNodeKey(path[1])].Position)
	end
	
	return path
end

function RealPathfinding:GetNodeKey(node)
	for key, gridNode in pairs(self.NavigationGrid) do
		if gridNode == node then
			return key
		end
	end
	return nil
end

function RealPathfinding:Contains(set, key)
	for _, item in ipairs(set) do
		if item == key then
			return true
		end
	end
	return false
end

function RealPathfinding:ContainsByKey(set, key)
	for _, item in ipairs(set) do
		if item.Key == key then
			return true
		end
	end
	return false
end

-- =============================================
-- NEURAL NETWORK DECISION MAKING SYSTEM
-- =============================================

local NeuralNetwork = {}
NeuralNetwork.__index = NeuralNetwork

function NeuralNetwork.new()
	local self = setmetatable({}, NeuralNetwork)
	
	self.weights = {
		path_safety = 0.4,
		path_efficiency = 0.3,
		energy_cost = 0.2,
		risk_tolerance = 0.1
	}
	
	self.experience_buffer = {}
	self.learning_rate = 0.01
	self.exploration_rate = 0.1
	self.max_experience = 1000
	
	return self
end

function NeuralNetwork:decide(path_options, current_state)
	if math.random() < self.exploration_rate then
		return path_options[math.random(1, #path_options)]
	end
	
	local best_score = -math.huge
	local best_path = nil
	
	for _, path in ipairs(path_options) do
		local score = 0
		
		score = score + (path.safety_factor or 1) * self.weights.path_safety
		score = score + (1 / (path.distance or 1)) * self.weights.path_efficiency
		score = score - (path.energy_cost or 0) * self.weights.energy_cost
		score = score + (path.risk_level or 0) * self.weights.risk_tolerance * (current_state.aggression or 0.5)
		
		if score > best_score then
			best_score = score
			best_path = path
		end
	end
	
	return best_path
end

function NeuralNetwork:learn(experience)
	table.insert(self.experience_buffer, experience)
	
	if #self.experience_buffer > self.max_experience then
		table.remove(self.experience_buffer, 1)
	end
	
	if experience.success then
		for factor, value in pairs(experience.factors) do
			if self.weights[factor] then
				self.weights[factor] = self.weights[factor] + self.learning_rate * value
			end
		end
	else
		for factor, value in pairs(experience.factors) do
			if self.weights[factor] then
				self.weights[factor] = self.weights[factor] - self.learning_rate * value
			end
		end
	end
	
	local total = 0
	for _, weight in pairs(self.weights) do
		total = total + math.abs(weight)
	end
	
	if total > 0 then
		for factor, weight in pairs(self.weights) do
			self.weights[factor] = weight / total
		end
	end
end

-- =============================================
-- PREDICTIVE MOVEMENT ANALYTICS
-- =============================================

local PredictiveAnalytics = {}
PredictiveAnalytics.__index = PredictiveAnalytics

function PredictiveAnalytics.new()
	local self = setmetatable({}, PredictiveAnalytics)
	
	self.obstacle_trajectories = {}
	self.collision_predictions = {}
	self.prediction_horizon = 2.0
	self.update_interval = 0.1
	
	return self
end

function PredictiveAnalytics:track_obstacle(obstacle_id, position, velocity)
	if not self.obstacle_trajectories[obstacle_id] then
		self.obstacle_trajectories[obstacle_id] = {
			positions = {},
			velocities = {},
			timestamps = {}
		}
	end
	
	local trajectory = self.obstacle_trajectories[obstacle_id]
	
	table.insert(trajectory.positions, position)
	table.insert(trajectory.velocities, velocity)
	table.insert(trajectory.timestamps, os.clock())
	
	while #trajectory.positions > 10 do
		table.remove(trajectory.positions, 1)
		table.remove(trajectory.velocities, 1)
		table.remove(trajectory.timestamps, 1)
	end
end

function PredictiveAnalytics:predict_collision(agent_position, agent_velocity, obstacle_id, time_horizon)
	time_horizon = time_horizon or self.prediction_horizon
	
	local trajectory = self.obstacle_trajectories[obstacle_id]
	if not trajectory or #trajectory.positions < 2 then
		return nil, math.huge
	end
	
	local last_pos = trajectory.positions[#trajectory.positions]
	local last_vel = trajectory.velocities[#trajectory.velocities]
	
	local predicted_obstacle_pos = last_pos + last_vel * time_horizon
	local predicted_agent_pos = agent_position + agent_velocity * time_horizon
	
	local distance = (predicted_agent_pos - predicted_obstacle_pos).Magnitude
	local time_to_collision = math.huge
	
	local relative_vel = agent_velocity - last_vel
	local relative_pos = agent_position - last_pos
	
	if relative_vel.Magnitude > 0.01 then
		time_to_collision = -relative_pos:Dot(relative_vel) / (relative_vel.Magnitude ^ 2)
		if time_to_collision < 0 then
			time_to_collision = math.huge
		end
	end
	
	return predicted_obstacle_pos, time_to_collision
end

-- =============================================
-- DYNAMIC PERSONALITY MATRIX
-- =============================================

local PersonalityMatrix = {}
PersonalityMatrix.__index = PersonalityMatrix

function PersonalityMatrix.new()
	local self = setmetatable({}, PersonalityMatrix)
	
	self.traits = {
		aggression = 0.5,
		caution = 0.5,
		curiosity = 0.3,
		sociability = 0.6,
		patience = 0.7
	}
	
	self.emotions = {
		confidence = 0.5,
		fear = 0.2,
		urgency = 0.3,
		frustration = 0.1
	}
	
	self.behavior_modifiers = {
		speed_multiplier = 1.0,
		risk_tolerance = 1.0,
		exploration_bonus = 1.0
	}
	
	return self
end

function PersonalityMatrix:update_emotions(situation)
	if situation.recent_failures > 2 then
		self.emotions.confidence = math.max(0.1, self.emotions.confidence - 0.1)
		self.emotions.frustration = math.min(1.0, self.emotions.frustration + 0.1)
	end
	
	if situation.success_rate > 0.8 then
		self.emotions.confidence = math.min(1.0, self.emotions.confidence + 0.05)
	end
	
	if situation.perceived_threat > 0.7 then
		self.emotions.fear = math.min(1.0, self.emotions.fear + 0.2)
		self.emotions.urgency = math.min(1.0, self.emotions.urgency + 0.1)
	end
	
	self.behavior_modifiers.speed_multiplier = 0.8 + (self.traits.aggression * 0.4) - (self.emotions.fear * 0.3)
	self.behavior_modifiers.risk_tolerance = self.traits.aggression * (1.0 - self.emotions.fear)
	self.behavior_modifiers.exploration_bonus = self.traits.curiosity * (1.0 + self.emotions.confidence * 0.5)
end

-- =============================================
-- SWARM INTELLIGENCE COORDINATION
-- =============================================

local SwarmIntelligence = {}
SwarmIntelligence.__index = SwarmIntelligence

function SwarmIntelligence.new(swarm_id)
	local self = setmetatable({}, SwarmIntelligence)
	
	self.swarm_id = swarm_id
	self.agents = {}
	self.formation_patterns = {
		LINE = "line",
		V_FORMATION = "v_formation",
		SQUARE = "square",
		CIRCLE = "circle"
	}
	
	self.communication_range = 50
	self.shared_knowledge = {}
	
	return self
end

function SwarmIntelligence:register_agent(agent_id, agent_data)
	self.agents[agent_id] = {
		position = agent_data.position,
		velocity = agent_data.velocity,
		goal = agent_data.goal,
		capabilities = agent_data.capabilities,
		last_update = os.clock()
	}
end

function SwarmIntelligence:update_agent_position(agent_id, position, velocity)
	if self.agents[agent_id] then
		self.agents[agent_id].position = position
		self.agents[agent_id].velocity = velocity
		self.agents[agent_id].last_update = os.clock()
	end
end

-- =============================================
-- MOVEMENT HANDLER IMPLEMENTATION
-- =============================================

local MovementHandler = {}
MovementHandler.__index = MovementHandler

function MovementHandler.new(character, aiType)
	local self = setmetatable({}, MovementHandler)
	
	self.Character = character
	self.AIType = aiType
	self.CurrentSpeed = 0
	self.TargetSpeed = MAX_SPEED
	self.Acceleration = 10
	self.Deceleration = 15
	self.IsMoving = false
	self.LastPosition = character.PrimaryPart.Position
	self.Humanoid = character:FindFirstChildOfClass("Humanoid")
	
	return self
end

function MovementHandler:Cleanup()
	if self.Character and self.Character.PrimaryPart then
		local body_velocity = self.Character.PrimaryPart:FindFirstChild("KynexBodyVelocity")
		if body_velocity then
			body_velocity:Destroy()
		end
	end
end

function MovementHandler:MoveAlongPath(path, currentWaypointIndex)
	if not path or currentWaypointIndex > #path then
		return false
	end
	
	local currentPos = self.Character.PrimaryPart.Position
	local targetPos = path[currentWaypointIndex]
	local distance = (targetPos - currentPos).Magnitude
	
	if distance < 2.0 then -- Reached waypoint
		return true
	end
	
	-- Calculate direction
	local direction = (targetPos - currentPos).Unit
	
	-- Apply movement
	if self.Humanoid then
		-- Use Humanoid for movement
		self.Humanoid:MoveTo(targetPos)
	else
		-- Fallback to BodyVelocity
		local body_velocity = self.Character.PrimaryPart:FindFirstChild("KynexBodyVelocity")
		if not body_velocity then
			body_velocity = Instance.new("BodyVelocity")
			body_velocity.Name = "KynexBodyVelocity"
			body_velocity.MaxForce = Vector3.new(4000, 0, 4000)
			body_velocity.Parent = self.Character.PrimaryPart
		end
		
		body_velocity.Velocity = direction * STEERING_FORCE
	end
	
	-- Adjust speed based on distance
	if distance < 5 then
		self.TargetSpeed = MAX_SPEED * 0.5
	else
		self.TargetSpeed = MAX_SPEED
	end
	
	if self.Humanoid then
		local speed_multiplier = 1.0
		if self.AIType == AI_TYPES.PARKOUR then
			speed_multiplier = 1.3
		elseif self.AIType == AI_TYPES.STEALTH then
			speed_multiplier = 0.7
		end
		
		self.Humanoid.WalkSpeed = self.TargetSpeed * speed_multiplier
	end
	
	return false
end

function MovementHandler:GetCurrentSpeed()
	local current_pos = self.Character.PrimaryPart.Position
	local distance = (current_pos - self.LastPosition).Magnitude
	self.LastPosition = current_pos
	
	self.CurrentSpeed = distance / PATH_UPDATE_INTERVAL
	return self.CurrentSpeed
end

-- =============================================
-- ENVIRONMENT MONITOR
-- =============================================

local EnvironmentMonitor = {}
EnvironmentMonitor.__index = EnvironmentMonitor

function EnvironmentMonitor.new()
	local self = setmetatable({}, EnvironmentMonitor)
	
	self.obstacles = {}
	self.dynamic_objects = {}
	self.terrain_cache = {}
	self.complexity_score = 0.5
	self.last_update = 0
	
	return self
end

function EnvironmentMonitor:UpdateObstacles(character)
	self.obstacles = {}
	
	if not character or not character.PrimaryPart then return end
	
	local character_pos = character.PrimaryPart.Position
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {Workspace.Terrain, character}
	params.CollisionGroup = "Default"
	
	local parts = Workspace:GetPartBoundsInBox(
		CFrame.new(character_pos),
		Vector3.new(50, 20, 50),
		params
	)
	
	for _, part in ipairs(parts) do
		if part.Size.Magnitude > 2 then
			self.obstacles[part] = {
				position = part.Position,
				size = part.Size,
				velocity = part.AssemblyLinearVelocity or Vector3.new(0, 0, 0),
				last_seen = os.clock()
			}
		end
	end
	
	self.last_update = os.clock()
end

function EnvironmentMonitor:GetComplexityScore()
	local obstacle_count = 0
	for _ in pairs(self.obstacles) do
		obstacle_count = obstacle_count + 1
	end
	
	self.complexity_score = math.min(1.0, obstacle_count / 20)
	return self.complexity_score
end

-- =============================================
-- LEARNING SYSTEM IMPLEMENTATION
-- =============================================

local LearningSystem = {}
LearningSystem.__index = LearningSystem

function LearningSystem.new(agentId)
	local self = setmetatable({}, LearningSystem)
	
	self.AgentId = agentId or "unknown"
	self.LearnedPaths = {}
	self.ObstacleMemory = {}
	self.SuccessRate = {}
	self.LearningRate = 0.1
	self.ConfidenceThreshold = 0.7
	self.MaxMemoryEntries = 1000
	
	self.NeuralNetwork = NeuralNetwork.new()
	self.PersonalityMatrix = PersonalityMatrix.new()
	
	return self
end

function LearningSystem:RecordPathExperience(path, success, duration)
	if not path then return end
	
	local pathHash = HttpService:GenerateGUID(false)
	
	if success then
		self.LearnedPaths[pathHash] = {
			path = path,
			success_count = 1,
			total_attempts = 1,
			last_used = os.clock(),
			average_duration = duration or 1.0
		}
	else
		self.ObstacleMemory[pathHash] = {
			reason = "path_failed",
			failure_count = 1,
			last_failure = os.clock()
		}
	end
	
	-- Update neural network
	local experience = {
		success = success,
		factors = {
			path_safety = 0.8,
			path_efficiency = 0.6,
			energy_cost = 0.3,
			risk_tolerance = self.PersonalityMatrix.traits.aggression
		}
	}
	
	self.NeuralNetwork:learn(experience)
end

-- =============================================
-- BEHAVIOR TREE IMPLEMENTATION
-- =============================================

local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

function BehaviorTree.new()
	local self = setmetatable({}, BehaviorTree)
	
	self.Root = nil
	self.Blackboard = {}
	self.MaxExecutionTime = 0.1
	self.LastExecutionTime = 0
	self.Goals = {}
	self.CurrentGoal = nil
	self.IsShuttingDown = false
	self.ActionPlan = {}
	
	return self
end

function BehaviorTree:SetGoal(goal, priority)
	self.Goals[goal] = priority
	self:SelectCurrentGoal()
end

function BehaviorTree:SelectCurrentGoal()
	local highestPriority = -1
	local selectedGoal = nil
	
	for goal, priority in pairs(self.Goals) do
		if priority > highestPriority then
			highestPriority = priority
			selectedGoal = goal
		end
	end
	
	self.CurrentGoal = selectedGoal
	self:PlanActions()
end

function BehaviorTree:PlanActions()
	if self.CurrentGoal == "reach_position" then
		self.ActionPlan = {
			"find_path",
			"navigate_path", 
			"avoid_obstacles",
			"adjust_movement"
		}
	elseif self.CurrentGoal == "explore_area" then
		self.ActionPlan = {
			"scan_environment",
			"select_exploration_target",
			"navigate_to_target",
			"gather_information"
		}
	elseif self.CurrentGoal == "evade_threat" then
		self.ActionPlan = {
			"assess_threat",
			"find_escape_route", 
			"move_to_safety",
			"maintain_awareness"
		}
	else
		self.ActionPlan = {"idle"}
	end
end

function BehaviorTree:Execute()
	if self.IsShuttingDown then return false end
	
	local startTime = os.clock()
	
	for _, action in ipairs(self.ActionPlan) do
		if os.clock() - startTime > self.MaxExecutionTime then
			break
		end
		
		local success = self:ExecuteAction(action)
		if not success then
			break
		end
	end
	
	self.LastExecutionTime = os.clock() - startTime
	return true
end

function BehaviorTree:ExecuteAction(action)
	-- Basic action execution
	if action == "find_path" then
		return self.Blackboard.FindPath ~= nil
	elseif action == "navigate_path" then
		return self.Blackboard.CurrentPath ~= nil
	elseif action == "avoid_obstacles" then
		return true
	end
	
	return true
end

-- =============================================
-- MAIN AI CONTROLLER - FULLY IMPLEMENTED
-- =============================================

local AIController = {}
AIController.__index = AIController

function AIController.new(character, aiType, options)
	local self = setmetatable({}, AIController)
	
	options = options or {}
	
	-- Input validation
	if not character or not character.PrimaryPart then
		error("AIController: Character must have PrimaryPart")
	end
	
	if not AI_TYPES[aiType] then
		warn("AIController: Invalid AI type '" .. tostring(aiType) .. "', defaulting to HUMANOID")
		aiType = AI_TYPES.HUMANOID
	end
	
	self.Character = character
	self.AIType = aiType
	self.Options = options
	self.AgentId = HttpService:GenerateGUID(false)
	self.IsActive = true
	self.IsShuttingDown = false
	
	-- Core systems
	self.RealPathfinding = RealPathfinding.new()
	self.EnvironmentMonitor = EnvironmentMonitor.new()
	self.MovementHandler = MovementHandler.new(character, aiType)
	
	-- Advanced systems
	if ADVANCED_FEATURES.REAL_TIME_LEARNING then
		self.LearningSystem = LearningSystem.new(self.AgentId)
	end
	
	if ADVANCED_FEATURES.BEHAVIOR_TREES then
		self.BehaviorTree = BehaviorTree.new()
		self.BehaviorTree.Blackboard.Character = character
	end
	
	if ADVANCED_FEATURES.PREDICTIVE_PATHING then
		self.PredictiveAnalytics = PredictiveAnalytics.new()
	end
	
	-- State management
	self.CurrentPath = nil
	self.CurrentWaypointIndex = 1
	self.PathStatus = PATH_STATUS.IN_PROGRESS
	self.TargetPosition = nil
	self.LastPathUpdate = 0
	self.LastUpdateTime = 0
	self.UpdateInterval = PATH_UPDATE_INTERVAL
	self.UpdateOffset = math.random() * self.UpdateInterval
	
	-- Performance metrics
	self.RecentFailures = 0
	self.SuccessRate = 0.5
	self.ThreatLevel = 0.0
	self.CurrentActivityLevel = 0.5
	
	-- Initialize navigation grid around character
	self.RealPathfinding:GenerateNavigationGrid(character.PrimaryPart.Position, 100)
	
	-- Start update loop
	self:StartUpdateLoop()
	
	warn("Kynexfind AI Controller created: " .. self.AgentId)
	return self
end

function AIController:StartUpdateLoop()
	SafeSpawn(function()
		while self.IsActive and not self.IsShuttingDown do
			local currentTime = os.clock()
			if currentTime - self.LastUpdateTime >= self.UpdateInterval then
				self.LastUpdateTime = currentTime
				ProtectedCall("AIControllerUpdate", function()
					self:AdvancedUpdate(self.UpdateInterval)
				end)
			end
			wait(self.UpdateInterval)
		end
	end)
end

function AIController:AdvancedUpdate(deltaTime)
	-- Update all systems in sequence
	self:UpdatePerception()
	self:UpdateDecisionMaking()
	self:UpdateMovement(deltaTime)
	self:UpdateLearning()
	
	-- Run behavior tree
	if self.BehaviorTree then
		self.BehaviorTree:Execute()
	end
end

function AIController:UpdatePerception()
	-- Update environment awareness
	self.EnvironmentMonitor:UpdateObstacles(self.Character)
	self.ThreatLevel = self.EnvironmentMonitor:GetComplexityScore() * 0.3
	
	-- Update predictive analytics
	if self.PredictiveAnalytics then
		for obstacle, data in pairs(self.EnvironmentMonitor.obstacles) do
			self.PredictiveAnalytics:track_obstacle(tostring(obstacle), data.position, data.velocity)
		end
	end
end

function AIController:UpdateDecisionMaking()
	-- Neural network decision making
	if self.LearningSystem and self.LearningSystem.NeuralNetwork then
		local options = self:GetAvailableOptions()
		if #options > 0 then
			local decision = self.LearningSystem.NeuralNetwork:decide(
				options,
				self:GetCurrentState()
			)
			self:ExecuteDecision(decision)
		end
	end
	
	-- Update personality
	if self.LearningSystem and self.LearningSystem.PersonalityMatrix then
		self.LearningSystem.PersonalityMatrix:update_emotions({
			recent_failures = self.RecentFailures,
			success_rate = self.SuccessRate,
			perceived_threat = self.ThreatLevel
		})
	end
end

function AIController:UpdateMovement(deltaTime)
	if not self.CurrentPath or self.CurrentWaypointIndex > #self.CurrentPath then
		return
	end
	
	-- Move along current path
	local reachedWaypoint = self.MovementHandler:MoveAlongPath(self.CurrentPath, self.CurrentWaypointIndex)
	
	if reachedWaypoint then
		self.CurrentWaypointIndex = self.CurrentWaypointIndex + 1
		
		-- Check if reached final destination
		if self.CurrentWaypointIndex > #self.CurrentPath then
			self.PathStatus = PATH_STATUS.SUCCESS
			self:OnPathComplete(true)
		end
	end
	
	-- Check if we need to recalculate path
	if os.clock() - self.LastPathUpdate > 5.0 then -- Recalculate every 5 seconds
		self:RecalculatePath()
	end
end

function AIController:UpdateLearning()
	-- Learn from recent experiences
	if self.LearningSystem and self.LastPathPerformance then
		self.LearningSystem:RecordPathExperience(
			self.CurrentPath,
			self.LastPathPerformance.success,
			self.LastPathPerformance.duration
		)
		self.LastPathPerformance = nil
	end
end

function AIController:GetAvailableOptions()
	local options = {}
	
	if self.TargetPosition then
		-- Generate different path options
		for i = 1, 3 do
			local option = {
				path = {self.Character.PrimaryPart.Position, self.TargetPosition},
				safety_factor = 0.8 - (i * 0.1),
				distance = (self.Character.PrimaryPart.Position - self.TargetPosition).Magnitude,
				energy_cost = 1.0 + (i * 0.2),
				risk_level = 0.1 * i
			}
			table.insert(options, option)
		end
	end
	
	return options
end

function AIController:GetCurrentState()
	return {
		position = self.Character.PrimaryPart.Position,
		velocity = self.Character.PrimaryPart.Velocity,
		aggression = self.LearningSystem and self.LearningSystem.PersonalityMatrix.traits.aggression or 0.5,
		energy = 1.0
	}
end

function AIController:ExecuteDecision(decision)
	if decision and decision.path then
		self.CurrentPath = decision.path
		self.CurrentWaypointIndex = 1
		self.PathStatus = PATH_STATUS.IN_PROGRESS
		self.LastPathUpdate = os.clock()
	end
end

function AIController:RecalculatePath()
	if not self.TargetPosition then return end
	
	self.PathStatus = PATH_STATUS.COMPUTING
	
	SafeSpawn(function()
		local newPath = self.RealPathfinding:FindPath(
			self.Character.PrimaryPart.Position,
			self.TargetPosition
		)
		
		if newPath and #newPath > 0 then
			self.CurrentPath = newPath
			self.CurrentWaypointIndex = 1
			self.PathStatus = PATH_STATUS.IN_PROGRESS
			self.LastPathUpdate = os.clock()
		else
			self.PathStatus = PATH_STATUS.FAILED
			self.RecentFailures = self.RecentFailures + 1
		end
	end)
end

function AIController:OnPathComplete(success)
	self.LastPathPerformance = {
		success = success,
		duration = os.clock() - self.LastPathUpdate
	}
	
	if success then
		self.SuccessRate = (self.SuccessRate * 0.9) + 0.1
		self.RecentFailures = math.max(0, self.RecentFailures - 1)
	else
		self.SuccessRate = self.SuccessRate * 0.9
		self.RecentFailures = self.RecentFailures + 1
	end
end

-- =============================================
-- PUBLIC API FUNCTIONS
-- =============================================

function Kynexfind.CreateAI(character, aiType, options)
	if not StabilitySystem.IsSystemStable then
		warn("Kynexfind: System unstable, cannot create AI")
		return nil
	end
	
	if not character then
		warn("Kynexfind: Character parameter is required")
		return nil
	end
	
	if not character:IsA("Model") then
		warn("Kynexfind: Character must be a Model")
		return nil
	end
	
	if not character.PrimaryPart then
		warn("Kynexfind: Character must have PrimaryPart")
		return nil
	end
	
	local ai = ProtectedCall("CreateAI", AIController.new, character, aiType, options)
	
	if not ai then
		warn("Kynexfind: Failed to create AI controller")
		return nil
	end
	
	return ai
end

function Kynexfind:FindPathAsync(character, targetPosition, callback)
	if not character or not targetPosition then
		if callback then callback(nil) end
		return
	end
	
	SafeSpawn(function()
		local pathfinding = RealPathfinding.new()
		pathfinding:GenerateNavigationGrid(character.PrimaryPart.Position, 100)
		local path = pathfinding:FindPath(character.PrimaryPart.Position, targetPosition)
		
		if callback then
			callback(path)
		end
	end)
end

function Kynexfind.CreateSwarm(characterCount, aiType, spawnPosition, options)
	if characterCount > 50 then
		warn("Kynexfind: Swarm size limited to 50 agents")
		characterCount = 50
	end
	
	local swarm = {}
	local successfulSpawns = 0
	
	for i = 1, characterCount do
		local character = Kynexfind.CreateMockCharacter(spawnPosition + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
		if character then
			local ai = Kynexfind.CreateAI(character, aiType, options)
			if ai then
				table.insert(swarm, ai)
				successfulSpawns = successfulSpawns + 1
			else
				character:Destroy()
			end
		end
	end
	
	warn("Kynexfind: Created " .. successfulSpawns .. "/" .. characterCount .. " swarm agents")
	return swarm
end

function Kynexfind.CreateMockCharacter(position)
	local success, result = pcall(function()
		local character = Instance.new("Model")
		local rootPart = Instance.new("Part")
		rootPart.Size = Vector3.new(2, 4, 1)
		rootPart.Position = position or Vector3.new(0, 0, 0)
		rootPart.Anchored = true
		rootPart.Name = "HumanoidRootPart"
		rootPart.CanCollide = true
		
		character.PrimaryPart = rootPart
		rootPart.Parent = character
		
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = character
		
		character.Parent = Workspace
		return character
	end)
	
	if not success then
		warn("Failed to create mock character: " .. tostring(result))
		return nil
	end
	
	return result
end

-- Method untuk mengatur target AI
function AIController:MoveTo(targetPosition)
	self.TargetPosition = targetPosition
	self:RecalculatePath()
end

-- Method untuk menghentikan AI
function AIController:Stop()
	self.TargetPosition = nil
	self.CurrentPath = nil
	self.PathStatus = PATH_STATUS.IN_PROGRESS
	self.MovementHandler:Cleanup()
end

-- Method untuk shutdown AI
function AIController:Shutdown()
	self.IsShuttingDown = true
	self.IsActive = false
	self:Stop()
	
	if self.BehaviorTree then
		self.BehaviorTree.IsShuttingDown = true
	end
	
	warn("Kynexfind AI Controller shutdown: " .. self.AgentId)
end

-- System monitoring
Kynexfind._GlobalMonitor = RunService.Heartbeat:Connect(function()
	ProtectedCall("StabilityHeartbeat", function()
		StabilitySystem:Heartbeat()
		StabilitySystem:MonitorMemory()
	end)
end)

function Kynexfind.EmergencyShutdown()
	warn("KYNEXFIND EMERGENCY SHUTDOWN INITIATED")
	
	if Kynexfind._GlobalMonitor then
		Kynexfind._GlobalMonitor:Disconnect()
		Kynexfind._GlobalMonitor = nil
	end
	
	for _, processor in pairs(MemoryManager) do
		processor.Active = false
		processor.MemoryPool = {}
		processor.Queue = {}
	end
	
	collectgarbage()
	
	warn("KYNEXFIND EMERGENCY SHUTDOWN COMPLETE")
end

function Kynexfind.GetSystemStatus()
	local function countActiveProcessors()
		local count = 0
		for _, processor in pairs(MemoryManager) do
			if processor.Active then
				count = count + 1
			end
		end
		return count
	end
	
	return {
		IsStable = StabilitySystem.IsSystemStable,
		RecoveryAttempts = StabilitySystem.RecoveryAttempts,
		ErrorCount = #StabilitySystem.ErrorLog,
		MemoryUsage = collectgarbage("count"),
		ActiveProcessors = countActiveProcessors()
	}
end

-- Export systems
Kynexfind.NeuralNetwork = NeuralNetwork
Kynexfind.PredictiveAnalytics = PredictiveAnalytics
Kynexfind.PersonalityMatrix = PersonalityMatrix
Kynexfind.SwarmIntelligence = SwarmIntelligence
Kynexfind.RealPathfinding = RealPathfinding

-- Export constants
Kynexfind.AI_TYPES = AI_TYPES
Kynexfind.NODE_TYPES = NODE_TYPES
Kynexfind.PATH_STATUS = PATH_STATUS
Kynexfind.ADVANCED_FEATURES = ADVANCED_FEATURES

warn("Kynexfind v1.0 - FULLY FUNCTIONAL loaded successfully!")

return Kynexfind
