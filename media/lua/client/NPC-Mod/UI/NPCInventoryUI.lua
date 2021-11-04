local function checkDistToNPCInventory()
    if NPCManager.openInventoryNPC == nil then return end
    if NPCUtils.getDistanceBetween(getPlayer(), NPCManager.openInventoryNPC.character) > 2 then
        NPCManager.openInventoryNPC = nil
    end
end

Events.OnTick.Add(checkDistToNPCInventory)

local function addNPCInv(page, step)
    if page == ISPlayerData[1].lootInventory and step == "buttonsAdded" then
        if NPCManager.openInventoryNPC then
            local char = NPCManager.openInventoryNPC.character

            ISPlayerData[1].lootInventory:addContainerButton(char:getInventory(), getTexture("media/textures/NPC_Icon.png"), "NPC", nil)

            local it = char:getInventory():getItems()
            for i = 0, it:size()-1 do
                local item = it:get(i)
                if item:getCategory() == "Container" and char:isEquipped(item) or item:getType() == "KeyRing" then
                    local containerButton = ISPlayerData[1].lootInventory:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                    if(item:getVisual() and item:getClothingItem()) then
                        local tint = item:getVisual():getTint(item:getClothingItem());
                        containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
                    end
                end
            end
        end
    end

    
end

Events.OnRefreshInventoryWindowContainers.Add(addNPCInv)


local function NPCDrop(char, items)
    local container = ItemContainer.new("floor", nil, nil, 10, 10)
    container:setExplored(true)
    for _, item in ipairs(items) do     
        if char:isEquipped(item) then
            ISTimedActionQueue.add(ISUnequipAction:new(char, item, 50));
        end
        ISTimedActionQueue.add(ISInventoryTransferAction:new(char, item, item:getContainer(), container))
    end
end

local function NPCUnequip(char, items)
    for _, item in ipairs(items) do     
        if item == char:getModData().NPC.forcePrimaryItem then
            char:getModData().NPC.forcePrimaryItem = nil
        end
        if item == char:getModData().NPC.forceSecondaryItem then
            char:getModData().NPC.forceSecondaryItem = nil
        end
        if item == char:getModData().NPC.forceTwoArmsItem then
            char:getModData().NPC.forceTwoArmsItem = nil
        end

        ISTimedActionQueue.add(ISUnequipAction:new(char, item, 50));
    end
end

local function NPCWear(char, item, items)
    for i, item1 in ipairs(items) do
        if not char:isEquipped(item1) and item1:getCategory() == "Clothing" then
            ISTimedActionQueue.add(ISWearClothing:new(char, item1, 50));
        end
    end
end

local function NPCEquipBack(char, item)
    ISTimedActionQueue.add(ISWearClothing:new(char, item, 50));
end

local function NPCEquipWeapon(char, item, primary, twohands)
    if twohands then
        char:getModData().NPC.forceTwoArmsItem = item
    elseif primary then
        char:getModData().NPC.forcePrimaryItem = item
    else
        char:getModData().NPC.forceSecondaryItem = item
    end

    if twohands then
        if char:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(char, char:getPrimaryHandItem(), 50));
        end
        if char:getSecondaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(char, char:getSecondaryHandItem(), 50));
        end
        ISInventoryPaneContextMenu.transferIfNeeded(char, item)
        ISTimedActionQueue.add(ISEquipWeaponAction:new(char, item, 50, primary, twohands));
    else
        if primary then
            if char:getPrimaryHandItem() then
                ISTimedActionQueue.add(ISUnequipAction:new(char, char:getPrimaryHandItem(), 50));
            end
            ISInventoryPaneContextMenu.transferIfNeeded(char, item)
            ISTimedActionQueue.add(ISEquipWeaponAction:new(char, item, 50, primary, twohands));
        else
            if char:getSecondaryHandItem() then
                ISTimedActionQueue.add(ISUnequipAction:new(char, char:getSecondaryHandItem(), 50));
            end
            ISInventoryPaneContextMenu.transferIfNeeded(char, item)
            ISTimedActionQueue.add(ISEquipWeaponAction:new(char, item, 50, primary, twohands));
        end
    end



    if char:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(char, char:getPrimaryHandItem(), 50));
    end
    ISInventoryPaneContextMenu.transferIfNeeded(char, item)
    ISTimedActionQueue.add(ISEquipWeaponAction:new(char, item, 50, primary, twohands));
end


local function getWornItemInLocation(playerObj, location)
    local wornItems = playerObj:getWornItems()
    local bodyLocationGroup = wornItems:getBodyLocationGroup()
    for i=1,wornItems:size() do
        local wornItem = wornItems:get(i-1)
        if (wornItem:getLocation() == location) or bodyLocationGroup:isExclusive(wornItem:getLocation(), location) then
            return wornItem:getItem()
        end
    end
    return nil
end

local function NPCContext(player, context, items)
    if not NPCManager.openInventoryNPC then
        return
    end
    
    local char = NPCManager.openInventoryNPC.character
    items = ISInventoryPane.getActualItems(items)

    local clothing = nil
    local backItem = nil
    local bothHandsItem = nil
    local primaryHandItem = nil
    local secondaryHandItem = nil
    local uneqipItem = nil
    local hairDye = nil
    local itemExtraOption = nil

    for _, item in ipairs(items) do 
        if char:getInventory() ~= item:getOutermostContainer() then return end

        if item:isHairDye() then
            hairDye = item;
        end

        -- Fanny pack and other extra context items
        if item:getClothingItemExtraOption() then
            itemExtraOption = item
        end

        if not char:isEquipped(item) then
            if item:getCategory() == "Clothing" then
                  clothing = item
            elseif instanceof(item, "InventoryContainer") and item:canBeEquipped() == "Back" then
                 backItem = item
            end

            if item:isTwoHandWeapon() and item:getCondition() > 0 and not char:isItemInBothHands(item) then
                bothHandsItem = item
            end
            if (instanceof(item, "HandWeapon") and item:getCondition() > 0) or (instanceof(item, "InventoryItem") and not instanceof(item, "HandWeapon")) then
                primaryHandItem = item
            end
            if (instanceof(item, "HandWeapon") and item:getCondition() > 0) or (instanceof(item, "InventoryItem") and not instanceof(item, "HandWeapon")) then
                secondaryHandItem = item
            end

        else
            uneqipItem = item
        end

        NPCHotBar.doMenuFromInventory(char, item, context);
    end

    if itemExtraOption then
        local context2
        if (itemExtraOption:IsClothing() or itemExtraOption:IsInventoryContainer()) and itemExtraOption:getClothingExtraSubmenu() then
            local option = context:addOption("NPC: " .. getText("ContextMenu_Wear"));
            local subMenu = context:getNew(context);
            context:addSubMenu(option, subMenu);
            context2 = subMenu;
    
            local location = itemExtraOption:IsClothing() and itemExtraOption:getBodyLocation() or itemExtraOption:canBeEquipped()
            local existingItem = getWornItemInLocation(char, location)
            if existingItem ~= itemExtraOption then
                local text = getText("ContextMenu_" .. itemExtraOption:getClothingExtraSubmenu());
                local option = context2:addOption(text, itemExtraOption, ISInventoryPaneContextMenu.onClothingItemExtra, itemExtraOption:getType(), char);
                ISInventoryPaneContextMenu.doWearClothingTooltip(char, itemExtraOption, itemExtraOption, option);
            end
        end
    
        for i=0,itemExtraOption:getClothingItemExtraOption():size()-1 do
            local text = getText("ContextMenu_" .. itemExtraOption:getClothingItemExtraOption():get(i));
            local itemType = moduleDotType(itemExtraOption:getModule(), itemExtraOption:getClothingItemExtra():get(i));
            local item = ISInventoryPaneContextMenu.getItemInstance(itemType);
            local option = context2:addOption(text, itemExtraOption, ISInventoryPaneContextMenu.onClothingItemExtra, itemType, char);
            ISInventoryPaneContextMenu.doWearClothingTooltip(char, item, itemExtraOption, option);
        end
    end

    if clothing then
        context:addOption("NPC: Wear", char, NPCWear, clothing, items)
    elseif backItem then
        context:addOption("NPC: Equip on back", char, NPCEquipBack, backItem)    
    end

    if hairDye and char:getHumanVisual():getHairModel() and char:getHumanVisual():getHairModel() ~= "Bald" then
        context:addOption("NPC Dye hair", hairDye, ISInventoryPaneContextMenu.onDyeHair, char, false);
    end
    if hairDye and char:getHumanVisual():getBeardModel() and char:getHumanVisual():getBeardModel() ~= "" then
        context:addOption("NPC Dye beard", hairDye, ISInventoryPaneContextMenu.onDyeHair, char, true);
    end

    if bothHandsItem then
        context:addOption("NPC: Equip in Both hands", char, NPCEquipWeapon, bothHandsItem, true, true)     
    end

    if primaryHandItem then
        context:addOption("NPC: Equip primary", char, NPCEquipWeapon, primaryHandItem, true, false)    
    end

    if secondaryHandItem then
        context:addOption("NPC: Equip secondary", char, NPCEquipWeapon, secondaryHandItem, false, false)    
    end

    context:addOption("NPC: Drop", char, NPCDrop, items) 
    
    if uneqipItem then
        context:addOption("NPC: Unequip", char, NPCUnequip, items) 
    end

end

Events.OnFillInventoryObjectContextMenu.Add(NPCContext)


local temp2 = ISInventoryPaneContextMenu.dropItem
ISInventoryPaneContextMenu.dropItem = function(item, player)
    if not NPCManager.openInventoryNPC then
        temp2(item, player)
        return
    end

    local char = NPCManager.openInventoryNPC.character
    if char:getInventory():containsRecursive(item) then
        local container = ItemContainer.new("floor", nil, nil, 10, 10)
        container:setExplored(true)
        ISTimedActionQueue.add(ISInventoryTransferAction:new(char, item, item:getContainer(), container))
    else
        temp2(item, player)
    end    
end

local temp = ISInventoryPane.transferItemsByWeight
function ISInventoryPane:transferItemsByWeight(items, container)
    if not NPCManager.openInventoryNPC then
        temp(self, items, container)
        return
    end

    local char = NPCManager.openInventoryNPC.character
    if char:getInventory():containsRecursive(items[1]) then
        for i, item in ipairs(items) do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(char, item, item:getContainer(), container))
        end
    else
        temp(self, items, container)
    end
end

local temp3 = ISInventoryPaneContextMenu.transferItems
ISInventoryPaneContextMenu.transferItems = function(items, playerInv, player, dontWalk)
    if not NPCManager.openInventoryNPC then
        temp3(items, playerInv, player, dontWalk)
        return
    end

    items = ISInventoryPane.getActualItems(items)
    local char = NPCManager.openInventoryNPC.character
    if char:getInventory():containsRecursive(items[1]) then
        for i, item in ipairs(items) do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(char, item, item:getContainer(), playerInv))
        end
    else
        temp3(items, playerInv, player, dontWalk)
    end
end

local temp4 = ISInventoryPaneContextMenu.onGrabHalfItems
ISInventoryPaneContextMenu.onGrabHalfItems = function(items, player)
    if not NPCManager.openInventoryNPC then
        temp4(items, player)
        return
    end

    items = ISInventoryPane.getActualItems(items)
    local char = NPCManager.openInventoryNPC.character
    if char:getInventory():containsRecursive(items[1]) then
        local countNeed = #items/2
        local count = 0
        for i, k in ipairs(items) do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(char, k, k:getContainer(), getPlayerInventory(player).inventory))
            count = count + 1
            if count >= countNeed then return end
        end
    else
        temp4(items, player)
    end
end

local temp5 = ISInventoryPaneContextMenu.onGrabOneItems
ISInventoryPaneContextMenu.onGrabOneItems = function(items, player)
    if not NPCManager.openInventoryNPC then
        temp5(items, player)
        return
    end

    items = ISInventoryPane.getActualItems(items)
    local char = NPCManager.openInventoryNPC.character
    if char:getInventory():containsRecursive(items[1]) then
        for i, item in ipairs(items) do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(char, item, item:getContainer(), getPlayerInventory(player).inventory))
            return
        end
    else
        temp5(items, player)
    end
end

local temp6 = ISInventoryPaneContextMenu.wearItem
ISInventoryPaneContextMenu.wearItem = function(item, player)
    if not NPCManager.openInventoryNPC then
        temp6(item, player)
        return
    end

    local char = NPCManager.openInventoryNPC.character
    if item:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(char, item, 50));
    else
        temp6(item, player)
    end
end

local temp7 = ISInventoryPaneContextMenu.onInspectClothing
ISInventoryPaneContextMenu.onInspectClothing = function(playerObj, clothing)
    if not NPCManager.openInventoryNPC then
        temp7(playerObj, clothing)
        return
    end

    local char = NPCManager.openInventoryNPC.character
    if clothing:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(char, clothing, 50));
    else
        temp7(playerObj, clothing)
    end
end
