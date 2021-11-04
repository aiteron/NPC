SurrenderTask = {}
SurrenderTask.__index = SurrenderTask

function SurrenderTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Surrender"
	o.complete = false

	return o
end


function SurrenderTask:isComplete()
	return self.complete
end

function SurrenderTask:stop()
end

function SurrenderTask:isValid()
    return self.character and NPCUtils.getDistanceBetween(self.character, self.mainPlayer) < 6 and self.mainPlayer:isAiming() and self.mainPlayer:getPrimaryHandItem() and self.mainPlayer:getPrimaryHandItem():isAimedFirearm() and (self.mainPlayer:getDotWithForwardDirection(self.character:getX(), self.character:getY()) + 0.1) >= 1
end

function SurrenderTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        ISTimedActionQueue.add(SurrenderAction:new(self.character, self.mainPlayer))
    end

    return true
end