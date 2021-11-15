FindItemsTask = {}
FindItemsTask.__index = FindItemsTask

function FindItemsTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "FindItems"
	o.complete = false

    o.sqPath = {}
    o.character:getModData().NPC.AI.updateItemLocationTimer = 0
    o:updateItemLocation()

	return o
end

function FindItemsTask:updateItemLocation()
    if self.character:getModData().NPC.AI.updateItemLocationTimer <= 0 then
        self.character:getModData().NPC.AI.updateItemLocationTimer = 120
        self.itemSquares, self.squaresCount = self.character:getModData()["NPC"]:getItemsSquareInNearbyItems(function(item)
            if self.character:getModData()["NPC"].AI.findItems.Food and NPCUtils:evalIsFood(item) then
                return true
            end          
        
            if self.character:getModData()["NPC"].AI.findItems.Weapon and NPCUtils:evalIsWeapon(item) then
                return true
            end  
        
            if self.character:getModData()["NPC"].AI.findItems.Clothing and NPCUtils:evalIsClothing(item) then
                return true
            end  
        
            if self.character:getModData()["NPC"].AI.findItems.Meds and NPCUtils:evalIsMeds(item) then
                return true
            end  
        
            if self.character:getModData()["NPC"].AI.findItems.Bags and NPCUtils:evalIsBags(item) then
                return true
            end  
        
            if self.character:getModData()["NPC"].AI.findItems.Melee and NPCUtils:evalIsMelee(item) then
                return true
            end  
        
            if self.character:getModData()["NPC"].AI.findItems.Literature and NPCUtils:evalIsLiterature(item) then
                return true
            end  
        
            return false
        end)
    
        self.sqPath = {}
        table.insert(self.sqPath, self.character:getSquare())
        self.sqPathCount = 1

        if self.character:getModData()["NPC"].AI.TaskArgs.FIND_ITEMS_WHERE == "NEAR" then
           self:clearTooFarSquares(self.itemSquares) 
        end

        while self.squaresCount > 0 do
            local nearestSq = self:findNearestSquare(self.itemSquares, self.sqPath[self.sqPathCount])
            if nearestSq == nil then
                self.squaresCount = 0
                break
            end
            if self.character:getModData().NPC.AI:getType() == "AutonomousAI" then
                if NPCUtils.getDistanceBetween(nearestSq, self.character) < 20 then
                    self.sqPath[self.sqPathCount+1] = nearestSq
                    self.sqPathCount = self.sqPathCount + 1
                    self.itemSquares[nearestSq] = nil
                end
            else
                self.sqPath[self.sqPathCount+1] = nearestSq
                self.sqPathCount = self.sqPathCount + 1
                self.itemSquares[nearestSq] = nil
            end

            self.squaresCount = self.squaresCount - 1
        end
    
        self.nextPoint = 2
    end
end

function FindItemsTask:isComplete()
	return self.complete
end

function FindItemsTask:stop()
end

function FindItemsTask:isValid()
    return self.character ~= nil
end

function FindItemsTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if self.character:getModData().NPC.AI.updateItemLocationTimer > 0 then
        self.character:getModData().NPC.AI.updateItemLocationTimer = self.character:getModData().NPC.AI.updateItemLocationTimer - 1
    end

    if self.character:getModData().NPC.lastWalkActionForceStopped then
        self.nextPoint = self.nextPoint + 1
        self.character:getModData().NPC.lastWalkActionForceStopped = false
    end

    if actionCount == 0 then
        if self.sqPath[self.nextPoint] == nil then
            if self.character:getModData()["NPC"].AI.TaskArgs.FIND_ITEMS_WHERE == "NEAR" then
                local dd = NPCUtils.getDistanceBetween(self.character, self.mainPlayer)
                if dd >= 4 then 
                    local goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(self.mainPlayer:getSquare()) 
		            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, goalSquare, dd > 6))
                end
                self:updateItemLocation()
                return true
            end
            if self.character:getModData().NPC.AI:getType() == "AutonomousAI" then
                self.complete = true
                self.character:getModData().NPC.AI.currentInterestPoint = nil
                print("DUCK")
            end
            return false
        end

        if self.sqPath[self.nextPoint] ~= nil then
            local items = self.character:getModData().NPC:getItemsInSquare(function(item)
                if self.character:getModData()["NPC"].AI.findItems.Food and NPCUtils:evalIsFood(item) then
                    return true
                end          
            
                if self.character:getModData()["NPC"].AI.findItems.Weapon and NPCUtils:evalIsWeapon(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Clothing and NPCUtils:evalIsClothing(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Meds and NPCUtils:evalIsMeds(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Bags and NPCUtils:evalIsBags(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Melee and NPCUtils:evalIsMelee(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Literature and NPCUtils:evalIsLiterature(item) then
                    return true
                end  
            
                return false
            end, 
            self.sqPath[self.nextPoint])

            for i=1, #items do
                if items[i]:getWorldItem() then
                    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.sqPath[self.nextPoint], false))
                    ISTimedActionQueue.add(ISGrabItemAction:new(self.character, items[i]:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, items[i]:getWorldItem())))
                else
                    local sq = NPCUtils.getNearestFreeSquare(self.character, self.sqPath[self.nextPoint], NPCUtils.isInRoom(self.sqPath[self.nextPoint] ))
                    if sq ~= nil then
                        if NPCUtils.getDistanceBetween(sq, self.character) > 1 then
                            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, sq, false))            
                        end
                    end
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, items[i], items[i]:getContainer(), self.character:getInventory()))
                end
            end

            self.nextPoint = self.nextPoint + 1
        end
    end

    return true
end

function FindItemsTask:findNearestSquare(squares, lastSq)
    local dist = 999
    local resultSquare = nil

    for sq, _ in pairs(squares) do
        local d = NPCUtils.getDistanceBetween(sq, lastSq)
        if sq:getZ() ~= lastSq:getZ() then
            d = d + 30
        end
        if d < dist then
            dist = d
            resultSquare = sq    
        end
    end

    return resultSquare
end

function FindItemsTask:clearTooFarSquares(squares)
    for sq, _ in pairs(squares) do
        if NPCUtils.getDistanceBetween(sq, self.mainPlayer) > 4 or self.mainPlayer:getZ() ~= sq:getZ() then
            squares[sq] = nil
            self.squaresCount = self.squaresCount - 1
        end
    end
end