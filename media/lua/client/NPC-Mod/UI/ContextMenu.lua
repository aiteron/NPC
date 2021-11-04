local items = {
    "Revolver",
    "Bullets45",
    "AssaultRifle",
    "556Clip",
    "556Bullets",
    "Axe",
    "Shotgun",
    "ShotgunShells"
}

local function giveItem(playerObj, character, weaponName, count)
    character:getInventory():AddItems("Base."..weaponName, count)
end

local function Kill(playerObj, character)
    character:Kill(character)
end


local function NPCContextMenu(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local clickedPlayer = nil
    local sq = nil

    for i, v in ipairs(worldobjects) do
        local square = v:getSquare();
        if square then
            sq = square
            break
        end
    end

    if sq then
        for x=sq:getX()-1, sq:getX()+1 do
            for y=sq:getY()-1, sq:getY()+1 do
                local sq2 = getCell():getGridSquare(x, y, sq:getZ());
				if sq2 then
                    for i=0,sq2:getMovingObjects():size()-1 do
                        if instanceof(sq2:getMovingObjects():get(i), "IsoPlayer") and playerObj ~= sq2:getMovingObjects():get(i) then
                            clickedPlayer = sq2:getMovingObjects():get(i)
                        end
                    end
                end
            end
        end
    end

    if clickedPlayer then
        local npcMenuOption = context:addOption("NPC")
        local subMenuNpc = context:getNew(context)
        context:addSubMenu(npcMenuOption, subMenuNpc)
        
        -- Give Item
        local giveItemOption = subMenuNpc:addOption("Give Item")
        local subMenuGiveItem = subMenuNpc:getNew(subMenuNpc)
        subMenuNpc:addSubMenu(giveItemOption, subMenuGiveItem)

        for _, name in ipairs(items) do
            local itemOption = subMenuGiveItem:addOption(name)
            local subMenuItem = subMenuGiveItem:getNew(subMenuGiveItem)
            subMenuGiveItem:addSubMenu(itemOption, subMenuItem)

            subMenuItem:addOption("1", playerObj, giveItem, clickedPlayer, name, 1)
            subMenuItem:addOption("5", playerObj, giveItem, clickedPlayer, name, 5)
            subMenuItem:addOption("10", playerObj, giveItem, clickedPlayer, name, 10)
            subMenuItem:addOption("20", playerObj, giveItem, clickedPlayer, name, 20)
        end

        -- Kill
        subMenuNpc:addOption("Kill", playerObj, Kill, clickedPlayer)
    end

    
end

Events.OnFillWorldObjectContextMenu.Add(NPCContextMenu);