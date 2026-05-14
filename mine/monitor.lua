local API_URL = "https://minecraft-turtle.up.railway.app/turtles"

-- Change this if your monitor name is different
local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

monitor.setTextScale(0.5)

-- Configuration
local PAGE_INTERVAL = 5 -- seconds to show each page
local COMPACT_MODE = true -- one-line-per-turtle when true

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

    local w, h = monitor.getSize()
    local headerLines = 3

    if COMPACT_MODE then
        -- Build stable list of turtles
        local ids = {}
        for id, _ in pairs(data) do table.insert(ids, id) end
        table.sort(ids, function(a,b) return tostring(a) < tostring(b) end)

        local rows = {}
        for _, id in ipairs(ids) do
            local t = data[id]
            local label = truncate(t.label or ("T" .. id), 12)
            local statusText = tostring(t.status or "unk")
            local fuel = tonumber(t.fuel) or 0
            local steps = tostring(t.steps_from_base or "-")
            local age = tostring(t.age_seconds or "-")
            local lvl = tostring(t.level or "-")

            local statusShort = statusText
            if string.len(statusShort) > 6 then statusShort = string.sub(statusShort,1,6) end

            local fuelMark = tostring(fuel)
            local line = string.format("%s %s | F:%s | D:%s | L:%s | %ss", label, statusShort, fuelMark, steps, lvl, age)
            if string.len(line) > w then line = truncate(line, w) end
            table.insert(rows, {line=line, online=not not t.online})
        end

        local pageSize = math.max(1, h - headerLines - 1)
        local totalPages = math.max(1, math.ceil(#rows / pageSize))
        pageIndex = ((pageIndex - 1) % totalPages) + 1
        local startIdx = (pageIndex - 1) * pageSize + 1
        local endIdx = math.min(#rows, startIdx + pageSize - 1)

        for i = startIdx, endIdx do
            local r = rows[i]
            local color = r.online and colors.white or colors.gray
            writeLine(r.line, color)
        end

        writeLine(string.rep("=", w))
        writeLine(string.format("Page %d/%d  (%d turtles)", pageIndex, totalPages, #rows))
    else
        -- Verbose mode (existing layout)
        for id, turtleData in pairs(data) do
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
            local steps = tostring(turtleData.steps_from_base or "-")
            local fuelColor = colors.green
            local stepsColor = colors.cyan
            if fuel < 100 then fuelColor = colors.red elseif fuel < 300 then fuelColor = colors.yellow end
            writeLine("Fuel: " .. tostring(turtleData.fuel), fuelColor)
            writeLine("Distance from base: " .. steps .. " blocks", stepsColor)

            writeLine("Seen: " .. tostring(turtleData.age_seconds) .. "s ago")
            writeLine(string.rep("-", 20))
        end
    end
end

while true do
    local response = http.get(API_URL)

    if response then
        local body = response.readAll()
        response.close()

        local data = textutils.unserializeJSON(body)
        drawTurtles(data)
        -- advance page only when in compact mode and multiple pages
        if COMPACT_MODE then
            -- determine pages based on monitor height
            local _, h = monitor.getSize()
            local pageSize = math.max(1, h - 3 - 1)
            local count = 0 for _ in pairs(data) do count = count + 1 end
            local totalPages = math.max(1, math.ceil(count / pageSize))
            if totalPages > 1 then
                pageIndex = pageIndex % totalPages + 1
            else
                pageIndex = 1
            end
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