StepBackTask = {}
StepBackTask.__index = StepBackTask

function StepBackTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "StepBack"
	o.complete = false

    if o.character:getSquare():isInARoom() then
        o.goalSquare = o:getSafestSquareOutside()
    else
        o.goalSquare = character:getModData()["NPC"]:getSafestSquare(1)
    end
    o.currentWalkAction = nil

    o.walkToWindowTimer = 0
    o.lastSquare = nil

    o.stayBugTimer = 0

    if character:getModData()["NPC"].AI:isCommandStayHere() then
        character:getModData()["NPC"].AI.command = ""
    end

	return o
end


function StepBackTask:isComplete()
	return self.complete
end

function StepBackTask:stop()

end

function StepBackTask:isValid()
    return self.character and self.goalSquare and self.goalSquare:hasFloor(false) and not self.character:getModData()["NPC"].isZombieAtFront and not self.character:getVehicle()
end

function StepBackTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
	    self.currentWalkAction = NPCWalkToAction:new(self.character, self.goalSquare, true)
		ISTimedActionQueue.add(self.currentWalkAction)
	end

    if self.character:getSquare() == self.goalSquare or self.character:getModData()["NPC"].nearestEnemy == nil then
        self.complete = true
    end

    return true
end

function StepBackTask:getSafestSquareOutside()
    if self.character:getModData()["NPC"].AI.fleeFindOutsideSqTimer > 0 then
        return self.character:getModData()["NPC"].fleeFindOutsideSq
    end
    self.character:getModData()["NPC"].AI.fleeFindOutsideSqTimer = 120

    local currentSquare = self.character:getSquare()
    local x = currentSquare:getX()
    local y = currentSquare:getY()
    local z = currentSquare:getZ()

    local distToDoor = 99999
    local extDoor = nil

    local distToFreeOutside = 99999
    local sqFreeOutside = nil

    for i=-30, 30 do
        for j=-30, 30 do
            local sq = getSquare(x+i, y+j, 0)
            if sq == nil then
            else
                local door = sq:getDoor(false)

                if sqFreeOutside == nil and not sq:isInARoom() and sq:isFree(false) then
                    sqFreeOutside = sq
                    distToFreeOutside = NPCUtils.getDistanceBetween(sq, currentSquare)
                end
    
                if not sq:isInARoom() and sq:isFree(false) and NPCUtils.getDistanceBetween(sq, currentSquare) < distToFreeOutside then
                    sqFreeOutside = sq
                    distToFreeOutside = NPCUtils.getDistanceBetween(sq, currentSquare)
                end
    
                if door and door:isExteriorDoor(self.character) then
                    local sq1 = door:getSquare()
                    local sq2 = door:getOppositeSquare()
                    if sq1:isInARoom() then
                        if NPCUtils.getDistanceBetween(sq2, currentSquare) < distToDoor then
                            extDoor = sq2
                            distToDoor = NPCUtils.getDistanceBetween(sq2, currentSquare)    
                        end
                    else
                        if NPCUtils.getDistanceBetween(sq1, currentSquare) < distToDoor then
                            extDoor = sq1
                            distToDoor = NPCUtils.getDistanceBetween(sq1, currentSquare)    
                        end
                    end
                end
            end
        end
    end

    if extDoor ~= nil then
        self.character:getModData()["NPC"].fleeFindOutsideSq = extDoor
        return extDoor
    end

    if sqFreeOutside == nil then
        local sq = self.character:getModData()["NPC"]:getSafestSquare(1)
        self.character:getModData()["NPC"].fleeFindOutsideSq = sq
        return sq
    end

    self.character:getModData()["NPC"].fleeFindOutsideSq = sqFreeOutside
    return sqFreeOutside
end