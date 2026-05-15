local API_URL = "https://minecraft-turtle.up.railway.app/turtles"

-- Change this if your monitor name is different
local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

monitor.setTextScale(0.5)

-- Configuration
local PAGE_INTERVAL = 5 -- seconds to show each page
local TURTLES_PER_PAGE = 5

local pageIndex = 1

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

    -- Build stable list of turtles
    local ids = {}
    for id, _ in pairs(data) do table.insert(ids, id) end
    table.sort(ids, function(a,b) return tonumber(a) < tonumber(b) end)

    local totalTurtles = #ids
    local totalPages = math.max(1, math.ceil(totalTurtles / TURTLES_PER_PAGE))
    pageIndex = ((pageIndex - 1) % totalPages) + 1

    local startIdx = (pageIndex - 1) * TURTLES_PER_PAGE + 1
    local endIdx = math.min(totalTurtles, startIdx + TURTLES_PER_PAGE - 1)

    for idx = startIdx, endIdx do
        local id = ids[idx]
        local turtleData = data[id]
        local label = turtleData.label or ("Turtle " .. id)
        local statusText = tostring(turtleData.status or "unknown")
        local modeText = tostring(turtleData.mode or "unknown")
        local message = truncate(turtleData.message or "", 40)
        local levelText = tostring(turtleData.level or "-")

        if turtleData.online then
            writeLine(label .. " [ONLINE]", colors.green)
        else
            writeLine(label .. " [OFFLINE]", colors.red)
        end

        writeLine("ID: " .. tostring(id) .. "  Mode: " .. modeText)
        writeLine("Status: " .. statusText)
        writeLine("Level: " .. levelText)
        writeLine("Msg: " .. message)

        local fuel = tonumber(turtleData.fuel) or 0
        local steps = tostring(turtleData.actual_distance_from_base or turtleData.steps_from_base or "-")
        local fuelColor = colors.green
        local stepsColor = colors.cyan
        if fuel < 100 then fuelColor = colors.red elseif fuel < 300 then fuelColor = colors.yellow end
        writeLine("Fuel: " .. tostring(turtleData.fuel), fuelColor)
        writeLine("Distance from base: " .. steps .. " blocks", stepsColor)

        writeLine("Seen: " .. tostring(turtleData.age_seconds) .. "s ago")
        writeLine(string.rep("-", 20))
    end

    if totalPages > 1 then
        local w, _ = monitor.getSize()
        writeLine(string.rep("=", w))
        writeLine(string.format("Page %d/%d  (%d turtles)", pageIndex, totalPages, totalTurtles))
    end
end

while true do
    local response = http.get(API_URL)

    if response then
        local body = response.readAll()
        response.close()

        local data = textutils.unserializeJSON(body)
        drawTurtles(data)
        -- advance page
        local count = 0 for _ in pairs(data) do count = count + 1 end
        local totalPages = math.max(1, math.ceil(count / TURTLES_PER_PAGE))
        if totalPages > 1 then
            pageIndex = pageIndex % totalPages + 1
        else
            pageIndex = 1
        end
    else
        clear()
        writeLine("Turtle Monitor")
        writeLine("==============")
        writeLine("")
        writeLine("Failed to reach backend")
    end

    sleep(PAGE_INTERVAL)
end