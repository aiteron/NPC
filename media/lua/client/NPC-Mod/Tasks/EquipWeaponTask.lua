EquipWeaponTask = {}
EquipWeaponTask.__index = EquipWeaponTask

function EquipWeaponTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "EquipWeapon"
	o.complete = false

    o.item = "none"

	return o
end


function EquipWeaponTask:isComplete()
	return self.complete
end

function EquipWeaponTask:stop()

end

function EquipWeaponTask:isValid()
    return self.character
end

function EquipWeaponTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if self.item ~= "none" and self.character:getPrimaryHandItem() == self.item and actionCount == 0 then 
        self.complete = true
        return
    end

    if actionCount == 0 then
        local currentWeapon = self.character:getPrimaryHandItem()
        if not instanceof(currentWeapon, "HandWeapon") then currentWeapon = nil end
        local meleWeapon = NPCUtils:getBestMeleWeapon(self.character:getInventory())
        local fireWeapon = NPCUtils:getBestRangedWeapon(self.character:getInventory())

        if currentWeapon == nil then
            if self.character:getModData()["NPC"]:isUsingGun() then
                if fireWeapon then
                    self.item = fireWeapon
                    if self.item:getAttachedSlot() ~= -1 then
                        self.character:getModData()["NPC"].hotbar:removeItem(self.item, true, true)
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 20, true, self.item:isTwoHandWeapon()))
                    end
                elseif meleWeapon then
                    self.item = meleWeapon
                    if self.item:getAttachedSlot() ~= -1 then
                        self.character:getModData()["NPC"].hotbar:removeItem(self.item, true, true)
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 20, true, self.item:isTwoHandWeapon()))
                    end
                end
            else
                if meleWeapon then
                    self.item = meleWeapon
                    if self.item:getAttachedSlot() ~= -1 then
                        self.character:getModData()["NPC"].hotbar:removeItem(self.item, true, true)
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 20, true, self.item:isTwoHandWeapon()))
                    end
                end
            end
        else
            if self.character:getModData()["NPC"]:isUsingGun() then
                ISTimedActionQueue.add(ISUnequipAction:new(self.character, self.character:getPrimaryHandItem(), 50));
                if fireWeapon then
                    self.item = fireWeapon
                    if self.item:getAttachedSlot() ~= -1 then
                        self.character:getModData()["NPC"].hotbar:removeItem(self.item, true, true)
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 20, true, self.item:isTwoHandWeapon()))
                    end
                end
                self.item = fireWeapon
            else
                ISTimedActionQueue.add(ISUnequipAction:new(self.character, self.character:getPrimaryHandItem(), 50));
                if meleWeapon then
                    self.item = meleWeapon
                    if self.item:getAttachedSlot() ~= -1 then
                        self.character:getModData()["NPC"].hotbar:removeItem(self.item, true, true)
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 20, true, self.item:isTwoHandWeapon()))
                    end
                end
                self.item = meleWeapon
            end
        end
    end

    return true
end