SitTask = {}
SitTask.__index = SitTask

function SitTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Sit"
	o.complete = false

    character:getModData().NPC.AI.idleCommand = "SIT"

    o.isStarted = false

	return o
end


function SitTask:isComplete()
	return self.complete
end

function SitTask:stop()
end

function SitTask:isValid()
    return self.character
end

function SitTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 and self.isStarted == false then
        if self.character:getActionStateName() ~= "sitonground" then
            self.character:reportEvent("EventSitOnGround")
            self.character:getModData().NPC:Say("I'll sit for a while", NPCColor.White)
        end

        self.isStarted = true
        return true
    end

    if actionCount == 0 and self.isStarted then
        self.complete = true
        self.character:getModData().NPC.AI.idleCommand = nil
    end

    return true
end