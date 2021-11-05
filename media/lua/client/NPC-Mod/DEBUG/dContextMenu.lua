
local function spawnCompanion(playerObj, square, preset, IsPlayerTeam)
    local npc = NPC:new(square, preset)
    if IsPlayerTeam then
        npc:setAI(PlayerGroupAI:new(npc.character))
    else
        npc:setAI(AutonomousAI:new(npc.character))
    end
end

local function reviveCompanion(playerObj, sq, name, id)
    NPC:load(id, sq:getX(), sq:getY(), sq:getZ(), true)
end

local function teleportToNPC(playerObj, npc)
    local pl = getPlayer()
    pl:setX(npc.character:getX())
    pl:setY(npc.character:getY())
    pl:setZ(npc.character:getZ())
end

local function spawnCompanionMenu(player, context, worldobjects, test)
	local sq = nil
    local playerObj = getSpecificPlayer(player)

    for i,v in ipairs(worldobjects) do
        local square = v:getSquare();
        if square then
            sq = square
            break
        end
    end
    
    if sq then
        local spawnMenuOption = context:addOption("DEBUG NPC", nil, nil)
        local subMenuSpawn = context:getNew(context)
        context:addSubMenu(spawnMenuOption, subMenuSpawn)

        subMenuSpawn:addOption("Spawn Random - Player team", playerObj, spawnCompanion, sq, NPCPresets_GetPreset(), true)
        subMenuSpawn:addOption("Spawn Random - Auto team", playerObj, spawnCompanion, sq, NPCPresets_GetPreset(), false)

        local deadOpt = subMenuSpawn:addOption("Revive dead NPC")
        local deadSubMenu = subMenuSpawn:getNew(subMenuSpawn)
        subMenuSpawn:addSubMenu(deadOpt, deadSubMenu)

        for name, id in pairs(NPCManager.deadNPCList) do
            deadSubMenu:addOption(name, playerObj, reviveCompanion, sq, name, id)
        end

        local teleportOpt = subMenuSpawn:addOption("Teleport to NPC")
        local teleportSubMenu = subMenuSpawn:getNew(subMenuSpawn)
        subMenuSpawn:addSubMenu(teleportOpt, teleportSubMenu)

        for i, char in ipairs(NPCManager.characters) do
            teleportSubMenu:addOption(char.character:getDescriptor():getSurname(), playerObj, teleportToNPC, char)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(spawnCompanionMenu);