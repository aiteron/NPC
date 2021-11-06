require "NPC-Mod/NPCGroupManager"

NPCManager = {}
NPCManager.characters = {}
NPCManager.vehicleSeatChoose = {}
NPCManager.vehicleSeatChooseSquares = {}
NPCManager.openInventoryNPC = nil
NPCManager.moodlesTimer = 0
NPCManager.characterMap = nil
NPCManager.deadNPCList = {}
NPCManager.loadedNPC = 0
NPCManager.spawnON = false
NPCManager.isSaveLoadUpdateOn = false

NPCManager.chooseSector = false
NPCManager.sector = nil

function NPCManager:OnTickUpdate()
    if getPlayer():isDead() then return end

    NPCManager.loadedNPC = 0
    for i, char in ipairs(NPCManager.characters) do
        char:update()

        if char.character:isDead() then
            local name = char.character:getDescriptor():getForename() .. " " .. char.character:getDescriptor():getSurname()
            if char.nickname then
                name = name .. "\"" .. char.nickname
            end

            NPCPrint("NPCManager", "NPC dead", name, char.UUID)

            NPCManager.deadNPCList[name] = char.UUID
            --
            NPCManager.characterMap[char.UUID] = nil
            table.remove(NPCManager.characters, i)  
            
            ---
            if char.isLeader then
                table.remove(NPCGroupManager.Groups[char.groupID].npc, tablefind(NPCGroupManager.Groups[char.groupID].npc, char.UUID))
                NPCGroupManager.Groups[char.groupID].count = NPCGroupManager.Groups[char.groupID].count - 1
                if NPCGroupManager.Groups[char.groupID].count <= 0 then
                    NPCGroupManager.Groups[char.groupID] = nil
                else
                    NPCGroupManager.Groups[char.groupID].leader = NPCGroupManager.Groups[char.groupID].npc[1]
                    NPCManager.characterMap[NPCGroupManager.Groups[char.groupID].leader].npc.isLeader = true
                    NPCPrint("NPCManager", "New leader of the group. GroupID:", char.groupID, NPCGroupManager.Groups[char.groupID].leader)
                end
            end
            return
        end
        NPCManager.loadedNPC = NPCManager.loadedNPC + 1 
        ---
        
    end

    NPCInsp("NPC", "NUM", NPCManager.loadedNPC)    

    if getPlayer():getSquare() ~= NPCManager.lastSaveSquare then
        NPCManager.isSaveLoadUpdateOn = true
    end
end
Events.OnTick.Add(NPCManager.OnTickUpdate)


local refreshBackpackTimer = 0
function NPCManager:InventoryUpdate()
    if getPlayer():isDead() then return end

    if refreshBackpackTimer <= 0 then
        refreshBackpackTimer = 60
        for i, char in ipairs(NPCManager.characters) do
            if not char.character:isDead() and char.AI:getType() == "PlayerGroupAI" then
                if NPCUtils.getDistanceBetween(char.character, getPlayer()) < 2 then
                    NPCManager.openInventoryNPC = char
                    ISPlayerData[1].lootInventory:refreshBackpacks()
                end
            end
        end
    else
        refreshBackpackTimer = refreshBackpackTimer - 1
    end
end
Events.OnTick.Add(NPCManager.InventoryUpdate)


NPCManager.hitPlayer = function(wielder, victim, weapon, damage)
    if instanceof(victim, "IsoPlayer") and victim:isNPC() then
        if wielder == getPlayer() and victim:getModData().NPC.AI:getType() == "PlayerGroupAI" then
            return
        else
            victim:getModData()["NPC"]:hitPlayer(wielder, weapon, damage)

            if ZombRand(0, 4) == 0 then
                if victim:getModData().NPC.reputationSystem.defaultReputation < 0 then
                    victim:getModData().NPC:Say(NPC_Dialogues.angryWarning[ZombRand(1, #NPC_Dialogues.angryWarning+1)], NPCColor.White)
                else
                    victim:getModData().NPC:Say(NPC_Dialogues.friendWarning[ZombRand(1, #NPC_Dialogues.friendWarning+1)], NPCColor.White)
                end
            end
                
        
            if wielder == getPlayer() then
                if victim:getModData().NPC.groupID ~= nil then
                    NPCManager.characterMap[NPCGroupManager:getLeaderOfGroup(victim:getModData().NPC.groupID)].npc.reputationSystem.playerRep = NPCManager.characterMap[NPCGroupManager:getLeaderOfGroup(victim:getModData().NPC.groupID)].npc.reputationSystem.playerRep - 500
                end
                victim:getModData().NPC.reputationSystem.playerRep = victim:getModData().NPC.reputationSystem.playerRep - 500
            else
                if victim:getModData().NPC.groupID ~= nil then
                    NPCManager.characterMap[NPCGroupManager:getLeaderOfGroup(victim:getModData().NPC.groupID)].npc.reputationSystem.reputationList[wielder:getModData().NPC.ID] = -500
                end
                victim:getModData().NPC.reputationSystem.reputationList[wielder:getModData().NPC.ID] = -500
            end
        end
	end
end
Events.OnWeaponHitCharacter.Add(NPCManager.hitPlayer)

NPCManager.onEnterVehicle = function(player)
    if player == getPlayer() then
        NPCManager.vehicleSeatChoose = {}
        NPCManager.vehicleSeatChooseSquares = {}
    end
end
Events.OnEnterVehicle.Add(NPCManager.onEnterVehicle)

NPCManager.onSwing = function(player, weapon)
    if player:getModData()["NPC"] ~= nil then
        local range = weapon:getSoundRadius() 
        local volume = weapon:getSoundVolume()
        addSound(player, player:getX(), player:getY(), player:getZ(), range, volume)
        getSoundManager():PlayWorldSound(weapon:getSwingSound(), player:getCurrentSquare(), 0.5, range, 1.0, false)    
    end
end
Events.OnWeaponSwing.Add(NPCManager.onSwing)

NPCManager.choosingStaySquare = false
NPCManager.choosingStayNPC = nil
NPCManager.highlightSquare = function()
    if NPCManager.choosingStaySquare then
        local z = getPlayer():getZ()
        local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
        local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
        if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
    end
    if NPCManager.chooseSector then
        if NPCManager.sector == nil then
            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
            local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
            if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
        else
            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)

            local t = nil
            local a = math.floor(x)
            local b = math.floor(NPCManager.sector.x1)
            if a > b then
                t = a
                a = b
                b = t                
            end
            
            local c = math.floor(y)
            local d = math.floor(NPCManager.sector.y1)
            if c > d then
                t = c
                c = d
                d = t                
            end

            for xx = a, b do
                for yy = c, d do
                    local sq = getCell():getGridSquare(xx, yy, z)
                    if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end        
                end
            end
        end
    end
end
Events.OnRenderTick.Add(NPCManager.highlightSquare)

NPCManager.onMouseDown = function()
    if NPCManager.choosingStaySquare then
        if NPCManager.choosingStayNPC then
            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
            local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
            if sq then
                NPCManager.choosingStayNPC.AI.staySquare = sq
                NPCManager.choosingStayNPC.AI.command = "STAY"
                NPCManager.choosingStayNPC = nil
            end
        end
        NPCManager.choosingStaySquare = false
    end

    if NPCManager.chooseSector then
        if NPCManager.sector == nil then
            NPCManager.sector = {}
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
            NPCManager.sector.x1 = x
            NPCManager.sector.y1 = y    
        else
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
            NPCManager.sector.x2 = x
            NPCManager.sector.y2 = y  

            if NPCManager.sector.x1 > NPCManager.sector.x2 then
                local t = NPCManager.sector.x1
                NPCManager.sector.x1 = NPCManager.sector.x2
                NPCManager.sector.x2 = t
            end
            if NPCManager.sector.y1 > NPCManager.sector.y2 then
                local t = NPCManager.sector.y1
                NPCManager.sector.y1 = NPCManager.sector.y2
                NPCManager.sector.y2 = t
            end
            
            NPCManager.chooseSector = false

            if NPCManager.isBaseChoose then
                NPCGroupManager.playerBase.x1 = NPCManager.sector.x1
                NPCGroupManager.playerBase.y1 = NPCManager.sector.y1
                NPCGroupManager.playerBase.x2 = NPCManager.sector.x2
                NPCGroupManager.playerBase.y2 = NPCManager.sector.y2
                NPCManager.isBaseChoose = false
            end

            if NPCManager.isDropLootChoose then
                NPCGroupManager.dropLoot[NPCManager.isDropLootType] = {x1 = NPCManager.sector.x1, y1 = NPCManager.sector.y1, x2 = NPCManager.sector.x2, y2 = NPCManager.sector.y2, z = getPlayer():getZ()}
            end
        end
    end
end
Events.OnMouseDown.Add(NPCManager.onMouseDown)



local tempTransferFunc = ISInventoryTransferAction.start
function ISInventoryTransferAction:start()
    if self.character:getModData().NPC then
        self.character:getModData().NPC:SayNote("*transfer " .. self.item:getName() .. "*", NPCColor.transferItem)
    end
    tempTransferFunc(self)
end

local tempTrasferPerfFunc = ISInventoryTransferAction.perform
function ISInventoryTransferAction:perform()
    tempTrasferPerfFunc(self)
    for i, char in ipairs(NPCManager.characters) do
        if NPCUtils.getDistanceBetween(char.character, getPlayer()) < 30 then
            table.insert(ScanSquaresSystem.nearbyItems.containers, self.destContainer)
            char.AI.EatTaskTimer = 0
            char.AI.DrinkTaskTimer = 0
        end
    end
end

local tempGrabFunc = ISGrabItemAction.start
function ISGrabItemAction:start()
    if self.character:getModData().NPC then
        self.character:getModData().NPC:Say("*transfer " .. self.item:getItem():getName() .. "*", NPCColor.transferItem)
    end
    tempGrabFunc(self)
end


NPCManager.zombiesDangerByXYZ = {}
NPCManager.updateZombieDangerSectorsTimer = 0
NPCManager.updateZombieDangerSectors = function()
    if NPCManager.updateZombieDangerSectorsTimer <= 0 then
        NPCManager.updateZombieDangerSectorsTimer = 500

        NPCManager.zombiesDangerByXYZ = {}
        
        local enemies = {}
        local objects = getPlayer():getCell():getObjectList()
        if(objects ~= nil) then
            for i=0, objects:size()-1 do
                local obj = objects:get(i);
                if obj ~= nil and instanceof(obj,"IsoZombie") and not obj:isDead() then    
                    enemies[obj] = true
                end
            end
        end

        for zomb, _ in pairs(enemies) do
            local counter = 0
            for zomb2, _ in pairs(enemies) do
                if zomb ~= zomb2 and zomb:getZ() == zomb2:getZ() and NPCUtils.getDistanceBetween(zomb, zomb2) < 3 then
                    counter = counter + 1
                end
                if counter >= 2 then break end
            end
            if counter >= 2 then
                local x = zomb:getSquare():getX()
                local y = zomb:getSquare():getY()
                local z = zomb:getSquare():getZ()
                for i=-2, 2 do
                    for j=-2, 2 do
                        NPCManager.zombiesDangerByXYZ["X" .. tostring(x+i) .. "Y" .. tostring(y+j) .. "Z" .. tostring(z)] = true
                    end
                end
            end
        end
    else
        NPCManager.updateZombieDangerSectorsTimer = NPCManager.updateZombieDangerSectorsTimer - 1
    end 
end
Events.OnTick.Add(NPCManager.updateZombieDangerSectors)

function NPCManager.LoadGrid(square)
    if NPCManager.spawnON and square:getZ() == 0 and square:getZoneType() == "TownZone" and not square:isSolid() and square:isFree(false) and ZombRand(1200) == 0 and NPCManager.loadedNPC < NPCConfig.config["NPC_NUM"] then
        local npc = NPC:new(square, NPCPresets_GetPreset(NPCPresets))
        npc:setAI(AutonomousAI:new(npc.character))

        NPCManager.loadedNPC = NPCManager.loadedNPC + 1
    end
end
Events.LoadGridsquare.Add(NPCManager.LoadGrid)

function NPCManager.LoadGridNewRooms(square)
    local id = square:getRoomID()
    if id ~= -1 and square:getZ() == 0 then
        id = square:getBuilding():getID()
        if NPC_InterestPointMap.Rooms[id] ~= nil then
            NPC_InterestPointMap.Rooms[id].x = (NPC_InterestPointMap.Rooms[id].x + square:getX())/2.0
            NPC_InterestPointMap.Rooms[id].y = (NPC_InterestPointMap.Rooms[id].y + square:getY())/2.0
        else
            NPC_InterestPointMap.Rooms[id] = {x = square:getX(), y = square:getY()}
        end
    end
end
Events.LoadGridsquare.Add(NPCManager.LoadGridNewRooms)

function NPCManager.SaveLoadFunc()
    if NPCManager.isSaveLoadUpdateOn == false then return end

    for charID, value in pairs(NPCManager.characterMap) do
        if value.isSaved == false then
            if NPCUtils.getDistanceBetween(getPlayer(), value.npc.character) > 60 then
                value.x = value.npc.character:getX()
                value.y = value.npc.character:getY()
                value.z = value.npc.character:getZ()

                value.npc:save()
                value.isSaved = true

                NPCPrint("NPCManager", "NPC is saved (SaveLoadFunc)", charID, value.npc.character:getDescriptor():getSurname())
            end
        end

        if value.isLoaded == false then
            if NPCUtils.getDistanceBetweenXYZ(value.x, value.y, getPlayer():getX(), getPlayer():getY()) < 60 and getCell():getGridSquare(value.x, value.y, 0) ~= nil then
                for i, char in ipairs(NPCManager.characters) do
                    if value.npc and char.UUID == value.npc.UUID then
                        table.remove(NPCManager.characters, i)            
                    end
                end
                value.npc = NPC:load(charID, value.x, value.y, value.z, false)
                value.isLoaded = true
                value.isSaved = false
                NPCPrint("NPCManager", "NPC is loaded (SaveLoadFunc)", charID, value.npc.character:getDescriptor():getSurname())
            end
        end

        if value.isLoaded == true and getCell():getGridSquare(value.npc.character:getX(), value.npc.character:getY(), 0) == nil then
            value.isLoaded = false
            for i, char in ipairs(NPCManager.characters) do
                if char.UUID == value.npc.UUID then
                    table.remove(NPCManager.characters, i)            
                end
            end
            NPCPrint("NPCManager", "NPC is unloaded (SaveLoadFunc)", charID)
        end
    end
end
Events.OnTick.Add(NPCManager.SaveLoadFunc)


function NPCManager.OnSave()
    for charID, value in pairs(NPCManager.characterMap) do
            value.x = value.npc.character:getX()
            value.y = value.npc.character:getY()
            value.z = value.npc.character:getZ()

            value.npc:save()
            value.isSaved = true

            NPCPrint("NPCManager", "NPC is saved (OnSave)", charID, value.npc.character:getDescriptor():getSurname())
    end

    NPCManager.isSaveLoadUpdateOn = false
    NPCManager.lastSaveSquare = getPlayer():getSquare()
end
Events.OnSave.Add(NPCManager.OnSave)

function NPCManager.OnLoad() 
end
Events.OnLoad.Add(NPCManager.OnLoad)

function NPCManager.OnGameStart()
    NPCPrint("NPCManager", "OnGameStart", "v.0.1.7")

    for charID, value in pairs(NPCManager.characterMap) do
        value.isLoaded = false
        if value.isLoaded == false and getCell():getGridSquare(value.x, value.y, value.z) ~= nil then
            value.npc = NPC:load(charID, value.x, value.y, value.z, false)
            value.isLoaded = true
            value.isSaved = false
                        
            if value.npc.character:getSquare() == nil then
                value.isLoaded = false
                for i, char in ipairs(NPCManager.characters) do
                    if char.UUID == value.npc.UUID then
                        table.remove(NPCManager.characters, i)            
                    end
                end
            else
                NPCPrint("NPCManager", "NPC is loaded (OnGameStart)", charID, value.npc.character:getDescriptor():getSurname()) 
            end
        end
    end
    NPCManager.spawnON = true
    NPCManager.isSaveLoadUpdateOn = true
end
Events.OnGameStart.Add(NPCManager.OnGameStart)

function NPCManager.LoadGlobalModData()
    NPCManager.characterMap = ModData.getOrCreate("characterMap")

    NPCGroupManager.Groups = ModData.getOrCreate("NPCGroups")
    NPCGroupManager.playerBase = ModData.getOrCreate("NPCPlayerBase")
    NPCGroupManager.dropLoot = ModData.getOrCreate("NPCDropLoot")

    MeetSystem.Data = ModData.getOrCreate("MeetSystemData")
end

Events.OnInitGlobalModData.Add(NPCManager.LoadGlobalModData)