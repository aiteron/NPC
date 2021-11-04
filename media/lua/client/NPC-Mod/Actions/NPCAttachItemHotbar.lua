require "TimedActions/ISBaseTimedAction"

NPCAttachItemHotbar = ISBaseTimedAction:derive("NPCAttachItemHotbar");

function NPCAttachItemHotbar:isValid()
	return self.character:getInventory():contains(self.item);
end

function NPCAttachItemHotbar:update()
end

function NPCAttachItemHotbar:start()
	self:setActionAnim("AttachItem")
	self:setOverrideHandModels(self.item, nil)
end

function NPCAttachItemHotbar:stop()
	if self.hotbar.attachedItems[self.slotIndex] ~= self.item and
			self.character:getAttachedItem(self.slot) == self.item then
		-- Action was cancelled after the 'attachConnect' event.
		self.character:removeAttachedItem(self.item)
	end
	ISBaseTimedAction.stop(self);
end

function NPCAttachItemHotbar:perform()
	-- remove previous item
	if self.hotbar.attachedItems[self.slotIndex] then
		self.hotbar.chr:removeAttachedItem(self.hotbar.attachedItems[self.slotIndex]);
		self.hotbar.attachedItems[self.slotIndex]:setAttachedSlot(-1);
		self.hotbar.attachedItems[self.slotIndex]:setAttachedSlotType(nil);
		self.hotbar.attachedItems[self.slotIndex]:setAttachedToModel(nil);
	end
	-- add new item
	-- if the item need to be attached elsewhere than its original emplacement because of a bag for example
	if self.hotbar.replacements and self.hotbar.replacements[self.item:getAttachmentType()] then
		self.slot = self.hotbar.replacements[self.item:getAttachmentType()];
		if self.slot == "null" then
			self.hotbar:removeItem(self.item);
			return;
		end
	end
	
	self.hotbar.chr:setAttachedItem(self.slot, self.item);
	self.item:setAttachedSlot(self.slotIndex);
	self.item:setAttachedSlotType(self.slotDef.type);
	self.item:setAttachedToModel(self.slot);
	
	self.hotbar:reloadIcons();

	ISInventoryPage.renderDirty = true

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function NPCAttachItemHotbar:animEvent(event, parameter)
	if event == 'attachConnect' then
		local hotbar = self.character:getModData().NPC.hotbar
		if self.equipped then
			self.character:removeFromHands(self.item)
		end
		hotbar.chr:setAttachedItem(self.slot, self.item);
		self:setOverrideHandModels(nil, nil)
	end
end

function NPCAttachItemHotbar:new(character, item, slot, slotIndex, slotDef)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.item = item;
	o.stopOnWalk = false;
	o.stopOnRun = true;
	o.slotIndex = slotIndex;
	o.slot = slot;
	o.slotDef = slotDef;
	o.fromHotbar = true;
	o.equipped = character:isEquipped(item);
	o.maxTime = 30;
	o.hotbar = character:getModData().NPC.hotbar
	o.useProgressBar = false;
	o.ignoreHandsWounds = true;
	if o.character:isTimedActionInstant() then
		o.maxTime = 1
	end
	return o;
end
