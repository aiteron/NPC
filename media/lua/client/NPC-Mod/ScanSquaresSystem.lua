ScanSquaresSystem = {}
ScanSquaresSystem.squares = {}
ScanSquaresSystem.nearbyItems = {}
ScanSquaresSystem.nearbyItems.clearWaterSources = {}
ScanSquaresSystem.nearbyItems.tainedWaterSources = {}
ScanSquaresSystem.nearbyItems.containers = {}
ScanSquaresSystem.nearbyItems.itemSquares = {}
ScanSquaresSystem.nearbyItems.deadBodies = {}
ScanSquaresSystem.timer = 0


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
end

Events.LoadGridsquare.Add(ScanSquaresSystem.loadGridSquare)


function ScanSquaresSystem.onTickUpdate()
    if ScanSquaresSystem.timer <= 0 then
        ScanSquaresSystem.timer = 600
        ScanSquaresSystem.nearbyItems.clearWaterSources = {}
        ScanSquaresSystem.nearbyItems.tainedWaterSources = {}
        ScanSquaresSystem.nearbyItems.containers = {}
        ScanSquaresSystem.nearbyItems.itemSquares = {}
        ScanSquaresSystem.nearbyItems.deadBodies = {}

        local cell = getCell()
        for xyz, sqData in pairs(ScanSquaresSystem.squares) do
            local square = cell:getGridSquare(sqData.x, sqData.y, sqData.z)
            if square == nil then
               ScanSquaresSystem.squares[xyz] = nil
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

                if not isUsefulSquare then
                    ScanSquaresSystem.squares[xyz] = nil
                end
            end
        end
    else
        ScanSquaresSystem.timer = ScanSquaresSystem.timer - 1
    end
end

Events.OnTick.Add(ScanSquaresSystem.onTickUpdate)