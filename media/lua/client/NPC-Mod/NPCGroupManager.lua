NPCGroupManager = {}
NPCGroupManager.Groups = nil
NPCGroupManager.playerBase = nil
NPCGroupManager.dropLoot = nil

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

    if npc1.groupID == nil and npc2.groupID == nil then
        npc1:Say(npc2.character:getDescriptor():getForename() .. ", you want join my team?", NPCColor.White)
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

    if npc1.groupID ~= nil and npc1.isLeader and npc2.groupID == nil and NPCGroupManager.Groups[npc1.groupID].count < 4 then
        npc1:Say(npc2.character:getDescriptor():getForename() .. ", you want join my team?", NPCColor.White)
        npc2:Say("Yes", NPCColor.White)

        npc2.groupID = npc1.groupID

        NPCGroupManager.Groups[npc1.groupID].count = NPCGroupManager.Groups[npc1.groupID].count + 1
        table.insert(NPCGroupManager.Groups[npc1.groupID].npc, npc2.UUID)

        npc2.userName:setGroupText(NPCGroupManager.Groups[npc1.groupID].color, NPCGroupManager.Groups[npc1.groupID].name)
    end
end

function NPCGroupManager:getLeaderOfGroup(id)
    return NPCGroupManager.Groups[id].leader
end

