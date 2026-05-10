local history = require("history")
local fuel = require("fuel")
local vein = require("vein")

local SAFETY_FUEL = 40

local function turnAround()
    turtle.turnRight()
    turtle.turnRight()
end

local function inventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    
    return true
end

local function dropOffItems()
    -- Dropoff chest is behind the turtle
    turnAround()
    
    for slot = 1, 16 do
        turtle.select(slot)
        
        local item = turtle.getItemDetail(slot)
        
        -- Keep coal, drop everything else
        if item and item.name ~= "minecraft:coal" then
            turtle.drop()
        end
    end
    
    -- Face strip mine direction again
    turnAround()
end

local function restockCoal()
    -- Coal/refuel chest is to the turtle's right
    turtle.turnRight()
    
    -- Pull coal from chest
    turtle.suck()
    
    -- Refuel using coal in inventory
    fuel.refuelFromInventory()
    
    -- Face strip mine direction again
    turtle.turnLeft()
end

local function serviceAtBase()
    print("Returning to base for dropoff/refuel")
    
    -- Go back to base but keep path so we can return to mining spot after
    history.returnToBase(true)
    
    dropOffItems()
    restockCoal()
    
    -- Return to exact strip-mining spot
    history.goBackToWork()
    history.useMain()
    
    print("Returned to work position")
end

local function needsService()
    local neededToBase = history.fuelNeededToBase()
    
    if turtle.getFuelLevel() <= neededToBase + SAFETY_FUEL then
        print("Fuel Level:", turtle.getFuelLevel(), " |  Needed to base:", neededToBase, " |  Safety Fuel:", SAFETY_FUEL)
        return true
    end
    
    if inventoryFull() then
        return true
    end
    
    return false
end

local function isOre(block)
    if not block then return false end
    
    return string.find(block.name, "_ore") ~= nil or
        block.name == "minecraft:ancient_debris" or
        block.name == "minecraft:netherrack"
end

local function inspectForOre()
    local found, block = turtle.inspect()
    return found and isOre(block)
end

local function inspectUpForOre()
    local found, block = turtle.inspectUp()
    
    return found and isOre(block)
end

local function inspectDownForOre()
    local found, block = turtle.inspectDown()
    
    return found and isOre(block)
end

local function stripMine()
    history.useMain()
    
    print("Starting fuel:", turtle.getFuelLevel()) 
    while true do
        if needsService() then
            serviceAtBase()
            -- Do we have enough fuel for another go?
            
        end
        
        -- Mine forward tunnel
        turtle.dig()
        history.forward()
        
        -- If ore is directly ahead, mine the vein
        if inspectForOre() then
            vein.mineVein()
        end
        
        -- Check left side for ore
        turtle.turnLeft()
        if inspectForOre() then
            vein.mineVein()
        end
        turtle.turnRight()
        
        -- Check right side for ore
        turtle.turnRight()
        if inspectForOre() then
            vein.mineVein()
        end
        turtle.turnLeft()
        
        -- Check up for ore
        if inspectUpForOre() then
            vein.mineVein()
        end
        
        -- Check down for ore
        if inspectDownForOre() then
            vein.mineVein()
        end
        
        -- Demo stop condition
        print(history.fuelNeededToBase())
        if history.fuelNeededToBase() >= 200 then
            break
        end
    end
    
    history.returnToBase(false)
end

stripMine()
