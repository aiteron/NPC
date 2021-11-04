require "TimedActions/ISBaseTimedAction"

NPCDetachItemHotbar = ISBaseTimedAction:derive("NPCDetachItemHotbar");

function NPCDetachItemHotbar:isValid()
	return self.character:getInventory():contains(self.item);
end

function NPCDetachItemHotbar:update()
end

function NPCDetachItemHotbar:start()
	self:setActionAnim("DetachItem")
end

function NPCDetachItemHotbar:stop()
    ISBaseTimedAction.stop(self);
end

function NPCDetachItemHotbar:perform()
	self.hotbar.chr:removeAttachedItem(self.item);
	self.item:setAttachedSlot(-1);
	self.item:setAttachedSlotType(nil);
	self.item:setAttachedToModel(nil);
	
	self.hotbar:reloadIcons();

	ISInventoryPage.renderDirty = true

	if self.setAfterRemove then
		if self.item:isTwoHandWeapon() then
			self.character:setPrimaryHandItem(self.item);
			self.character:setSecondaryHandItem(self.item);
		else
			self.character:setPrimaryHandItem(self.item);
		end
	end

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function NPCDetachItemHotbar:animEvent(event, parameter)
	if event == 'detachConnect' then
		local hotbar = self.character:getModData().NPC.hotbar
		hotbar.chr:removeAttachedItem(self.item);
		self:setOverrideHandModels(self.item, nil)
	end
end

function NPCDetachItemHotbar:new(character, item, setAfterRemove)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.item = item;
	o.stopOnWalk = false;
	o.stopOnRun = true;
	o.equipped = character:isEquipped(item);
	o.hotbar = character:getModData().NPC.hotbar
	o.fromHotbar = true;
	o.useProgressBar = false;
	o.ignoreHandsWounds = true;
	o.maxTime = 25;
	o.setAfterRemove = setAfterRemove
	if o.equipped then
		o.maxTime = 1;
	end
	if o.character:isTimedActionInstant() then
		o.maxTime = 1
	end
	return o;
end
