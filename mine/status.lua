local Status = {}

local API_URL = "https://minecraft-turtle.up.railway.app/status"

local config = {}

do
    local ok, loadedConfig = pcall(require, "config")

    if ok and type(loadedConfig) == "table" then
        config = loadedConfig
    end
end

if config.turtleName then
    local currentLabel = os.getComputerLabel()
    if currentLabel ~= config.turtleName then
        os.setComputerLabel(config.turtleName)
    end
end

local currentStatus = "idle"
local currentMode = "none"
local fuelNeeded = 0
local currentLevel = nil
local actualDistance = 0
local currentMessage = ""
local currentErrorReason = nil

function Status.setStepsFromBase(stepsFromBase)
    fuelNeeded = math.max(0, tonumber(stepsFromBase) or 0)
end

function Status.setActualDistanceFromBase(distanceFromBase)
    actualDistance = math.max(0, tonumber(distanceFromBase) or 0)
end

function Status.setStatus(status, mode, message, fuelNeededToBase, level)
    currentStatus = status
    currentMode = mode or currentMode
    currentMessage = message or currentMessage
    currentErrorReason = nil
    if fuelNeededToBase ~= nil then
        Status.setStepsFromBase(fuelNeededToBase)
    end
    if level ~= nil then
        currentLevel = level
    end
    Status.heartbeat(message)
end

function Status.setError(status, mode, message, fuelNeededToBase, level)
    currentStatus = status or "stuck"
    currentMode = mode or currentMode
    currentMessage = message or currentMessage
    currentErrorReason = message

    if fuelNeededToBase ~= nil then
        Status.setStepsFromBase(fuelNeededToBase)
    end
    if level ~= nil then
        currentLevel = level
    end

    return Status.heartbeat(message)
end

function Status.heartbeat(message)
    if not http then
        print("HTTP API not available")
        return false
    end

    local computerId = os.getComputerID()
    local label = os.getComputerLabel()
    local turtleName = config.turtleName or label or ("Turtle " .. tostring(computerId))

    local body = textutils.serializeJSON({
        id = computerId,
        label = label or turtleName,
        mine_id = config.mineId or "unknown",
        strip_id = config.stripId or "unknown",
        turtle_name = turtleName,
        status = currentStatus,
        mode = currentMode,
        fuel = turtle.getFuelLevel(),
        steps_from_base = fuelNeeded,
        actual_distance_from_base = actualDistance,
        level = currentLevel,
        message = message or currentMessage or "",
        error_reason = currentErrorReason
    })

    local response = http.post(API_URL, body, {
        ["Content-Type"] = "application/json"
    })

    if response then
        response.close()
        return true
    end

    return false
end

return Status