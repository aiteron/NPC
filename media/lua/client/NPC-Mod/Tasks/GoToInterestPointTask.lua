GoToInterestPointTask = {}
GoToInterestPointTask.__index = GoToInterestPointTask

function GoToInterestPointTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "GoToInterestPoint"
	o.complete = false

    local newRoomID = NPC_InterestPointMap:getNearestNewRoom(o.character:getX(), o.character:getY(), o.character:getModData().NPC.visitedRooms)
    o.goalX = NPC_InterestPointMap.Rooms[newRoomID].x
    o.goalY = NPC_InterestPointMap.Rooms[newRoomID].y
    o.roomID = newRoomID

    print(o.goalX, "  ", o.goalY)

	return o
end


function GoToInterestPointTask:isComplete()
	return self.complete
end

function GoToInterestPointTask:isValid()
    return self.character
end

function GoToInterestPointTask:stop()

end

function GoToInterestPointTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if self.mainPlayer:getVehicle() == nil and self.character:getVehicle() == nil then
        if self.character:getModData().NPC.lastWalkActionFailed then
            self.character:getModData().NPC.lastWalkActionFailed = false
            self.character:getModData().NPC.visitedRooms[self.roomID] = true
            return false
        end

        if actionCount == 0 then
            self.goalSquare = getCell():getGridSquare(self.goalX, self.goalY, 0)            

            if self.goalSquare == nil then
                local dToPlayer = NPCUtils.getDistanceBetweenXYZ(self.goalX, self.goalY, self.mainPlayer:getX(), self.mainPlayer:getY())
                local coeff = 70.0 / dToPlayer 

                local deltaX = self.goalX - self.character:getX()
                local deltaY = self.goalY - self.character:getY()

                self.goalX = deltaX * coeff + self.character:getX()
                self.goalY = deltaY * coeff + self.character:getY()
                self.goalSquare = getCell():getGridSquare(self.goalX, self.goalY, 0)            
            end
            
		    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, false))
        end

        if self.character:getSquare() == self.goalSquare then
            self.complete = true
            return true
        end
    end
    return true
end

function GoToInterestPointTask:isRun()
    return NPCUtils.getDistanceBetween(self.character:getSquare(), self.mainPlayer:getSquare()) > 5 or self.mainPlayer:getVehicle() ~= nil
end