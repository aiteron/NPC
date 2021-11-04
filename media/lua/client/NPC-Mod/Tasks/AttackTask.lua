AttackTask = {}
AttackTask.__index = AttackTask

function AttackTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Attack"
	o.complete = false

    o.delayTimer = 0
    o.currentRunAction = nil

    if ZombRand(0, 8) == 0 then
        character:getModData().NPC:Say(NPC_Dialogues.attackTalk[ZombRand(1, #NPC_Dialogues.attackTalk+1)], NPCColor.White)
    end

	return o
end


function AttackTask:isComplete()
	return self.complete
end

function AttackTask:isValid()
    if not self.character and self.character:getModData()["NPC"].nearestEnemy then
        self.character:NPCSetAttack(false)
        self.character:NPCSetMelee(false)
        self.character:NPCSetAiming(false)
        self.character:setForceShove(false);
        self.character:setAimAtFloor(false)
        self.character:setVariable("bShoveAiming", false);
        return false
    end

    return true
end

function AttackTask:stop()
    self.character:NPCSetAttack(false)
    self.character:NPCSetMelee(false)
    self.character:NPCSetAiming(false)
    self.character:setForceShove(false);
    self.character:setAimAtFloor(false)
    self.character:setVariable("bShoveAiming", false);
end

function AttackTask:update()
    if not self:isValid() then return false end
    
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    self.character:getModData()["NPC"]:doVision()
    self.character:faceThisObject(self.character:getModData()["NPC"].nearestEnemy)

    local dist = NPCUtils.getDistanceBetween(self.character, self.character:getModData()["NPC"].nearestEnemy)

    if self.character:getModData()["NPC"]:isUsingGun() and self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():isAimedFirearm() then
        if self.character:getVehicle() ~= nil then
            return false
        end
        
        if dist < 3 then
            if not ISTimedActionQueue.hasAction(self.currentWalkAction) then
                self.character:NPCSetAiming(false)
                local sq = self.character:getModData()["NPC"]:getSafestSquare(2)
                ISTimedActionQueue.clear(self.character)
                self.currentWalkAction = NPCWalkToAction:new(self.character, sq, true)
                ISTimedActionQueue.add(self.currentWalkAction)
            end
        else
            if actionCount == 0 then
                if self.character:getModData()["NPC"].nearestEnemy ~= nil and self.delayTimer <= 0 then
                    self.character:NPCSetAiming(true)
                    if ISReloadWeaponAction.canShoot(self.character:getPrimaryHandItem()) then
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(false);
                        self.character:pressedAttack()
                        self.delayTimer = 50  
                    else
                        if not self.character:getModData()["NPC"]:readyGun(self.character:getPrimaryHandItem()) then
                            self:stop()
                            return false
                        end
                    end
                else
                    self.character:NPCSetAttack(false)
                    self.character:NPCSetMelee(false)
                end
            end
            if self.delayTimer > 0 then
                self.delayTimer = self.delayTimer - 1
            end
        end

        if self.character:getModData()["NPC"].nearestEnemy == nil or self.character:getModData()["NPC"].nearestEnemy:isDead() then
            self.complete = true
            self.character:setAimAtFloor(false)
            self.character:NPCSetAttack(false)
            self.character:NPCSetMelee(false)
            self.character:NPCSetAiming(false)
            self.character:setForceShove(false);
            self.character:setVariable("bShoveAiming", false);
        end
    else
        if self.character:getVehicle() ~= nil then
            return false
        end

        local minrange = self.character:getModData()["NPC"]:getMinWeaponRange()
        local maxrange = self.character:getModData()["NPC"]:getMaxWeaponRange()

        if dist >= maxrange then
            self.character:NPCSetAttack(false)
            self.character:NPCSetMelee(false)
    
            if actionCount == 0 then
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.character:getModData()["NPC"].nearestEnemy:getSquare(), false))
            end
        else
            ISTimedActionQueue.clear(self.character)
            if self.character:getModData()["NPC"].nearestEnemy then
                if self.character:getModData()["NPC"].nearestEnemy:isOnFloor() then
                    if self.character:getPrimaryHandItem() ~= nil then
                        self.character:setAimAtFloor(true)
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(true);
                        self.character:pressedAttack()
                        --print("A")
                    else
                        self.character:setAimAtFloor(true)
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(true);
                        self.character:pressedAttack()
                        --print("B")
                    end
                else
                    if dist < minrange then
                        self.character:setAimAtFloor(false)
                        self.character:setForceShove(true);
                        self.character:setVariable("bShoveAiming", true);
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(true);  
                        self.character:pressedAttack();
                        --print("C")
                    else
                        if self.character:getPrimaryHandItem() ~= nil then
                            self.character:setAimAtFloor(false)
                            self.character:NPCSetAttack(true);
                            self.character:NPCSetMelee(true);
                            self.character:pressedAttack()
                            --print("D")
                        else
                            self.character:setAimAtFloor(false)
                            self.character:setForceShove(true);
                            self.character:setVariable("bShoveAiming", true);
                            self.character:NPCSetAttack(true);
                            self.character:NPCSetMelee(false);  
                            self.character:pressedAttack();
                            --print("E")
                        end
                    end
                end
            end
        end
    
        if self.character:getModData()["NPC"].nearestEnemy == nil or self.character:getModData()["NPC"].nearestEnemy:isDead() then
            self.complete = true
            self.character:NPCSetAttack(false)
            self.character:NPCSetMelee(false)
            self.character:setForceShove(false)
            self.character:NPCSetAiming(false)
            self.character:setAimAtFloor(false)
            self.character:setVariable("bShoveAiming", false);
        end
    end
    return true
end