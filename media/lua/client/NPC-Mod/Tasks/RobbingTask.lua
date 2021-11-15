RobbingTask = {}
RobbingTask.__index = RobbingTask

function RobbingTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Robbing"
	o.complete = false

    o.robbedCharacter = o.character:getModData().NPC.AI.TaskArgs.robbedPerson

    o.character:getModData().NPC:Say("Stay here! I am robbing you!", NPCColor.White)

    local robbedNPC = o.robbedCharacter:getModData().NPC
    local groupID = NPCGroupManager:getGroupID(robbedNPC.UUID)
    if groupID ~= nil then
        for _, id in ipairs(NPCGroupManager.Data.groups[groupID].npcIDs) do
            local teammate = NPCManager:getCharacter(id)    
            if teammate ~= nil then
                teammate.reputationSystem:updateNPCRep(-500)
            end
        end
    end

    robbedNPC.isRobbed = true
    robbedNPC.robbedBy = o.character

	return o
end


function RobbingTask:isComplete()
	return self.complete
end

function RobbingTask:stop()
end

function RobbingTask:isValid()
    return self.character
end

function RobbingTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        self.isStarted = true
    end

    if actionCount == 0 then
        self.complete = true
    end

    return true
end