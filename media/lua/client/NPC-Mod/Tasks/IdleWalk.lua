require "NPC-Mod/NPCGroupManager"

IdleWalkTask = {}
IdleWalkTask.__index = IdleWalkTask

function IdleWalkTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "IdleWalk"
	o.complete = false

    character:getModData().NPC.AI.idleCommand = "IDLE_WALK"

    o.isStarted = false

	return o
end


function IdleWalkTask:isComplete()
	return self.complete
end

function IdleWalkTask:stop()
end

function IdleWalkTask:isValid()
    return self.character
end

function IdleWalkTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 and self.isStarted == false then
        if self.character:getModData().NPC.AI.command == "FOLLOW" then
            if self.character:getModData().NPC.AI:getType() == "PlayerGroupAI" then
                self.goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(getPlayer():getSquare()) 
		        ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, false))
            else
                self.goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(character:getModData().NPC.UUID))].npc.character:getSquare()) 
		        ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, false))
            end
        else
            self.goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(self.character:getSquare()) 
            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, false))
        end
        self.isStarted = true
    end

    if actionCount == 0 and self.isStarted then
        self.complete = true
        self.character:getModData().NPC.AI.idleCommand = nil
    end

    return true
end