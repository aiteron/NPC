NPC = {}
NPC.__index = NPC

function NPC:new(square, preset)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	-- Create character
    o.character = o:createIsoPlayer(square, preset)
	o.character:getModData()["NPC"] = o
	
	o.AI = PlayerGroupAI:new(o.character)
	o.UUID = NPCUtils.UUID()
	o.userName = NPCUsername:new(o.character)
	o.sayDialog = NPCSayDialog:new(o.character)
	o.hotbar = NPCHotBar:new(o.character)
	o.reputationSystem = ReputationSystem:new(o.character, preset)
	
	-- Add npc to NPCManager
	table.insert(NPCManager.characters, o)
	NPCManager.characterMap[o.UUID] = { isLoaded = true, isSaved = false, npc = o , x = o.character:getX(), y = o.character:getY(), z = o.character:getZ() }
	
	NPCPrint("NPC", "Create new NPC", o.character:getDescriptor():getSurname(), o.UUID)
	---
	o.saveTimer = 1800
	o.walkToDelay = 0

	o.visitedRooms = {}

	---
	o.groupCharacteristic = preset.groupCharacteristic
	o.isRaider = preset.isRaider
	if o.isRaider then
		o.userName:setRaiderNickname()
	end
	---
	o.isRobbed = false
	o.robbedBy = nil
	o.robDropLoot = false
	o.robFlee = false

	o:save()

	return o
end

function NPC:createIsoPlayer(square, preset)
	local survivorDesc = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, preset.isFemale)

	-- Skin color
	survivorDesc:getHumanVisual():setSkinTextureIndex(preset.skinColor)	-- int 0-4

	-- Hair
	survivorDesc:getHumanVisual():setHairModel(preset.hair)

	local ic = ImmutableColor.new(preset.hairColor.r, preset.hairColor.g, preset.hairColor.b, 1)
	survivorDesc:getHumanVisual():setHairColor(ic)

	-- Beard
	survivorDesc:getHumanVisual():setBeardModel(preset.beard)
	
	ic = ImmutableColor.new(preset.beardColor.r, preset.beardColor.g, preset.beardColor.b, 1)
	survivorDesc:getHumanVisual():setBeardColor(immutableColor)

	-- Set name
	survivorDesc:setForename(preset.forename)
	survivorDesc:setSurname(preset.surname)

	-- Set profession
	survivorDesc:setProfession(preset.profession)


	if preset.outfit == "RAND" then
		local outfits = getAllOutfits(preset.isFemale)
		local nameOutfit = outfits:get(ZombRand(outfits:size()))
		survivorDesc:dressInNamedOutfit(nameOutfit)
	end


	-- Create isoPlayer
	local Z = 0
	if square:isSolidFloor() then Z = square:getZ() end
	local character = IsoPlayer.new(getWorld():getCell(), survivorDesc, square:getX(), square:getY(), Z)
	
	-- Perks
	for perk, num in pairs(preset.perks) do
		for i=1, num do
			character:LevelPerk(Perks.FromString(perk))
		end
	end

	-- Outfit
	if preset.outfit == "RAND" then
	else
		for _, element in ipairs(preset.outfit) do
			if type(element) == "table" then
				local invItem = instanceItem(element[1])
				if invItem then
					character:getInventory():AddItem(invItem)
					if element[2] == "Both hands" then
						character:setPrimaryHandItem(invItem)
						character:setSecondaryHandItem(invItem)
					elseif element[2] == "Primary" then
						character:setPrimaryHandItem(invItem)
					elseif element[2] == "Secondary" then
						character:setSecondaryHandItem(invItem)
					elseif element[2] == "Color" then
						invItem:setColor(Color.new(element[3].r, element[3].g, element[3].b, 1))
						if invItem:getBodyLocation() ~= "" then
							character:setWornItem(invItem:getBodyLocation(), invItem);
						end
					end
				end
			else
				local clothingItem = instanceItem(element)
				if clothingItem then
					character:getInventory():AddItem(clothingItem)
					if instanceof(clothingItem, "InventoryContainer") and clothingItem:canBeEquipped() ~= "" then
						character:setClothingItem_Back(clothingItem)
					elseif clothingItem:getCategory() == "Clothing" then
						if clothingItem:getBodyLocation() ~= "" then
							character:setWornItem(clothingItem:getBodyLocation(), clothingItem);
						end
					end
				else
					NPCPrint("NPC", "Error in NPC preset", element)
				end 
			end
		end
	end

	-- Items
	for _, element in ipairs(preset.items) do
		if type(element) == "table" then
			local invItems = character:getInventory():getItems()
			for i=1, invItems:size() do
				local tempItem = invItems:get(i-1)
				if instanceof(tempItem, "InventoryContainer") and tempItem:isEquipped() and (tempItem:getModule() .. "." .. tempItem:getType()) == element[1] then
					for j=2, #element do
						local containerItem = instanceItem(element[j])
						tempItem:getInventory():AddItem(containerItem)
					end
				end
			end
		else
			local invItem = instanceItem(element)
			character:getInventory():AddItem(invItem)
		end
	end

	-- Attach items
	for _, attachTable in ipairs(preset.attachments) do
		local invItems = character:getInventory():getItems()
		for i=1, invItems:size() do
			local tempItem = invItems:get(i-1)
			if (tempItem:getModule() .. "." .. tempItem:getType()) == attachTable[1] then
				character:setAttachedItem(attachTable[3], tempItem);
				tempItem:setAttachedSlot(attachTable[2]);
				tempItem:setAttachedSlotType(attachTable[4]);
				tempItem:setAttachedToModel(attachTable[3]);
			end
		end	
	end

	----
	character:setSceneCulled(false)
	character:setNPC(true);

	return character
end

function NPC:save()
	NPCPrint("NPC", "Saving NPC", self.character:getDescriptor():getSurname(), self.UUID)

	local filename = NPCUtils.getSaveDir() .. "NPC"..tostring(self.UUID);
	self.character:getModData().actionContext_isSit = self.character:getActionStateName() == "sitonground"
	
	self.character:getModData().NPCAIType = self.AI:getType()

	local tempTask = nil
	if self.character:getModData()["NPC"].AI.TaskManager.tasks[0] ~= nil then
		self.character:getModData().NPCTaskName = self.character:getModData()["NPC"].AI.TaskManager.tasks[0].task.name
		self.character:getModData().NPCTaskScore = self.character:getModData()["NPC"].AI.TaskManager.tasks[0].score
		tempTask = self.character:getModData()["NPC"].AI.TaskManager.tasks[0]
		self.character:getModData()["NPC"].AI.TaskManager.tasks[0] = nil
	end

	self.character:getModData()["NPC"].AI.TaskManager.tasks[0] = tempTask

	self.character:getModData().defaultRep = self.character:getModData()["NPC"].reputationSystem.defaultReputation
	self.character:getModData().playerRep = self.character:getModData()["NPC"].reputationSystem.playerRep
	self.character:getModData().repList = self.character:getModData()["NPC"].reputationSystem.reputationList

	self.character:save(filename .. "_REVIVE")
	self.character:save(filename);


	self.saveTimer = 1800
end

function NPC:load(UUID, x, y, z, isRevive)
	NPCPrint("NPC", "Load NPC", UUID)

	if not x or not y or not z then
		local p = getPlayer()
		x = p:getX()
		y = p:getY()
		z = p:getZ()
	end


	local survivorDesc = SurvivorFactory.CreateSurvivor();
	local Buddy = IsoPlayer.new(getWorld():getCell(),survivorDesc,x,y,z);
	Buddy:getInventory():emptyIt();
	local filename = NPCUtils.getSaveDir() .. "NPC"..tostring(UUID);
	if isRevive then
		filename = filename .. "_REVIVE"
	end
	Buddy:load(filename);

	Buddy:setX(x)
	Buddy:setY(y)
	Buddy:setZ(z)
	Buddy:setNPC(true);
	Buddy:setBlockMovement(false)
	Buddy:setSceneCulled(false)

	local o = Buddy:getModData()["NPC"]
	setmetatable(o, self)
	self.__index = self

    o.character = Buddy
	o.userName = NPCUsername:new(o.character)
	o.sayDialog = NPCSayDialog:new(o.character)
	o.hotbar = NPCHotBar:new(o.character)

	o.reputationSystem = ReputationSystem:new(o.character, nil)
	o.reputationSystem.defaultReputation = o.character:getModData().defaultRep
	o.reputationSystem.playerRep = o.character:getModData().playerRep
	o.reputationSystem.reputationList = o.character:getModData().repList

	table.insert(NPCManager.characters, o)

	self:loadAI(o)

	if Buddy:getModData().actionContext_isSit then
		Buddy:reportEvent("EventSitOnGround")
	end
	--
	return o
end

function NPC:loadAI(o)
	if o.character:getModData().NPCAIType == "PlayerGroupAI" then
		o.AI = PlayerGroupAI:new(o.character)
	else
		o.AI = AutonomousAI:new(o.character)
	end

	local taskTable = {
		["AttachItem"] = {command = "ATTACH", task = AttachItemTask},
		["Attack"] = {command = "", task = AttackTask},
		["EatDrink"] = {command = "", task = EatDrinkTask},
		["EquipWeapon"] = {command = "", task = EquipWeaponTask},
		["FindItems"] = {command = "FIND_ITEMS", task = FindItemsTask},
		["FirstAid"] = {command = "", task = FirstAidTask},
		["Flee"] = {command = "", task = FleeTask},
		["StepBack"] = {command = "", task = StepBackTask},
		["Follow"] = {command = "FOLLOW", task = FollowTask},
		["ReloadWeapon"] = {command = "", task = ReloadWeaponTask},
		["StayHere"] = {command = "STAY", task = StayHereTask},
		["Surrender"] = {command = "", task = SurrenderTask},
		["Wash"] = {command = "WASH", task = WashTask},
		["Smoke"] = {command = "", task = SmokeTask},
		["GoToInterestPoint"] = {command = "", task = GoToInterestPointTask},
		["Talk"] = {command = "", task = TalkTask}
	}

	if o.character:getModData().NPCTaskName ~= nil then
		NPCPrint("NPC", "Load NPC last AI task", o.character:getModData().NPCTaskName, o.character:getDescriptor():getSurname(), o.UUID)

		if o.character:getModData().NPCTaskName == "Talk" then
			return
		end

		o.AI.command = taskTable[o.character:getModData().NPCTaskName].command
		o.AI.TaskManager:addToTop(taskTable[o.character:getModData().NPCTaskName].task:new(o.character), o.character:getModData().NPCTaskScore)
	end
end

function NPC:update()
	self.AI:update()

	self.userName:update()
	self.sayDialog:update()
	self.hotbar:update()

	self:updateSpecialParams()

	if self.saveTimer > 0 then
		self.saveTimer = self.saveTimer - 1
	else
		self:save()
	end
end

function NPC:updateSpecialParams()
	self.character:getStats():setFatigue(0) -- Set sleep always full
	
	if not NPCConfig.config["NPC_NEED_FOOD"] then
		self.character:getStats():setThirst(0.0)
		self.character:getStats():setHunger(0.0)
	end

	self.character:getStats():setPanic(0);
	self.character:getBodyDamage():setHasACold(false)

	if not NPCConfig.config["NPC_CAN_INFECT"] then
		self.character:getBodyDamage():setInfectionLevel(0)
	end

	if not NPCConfig.config["NPC_NEED_AMMO"] then
		local container = self.character:getInventory()
		for j=1, container:getItems():size() do
			local weapon = container:getItems():get(j-1)
			if instanceof(weapon, "HandWeapon") and weapon:isAimedFirearm() then
				if(weapon:getMagazineType()) then
					if weapon:isContainsClip() then
						local ammoCount = self.character:getInventory():getItemCountRecurse(weapon:getAmmoType()) + weapon:getCurrentAmmoCount()
						if ammoCount < 10 then
							for i=ammoCount, 10 do
								self.character:getInventory():AddItem(weapon:getAmmoType())	
							end
						end
					else
						local ammoCount = self.character:getInventory():getItemCountRecurse(weapon:getAmmoType())
						local magazine = self.character:getInventory():getFirstTypeRecurse(weapon:getMagazineType())
						if magazine == nil then
							self.character:getInventory():AddItem(weapon:getMagazineType())	
						else
							ammoCount = ammoCount + magazine:getCurrentAmmoCount()
						end
						if ammoCount < 10 then
							for i=ammoCount, 10 do
								self.character:getInventory():AddItem(weapon:getAmmoType())	
							end
						end
					end
				else
					local ammoCount = self.character:getInventory():getItemCountRecurse(weapon:getAmmoType()) + weapon:getCurrentAmmoCount()
					if ammoCount < 10 then
						for i=ammoCount, 10 do
							self.character:getInventory():AddItem(weapon:getAmmoType())	
						end
					end
				end
			end
		end
	end
end

function NPC:setAI(ai)
	self.AI = ai
end

function NPC:hitPlayer(wielder, weapon, damage)
	self.AI:hitPlayer(wielder, weapon, damage)
end

function NPC:Say(text, color)
	self.sayDialog:Say(text, color)
end

function NPC:SayNote(text, color)
	self.sayDialog:SayNote(text, color)
end

function NPC:doVision()
	local objects = self.character:getCell():getObjectList()
	self.seeEnemyCount = 0

	if self.nearestEnemy ~= nil and (self.nearestEnemy:isDead() or NPCUtils.getDistanceBetween(self.character, self.nearestEnemy) > 15) then
		self.nearestEnemy = nil
	end

	local nearestDist = 100000
	if self.nearestEnemy ~= nil then
		nearestDist = NPCUtils.getDistanceBetween(self.character, self.nearestEnemy)
	end
	
	self.isNearTooManyZombies = false
	local nearZombiesCount = 0
	self.isZombieAtFront = false
	self.isEnemyAtBack = false

	if(objects ~= nil) then
		for i=0, objects:size()-1 do
			local obj = objects:get(i);
			if obj ~= nil and obj ~= self.character and (instanceof(obj,"IsoZombie") or instanceof(obj,"IsoPlayer")) then
				if not obj:isDead() and obj:getSquare() ~= nil and obj:getSquare():getZ() == self.character:getSquare():getZ() then
					local dist = NPCUtils.getDistanceBetween(self.character, obj)
					if obj:isOnFloor() then dist = dist + 1 end		-- less priority to lay down zombie	

					if self:isEnemy(obj) then
						if self:canSee(obj) and dist < 10 then
							self.seeEnemyCount = self.seeEnemyCount + 1
							
							if dist < nearestDist then
								nearestDist = dist
								self.nearestEnemy = obj
							end
						end

						-- Can hear if near
						if dist <= 2 and dist < nearestDist then
							nearestDist = dist
							self.nearestEnemy = obj

							if not self:canSee(obj) then
								self.isEnemyAtBack = true;
							else
								if dist < 1.5 then
									self.isZombieAtFront = true
								end
							end

						end

						if dist <= 3 then
							nearZombiesCount = nearZombiesCount + 1
						end
					end
				end
			end
		end
	end

	if nearZombiesCount > 2 then
		self.isNearTooManyZombies = true
	end
end

function NPC:canSee(character)
	if instanceof(character,"IsoZombie") then return self.character:CanSee(character) end

	local visionCone = 0.9

	if self.character:CanSee(character) then
		if(character:isSneaking()) then 
			visionCone = visionCone - 0.3 
		end

		return (self.character:getDotWithForwardDirection(character:getX(), character:getY()) + visionCone) >= 1
	end
	return false
end

function NPC:isEnemy(character)
	if instanceof(character,"IsoZombie") then
		return true
	end
	if instanceof(character, "IsoPlayer") then
		if character:getModData().NPC ~= nil then
			if self.reputationSystem.getPlayerRep ~= nil and self.reputationSystem:getNPCRep(character:getModData().NPC) < 0 then
				return true
			end
		else
			if self.reputationSystem.getPlayerRep ~= nil and self.reputationSystem:getPlayerRep() < 0 then
				return true
			end
		end
	end
	return false
end

function NPC:getMinWeaponRange()
	local out = 0.5
	if(self.character:getPrimaryHandItem() ~= nil) then
		if(instanceof(self.character:getPrimaryHandItem(),"HandWeapon")) then
			return self.character:getPrimaryHandItem():getMinRange()
		end
	end
	return out
end

function NPC:getMaxWeaponRange()
	local out = 0.8
	if(self.character:getPrimaryHandItem() ~= nil) then
		if(instanceof(self.character:getPrimaryHandItem(),"HandWeapon")) then
			return self.character:getPrimaryHandItem():getMaxRange()
		end
	end
	return out
end

function NPC:hasInjury()
	local bodyparts = self.character:getBodyDamage():getBodyParts()
	
	for i=0, bodyparts:size()-1 do
		local bp = bodyparts:get(i)
		if(bp:HasInjury()) and (bp:bandaged() == false) then
			return true
		end
	end
	return false
end

function NPC:getSafestSquare(rangeCoeff)
    local currentSquare = self.character:getSquare()
    local x = currentSquare:getX()
    local y = currentSquare:getY()
    local z = currentSquare:getZ()

    local sectors = {}
    sectors["A"] = 0
    sectors["B"] = 0
    sectors["C"] = 0
    sectors["D"] = 0
    sectors["E"] = 0
    sectors["F"] = 0
    sectors["G"] = 0
    sectors["H"] = 0

    local objects = self.character:getCell():getObjectList()
    if(objects ~= nil) then
		for i=0, objects:size()-1 do
			local obj = objects:get(i);
			if obj ~= nil and obj ~= self.character and (instanceof(obj,"IsoZombie") or instanceof(obj,"IsoPlayer")) then
                local dist = NPCUtils.getDistanceBetween(self.character, obj)

				if not obj:isDead() and self:isEnemy(obj) and z == obj:getSquare():getZ() and dist < 20 then
                    local sector = self:getSector(x, y, obj:getSquare():getX(), obj:getSquare():getY())
                    sectors[sector] = sectors[sector] + 1
                end
            end
        end
    end

    local minCount = 999999
    local resultSectors = {"A"}
    for key, count in pairs(sectors) do
        if count < minCount then
            minCount = count
            resultSectors = {}
            table.insert(resultSectors, key)
        elseif count == minCount then
            table.insert(resultSectors, key)
        end
    end

    local shiftsForSectors = {}
    shiftsForSectors["A"] = {dx = 2, dy = 4}
    shiftsForSectors["B"] = {dx = 4, dy = 2}
    shiftsForSectors["C"] = {dx = 4, dy = -2}
    shiftsForSectors["D"] = {dx = 2, dy = -4}
    shiftsForSectors["E"] = {dx = -2, dy = -4}
    shiftsForSectors["F"] = {dx = -4, dy = -2}
    shiftsForSectors["G"] = {dx = -4, dy = 2}
    shiftsForSectors["H"] = {dx = -2, dy = 4}

	local c = -1
	local resSector = "A"
	for _, sec in ipairs(resultSectors) do
		if sectors[self:getOppositeSector(sec)] > c then
			c = sectors[self:getOppositeSector(sec)]
			resSector = sec
		end	
	end

    local sq = getSquare(x + shiftsForSectors[resSector].dx*rangeCoeff, y + shiftsForSectors[resSector].dy*rangeCoeff, z)
    if sq == nil or not sq:isFree(false) then
        sq = getSquare(x + shiftsForSectors[resSector].dx*rangeCoeff/2, y + shiftsForSectors[resSector].dy*rangeCoeff/2, z)
    end
    if sq == nil or not sq:isFree(false) then
        return nil
    end

    return sq
end

function NPC:getOppositeSector(sector)
	local tab = {}
	tab["A"] = "E"
	tab["B"] = "F"
	tab["C"] = "G"
	tab["D"] = "H"
	tab["E"] = "A"
	tab["F"] = "B"
	tab["G"] = "C"
	tab["H"] = "D"
	return tab[sector]
end

function NPC:getSector(x, y, x2, y2)
    local xx = x2 - x
    local yy = y2 - y

    if xx >= 0 and yy >= 0 then
        if yy > xx then
            return "A"
        else
            return "B"
        end
    elseif xx >= 0 and yy <= 0 then
        if xx > -yy then
            return "C"
        else
            return "D"
        end
    elseif xx <= 0 and yy >= 0 then
        if yy > -xx then
            return "H"
        else
            return "G"
        end
    else
        if -yy > -xx then
            return "E"
        else
            return "F"
        end
    end
end

function NPC:isUsingGun()
	return self.AI.isUsingGunParam
end

function NPC:readyGun(weapon)
	if(not weapon) or (not weapon:isAimedFirearm()) then return false end

	if weapon:isJammed() then
		weapon:setJammed(false)
	end	

	if weapon:haveChamber() and not weapon:isRoundChambered() then
		if(ISReloadWeaponAction.canRack(weapon)) then
			ISReloadWeaponAction.OnPressRackButton(self.character, weapon)
			return true
		end	
	end

	if(weapon:getMagazineType()) then
		if weapon:isContainsClip() then
			local magazine = weapon:getBestMagazine(self.character)
			if(magazine == nil) then
				ISTimedActionQueue.add(ISEjectMagazine:new(self.character, weapon))
			end
		else
			local ammoCount = ISInventoryPaneContextMenu.transferBullets(self.character, weapon:getAmmoType(), weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
			if ammoCount == 0 then
				return false
			end

			ISReloadWeaponAction.ReloadBestMagazine(self.character, weapon)
		end
	else
		if weapon:getCurrentAmmoCount() >= weapon:getMaxAmmo() then
			return true
		end

		local ammoCount = ISInventoryPaneContextMenu.transferBullets(self.character, weapon:getAmmoType(), weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
		if ammoCount == 0 then
			return false
		end
		ISTimedActionQueue.add(ISReloadWeaponAction:new(self.character, weapon))
		return true
	end

	return true
end

function NPC:haveAmmo()
	local currentWeapon = self.character:getPrimaryHandItem()
	if currentWeapon == nil or not currentWeapon:isAimedFirearm() then return end

	local ammoCount = ISInventoryPaneContextMenu.transferBullets(self.character, currentWeapon:getAmmoType(), currentWeapon:getCurrentAmmoCount(), currentWeapon:getMaxAmmo())
	if ammoCount == 0 then
		return
	end

	return ammoCount
end

function NPC:getNearestItemSquareInNearbyItems(evalFunc)
	local dist = 999
	local result = nil
	local resultSq = nil

	for i, container in ipairs(ScanSquaresSystem.nearbyItems.containers) do
		local item = container:getFirstEvalRecurse(evalFunc)
		local d = NPCUtils.getDistanceBetween(container:getSourceGrid(), self.character)
		if item and d < dist then
			result = item
			resultSq = container:getSourceGrid()
			dist = d
		end
	end

	for i, sq in ipairs(ScanSquaresSystem.nearbyItems.itemSquares) do
		local items = sq:getWorldObjects()
		local d = NPCUtils.getDistanceBetween(sq, self.character)
		for j=0, items:size()-1 do
			local item = items:get(j):getItem()
			if item then
				if evalFunc(item) and d < dist then
					result = item
					resultSq = sq
					dist = d
				else
					if item:getCategory() == "Container" then
						local item2 = item:getInventory():getFirstEvalRecurse(evalFunc)
						if item2 and d < dist then
							result = item2
							resultSq = sq
							dist = d
						end
					end
				end
			end
		end	
	end

	for i, body in ipairs(ScanSquaresSystem.nearbyItems.deadBodies) do
		local container = body:getContainer()
		local item = container:getFirstEvalRecurse(evalFunc)
		local d = NPCUtils.getDistanceBetween(container:getSourceGrid(), self.character)
		if item and d < dist then
			result = item
			resultSq = container:getSourceGrid()
			dist = d
		end
	end

	return result, resultSq
end

function NPC:getItemsSquareInNearbyItems(evalFunc)
	local resultItemSquares = {}
	local count = 0
	
	for _, container in ipairs(ScanSquaresSystem.nearbyItems.containers) do
		if container ~= nil then
			local items = container:getAllEvalRecurse(evalFunc)
			if items:size() > 0 then
				resultItemSquares[container:getSourceGrid()] = true
				count = count + 1
			end
		end
	end

	for _, sq in ipairs(ScanSquaresSystem.nearbyItems.itemSquares) do
		local items = sq:getWorldObjects()
		for j=0, items:size()-1 do
			local item = items:get(j):getItem()
			if item then
				if evalFunc(item) then
					resultItemSquares[sq] = true
					count = count + 1
					break
				else
					if item:getCategory() == "Container" then
						local items2 = item:getInventory():getAllEvalRecurse(evalFunc)
						if items2:size() > 0 then
							resultItemSquares[sq] = true
							count = count + 1
							break
						end
					end
				end
			end
		end	
	end

	for i, body in ipairs(ScanSquaresSystem.nearbyItems.deadBodies) do
		local container = body:getContainer()
		local items = container:getAllEvalRecurse(evalFunc)
		if items:size() > 0 then
			resultItemSquares[container:getSourceGrid()] = true
			count = count + 1
		end
	end

	return resultItemSquares, count
end

function NPC:getItemsInSquare(evalFunc, sq)
	local resultItems = {}

	local objs = sq:getObjects()
	for j=0, objs:size()-1 do
		local obj = objs:get(j)
		for containerIndex = 1, obj:getContainerCount() do
			local container = obj:getContainerByIndex(containerIndex-1)
			local items = container:getAllEvalRecurse(evalFunc)
			for i=1, items:size() do
				local item = items:get(i-1)
				table.insert(resultItems, item)
			end
		end
	end	

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

	local bodys = sq:getDeadBodys()
	for j=0, bodys:size()-1 do
		if bodys:get(j):getContainer():getItems():size() > 0 then
			local items = bodys:get(j):getContainer():getAllEvalRecurse(evalFunc)
			for i=1, items:size() do
				table.insert(resultItems, items:get(i-1))
			end
		end
	end	

	return resultItems
end

function NPC:getFreeFood()
	local container = self.character:getInventory()
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
	local tmpItem2 = nil
    for item, score in pairs(foodTable) do
        if score >= tmpScore then
            if tmpItem ~= nil then
				tmpItem2 = tmpItem
			end
			tmpItem = item
            tmpScore = score
        end
    end

	return tmpItem2
end

function NPC:isOkDist(sq)
	if not self.AI:isCommandFollow() and not self.AI:isCommandStayHere() then
        return true
    end
    if self.AI:isCommandFollow() and NPCUtils.getDistanceBetween(sq, getPlayer()) < 3 then
        return true
    end
    if self.AI:isCommandStayHere() and NPCUtils.getDistanceBetween(sq, self.AI.staySquare) < 2 then
        return true
    end
    return false
end

function NPC:getX()
	return self.character:getX()
end

function NPC:getY()
	return self.character:getY()
end

function NPC:getZ()
	return self.character:getZ()
end