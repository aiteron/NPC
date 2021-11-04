StayHereTask = {}
StayHereTask.__index = StayHereTask

function StayHereTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "StayHere"
	o.complete = false

    o.stayLocation = character:getModData()["NPC"].AI.staySquare

	return o
end


function StayHereTask:isComplete()
	return self.complete
end

function StayHereTask:isValid()
    return self.character
end

function StayHereTask:stop()

end

function StayHereTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.stayLocation, self:isRun()))
    end

    if self.character:getSquare() == self.stayLocation then
        self.complete = true
        return true
    end

    return true
end

function StayHereTask:isRun()
    return NPCUtils.getDistanceBetween(self.character:getSquare(), self.stayLocation) > 5
end