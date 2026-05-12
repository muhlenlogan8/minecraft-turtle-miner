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

    local function center(text)
        local w, _ = monitor.getSize()
        local pad = math.max(0, math.floor((w - string.len(text)) / 2))
        return string.rep(" ", pad) .. text
    end

    local function truncate(s, n)
        s = tostring(s or "")
        if string.len(s) <= n then return s end
        return string.sub(s, 1, n - 3) .. "..."
    end

    writeLine(center("Turtle Monitor"))
    writeLine(center("=============="))
    writeLine("")

    if not data or next(data) == nil then
        writeLine("No turtles reporting.")
        return
    end

    for id, turtleData in pairs(data) do
        local label = turtleData.label or ("Turtle " .. id)
        local statusText = tostring(turtleData.status or "unknown")
        local modeText = tostring(turtleData.mode or "unknown")
        local message = truncate(turtleData.message or "", 40)

        if turtleData.online then
            writeLine(label .. " [ONLINE]", colors.green)
        else
            writeLine(label .. " [OFFLINE]", colors.red)
        end

        writeLine("ID: " .. tostring(id) .. "  Mode: " .. modeText)
        writeLine("Status: " .. statusText)
        writeLine("Msg: " .. message)

        local fuel = tonumber(turtleData.fuel) or 0
        local steps = tostring(turtleData.steps_from_base or "-")
        local fuelColor = colors.green
        if fuel < 100 then fuelColor = colors.red elseif fuel < 300 then fuelColor = colors.yellow end
        writeLine("Fuel: " .. tostring(turtleData.fuel) .. "  StepsFromBase: " .. steps, fuelColor)

        writeLine("Seen: " .. tostring(turtleData.age_seconds) .. "s ago")
        writeLine(string.rep("-", 20))
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