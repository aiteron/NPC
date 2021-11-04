require "ISUI/ISPanelJoypad"

NPCHotBar = ISPanelJoypad:derive("NPCHotBar");

function NPCHotBar:getSlotDef(slot)
	for i,v in ipairs(ISHotbarAttachDefinition) do
		if slot == v.type then
			return v;
		end
	end
	return nil
end

function NPCHotBar:getSlotDefReplacement(slot)
	for i,v in ipairs(ISHotbarAttachDefinition.replacements) do
		if slot == v.type then
			return v;
		end
	end
	return slot;
end

function NPCHotBar.doMenuFromInventory(char, item, context)
	local self = char:getModData().NPC.hotbar
	if self == nil then return end
	if self:isInHotbar(item) and item:getAttachmentType() and item:getAttachedSlot() ~= -1 then
		local slot = self.availableSlot[item:getAttachedSlot()]
		local slotName = getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name;
		context:addOptionOnTop("NPC: ".. getText("ContextMenu_RemoveFromHotbar", self.attachedItems[item:getAttachedSlot()]:getDisplayName(), slotName), self, NPCHotBar.removeItemStartTask, self.attachedItems[item:getAttachedSlot()], true);
	end
	if item:getAttachmentType() and not self:isInHotbar(item) and not item:isBroken() and self.replacements[item:getAttachmentType()] ~= "null" then
		local subOption = context:addOptionOnTop("NPC: ".. getText("ContextMenu_Attach"), nil);
		local subMenuAttach = context:getNew(context);
		context:addSubMenu(subOption, subMenuAttach);
		
		local found = false;
		for slotIndex, slot in pairs(self.availableSlot) do
			local slotDef = slot.def;
			for i, v in pairs(slotDef.attachments) do
				if item:getAttachmentType() == i then
					local doIt = true;
					local name = getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name;
					if self.replacements and self.replacements[item:getAttachmentType()] then
						slot = self.replacements[item:getAttachmentType()];
						if slot == "null" then
							doIt = false;
						end
					end
					if doIt then
						local option = subMenuAttach:addOption(name, self, NPCHotBar.attachItemStartTask, item, v, slotIndex, slotDef, true);
						if self.attachedItems[slotIndex] then
							local tooltip = ISWorldObjectContextMenu.addToolTip();
							tooltip.description = tooltip.description .. getText("Tooltip_ReplaceWornItems") .. " <LINE> <INDENT:20> "
							tooltip.description = tooltip.description .. self.attachedItems[slotIndex]:getDisplayName()
							option.toolTip = tooltip
						end 
						found = true;
					end
				end
			end
		end


		-- didn't found anything to it, gonna add the possibilities as a tooltip
		if not found then
			subOption.notAvailable = true;
			local tooltip = ISWorldObjectContextMenu.addToolTip();
			local text = getText("Tooltip_CanBeAttached") .. " <LINE> <INDENT:20> ";
			for i,v in pairs(ISHotbarAttachDefinition) do
				if v.attachments then
					for type,atch in pairs(v.attachments) do
						if type == item:getAttachmentType() then
							text = text .. getText("IGUI_HotbarAttachment_" .. v.type) .. " <LINE> "
						end
					end
				end
			end
			subOption.subOption = nil;
			tooltip.description = text;
			subOption.toolTip = tooltip;
		end
	end
end

function NPCHotBar:isInHotbar(item)
	if not self.attachedItems then return false; end
	for i, equipped in pairs(self.attachedItems) do
		if equipped == item then
			return true;
		end
	end
	return false;
end

function NPCHotBar:update()
	if self.needsRefresh then
		self:refresh()
	end

	-- don't update during other actions (to avoid flicking during equipping etc.)
	local queue = ISTimedActionQueue.queues[self.character];
	if queue and #queue.queue > 0 then
		return;
	end
	-- check if we need to remove item from the hotbar or attached model on the player
	for i, item in pairs(self.attachedItems) do
		local slot = self.availableSlot[item:getAttachedSlot()]
		if not slot or not self:canBeAttached(slot, item) or not self.chr:getInventory():contains(item) or item:isBroken() then
			self:removeItem(item, false, false);
			self.chr:removeAttachedItem(item);
		else
			local slotDef = slot.def;
			if self.chr:isEquipped(item) then
				self.chr:removeAttachedItem(item);
			elseif not self.chr:getAttachedItem(item:getAttachedToModel()) then -- ensure it's attached
				self:attachItem(item, slotDef.attachments[item:getAttachmentType()], item:getAttachedSlot(), slotDef, false)
			end
		end
	end
end

function NPCHotBar:canBeAttached(slot, item)
	local slotDef = slot.def;
	for i,v in pairs(slotDef.attachments) do
		if item:getAttachmentType() == i then
			local doIt = true;
			if self.replacements and self.replacements[item:getAttachmentType()] then
				slot = self.replacements[item:getAttachmentType()];
				if slot == "null" then
					doIt = false;
				end
			end
			if doIt then
				return true;
			end
		end
	end
	return false;
end

-- Set the variable depending on where the item is (to trigger either back, holster or belt anim..)
function NPCHotBar:setAttachAnim(item, slot)
	if slot then
		self.chr:SetVariable("AttachAnim", slot.animset);
		return;
	end
	for i,slot in pairs(self.availableSlot) do
		if slot.def.type == item:getAttachedSlotType() then
			self.chr:SetVariable("AttachAnim", slot.def.animset);
			break;
		end
	end
end

function NPCHotBar:removeItemStartTask(item, doAnim)
	self.character:getModData().NPC.AI.command = "ATTACH"

	self.character:getModData().NPC.AI.TaskArgs = {}
	self.character:getModData().NPC.AI.TaskArgs.isAttach = false
	self.character:getModData().NPC.AI.TaskArgs.item = item
	self.character:getModData().NPC.AI.TaskArgs.doAnim = doAnim
end

-- remove an item from the hotbar
function NPCHotBar:removeItem(item, doAnim, setAfterRemove)
	if doAnim then
		self:setAttachAnim(item);
		ISTimedActionQueue.add(NPCDetachItemHotbar:new(self.chr, item, setAfterRemove));
	else
		self.chr:removeAttachedItem(item);
		item:setAttachedSlot(-1);
		item:setAttachedSlotType(nil);
		item:setAttachedToModel(nil);
		
		self:reloadIcons();
	end
end

function NPCHotBar:isItemAttached(item)
	for i, attached in pairs(self.attachedItems) do
		if attached == item then
			return true;
		end
	end
	return false;
end

function NPCHotBar:attachItemStartTask(item, slot, slotIndex, slotDef, doAnim)
	self.character:getModData().NPC.AI.command = "ATTACH"

	self.character:getModData().NPC.AI.TaskArgs = {}
	self.character:getModData().NPC.AI.TaskArgs.isAttach = true
	self.character:getModData().NPC.AI.TaskArgs.item = item
	self.character:getModData().NPC.AI.TaskArgs.slot = slot
	self.character:getModData().NPC.AI.TaskArgs.slotIndex = slotIndex
	self.character:getModData().NPC.AI.TaskArgs.slotDef = slotDef
	self.character:getModData().NPC.AI.TaskArgs.doAnim = doAnim
end

function NPCHotBar:attachItem(item, slot, slotIndex, slotDef, doAnim)
	if doAnim then
		if self.replacements and self.replacements[item:getAttachmentType()] then
			slot = self.replacements[item:getAttachmentType()];
		end
		self:setAttachAnim(item, slotDef);
		ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item)
		-- first remove the current equipped one if needed
		if self.attachedItems[slotIndex] then
			ISTimedActionQueue.add(NPCDetachItemHotbar:new(self.chr, self.attachedItems[slotIndex]));
		end
		local attachHotbarAct = NPCAttachItemHotbar:new(self.chr, item, slot, slotIndex, slotDef) 
		ISTimedActionQueue.add(attachHotbarAct);
	else
		-- add new item
		-- if the item need to be attached elsewhere than its original emplacement because of a bag for example
		if self.replacements and self.replacements[item:getAttachmentType()] then
			slot = self.replacements[item:getAttachmentType()];
			if slot == "null" then
				self:removeItem(item, false, false);
				return;
			end
		end

		self.chr:setAttachedItem(slot, item);
		item:setAttachedSlot(slotIndex);
		item:setAttachedSlotType(slotDef.type);
		item:setAttachedToModel(slot);
		
		self:reloadIcons();
	end
end

function NPCHotBar:reloadIcons()
	self.attachedItems = {};
	for i=0, self.chr:getInventory():getItems():size()-1 do
		local item = self.chr:getInventory():getItems():get(i);
		if item:getAttachedSlot() > -1 then
			self.attachedItems[item:getAttachedSlot()] = item;
		end
	end
end

function NPCHotBar:haveThisSlot(slotType, list)
	if not list then
		list = self.availableSlot;
	end
	for i,v in pairs(list) do
		if v.slotType == slotType then
			return true;
		end
	end
	return false;
end

function NPCHotBar:compareWornItems()
	local wornItems = self.chr:getWornItems()
	if #self.wornItems ~= wornItems:size() then
		return true
	end
	for index,item in ipairs(self.wornItems) do
		if item ~= wornItems:getItemByIndex(index-1) then
			return true
		end
	end
	return false
end

-- redo our slots when clothing has changed
function NPCHotBar:refresh()
	self.needsRefresh = false

	-- the clothingUpdate is called quite often, we check if we changed any clothing to be sure we need to refresh
	-- as it can be called also when adding blood/holes..
	local refresh = false;

	if not self.wornItems then
		self.wornItems = {};
		refresh = true;
	elseif self:compareWornItems() then
		refresh = true;
	end
	
	if not refresh then
		return;
	end

	local newSlots = {};
	local newIndex = 2;
	local slotIndex = #self.availableSlot + 1;

	-- always have a back attachment
	local slotDef = self:getSlotDef("Back");
	newSlots[1] = {slotType = slotDef.type, name = slotDef.name, def = slotDef};
	
	self.replacements = {};
	table.wipe(self.wornItems)
	
	-- check to add new availableSlot if we have new equipped clothing that gives some
	-- we first do this so we keep our order in hotkeys (equipping new emplacement will make them goes on last position)
	for i=0, self.chr:getWornItems():size()-1 do
		local item = self.chr:getWornItems():getItemByIndex(i);
		table.insert(self.wornItems, item)
		-- Skip bags in hands
		if item and self.chr:isHandItem(item) then
			item = nil
		end
		-- item gives some attachments
		if item and item:getAttachmentsProvided() then

			for j=0, item:getAttachmentsProvided():size()-1 do
				local slotDef = self:getSlotDef(item:getAttachmentsProvided():get(j));
				if slotDef then
					newSlots[newIndex] = {slotType = slotDef.type, name = slotDef.name, def = slotDef};
					newIndex = newIndex + 1;
					if not self:haveThisSlot(slotDef.type) then
						self.availableSlot[slotIndex] = {slotType = slotDef.type, name = slotDef.name, def = slotDef, texture = item:getTexture()};
						slotIndex = slotIndex + 1;
						self:savePosition();
					else
						-- This sets the slot texture after loadPosition().
						for i2,slot in pairs(self.availableSlot) do
							if slot.slotType == slotDef.type then
								slot.texture = item:getTexture()
								break
							end
						end
					end
				end
			end
		end
		if item and item:getAttachmentReplacement() then -- item has a replacement
			local replacementDef = self:getSlotDefReplacement(item:getAttachmentReplacement());
			if replacementDef then
				for type, model in pairs(replacementDef.replacement) do
					self.replacements[type] = model;
				end
			end
		end
	end

	-- check if we're missing slots
	if #self.availableSlot ~= #newSlots then
		local removed = 0;
		if #self.availableSlot > #newSlots then
			removed = #self.availableSlot - #newSlots;
		end
		for i,v in pairs(self.availableSlot) do
			if not self:haveThisSlot(v.slotType, newSlots) then
				-- remove the attached items that was in a slot we just lost
				if self.attachedItems[i] then
					self:removeItem(self.attachedItems[i], false, false);
					self.attachedItems[i] = nil;
				end
				-- we gonna check if we had an item in a slot that has a bigger index and was removed to move it
				if self.attachedItems[i + removed] then
					self.attachedItems[i] = self.attachedItems[i + removed];
					self.attachedItems[i]:setAttachedSlot(i);
					self.attachedItems[i + removed] = nil;
				end
				self.availableSlot[i] = nil;
			end
		end
		
		self:savePosition();
	end
	
	newSlots = {};
	-- now we redo our correct order
	local currentIndex = 1;
	for i,v in pairs(self.availableSlot) do
		newSlots[currentIndex] = v;
		currentIndex = currentIndex + 1;
	end
	
	self.availableSlot = newSlots;
	
	-- we re attach out items, if we added a bag for example, we need to redo the correct attachment
	for i, item in pairs(self.attachedItems) do
		local slot = self.availableSlot[item:getAttachedSlot()];
		local slotDef = slot.def;
		local slotIndex = item:getAttachedSlot();
		self:removeItem(item, false, false);
		-- we get back what model it should be on, as it can change if we remove a replacement (have a bag + something on your back, remove bag, we need to get the original attached definition)
		if self.chr:getInventory():contains(item) and not item:isBroken() then
			self:attachItem(item, slotDef.attachments[item:getAttachmentType()], slotIndex, self:getSlotDef(slot.slotType), false);
		end
	end

	self:reloadIcons();
end

-- load our position to be sure everything stay the same and we don't attach something where it shouldn't
function NPCHotBar:loadPosition()
	local modData = self.chr:getModData();
	if modData["hotbar"] then
		for i,v in pairs(modData["hotbar"]) do
			local slotDef = self:getSlotDef(v);
			if slotDef then
				self.availableSlot[i] = {slotType = slotDef.type, name = slotDef.name, def = slotDef};
			end
		end
	else
		local slotDef = self:getSlotDef("Back");
		self.availableSlot[1] = {slotType = slotDef.type, name = slotDef.name, def = slotDef};
	end
end

function NPCHotBar:savePosition()
	local modData = self.chr:getModData();
	modData["hotbar"] = {};
	for i,v in pairs(self.availableSlot) do
		modData["hotbar"][i] = v.slotType;
	end
end


NPCHotBar.onClothingUpdated = function(player)
    if player:getModData().NPC then
        player:getModData().NPC.hotbar.needsRefresh = true
    end
end

function NPCHotBar:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.availableSlot = {};
	o.character = character;
	o.chr = character;
	o:loadPosition();
	o.attachedItems = {};
	o.needsRefresh = false
	o:refresh();
	return o;
end

local function OnGameStart()
	Events.OnClothingUpdated.Add(NPCHotBar.onClothingUpdated);
end

Events.OnGameStart.Add(OnGameStart);

