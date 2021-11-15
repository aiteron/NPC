ScanSquaresSystem = {}
ScanSquaresSystem.squares = {}
ScanSquaresSystem.nearbyItems = {}
ScanSquaresSystem.nearbyItems.clearWaterSources = {}
ScanSquaresSystem.nearbyItems.tainedWaterSources = {}
ScanSquaresSystem.nearbyItems.containers = {}
ScanSquaresSystem.nearbyItems.itemSquares = {}
ScanSquaresSystem.nearbyItems.deadBodies = {}
ScanSquaresSystem.timer = 0

ScanSquaresSystem.objSquares = {}
ScanSquaresSystem.doors = {}
ScanSquaresSystem.windows = {}

function ScanSquaresSystem.loadGridSquare(square)
    local sqx = square:getX()
    local sqy = square:getY()
    local sqz = square:getZ()

    local isUsefulSquare = false

    local items = square:getObjects()
    for j=0, items:size()-1 do
        local item = items:get(j)
        if item:hasWater() then
            if not item:isTaintedWater() then
                table.insert(ScanSquaresSystem.nearbyItems.clearWaterSources, item)
            else
                table.insert(ScanSquaresSystem.nearbyItems.tainedWaterSources, item)
            end
            isUsefulSquare = true
        end

        for containerIndex = 1, item:getContainerCount() do
            local container = item:getContainerByIndex(containerIndex-1)
            table.insert(ScanSquaresSystem.nearbyItems.containers, container)
            isUsefulSquare = true
        end
    end	

    items = square:getWorldObjects()
    for j=0, items:size()-1 do
        if(items:get(j):getItem()) then
            table.insert(ScanSquaresSystem.nearbyItems.itemSquares, square)
            isUsefulSquare = true
            break
        end
    end	

    items = square:getDeadBodys()
    for j=0, items:size()-1 do
        if(items:get(j):getContainer():getItems():size() > 0) then
            table.insert(ScanSquaresSystem.nearbyItems.deadBodies, items:get(j))
            isUsefulSquare = true
            break
        end
    end	

    if isUsefulSquare then
        ScanSquaresSystem.squares["X=" .. sqx .. "Y=" .. sqy .. "Z=" .. sqz] = {x = sqx, y = sqy, z = sqz}
    end

    ----
    isUsefulSquare = false
    if square:getWindow() ~= nil then
        table.insert(ScanSquaresSystem.windows, square:getWindow())
        isUsefulSquare = true
    end

    local door = NPCUtils:getDoor(square)
    if door then
        table.insert(ScanSquaresSystem.doors, door)
        isUsefulSquare = true
    end

    if isUsefulSquare then
        ScanSquaresSystem.objSquares["X=" .. sqx .. "Y=" .. sqy .. "Z=" .. sqz] = {x = sqx, y = sqy, z = sqz}
    end
end
Events.LoadGridsquare.Add(ScanSquaresSystem.loadGridSquare)

ScanSquaresSystem.tempSquareBuffer = nil
ScanSquaresSystem.isUpdateSquares = false
ScanSquaresSystem.tempObjSquareBuffer = nil
ScanSquaresSystem.isUpdateObjSquares = false
function ScanSquaresSystem.onTickUpdate()
    if ScanSquaresSystem.timer <= 0 then
        ScanSquaresSystem.timer = 1200
        ScanSquaresSystem.nearbyItems.clearWaterSources = {}
        ScanSquaresSystem.nearbyItems.tainedWaterSources = {}
        ScanSquaresSystem.nearbyItems.containers = {}
        ScanSquaresSystem.nearbyItems.itemSquares = {}
        ScanSquaresSystem.nearbyItems.deadBodies = {}
        ScanSquaresSystem.doors = {}
        ScanSquaresSystem.windows = {}

        ScanSquaresSystem.tempSquareBuffer = ScanSquaresSystem.squares
        ScanSquaresSystem.squares = {}
        ScanSquaresSystem.isUpdateSquares = true
        ScanSquaresSystem.tempObjSquareBuffer = ScanSquaresSystem.objSquares
        ScanSquaresSystem.objSquares = {}
        ScanSquaresSystem.isUpdateObjSquares = true

        NPCPrint("ScanSquaresSystem", "Clear scan sectors started")
    else
        ScanSquaresSystem.timer = ScanSquaresSystem.timer - 1
    end

    local cell = getCell()
    if ScanSquaresSystem.isUpdateSquares then
        local isUpdated = false
        for xyz, sqData in pairs(ScanSquaresSystem.tempSquareBuffer) do
            isUpdated = true
            local square = cell:getGridSquare(sqData.x, sqData.y, sqData.z)
            if square == nil then
                ScanSquaresSystem.tempSquareBuffer[xyz] = nil
            else
                local isUsefulSquare = false

                local items = square:getObjects()
                for j=0, items:size()-1 do
                    local item = items:get(j)
                    if item:hasWater() then
                        if not item:isTaintedWater() then
                            table.insert(ScanSquaresSystem.nearbyItems.clearWaterSources, item)
                        else
                            table.insert(ScanSquaresSystem.nearbyItems.tainedWaterSources, item)
                        end
                        isUsefulSquare = true
                    end

                    for containerIndex = 1, item:getContainerCount() do
                        local container = item:getContainerByIndex(containerIndex-1)
                        table.insert(ScanSquaresSystem.nearbyItems.containers, container)
                        isUsefulSquare = true
                    end
                end	

                items = square:getWorldObjects()
                for j=0, items:size()-1 do
                    if(items:get(j):getItem()) then
                        table.insert(ScanSquaresSystem.nearbyItems.itemSquares, square)
                        isUsefulSquare = true
                        break
                    end
                end	

                items = square:getDeadBodys()
                for j=0, items:size()-1 do
                    if(items:get(j):getContainer():getItems():size() > 0) then
                        table.insert(ScanSquaresSystem.nearbyItems.deadBodies, items:get(j))
                        isUsefulSquare = true
                        break
                    end
                end	

                ScanSquaresSystem.tempSquareBuffer[xyz] = nil
                if isUsefulSquare then
                    ScanSquaresSystem.squares[xyz] = sqData
                end
            end
            return
        end
        if not isUpdated then
            ScanSquaresSystem.tempSquareBuffer = nil
            ScanSquaresSystem.isUpdateSquares = false
            NPCPrint("ScanSquaresSystem", "Cleared scan sectors 1")
        end
    end

    if ScanSquaresSystem.isUpdateObjSquares then
        local isUpdated = false
        for xyz, sqData in pairs(ScanSquaresSystem.tempObjSquareBuffer) do
            local square = cell:getGridSquare(sqData.x, sqData.y, sqData.z)
            if square == nil then
                ScanSquaresSystem.tempObjSquareBuffer[xyz] = nil
            else
                local isUsefulSquare = false
                if square:getWindow() ~= nil then
                    table.insert(ScanSquaresSystem.windows, square:getWindow())
                    isUsefulSquare = true
                end

                local door = NPCUtils:getDoor(square)
                if door then
                    table.insert(ScanSquaresSystem.doors, door)
                    isUsefulSquare = true
                end

                ScanSquaresSystem.tempObjSquareBuffer[xyz] = nil
                if isUsefulSquare then
                    ScanSquaresSystem.objSquares[xyz] = sqData
                end
            end
            return
        end
        if not isUpdated then
            ScanSquaresSystem.tempObjSquareBuffer = nil
            ScanSquaresSystem.isUpdateObjSquares = false
            NPCPrint("ScanSquaresSystem", "Cleared scan sectors 2")
        end
    end    
end

function ScanSquaresSystem.UpdateGridSquare()

end


Events.OnTick.Add(ScanSquaresSystem.onTickUpdate)