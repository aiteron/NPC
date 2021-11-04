AttachItemTask = {}
AttachItemTask.__index = AttachItemTask

function AttachItemTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "AttachItem"
	o.complete = false

    o.arg = o.character:getModData()["NPC"].AI.TaskArgs

    o.isDone = false

	return o
end


function AttachItemTask:isComplete()
	return self.complete
end

function AttachItemTask:stop()

end

function AttachItemTask:isValid()
    return self.character
end

function AttachItemTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 and not self.isDone then
        if self.arg.isAttach then
            self.character:getModData()["NPC"].hotbar:attachItem(self.arg.item, self.arg.slot, self.arg.slotIndex, self.arg.slotDef, self.arg.doAnim)
            self.isDone = true
        else
            self.character:getModData()["NPC"].hotbar:removeItem(self.arg.item, self.arg.doAnim)
            self.isDone = true
        end
    end

    if #ISTimedActionQueue.getTimedActionQueue(self.character).queue == 0 and self.isDone then
        self.complete = true
        self.character:getModData().NPC.AI.command = ""
    end

    return true
end