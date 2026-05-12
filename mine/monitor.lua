local API_URL = "https://minecraft-turtle.up.railway.app/turtles"

-- Change this if your monitor name is different
local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

monitor.setTextScale(0.5)

local function clear()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

local function writeLine(text, color)
    if color then
        monitor.setTextColor(color)
    else
        monitor.setTextColor(colors.white)
    end

    local _, y = monitor.getCursorPos()
    monitor.write(text)
    monitor.setCursorPos(1, y + 1)

    monitor.setTextColor(colors.white)
end

local function drawTurtles(data)
    clear()

    writeLine("Turtle Monitor")
    writeLine("==============")
    writeLine("")

    if not data or next(data) == nil then
        writeLine("No turtles reporting.")
        return
    end

    for id, turtleData in pairs(data) do
        local online = turtleData.online and "ONLINE" or "OFFLINE"
        local label = turtleData.label or ("Turtle " .. id)

        if turtleData.online then
            writeLine(label .. " [ONLINE]", colors.green)
        else
            writeLine(label .. " [OFFLINE]", colors.red)
        end

        writeLine("Mode: " .. tostring(turtleData.mode))
        writeLine("Status: " .. tostring(turtleData.status))
        writeLine("Last Message: " .. tostring(turtleData.message))

        local fuel = tonumber(turtleData.fuel) or 0
        if fuel < 100 then
            writeLine("Fuel: " .. tostring(turtleData.fuel), colors.red)
        elseif fuel < 300 then
            writeLine("Fuel: " .. tostring(turtleData.fuel), colors.yellow)
        else
            writeLine("Fuel: " .. tostring(turtleData.fuel), colors.green)
        end
        
        writeLine("Steps From Base: " .. tostring(turtleData.steps_from_base))
        writeLine("Seen: " .. tostring(turtleData.age_seconds) .. "s ago")
        writeLine("")
    end
end

while true do
    local response = http.get(API_URL)

    if response then
        local body = response.readAll()
        response.close()

        local data = textutils.unserializeJSON(body)
        drawTurtles(data)
    else
        clear()
        writeLine("Turtle Monitor")
        writeLine("==============")
        writeLine("")
        writeLine("Failed to reach backend")
    end

    sleep(5)
end