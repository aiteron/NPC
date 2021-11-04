WashTask = {}
WashTask.__index = WashTask

function WashTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Wash"
	o.complete = false

	return o
end


function WashTask:isComplete()
	return self.complete
end

function WashTask:stop()

end

function WashTask:isValid()
    return self.character
end

function WashTask:getInfWater()
    local dist = 10
    local resWaterS = nil

    for i, water in ipairs(ScanSquaresSystem.nearbyItems.clearWaterSources) do
        local d = NPCUtils.getDistanceBetween(water, self.character)
        if d < dist and water:getWaterAmount() > 5000 then
            dist = d
            resWaterS = water
        end        
    end

    for i, water in ipairs(ScanSquaresSystem.nearbyItems.tainedWaterSources) do
        local d = NPCUtils.getDistanceBetween(water, self.character)
        if d < dist and water:getWaterAmount() > 5000 then
            dist = d
            resWaterS = water
        end        
    end
    
    return resWaterS
end

function WashTask:getTainedWater()
    local dist = 10
    local resWaterS = nil

    for i, water in ipairs(ScanSquaresSystem.nearbyItems.tainedWaterSources) do
        local d = NPCUtils.getDistanceBetween(water, self.character)
        if d < dist then
            dist = d
            resWaterS = water
        end        
    end
    
    return resWaterS
end

function WashTask:getClearWater()
    local dist = 10
    local resWaterS = nil

    for i, water in ipairs(ScanSquaresSystem.nearbyItems.tainedWaterSources) do
        local d = NPCUtils.getDistanceBetween(water, self.character)
        if d < dist then
            dist = d
            resWaterS = water
        end        
    end
    
    return resWaterS
end

function WashTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 and not self.isDone then
        -- nearest water source with infinite/tained/clear water source in radius 10
        local waterSource = self:getInfWater()
        if waterSource == nil then
            waterSource = self:getTainedWater()
        end
        if waterSource == nil then
            waterSource = self:getClearWater()
        end

        if waterSource == nil then
            self.character:getModData()["NPC"].AI.command = ""
            self.character:getModData()["NPC"]:Say("No water for wash nearby...", NPCColor.White)
            
            self.complete = true
        else
            if NPCUtils.getDistanceBetween(self.character, waterSource:getSquare()) > 1.5 then
                local sq = NPCUtils.getNearestFreeSquare(self.character, waterSource:getSquare(), NPCUtils.isInRoom(waterSource:getSquare()))
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, sq, false))
            end

            local waterRemaining = waterSource:getWaterAmount()
            local soapList = {}
            local barList = self.character:getInventory():getItemsFromType("Soap2", true)
            for i=0, barList:size() - 1 do
                local item = barList:get(i)
                table.insert(soapList, item)
            end
            
            local bottleList = self.character:getInventory():getItemsFromType("CleaningLiquid2", true)
            for i=0, bottleList:size() - 1 do
                local item = bottleList:get(i)
                table.insert(soapList, item)
            end

            if self.character:getModData()["NPC"].AI.washArg == nil then
                self.character:getModData()["NPC"].AI.command = ""
                self.character:getModData()["NPC"]:Say("Not enough water", NPCColor.White)
                self.complete = true
                return
            elseif self.character:getModData()["NPC"].AI.washArg == "Character" then
                if waterRemaining < 1 then
                    self.character:getModData()["NPC"].AI.washArg = nil
                    return
                end
                ISTimedActionQueue.add(ISWashYourself:new(self.character, waterSource, soapList));
                self.isDone = true
            else
                local soapRemaining = ISWashClothing.GetSoapRemaining(soapList)
		        local waterRemaining = waterSource:getWaterAmount()

                for i, item in ipairs(self.character:getModData()["NPC"].AI.washArg) do
                    local bloodAmount = 0
                    local dirtAmount = 0
                    if instanceof(item, "Clothing") then
                        if BloodClothingType.getCoveredParts(item:getBloodClothingType()) then
                            local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
                            for j=0, coveredParts:size()-1 do
                                local thisPart = coveredParts:get(j)
                                bloodAmount = bloodAmount + item:getBlood(thisPart)
                            end
                        end
                        if item:getDirtyness() > 0 then
                            dirtAmount = dirtAmount + item:getDirtyness()
                        end
                    else
                        bloodAmount = bloodAmount + item:getBloodLevel()
                    end

                    if waterRemaining > ISWashClothing.GetRequiredWater(item) then
                        waterRemaining = waterRemaining - ISWashClothing.GetRequiredWater(item)

                        local noSoap = true
                        if soapRemaining > ISWashClothing.GetRequiredSoap(item) then
                            soapRemaining = soapRemaining - ISWashClothing.GetRequiredSoap(item)
                            noSoap = false
                        end
                        ISTimedActionQueue.add(ISWashClothing:new(self.character, waterSource, soapList, item, bloodAmount, dirtAmount, noSoap))
                    else
                        self.character:getModData()["NPC"].AI.washArg = nil
                        return
                    end
                end
                self.character:getModData()["NPC"].AI.washArg = nil
                self.isDone = true
            end
        end
    end

    if #ISTimedActionQueue.getTimedActionQueue(self.character).queue == 0 and self.isDone then
        self.complete = true
        self.character:getModData()["NPC"].AI.command = ""
    end

    return true
end