require "NPC-Mod/NPCGroupManager"

FollowTask = {}
FollowTask.__index = FollowTask

function FollowTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    if character:getModData().NPC.AI:getType() == "AutonomousAI" then
        local leaderValue = NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(character:getModData().NPC.UUID))]
        if leaderValue ~= nil then
            o.followCharacter = leaderValue.npc.character
        end
    else
        o.followCharacter = getPlayer()
    end
    

    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Follow"
	o.complete = false

    character:setSneaking(o.mainPlayer:isSneaking())

	return o
end


function FollowTask:isComplete()
	return self.complete
end

function FollowTask:isValid()
    return self.character ~= nil and self.followCharacter ~= nil
end

function FollowTask:stop()

end

function FollowTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if self.followCharacter:getVehicle() == nil and self.character:getVehicle() == nil then
        -- If can't go - stay on place
        if self.character:getModData().NPC.lastWalkActionForceStopped then
            self.waitPos = self.followCharacter:getSquare()
            self.character:getModData().NPC.lastWalkActionForceStopped = false
        end

        if self.waitPos ~= nil then
            if self.waitPos == self.followCharacter:getSquare() then 
                return true
            else
                self.waitPos = nil
            end
        end
        --

        if actionCount == 0 and NPCUtils.getDistanceBetween(self.followCharacter, self.character) > 3 then
            self.goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(self.followCharacter:getSquare()) 
		    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, self:isRun()))
        end

        if NPCUtils.getDistanceBetween(self.followCharacter, self.character) <= 3 then
            ISTimedActionQueue.clear(self.character)
            self.goalSquare = self.character:getSquare()
        end

        if self.character:getSquare() == self.goalSquare then
            self.complete = true
            return true
        end
    elseif self.followCharacter:getVehicle() ~= nil and self.character:getVehicle() == nil then

        if self.enterSeat and self.followCharacter:getVehicle():getCharacter(self.enterSeat) then
            local char = self.followCharacter:getVehicle():getCharacter(self.enterSeat)
            local seat = self:getFirstBackUnoccupiedSeat()
            if seat ~= nil then
                ISTimedActionQueue.add(ISSwitchVehicleSeat:new(char, seat))
            end
        end

        if actionCount == 0 then
            self.goalSquare = self:getVehicleEnterSquare()
            if self.character:getSquare() ~= NPCManager.vehicleSeatChooseSquares[self.character] then
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, self:isRun()))    
            end
            ISTimedActionQueue.add(ISEnterVehicle:new(self.character, self.followCharacter:getVehicle(), self.enterSeat))
        end
    elseif self.followCharacter:getVehicle() == nil and self.character:getVehicle() ~= nil then

        if actionCount == 0 then
            ISTimedActionQueue.add(ISExitVehicle:new(self.character))
        end
    end
    return true
end

function FollowTask:isRun()
    return NPCUtils.getDistanceBetween(self.character:getSquare(), self.followCharacter:getSquare()) > 5 or self.followCharacter:getVehicle() ~= nil
end

function FollowTask:getEnterSeat()
    local car = self.followCharacter:getVehicle()
    local numOfSeats = car:getScript():getPassengerCount()

    local firstDoor = nil
    local bestDoor = nil

    for seat = numOfSeats - 1, 1, -1 do
        local tmpDoor = car:getPassengerDoor(seat)
        if tmpDoor ~= nil then
            if firstDoor == nil then
                firstDoor = seat
            end
            if not car:isSeatOccupied(seat) and not self:checkChoosenSeats(seat) then
               bestDoor = seat 
            end            
        end
    end

    if bestDoor == nil then return firstDoor end
    return bestDoor
end

function FollowTask:checkChoosenSeats(seat)
    for _, seat2 in pairs(NPCManager.vehicleSeatChoose) do
        if seat == seat2 then return true end
    end
    return false
end

function FollowTask:getFirstBackUnoccupiedSeat()
    local car = self.followCharacter:getVehicle()
    local numOfSeats = car:getScript():getPassengerCount()

    for seat = numOfSeats - 1, 1, -1 do
        if not car:isSeatOccupied(seat) and not self:checkChoosenSeats(seat) then
            return seat
        end
    end
end

function FollowTask:getVehicleEnterSquare()
    local car = self.followCharacter:getVehicle()

    self.enterSeat = self:getEnterSeat()
    NPCManager.vehicleSeatChoose[self.character] = self.enterSeat
    local door = car:getPassengerDoor(self.enterSeat)

    local pos = car:getAreaCenter(door:getArea())
    local sq = getCell():getGridSquare(pos:getX(), pos:getY(), self.character:getZ())
    NPCManager.vehicleSeatChooseSquares[self.character] = sq

    return sq
end