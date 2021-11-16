NPCGroupManager = {}
NPCGroupManager.Data = nil
NPCGroupManager.playerBase = nil
NPCGroupManager.dropLoot = nil

NPCGroupManager.declinedInvitations = {}
NPCGroupManager.igonreNPCIDs = {}


----

function NPCGroupManager:addGroup(leaderID, npcs, name)
    local id = NPCUtils:UUID()
    local color = {r = ZombRand(0, 101)/100.0, g = ZombRand(0, 101)/100.0, b = ZombRand(0, 101)/100.0}

    local Tcount = 0
    for i, npcID in ipairs(npcs) do
        if NPCManager:getCharacter(npcID) ~= nil then
            NPCGroupManager.Data.characterGroup[npcID] = id
            Tcount = Tcount + 1

            NPCManager:getCharacter(npcID).userName:setGroupText(color, name)

            if NPCManager:getCharacter(leaderID).isRaider then
                NPCManager:getCharacter(npcID).isRaider = true
                NPCManager:getCharacter(npcID).userName:setRaiderNickname()
            end
        end
    end

    NPCGroupManager.Data.leaders[leaderID] = true
    NPCGroupManager.Data.groups[id] = { ["count"] = Tcount, ["leaderID"] = leaderID, ["npcIDs"] = npcs, ["color"] = color, ["name"] = name }
end

function NPCGroupManager:getLeaderID(groupID)
    return NPCGroupManager.Data.groups[groupID].leaderID
end

function NPCGroupManager:isLeader(npcID)
    return NPCGroupManager.Data.leaders[npcID]
end

function NPCGroupManager:getGroupCount(groupID)
    return NPCGroupManager.Data.groups[groupID].count
end

function NPCGroupManager:getGroupID(npcID)
    return NPCGroupManager.Data.characterGroup[npcID]
end

function NPCGroupManager:addToGroup(groupID, npcID)
    if NPCManager:getCharacter(npcID) ~= nil then
        NPCGroupManager.Data.groups[groupID].count = NPCGroupManager.Data.groups[groupID].count + 1
        table.insert(NPCGroupManager.Data.groups[groupID].npcIDs, npcID)
        NPCGroupManager.Data.characterGroup[npcID] = groupID

        NPCManager:getCharacter(npcID).userName:setGroupText(NPCGroupManager.Data.groups[groupID].color, NPCGroupManager.Data.groups[groupID].name)
    end
end

function NPCGroupManager:removeFromGroup(npcID)
    local groupID = NPCGroupManager.Data.characterGroup[npcID]
    NPCGroupManager.Data.groups[groupID].count = NPCGroupManager.Data.groups[groupID].count - 1
    table.remove(NPCGroupManager.Data.groups[groupID].npcIDs, tablefind(NPCGroupManager.Data.groups[groupID].npcIDs, npcID))

    NPCGroupManager.Data.characterGroup[npcID] = nil
    if NPCManager:getCharacter(npcID) ~= nil then
        NPCManager:getCharacter(npcID).userName:removeGroupText()
    end

    if NPCGroupManager.Data.leaders[npcID] then
        NPCGroupManager.Data.leaders[npcID] = false
        NPCGroupManager.Data.groups[groupID].leaderID = NPCGroupManager.Data.groups[groupID].npcIDs[1]
    end

    if NPCGroupManager.Data.groups[groupID].count == 1 then
        NPCGroupManager.Data.leaders[NPCGroupManager.Data.groups[groupID].leaderID] = nil
        NPCGroupManager.Data.characterGroup[NPCGroupManager.Data.groups[groupID].leaderID] = nil
        if NPCManager:getCharacter(NPCGroupManager.Data.groups[groupID].leaderID) ~= nil then
            NPCManager:getCharacter(NPCGroupManager.Data.groups[groupID].leaderID).userName:removeGroupText()
        end
        NPCGroupManager.Data.groups[groupID] = nil
    end
end


function NPCGroupManager:ignoreNPC(raiderID, npcID)
    if NPCGroupManager.igonreNPCIDs[raiderID] == nil then
        NPCGroupManager.igonreNPCIDs[raiderID] = {}
    end
    NPCGroupManager.igonreNPCIDs[raiderID][npcID] = true

    NPCManager:getCharacter(raiderID).reputationSystem.reputationList[npcID] = 0
end

function NPCGroupManager:isIgnoreNPC(raiderID, npcID)
    return NPCGroupManager.igonreNPCIDs[raiderID] and NPCGroupManager.igonreNPCIDs[raiderID][npcID]
end

function NPCGroupManager:declineInvite(npc1ID, npc2ID)
    if NPCGroupManager.declinedInvitations[npc1ID] == nil then
        NPCGroupManager.declinedInvitations[npc1ID] = {}
    end
    NPCGroupManager.declinedInvitations[npc1ID][npc2ID] = true
end

function NPCGroupManager:isDeclinedInvite(npc1ID, npc2ID)
    return NPCGroupManager.declinedInvitations[npc1ID] and NPCGroupManager.declinedInvitations[npc1ID][npc2ID]
end


function NPCGroupManager:getTeamScore(npcID)
    local NPCgroupID = NPCGroupManager:getGroupID(npcID)
    local NPCScore = 0

    if NPCgroupID == nil then
        local npc = NPCManager:getCharacter(npcID)
        if npc ~= nil then
            NPCScore = NPCScore + NPCUtils:getNPCScore(npc)
        end
    else
        for _, teamNPCID in ipairs(NPCGroupManager.Data.groups[NPCgroupID].npcIDs) do
            local npc = NPCManager:getCharacter(teamNPCID)
            if npc ~= nil then
                NPCScore = NPCScore + NPCUtils:getNPCScore(npc)
            end
        end
    end

    return NPCScore
end








--------

function NPCGroupManager:isAtBase(x, y)
    if NPCGroupManager.playerBase.x1 ~= nil then
        if x >= NPCGroupManager.playerBase.x1 and x <= NPCGroupManager.playerBase.x2 and y >= NPCGroupManager.playerBase.y1 and y <= NPCGroupManager.playerBase.y2 then
            return true
        end
    end
    return false
end

local groupNames = {
    "The Untouchaballs",
    "Agony of De Feet",
    "We Got the Runs",
    "Goal Diggers",
    "Motherlovers",
    "Staff Infection",
    "Single Belles",
    "No More Debt",
    "Hungry Hippos",
    "5 for Fighting",
    "Juan on Juan",
    "Lord of the Rims",
    "Amigos",
    "Avengers",
    "Bosses",
    "Champions",
    "Dominators",
    "Dream Team",
    "Elite",
    "Force",
    "Heatwave",
    "Hot Shots",
    "Icons",
    "Justice League",
    "Legends",
    "Maniacs"
}

local meetTimer = 0
function NPCGroupManager:updateMeetNPC()
    if meetTimer <= 0 then
        meetTimer = 120

        for i, char in ipairs(NPCManager.characters) do
            for j, char2 in ipairs(NPCManager.characters) do
                if char ~= char2 then
                    if NPCUtils.getDistanceBetween(char.character, char2.character) < 20 then
                        NPCGroupManager:meet(char, char2)
                    end
                end     
            end
        end
    else
        meetTimer = meetTimer - 1
    end
end
Events.OnTick.Add(NPCGroupManager.updateMeetNPC)


function NPCGroupManager:inviteToTeam(npc1, npc2)
    if NPCGroupManager:getGroupID(npc1.UUID) == nil then
        if npc1.groupCharacteristic ~= "Lonely" and not NPCGroupManager:isDeclinedInvite(npc1.UUID, npc2.UUID) then
            npc1:Say(npc2.character:getDescriptor():getForename() .. ", you want join my team?", NPCColor.White)
            if npc2.groupCharacteristic == "Lonely" then
                npc2:Say("I am survive alone", NPCColor.White)
                NPCGroupManager:declineInvite(npc1.UUID, npc2.UUID)
            elseif npc2.groupCharacteristic == "Group Guy" then
                npc2:Say("I am so lonely. Yes, I will go with you", NPCColor.White)
                npc2:Say("Yes", NPCColor.White)
                NPCGroupManager:addGroup(npc1.UUID, {npc1.UUID, npc2.UUID}, groupNames[ZombRand(1, #groupNames+1)])            
            else
                npc2:Say("Yes", NPCColor.White)
                NPCGroupManager:addGroup(npc1.UUID, {npc1.UUID, npc2.UUID}, groupNames[ZombRand(1, #groupNames+1)])
            end
        end
    else
        if NPCGroupManager:isLeader(npc1.UUID) and NPCGroupManager:getGroupCount(NPCGroupManager:getGroupID(npc1.UUID)) < 4 and not NPCGroupManager:isDeclinedInvite(npc1.UUID, npc2.UUID) then
            npc1:Say(npc2.character:getDescriptor():getForename() .. ", you want join my team?", NPCColor.White)
            if npc2.groupCharacteristic == "Lonely" then
                npc2:Say("I am survive alone", NPCColor.White)
                NPCGroupManager:declineInvite(npc1.UUID, npc2.UUID)
            elseif npc2.groupCharacteristic == "Group Guy" then
                npc2:Say("I am so lonely. Yes, I will go with you", NPCColor.White)
                npc2:Say("Yes", NPCColor.White)
                NPCGroupManager:addToGroup(NPCGroupManager:getGroupID(npc1.UUID), npc2.UUID)
            else
                npc2:Say("Yes", NPCColor.White)
                NPCGroupManager:addToGroup(NPCGroupManager:getGroupID(npc1.UUID), npc2.UUID)
            end
        end
    end
end

function NPCGroupManager:meet(npc1, npc2)
    if (NPCGroupManager:getGroupID(npc1.UUID) ~= nil or NPCGroupManager:getGroupID(npc2.UUID) ~= nil) and NPCGroupManager:getGroupID(npc1.UUID) == NPCGroupManager:getGroupID(npc2.UUID) then return end
    if npc1.AI:getType() == "PlayerGroupAI" then return end

    if npc2.AI:getType() == "PlayerGroupAI" then
        if npc1.isRaider and (NPCGroupManager:getGroupID(npc1.UUID) == nil or NPCGroupManager:isLeader(npc1.UUID)) then
            if not NPCGroupManager:isIgnoreNPC(npc1.UUID, npc2.UUID) then
                if ZombRand(0, 10) <= 10 then
                    npc1.AI.command = "ROBBING"
                    npc1.AI.TaskArgs.robbedPerson = npc2.character
                    NPCGroupManager:ignoreNPC(npc1.UUID, npc2.UUID)
                else
                    NPCGroupManager:ignoreNPC(npc1.UUID, npc2.UUID)
                end
            end
        end
    elseif NPCGroupManager:getGroupID(npc2.UUID) ~= nil then
        if npc1.isRaider and (NPCGroupManager:getGroupID(npc1.UUID) == nil or NPCGroupManager:isLeader(npc1.UUID)) then
            if not NPCGroupManager:isIgnoreNPC(npc1.UUID, npc2.UUID) then
                if ZombRand(0, 10) <= 10 and NPCGroupManager:getTeamScore(npc2.UUID) < NPCGroupManager:getTeamScore(npc1.UUID) or true then
                    npc1.AI.command = "ROBBING"
                    npc1.AI.TaskArgs.robbedPerson = npc2.character
                    NPCGroupManager:ignoreNPC(npc1.UUID, npc2.UUID)
                else
                    NPCGroupManager:ignoreNPC(npc1.UUID, npc2.UUID)
                end
            end
        end
    else
        if npc1.isRaider and (NPCGroupManager:getGroupID(npc1.UUID) == nil or NPCGroupManager:isLeader(npc1.UUID)) then
            if not NPCGroupManager:isIgnoreNPC(npc1.UUID, npc2.UUID) then
                if ZombRand(0, 10) <= 10  then
                    if NPCGroupManager:getTeamScore(npc2.UUID) < NPCGroupManager:getTeamScore(npc1.UUID) or true then
                        npc1.AI.command = "ROBBING"
                        npc1.AI.TaskArgs.robbedPerson = npc2.character
                        NPCGroupManager:ignoreNPC(npc1.UUID, npc2.UUID)
                    else
                        NPCGroupManager:inviteToTeam(npc1, npc2)
                    end
                else
                    NPCGroupManager:ignoreNPC(npc1.UUID, npc2.UUID)
                end
            end
        elseif not npc1.isRaider and not npc2.isRaider then
            NPCGroupManager:inviteToTeam(npc1, npc2)
        end
    end
end

function NPCGroupManager:joiningNPCToPlayerTeam(npc)
    if NPCGroupManager:getGroupID(npc.UUID) == nil then
        npc:setAI(PlayerGroupAI:new(npc.character)) 	
        npc.reputationSystem.playerRep = 600
    else
        NPCGroupManager:removeFromGroup(npc.UUID)

        npc:setAI(PlayerGroupAI:new(npc.character)) 	
        npc.reputationSystem.playerRep = 600
    end
end

function NPCGroupManager:getPlayerTeamScore()
    local resultScore = 0

    for i, char in ipairs(NPCManager.characters) do
        if char.AI:getType() == "PlayerGroupAI" then
            resultScore = resultScore + (char.character:getHealth()*100 - 80)
            
            local foodItems = char.character:getInventory():getAllEvalRecurse(function(item)
                if NPCUtils:evalIsFood(item) then
                    return true
                end          
            end)
            resultScore = resultScore + foodItems:size() * 5

            local weaponItems = char.character:getInventory():getAllEvalRecurse(function(item)
                if NPCUtils:evalIsMelee(item) or NPCUtils:evalIsWeapon(item) then
                    return true
                end          
            end)
            resultScore = resultScore + weaponItems:size() * 10
        end
    end

    return resultScore
end

function NPCGroupManager:getTypeOfItemsThatNeed(npc)
    local inv = npc.character:getInventory()

    if inv:getAllEvalRecurse(NPCUtils.evalIsMelee):size() <= 0 then
        return "melee"
    end
    
    if inv:getAllEvalRecurse(NPCUtils.evalIsFood):size() < 5 then
        return "food"
    end

    if npc.character:getHealth() < 0.5 then
        return "meds"
    end
end

function NPCGroupManager:getItemsOnFloorNearPlayer(typeOfItemsThatNeed)
    local x = getPlayer():getX()
    local y = getPlayer():getY()
    local z = getPlayer():getZ()
    
    local resultItems = {}
    for i=-1, 1 do
        for j=-1, 1 do
            local sq = getCell():getGridSquare(x+i, y+j, z)        
            local items = NPCUtils:getItemsOnFloor(function(item)
                if typeOfItemsThatNeed == "food" and NPCUtils:evalIsFood(item) then
                    return true
                end
            
                if typeOfItemsThatNeed == "meds" and NPCUtils:evalIsMeds(item) then
                    return true
                end  
            
                if typeOfItemsThatNeed == "melee" and NPCUtils:evalIsMelee(item) then
                    return true
                end  
            
                return false
            end, sq)

            for _, item in ipairs(items) do
                table.insert(resultItems, item)
            end
        end
    end

    return resultItems
end

function NPCGroupManager:playerInviteToTeamNPC(npc)
    if npc.groupCharacteristic == "Lonely" then
        npc:Say("I am survive alone", NPCColor.White)
    elseif npc.groupCharacteristic == "Group Guy" then
        if NPCGroupManager:getGroupID(npc.UUID) == nil or NPCGroupManager:getGroupCount(NPCGroupManager:getGroupID(npc.UUID)) <= 1 then
            npc:Say("I am so lonely. Yes, I will go with you", NPCColor.White)
            NPCGroupManager:joiningNPCToPlayerTeam(npc) 
        else
            npc:Say("I am already in team", NPCColor.White)
        end
    else
        if npc.reputationSystem.playerRep > 500 then
            npc:Say("Yes, I will go with you", NPCColor.White)
            NPCGroupManager:joiningNPCToPlayerTeam(npc) 
        elseif npc.reputationSystem.playerRep < 0 then
            npc:Say("You are dick. I will kill you!", NPCColor.Red)
        else
            local score = npc.reputationSystem.playerRep
            local teamScore = NPCGroupManager:getPlayerTeamScore()

            if score + teamScore > 500 then
                if teamScore > 100 then
                    npc:Say("You have a cool team", NPCColor.White)
                end
                npc:Say("Yes, I will go with you", NPCColor.White)
                NPCGroupManager:joiningNPCToPlayerTeam(npc)
            else
                if teamScore < 0 then
                    npc:Say("Your team a weak", NPCColor.White)
                else
                    local typeOfItemsThatNeed = NPCGroupManager:getTypeOfItemsThatNeed(npc)
                    npc:Say("I need " .. typeOfItemsThatNeed, NPCColor.White)
                    npc:Say("Drop this items on floor", NPCColor.White)

                    local items = NPCGroupManager:getItemsOnFloorNearPlayer(typeOfItemsThatNeed)
                    if #items > 0 then
                        npc:Say("One sec, I will take it", NPCColor.White)
                        npc.AI.command = "TAKE_ITEMS_FROM_PLAYER"
                        npc.AI.TaskArgs.inviteItems = items
                    end
                end
            end
        end
    end
end

