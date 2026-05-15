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

local function run(move)
    if move == "forward" then return turtle.forward()
    elseif move == "back" then return turtle.back()
    elseif move == "up" then return turtle.up()
    elseif move == "down" then return turtle.down()
    elseif move == "turnLeft" then turtle.turnLeft(); return true
    elseif move == "turnRight" then turtle.turnRight(); return true
    end
end
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
    return false
end

function History.useMain()
    History.active = "main"
    setCurrentDistance(History.currentDistance)
    Status.setStatus("idle", nil, "Using main path", History.fuelNeededToBase())
end

function History.useBranch()
    History.branchMoves = {}
    History.active = "branch"
    setCurrentDistance(History.currentDistance)
    Status.setStatus("branching", nil, "Started branch", 0)
end

function History.forward() return moveTracked("forward") end
function History.back() return moveTracked("back") end
function History.up() return moveTracked("up") end
function History.down() return moveTracked("down") end
function History.turnLeft() return moveTracked("turnLeft") end
function History.turnRight() return moveTracked("turnRight") end

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
    Status.setStatus("returning", nil, "Returning to base", History.fuelNeededToBase())

    local success = true

    for i = #History.mainReverse, 1, -1 do
        if not run(History.mainReverse[i]) then
            success = false
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
    Status.setStatus("resuming", nil, "Going back to work", History.fuelNeededForAnotherGo())

    local success = true

    for i = 1, #History.mainForward do
        if not run(History.mainForward[i]) then
            success = false
            break
        end
        Status.setStepsFromBase(i)
        setCurrentDistance(History.currentDistance + 1)
        Status.heartbeat("Going back to work")
    end

    return success
end

function History.returnToStrip()
    Status.setStatus("returning_branch", nil, "Returning to strip", 0)

    local success = true

    for i = #History.branchMoves, 1, -1 do
        if not run(History.branchMoves[i]) then
            success = false
            break
        end
        Status.heartbeat("Returning to strip")
    end

    History.branchMoves = {}
    History.active = "main"
    Status.setStepsFromBase(History.fuelNeededToBase())
    setCurrentDistance(History.currentDistance)

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

