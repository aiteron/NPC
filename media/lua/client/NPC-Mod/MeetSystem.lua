MeetSystem = {}
MeetSystem.Data = nil
MeetSystem.chanceToSay = 15
MeetSystem.longBreakTime = 60000


function MeetSystem:firstMeet(npc1, npc2)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 then
        if npc1.reputationSystem.defaultReputation < 0 then
            npc1:Say(NPC_Dialogues.angryFirstMeet[ZombRand(1, #NPC_Dialogues.angryFirstMeet+1)], NPCColor.White)
        else
            npc1:Say(NPC_Dialogues.friendFirstMeet[ZombRand(1, #NPC_Dialogues.friendFirstMeet+1)], NPCColor.White)
        end
    end
end

function MeetSystem:meetAfterLongBreak(npc1, npc2)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 and npc1.groupID == npc2.groupID then
        npc1:Say(NPC_Dialogues.meetAfterLongBreak[ZombRand(1, #NPC_Dialogues.meetAfterLongBreak+1)], NPCColor.White)
    end
end

function MeetSystem:byebyeTalk(npc1, npc2)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 then
        if npc1.reputationSystem.defaultReputation < 0 then
            npc1:Say(NPC_Dialogues.angryByeBye[ZombRand(1, #NPC_Dialogues.angryByeBye+1)], NPCColor.White)
        else
            npc1:Say(NPC_Dialogues.friendByeBye[ZombRand(1, #NPC_Dialogues.friendByeBye+1)], NPCColor.White)
        end
    end
end

function MeetSystem:firstMeetPlayer(npc1, pl)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 then
        if npc1.reputationSystem.playerRep < 0 then
            npc1:Say(NPC_Dialogues.angryFirstMeet[ZombRand(1, #NPC_Dialogues.angryFirstMeet+1)], NPCColor.White)
        else
            npc1:Say(NPC_Dialogues.friendFirstMeet[ZombRand(1, #NPC_Dialogues.friendFirstMeet+1)], NPCColor.White)
        end
    end
end

function MeetSystem:meetAfterLongBreakPlayer(npc1, pl)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 and npc1.AI:getType() == "PlayerGroupAI" then
        npc1:Say(NPC_Dialogues.meetAfterLongBreak[ZombRand(1, #NPC_Dialogues.meetAfterLongBreak+1)], NPCColor.White)
    end
end

function MeetSystem:byebyeTalkPlayer(npc1, pl)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 then
        if npc1.reputationSystem.playerRep < 0 then
            npc1:Say(NPC_Dialogues.angryByeBye[ZombRand(1, #NPC_Dialogues.angryByeBye+1)], NPCColor.White)
        else
            npc1:Say(NPC_Dialogues.friendByeBye[ZombRand(1, #NPC_Dialogues.friendByeBye+1)], NPCColor.White)
        end
    end
end


local meetManagingTimer = 0
function MeetSystem:meetManaging()
    if meetManagingTimer <= 0 then
        meetManagingTimer = 60

        for i, char1 in ipairs(NPCManager.characters) do
            if ZombRand(0, 100) == 0 then
                if char1.reputationSystem.defaultReputation < 0 then
                    char1:Say(NPC_Dialogues.angryRandomTalk[ZombRand(1, #NPC_Dialogues.angryRandomTalk+1)], NPCColor.White)
                else
                    char1:Say(NPC_Dialogues.friendRandomTalk[ZombRand(1, #NPC_Dialogues.friendRandomTalk+1)], NPCColor.White)
                end
            end

            for j, char2 in ipairs(NPCManager.characters) do
                if char1 ~= char2 then
                    if MeetSystem.Data[char1.UUID] == nil then
                        MeetSystem.Data[char1.UUID] = {}
                    end
                    if MeetSystem.Data[char1.UUID][char2.UUID] == nil then
                        MeetSystem.Data[char1.UUID][char2.UUID] = {}
                    end
                    ---
                    if NPCUtils.getDistanceBetween(char1, char2) > 5 then
                        if MeetSystem.Data[char1.UUID][char2.UUID].divided == false then
                            MeetSystem:byebyeTalk(char1, char2)
                        end
                        MeetSystem.Data[char1.UUID][char2.UUID].divided = true
                    else
                        if MeetSystem.Data[char1.UUID][char2.UUID].divided then
                            MeetSystem.Data[char1.UUID][char2.UUID].divided = false

                            if MeetSystem.Data[char1.UUID][char2.UUID].time == nil then
                                MeetSystem:firstMeet(char1, char2)
                            else
                                if getTimeInMillis() - MeetSystem.Data[char1.UUID][char2.UUID].time  > MeetSystem.longBreakTime then
                                    MeetSystem:meetAfterLongBreak(char1, char2)
                                    MeetSystem.Data[char1.UUID][char2.UUID].time = getTimeInMillis()
                                end
                            end
                        end
                        MeetSystem.Data[char1.UUID][char2.UUID].time = getTimeInMillis()
                    end
                end
            end
        end

        for i, char in ipairs(NPCManager.characters) do
            if MeetSystem.Data[char.UUID] == nil then
                MeetSystem.Data[char.UUID] = {}
            end
            if MeetSystem.Data[char.UUID]["PLAYER"] == nil then
                MeetSystem.Data[char.UUID]["PLAYER"] = {}
            end
            --
            if NPCUtils.getDistanceBetween(getPlayer(), char) > 5 then
                if MeetSystem.Data[char.UUID]["PLAYER"].divided == false then
                    MeetSystem:byebyeTalkPlayer(char, getPlayer())
                end

                MeetSystem.Data[char.UUID]["PLAYER"].divided = true
            else
                if MeetSystem.Data[char.UUID]["PLAYER"].divided then
                    MeetSystem.Data[char.UUID]["PLAYER"].divided = false

                    if MeetSystem.Data[char.UUID]["PLAYER"].time == nil then
                        MeetSystem:firstMeetPlayer(char, getPlayer())
                    else
                        if getTimeInMillis() - MeetSystem.Data[char.UUID]["PLAYER"].time > MeetSystem.longBreakTime then
                            MeetSystem:meetAfterLongBreakPlayer(char, getPlayer())
                            MeetSystem.Data[char.UUID]["PLAYER"].time = getTimeInMillis()
                        end
                    end
                end
                MeetSystem.Data[char.UUID]["PLAYER"].time = getTimeInMillis()
            end
        end
        
    else
        meetManagingTimer = meetManagingTimer - 1
    end
end
Events.OnTick.Add(MeetSystem.meetManaging)

