local Status = {}

local API_URL = "https://minecraft-turtle.up.railway.app/updateStatus"

local currentStatus = "idle"
local currentMode = "none"

function Status.setStatus(status, mode, message)
    currentStatus = status
    currentMode = mode or CurrentMode
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