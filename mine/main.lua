local history = require("history")
local fuel = require("fuel")
local vein = require("vein")
local status = require("status")

local SAFETY_FUEL = 80
local STRIP_LENGTH = 350
local DROP_PER_LEVEL = 1
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
        
        if item then
            turtle.drop()
        end
    end
    
    -- Face strip mine direction again
    turnAround()
end

local function isChest(block)
    if not block then return false end

    return block.name == "minecraft:chest"
        or block.name == "minecraft:trapped_chest"
        or string.find(block.name, "chest") ~= nil
end

local function trySuckFromChest()
    local found, block = turtle.inspect()

    if found and isChest(block) then
        turtle.suck()
        fuel.refuelFromInventory()
        return true
    end

    return false
end

local function restockCoal()
    -- Check for right chest
    turtle.turnRight()

    if trySuckFromChest() then
        turtle.turnLeft()
        return true
    end
    
    -- If no chest on right, check left
    turnAround()

    if trySuckFromChest() then
        turtle.turnRight()
        return true
    end

    -- No chest found, face strip mine direction again
    turtle.turnRight()

    print("No fuel chest found for refueling!")
    return false
end

local function waitForSafeFuel()
    local attempts = 0
    local requiredFuel = math.max(SAFETY_FUEL, history.fuelNeededForAnotherGo())

    while turtle.getFuelLevel() < requiredFuel do
        attempts = attempts + 1
        requiredFuel = math.max(SAFETY_FUEL, history.fuelNeededForAnotherGo())
        status.setStatus(
            "waiting_for_fuel",
            "servicing",
            "Waiting for coal (attempt " .. attempts .. ")",
            history.fuelNeededToBase()
        )

        if restockCoal() then
            fuel.refuelFromInventory()
        end

        status.heartbeat(
            "Waiting for coal | fuel " .. turtle.getFuelLevel() .. "/" .. requiredFuel
        )

        if turtle.getFuelLevel() >= requiredFuel then
            break
        end

        sleep(2)
    end

    status.setStatus(
        "running",
        "servicing",
        "Fuel restored to safe level",
        history.fuelNeededToBase()
    )
end

local function serviceAtBase(keepPath)
    print("Returning to base for dropoff/refuel")
    status.setStatus("running", "servicing", "Returning to base for dropoff/refuel")
    
    local reachedBase

    if keepPath then
        reachedBase = history.returnToBase(true)
    else
        reachedBase = history.returnToBase(false)
    end

    if not reachedBase then
        print("Could not reach base. Skipping refuel.")
        return false
    end
    
    dropOffItems()
    restockCoal()
    if turtle.getFuelLevel() < math.max(SAFETY_FUEL, history.fuelNeededForAnotherGo()) then
        waitForSafeFuel()
    end
    
    if keepPath then
        status.setStatus("running", "strip_mining", "Returned to work position")
        if not history.goBackToWork() then
            print("Could not return to work position.")
            return false
        end
    end
    
    history.useMain()
    
    print("Returned to base")
    return true
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

local function mineOneStep(level, step)
    status.setStatus(
        "running",
        "mining",
        "Mining level " .. tostring(level) .. " step " .. tostring(step),
        history.fuelNeededToBase(),
        level
    )

    if needsService() then
        if not serviceAtBase(true) then
            status.setError("stuck", "servicing", "Failed servicing at base", history.fuelNeededToBase(), level)
            return false
        end
    end

    turtle.dig()
    if not history.forward() then
        status.setError("stuck", "strip_mining", "Failed to advance on level " .. tostring(level), history.fuelNeededToBase(), level)
        return false
    end

    -- Check front
    if inspectForOre() then
        status.setStatus("running", "vein_mining", "Mining vein ahead", history.fuelNeededToBase(), level)
        if not vein.mineVein() then return false end
    end

    -- Check left
    turtle.turnLeft()
    if inspectForOre() then
        status.setStatus("running", "vein_mining", "Mining vein on left", history.fuelNeededToBase(), level)
        if not vein.mineVein() then return false end
    end
    turtle.turnRight()

    -- Check right
    turtle.turnRight()
    if inspectForOre() then
        status.setStatus("running", "vein_mining", "Mining vein on right", history.fuelNeededToBase(), level)
        if not vein.mineVein() then return false end
    end
    turtle.turnLeft()

    -- Check up
    if inspectUpForOre() then
        status.setStatus("running", "vein_mining", "Mining vein above", history.fuelNeededToBase(), level)
        if not vein.mineVein() then return false end
    end

    -- Check down
    if inspectDownForOre() then
        status.setStatus("running", "vein_mining", "Mining vein below", history.fuelNeededToBase(), level)
        if not vein.mineVein() then return false end
    end

    return true
end

local function goDownBlocks(blockCount)
    for i = 1, blockCount do
        if needsService() then
            if not serviceAtBase(true) then
                return false
            end
        end

        if not goDownOne() then
            return false
        end
    end

    return true
end

local function stripMine()
    history.useMain()
    status.setStatus("running", "strip_mining", "Starting miner", history.fuelNeededToBase(), 1)

    print("Starting fuel:", turtle.getFuelLevel())

    local level = 1
    local currentDepth = 0

    local shouldStop = false

    while level <= MAX_LEVELS and not shouldStop do
        if currentDepth > 0 then
            print("Descending", currentDepth, "blocks for level", level)
            status.setStatus("running", "descending", "Going down to level " .. level, history.fuelNeededToBase(), level)

            if not goDownBlocks(currentDepth) then
                print("Hit bottom or cannot go lower. Stopping.")
                shouldStop = true
                break
            end
        end

        print("Starting level:", level)
        status.setStatus("running", "strip_mining", "Mining level " .. level, history.fuelNeededToBase(), level)

        -- Mine 350 blocks forward on this level
        for step = 1, STRIP_LENGTH do
            if not mineOneStep(level, step) then
                shouldStop = true
                break
            end
        end

        if shouldStop then
            break
        end

        -- After 350 blocks return to base, drop off, and refuel.
        if not serviceAtBase(false) then
            shouldStop = true
            break
        end

        currentDepth = currentDepth + DROP_PER_LEVEL

        level = level + 1
    end

    status.setStatus("running", "returning", "Returning to base", history.fuelNeededToBase(), level)

    if not history.returnToBase(false) then
        return
    end

    dropOffItems()
    restockCoal()

    status.setStatus("idle", "done", "Returned to base", history.fuelNeededToBase(), level)
end

stripMine()
