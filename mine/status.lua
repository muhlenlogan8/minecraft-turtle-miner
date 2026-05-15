local Status = {}

local API_URL = "https://minecraft-turtle.up.railway.app/status"

local currentStatus = "idle"
local currentMode = "none"
local fuelNeeded = 0
local currentLevel = nil
local actualDistance = 0

function Status.setStepsFromBase(stepsFromBase)
    fuelNeeded = math.max(0, tonumber(stepsFromBase) or 0)
end

function Status.setActualDistanceFromBase(distanceFromBase)
    actualDistance = math.max(0, tonumber(distanceFromBase) or 0)
end

function Status.setStatus(status, mode, message, fuelNeededToBase, level)
    currentStatus = status
    currentMode = mode or currentMode
    if fuelNeededToBase ~= nil then
        Status.setStepsFromBase(fuelNeededToBase)
    end
    if level ~= nil then
        currentLevel = level
    end
    Status.heartbeat(message)
end

function Status.heartbeat(message)
    if not http then
        print("HTTP API not available")
        return false
    end

    local body = textutils.serializeJSON({
        id = os.getComputerID(),
        label = os.getComputerLabel(),
        status = currentStatus,
        mode = currentMode,
        fuel = turtle.getFuelLevel(),
        steps_from_base = fuelNeeded,
        actual_distance_from_base = actualDistance,
        level = currentLevel,
        message = message or ""
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