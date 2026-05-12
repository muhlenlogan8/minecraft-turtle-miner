local status = require("status")

local Vein = {}

local function isOre(block)
    if not block then return false end

    return string.find(block.name, "_ore") ~= nil or
        block.name == "minecraft:ancient_debris"

end

local function tryMineForward()
    status.heartbeat("Checking vein ahead")
    local found, block = turtle.inspect()

    if found and isOre(block) then
        status.heartbeat("Mining ore ahead")
        turtle.dig()
        turtle.forward()

        Vein.mineConnectedOre()

        turtle.back()
    end
end

local function tryMineUp()
    status.heartbeat("Checking vein above")
    local found, block = turtle.inspectUp()

    if found and isOre(block) then
        status.heartbeat("Mining ore above")
        turtle.digUp()
        turtle.up()

        Vein.mineConnectedOre()

        turtle.down()

    end
end

local function tryMineDown()
    status.heartbeat("Checking vein below")
    local found, block = turtle.inspectDown()

    if found and isOre(block) then
        status.heartbeat("Mining ore below")
        turtle.digDown()
        turtle.down()

        Vein.mineConnectedOre()

        turtle.up()
    end
end

function Vein.mineConnectedOre()
    status.heartbeat("Mining Ore Vein")

    -- Check vertical first
    tryMineDown()
    tryMineUp()

    -- Check front
    tryMineForward()

    -- Check left
    turtle.turnLeft()
    tryMineForward()
    turtle.turnRight()

    -- Check right
    turtle.turnRight()
    tryMineForward()
    --turtle.turnLeft()

    -- Check behind
    --turtle.turnRight()
    turtle.turnRight()
    tryMineForward()
    turtle.turnLeft()
    turtle.turnLeft()
end

function Vein.mineVein()
    Vein.mineConnectedOre()
end

return Vein

