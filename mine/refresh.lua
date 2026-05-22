local args = { ... }

local API_URL = "https://minecraft-turtle.up.railway.app"

if not http then
    print("HTTP API not available")
    return
end

local response = http.post(API_URL .. "/refresh", "", {
    ["Content-Type"] = "application/json"
})

if not response then
    print("Failed to refresh turtle data")
    return
end

local body = response.readAll()
response.close()

if body and #body > 0 then
    print(body)
else
    print("Cleared all turtle data")
end

print("Rebooting to refresh local state...")
os.reboot()