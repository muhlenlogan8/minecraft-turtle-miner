local History = {}

History.mainReverse = {}
History.mainForward = {}
History.branchMoves = {}
History.active = "main"

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
end

function History.useBranch()
    History.branchMoves = {}
    History.active = "branch"
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
    for i = #History.mainReverse, 1, -1 do
        run(History.mainReverse[i])
    end

    if not keepPath then
        History.mainReverse = {}
        History.mainForward = {}
    end
end

function History.goBackToWork()
    for i = 1, #History.mainForward do
        run(History.mainForward[i])
    end
end

function History.returnToStrip()
    for i = #History.branchMoves, 1, -1 do

        run(History.branchMoves[i])
    end

    History.branchMoves = {}
    History.active = "main"
end

function History.clearBranch()
    History.branchMoves = {}
    History.active = "main"
end

function History.fuelNeededToBase()
    return fuelNeeded(History.mainReverse)
end

function History.fuelNeededForAnotherGo()
    return fuelNeeded(History.mainForward) * 2
end

return History

