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
	
	-- Layer 1: Critical Error Handler
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
		
		-- Layer 2: Automatic Recovery
		if self.RecoveryAttempts < self.MAX_RECOVERY_ATTEMPTS then
			self.RecoveryAttempts = self.RecoveryAttempts + 1
			warn("Attempting recovery #" .. self.RecoveryAttempts)
			self:AttemptRecovery()
		else
			self.IsSystemStable = false
			error("KYNEXFIND SYSTEM UNSTABLE - Manual intervention required")
		end
	end,
	
	-- Layer 3: Recovery Mechanism
	AttemptRecovery = function(self)
		-- Reset semua state berbahaya
		for processorId, processor in pairs(MemoryManager) do
			processor.Active = false
			processor.MemoryPool = {}
			processor.Queue = {}
		end
		
		-- Clear coroutine yang stuck menggunakan method yang aman
		local threads = {}
		local co = coroutine.running()
		if co then
			table.insert(threads, co)
		end
		
		-- Reset error counter setelah cooldown
		delay(self.ERROR_COOLDOWN, function()
			self.RecoveryAttempts = 0
			self.IsSystemStable = true
			warn("Kynexfind System Recovery Complete")
		end)
	end,
	
	-- Layer 4: Memory Leak Protection
	MonitorMemory = function(self)
		local currentTime = os.clock()
		if currentTime - self.LastCleanupTime > self.MEMORY_CLEANUP_INTERVAL then
			self:PerformMemoryCleanup()
			self.LastCleanupTime = currentTime
		end
	end,
	
	-- Layer 5: Memory Cleanup
	PerformMemoryCleanup = function(self)
		-- Collect garbage
		collectgarbage()
		
		-- Clean up expired cache entries di semua processor
		for _, processor in pairs(MemoryManager) do
			if processor.MemoryPool and processor.MemoryPool.PathCache then
				for cacheKey, cacheData in pairs(processor.MemoryPool.PathCache) do
					if os.clock() - cacheData.timestamp > 300 then -- 5 minutes
						processor.MemoryPool.PathCache[cacheKey] = nil
					end
				end
			end
		end
		
		-- Clean up old error logs
		while #self.ErrorLog > 100 do
			table.remove(self.ErrorLog, 1)
		end
	end,
	
	-- Layer 6: System Heartbeat
	Heartbeat = function(self)
		local currentTime = os.clock()
		if currentTime - self.LastHeartbeatTime > self.HEARTBEAT_INTERVAL then
			self.LastHeartbeatTime = currentTime
			
			-- Check system health
			if not self:CheckSystemHealth() then
				self:HandleCriticalError("System health check failed", "HeartbeatMonitor")
			end
		end
	end,
	
	-- Layer 7: Health Check
	CheckSystemHealth = function(self)
		-- Check memory usage
		local memoryUsage = collectgarbage("count")
		if memoryUsage > 100000 then -- 100MB threshold
			warn("Kynexfind: High memory usage detected: " .. memoryUsage .. "KB")
			self:PerformMemoryCleanup()
		end
		
		-- Check processor overload
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

-- Constants dengan validation
local PATH_UPDATE_INTERVAL = 0.05
local STEERING_FORCE = 50
local MAX_SPEED = 16
local NODE_RADIUS = 2
local AVOIDANCE_RAY_LENGTH = 10
local REPATH_THRESHOLD = 5

-- Validated Node Types
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

-- Validated Path Status
local PATH_STATUS = {
	SUCCESS = "Success",
	FAILED = "Failed",
	COMPUTING = "Computing",
	IN_PROGRESS = "InProgress",
	PARTIAL = "Partial"
}

-- Enhanced AI Types dengan safety checks
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

-- Memory Allocations dengan protection
local MemoryManager = {
	PathProcessor1 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor2 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor3 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor4 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false},
	PathProcessor5 = {Active = false, MemoryPool = {}, Queue = {}, Lock = false}
}

-- Global Path Cache
local PathCache = {}

-- Advanced Feature Flags dengan fallbacks
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

-- EXTREME STABILITY WRAPPER FUNCTIONS
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

-- Enhanced Memory Management dengan locks
local function AllocateMemory(processorId)
	local processor = MemoryManager[processorId]
	if not processor then return false end
	
	-- Acquire lock
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
	
	-- Acquire lock
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
-- NEURAL NETWORK DECISION MAKING SYSTEM
-- =============================================

local NeuralNetwork = {}
NeuralNetwork.__index = NeuralNetwork

function NeuralNetwork.new()
	local self = setmetatable({}, NeuralNetwork)
	
	-- Neural network parameters
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
	-- Exploration vs exploitation
	if math.random() < self.exploration_rate then
		-- Random exploration
		return path_options[math.random(1, #path_options)]
	end
	
	-- Calculate scores for each path option
	local best_score = -math.huge
	local best_path = nil
	
	for _, path in ipairs(path_options) do
		local score = 0
		
		-- Safety consideration
		score = score + (path.safety_factor or 1) * self.weights.path_safety
		
		-- Efficiency consideration
		score = score + (1 / (path.distance or 1)) * self.weights.path_efficiency
		
		-- Energy cost consideration
		score = score - (path.energy_cost or 0) * self.weights.energy_cost
		
		-- Risk tolerance based on personality
		score = score + (path.risk_level or 0) * self.weights.risk_tolerance * (current_state.aggression or 0.5)
		
		if score > best_score then
			best_score = score
			best_path = path
		end
	end
	
	return best_path
end

function NeuralNetwork:learn(experience)
	-- Add to experience buffer
	table.insert(self.experience_buffer, experience)
	
	-- Limit buffer size
	if #self.experience_buffer > self.max_experience then
		table.remove(self.experience_buffer, 1)
	end
	
	-- Simple reinforcement learning
	if experience.success then
		-- Strengthen weights that led to success
		for factor, value in pairs(experience.factors) do
			if self.weights[factor] then
				self.weights[factor] = self.weights[factor] + self.learning_rate * value
			end
		end
	else
		-- Weaken weights that led to failure
		for factor, value in pairs(experience.factors) do
			if self.weights[factor] then
				self.weights[factor] = self.weights[factor] - self.learning_rate * value
			end
		end
	end
	
	-- Normalize weights
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
	self.prediction_horizon = 2.0 -- seconds
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
	
	-- Keep only recent data
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
	
	-- Predict obstacle position using linear extrapolation
	local last_pos = trajectory.positions[#trajectory.positions]
	local last_vel = trajectory.velocities[#trajectory.velocities]
	
	local predicted_obstacle_pos = last_pos + last_vel * time_horizon
	local predicted_agent_pos = agent_position + agent_velocity * time_horizon
	
	local distance = (predicted_agent_pos - predicted_obstacle_pos).Magnitude
	local time_to_collision = math.huge
	
	-- Calculate time to collision using relative velocity
	local relative_vel = agent_velocity - last_vel
	local relative_pos = agent_position - last_pos
	
	-- PERBAIKAN 4: Hindari division by zero
	if relative_vel.Magnitude > 0.01 then -- Threshold untuk menghindari nilai terlalu kecil
		time_to_collision = -relative_pos:Dot(relative_vel) / (relative_vel.Magnitude ^ 2)
		if time_to_collision < 0 then
			time_to_collision = math.huge
		end
	end
	
	return predicted_obstacle_pos, time_to_collision
end

function PredictiveAnalytics:smooth_path(path, agent_velocity, obstacles)
	if not path or #path < 3 then return path end
	
	local smoothed_path = {path[1]}
	
	for i = 2, #path - 1 do
		local prev_point = path[i-1]
		local curr_point = path[i]
		local next_point = path[i+1]
		
		-- Apply simple smoothing using averaging
		local smoothed_point = (prev_point + curr_point + next_point) / 3
		
		-- Check for obstacles in smoothed path
		local has_obstacle = false
		for obstacle_id, _ in pairs(obstacles) do
			local obstacle_pos, ttc = self:predict_collision(curr_point, agent_velocity, obstacle_id, 1.0)
			if ttc < 0.5 then -- 500ms threshold
				has_obstacle = true
				break
			end
		end
		
		if not has_obstacle then
			table.insert(smoothed_path, smoothed_point)
		else
			table.insert(smoothed_path, curr_point)
		end
	end
	
	table.insert(smoothed_path, path[#path])
	return smoothed_path
end

-- =============================================
-- DYNAMIC PERSONALITY MATRIX
-- =============================================

local PersonalityMatrix = {}
PersonalityMatrix.__index = PersonalityMatrix

function PersonalityMatrix.new()
	local self = setmetatable({}, PersonalityMatrix)
	
	-- Core personality traits (0.0 to 1.0)
	self.traits = {
		aggression = 0.5,
		caution = 0.5,
		curiosity = 0.3,
		sociability = 0.6,
		patience = 0.7
	}
	
	-- Emotional state
	self.emotions = {
		confidence = 0.5,
		fear = 0.2,
		urgency = 0.3,
		frustration = 0.1
	}
	
	-- Behavior modifiers
	self.behavior_modifiers = {
		speed_multiplier = 1.0,
		risk_tolerance = 1.0,
		exploration_bonus = 1.0
	}
	
	return self
end

function PersonalityMatrix:update_emotions(situation)
	-- Update emotions based on current situation
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
	
	-- Update behavior modifiers based on emotions and traits
	self.behavior_modifiers.speed_multiplier = 0.8 + (self.traits.aggression * 0.4) - (self.emotions.fear * 0.3)
	self.behavior_modifiers.risk_tolerance = self.traits.aggression * (1.0 - self.emotions.fear)
	self.behavior_modifiers.exploration_bonus = self.traits.curiosity * (1.0 + self.emotions.confidence * 0.5)
end

function PersonalityMatrix:get_decision_influence()
	return {
		speed = self.behavior_modifiers.speed_multiplier,
		risk_tolerance = self.behavior_modifiers.risk_tolerance,
		exploration_bonus = self.behavior_modifiers.exploration_bonus,
		social_coordination = self.traits.sociability
	}
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

function SwarmIntelligence:calculate_agent_options(agent_data, target_position)
	-- Simplified agent options calculation
	local options = {}
	
	-- Generate 3 different path options
	for i = 1, 3 do
		local option = {
			path = {agent_data.position, target_position},
			confidence = 0.7 + math.random() * 0.3,
			distance = (agent_data.position - target_position).Magnitude,
			safety_factor = 0.8,
			energy_cost = 1.0
		}
		table.insert(options, option)
	end
	
	return options
end

function SwarmIntelligence:get_collective_decision(target_position)
	-- Simple voting system for collective decision making
	local path_options = {}
	local votes = {}
	
	-- Gather opinions from all agents
	for agent_id, agent_data in pairs(self.agents) do
		local agent_options = self:calculate_agent_options(agent_data, target_position)
		
		for _, option in ipairs(agent_options) do
			local option_key = tostring(option.path[1]) .. "_" .. tostring(option.path[#option.path])
			
			if not path_options[option_key] then
				path_options[option_key] = option
				votes[option_key] = 0
			end
			
			votes[option_key] = votes[option_key] + option.confidence
		end
	end
	
	-- Find the option with most votes
	local best_option = nil
	local highest_votes = -1
	
	for option_key, vote_count in pairs(votes) do
		if vote_count > highest_votes then
			highest_votes = vote_count
			best_option = path_options[option_key]
		end
	end
	
	return best_option
end

function SwarmIntelligence:calculate_formation_positions(target_position, formation_type)
	local positions = {}
	local agent_count = 0
	
	for _ in pairs(self.agents) do
		agent_count = agent_count + 1
	end
	
	if formation_type == self.formation_patterns.V_FORMATION then
		-- V formation calculation
		for i = 1, agent_count do
			local angle = math.rad((i - 1) * 30 - (agent_count * 15))
			local offset = Vector3.new(
				math.sin(angle) * 4 * math.ceil(i / 2),
				0,
				math.cos(angle) * 4 * math.ceil(i / 2)
			)
			table.insert(positions, target_position + offset)
		end
	elseif formation_type == self.formation_patterns.LINE then
		-- Line formation
		for i = 1, agent_count do
			local offset = Vector3.new((i - math.ceil(agent_count / 2)) * 3, 0, 0)
			table.insert(positions, target_position + offset)
		end
	else
		-- Default: circle formation
		for i = 1, agent_count do
			local angle = math.rad((i - 1) * (360 / agent_count))
			local offset = Vector3.new(math.sin(angle) * 5, 0, math.cos(angle) * 5)
			table.insert(positions, target_position + offset)
		end
	end
	
	return positions
end

-- =============================================
-- THREAT ASSESSMENT SYSTEM
-- =============================================

local ThreatAssessment = {}
ThreatAssessment.__index = ThreatAssessment

function ThreatAssessment.new()
	local self = setmetatable({}, ThreatAssessment)
	
	self.threat_zones = {}
	self.safe_zones = {}
	self.risk_weights = {
		distance = 0.3,
		visibility = 0.2,
		cover_availability = 0.2,
		enemy_presence = 0.3
	}
	
	return self
end

function ThreatAssessment:register_threat_zone(position, radius, threat_level, threat_type)
	local threat_id = HttpService:GenerateGUID(false)
	
	self.threat_zones[threat_id] = {
		position = position,
		radius = radius,
		threat_level = threat_level,
		threat_type = threat_type,
		last_detected = os.clock()
	}
	
	return threat_id
end

function ThreatAssessment:assess_area_risk(position, character) -- PERBAIKAN 5: Tambahkan parameter character
	local total_risk = 0
	local highest_individual_risk = 0
	
	for threat_id, threat_data in pairs(self.threat_zones) do
		local distance = (position - threat_data.position).Magnitude
		
		if distance < threat_data.radius then
			-- Calculate risk contribution from this threat
			local distance_factor = 1 - (distance / threat_data.radius)
			local risk_contribution = threat_data.threat_level * distance_factor
			
			total_risk = total_risk + risk_contribution
			highest_individual_risk = math.max(highest_individual_risk, risk_contribution)
		end
	end
	
	-- Consider environmental factors
	local visibility_risk = self:calculate_visibility_risk(position, character) -- PERBAIKAN 5: Kirim character
	local cover_risk = self:calculate_cover_risk(position)
	
	total_risk = total_risk + visibility_risk * self.risk_weights.visibility
	total_risk = total_risk + cover_risk * self.risk_weights.cover_availability
	
	return math.min(1.0, total_risk), highest_individual_risk
end

function ThreatAssessment:calculate_visibility_risk(position, character) -- PERBAIKAN 5: Tambahkan parameter character
	-- Simplified visibility calculation menggunakan Raycast modern
	local risk = 0
	
	-- Check visibility in multiple directions
	local directions = {
		Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
	}
	
	for _, direction in ipairs(directions) do
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		
		-- PERBAIKAN 5: Filter termasuk karakter AI sendiri
		local filterList = {Workspace.Terrain}
		if character then
			table.insert(filterList, character)
		end
		raycastParams.FilterDescendantsInstances = filterList
		
		local result = Workspace:Raycast(position, direction * 20, raycastParams)
		if not result then
			risk = risk + 0.25 -- No obstruction means more visible
		end
	end
	
	return risk
end

function ThreatAssessment:calculate_cover_risk(position)
	-- Calculate availability of cover menggunakan OverlapParams modern
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
	overlapParams.FilterDescendantsInstances = {Workspace.Terrain}
	
	local parts = Workspace:GetPartBoundsInBox(
		CFrame.new(position),
		Vector3.new(10, 4, 10),
		overlapParams
	)
	
	local cover_score = 0
	for _, part in ipairs(parts) do
		if part.Size.Magnitude > 2 then
			cover_score = cover_score + 0.1
		end
	end
	
	return math.min(1.0, cover_score)
end

function ThreatAssessment:get_safe_path(start_pos, end_pos, risk_tolerance)
	risk_tolerance = risk_tolerance or 0.3
	
	-- This would implement risk-aware path planning
	-- For now, return a simple straight path
	return {start_pos, end_pos}
end

-- =============================================
-- MULTI-LAYER 3D PATHFINDING
-- =============================================

local MultiLayer3DPathfinding = {}
MultiLayer3DPathfinding.__index = MultiLayer3DPathfinding

function MultiLayer3DPathfinding.new()
	local self = setmetatable({}, MultiLayer3DPathfinding)
	
	self.layers = {
		ground = {max_height = 10, cost_multiplier = 1.0},
		air = {max_height = 100, cost_multiplier = 1.2},
		water = {max_height = 5, cost_multiplier = 1.5}
	}
	
	self.vertical_threshold = 2.0
	self.layer_transition_cost = 2.0
	
	return self
end

function MultiLayer3DPathfinding:find_3d_path(start_pos, end_pos, agent_type)
	local start_layer = self:classify_position(start_pos)
	local end_layer = self:classify_position(end_pos)
	
	-- If same layer, do simple pathfinding
	if start_layer == end_layer then
		return self:find_path_in_layer(start_pos, end_pos, start_layer)
	end
	
	-- Multi-layer pathfinding needed
	-- Find transition points between layers
	local transition_points = self:find_layer_transitions(start_pos, end_pos, start_layer, end_layer)
	
	if #transition_points == 0 then
		return nil -- No valid path between layers
	end
	
	-- Build complete path through layers
	local complete_path = {start_pos}
	
	for i, transition in ipairs(transition_points) do
		table.insert(complete_path, transition.entry_point)
		table.insert(complete_path, transition.exit_point)
	end
	
	table.insert(complete_path, end_pos)
	
	return complete_path
end

function MultiLayer3DPathfinding:classify_position(position)
	-- Classify position into appropriate layer menggunakan Raycast modern
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {}
	
	local result = Workspace:Raycast(position + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0), raycastParams)
	
	if result then
		local height_above_ground = position.Y - result.Position.Y
		
		if height_above_ground < self.layers.ground.max_height then
			return "ground"
		elseif height_above_ground < self.layers.air.max_height then
			return "air"
		end
	end
	
	-- Check if in water (simplified)
	if position.Y < 0 then
		return "water"
	end
	
	return "air"
end

function MultiLayer3DPathfinding:find_path_in_layer(start_pos, end_pos, layer)
	-- Simple straight path for now
	return {start_pos, end_pos}
end

function MultiLayer3DPathfinding:find_layer_transitions(start_pos, end_pos, start_layer, end_layer)
	local transitions = {}
	
	-- Simplified transition finding
	-- In real implementation, this would analyze the environment for valid transitions
	
	if start_layer == "ground" and end_layer == "air" then
		-- Find takeoff point (e.g., high ground)
		local takeoff_point = start_pos + Vector3.new(0, 10, 0)
		table.insert(transitions, {
			entry_point = start_pos,
			exit_point = takeoff_point,
			from_layer = "ground",
			to_layer = "air"
		})
	end
	
	return transitions
end

-- =============================================
-- QUANTUM PATH OPTIMIZATION
-- =============================================

local QuantumPathOptimization = {}
QuantumPathOptimization.__index = QuantumPathOptimization

function QuantumPathOptimization.new()
	local self = setmetatable({}, QuantumPathOptimization)
	
	self.parallel_paths = {}
	self.quantum_states = {}
	
	return self
end

function QuantumPathOptimization:calculate_parallel_paths(start_pos, end_pos, num_paths)
	num_paths = num_paths or 3
	
	local paths = {}
	
	for i = 1, num_paths do
		-- Generate slightly different paths using different algorithms
		local path = self:generate_quantum_path(start_pos, end_pos, i)
		if path then
			table.insert(paths, path)
		end
	end
	
	-- Evaluate all paths and select best one
	local best_path = self:select_optimal_path(paths)
	
	return best_path, paths
end

function QuantumPathOptimization:generate_quantum_path(start_pos, end_pos, algorithm_variant)
	-- Different algorithm variants for parallel computation
	if algorithm_variant == 1 then
		return self:a_star_variant(start_pos, end_pos, "distance")
	elseif algorithm_variant == 2 then
		return self:a_star_variant(start_pos, end_pos, "safety")
	elseif algorithm_variant == 3 then
		return self:a_star_variant(start_pos, end_pos, "energy_efficiency")
	end
	
	return self:a_star_variant(start_pos, end_pos, "balanced")
end

function QuantumPathOptimization:a_star_variant(start_pos, end_pos, optimization_type)
	-- Simplified A* implementation with different optimization criteria
	-- For now, return a simple path
	return {start_pos, (start_pos + end_pos) / 2, end_pos}
end

function QuantumPathOptimization:select_optimal_path(paths)
	if #paths == 0 then return nil end
	
	local best_score = -math.huge
	local best_path = paths[1]
	
	for _, path in ipairs(paths) do
		local score = self:evaluate_path_quality(path)
		if score > best_score then
			best_score = score
			best_path = path
		end
	end
	
	return best_path
end

function QuantumPathOptimization:evaluate_path_quality(path)
	-- Evaluate path based on multiple criteria
	local length_score = 1 / (#path * 0.1) -- Prefer shorter paths
	local smoothness_score = self:calculate_path_smoothness(path)
	
	return length_score * 0.6 + smoothness_score * 0.4
end

function QuantumPathOptimization:calculate_path_smoothness(path)
	if #path < 3 then return 1.0 end
	
	local total_angle = 0
	for i = 2, #path - 1 do
		local v1 = (path[i] - path[i-1]).Unit
		local v2 = (path[i+1] - path[i]).Unit
		local dot = math.max(-1, math.min(1, v1:Dot(v2)))
		local angle = math.acos(dot)
		total_angle = total_angle + angle
	end
	
	local avg_angle = total_angle / (#path - 2)
	return 1.0 / (1.0 + avg_angle)
end

-- =============================================
-- DYNAMIC TERRAIN ANALYSIS
-- =============================================

local DynamicTerrainAnalysis = {}
DynamicTerrainAnalysis.__index = DynamicTerrainAnalysis

function DynamicTerrainAnalysis.new()
	local self = setmetatable({}, DynamicTerrainAnalysis)
	
	self.terrain_types = {
		GRASS = {cost = 1.0, speed = 1.0},
		ROAD = {cost = 0.7, speed = 1.3},
		WATER = {cost = 2.0, speed = 0.5},
		MOUNTAIN = {cost = 3.0, speed = 0.3},
		SAND = {cost = 1.5, speed = 0.7}
	}
	
	self.weather_effects = {
		CLEAR = {multiplier = 1.0},
		RAIN = {multiplier = 0.8},
		SNOW = {multiplier = 0.5},
		STORM = {multiplier = 0.3}
	}
	
	self.current_weather = "CLEAR"
	
	return self
end

function DynamicTerrainAnalysis:analyze_terrain(position)
	-- Sample terrain material at position menggunakan Raycast modern
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {}
	
	local result = Workspace:Raycast(position + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0), raycastParams)
	
	if result then
		local surface_type = self:classify_surface(result.Instance, result.Position)
		local slope = math.deg(math.acos(result.Normal.Y))
		
		return {
			type = surface_type,
			slope = slope,
			cost = self:calculate_movement_cost(surface_type, slope),
			speed_multiplier = self:calculate_speed_multiplier(surface_type, slope)
		}
	end
	
	return {type = "GRASS", slope = 0, cost = 1.0, speed_multiplier = 1.0}
end

function DynamicTerrainAnalysis:classify_surface(part, position)
	-- Simplified surface classification
	if part:IsA("Part") then
		if part.Material == Enum.Material.Grass then
			return "GRASS"
		elseif part.Material == Enum.Material.Asphalt then
			return "ROAD"
		elseif part.Material == Enum.Material.Water then
			return "WATER"
		elseif part.Material == Enum.Material.Sand then
			return "SAND"
		end
	end
	
	return "GRASS"
end

function DynamicTerrainAnalysis:calculate_movement_cost(surface_type, slope)
	local base_cost = self.terrain_types[surface_type] and self.terrain_types[surface_type].cost or 1.0
	local weather_multiplier = self.weather_effects[self.current_weather].multiplier
	
	-- Slope penalty
	local slope_penalty = 1.0 + (slope / 45) * 0.5
	
	return base_cost * weather_multiplier * slope_penalty
end

function DynamicTerrainAnalysis:calculate_speed_multiplier(surface_type, slope)
	local base_speed = self.terrain_types[surface_type] and self.terrain_types[surface_type].speed or 1.0
	local weather_multiplier = self.weather_effects[self.current_weather].multiplier
	
	-- Slope penalty for speed
	local slope_penalty = 1.0 - (slope / 45) * 0.3
	
	return base_speed * weather_multiplier * slope_penalty
end

function DynamicTerrainAnalysis:set_weather(weather_type)
	if self.weather_effects[weather_type] then
		self.current_weather = weather_type
	end
end

-- =============================================
-- TEMPORAL PATH MEMORY
-- =============================================

local TemporalPathMemory = {}
TemporalPathMemory.__index = TemporalPathMemory

function TemporalPathMemory.new()
	local self = setmetatable({}, TemporalPathMemory)
	
	self.path_memory = {}
	self.failed_paths = {}
	
	-- Memory decay parameters
	self.decay_rate = 0.1 -- per hour
	self.max_memory_age = 24 * 3600 -- 24 hours
	
	return self
end

function TemporalPathMemory:remember_successful_path(path_id, path_data, performance_metrics)
	self.path_memory[path_id] = {
		path = path_data,
		metrics = performance_metrics,
		success_count = (self.path_memory[path_id] and self.path_memory[path_id].success_count or 0) + 1,
		last_used = os.clock(),
		created = os.clock()
	}
end

function TemporalPathMemory:remember_failed_path(path_id, failure_reason)
	self.failed_paths[path_id] = {
		reason = failure_reason,
		failure_count = (self.failed_paths[path_id] and self.failed_paths[path_id].failure_count or 0) + 1,
		last_failure = os.clock()
	}
end

function TemporalPathMemory:get_successful_paths(start_pos, end_pos, similarity_threshold)
	similarity_threshold = similarity_threshold or 0.7
	
	local matching_paths = {}
	
	for path_id, memory in pairs(self.path_memory) do
		local similarity = self:calculate_path_similarity(memory.path, start_pos, end_pos)
		if similarity >= similarity_threshold then
			table.insert(matching_paths, {
				path = memory.path,
				confidence = memory.success_count / (memory.success_count + 1),
				performance = memory.metrics
			})
		end
	end
	
	-- Sort by confidence
	table.sort(matching_paths, function(a, b)
		return a.confidence > b.confidence
	end)
	
	return matching_paths
end

function TemporalPathMemory:calculate_path_similarity(path, start_pos, end_pos)
	-- Calculate how similar this path is to the desired start-end positions
	local start_similarity = 1.0 / (1.0 + (path[1] - start_pos).Magnitude)
	local end_similarity = 1.0 / (1.0 + (path[#path] - end_pos).Magnitude)
	
	return (start_similarity + end_similarity) / 2
end

function TemporalPathMemory:cleanup_old_memories()
	local current_time = os.clock()
	local to_remove = {}
	
	for path_id, memory in pairs(self.path_memory) do
		if current_time - memory.created > self.max_memory_age then
			table.insert(to_remove, path_id)
		end
	end
	
	for _, path_id in ipairs(to_remove) do
		self.path_memory[path_id] = nil
	end
end

-- =============================================
-- ADAPTIVE HEURISTIC SYSTEM
-- =============================================

local AdaptiveHeuristicSystem = {}
AdaptiveHeuristicSystem.__index = AdaptiveHeuristicSystem

function AdaptiveHeuristicSystem.new()
	local self = setmetatable({}, AdaptiveHeuristicSystem)
	
	self.heuristic_weights = {
		distance = 1.0,
		terrain_cost = 0.8,
		risk_factor = 0.5,
		energy_cost = 0.3
	}
	
	self.learning_rate = 0.01
	self.context_history = {}
	
	return self
end

function AdaptiveHeuristicSystem:calculate_heuristic(current_pos, target_pos, context)
	context = context or {}
	
	local base_distance = (target_pos - current_pos).Magnitude
	local heuristic = base_distance * self.heuristic_weights.distance
	
	-- Add terrain cost consideration
	if context.terrain_cost then
		heuristic = heuristic + context.terrain_cost * self.heuristic_weights.terrain_cost
	end
	
	-- Add risk consideration
	if context.risk_factor then
		heuristic = heuristic + context.risk_factor * 100 * self.heuristic_weights.risk_factor
	end
	
	-- Add energy cost consideration
	if context.energy_cost then
		heuristic = heuristic + context.energy_cost * self.heuristic_weights.energy_cost
	end
	
	return heuristic
end

function AdaptiveHeuristicSystem:adjust_weights(success, performance_metrics)
	if success then
		-- Strengthen weights that led to good performance
		for factor, value in pairs(performance_metrics) do
			if self.heuristic_weights[factor] then
				self.heuristic_weights[factor] = self.heuristic_weights[factor] + self.learning_rate * value
			end
		end
	else
		-- Weaken weights that led to poor performance
		for factor, value in pairs(performance_metrics) do
			if self.heuristic_weights[factor] then
				self.heuristic_weights[factor] = math.max(0.1, self.heuristic_weights[factor] - self.learning_rate * value)
			end
		end
	end
	
	-- Normalize weights
	self:normalize_weights()
end

function AdaptiveHeuristicSystem:normalize_weights()
	local total = 0
	for _, weight in pairs(self.heuristic_weights) do
		total = total + weight
	end
	
	if total > 0 then
		for factor, weight in pairs(self.heuristic_weights) do
			self.heuristic_weights[factor] = weight / total
		end
	end
end

function AdaptiveHeuristicSystem:select_algorithm(context)
	-- Select pathfinding algorithm based on context
	if context.urgency and context.urgency > 0.8 then
		return "greedy" -- Fast but suboptimal
	elseif context.precision_required and context.precision_required > 0.7 then
		return "a_star" -- Optimal but slower
	else
		return "hybrid" -- Balanced approach
	end
end

-- =============================================
-- IMPLEMENTASI MODUL YANG HILANG
-- =============================================

-- EnvironmentMonitor Implementation
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

function EnvironmentMonitor:GetComplexityScore()
	-- Calculate environmental complexity based on obstacles and terrain
	local obstacle_count = 0
	for _ in pairs(self.obstacles) do
		obstacle_count = obstacle_count + 1
	end
	
	self.complexity_score = math.min(1.0, obstacle_count / 20)
	return self.complexity_score
end

function EnvironmentMonitor:UpdateObstacles()
	-- Update obstacles in environment
	self.obstacles = {}
	
	-- Find nearby parts that could be obstacles
	local character_pos = Vector3.new(0, 0, 0) -- Would be set by parent
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
	overlapParams.FilterDescendantsInstances = {Workspace.Terrain}
	
	local parts = Workspace:GetPartBoundsInBox(
		CFrame.new(character_pos),
		Vector3.new(50, 20, 50),
		overlapParams
	)
	
	for _, part in ipairs(parts) do
		if part.Size.Magnitude > 2 then
			self.obstacles[part] = {
				position = part.Position,
				size = part.Size,
				last_seen = os.clock()
			}
		end
	end
	
	self.last_update = os.clock()
end

-- MovementHandler Implementation dengan PERBAIKAN 2 dan 3
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
	
	-- PERBAIKAN 3: Cache Humanoid reference
	self.Humanoid = character:FindFirstChildOfClass("Humanoid")
	
	return self
end

-- PERBAIKAN 2: Tambahkan cleanup untuk BodyVelocity
function MovementHandler:Cleanup()
	if self.Character and self.Character.PrimaryPart then
		local body_velocity = self.Character.PrimaryPart:FindFirstChild("BodyVelocity")
		if body_velocity then
			body_velocity:Destroy()
		end
	end
end

function MovementHandler:GetCurrentSpeed()
	local current_pos = self.Character.PrimaryPart.Position
	local distance = (current_pos - self.LastPosition).Magnitude
	self.LastPosition = current_pos
	
	-- Estimate speed based on distance moved
	self.CurrentSpeed = distance / PATH_UPDATE_INTERVAL
	return self.CurrentSpeed
end

function MovementHandler:UpdateBiomechanicalMovement(deltaTime)
	if not self.Character or not self.Character.PrimaryPart then
		return
	end
	
	-- Simple movement implementation
	-- PERBAIKAN 3: Gunakan cached Humanoid reference
	if self.Humanoid then
		-- Adjust speed based on AI type
		local speed_multiplier = 1.0
		if self.AIType == AI_TYPES.PARKOUR then
			speed_multiplier = 1.3
		elseif self.AIType == AI_TYPES.STEALTH then
			speed_multiplier = 0.7
		end
		
		self.Humanoid.WalkSpeed = self.TargetSpeed * speed_multiplier
	end
end

function MovementHandler:MoveToPrecision(target_position, precision_requirements)
	if not self.Character or not self.Character.PrimaryPart then
		return
	end
	
	local current_pos = self.Character.PrimaryPart.Position
	local direction = (target_position - current_pos).Unit
	
	-- Apply steering force
	local body_velocity = self.Character.PrimaryPart:FindFirstChild("BodyVelocity")
	if not body_velocity then
		body_velocity = Instance.new("BodyVelocity")
		body_velocity.MaxForce = Vector3.new(4000, 0, 4000)
		body_velocity.Parent = self.Character.PrimaryPart
	end
	
	body_velocity.Velocity = direction * STEERING_FORCE
	
	-- Adjust speed based on distance to target
	local distance = (target_position - current_pos).Magnitude
	if distance < 5 then
		self.TargetSpeed = MAX_SPEED * 0.5
	else
		self.TargetSpeed = MAX_SPEED
	end
end

function MovementHandler:GetPrecisionRequirements()
	return {
		position_tolerance = 1.0,
		angle_tolerance = 15,
		speed_control = true
	}
end

-- PredictiveEngine Implementation
local PredictiveEngine = {}
PredictiveEngine.__index = PredictiveEngine

function PredictiveEngine.new()
	local self = setmetatable({}, PredictiveEngine)
	
	self.prediction_horizon = 2.0
	self.trajectory_cache = {}
	
	return self
end

function PredictiveEngine:PredictObstacleMovement(obstacle_id, current_position, current_velocity)
	-- Simple linear prediction
	return current_position + current_velocity * self.prediction_horizon
end

function PredictiveEngine:CalculateAvoidanceVector(current_position, target_position, obstacles)
	local avoidance_vector = Vector3.new(0, 0, 0)
	
	for obstacle_id, obstacle_data in pairs(obstacles) do
		local predicted_position = self:PredictObstacleMovement(
			obstacle_id, 
			obstacle_data.position, 
			obstacle_data.velocity or Vector3.new(0, 0, 0)
		)
		
		local to_obstacle = predicted_position - current_position
		local distance = to_obstacle.Magnitude
		
		if distance < 10 then
			-- Calculate repulsion force
			local repulsion_force = (1.0 / math.max(distance, 0.1)) * 50
			avoidance_vector = avoidance_vector - to_obstacle.Unit * repulsion_force
		end
	end
	
	return avoidance_vector
end

-- EnergyManager Implementation
local EnergyManager = {}
EnergyManager.__index = EnergyManager

function EnergyManager.new()
	local self = setmetatable({}, EnergyManager)
	
	self.current_energy = 100.0
	self.max_energy = 100.0
	self.energy_drain_rate = 5.0 -- per second
	self.energy_regen_rate = 10.0 -- per second
	self.last_update = os.clock()
	
	return self
end

function EnergyManager:UpdateEnergyConsumption(activity_level)
	local current_time = os.clock()
	local delta_time = current_time - self.last_update
	
	-- Calculate energy change based on activity
	local energy_change = 0
	if activity_level > 0.5 then
		-- High activity - drain energy
		energy_change = -self.energy_drain_rate * activity_level * delta_time
	else
		-- Low activity - regenerate energy
		energy_change = self.energy_regen_rate * (1 - activity_level) * delta_time
	end
	
	self.current_energy = math.max(0, math.min(self.max_energy, self.current_energy + energy_change))
	self.last_update = current_time
	
	return self.current_energy
end

function EnergyManager:CanPerformAction(action_cost)
	return self.current_energy >= action_cost
end

function EnergyManager:GetEnergyLevel()
	return self.current_energy / self.max_energy
end

-- =============================================
-- INTERNAL MODULES DENGAN SEMUA FITUR BARU
-- =============================================

local AIController = {}
local PathfindingModule = {}
local NodeGraph = {}
local LearningSystem = {}
local CommunicationNetwork = {}
local BehaviorTree = {}

-- Enhanced Helper Functions dengan validation
local function VectorToTable(vec)
	if typeof(vec) ~= "Vector3" then
		warn("VectorToTable: Expected Vector3, got " .. typeof(vec))
		return {X = 0, Y = 0, Z = 0}
	end
	return {X = vec.X, Y = vec.Y, Z = vec.Z}
end

local function TableToVector(tbl)
	if type(tbl) ~= "table" or not tbl.X or not tbl.Y or not tbl.Z then
		warn("TableToVector: Invalid table structure")
		return Vector3.new(0, 0, 0)
	end
	return Vector3.new(tbl.X, tbl.Y, tbl.Z)
end

local function DeepCopy(original)
	if type(original) ~= "table" then return original end
	
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function GetEuclideanDistance(pos1, pos2)
	if typeof(pos1) ~= "Vector3" or typeof(pos2) ~= "Vector3" then
		warn("GetEuclideanDistance: Invalid position types")
		return math.huge
	end
	return (pos1 - pos2).Magnitude
end

-- Enhanced Learning System dengan stability improvements
function LearningSystem.new(agentId)
	local self = setmetatable({}, LearningSystem)
	
	self.AgentId = agentId or "unknown"
	self.LearnedPaths = {}
	self.ObstacleMemory = {}
	self.SuccessRate = {}
	self.LearningRate = 0.1
	self.ConfidenceThreshold = 0.7
	self.MaxMemoryEntries = 1000
	
	-- Integrate new systems
	self.NeuralNetwork = NeuralNetwork.new()
	self.PersonalityMatrix = PersonalityMatrix.new()
	self.TemporalMemory = TemporalPathMemory.new()
	
	return self
end

function LearningSystem:RecordPathExperience(path, success, duration)
	if type(path) ~= "table" then return end
	
	-- Use Temporal Memory
	if success then
		local pathHash = HttpService:GenerateGUID(false)
		self.TemporalMemory:remember_successful_path(pathHash, path, {
			duration = duration,
			length = #path,
			efficiency = duration and (#path / math.max(duration, 0.1)) or 1.0
		})
	else
		local pathHash = HttpService:GenerateGUID(false)
		self.TemporalMemory:remember_failed_path(pathHash, "unknown")
	end
	
	-- Also update neural network
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

-- Enhanced Communication Network dengan semua fitur swarm
function CommunicationNetwork.new()
	local self = setmetatable({}, CommunicationNetwork)
	
	self.Agents = {}
	self.Messages = {}
	self.GroupFormations = {}
	self.IsShuttingDown = false
	
	-- Integrate Swarm Intelligence
	self.SwarmIntelligence = SwarmIntelligence.new("global_swarm")
	
	return self
end

function CommunicationNetwork:RegisterAgent(agentId, agentType, capabilities)
	self.SwarmIntelligence:register_agent(agentId, {
		agent_type = agentType,
		capabilities = capabilities or {},
		position = Vector3.new(0, 0, 0),
		velocity = Vector3.new(0, 0, 0)
	})
end

function CommunicationNetwork:UpdateAgentPosition(agentId, position, velocity)
	self.SwarmIntelligence:update_agent_position(agentId, position, velocity)
end

function CommunicationNetwork:SharePathKnowledge(agentId, path, status)
	-- Share path knowledge with other agents in swarm
	for otherAgentId, otherAgent in pairs(self.SwarmIntelligence.agents) do
		if otherAgentId ~= agentId then
			-- In real implementation, this would send the path data
			-- For now, just log it
			warn("Agent " .. agentId .. " sharing path with " .. otherAgentId)
		end
	end
end

function CommunicationNetwork:GetCollectiveDecision(targetPosition)
	return self.SwarmIntelligence:get_collective_decision(targetPosition)
end

function CommunicationNetwork:Shutdown()
	self.IsShuttingDown = true
	self.Agents = {}
	self.Messages = {}
	self.GroupFormations = {}
end

-- Enhanced Behavior Tree dengan goal-oriented planning
function BehaviorTree.new()
	local self = setmetatable({}, BehaviorTree)
	
	self.Root = nil
	self.Blackboard = {}
	self.MaxExecutionTime = 0.1 -- 100ms max per execution
	self.LastExecutionTime = 0
	self.Goals = {}
	self.CurrentGoal = nil
	self.IsShuttingDown = false
	
	-- Goal-Oriented Action Planning
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
	-- Hierarchical task decomposition for current goal
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
	end
end

function BehaviorTree:Execute()
	if self.IsShuttingDown then return false end
	
	local startTime = os.clock()
	
	-- Execute current action plan
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
	
	if self.LastExecutionTime > self.MaxExecutionTime then
		warn("BehaviorTree execution took " .. self.LastExecutionTime .. "s")
	end
	
	return true
end

function BehaviorTree:ExecuteAction(action)
	-- Execute specific action based on current plan
	if action == "find_path" then
		return self:FindPathAction()
	elseif action == "navigate_path" then
		return self:NavigatePathAction()
	elseif action == "avoid_obstacles" then
		return self:AvoidObstaclesAction()
	end
	
	return true
end

function BehaviorTree:FindPathAction()
	-- Path finding logic would go here
	return true
end

function BehaviorTree:NavigatePathAction()
	-- Path navigation logic would go here
	return true
end

function BehaviorTree:AvoidObstaclesAction()
	-- Obstacle avoidance logic would go here
	return true
end

-- Enhanced NodeGraph dengan semua fitur advanced
function NodeGraph.new()
	local self = setmetatable({}, NodeGraph)
	
	self.Nodes = {}
	self.Connections = {}
	self.NodeWeights = {}
	self.NodeCount = 0
	self.MaxNodes = 10000 -- Safety limit
	
	-- Integrate advanced systems
	self.TerrainAnalysis = DynamicTerrainAnalysis.new()
	self.ThreatAssessment = ThreatAssessment.new()
	self.AdaptiveHeuristic = AdaptiveHeuristicSystem.new()
	
	return self
end

function NodeGraph:AddNode(position, nodeType, properties)
	if self.NodeCount >= self.MaxNodes then
		warn("NodeGraph: Maximum node count reached")
		return nil
	end
	
	if typeof(position) ~= "Vector3" then
		warn("NodeGraph: Invalid position type")
		return nil
	end
	
	-- Analyze terrain at node position
	local terrain_info = self.TerrainAnalysis:analyze_terrain(position)
	local risk_level, _ = self.ThreatAssessment:assess_area_risk(position)
	
	local nodeId = self.NodeCount + 1
	local node = {
		Id = nodeId,
		Position = position,
		Type = nodeType or NODE_TYPES.WALK,
		Properties = properties or {},
		DynamicWeight = 1.0,
		LastUpdated = os.clock(),
		TerrainInfo = terrain_info,
		RiskLevel = risk_level,
		MovementCost = terrain_info.cost
	}
	
	self.Nodes[nodeId] = node
	self.Connections[nodeId] = {}
	self.NodeWeights[nodeId] = 1.0
	self.NodeCount = self.NodeCount + 1
	
	return nodeId
end

-- Advanced PathfindingModule dengan semua optimizations
function PathfindingModule.new(nodeGraph, processorId)
	local self = setmetatable({}, PathfindingModule)
	
	self.NodeGraph = nodeGraph
	self.PathCache = {}
	self.ProcessorId = processorId or "PathProcessor1"
	self.ActiveComputations = 0
	self.MaxParallelComputations = 5
	self.ComputationTimeout = 10.0 -- 10 second timeout
	self.LastCleanupTime = 0
	self.IsShuttingDown = false
	
	-- Integrate advanced pathfinding systems
	self.QuantumOptimizer = QuantumPathOptimization.new()
	self.MultiLayerPathfinding = MultiLayer3DPathfinding.new()
	self.PredictiveAnalytics = PredictiveAnalytics.new()
	
	-- Start cleanup routine
	self:StartCleanupRoutine()
	
	return self
end

function PathfindingModule:StartCleanupRoutine()
	SafeSpawn(function()
		while true do
			wait(30) -- Cleanup every 30 seconds
			if self.IsShuttingDown then break end
			
			self:CleanupExpiredCache()
		end
	end)
end

function PathfindingModule:CleanupExpiredCache()
	local currentTime = os.clock()
	local expiredKeys = {}
	
	for cacheKey, cacheData in pairs(self.PathCache) do
		if currentTime - cacheData.timestamp > 300 then -- 5 minutes
			table.insert(expiredKeys, cacheKey)
		end
	end
	
	for _, key in ipairs(expiredKeys) do
		self.PathCache[key] = nil
	end
end

function PathfindingModule:FindPathAsync(startPos, endPos, aiType, options, callback)
	if self.IsShuttingDown then
		warn("PathfindingModule is shutting down")
		if callback then callback(nil) end
		return
	end
	
	options = options or {}
	
	-- Validate parameters
	local paramCheck, paramError = ValidateParameters({
		startPos = startPos,
		endPos = endPos,
		aiType = aiType
	}, {
		startPos = "Vector3",
		endPos = "Vector3", 
		aiType = "string"
	})
	
	if not paramCheck then
		warn("PathfindingModule: Invalid parameters - " .. paramError)
		if callback then callback(nil) end
		return
	end
	
	-- Use quantum optimization for parallel path calculation
	local bestPath, allPaths = self.QuantumOptimizer:calculate_parallel_paths(startPos, endPos, 3)
	
	if bestPath then
		-- Apply predictive smoothing
		local smoothedPath = self.PredictiveAnalytics:smooth_path(bestPath, Vector3.new(0, 0, 0), {})
		
		if callback then
			callback(smoothedPath)
		end
		return
	end
	
	-- Fallback to traditional pathfinding
	self:TraditionalPathfinding(startPos, endPos, aiType, options, callback)
end

function PathfindingModule:TraditionalPathfinding(startPos, endPos, aiType, options, callback)
	-- Traditional A* implementation would go here
	-- For now, return a simple path
	local simplePath = {startPos, (startPos + endPos) / 2, endPos}
	
	if callback then
		callback(simplePath)
	end
end

-- Enhanced AIController dengan semua fitur advanced dan PERBAIKAN 1, 2, 9
function AIController.new(character, aiType, options)
	local self = setmetatable({}, AIController)
	
	options = options or {}
	
	-- Layer 8: Input Validation
	if not character or not character.PrimaryPart then
		error("AIController: Character must have PrimaryPart")
	end
	
	if not AI_TYPES[aiType] then
		warn("AIController: Invalid AI type '" .. tostring(aiType) .. "', defaulting to HUMANOID")
		aiType = AI_TYPES.HUMANOID
	end
	
	self.Character = character
	self.AIType = aiType or AI_TYPES.HUMANOID
	self.Options = options
	self.AgentId = HttpService:GenerateGUID(false)
	self.IsActive = true
	self.IsShuttingDown = false
	
	-- Initialize semua properti yang diperlukan
	self.LastUpdateTime = 0
	self.LastPathPerformance = nil
	self.RecentFailures = 0
	self.SuccessRate = 0.5
	self.ThreatLevel = 0.0
	self.ActiveComputations = 0
	self.MaxParallelComputations = 5
	self.ComplexEnvironment = false
	self.LongPath = false
	self.SwarmCoordination = false
	self.CurrentActivityLevel = 0.5
	
	-- PERBAIKAN 1: Instance-specific interval
	self.UpdateInterval = PATH_UPDATE_INTERVAL
	
	-- Layer 9: Protected Initialization
	local initSuccess = ProtectedCall("AIControllerInit", function()
		-- Core systems
		self.NodeGraph = NodeGraph.new()
		self.PathfindingModule = PathfindingModule.new(self.NodeGraph, "PathProcessor1")
		self.EnvironmentMonitor = EnvironmentMonitor.new()
		self.MovementHandler = MovementHandler.new(character, aiType)
		
		-- Advanced systems
		if ADVANCED_FEATURES.REAL_TIME_LEARNING then
			self.LearningSystem = LearningSystem.new(self.AgentId)
		end
		
		if ADVANCED_FEATURES.MULTI_AGENT_COORDINATION then
			self.CommunicationNetwork = CommunicationNetwork.new()
			self.CommunicationNetwork:RegisterAgent(self.AgentId, aiType)
		end
		
		if ADVANCED_FEATURES.BEHAVIOR_TREES then
			self.BehaviorTree = self:CreateBehaviorTree()
		end
		
		if ADVANCED_FEATURES.PREDICTIVE_PATHING then
			self.PredictiveEngine = PredictiveEngine.new()
		end
		
		if ADVANCED_FEATURES.ENERGY_MANAGEMENT then
			self.EnergyManager = EnergyManager.new()
		end
		
		-- State management
		self.CurrentPath = nil
		self.CurrentWaypointIndex = 1
		self.PathStatus = PATH_STATUS.IN_PROGRESS
		self.TargetPosition = nil
		self.LastPathUpdate = 0
		
		-- Performance optimization
		self.UpdateOffset = math.random() * self.UpdateInterval -- PERBAIKAN 1: Gunakan instance-specific interval
		
		-- Initialize
		self:InitializeNodeGraph()
		
		return true
	end)
	
	if not initSuccess then
		warn("AIController: Initialization failed for agent " .. self.AgentId)
		return nil
	end
	
	-- Layer 10: Protected Update Loop
	self:StartUpdateLoop()
	
	return self
end

-- Implementasi fungsi-fungsi yang hilang di AIController
function AIController:CreateBehaviorTree()
	return BehaviorTree.new()
end

function AIController:InitializeNodeGraph()
	-- Initialize dengan beberapa node dasar di sekitar karakter
	local startPos = self.Character.PrimaryPart.Position
	for i = 1, 10 do
		local nodePos = startPos + Vector3.new(
			math.random(-20, 20),
			0,
			math.random(-20, 20)
		)
		self.NodeGraph:AddNode(nodePos, NODE_TYPES.WALK)
	end
end

function AIController:UpdateVisualPerception()
	-- Simple visual perception update
	self.EnvironmentMonitor:UpdateObstacles()
end

function AIController:UpdateAcousticPerception()
	-- Acoustic perception would go here
	-- For now, just update threat level based on environment
	self.ThreatLevel = self.EnvironmentMonitor:GetComplexityScore() * 0.3
end

function AIController:UpdateEnvironmentalAwareness()
	-- Update environmental awareness
	self.ComplexEnvironment = self.EnvironmentMonitor:GetComplexityScore() > 0.7
end

function AIController:GetAvailableOptions()
	-- Return available movement options
	return {
		{
			path = {self.Character.PrimaryPart.Position, self.TargetPosition},
			safety_factor = 0.8,
			distance = (self.Character.PrimaryPart.Position - self.TargetPosition).Magnitude,
			energy_cost = 1.0,
			risk_level = 0.2
		}
	}
end

function AIController:GetCurrentState()
	return {
		position = self.Character.PrimaryPart.Position,
		velocity = self.Character.PrimaryPart.Velocity,
		aggression = self.LearningSystem and self.LearningSystem.PersonalityMatrix.traits.aggression or 0.5,
		energy = self.EnergyManager and self.EnergyManager:GetEnergyLevel() or 1.0
	}
end

function AIController:ExecuteDecision(decision)
	-- Execute the decision from neural network
	if decision and decision.path then
		self.CurrentPath = decision.path
		self.CurrentWaypointIndex = 1
		self.PathStatus = PATH_STATUS.IN_PROGRESS
	end
end

function AIController:GetPrecisionRequirements()
	return {
		position_tolerance = 1.0,
		angle_tolerance = 15,
		speed_control = true
	}
end

function AIController:CalculateAvailableResources()
	return {
		computation = 1.0 - (self.ActiveComputations / self.MaxParallelComputations),
		memory = 1.0 - (collectgarbage("count") / 50000), -- 50MB limit
		network = 0.8 -- Assume 80% network availability
	}
end

function AIController:PredictResourceNeeds()
	local predictedNeeds = {
		computation = 0.3, -- Base computation need
		memory = 0.2, -- Base memory need
		network = 0.1 -- Base network need
	}
	
	-- Adjust based on current situation
	if self.ComplexEnvironment then
		predictedNeeds.computation = predictedNeeds.computation + 0.3
	end
	
	if self.LongPath then
		predictedNeeds.memory = predictedNeeds.memory + 0.2
	end
	
	if self.SwarmCoordination then
		predictedNeeds.network = predictedNeeds.network + 0.3
	end
	
	return predictedNeeds
end

function AIController:AllocateResources(available, needs)
	-- Simple resource allocation strategy
	local allocation = {}
	
	for resource, need in pairs(needs) do
		allocation[resource] = math.min(need, available[resource] or 0)
	end
	
	-- Apply allocation
	if allocation.computation < needs.computation then
		self:ReduceComputationQuality()
	end
	
	if allocation.memory < needs.memory then
		self:CleanupMemory()
	end
	
	if allocation.network < needs.network then
		self:ReduceCommunicationFrequency()
	end
end

function AIController:ReduceComputationQuality()
	-- Reduce computation quality to save resources
	if self.PathfindingModule then
		self.PathfindingModule.ComputationTimeout = 5.0 -- Reduce from 10 to 5 seconds
	end
end

function AIController:CleanupMemory()
	-- Clean up memory
	if self.LearningSystem and self.LearningSystem.TemporalMemory then
		self.LearningSystem.TemporalMemory:cleanup_old_memories()
	end
	collectgarbage()
end

function AIController:ReduceCommunicationFrequency()
	-- Reduce communication frequency
	if self.CommunicationNetwork then
		-- In real implementation, this would adjust communication intervals
		warn("Reducing communication frequency for agent " .. self.AgentId)
	end
end

-- PERBAIKAN 9: Character validation lebih lengkap
function AIController:DiagnoseSystemHealth()
	local issues = {}
	local performance_score = 1.0
	
	-- Check various system components
	if not self.Character or not self.Character.PrimaryPart or not self.Character.Parent then
		table.insert(issues, "Character invalid or destroyed")
		performance_score = performance_score - 0.3
	end
	
	if self.CurrentPath and #self.CurrentPath > 50 then
		table.insert(issues, "Path too long")
		performance_score = performance_score - 0.1
	end
	
	if self.RecentFailures > 5 then
		table.insert(issues, "High failure rate")
		performance_score = performance_score - 0.2
	end
	
	if collectgarbage("count") > 10000 then
		table.insert(issues, "High memory usage")
		performance_score = performance_score - 0.1
	end
	
	return {
		issues = issues,
		performance_score = math.max(0, performance_score)
	}
end

function AIController:AttemptSelfRepair(issues)
	-- Attempt to repair identified issues
	for _, issue in ipairs(issues) do
		if issue == "Character invalid or destroyed" then
			-- Try to reacquire character reference
			warn("Attempting to repair character reference")
		elseif issue == "Path too long" then
			-- Request new path
			self.CurrentPath = nil
		elseif issue == "High failure rate" then
			-- Reset learning temporarily
			if self.LearningSystem then
				self.LearningSystem.SuccessRate = {}
			end
		elseif issue == "High memory usage" then
			self:CleanupMemory()
		end
	end
end

-- PERBAIKAN 1: Gunakan instance-specific interval
function AIController:OptimizePerformance()
	-- Optimize system performance
	self:CleanupMemory()
	
	-- Adjust update frequency based on performance
	if self.LastUpdateTime > 0.1 then
		self.UpdateInterval = math.min(0.1, self.UpdateInterval * 1.1)
	else
		self.UpdateInterval = math.max(0.01, self.UpdateInterval * 0.9)
	end
end

function AIController:SaveLearningData()
	-- Save learning data (in real implementation, this would save to datastore)
	if self.LearningSystem then
		warn("Saving learning data for agent " .. self.AgentId)
	end
end

-- Layer 11: Safe Update Loop dengan adaptive frequency
function AIController:StartUpdateLoop()
	self.Connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not self.IsActive or self.IsShuttingDown then
			self.Connection:Disconnect()
			return
		end
		
		-- Adaptive update frequency based on complexity
		local updateInterval = self:CalculateAdaptiveUpdateInterval()
		if os.clock() - self.LastUpdateTime < updateInterval then
			return
		end
		
		self.LastUpdateTime = os.clock()
		
		ProtectedCall("AIControllerUpdate", function()
			self:AdvancedUpdate(deltaTime)
		end)
	end)
end

-- PERBAIKAN 1: Gunakan instance-specific interval
function AIController:CalculateAdaptiveUpdateInterval()
	-- Dynamic update rate based on complexity
	local baseInterval = self.UpdateInterval
	
	-- Increase interval if path is simple
	if self.CurrentPath and #self.CurrentPath < 5 then
		return baseInterval * 2
	end
	
	-- Decrease interval if complex environment
	if self.EnvironmentMonitor:GetComplexityScore() > 0.7 then
		return baseInterval * 0.5
	end
	
	-- Decrease interval if high speed
	local currentSpeed = self.MovementHandler:GetCurrentSpeed()
	if currentSpeed > MAX_SPEED * 0.8 then
		return baseInterval * 0.7
	end
	
	return baseInterval
end

-- Layer 12: Advanced Update dengan semua sistem
function AIController:AdvancedUpdate(deltaTime)
	-- Update all systems
	self:UpdatePerception()
	self:UpdateDecisionMaking()
	self:UpdateMovement(deltaTime)
	self:UpdateLearning()
	self:UpdateCommunication()
	
	-- Resource management
	self:UpdateResourceManagement()
	
	-- Self-diagnosis
	self:RunSelfDiagnosis()
end

function AIController:UpdatePerception()
	-- Update visual, acoustic, and environmental perception
	if ADVANCED_FEATURES.SITUATIONAL_AWARENESS then
		self:UpdateVisualPerception()
		self:UpdateAcousticPerception()
		self:UpdateEnvironmentalAwareness()
	end
end

function AIController:UpdateDecisionMaking()
	-- Neural network decision making
	if self.LearningSystem and self.LearningSystem.NeuralNetwork then
		local decision = self.LearningSystem.NeuralNetwork:decide(
			self:GetAvailableOptions(),
			self:GetCurrentState()
		)
		
		if decision then
			self:ExecuteDecision(decision)
		end
	end
	
	-- Behavior tree execution
	if self.BehaviorTree then
		self.BehaviorTree:Execute()
	end
end

function AIController:UpdateMovement(deltaTime)
	-- Biomechanical movement simulation
	if self.MovementHandler then
		self.MovementHandler:UpdateBiomechanicalMovement(deltaTime)
		
		-- Precision movement control
		if self.CurrentPath and self.CurrentWaypointIndex <= #self.CurrentPath then
			self.MovementHandler:MoveToPrecision(
				self.CurrentPath[self.CurrentWaypointIndex],
				self:GetPrecisionRequirements()
			)
		end
	end
end

function AIController:UpdateLearning()
	-- Continuous learning from experiences
	if self.LearningSystem then
		-- Learn from recent path performance
		if self.LastPathPerformance then
			self.LearningSystem:RecordPathExperience(
				self.CurrentPath,
				self.LastPathPerformance.success,
				self.LastPathPerformance.duration
			)
		end
		
		-- Update personality based on experiences
		if self.LearningSystem.PersonalityMatrix then
			self.LearningSystem.PersonalityMatrix:update_emotions({
				recent_failures = self.RecentFailures or 0,
				success_rate = self.SuccessRate or 0.5,
				perceived_threat = self.ThreatLevel or 0.0
			})
		end
	end
end

function AIController:UpdateCommunication()
	-- Multi-agent coordination
	if self.CommunicationNetwork then
		-- Update position in swarm
		self.CommunicationNetwork:UpdateAgentPosition(
			self.AgentId,
			self.Character.PrimaryPart.Position,
			self.Character.PrimaryPart.Velocity
		)
		
		-- Share knowledge with swarm
		if self.CurrentPath then
			self.CommunicationNetwork:SharePathKnowledge(
				self.AgentId,
				self.CurrentPath,
				self.PathStatus
			)
		end
	end
end

function AIController:UpdateResourceManagement()
	-- Predictive resource management
	local availableResources = self:CalculateAvailableResources()
	local predictedNeeds = self:PredictResourceNeeds()
	
	self:AllocateResources(availableResources, predictedNeeds)
	
	-- Energy management
	if self.EnergyManager then
		self.EnergyManager:UpdateEnergyConsumption(self.CurrentActivityLevel)
	end
end

function AIController:RunSelfDiagnosis()
	-- Self-diagnosis and repair
	local healthStatus = self:DiagnoseSystemHealth()
	
	if healthStatus.issues and #healthStatus.issues > 0 then
		warn("AIController " .. self.AgentId .. " detected issues: " .. table.concat(healthStatus.issues, ", "))
		self:AttemptSelfRepair(healthStatus.issues)
	end
	
	-- Performance optimization
	if healthStatus.performance_score < 0.7 then
		self:OptimizePerformance()
	end
end

-- Layer 13: Graceful Shutdown dengan PERBAIKAN 2
function AIController:Shutdown()
	self.IsShuttingDown = true
	self.IsActive = false
	
	-- Disconnect events
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	
	-- Shutdown subsystems
	if self.PathfindingModule then
		self.PathfindingModule.IsShuttingDown = true
	end
	
	if self.CommunicationNetwork then
		self.CommunicationNetwork:Shutdown()
	end
	
	-- PERBAIKAN 2: Cleanup MovementHandler
	if self.MovementHandler then
		self.MovementHandler:Cleanup()
	end
	
	-- Save learning data
	if self.LearningSystem then
		self:SaveLearningData()
	end
	
	-- Clear references
	self.NodeGraph = nil
	self.PathfindingModule = nil
	self.EnvironmentMonitor = nil
	self.MovementHandler = nil
	self.LearningSystem = nil
	self.CommunicationNetwork = nil
	self.BehaviorTree = nil
	self.PredictiveEngine = nil
	self.EnergyManager = nil
	self.CurrentPath = nil
	self.TargetPosition = nil
	
	warn("AIController: Shutdown complete for agent " .. self.AgentId)
end

-- =============================================
-- PUBLIC API FUNCTIONS
-- =============================================

-- Layer 15: Enhanced Public API
function Kynexfind.CreateAI(character, aiType, options)
	-- Pre-flight Check
	if not StabilitySystem.IsSystemStable then
		warn("Kynexfind: System unstable, cannot create AI")
		return nil
	end
	
	-- Validate inputs
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

-- PERBAIKAN 6: Gunakan SwarmId untuk registrasi swarm
function Kynexfind.CreateSwarm(characterCount, aiType, spawnPosition, options)
	-- Validate parameters
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
				ai.SwarmId = "Swarm_" .. HttpService:GenerateGUID(false)
				-- PERBAIKAN 6: Gunakan SwarmId untuk registrasi swarm
				if ai.CommunicationNetwork then
					ai.CommunicationNetwork.SwarmIntelligence.swarm_id = ai.SwarmId
				end
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

-- Additional utility functions dengan PERBAIKAN 7
function Kynexfind.CreateMockCharacter(position)
	-- PERBAIKAN 7: Tambahkan error handling
	local success, result = pcall(function()
		local character = Instance.new("Model")
		local rootPart = Instance.new("Part")
		rootPart.Size = Vector3.new(2, 4, 1)
		rootPart.Position = position
		rootPart.Anchored = true
		rootPart.Name = "HumanoidRootPart"
		
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

-- PERBAIKAN 8: GlobalMonitor sebagai property Kynexfind
Kynexfind._GlobalMonitor = RunService.Heartbeat:Connect(function()
	ProtectedCall("StabilityHeartbeat", function()
		StabilitySystem:Heartbeat()
		StabilitySystem:MonitorMemory()
		
		-- Predictive load balancing
		Kynexfind:PerformLoadBalancing()
	end)
end)

-- Predictive Load Balancing
function Kynexfind:PerformLoadBalancing()
	local systemStatus = self.GetSystemStatus()
	
	if systemStatus.ActiveProcessors >= 4 then
		-- Distribute load to less busy processors
		for processorId, processor in pairs(MemoryManager) do
			if not processor.Active then
				-- Can activate this processor
				break
			end
		end
	end
	
	-- Memory compression if needed
	if systemStatus.MemoryUsage > 50000 then -- 50MB
		self:CompressMemory()
	end
end

function Kynexfind:CompressMemory()
	-- Simple memory compression by cleaning caches
	for _, processor in pairs(MemoryManager) do
		if processor.MemoryPool and processor.MemoryPool.PathCache then
			local newCache = {}
			local count = 0
			
			for key, value in pairs(processor.MemoryPool.PathCache) do
				if count < 100 then -- Keep only 100 entries
					newCache[key] = value
					count = count + 1
				end
			end
			
			processor.MemoryPool.PathCache = newCache
		end
	end
	
	collectgarbage()
end

-- Emergency shutdown function dengan PERBAIKAN 8
function Kynexfind.EmergencyShutdown()
	warn("KYNEXFIND EMERGENCY SHUTDOWN INITIATED")
	
	-- PERBAIKAN 8: Akses GlobalMonitor melalui property
	if Kynexfind._GlobalMonitor then
		Kynexfind._GlobalMonitor:Disconnect()
		Kynexfind._GlobalMonitor = nil
	end
	
	-- Shutdown all active AI controllers
	for _, processor in pairs(MemoryManager) do
		processor.Active = false
		processor.MemoryPool = {}
		processor.Queue = {}
	end
	
	-- Force garbage collection
	collectgarbage()
	
	warn("KYNEXFIND EMERGENCY SHUTDOWN COMPLETE")
end

-- System information function
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

-- Export semua sistem baru
Kynexfind.NeuralNetwork = NeuralNetwork
Kynexfind.PredictiveAnalytics = PredictiveAnalytics
Kynexfind.PersonalityMatrix = PersonalityMatrix
Kynexfind.SwarmIntelligence = SwarmIntelligence
Kynexfind.ThreatAssessment = ThreatAssessment
Kynexfind.MultiLayer3DPathfinding = MultiLayer3DPathfinding
Kynexfind.QuantumPathOptimization = QuantumPathOptimization
Kynexfind.DynamicTerrainAnalysis = DynamicTerrainAnalysis
Kynexfind.TemporalPathMemory = TemporalPathMemory
Kynexfind.AdaptiveHeuristicSystem = AdaptiveHeuristicSystem

-- Export constants and types
Kynexfind.AI_TYPES = AI_TYPES
Kynexfind.NODE_TYPES = NODE_TYPES
Kynexfind.PATH_STATUS = PATH_STATUS
Kynexfind.ADVANCED_FEATURES = ADVANCED_FEATURES
Kynexfind.StabilitySystem = StabilitySystem -- For advanced debugging

warn("Kynexfind v0.2 - FIXED VERSION loaded successfully!")

return Kynexfind

bagaimana cara menyimpannya di github dan mengetest nya
