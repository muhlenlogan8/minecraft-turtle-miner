local status = require("status")

local Vein = {}

local function isOre(block)
    if not block then return false end

    return string.find(block.name, "_ore") ~= nil or
        block.name == "minecraft:ancient_debris"

end

local function tryMineForward()
    local found, block = turtle.inspect()

    if found and isOre(block) then
        turtle.dig()
        turtle.forward()

        Vein.mineConnectedOre()

        turtle.back()
    end
end

local function tryMineUp()
    local found, block = turtle.inspectUp()

    if found and isOre(block) then
        turtle.digUp()
        turtle.up()

        Vein.mineConnectedOre()

        turtle.down()

    end
end

local function tryMineDown()
    local found, block = turtle.inspectDown()

    if found and isOre(block) then
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

