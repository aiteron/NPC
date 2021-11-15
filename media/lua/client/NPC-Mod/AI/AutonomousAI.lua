AutonomousAI = {}
AutonomousAI.__index = AutonomousAI

function AutonomousAI:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.mainPlayer = getPlayer()
    o.character = character
    o.TaskManager = TaskManager:new(character)

    o.TaskArgs = {}
    o.command = nil
    o.idleCommand = nil

    o.staySquare = nil

    o.agressiveAttack = true

    o.rareUpdateTimer = 0
    o.EatTaskTimer = 0
    o.DrinkTaskTimer = 0

    ---
    o.isUsingGunParam = true

	o.findItems = {}
	o.findItems.Food = false
	o.findItems.Weapon = false
	o.findItems.Clothing = false
	o.findItems.Meds = false
	o.findItems.Bags = false
	o.findItems.Melee = false
	o.findItems.Literature = false

	o.fleeFindOutsideSqTimer = 0
	o.fleeFindOutsideSq = nil

    o.chillTime = 0
    o.currentInterestPoint = nil

    o.updateItemLocationTimer = 0
    
    return o
end

-- Check command functions --

function AutonomousAI:isCommandFollow()
    return self.command == "FOLLOW"
end

function AutonomousAI:isCommandStayHere()
    return self.command == "STAY"
end

function AutonomousAI:isCommandPatrol()
    return self.command == "PATROL"
end

function AutonomousAI:isCommandFindItems()
    return self.command == "FIND_ITEMS"
end

function AutonomousAI:isCommandWash()
    return self.command == "WASH"
end

function AutonomousAI:isCommandAttach()
    return self.command == "ATTACH"
end

function AutonomousAI:isFlee()
	return self.TaskManager:getCurrentTaskName() == "Flee"
end

------------------------------------

function AutonomousAI:UpdateInputParams()
    local p = {}
    
    local needToHeal = 1 - self.character:getBodyDamage():getOverallBodyHealth()/100.0              -- (from 0 to 1: 0-notneed, 1-isveryneed) // how much need to heal
    p.needToHeal = 0
    local hasInjury = false
    for i=0, self.character:getBodyDamage():getBodyParts():size()-1 do
        local bp = self.character:getBodyDamage():getBodyParts():get(i)
        if(bp:HasInjury()) and (bp:bandaged() == false) then
            hasInjury = true
            break
        end
    end
    if hasInjury then
        p.needToHeal = needToHeal
    end

    ------
    p.isGoodWeapon = 1                                          -- (1-yes, 0-no) // Is not broken weapon and have ammo if need in inv
    local currentWeapon = self.character:getPrimaryHandItem()
    if not instanceof(currentWeapon, "HandWeapon") then currentWeapon = nil end
    local meleWeapon = NPCUtils:getBestMeleWeapon(self.character:getInventory())
    local fireWeapon = NPCUtils:getBestRangedWeapon(self.character:getInventory())

    if meleWeapon == nil and fireWeapon == nil then
        if currentWeapon ~= nil then
            if currentWeapon:isAimedFirearm() then
                if currentWeapon:getCondition() < 1 then
                    self.character:getModData()["NPC"]:Say("It's bad condition weapon", NPCColor.Red)
                    p.isGoodWeapon = 0
                elseif self.character:getInventory():getItemCountRecurse(currentWeapon:getAmmoType()) <= 0 then
                    self.character:getModData()["NPC"]:Say("I don't have ammo", NPCColor.Red)
                    p.isGoodWeapon = 0
                elseif currentWeapon:getMagazineType() and self.character:getInventory():getFirstTypeRecurse(currentWeapon:getMagazineType()) == nil then
                    self.character:getModData()["NPC"]:Say("I don't have magazine", NPCColor.Red)
                    p.isGoodWeapon = 0
                end
            else
                if currentWeapon:getCondition() < 1 then
                    self.character:getModData()["NPC"]:Say("It's bad condition weapon", NPCColor.Red)
                    p.isGoodWeapon = 0
                end
            end
        end
    else
        if self.character:getModData()["NPC"]:isUsingGun() and (currentWeapon == nil or not currentWeapon:isAimedFirearm() and fireWeapon) then
            p.isGoodWeapon = 0
        end

        if not self.character:getModData()["NPC"]:isUsingGun() and (currentWeapon == nil or currentWeapon:isAimedFirearm() or currentWeapon ~= meleWeapon) then
            p.isGoodWeapon = 0
        end
    end  
    ----------
    p.isHaveGoodStuff = 0                                     -- (1-yes, 0-no) // Have many cool loot in inventory

    if self.character:getModData()["NPC"]:isUsingGun() then
        p.isMeleeWeaponEquipped = 0                                -- (1-yes, 0-no) // is melee weapon in arms?
    else
        p.isMeleeWeaponEquipped = 1
    end

    if self.agressiveAttack then
        p.isAgressiveMode = 1               -- (1-yes, 0-no) // if off - npc dont  attack enemies
    else
        p.isAgressiveMode = 0
    end

    if self.character:getModData()["NPC"].nearestEnemy ~= nil or self.character:getModData()["NPC"].isEnemyAtBack then
        p.isNearEnemy = 1                   -- (1-yes, 0-no) // is enemy in danger vision dist (<8)
    else
        p.isNearEnemy = 0
    end

    p.needReload = 0
    if currentWeapon and currentWeapon:isAimedFirearm() and currentWeapon:getCurrentAmmoCount() < currentWeapon:getMaxAmmo() and self.character:getModData()["NPC"]:haveAmmo() then
        p.needReload = 1 - currentWeapon:getCurrentAmmoCount()/currentWeapon:getMaxAmmo()
    end

    p.isTooDangerous = 0                -- (1-yes, 0-no) // is too dangerous other npc or too many zombies
    if self.character:getModData()["NPC"].nearestEnemy ~= nil or self.character:getModData()["NPC"].isEnemyAtBack then
        if self.character:getModData()["NPC"].isEnemyAtBack and self.character:getModData()["NPC"].isNearTooManyZombie then
            p.isTooDangerous = 1
        elseif self.character:getModData()["NPC"].isNearTooManyZombies or not self.agressiveAttack then
            if not self.character:isOutside() or not self.agressiveAttack then
                p.isTooDangerous = 1
            elseif self.character:getPrimaryHandItem() == nil or self.character:getPrimaryHandItem() and not self.character:getPrimaryHandItem():isAimedFirearm() then
                p.isTooDangerous = 1
            end           
        end
    end    
    
    p.isInSafeZone = 1                  -- (1-yes, 0-no) // no enemies in dist < 4
    if self.character:getModData()["NPC"].nearestEnemy ~= nil and NPCUtils.getDistanceBetween(self.character, self.character:getModData()["NPC"].nearestEnemy) < 4 then
        p.isInSafeZone = 0
    end

    if self.TaskManager:getCurrentTaskName() == "Flee" then
        p.isRunFromDanger = 1               -- (1-yes, 0-no) // npc is flee from last danger
    else
        p.isRunFromDanger = 0
    end
        
    p.needEatDrink = 0
    if self.EatTaskTimer <= 0 and self.character:getMoodles():getMoodleLevel(MoodleType.Hungry) > 1 then
        p.needEatDrink = 1
    end
    if self.DrinkTaskTimer <= 0 and self.character:getMoodles():getMoodleLevel(MoodleType.Thirst) > 1 then
        p.needEatDrink = 1
    end
    if self.character:getModData()["NPC"]:haveAmmo() then
        p.isHaveAmmoToReload = 1
    else
        p.isHaveAmmoToReload = 0
    end
    ---

    p.findItems = 0
    p.goToPoint = 0
    p.followLeader = 0
    p.haveGroup = 0
    p.isLeader = 0
    p.isChillTime = 0

    if NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID) == nil then
        if self.currentInterestPoint ~= nil then
            p.findItems = 1
        else
            local newRoomID = NPC_InterestPointMap:getNearestNewRoom(self.character:getX(), self.character:getY(), self.character:getModData().NPC.visitedRooms)

            if newRoomID ~= nil then
                if NPCUtils.getDistanceBetweenXYZ(NPC_InterestPointMap.Rooms[newRoomID].x, NPC_InterestPointMap.Rooms[newRoomID].y, self.character:getX(), self.character:getY()) < 6 then
                    p.findItems = 1
                    self:calcFindItemCategories()
                    self.currentInterestPoint = newRoomID
                    self.character:getModData().NPC.visitedRooms[newRoomID] = true 
                else
                    p.goToPoint = 1
                end
            else
                print("NO NEW INTEREST POINT")
            end
        end
    else
        p.haveGroup = 1
        if NPCGroupManager:isLeader(self.character:getModData().NPC.UUID) then
            p.isLeader = 1

            if self.currentInterestPoint ~= nil then
                p.findItems = 1
            else
                local newRoomID = NPC_InterestPointMap:getNearestNewRoom(self.character:getX(), self.character:getY(), self.character:getModData().NPC.visitedRooms)

                if newRoomID ~= nil then
                    if NPCUtils.getDistanceBetweenXYZ(NPC_InterestPointMap.Rooms[newRoomID].x, NPC_InterestPointMap.Rooms[newRoomID].y, self.character:getX(), self.character:getY()) < 6 then
                        p.findItems = 1
                        self:calcFindItemCategories()
                        self.currentInterestPoint = newRoomID
                        self.character:getModData().NPC.visitedRooms[newRoomID] = true 

                    else
                        p.goToPoint = 1
                    end
                else
                    print("NO NEW INTEREST POINT")
                end
            end
            

            if self.chillTime > 0 then
                p.isChillTime = 1
            else
                if ZombRand(20000) == 0 then
                    self.chillTime = 600
                    p.isChillTime = 1
                end
            end
        else
            local leaderID = NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID))
            local leader = NPCManager:getCharacter(leaderID)

            if leader ~= nil then
                if leader.AI.TaskManager:getCurrentTaskName() == "FindItems" and NPCUtils.getDistanceBetween(leader, self.character) < 20 then
                    p.findItems = 1
                    self:calcFindItemCategories()
                else
                    p.followLeader = 1
                end 

                if leader.AI.chillTime > 0 then
                    p.isChillTime = 1
                end
            end
        end
    end

    p.isSmoke = 0
    p.isSit = 0
    p.talkIdle = 0
    p.idleWalk = 0

    if p.isChillTime == 1 then
        if ZombRand(0,20000) == 0 then
            p.isSmoke = 1
        elseif ZombRand(0, 2000) == 0 then
            p.talkIdle = 1
        elseif ZombRand(0, 5000) == 0 then
            p.isSit = 1
        elseif ZombRand(0, 500) == 0 then
            p.idleWalk = 1
        end
    end

    if self.idleCommand == "TALK_COMPANION" then
        p.talkIdle = 1
    end

    p.isRobbed = 0
    if self.character:getModData().NPC.isRobbed then
        p.isRobbed = 1
    end

    p.enemyAimHealth = 1            -- (from 0 to 1: 0-dead, 1-fullhealth) // aim enemy health
    if self.character:getModData().NPC.robbedBy ~= nil then
       p.enemyAimHealth = self.character:getModData().NPC.robbedBy:getHealth()
    end

    ---
    self.IP = p
end

function AutonomousAI:getType()
    return "AutonomousAI"
end

function AutonomousAI:update()
    self.rareUpdateTimer = self.rareUpdateTimer + 1
    if self.rareUpdateTimer == 30 then
        self.rareUpdateTimer = 0
        self:rareUpdate()
    end

	if self.fleeFindOutsideSqTimer > 0 then
        self.fleeFindOutsideSqTimer = self.fleeFindOutsideSqTimer - 1
    end

    if self.chillTime > 0 then
        self.chillTime = self.chillTime - 1
    end

    self:UpdateInputParams()
    self:chooseTask()
    self.TaskManager:update()
end

function AutonomousAI:rareUpdate()
    self.character:getModData()["NPC"]:doVision()
end

function AutonomousAI:calcSurrenderCat()
    --print("SURR CAT.")

    local surr = {}
    surr.name = "Surrender"
    surr.score = self.IP.isRobbed

    local attack = {}
    attack.name = "Attack"
    attack.score = self.IP.isRobbed 

    local flee = {}
    flee.name = "Flee"
    flee.score = self.IP.isRobbed 

    return getMaxTaskName(surr, attack, flee)
end

function AutonomousAI:calcDangerCat()
    --print("DANGER CAT.")

    local attack = {}
    attack.name = "Attack"
    attack.score = self.IP.isAgressiveMode * self.IP.isNearEnemy * (1 - self.IP.isRunFromDanger) * self.IP.isGoodWeapon * (1 - self.IP.needReload) * (1 - self.IP.isTooDangerous)

    local flee = {}
    flee.name = "Flee"
    flee.score = self.IP.isNearEnemy *norm(self.IP.isRunFromDanger, self.IP.isTooDangerous, self.IP.needToHeal)

    local stepBack = {}
    stepBack.name = "StepBack"
    stepBack.score = self.IP.isNearEnemy*(1-self.IP.isInSafeZone)* norm(self.IP.needReload*self.IP.isGoodWeapon, 1 - self.IP.isGoodWeapon) * (1-flee.score)

    local reload = {}
    reload.name = "ReloadWeapon"
    reload.score = self.IP.isNearEnemy*(1-self.IP.isRunFromDanger)*self.IP.needReload*self.IP.isGoodWeapon*self.IP.isInSafeZone*self.IP.isHaveAmmoToReload

    local equip = {}
    equip.name = "EquipWeapon"
    equip.score = self.IP.isNearEnemy*(1-self.IP.isRunFromDanger)*(1-self.IP.isGoodWeapon)*self.IP.isInSafeZone

    return getMaxTaskName(attack, flee, stepBack, reload, equip)
end

function AutonomousAI:calcImportantCat()
    --print("IMPORTANT CAT.")

    self.IP.isCanHeal = 0
    if self.IP.needToHeal > 0 then
        self.IP.isCanHeal = 1
    end

    local firstAid = {}
    firstAid.name = "FirstAid"
    firstAid.score = self.IP.needToHeal * self.IP.isCanHeal

    local reload = {}
    reload.name = "ReloadWeapon"
    reload.score = self.IP.needReload*self.IP.isGoodWeapon*self.IP.isHaveAmmoToReload

    local eatDrink = {}
    eatDrink.name = "EatDrink"
    eatDrink.score = self.IP.needEatDrink

    return getMaxTaskName(firstAid, reload, eatDrink)
end

function AutonomousAI:calcNPCTaskCat()
    if self.command ~= nil then
        local take_items_from_player = {}
        take_items_from_player.name = "TakeItemsFromPlayer"
        take_items_from_player.score = 0
        if self.command == "TAKE_ITEMS_FROM_PLAYER" then
            take_items_from_player.score = 1
        end

        local robbing = {}
        robbing.name = "Robbing"
        robbing.score = 0
        if self.command == "ROBBING" then
            robbing.score = 1
        end

        return getMaxTaskName(take_items_from_player, robbing)
    else
        local find_items = {}
        find_items.name = "FindItems"
        find_items.score = self.IP.findItems * (1 - self.IP.isChillTime)

        local goToInterestPoint = {}
        goToInterestPoint.name = "GoToInterestPoint"
        goToInterestPoint.score = self.IP.goToPoint * (1 - self.IP.findItems) * (1 - self.IP.isChillTime)

        local followLeader = {}
        followLeader.name = "Follow"
        followLeader.score = self.IP.haveGroup * (1 - self.IP.isLeader) * (1 - self.IP.isChillTime) * (1 - self.IP.findItems)
        ----
        local talk = {}
        talk.name = "Talk"
        talk.score = self.IP.isChillTime * self.IP.talkIdle

        local walk = {}
        walk.name = "IdleWalk"
        walk.score = self.IP.isChillTime * self.IP.idleWalk

        local sit = {}
        sit.name = "Sit"
        sit.score = self.IP.isChillTime * self.IP.isSit

        local smoke = {}
        smoke.name = "Smoke"
        smoke.score = self.IP.isChillTime * self.IP.isSmoke

        return getMaxTaskName(find_items, goToInterestPoint, followLeader, talk, walk, sit, smoke)
    end
end

function AutonomousAI:calcCommonTaskCat()
    if ZombRand(0,100) < 5 then
        return --"Smoke"
    end
end

function getMaxTaskName(a, b, c, d, e, f, g)
    local t = {a, b, c, d, e, f, g}
    local task
    local max = 0
    for i, v in ipairs(t) do
        if v.score > max then
            max = v.score
            task = v
        end        
    end
    if task == nil then return nil end
    return task.name
end

function norm(a, b, c, d, e, f)
    local t = { a, b, c, d, e, f }
    local s = 0
    for i, v in ipairs(t) do
        s = s + v
    end
    return math.min(s, 1)
end



function AutonomousAI:chooseTask()
    local taskPoints = {}
    taskPoints["Follow"] = FollowTask
    taskPoints["Flee"] = FleeTask
    taskPoints["Attack"] = AttackTask
    taskPoints["EquipWeapon"] = EquipWeaponTask
    taskPoints["ReloadWeapon"] = ReloadWeaponTask
    taskPoints["FirstAid"] = FirstAidTask
    taskPoints["StayHere"] = StayHereTask
    taskPoints["Surrender"] = SurrenderTask
    taskPoints["EatDrink"] = EatDrinkTask
    taskPoints["FindItems"] = FindItemsTask
    taskPoints["Wash"] = WashTask
    taskPoints["AttachItem"] = AttachItemTask
    taskPoints["StepBack"] = StepBackTask
    taskPoints["Smoke"] = SmokeTask
    taskPoints["GoToInterestPoint"] = GoToInterestPointTask
    taskPoints["Talk"] = TalkTask
    taskPoints["TakeItemsFromPlayer"] = TakeItemsFromPlayerTask
    taskPoints["Robbing"] = RobbingTask

    taskPoints["Smoke"] = SmokeTask
    taskPoints["Sit"] = SitTask
    taskPoints["IdleWalk"] = IdleWalkTask

    -- Each category task have more priority than next (surrender > danger > important > ...)
    local task = nil
    local score = 0
    local surrenderTask = self:calcSurrenderCat()
    if surrenderTask ~= nil then
        task = surrenderTask
        score = 600
    else
        local dangerTask = self:calcDangerCat()
        if dangerTask ~= nil then
            task = dangerTask
            score = 500
        else
            local importantTask = self:calcImportantCat()
            if importantTask ~= nil then
                task = importantTask
                score = 400
            else
                local playerTask = self:calcNPCTaskCat()
                if playerTask ~= nil then
                    task = playerTask
                    score = 300
                else
                    local commonTask = self:calcCommonTaskCat()
                    if commonTask ~= nil then
                        task = commonTask
                        score = 200
                    end
                end
            end
        end
    end

    if self.TaskManager:getCurrentTaskScore() <= score and task ~= nil and task ~= self.TaskManager:getCurrentTaskName() then
        ISTimedActionQueue.clear(self.character)
        NPCPrint("AI", "New current task", task, self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname())
        self.TaskManager:addToTop(taskPoints[task]:new(self.character), score)
    end
end

function AutonomousAI:hitPlayer(wielder, weapon, damage)
    local parts = self.character:getBodyDamage():getBodyParts()
    local partIndex = ZombRand(0, parts:size())

    ISTimedActionQueue.clear(self.character)
    ISTimedActionQueue.add(ISGetHitAction:new(self.character, wielder))

    local bodyDefence = true;

    local bluntCat = false
    local firearmCat = false
    local otherCat = false

    if weapon:getType() == "BareHands" then
        return
    end

    if (weapon:getCategories():contains("Blunt") or weapon:getCategories():contains("SmallBlunt")) then
        bluntCat = true1
    elseif not (weapon:isAimedFirearm()) then
        otherCat = true
    else 
        firearmCat = true
    end

    local bodydamage = self.character:getBodyDamage()
    local bodypart = bodydamage:getBodyPart(BodyPartType.FromIndex(partIndex));
    if (ZombRand(0,100) < self.character:getBodyPartClothingDefense(partIndex, otherCat, firearmCat)) then
        bodyDefence = false;
        --self.character:addHoleFromZombieAttacks(BloodBodyPartType.FromIndex(partIndex));
    end
    if bodyDefence == false then
        return;
    end

    self.character:addHole(BloodBodyPartType.FromIndex(partIndex));
    self.character:splatBloodFloorBig(0.4);
    self.character:splatBloodFloorBig(0.4);
    self.character:splatBloodFloorBig(0.4);

    if (otherCat) then
        if (ZombRand(0,6) == 6) then
            bodypart:generateDeepWound();
        elseif (ZombRand(0,3) == 3) then
            bodypart:setCut(true);
        else
            bodypart:setScratched(true, true);
        end
    elseif (bluntCat) then
        if (ZombRand(0,4) == 4) then
            bodypart:setCut(true);
        else
            bodypart:setScratched(true, true);
        end
    elseif (firearmCat) then
        bodypart:setHaveBullet(true, 0);
    end

    bodydamage:AddDamage(partIndex, damage*100.0);
    local stats = self.character:getStats();
    if bluntCat then
        stats:setPain(stats:getPain() + bodydamage:getInitialThumpPain() * BodyPartType.getPainModifyer(partIndex));
    elseif otherCat then
        stats:setPain(stats:getPain() + bodydamage:getInitialScratchPain() * BodyPartType.getPainModifyer(partIndex));
    elseif firearmCat then
        stats:setPain(stats:getPain() + bodydamage:getInitialBitePain() * BodyPartType.getPainModifyer(partIndex));
    end

    bodydamage:Update();
end

function AutonomousAI:calcFindItemCategories()
    self.findItems.Food = true
	self.findItems.Weapon = true
	self.findItems.Clothing = false
	self.findItems.Meds = true
	self.findItems.Bags = true
	self.findItems.Melee = true
	self.findItems.Literature = false
end
