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

    o.saidDropLoot = false
    o.timer = 0

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
        self.character:facePosition(self.robbedCharacter:getX(), self.robbedCharacter:getY())
        if self.saidDropLoot == false then
            self.character:getModData().NPC:Say("Drop Items on floor!", NPCColor.White)
            self.saidDropLoot = true

            ISTimedActionQueue.clear(self.robbedCharacter:getModData().NPC.character)
	        self.robbedCharacter:getModData().NPC.robDropLoot = true
            
            self.timer = 120
            self.character:getModData().NPC.reputationSystem.reputationList[self.robbedCharacter:getModData().NPC.UUID] = 0
        end
        if self.saidDropLoot and self.timer <= 0  then
            self.character:getModData().NPC:Say("Now flee!", NPCColor.White)

            ISTimedActionQueue.clear(self.robbedCharacter:getModData().NPC.character)
	        self.robbedCharacter:getModData().NPC.robFlee = true

            self.startLoot = true
            self.square = self.robbedCharacter:getSquare()
        end
        if self.startLoot then
            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.square, false))
            local items = self:getItemsOnFloorNearSquare(self.square)
            for _, item in ipairs(items) do
                if item ~= nil and item:getWorldItem() then
                    ISTimedActionQueue.add(ISGrabItemAction:new(self.character, item:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, item:getWorldItem())))
                end
            end
        end
        if self.timer > 0 then
            self.timer = self.timer - 1
        end
    end

    if #ISTimedActionQueue.getTimedActionQueue(self.character).queue == 0 and self.startLoot then
        self.character:getModData().NPC.AI.command = nil
        self.character:getModData().NPC.AI.TaskArgs.robbedPerson = nil
        self.complete = true
    end

    return true
end


function RobbingTask:getItemsOnFloorNearSquare(square)
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    
    local resultItems = {}
    for i=-1, 1 do
        for j=-1, 1 do
            local sq = getCell():getGridSquare(x+i, y+j, z)        
            local items = NPCUtils:getItemsOnFloor(function(item)
                return true
            end, sq)

            for _, item in ipairs(items) do
                table.insert(resultItems, item)
            end
        end
    end

    return resultItems
end