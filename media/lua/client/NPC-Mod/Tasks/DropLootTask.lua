DropLootTask = {}
DropLootTask.__index = DropLootTask

function DropLootTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "DropLoot"
	o.complete = false

    character:getModData().NPC.AI.idleCommand = "IDLE_WALK"

    o.isStarted = false

	return o
end


function DropLootTask:isComplete()
	return self.complete
end

function DropLootTask:stop()
end

function DropLootTask:isValid()
    return self.character
end

function DropLootTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 and self.isStarted == false then
        local types = {"FOOD", "WEAPON", "CLOTHING", "MEDS", "BAGS", "MELEE", "LITERATURE"}
        for i, itemType in ipairs(types) do
            if NPCGroupManager.dropLoot[itemType] ~= nil then
                local foodItems = self:getItems(itemType)
                local x, y, z = self:getRandomCoordsFromSector(itemType)
                local sq = getCell():getGridSquare(x, y, z)

                if foodItems:size() ~= 0 then
                    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, NPCUtils.AdjacentFreeTileFinder_Find(sq), false))
                    for i=0, foodItems:size()-1 do
                        local item = foodItems:get(i)
                        local container = self:getRandomContainer(sq)

                        if container == nil then
                            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item, item:getContainer(), ISInventoryPage.floorContainer[1]))    
                        else
                            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item, item:getContainer(), container))    
                        end
                    end    
                end
            end
        end
        self.isStarted = true
    end

    if #ISTimedActionQueue.getTimedActionQueue(self.character).queue == 0 and self.isStarted then
        self.complete = true
        self.character:getModData().NPC.AI.command = nil
    end

    return true
end

function DropLootTask:getItems(itemType)
    local items = {}
    if itemType == "FOOD" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsFood(item)
        end)
    end

    if itemType == "WEAPON" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsWeapon(item)
        end)
    end
    
    if itemType == "CLOTHING" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsClothing(item)
        end)
    end
    
    if itemType == "MEDS" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsMeds(item)
        end)
    end
    
    if itemType == "BAGS" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsBags(item)
        end)
    end
    
    if itemType == "MELEE" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsMelee(item)
        end)
    end
    
    if itemType == "LITERATURE" then
        items = self.character:getInventory():getAllEvalRecurse(function(item)  
            return NPCUtils:evalIsLiterature(item)
        end)
    end 
   
    return items
end

function DropLootTask:getRandomCoordsFromSector(name)
    local x = ZombRand(NPCGroupManager.dropLoot[name].x1, NPCGroupManager.dropLoot[name].x2+1)
    local y = ZombRand(NPCGroupManager.dropLoot[name].y1, NPCGroupManager.dropLoot[name].y2+1)
    return x, y, NPCGroupManager.dropLoot[name].z
end

function DropLootTask:getRandomContainer(sq)
    local containers = {}

    local items = sq:getObjects()
    for j=0, items:size()-1 do
        local item = items:get(j)
        for containerIndex = 1, item:getContainerCount() do
            local container = item:getContainerByIndex(containerIndex-1)
            table.insert(containers, container)
        end
    end
    if #containers == 0 then
        return nil
    else
        return containers[ZombRand(1, #containers+1)]
    end
end