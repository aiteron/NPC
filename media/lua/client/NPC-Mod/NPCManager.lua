require "NPC-Mod/NPCGroupManager"

local BUILD_VERSION = "v.0.1.15"

NPCManager = {}
NPCManager.characters = {}
NPCManager.vehicleSeatChoose = {}
NPCManager.vehicleSeatChooseSquares = {}
NPCManager.openInventoryNPC = nil
NPCManager.moodlesTimer = 0
NPCManager.characterMap = nil
NPCManager.deadNPCList = {}
NPCManager.NPCInRadius = 0
NPCManager.spawnON = false
NPCManager.isSaveLoadUpdateOn = false

NPCManager.chooseSector = false
NPCManager.sector = nil

NPCManager.pvpTurnOffTimer = 0
NPCManager.pvpTurnedOn = false

function NPCManager:OnTickUpdate()
    if getPlayer():isDead() then return end

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
            if NPCGroupManager:getGroupID(char.UUID) ~= nil then
                NPCGroupManager:removeFromGroup(char.UUID)
            return
            end
        end
        ---
        
    end
    --NPCPrint("NPCManager", "FPS:", getAverageFPS())  
    NPCInsp("NPC", "NPC count", NPCManager.NPCInRadius)

    if getPlayer():getSquare() ~= NPCManager.lastSaveSquare then
        NPCManager.isSaveLoadUpdateOn = true
    end

    ---
    if NPCManager.pvpTurnOffTimer <= 0 then
        if IsoPlayer.getCoopPVP() and not NPCManager.pvpTurnedOn then
            IsoPlayer.setCoopPVP(false)
        end
    else
        NPCManager.pvpTurnOffTimer = NPCManager.pvpTurnOffTimer - 1
    end
end
Events.OnTick.Add(NPCManager.OnTickUpdate)

local refreshBackpackTimer = 0
function NPCManager:InventoryUpdate()
    if getPlayer():isDead() then return end

    if refreshBackpackTimer <= 0 then
        refreshBackpackTimer = 60
        for i, char in ipairs(NPCManager.characters) do
            if not char.character:isDead() and (char.AI:getType() == "PlayerGroupAI" or char.isRobbed) then
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
            victim:getModData()["NPC"].reputationSystem:updatePlayerRep(-200)
            victim:getModData()["NPC"]:SayNote("Reputation [img=media/ui/ArrowDown.png]", NPCColor.Red)

            if NPCGroupManager:getGroupID(victim:getModData()["NPC"].UUID) ~= nil then
                if NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(victim:getModData()["NPC"].UUID))] and NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(victim:getModData()["NPC"].UUID))].isLoaded then
                    local npc = NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(victim:getModData()["NPC"].UUID)))
                    if npc ~= nil then
                        npc.reputationSystem:updatePlayerRep(-50)
                        npc:SayNote("Reputation [img=media/ui/ArrowDown.png]", NPCColor.Red)
                    end
                end
            end

            if ZombRand(0, 4) == 0 then
                if victim:getModData().NPC.reputationSystem.defaultReputation < 0 then
                    victim:getModData().NPC:Say(NPC_Dialogues.angryWarning[ZombRand(1, #NPC_Dialogues.angryWarning+1)], NPCColor.White)
                else
                    victim:getModData().NPC:Say(NPC_Dialogues.friendWarning[ZombRand(1, #NPC_Dialogues.friendWarning+1)], NPCColor.White)
                end
            end
                
        
            if wielder == getPlayer() then
                if NPCGroupManager:getGroupID(victim:getModData().NPC.UUID) ~= nil then
                    local npc = NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(victim:getModData().NPC.UUID)))
                    if npc ~= nil then
                        npc.reputationSystem.playerRep = npc.reputationSystem.playerRep - 500
                    end
                end
                victim:getModData().NPC.reputationSystem.playerRep = victim:getModData().NPC.reputationSystem.playerRep - 500
            else
                if NPCGroupManager:getGroupID(victim:getModData().NPC.UUID) ~= nil then
                    local char = NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(victim:getModData().NPC.UUID)))
                    if char ~= nil then
                        char.reputationSystem.reputationList[wielder:getModData().NPC.ID] = -500
                    end
                end
                victim:getModData().NPC.reputationSystem.reputationList[wielder:getModData().NPC.ID] = -500
            end
        end
	end
end
Events.OnWeaponHitCharacter.Add(NPCManager.hitPlayer)

local lastHittedZombie = nil
NPCManager.hitZombie = function(wielder, victim, weapon, damage)
    if instanceof(victim, "IsoZombie") and wielder == getPlayer() then
        lastHittedZombie = victim
    end
end
Events.OnWeaponHitCharacter.Add(NPCManager.hitZombie)

NPCManager.killZombie = function(zombie)
    if zombie == lastHittedZombie then
        for i, char in ipairs(NPCManager.characters) do
            if NPCUtils.getDistanceBetween(char.character, getPlayer()) < 10 then
                char.reputationSystem:updatePlayerRep(5)
                char:SayNote("Reputation [img=media/ui/ArrowUp.png]", NPCColor.Green)
            end
        end    
    end
end
Events.OnZombieDead.Add(NPCManager.killZombie)

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

function ISInventoryTransferAction:perform()
	-- I would have done this in start(), however the first action added to the queue
	-- is started immediately, before any other actions can be added.
	self:checkQueueList()

	self.item:setJobDelta(0.0)
--	print("perform on item", self.item, self.item:getDisplayName())
	-- take the next item in our queue list
	local queuedItem = table.remove(self.queueList, 1);
	-- reopen the correct container
	if self.selectedContainer and self.character == getPlayer() then
		getPlayerLoot(self.character:getPlayerNum()):selectButtonForContainer(self.selectedContainer)
	end

	for i,item in ipairs(queuedItem.items) do
		self.item = item
		-- Check destination container capacity and item-count limit.
		if not self:isValid() then
			self.queueList = {}
			break
		end
		self:transferItem(item);
	end
	-- if we still have other item to transfer in our queue list, we "reset" the action
	if #self.queueList > 0 then
		queuedItem = self.queueList[1]
		self.item = queuedItem.items[1];
--		print("reset with new item: ", queuedItem.items[1], #queuedItem.items)
		local time = queuedItem.time;
		if self:isAlreadyTransferred(self.item) then
			time = 0
		end
		self.maxTime = time
		self.action:setTime(tonumber(time))
		self:resetJobDelta();
		self:startActionAnim()
	else
		self.action:stopTimedActionAnim();
		self.action:setLoopedAction(false);

		if self.onCompleteFunc then
			local args = self.onCompleteArgs
			self.onCompleteFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
		end

		-- needed to remove from queue / start next.
		ISBaseTimedAction.perform(self);
	end

	if instanceof(self.item, "Radio") then
		self.character:updateEquippedRadioFreq();
	end

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

function NPCManager.LoadGrid(square)
    if NPCManager.spawnON and square:getZ() == 0 and square:getZoneType() == "TownZone" and not square:isSolid() and square:isFree(false) and ZombRand(5000) == 0 and NPCManager.NPCInRadius < NPCConfig.config["NPC_NUM"] then
        local npc = NPC:new(square, NPCPresets_GetPreset(NPCPresets))
        npc:setAI(AutonomousAI:new(npc.character))

        NPCManager.NPCInRadius = NPCManager.NPCInRadius + 1
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
        if value.npc == nil then
            value.isSaved = true
            value.isLoaded = false
        end

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
            value.npc = nil
            NPCPrint("NPCManager", "NPC is unloaded (SaveLoadFunc)", charID)
        end
    end
end
Events.OnTick.Add(NPCManager.SaveLoadFunc)


function NPCManager.OnSave()
    for charID, value in pairs(NPCManager.characterMap) do
        if value.npc ~= nil then
            value.x = value.npc.character:getX()
            value.y = value.npc.character:getY()
            value.z = value.npc.character:getZ()

            value.npc:save()
            value.isSaved = true
            
            NPCPrint("NPCManager", "NPC is saved (OnSave)", charID, value.npc.character:getDescriptor():getSurname())

            value.npc = nil
        end
    end

    NPCManager.isSaveLoadUpdateOn = false
    NPCManager.lastSaveSquare = getPlayer():getSquare()
end
Events.OnSave.Add(NPCManager.OnSave)

function NPCManager.OnLoad() 
end
Events.OnLoad.Add(NPCManager.OnLoad)

function NPCManager.OnGameStart()
    NPCPrint("NPCManager", "OnGameStart", BUILD_VERSION)

    IsoPlayer.setCoopPVP(false)

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

    NPCGroupManager.Data = ModData.getOrCreate("NPCGroups")
    if NPCGroupManager.Data.leaders == nil then
        NPCGroupManager.Data.leaders = {}   -- playerUUID = GroupUUID
        NPCGroupManager.Data.groups = {}    -- GroupUUID = {count, leader, {npcIDs}}
        NPCGroupManager.Data.characterGroup = {} -- playerUUID = GroupID
    end


    NPCGroupManager.playerBase = ModData.getOrCreate("NPCPlayerBase")
    NPCGroupManager.dropLoot = ModData.getOrCreate("NPCDropLoot")

    MeetSystem.Data = ModData.getOrCreate("MeetSystemData")
end
Events.OnInitGlobalModData.Add(NPCManager.LoadGlobalModData)

local countInRadiusNPCTimer = 0
function NPCManager.CountNPCInRadius()
    if countInRadiusNPCTimer <= 0 then
        countInRadiusNPCTimer = 60
        NPCManager.NPCInRadius = 0
        local x = getPlayer():getX()
        local y = getPlayer():getY()
        for _, value in pairs(NPCManager.characterMap) do
            if value.isLoaded then
                if NPCUtils.getDistanceBetweenXYZ(value.npc.character:getX(), value.npc.character:getY(), x, y) < 120 then
                    NPCManager.NPCInRadius = NPCManager.NPCInRadius + 1
                end 
            else
                if NPCUtils.getDistanceBetweenXYZ(value.x, value.y, x, y) < 120 then
                    NPCManager.NPCInRadius = NPCManager.NPCInRadius + 1
                end
            end
        end
    else
        countInRadiusNPCTimer = countInRadiusNPCTimer - 1
    end
end
Events.OnTick.Add(NPCManager.CountNPCInRadius)


function NPCManager:getCharacter(id)
    if NPCManager.characterMap[id] == nil then return nil end
    return NPCManager.characterMap[id].npc
end

local pointTimer = 0
function NPCManager:showNamesByMousePoint()
    if NPCConfig.config["NPC_HIDE_NAMES"] then
        if pointTimer <= 0 then
            pointTimer = 30
            local charBySq = {}

            for i, npc in ipairs(NPCManager.characters) do
                local sq = npc.character:getSquare()
                if sq ~= nil then
                    charBySq[sq] = npc
                end
                npc.userName:setShowName(false)
            end

            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
            local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
            if sq and sq:getFloor() then 
                if charBySq[sq] ~= nil then
                    charBySq[sq].userName:setShowName(true)
                end
            end
        else
            pointTimer = pointTimer - 1
        end
    end
end
Events.OnTick.Add(NPCManager.showNamesByMousePoint)