require "NPC-Mod/NPCGroupManager"

ReputationSystem = {}
ReputationSystem.__index = ReputationSystem

function ReputationSystem:new(character, preset)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.character = character

    o.reputationList = {}
    if preset ~= nil then
        o.playerRep = preset.defaultReputation
        o.defaultReputation = preset.defaultReputation
    else
        o.playerRep = 0
        o.defaultReputation = 0
    end
    
    return o
end

function ReputationSystem:getNPCRep(npc)
    if NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID) ~= nil then
        if NPCGroupManager:isLeader(self.character:getModData().NPC.UUID) then
            if NPCGroupManager:getGroupID(npc.UUID) == NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID) then
                return 1000
            else
                if self.reputationList[npc.UUID] == nil then
                    return self.defaultReputation
                else
                    return self.reputationList[npc.UUID]
                end
            end
        else
            if NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID))] == nil or NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID))].isLoaded == false then
                if self.reputationList[npc.UUID] == nil then
                    return self.defaultReputation
                else
                    return self.reputationList[npc.UUID]
                end
            else
                local char = NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID)))
                if char == nil then
                    return 0
                else
                    return char.reputationSystem:getNPCRep(npc)
                end
                
            end
        end
    else
        if npc.AI:getType() == "PlayerGroupAI" and self.character:getModData().NPC.AI:getType() == "PlayerGroupAI" then
            return 1000
        end

        if self.reputationList[npc.UUID] == nil then
            return self.defaultReputation
        else
            return self.reputationList[npc.UUID]
        end
    end
end

function ReputationSystem:getPlayerRep()
    if NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID) ~= nil then
        if NPCGroupManager:isLeader(self.character:getModData().NPC.UUID) then
            return self.playerRep
        else
            if NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID))] == nil or NPCManager.characterMap[NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID))].isLoaded == false then
                return self.playerRep
            end
            local char = NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.UUID)))
            if char == nil then
                return 0
            else
                return char.reputationSystem:getPlayerRep()
            end
        end
    else
        if self.character:getModData().NPC.AI:getType() == "PlayerGroupAI" then
            return 1000
        else
            return self.playerRep
        end
    end
end

function ReputationSystem:updatePlayerRep(value)
    self.playerRep = self.playerRep + value
end

function ReputationSystem:updateNPCRep(value, npcID)
    if self.reputationList[npcID] == nil then
        self.reputationList[npcID] = self.defaultReputation
    end
    print(self.reputationList[npcID])
    print(self.defaultReputation)
    self.reputationList[npcID] = self.reputationList[npcID] + value
end



