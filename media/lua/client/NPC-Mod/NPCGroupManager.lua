NPCGroupManager = {}
NPCGroupManager.Groups = nil
NPCGroupManager.playerBase = nil
NPCGroupManager.dropLoot = nil

NPCGroupManager.declinedInvitations = {}

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


function NPCGroupManager:meet(npc1, npc2)
    if (npc1.groupID ~= nil or npc2.groupID ~= nil) and npc1.groupID == npc2.groupID then return end
    if npc1.AI:getType() == "PlayerGroupAI" or npc2.AI:getType() == "PlayerGroupAI" then return end
    
    if npc1.groupID == nil and npc2.groupID == nil and npc1.groupCharacteristic ~= "Lonely" and (NPCGroupManager.declinedInvitations[npc1.UUID] == nil or NPCGroupManager.declinedInvitations[npc1.UUID][npc2.UUID] == nil) then
        npc1:Say(npc2.character:getDescriptor():getForename() .. ", you want join my team?", NPCColor.White)
        if npc2.groupCharacteristic == "Lonely" then
            npc2:Say("I am survive alone", NPCColor.White)
            if NPCGroupManager.declinedInvitations[npc1.UUID] == nil then
                NPCGroupManager.declinedInvitations[npc1.UUID] = {}
                NPCGroupManager.declinedInvitations[npc1.UUID][npc2.UUID] = true
            else
                NPCGroupManager.declinedInvitations[npc1.UUID][npc2.UUID] = true
            end
        elseif npc2.groupCharacteristic == "Group Guy" then
            npc2:Say("I am so lonely. Yes, I will go with you", NPCColor.White)
            npc2:Say("Yes", NPCColor.White)

            local id = NPCUtils:UUID()
            npc1.groupID = id
            npc2.groupID = id

            npc1.isLeader = true
            local name = groupNames[ZombRand(1, #groupNames+1)]
            local color = {r = ZombRand(0, 101)/100.0, g = ZombRand(0, 101)/100.0, b = ZombRand(0, 101)/100.0}
            NPCGroupManager.Groups[id] = {leader = npc1.UUID, npc = {npc1.UUID, npc2.UUID}, count = 2, color = color, name = name}

            npc1.userName:setGroupText(color, name)
            npc2.userName:setGroupText(color, name)
        else
            npc2:Say("Yes", NPCColor.White)

            local id = NPCUtils:UUID()
            npc1.groupID = id
            npc2.groupID = id

            npc1.isLeader = true
            local name = groupNames[ZombRand(1, #groupNames+1)]
            local color = {r = ZombRand(0, 101)/100.0, g = ZombRand(0, 101)/100.0, b = ZombRand(0, 101)/100.0}
            NPCGroupManager.Groups[id] = {leader = npc1.UUID, npc = {npc1.UUID, npc2.UUID}, count = 2, color = color, name = name}

            npc1.userName:setGroupText(color, name)
            npc2.userName:setGroupText(color, name)
        end
    end

    if npc1.groupID ~= nil and npc1.isLeader and npc2.groupID == nil and NPCGroupManager.Groups[npc1.groupID].count < 4 and (NPCGroupManager.declinedInvitations[npc1.groupID] == nil or NPCGroupManager.declinedInvitations[npc1.groupID][npc2.UUID] == nil) then
        npc1:Say(npc2.character:getDescriptor():getForename() .. ", you want join my team?", NPCColor.White)
        if npc2.groupCharacteristic == "Lonely" then
            npc2:Say("I am survive alone", NPCColor.White)
            if NPCGroupManager.declinedInvitations[npc1.groupID] == nil then
                NPCGroupManager.declinedInvitations[npc1.groupID] = {}
                NPCGroupManager.declinedInvitations[npc1.groupID][npc2.UUID] = false
            else
                NPCGroupManager.declinedInvitations[npc1.groupID][npc2.UUID] = false
            end
        elseif npc2.groupCharacteristic == "Group Guy" then
            npc2:Say("I am so lonely. Yes, I will go with you", NPCColor.White)
            npc2:Say("Yes", NPCColor.White)

            npc2.groupID = npc1.groupID

            NPCGroupManager.Groups[npc1.groupID].count = NPCGroupManager.Groups[npc1.groupID].count + 1
            table.insert(NPCGroupManager.Groups[npc1.groupID].npc, npc2.UUID)

            npc2.userName:setGroupText(NPCGroupManager.Groups[npc1.groupID].color, NPCGroupManager.Groups[npc1.groupID].name)
        else
            npc2:Say("Yes", NPCColor.White)

            npc2.groupID = npc1.groupID
    
            NPCGroupManager.Groups[npc1.groupID].count = NPCGroupManager.Groups[npc1.groupID].count + 1
            table.insert(NPCGroupManager.Groups[npc1.groupID].npc, npc2.UUID)
    
            npc2.userName:setGroupText(NPCGroupManager.Groups[npc1.groupID].color, NPCGroupManager.Groups[npc1.groupID].name)
        end
    end
end

function NPCGroupManager:getLeaderOfGroup(id)
    return NPCGroupManager.Groups[id].leader
end

function NPCGroupManager:joiningNPCToPlayerTeam(npc)
    if npc.groupID == nil then
        npc:setAI(PlayerGroupAI:new(npc.character)) 	
        npc.reputationSystem.playerRep = 600
    else
        table.remove(NPCGroupManager.Groups[npc.groupID].npc, tablefind(NPCGroupManager.Groups[npc.groupID].npc, npc.UUID))
        NPCGroupManager.Groups[npc.groupID].count = NPCGroupManager.Groups[npc.groupID].count - 1
        if NPCGroupManager.Groups[npc.groupID].count <= 0 then
            NPCGroupManager.Groups[npc.groupID] = nil
        else
            NPCGroupManager.Groups[npc.groupID].leader = NPCGroupManager.Groups[npc.groupID].npc[1]
            NPCManager.characterMap[NPCGroupManager.Groups[npc.groupID].leader].npc.isLeader = true
        end
        npc.isLeader = false
        npc.groupID = nil
        npc.userName:removeGroupText()

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
        if npc.groupID == nil or NPCGroupManager.Groups[npc.groupID].count <= 1 then
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
                        npc.AI.TaskArgs = items
                    end
                end
            end
        end
    end
end

