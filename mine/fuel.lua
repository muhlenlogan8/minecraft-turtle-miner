local Fuel = {}

local status = require("status")

local COAL_FUEL_VALUE = 80

function Fuel.countCoal()
    local count = 0
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        
        if item and item.name == "minecraft:coal" then
            count = count + item.count
        end
    end
    
    return count
end

function Fuel.totalFuelAvailable()
    return turtle.getFuelLevel() + Fuel.countCoal() * COAL_FUEL_VALUE
end

function Fuel.refuelFromInventory()
    print("Refueling from inventory")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        
        if item and item.name == "minecraft:coal" then
            status.heartbeat("Refueling from coal inventory")
            turtle.select(slot)
            local count = item.count
            while count > 0 and turtle.getFuelLevel() < 1000 do
                turtle.refuel(1)
                count = count - 1
            end
        end
    end
end

return Fuel
