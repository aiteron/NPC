PlayerGroupAI = {}
PlayerGroupAI.__index = PlayerGroupAI

function PlayerGroupAI:new(character)
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

    o.isAtBase = false

    o.updateItemLocationTimer = 0
    
    return o
end

-- Check command functions --

function PlayerGroupAI:isCommandFollow()
    return self.command == "FOLLOW"
end

function PlayerGroupAI:isCommandStayHere()
    return self.command == "STAY"
end

function PlayerGroupAI:isCommandPatrol()
    return self.command == "PATROL"
end

function PlayerGroupAI:isCommandFindItems()
    return self.command == "FIND_ITEMS"
end

function PlayerGroupAI:isCommandWash()
    return self.command == "WASH"
end

function PlayerGroupAI:isCommandAttach()
    return self.command == "ATTACH"
end

function PlayerGroupAI:isFlee()
	return self.TaskManager:getCurrentTaskName() == "Flee"
end

------------------------------------

function PlayerGroupAI:UpdateInputParams()
    local p = {}
    
    p.isEnemyAim = 0    -- (1-yes, 0-no) // Is enemy aim gun on NPC
    if NPCUtils.getDistanceBetween(self.character, self.mainPlayer) < 6 and self.mainPlayer:isAiming() and self.mainPlayer:getPrimaryHandItem() and self.mainPlayer:getPrimaryHandItem():isAimedFirearm() and (self.mainPlayer:getDotWithForwardDirection(self.character:getX(), self.character:getY()) + 0.1) >= 1 then
        p.isEnemyAim = 1
    end

    p.enemyAimHealth = self.mainPlayer:getBodyDamage():getOverallBodyHealth()/100.0             -- (from 0 to 1: 0-dead, 1-fullhealth) // aim enemy health
    p.isEnemyAimMany = 0                                        -- (1-yes, 0-no) // is many enemies aim gun on NPC
    
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
    p.isHaveGoodStuff = 1                                       -- (1-yes, 0-no) // Have many cool loot in inventory

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

    if self.character:getModData()["NPC"].nearestEnemy ~= nil then
        p.isNearEnemy = 1                   -- (1-yes, 0-no) // is enemy in danger vision dist (<8)
    else
        p.isNearEnemy = 0
    end
    p.needReload = 0
    if currentWeapon and currentWeapon:isAimedFirearm() and currentWeapon:getCurrentAmmoCount() < currentWeapon:getMaxAmmo() and self.character:getModData()["NPC"]:haveAmmo() then
        p.needReload = 1 - currentWeapon:getCurrentAmmoCount()/currentWeapon:getMaxAmmo()
    end


    p.isTooDangerous = 0                -- (1-yes, 0-no) // is too dangerous other npc or too many zombies
    if self.character:getModData()["NPC"].nearestEnemy ~= nil then
        if self.character:getModData()["NPC"].isEnemyAtBack then
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

    if self.TaskManager:getCurrentTaskName() == "Flee" or self.TaskManager:getCurrentTaskName() == "StepBack" then
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
    if ZombRand(0,20000) == 0 then
        p.isSmoke = true
    elseif ZombRand(0, 5000) == 0 then
        p.isSit = true
    elseif ZombRand(0, 500) == 0 then
        p.idleWalk = true
    elseif ZombRand(0, 2000) == 0 then
        p.talkIdle = true
    end


    --
    self.IP = p
end

function PlayerGroupAI:getType()
    return "PlayerGroupAI"
end

function PlayerGroupAI:update()
    self.rareUpdateTimer = self.rareUpdateTimer + 1
    if self.rareUpdateTimer == 30 then
        self.rareUpdateTimer = 0
        self:rareUpdate()
    end

	if self.fleeFindOutsideSqTimer > 0 then
        self.fleeFindOutsideSqTimer = self.fleeFindOutsideSqTimer - 1
    end

    self:UpdateInputParams()
    self:chooseTask()
    self.TaskManager:update()


    local isAtBase = NPCGroupManager:isAtBase(self.character:getX(), self.character:getY())
    if isAtBase then
        if self.isAtBase == false then
            if ZombRand(0, 10) == 0 then
                self.character:getModData().NPC:Say("HOME SWEET HOME", NPCColor.White)    
            end
        end
        self.isAtBase = true
    else
        self.isAtBase = false
    end    
end

function PlayerGroupAI:rareUpdate()
    self.character:getModData()["NPC"]:doVision()
end

function PlayerGroupAI:calcSurrenderCat()
    --print("SURR CAT.")

    local surr = {}
    surr.name = "Surrender"
    surr.score = self.IP.isEnemyAim * norm(self.IP.isEnemyAimMany, self.IP.needToHeal)

    local attack = {}
    attack.name = "Attack"
    attack.score = self.IP.isEnemyAim * (1-self.IP.isEnemyAimMany) * (1-self.IP.isMeleeWeaponEquipped*self.IP.enemyAimHealth) * norm(self.IP.isGoodWeapon, (1-self.IP.enemyAimHealth))

    local flee = {}
    flee.name = "Flee"
    flee.score = self.IP.isEnemyAim * (1-self.IP.isEnemyAimMany) * self.IP.isHaveGoodStuff * (1 - attack.score)

    return getMaxTaskName(surr, attack, flee)
end

function PlayerGroupAI:calcDangerCat()
    --print("DANGER CAT.")

    local attack = {}
    attack.name = "Attack"
    attack.score = self.IP.isAgressiveMode* self.IP.isNearEnemy * (1 - self.IP.isRunFromDanger) * self.IP.isGoodWeapon * (1 - self.IP.needReload) * (1 - self.IP.isTooDangerous)

    --print("attack ", attack.score)

    local flee = {}
    flee.name = "Flee"
    flee.score = self.IP.isNearEnemy *norm(self.IP.isRunFromDanger, self.IP.isTooDangerous, self.IP.needToHeal)

    --print("flee ", flee.score)

    local stepBack = {}
    stepBack.name = "StepBack"
    stepBack.score = self.IP.isNearEnemy*(1-self.IP.isInSafeZone)*self.IP.needReload*self.IP.isGoodWeapon * (1-flee.score)

    local reload = {}
    reload.name = "ReloadWeapon"
    reload.score = self.IP.isNearEnemy*(1-self.IP.isRunFromDanger)*self.IP.needReload*self.IP.isGoodWeapon*self.IP.isInSafeZone*self.IP.isHaveAmmoToReload

    local equip = {}
    equip.name = "EquipWeapon"
    equip.score = self.IP.isNearEnemy*(1-self.IP.isRunFromDanger)*(1-self.IP.isGoodWeapon)*self.IP.isInSafeZone

    return getMaxTaskName(attack, flee, stepBack, reload, equip)
end

function PlayerGroupAI:calcImportantCat()
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

function PlayerGroupAI:calcPlayerTaskCat()
    local follow = {}
    follow.name = "Follow"
    follow.score = 0
    if self:isCommandFollow() and NPCUtils.getDistanceBetween(self.character, self.mainPlayer) > 3 then
        follow.score = 1
    end

    local stay = {}
    stay.name = "StayHere"
    stay.score = 0
    if self:isCommandStayHere() and self.character:getSquare() ~= self.staySquare then
        stay.score = 1
    end

    local patrol = {}
    patrol.name = "Patrol"
    patrol.score = 0
    if self:isCommandPatrol() then
        patrol.score = 1
    end

    local find_items = {}
    find_items.name = "FindItems"
    find_items.score = 0
    if self:isCommandFindItems() then
        find_items.score = 1
    end

    local wash = {}
    wash.name = "Wash"
    wash.score = 0
    if self:isCommandWash() then
        wash.score = 1
    end

    local attach = {}
    attach.name = "AttachItem"
    attach.score = 0
    if self:isCommandAttach() then
        attach.score = 1
    end

    local dropLoot = {}
    dropLoot.name = "DropLoot"
    dropLoot.score = 0
    if self.command == "DROP_LOOT" then
        dropLoot.score = 1
    end

    local talk = {}
    talk.name = "Talk"
    talk.score = 0
    if self.command == "TALK" then
        talk.score = 1
    end

    return getMaxTaskName(follow, stay, patrol, find_items, wash, attach, talk, dropLoot)
end

function PlayerGroupAI:calcCommonTaskCat()
    if self.idleCommand ~= nil then
        if self.idleCommand == "SMOKE" then
            return "Smoke"
        end
    
        if self.idleCommand == "SIT" then
            return "Sit"
        end
    
        if self.idleCommand == "IDLE_WALK" and self.character:getActionStateName() ~= "sitonground" then
            return "IdleWalk"
        end
    
        if self.idleCommand == "TALK" then
            self.TaskArgs.talkChar = getPlayer()
            return "Talk"
        end
    else
        if self.IP.isSmoke then
            return "Smoke"
        end
    
        if self.IP.isSit then
            return "Sit"
        end
    
        if self.IP.idleWalk and self.character:getActionStateName() ~= "sitonground" then
            return "IdleWalk"
        end
    
        if self.IP.talkIdle  then
            self.TaskArgs.talkChar = getPlayer()
            return "Talk"
        end
    end
end

function getMaxTaskName(a, b, c, d, e, f, g, i, j, k, l, m)
    local t = {a, b, c, d, e, f, g, i, j, k, l, m}
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



function PlayerGroupAI:chooseTask()
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
    taskPoints["Talk"] = TalkTask
    taskPoints["DropLoot"] = DropLootTask

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
                local playerTask = self:calcPlayerTaskCat()
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

    --print("TASK ", task)
    --print("CURRENT T ", self.TaskManager:getCurrentTaskName())

    if self.TaskManager:getCurrentTaskScore() <= score and task ~= nil and task ~= self.TaskManager:getCurrentTaskName() then
        ISTimedActionQueue.clear(self.character)
        NPCPrint("AI", "New current task", task, self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
        self.TaskManager:addToTop(taskPoints[task]:new(self.character), score)
    end
end

function PlayerGroupAI:hitPlayer(wielder, weapon, damage)
    local parts = self.character:getBodyDamage():getBodyParts()
    local partIndex = ZombRand(parts:size())

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
        self.character:addHoleFromZombieAttacks(BloodBodyPartType.FromIndex(partIndex));
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