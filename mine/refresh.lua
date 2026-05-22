local args = { ... }

local API_URL = "https://minecraft-turtle.up.railway.app"
local turtleId = tostring(args[1] or os.getComputerID())
local clearAll = args[1] == "all"

if not http then
    print("HTTP API not available")
    return
end

local response = http.post(API_URL .. "/refresh", textutils.serializeJSON({
    id = turtleId,
    label = os.getComputerLabel(),
    clear_all = clearAll
}), {
    ["Content-Type"] = "application/json"
})

if not response then
    print("Failed to clear turtle data for " .. turtleId)
    return
end

local body = response.readAll()
response.close()

if body and #body > 0 then
    print(body)
else
    print("Cleared turtle data for " .. turtleId)
end

print("Rebooting to refresh local state...")
os.reboot()