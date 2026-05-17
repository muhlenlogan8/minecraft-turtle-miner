local status = require("status")
local history = require("history")

local Vein = {}

local MAX_VEIN_DEPTH = 64

local function isOre(block)
    if not block then return false end

    return string.find(block.name, "_ore") ~= nil or
        block.name == "minecraft:ancient_debris"

end

local function failVein(message)
    status.setError("stuck", "vein_mining", message, history.fuelNeededToBase())
    return false
end

local function mineConnectedOre(depth)
    depth = depth or 0

    if depth >= MAX_VEIN_DEPTH then
        return failVein("Vein depth limit reached")
    end

    status.heartbeat("Mining ore vein")

    local function tryMineForward(nextDepth)
        status.heartbeat("Checking vein ahead")
        local found, block = turtle.inspect()

        if found and isOre(block) then
            status.heartbeat("Mining ore ahead")
            turtle.dig()

            if not history.forward() then
                return failVein("Failed to move into vein: forward")
            end

            if not mineConnectedOre(nextDepth) then
                return false
            end

            if not history.back() then
                return failVein("Failed to backtrack out of vein: forward")
            end
        end

        return true
    end

    local function tryMineUp(nextDepth)
        status.heartbeat("Checking vein above")
        local found, block = turtle.inspectUp()

        if found and isOre(block) then
            status.heartbeat("Mining ore above")
            turtle.digUp()

            if not history.up() then
                return failVein("Failed to move into vein: up")
            end

            if not mineConnectedOre(nextDepth) then
                return false
            end

            if not history.down() then
                return failVein("Failed to backtrack out of vein: up")
            end
        end

        return true
    end

    local function tryMineDown(nextDepth)
        status.heartbeat("Checking vein below")
        local found, block = turtle.inspectDown()

        if found and isOre(block) then
            status.heartbeat("Mining ore below")
            turtle.digDown()

            if not history.down() then
                return failVein("Failed to move into vein: down")
            end

            if not mineConnectedOre(nextDepth) then
                return false
            end

            if not history.up() then
                return failVein("Failed to backtrack out of vein: down")
            end
        end

        return true
    end

    if not tryMineDown(depth + 1) then
        return false
    end

    if not tryMineUp(depth + 1) then
        return false
    end

    if not tryMineForward(depth + 1) then
        return false
    end

    if not history.turnLeft() then
        return failVein("Failed to turn left while mining vein")
    end
    if not tryMineForward(depth + 1) then
        return false
    end
    if not history.turnRight() then
        return failVein("Failed to restore facing after left vein check")
    end

    if not history.turnRight() then
        return failVein("Failed to turn right while mining vein")
    end
    if not tryMineForward(depth + 1) then
        return false
    end

    if not history.turnRight() then
        return failVein("Failed to turn behind while mining vein")
    end
    if not tryMineForward(depth + 1) then
        return false
    end
    if not history.turnLeft() then
        return failVein("Failed to restore facing after behind vein check")
    end
    if not history.turnLeft() then
        return failVein("Failed to restore facing after behind vein check")
    end

    return true
end
function Vein.mineConnectedOre()
    status.heartbeat("Mining Ore Vein")
    return mineConnectedOre(0)

function Vein.mineVein()
    Vein.mineConnectedOre()
    history.useBranch()

    local success = Vein.mineConnectedOre()
    local returned = history.returnToStrip()

    if not returned then
        status.setError("stuck", "returning_branch", "Could not return to strip after vein", history.fuelNeededToBase())
        return false
    end

    return success

return Vein

