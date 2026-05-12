local history = require("history")
local fuel = require("fuel")
local vein = require("vein")
local status = require("status")

local SAFETY_FUEL = 40
local STRIP_LENGTH = 350
local DROP_PER_LEVEL = 2
local MAX_LEVELS = 60 -- Optional safety limit just in case

local function turnAround()
    turtle.turnRight()
    turtle.turnRight()
end

local function goDownOne()
    turtle.digDown()

    if history.down() then
        return true
    end

    print("Could not move down.")
    return false
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

local function serviceAtBase(fullService)
    print("Returning to base for dropoff/refuel")
    status.setStatus("running", "servicing", "Returning to base for dropoff/refuel")
    
    -- Go back to base but keep path if this is a full service (for returning to work position after)
    if fullService then
        history.returnToBase(true)
    else
        history.returnToBase(false)
    end
    
    dropOffItems()
    if fullService then restockCoal() end
    
    -- Return to exact strip-mining spot
    status.setStatus("running", "strip_mining", "Returned to work position")
    if fullService then history.goBackToWork() end
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
        block.name == "minecraft:ancient_debris"
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

local function mineOneStep()
    if needsService() then
        serviceAtBase(true)
    end

    turtle.dig()
    history.forward()

    -- Check front
    if inspectForOre() then
        vein.mineVein()
    end

    -- Check left
    turtle.turnLeft()
    if inspectForOre() then
        vein.mineVein()
    end
    turtle.turnRight()

    -- Check right
    turtle.turnRight()
    if inspectForOre() then
        vein.mineVein()
    end
    turtle.turnLeft()

    -- Check up
    if inspectUpForOre() then
        vein.mineVein()
    end

    -- Check down
    if inspectDownForOre() then
        vein.mineVein()
    end
end

local function goDownToNextLevel()
    for i = 1, DROP_PER_LEVEL do
        if needsService() then
            serviceAtBase(true)
        end

        if not goDownOne() then
            return false
        end
    end

    return true
end

local function stripMine()
    history.useMain()
    status.setStatus("running", "strip_mining", "Starting miner", history.fuelNeededToBase())

    print("Starting fuel:", turtle.getFuelLevel())

    local level = 1

    local shouldStop = false

    while level <= MAX_LEVELS and not shouldStop do
        print("Starting level:", level)
        status.setStatus("running", "strip_mining", "Mining level " .. level, history.fuelNeededToBase())

        -- Mine 300 blocks forward on this level
        for step = 1, STRIP_LENGTH do
            status.heartbeat("L" .. level .. " | step " .. step .. "/" .. STRIP_LENGTH)
            mineOneStep()
        end

        -- After 300 blocks service at base before going down to next level
        serviceAtBase(false)

        -- After service, go down 2 blocks
        print("Finished level " .. level .. ". Going down " .. DROP_PER_LEVEL .. " blocks.")
        status.setStatus("running", "descending", "Going down to next level", history.fuelNeededToBase())

        for drop = 1, level do
            if not goDownToNextLevel() then
                print("Hit bottom or cannot go lower. Stopping.")
                shouldStop = true
                break
            end
        end

        level = level + 1
    end

    status.setStatus("running", "returning", "Returning to base", history.fuelNeededToBase())

    history.returnToBase(false)

    dropOffItems()
    restockCoal()

    status.setStatus("idle", "done", "Returned to base", history.fuelNeededToBase())
end

stripMine()
