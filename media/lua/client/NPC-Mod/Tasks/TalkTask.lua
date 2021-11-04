TalkTask = {}
TalkTask.__index = TalkTask

function TalkTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Talk"
	o.complete = false

    o.talkCompanion = character:getModData().NPC.AI.TaskArgs

    character:getModData().NPC.AI.idleCommand = "TALK"

    o.dialogue = NPC_Dialogues.smallTalk[ZombRand(1, #NPC_Dialogues.smallTalk+1)]
    o.dialogueCount = 1
    o.dialogueTimer = 0
	return o
end


function TalkTask:isComplete()
	return self.complete
end

function TalkTask:stop()

end

function TalkTask:isValid()
    return self.character
end

function TalkTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        self.character:facePosition(self.talkCompanion:getX(), self.talkCompanion:getY())

        if self.character:getModData().NPC.AI.command == "TALK_COMPANION" then
        else
            if self.dialogueTimer <= 0 then
                self.dialogueTimer = 100
                if self.dialogueCount % 2 == 0 then
                    if self.talkCompanion == getPlayer() then
                        self.talkCompanion:Say(self.dialogue[self.dialogueCount])
                    else
                        self.talkCompanion:getModData().NPC:Say(self.dialogue[self.dialogueCount], NPCColor.White)
                    end
                else
                    self.character:getModData().NPC:Say(self.dialogue[self.dialogueCount], NPCColor.White)
                end
                self.dialogueCount = self.dialogueCount + 1
            else
                self.dialogueTimer = self.dialogueTimer - 1
            end
            if self.dialogueCount == #self.dialogue then
                self.complete = true
                self.character:getModData().NPC.AI.idleCommand = nil

                if self.talkCompanion ~= getPlayer() then
                    
                else
                    HaloTextHelper.addTextWithArrow(self.talkCompanion, getText("IGUI_HaloNote_Boredom"), false, HaloTextHelper.getColorGreen());
                end
                
                --
                local val = self.talkCompanion:getBodyDamage():getBoredomLevel()
                val = val - 20
                if val < 0 then
                    val = 0
                end
                self.talkCompanion:getBodyDamage():setBoredomLevel(val);
                --
                local val = self.character:getBodyDamage():getBoredomLevel()
                val = val - 20
                if val < 0 then
                    val = 0
                end
                self.character:getBodyDamage():setBoredomLevel(val);
            end
        end
    end

    return true
end