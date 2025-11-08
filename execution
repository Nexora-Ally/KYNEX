-- Simple & Safe Loadstring Executor
-- by Zarizz (optimized version)

local HttpService = game:GetService("HttpService")

local allowed_domains = { "raw.githubusercontent.com", "gist.githubusercontent.com" }
local MAX_SIZE = 200 * 1024 -- 200 KB max
local VERBOSE = true

local function log(...)
	if VERBOSE then print("[SafeLoader]", ...) end
end

local function getDomain(url)
	return url:match("^https?://([^/]+)")
end

local function isAllowed(url)
	local host = getDomain(url)
	for _, domain in ipairs(allowed_domains) do
		if host and host:find(domain) then return true end
	end
	return false
end

local function httpGet(url)
	if syn and syn.request then
		local r = syn.request({ Url = url, Method = "GET" })
		if r and r.StatusCode == 200 then return r.Body end
	elseif http and http.request then
		local r = http.request({ Url = url, Method = "GET" })
		if r and r.StatusCode == 200 then return r.Body end
	else
		return HttpService:GetAsync(url, true)
	end
end

local function makeSandbox()
	local env = {
		print = function(...) print("[Sandbox]:", ...) end,
		pairs = pairs,
		ipairs = ipairs,
		type = type,
		tostring = tostring,
		math = math,
		string = string,
		table = table,
		os = { time = os.time, clock = os.clock },
	}
	return env
end

return function(url)
	if type(url) ~= "string" or not url:match("^https://") then
		warn("❌ Invalid or non-HTTPS URL.")
		return
	end
	if not isAllowed(url) then
		warn("❌ Domain not allowed:", getDomain(url))
		return
	end

	local ok, result = pcall(httpGet, url)
	if not ok or not result then
		warn("❌ Failed to fetch:", result)
		return
	end
	if #result > MAX_SIZE then
		warn("❌ Script too large.")
		return
	end
	if result:match("os%.execute") or result:match("io%.popen") or result:match("loadstring%(") then
		warn("⚠️ Suspicious code detected.")
		return
	end

	local func, err = loadstring(result)
	if not func then
		warn("❌ Loadstring error:", err)
		return
	end

	setfenv(func, makeSandbox())

	local success, msg = pcall(func)
	if success then
		log("✅ Script executed successfully!")
	else
		warn("❌ Runtime error:", msg)
	end
end
