local API_URL = "https://YOUR-RAILWAY-APP.up.railway.app/turtles"

while true do
    term.clear()
    term.setCursorPos(1, 1)

    print("Turtle Monitor")
    print("==============")
    print("")

    local response = http.get(API_URL)

    if not response then
        print("Failed to reach backend")
    else
        local body = response.readAll()
        response.close()

        local data = textutils.unserializeJSON(body)

        if not data then
            print("Invalid JSON")
        else
            for id, turtleData in pairs(data) do
                local online = turtleData.online and "ONLINE" or "OFFLINE"

                print((turtleData.label or ("Turtle " .. id)) .. " - " .. online)
                print("Status: " .. tostring(turtleData.status))
                print("Mode: " .. tostring(turtleData.mode))
                print("Fuel: " .. tostring(turtleData.fuel))
                print("Seen: " .. tostring(turtleData.age_seconds) .. "s ago")
                print("")
            end
        end
    end

    sleep(5)
end