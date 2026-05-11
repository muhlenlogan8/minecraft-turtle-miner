local Status = {}

local API_URL = "https://minecraft-turtle.up.railway.app/updateStatus"

local currentStatus = "idle"
local currentMode = "none"

function Status.set(status, mode, message)
    currentStatus = status
    currentMode = mode or CurrentMode
    Status.heartbeat(message)
end

function Status.heartbeat(message)
    if not http then return end

    local body = textutils.serializeJSON({
        id = os.getComputerID(),
        label.os.getComputerLabel(),
        status = currentStatus,
        mode = currentMode,
        fuel = turtle.getFuelLevel(),
        message = message or ""
    })

    pcall(function()
        http.post(API_URL, body, {["Content-Type"] = "application/json"})
    end)
end

return Status