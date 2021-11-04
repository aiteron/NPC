EatDrinkTask = {}
EatDrinkTask.__index = EatDrinkTask

function EatDrinkTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "EatDrink"
	o.complete = false

	return o
end


function EatDrinkTask:isComplete()
	return self.complete
end

function EatDrinkTask:stop()

end

function EatDrinkTask:isValid()
    return self.character
end

function EatDrinkTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue
    local isFailFindWater = false
    local isFailFindFood = false

    if actionCount == 0 and self.character:getMoodles():getMoodleLevel(MoodleType.Hungry) > 1 and self.character:getModData()["NPC"].AI.EatTaskTimer <= 0 then
        --print("A")

        local food = NPCUtils.FindAndReturnBestFood(self.character:getInventory())
        if food then
            --print("B")
            ISInventoryPaneContextMenu.transferIfNeeded(self.character, food)
            ISTimedActionQueue.add(ISEatDrinkAction:new(self.character, food, 1))
        else
            --print("C")
            local foods, foodSquares = self.character:getModData()["NPC"]:getItemsSquareInNearbyItems(function(item)
                if item:getCategory() == "Food" then
                    return true
                end
                return false
            end)
            local tmpFoods = {}
            for i, f in ipairs(foods) do
                if self.character:getModData()["NPC"]:isOkDist(foodSquares[f]) then
                    table.insert(tmpFoods, f)
                end
            end

            food = NPCUtils.FindAndReturnBestFoodFromTable(tmpFoods)
            local foodSq = foodSquares[food]
            if food then
                --print("D")
                if food:getWorldItem() then
                    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, foodSq, false))
                    ISTimedActionQueue.add(ISGrabItemAction:new(self.character, food:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, food:getWorldItem())))
                else
                    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, NPCUtils.getNearestFreeSquare(self.character, foodSq, NPCUtils.isInRoom(foodSq)), false))
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, food, food:getContainer(), self.character:getInventory()))
                end                    
                ISTimedActionQueue.add(WaitAction:new(self.character, 20))
            else
                --print("E")
                self.character:getModData()["NPC"]:Say("I'm hungry", NPCColor.White)
                isFailFindFood = true
                self.character:getModData()["NPC"].AI.EatTaskTimer = 1000

                local isGetFood = false
                for i, char in ipairs(NPCManager.characters) do
                    if isGetFood == false and char ~= self.character and NPCUtils.getDistanceBetween(char.character, self.character:getModData()["NPC"].character) < 12 then
                        food = char:getFreeFood()
                        --print("F")

                        if food ~= nil then
                            --print("G")
                            self.character:getModData()["NPC"].AI.EatTaskTimer = 10
                            isGetFood = true
                            char:Say("Take this food", NPCColor.White)
                            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, char.character:getSquare(), false))
                            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, food, food:getContainer(), self.character:getInventory()))                    
                        end          
                    end
                end
            end
        end
    end

    actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue
    if actionCount == 0 and self.character:getMoodles():getMoodleLevel(MoodleType.Thirst) > 1 and self.character:getModData()["NPC"].AI.DrinkTaskTimer <= 0 then
        local water, count = self:getWaterFromBags(self.character:getInventory())
        if water then
            ISInventoryPaneContextMenu.transferIfNeeded(self.character, water)
        else
            local waterSource = self:getNearestWaterSource()

            if waterSource and waterSource:getSquare() and self.character:getModData()["NPC"]:isOkDist(waterSource) then
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, NPCUtils.getNearestFreeSquare(self.character, waterSource:getSquare(), NPCUtils.isInRoom(waterSource:getSquare())), false))
                local waterAvailable = waterSource:getWaterAmount()
                local thirst = self.character:getStats():getThirst()
                local waterNeeded = math.floor((thirst + 0.005) / 0.1)
                local waterConsumed = math.min(waterNeeded, waterAvailable)
                ISTimedActionQueue.add(ISTakeWaterAction:new(self.character, nil, waterConsumed, waterSource, (waterConsumed * 10) + 15, nil));

                local emptyWaterContainer = self:getEmptyWaterContainer()

                if emptyWaterContainer then
                    ISInventoryPaneContextMenu.transferIfNeeded(self.character, emptyWaterContainer)
                    self:fillEmptyItemWithWater(emptyWaterContainer, waterSource)
                end
            else
                local waterItem, waterItemSq = self.character:getModData()["NPC"]:getNearestItemSquareInNearbyItems(function(item)
                    if item:isWaterSource() and item:getType() ~= "Bleach" then
                        return true
                    end
                    return false
                end)

                if waterItem and self.character:getModData()["NPC"]:isOkDist(waterItemSq) then
                    if waterItem:getWorldItem() then
                        ISTimedActionQueue.add(NPCWalkToAction:new(self.character, waterItemSq, false))
                        ISTimedActionQueue.add(ISGrabItemAction:new(self.character, waterItem:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, waterItem:getWorldItem())))
                    else
                        ISTimedActionQueue.add(NPCWalkToAction:new(self.character, waterItemSq, false))
                        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, waterItem, waterItem:getContainer(), self.character:getInventory()))
                    end              
                    ISTimedActionQueue.add(WaitAction:new(self.character, 20))
                else
                    self.character:getModData()["NPC"]:Say("I'm thirsty", NPCColor.White)
                    isFailFindWater = true
                    self.character:getModData()["NPC"].AI.DrinkTaskTimer = 1000

                    local isGetWater = false
                    for i, char in ipairs(NPCManager.characters) do
                        if isGetWater == false and char ~= self.character and NPCUtils.getDistanceBetween(char.character, self.character:getModData()["NPC"].character) < 12 then
                            water, count = self:getWaterFromBags(char.character:getInventory())

                            if water ~= nil and count > 1 then
                                self.character:getModData()["NPC"].AI.DrinkTaskTimer = 10
                                isGetWater = true
                                char:Say("Take this water", NPCColor.White)
                                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, char.character:getSquare(), false))
                                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, water, water:getContainer(), self.character:getInventory()))                    
                            end          
                        end
                    end
                end
            end
        end
    end

    if (self.character:getMoodles():getMoodleLevel(MoodleType.Hungry) <= 1 or isFailFindFood) and (self.character:getMoodles():getMoodleLevel(MoodleType.Thirst) <= 1 or isFailFindWater) then
        self.complete = true
    end

    return true
end

function EatDrinkTask:getWaterFromBags(container)
    local waterItem = nil
    local waterItemCount = 0

	for j=1, container:getItems():size() do
		local item = container:getItems():get(j-1)
        if item:isEquipped() and item:getCategory() == "Container" then
            local con = item:getInventory()
            local items = con:getItems()
            for i=1, items:size() do
                local item2 = items:get(i-1)
                if item2:isWaterSource() and item2:getType() ~= "Bleach" then
                    waterItem = item2
                    waterItemCount = waterItemCount + 1
                end
            end
        else
            if item:isWaterSource() and item:getType() ~= "Bleach" then
                waterItem = item
                waterItemCount = waterItemCount + 1
            end
        end
    end

    return waterItem, waterItemCount
end

function EatDrinkTask:getEmptyWaterContainer()
    local pourInto = self.character:getInventory():getFirstEvalRecurse(function(item)
		-- our item can store water, but doesn't have water right now
		if item:canStoreWater() and not item:isWaterSource() and not item:isBroken() then
			return true
		end
		return false
	end)
    return pourInto
end

function EatDrinkTask:fillEmptyItemWithWater(item, waterObject)
    local waterAvailable = waterObject:getWaterAmount()
    local newItemType = item:getReplaceOnUseOn();
    newItemType = string.sub(newItemType,13);
    newItemType = item:getModule() .. "." .. newItemType;
    local newItem = InventoryItemFactory.CreateItem(newItemType,0);
    newItem:setCondition(item:getCondition());
    newItem:setFavorite(item:isFavorite());
    local returnToContainer = item:getContainer():isInCharacterInventory(self.character) and item:getContainer()
    ISWorldObjectContextMenu.transferIfNeeded(self.character, item)
    local destCapacity = 1 / newItem:getUseDelta()
    local waterConsumed = math.min(math.floor(destCapacity + 0.001), waterAvailable)
    ISTimedActionQueue.add(ISTakeWaterAction:new(self.character, newItem, waterConsumed, waterObject, waterConsumed * 10, item));
    if returnToContainer and (returnToContainer ~= self.character:getInventory()) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item, self.character:getInventory(), returnToContainer))
    end
end

function EatDrinkTask:getNearestWaterSource()
    local dist = 999
    local sourceRes = nil

    for i, source in ipairs(ScanSquaresSystem.nearbyItems.clearWaterSources) do
        local d = NPCUtils.getDistanceBetween(source:getSquare(), self.character)
        if d < dist and source:getSquare() ~= nil then
            dist = d
            sourceRes = source
        end
    end
    return sourceRes
end