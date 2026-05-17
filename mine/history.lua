local Status = require("status")

local History = {}

History.mainReverse = {}
History.mainForward = {}
History.branchMoves = {}
History.active = "main"
History.currentDistance = 0

local function setCurrentDistance(distance)
    History.currentDistance = math.max(0, tonumber(distance) or 0)
    Status.setActualDistanceFromBase(History.currentDistance)
end

local reverseOf = {
    forward = "back",
    back = "forward",
    up = "down",
    down = "up",
    turnLeft = "turnRight",
    turnRight = "turnLeft"
}

local function isFuelMove(move)
    return move == "forward" or move == "back" or move == "up" or move == "down"
end

local safeForward
local safeBack
local safeUp
local safeDown

local function run(move)
    if move == "forward" then return safeForward()
    elseif move == "back" then return safeBack()
    elseif move == "up" then return safeUp()
    elseif move == "down" then return safeDown()
    elseif move == "turnLeft" then turtle.turnLeft(); return true
    elseif move == "turnRight" then turtle.turnRight(); return true
    end
end

local function reportStuck(mode, message)
    if mode == "branch" then
        mode = "vein_mining"
    end

    Status.setError("stuck", mode or History.active, message, History.fuelNeededToBase())
end

safeForward = function()
    for _ = 1, 5 do
        if turtle.forward() then
            return true
        end

        turtle.dig()
        turtle.attack()
        sleep(0.2)
    end

    return false
end

safeBack = function()
    for _ = 1, 5 do
        if turtle.back() then
            return true
        end

        turtle.turnLeft()
        turtle.turnLeft()
        turtle.dig()
        turtle.attack()
        turtle.turnLeft()
        turtle.turnLeft()
        sleep(0.2)
    end

    return false
end

safeUp = function()
    for _ = 1, 5 do
        if turtle.up() then
            return true
        end

        turtle.digUp()
        turtle.attackUp()
        sleep(0.2)
    end

    return false
end

safeDown = function()
    for _ = 1, 5 do
        if turtle.down() then
            return true
        end

        turtle.digDown()
        turtle.attackDown()
        sleep(0.2)
    end

    return false
end

History.safeForward = safeForward
History.safeBack = safeBack
History.safeUp = safeUp
History.safeDown = safeDown

local function save(move)
    local reverseMove = reverseOf[move]

    if History.active == "main" then
        if isFuelMove(move) then
            table.insert(History.mainReverse, reverseMove)
            table.insert(History.mainForward, move)
            Status.setStepsFromBase(History.fuelNeededToBase())
            setCurrentDistance(History.currentDistance + 1)
        end
    else
        table.insert(History.branchMoves, reverseMove)
    end
end

local function moveTracked(move)
    if run(move) then
        save(move)
        return true
    end

    reportStuck(History.active, "Failed move: " .. move)
    return false
end

function History.useMain()
    History.active = "main"
    setCurrentDistance(History.currentDistance)
    Status.setStatus("idle", "main", "Using main path", History.fuelNeededToBase())
end

function History.useBranch()
    History.branchMoves = {}
    History.active = "branch"
    setCurrentDistance(History.currentDistance)
    Status.setStatus("running", "vein_mining", "Started branch", History.fuelNeededToBase())
end

function History.forward()
    return moveTracked("forward")
end

function History.back()
    return moveTracked("back")
end

function History.up()
    return moveTracked("up")
end

function History.down()
    return moveTracked("down")
end

function History.turnLeft()
    return moveTracked("turnLeft")
end

function History.turnRight()
    return moveTracked("turnRight")
end

local function fuelNeeded(moves)
    local fuel = 0

    for _, move in ipairs(moves) do
        if move == "forward" or move == "back" or move == "up" or move == "down" then

            fuel = fuel + 1
        end
    end
    return fuel
end

function History.returnToBase(keepPath)
    Status.setStatus("returning", "returning", "Returning to base", History.fuelNeededToBase())

    local success = true
    local totalMoves = #History.mainReverse

    for i = totalMoves, 1, -1 do
        local move = History.mainReverse[i]
        if not run(move) then
            success = false
            Status.setError(
                "stuck",
                "returning",
                "Failed returning to base on move " .. i .. "/" .. totalMoves .. ": " .. tostring(move),
                History.fuelNeededToBase()
            )
            break
        end
        Status.setStepsFromBase(i - 1)
        setCurrentDistance(History.currentDistance - 1)
        Status.heartbeat("Returning to base")
    end

    if success then
        setCurrentDistance(0)
        Status.setStepsFromBase(0)
    end

    if success and not keepPath then
        History.mainReverse = {}
        History.mainForward = {}
    end

    return success
end

function History.goBackToWork()
    Status.setStatus("resuming", "resuming", "Going back to work", History.fuelNeededForAnotherGo())

    local success = true

    for i = 1, #History.mainForward do
        local move = History.mainForward[i]
        if not run(move) then
            success = false
            Status.setError(
                "stuck",
                "resuming",
                "Failed going back to work on move " .. i .. "/" .. #History.mainForward,
                History.fuelNeededForAnotherGo()
            )
            break
        end
        Status.setStepsFromBase(i)
        setCurrentDistance(History.currentDistance + 1)
        Status.heartbeat("Going back to work")
    end

    return success
end

function History.returnToStrip()
    Status.setStatus("returning_branch", "returning_branch", "Returning to strip", 0)

    local success = true

    for i = #History.branchMoves, 1, -1 do
        local move = History.branchMoves[i]
        if not run(move) then
            success = false
            Status.setError(
                "stuck",
                "returning_branch",
                "Failed returning from vein",
                History.fuelNeededToBase()
            )
            break
        end
        Status.heartbeat("Returning to strip")
    end

    if success then
        History.branchMoves = {}
        History.active = "main"
        Status.setStepsFromBase(History.fuelNeededToBase())
        setCurrentDistance(History.currentDistance)
    end

    return success
end

function History.clearBranch()
    History.branchMoves = {}
    History.active = "main"
    Status.setStepsFromBase(History.fuelNeededToBase())
    setCurrentDistance(History.currentDistance)
end

function History.fuelNeededToBase()
    return fuelNeeded(History.mainReverse)
end

function History.fuelNeededForAnotherGo()
    return fuelNeeded(History.mainForward) * 2
end

function History.actualDistanceFromBase()
    return History.currentDistance
end

return History

