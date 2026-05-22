local history = require("history")
local fuel = require("fuel")
local status = require("status")

local config = {}

do
    local ok, loadedConfig = pcall(require, "config")

    if ok and type(loadedConfig) == "table" then
        config = loadedConfig
    end
end

local SAFETY_FUEL = tonumber(config.quarrySafetyFuel) or 80

-- New x/y/z names, with compatibility for older config keys.
local QUARRY_X = tonumber(config.quarryX) or tonumber(config.quarryForwardSteps) or 16
local QUARRY_Y = tonumber(config.quarryY) or tonumber(config.quarryRows) or 16
local QUARRY_Z = tonumber(config.quarryZ) or tonumber(config.quarryMaxRows) or 16

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
    -- Dropoff chest is behind the turtle at base.
    turnAround()

    for slot = 1, 16 do
        turtle.select(slot)

        local item = turtle.getItemDetail(slot)

        if item then
            turtle.drop()
        end
    end

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
    -- Fuel chest is expected on right or left of turtle at base.
    turtle.turnRight()

    if trySuckFromChest() then
        turtle.turnLeft()
        return true
    end

    turnAround()

    if trySuckFromChest() then
        turtle.turnRight()
        return true
    end

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
        "quarry",
        "Fuel restored to safe level",
        history.fuelNeededToBase()
    )
end

local function serviceAtBase(keepPath)
    print("Returning to base for dropoff/refuel")
    status.setStatus("running", "servicing", "Returning to base for dropoff/refuel")

    local reachedBase = history.returnToBase(keepPath == true)

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
        status.setStatus("running", "quarry", "Returned to work position")

        if not history.goBackToWork() then
            print("Could not return to work position.")
            return false
        end
    end

    history.useMain("quarry")

    print("Returned to base")
    return true
end

local function needsService()
    local neededToBase = history.fuelNeededToBase()

    if turtle.getFuelLevel() <= neededToBase + SAFETY_FUEL then
        print("Fuel Level:", turtle.getFuelLevel(), " | Needed to base:", neededToBase, " | Safety Fuel:", SAFETY_FUEL)
        return true
    end

    if inventoryFull() then
        return true
    end

    return false
end

local function moveForwardDig(level, row, xPos)
    if needsService() then
        if not serviceAtBase(true) then
            status.setError("stuck", "servicing", "Failed servicing at base", history.fuelNeededToBase(), level)
            return false
        end
    end

    status.setStatus(
        "running",
        "quarry",
        "Layer " .. level .. " row " .. row .. " x " .. xPos,
        history.fuelNeededToBase(),
        level
    )

    turtle.dig()

    if not history.forward() then
        status.setError(
            "stuck",
            "quarry",
            "Failed to advance on layer " .. level .. " row " .. row .. " x " .. xPos,
            history.fuelNeededToBase(),
            level
        )
        return false
    end

    return true
end

local function shiftToNextRow(layer, row, goRight)
    if goRight then
        if not history.turnRight() then
            return false
        end
    else
        if not history.turnLeft() then
            return false
        end
    end

    if needsService() then
        if not serviceAtBase(true) then
            status.setError("stuck", "servicing", "Failed servicing while shifting rows", history.fuelNeededToBase(), layer)
            return false
        end
    end

    turtle.dig()

    if not history.forward() then
        status.setError(
            "stuck",
            "quarry",
            "Failed to shift to row " .. (row + 1) .. " on layer " .. layer,
            history.fuelNeededToBase(),
            layer
        )
        return false
    end

    if goRight then
        if not history.turnRight() then
            return false
        end
    else
        if not history.turnLeft() then
            return false
        end
    end

    return true
end

local function enterLayer(layer)
    status.setStatus("running", "quarry", "Entering layer " .. layer, history.fuelNeededToBase(), layer)

    -- Move out from base, then one more block so the quarry starts two blocks ahead.
    turtle.dig()

    if not history.forward() then
        status.setError("stuck", "quarry", "Could not enter quarry area", history.fuelNeededToBase(), layer)
        return false
    end

    turtle.dig()

    if not history.forward() then
        status.setError("stuck", "quarry", "Could not enter quarry area", history.fuelNeededToBase(), layer)
        return false
    end

    for depth = 2, layer do
        if needsService() then
            if not serviceAtBase(true) then
                status.setError("stuck", "servicing", "Failed servicing while entering layer", history.fuelNeededToBase(), layer)
                return false
            end
        end

        if not goDownOne() then
            status.setError(
                "stuck",
                "quarry",
                "Could not reach depth for layer " .. layer,
                history.fuelNeededToBase(),
                layer
            )
            return false
        end
    end

    return true
end

local function mineLayer(layer)
    if not enterLayer(layer) then
        return false
    end

    for row = 1, QUARRY_Y do
        status.setStatus(
            "running",
            "quarry",
            "Mining layer " .. layer .. " row " .. row .. " of " .. QUARRY_Y,
            history.fuelNeededToBase(),
            layer
        )

        -- We are already on x = 1 after entering the layer.
        for xPos = 2, QUARRY_X do
            if not moveForwardDig(layer, row, xPos) then
                return false
            end
        end

        if row < QUARRY_Y then
            local goRight = (row % 2 == 1)
            if not shiftToNextRow(layer, row, goRight) then
                return false
            end
        end
    end

    return true
end

local function quarryRun()
    if QUARRY_X < 1 or QUARRY_Y < 1 or QUARRY_Z < 1 then
        status.setError("stuck", "quarry", "Invalid quarry dimensions. x/y/z must be >= 1", history.fuelNeededToBase(), 0)
        return
    end

    history.useMain("quarry")
    status.setStatus("running", "quarry", "Starting quarry x=" .. QUARRY_X .. " y=" .. QUARRY_Y .. " z=" .. QUARRY_Z, history.fuelNeededToBase(), 1)

    print("Starting fuel:", turtle.getFuelLevel())

    for layer = 1, QUARRY_Z do
        if not mineLayer(layer) then
            break
        end

        if not serviceAtBase(false) then
            status.setError("stuck", "servicing", "Failed servicing after layer " .. layer, history.fuelNeededToBase(), layer)
            return
        end
    end

    status.setStatus("idle", "quarry", "Quarry run complete", history.fuelNeededToBase(), QUARRY_Z)
end

quarryRun()
