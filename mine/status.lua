local Status = {}

local API_URL = "https://minecraft-turtle.up.railway.app/status"

local currentStatus = "idle"
local currentMode = "none"
local fuelNeeded = 0

function Status.setStatus(status, mode, message, fuelNeededToBase)
    currentStatus = status
    currentMode = mode or currentMode
    fuelNeeded = fuelNeededToBase or 0
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