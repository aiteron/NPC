SmokeTask = {}
SmokeTask.__index = SmokeTask

function SmokeTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Smoke"
	o.complete = false

    character:getModData().NPC.AI.idleCommand = "SMOKE"

    o.isStarted = false

	return o
end


function SmokeTask:isComplete()
	return self.complete
end

function SmokeTask:stop()
end

function SmokeTask:isValid()
    return self.character
end

function SmokeTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 and self.isStarted == false then
        if self.character:getInventory():getFirstTypeRecurse("Cigarettes") == nil then
            self.character:getInventory():AddItem("Base.Cigarettes")    
        end

        if self.character:getInventory():getFirstTypeRecurse("Lighter") == nil then
            self.character:getInventory():AddItem("Base.Lighter")
        end

        ISTimedActionQueue.add(ISEatFoodAction:new(self.character, self.character:getInventory():getFirstTypeRecurse("Cigarettes"), 1));
        self.isStarted = true
        return true
    end

    if actionCount == 0 and self.isStarted then
        self.complete = true
        self.character:getModData().NPC.AI.idleCommand = nil
    end

    return true
end