NPCUtils = {}

function NPCUtils.getDistanceBetween(z1,z2)
	if(z1 == nil) or (z2 == nil) then return -1 end
	
	local z1x = z1:getX();
	local z1y = z1:getY();
	local z2x = z2:getX();
	local z2y = z2:getY();

	return IsoUtils.DistanceTo(z1x, z1y, z2x, z2y)
end

function NPCUtils.getDistanceBetweenXYZ(x1,y1,x2,y2)
	return IsoUtils.DistanceTo(x1, y1, x2, y2)
end

function NPCUtils.getSaveDir()
    return Core.getMyDocumentFolder()..getFileSeparator().."Saves"..getFileSeparator().. getWorld():getGameMode() .. getFileSeparator() .. getWorld():getWorld().. getFileSeparator();
end

function NPCUtils.AdjacentFreeTileFinder_Find(gridSquare)
    local choices = {}
    local choicescount = 1;
    -- first try straight lines (N/S/E/W)
    local a = gridSquare:getAdjacentSquare(IsoDirections.W)
    local b = gridSquare:getAdjacentSquare(IsoDirections.E)
    local c = gridSquare:getAdjacentSquare(IsoDirections.N)
    local d = gridSquare:getAdjacentSquare(IsoDirections.S)

    -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then table.insert(choices, a); choicescount = choicescount + 1; end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then table.insert(choices, b); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then table.insert(choices, d); choicescount = choicescount + 1; end

    a = gridSquare:getAdjacentSquare(IsoDirections.NW)
	b = gridSquare:getAdjacentSquare(IsoDirections.NE)
	c = gridSquare:getAdjacentSquare(IsoDirections.SW)
	d = gridSquare:getAdjacentSquare(IsoDirections.SE)

	if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then  table.insert(choices, a); choicescount = choicescount + 1; end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then  table.insert(choices, b); choicescount = choicescount + 1;end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); choicescount = choicescount + 1;end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then  table.insert(choices, d); choicescount = choicescount + 1; end

    -- if we have multiple choices, pick the one closest to the player
    if choicescount > 1 then
        return choices[ZombRand(#choices-1)+1]
    else
        return choices[1]
    end
end

function NPCUtils.getNearestFreeSquare(obj, gridSquare, isInRoom)
    local choices = {}
    -- first try straight lines (N/S/E/W)
    local a = gridSquare:getAdjacentSquare(IsoDirections.W)
    local b = gridSquare:getAdjacentSquare(IsoDirections.E)
    local c = gridSquare:getAdjacentSquare(IsoDirections.N)
    local d = gridSquare:getAdjacentSquare(IsoDirections.S)

    -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then table.insert(choices, a); end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then table.insert(choices, b); end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then table.insert(choices, d); end

    a = gridSquare:getAdjacentSquare(IsoDirections.NW)
	b = gridSquare:getAdjacentSquare(IsoDirections.NE)
	c = gridSquare:getAdjacentSquare(IsoDirections.SW)
	d = gridSquare:getAdjacentSquare(IsoDirections.SE)

	if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then  table.insert(choices, a); end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then  table.insert(choices, b);end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then  table.insert(choices, d); end

    local dist = 99999
    local sq = nil
    for i, square in ipairs(choices) do
        local d = NPCUtils.getDistanceBetween(obj, square)
        if d < dist and (not isInRoom or NPCUtils.isInRoom(square)) then
            sq = square
            dist = d
        end
    end
    return sq
end

function NPCUtils.FindNearestDoor(square, isUnlocked)
    local dist = 10000
    local door = nil

    for y=square:getY() - 4, square:getY() + 4 do
		for x=square:getX() - 4, square:getX() + 4 do
			local square2 = getCell():getGridSquare(x, y, square:getZ())
			if square2 ~= nil then
				local tmpDoor = NPCUtils:getDoor(square2)
                local tmpDist = NPCUtils.getDistanceBetween(square, square2)
                if tmpDoor and tmpDist < dist and (not isUnlocked or not tmpDoor:isLocked()) then
                    dist = tmpDist
                    door = tmpDoor
                end
			end
		end
	end
    return door
end

function NPCUtils.FindNearestWindow(square)
    local dist = 10000
    local obj = nil

    for y=square:getY() - 10, square:getY() + 10 do
		for x=square:getX() - 10, square:getX() + 10 do
			local square2 = getCell():getGridSquare(x, y, square:getZ())
			if square2 ~= nil then
				local tmpWindow = square2:getWindow()
                local tmpDist = NPCUtils.getDistanceBetween(square, square2)

                if tmpWindow and tmpDist < dist then
                    dist = tmpDist
                    obj = tmpWindow
                end
			end
		end
	end
    return obj
end

function NPCUtils.getNPCFromSquare(square)
    for i, char in ipairs(NPCManager.characters) do
        if square == char.character:getSquare() then
            return char
        end
    end
    return nil
end

function NPCUtils.hasAnotherNPCOnSquare(square, char1)
    for i, char in ipairs(NPCManager.characters) do
        if square == char.character:getSquare() and char ~= char1 then
            return true
        end
    end
    return false
end

function NPCUtils.isInRoom(square)
    return square:getRoom() ~= nil or square:isInARoom()
end

function NPCUtils.getNearestSquare(obj, sq1, sq2)
    if NPCUtils.getDistanceBetween(sq1, obj) < NPCUtils.getDistanceBetween(sq2, obj) then
        return sq1
    else
        return sq2
    end
end

NPCUtils.FoodsToExlude = {"Bleach", "Cigarettes", "Antibiotics", "Teabag2" ,"Salt", "Pepper", "Cockroach", "Cricket", "DeadMouse", "DeadRat", "Worm", "GrassHopper"}
NPCUtils.FindAndReturnBestFood = function(container) 
	if not container then return nil end
	local foodTable = {}
    local items = container:getItems()
	
    for i=1, items:size() do
        local item = items:get(i-1)
        if item:getContainer() ~= nil and item:isEquipped() then
            local items2 = item:getContainer():getItems()
            for j=1, items2:size() do
                local item2 = items2:get(j-1)
                if(item2 ~= nil) and (item2:getCategory() == "Food") and not (item2:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item2:getType())) then
                    foodTable[item2] = 0
                end
            end
        else
            if(item ~= nil) and (item:getCategory() == "Food") and not (item:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType())) then
                foodTable[item] = 0
            end
        end
    end

    for item, score in pairs(foodTable) do
        local FoodType = item:getFoodType()
        if (FoodType == "NoExplicit") or (FoodType == nil) or (tostring(FoodType) == "nil") then
            score = score + 0
        elseif (FoodType == "Fruits") or (FoodType == "Vegetables") then 
            score = score + 2
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end
        elseif ((FoodType == "Egg") or (FoodType == "Meat")) or item:isIsCookable() then
            if(item:isCooked()) then score = score + 2 end
            if(item:isBurnt()) then score = score - 1 end
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end					
        end
        foodTable[item] = score
    end

    local tmpScore = -1
    local tmpItem = nil
    for item, score in pairs(foodTable) do
        if score > tmpScore then
            tmpItem = item
            tmpScore = score
        end
    end

	return tmpItem
end

NPCUtils.FindAndReturnBestFoodFromTable = function(items)
    local foodTable = {}

    for _, item in ipairs(items) do
        if(item ~= nil) and (item:getCategory() == "Food") and not (item:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType())) then
            foodTable[item] = 0
        end
    end

    for item, score in pairs(foodTable) do
        local FoodType = item:getFoodType()
        if (FoodType == "NoExplicit") or (FoodType == nil) or (tostring(FoodType) == "nil") then
            score = score + 0
        elseif (FoodType == "Fruits") or (FoodType == "Vegetables") then 
            score = score + 2
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end
        elseif ((FoodType == "Egg") or (FoodType == "Meat")) or item:isIsCookable() then
            if(item:isCooked()) then score = score + 2 end
            if(item:isBurnt()) then score = score - 1 end
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end					
        end
        foodTable[item] = score
    end

    local tmpScore = -1
    local resFood = nil
    for item, score in pairs(foodTable) do
        if score > tmpScore then
            resFood = item
            tmpScore = score
        end
    end

    return resFood
end

function NPCUtils.tableHasValue(table, val)
    for i, v in ipairs(table) do
        if val == v then
            return true
        end
    end
    return false
end

function NPCUtils:getDoor(sq)
    if sq:getDoor(false) then return sq:getDoor(false) end
    return sq:getDoor(true)
end

function NPCUtils:inSafeZone(sq)
    return not NPCManager.zombiesDangerByXYZ["X" .. tostring(sq:getX()) .. "Y" .. tostring(sq:getY()) .. "Z" .. tostring(sq:getZ())]
end

function NPCUtils:evalIsFood(item)
    if item == nil then return false end

    if item:getCategory() == "Food" and not (item:getPoisonPower() > 1) and not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType()) then
        return true
    end

    if item:isWaterSource() then return true end

    return false
end

function NPCUtils:evalIsWeapon(item)
    if item == nil then return false end

    if item:getCategory() == "Weapon" and instanceof(item, "HandWeapon") and item:isAimedFirearm() or item:getCategory() == "WeaponPart" then
        return true
    end

    if item:getMaxAmmo() > 0 then return true end
    if item:getDisplayCategory() == "Ammo" then return true end

    return false
end

function NPCUtils:evalIsClothing(item)
    return item ~= nil and item:getCategory() == "Clothing"
end

local evalMedsList = {"Needle", "Thread", "SutureNeedle", "Splint", "SutureNeedleHolder", "PlantainCataplasm", "WildGarlicCataplasm", "ComfreyCataplasm", "Disinfectant", "Splint", "Splint", "Splint", }
function NPCUtils:evalIsMeds(item)
    if item == nil then return false end

    if ISInventoryPaneContextMenu.startWith(item:getType(), "Pills") then return true end   -- All Pills

    if item:isCanBandage() then return true end

    if NPCUtils.tableHasValue(evalMedsList, item:getType()) then return true end

    return false
end

function NPCUtils:evalIsBags(item)
    return item ~= nil and item:getCategory() == "Container"
end

function NPCUtils:evalIsMelee(item)
    if item == nil then return false end

    if item:getCategory() == "Weapon" and instanceof(item, "HandWeapon") and not item:isAimedFirearm() then return true end

    return false
end

function NPCUtils:evalIsLiterature(item)
    return item ~= nil and item:getCategory() == "Literature"
end

function NPCUtils.UUID()
    local seed={'e','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb={}
    for i=1,32 do

        table.insert(tb,seed[ZombRand(16)+1])
    end
    local sid=table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(sid,1,8),
        string.sub(sid,9,12),
        string.sub(sid,13,16),
        string.sub(sid,17,20),
        string.sub(sid,21,32)
    )
end

function NPCUtils:getBestMeleWeapon(container)
	local score = 0
	local bestItem = nil
	for j=1, container:getItems():size() do
		local item = container:getItems():get(j-1)
		if instanceof(item, "HandWeapon") and not item:isAimedFirearm() and not (item:getSwingAnim() == "Throw") and NPCUtils:getWeaponScore(item, container) > score then
			score = item:getScore(nil)
			bestItem = item
		end
	end

	return bestItem
end

function NPCUtils:getBestRangedWeapon(container)
	local score = 0
	local bestItem = nil
	for j=1, container:getItems():size() do
		local item = container:getItems():get(j-1)
		if instanceof(item, "HandWeapon") and item:isAimedFirearm() and NPCUtils:getWeaponScore(item, container) > score then
			score = item:getScore(nil)
			bestItem = item
		end
	end
	return bestItem
end

function NPCUtils:getWeaponScore(weapon, container)
	local score = 0
	score = score + weapon:getCondition()
	if weapon:getCondition() <= 0 then
		score = -99999
	end
	
	if weapon:isAimedFirearm() then
		if(weapon:getMagazineType()) then
			if weapon:isContainsClip() then
				local ammoCount = container:getItemCountRecurse(weapon:getAmmoType())
				score = score + 10 + weapon:getCurrentAmmoCount() + ammoCount
			else
				local ammoCount = container:getItemCountRecurse(weapon:getAmmoType())
				local magazine = container:getFirstTypeRecurse(weapon:getMagazineType())
				if magazine == nil then
					score = -99999
				else
					score = score + 10 + magazine:getCurrentAmmoCount() + ammoCount
				end
			end
		else
			local ammoInGun = weapon:getCurrentAmmoCount()
			local ammoCount = container:getItemCountRecurse(weapon:getAmmoType())

			if ammoInGun == 0 and ammoCount == 0 then
				score = -99999
			else
				score = score + ammoInGun + ammoCount
			end
		end
	else
		score = score + weapon:getMaxDamage()*10
	end

	return score
end

function NPCUtils:checkUsefulStuffAtFloor(x, y, z)
    local score = 0
    local resultItems = {}
    for i=-1, 1 do
        for j=-1, 1 do
            local sq = getCell():getGridSquare(x+i, y+j, z)        
            local items = NPCUtils:getItemsOnFloor(function(item)
                if NPCUtils:evalIsFood(item) then
                    return true
                end          
            
                if NPCUtils:evalIsWeapon(item) then
                    return true
                end  
            
                if NPCUtils:evalIsClothing(item) then
                    return true
                end  
            
                if NPCUtils:evalIsMeds(item) then
                    return true
                end  
            
                if NPCUtils:evalIsBags(item) then
                    return true
                end  
            
                if NPCUtils:evalIsMelee(item) then
                    return true
                end  
            
                if NPCUtils:evalIsLiterature(item) then
                    return true
                end  
            
                return false
            end, sq)

            for _, item in ipairs(items) do
                if NPCUtils:evalIsFood(item) then
                    score = score + 10
                end

                if NPCUtils:evalIsWeapon(item) then
                    score = score + 25
                end  
            
                if NPCUtils:evalIsClothing(item) then
                    score = score + 5
                end  
            
                if NPCUtils:evalIsMeds(item) then
                    score = score + 15
                end  
            
                if NPCUtils:evalIsBags(item) then
                    score = score + 50
                end  
            
                if NPCUtils:evalIsMelee(item) then
                    score = score + 25
                end  
            
                if NPCUtils:evalIsLiterature(item) then
                    score = score + 0
                end  

                table.insert(resultItems, item)
            end
        end
    end

    return score, resultItems
end



function NPCUtils:getItemsOnFloor(evalFunc, sq)
	local resultItems = {}

	local wObjs = sq:getWorldObjects()
	for j=0, wObjs:size()-1 do
		local item = wObjs:get(j):getItem()
		if item then
			if evalFunc(item) then
				table.insert(resultItems, item)
			else
				if item:getCategory() == "Container" then
					local cItems = item:getInventory():getAllEvalRecurse(evalFunc)
					for i = 1, cItems:size() do
						local cItem = cItems:get(i-1)
						table.insert(resultItems, cItem)
					end
				end
			end
		end
	end	
	return resultItems
end

function table.contains(tbl, e)
    for _, v in pairs(tbl) do
        if v == e then
            return true
        end
    end

    return false
end

function table.copy(tbl)
    local t = {}

    for _, v in pairs(tbl) do
        table.insert(t, v)
    end

    return t
end

function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end