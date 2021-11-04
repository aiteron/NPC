ReloadWeaponTask = {}
ReloadWeaponTask.__index = ReloadWeaponTask

function ReloadWeaponTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "ReloadWeapon"
	o.complete = false

    o.delayTimer = 0

	return o
end


function ReloadWeaponTask:isComplete()
	return self.complete
end

function ReloadWeaponTask:isValid()
    return self.character and self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():isAimedFirearm()
end

function ReloadWeaponTask:stop()
    self.character:NPCSetAttack(false)
    self.character:NPCSetMelee(false)
    self.character:NPCSetAiming(false)
    self.character:setForceShove(false);
    self.character:setVariable("bShoveAiming", false);
end

function ReloadWeaponTask:update()
    if not self:isValid() then return false end
    local currentWeapon = self.character:getPrimaryHandItem()
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        self.character:getModData()["NPC"]:readyGun(currentWeapon)
    end

    if currentWeapon:getCurrentAmmoCount() >= currentWeapon:getMaxAmmo() or self.character:getInventory():getItemCountRecurse(currentWeapon:getAmmoType()) == 0 then
        self.complete = true
    end

    return true
end