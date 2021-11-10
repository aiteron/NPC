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

    if o.character:getModData().NPC.isRobbed then
        character:getModData().NPC:Say("Okay, i am surrend!", NPCColor.White)
    end

    o.robbedBy = o.character:getModData().NPC.robbedBy

	return o
end


function SurrenderTask:isComplete()
	return self.complete
end

function SurrenderTask:stop()
end

function SurrenderTask:isValid()
    return self.character and self.robbedBy
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

    if NPCUtils.getDistanceBetween(self.robbedBy, self.character) > 15 then
        self.character:getModData().NPC.isRobbed = false
        self.character:getModData().NPC.robbedBy = nil
        self.complete = true
    end

    return true
end