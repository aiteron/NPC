NPCSayDialog = {}
NPCSayDialog.__index = NPCSayDialog

function NPCSayDialog:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character

    o.dialogs = {}

    o.noteText = TextDrawObject.new()
    o.noteText:setAllowAnyImage(true);
    o.noteText:setDefaultFont(UIFont.Small)
    o.noteTimer = 0

    ---
    o.moodles = {}
    o.moodlesCount = 0
    for i=1, 10 do
        local textObj = TextDrawObject.new()
        textObj:setAllowAnyImage(true);
        textObj:setAllowChatIcons(true)
        textObj:setDefaultFont(UIFont.Medium)
        textObj:setDefaultColors(1, 1 ,1 ,1)
        
        local back = TextDrawObject.new()
        back:setAllowAnyImage(true);
        back:setAllowChatIcons(true)
        back:setDefaultFont(UIFont.Medium)
        back:setDefaultColors(1, 1 ,1 ,1)
        
        table.insert(o.moodles, {isOn = false, icon = textObj, backIcon = back, dx = i*34, dy = -8})
    end
    for i=1, 10 do
        local textObj = TextDrawObject.new()
        textObj:setAllowAnyImage(true);
        textObj:setAllowChatIcons(true)
        textObj:setDefaultFont(UIFont.Medium)
        textObj:setDefaultColors(1, 1 ,1 ,1)
        
        local back = TextDrawObject.new()
        back:setAllowAnyImage(true);
        back:setAllowChatIcons(true)
        back:setDefaultFont(UIFont.Medium)
        back:setDefaultColors(1, 1 ,1 ,1)
        
        table.insert(o.moodles, {isOn = false, icon = textObj, backIcon = back, dx = i*34, dy = -8-34, shiftX=0, shiftY=0})
    end

	return o
end

function NPCSayDialog:UpdateMoodles()
    self.moodlesCount = 0
    for i=1, 20 do
        self.moodles[i].isOn = false;
        self.moodles[i].shiftX = 0;
        self.moodles[i].shiftY = 0;
    end    

    local c = 1
    if self.character:getMoodles():getMoodleLevel(MoodleType.Endurance) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Endurance.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Endurance, self.character:getMoodles():getMoodleLevel(MoodleType.Endurance))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Tired) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Tired.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Tired, self.character:getMoodles():getMoodleLevel(MoodleType.Tired))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Hungry) > 1 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Hungry.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Hungry, self.character:getMoodles():getMoodleLevel(MoodleType.Hungry))) 
        c = c + 1 
    elseif self.character:getMoodles():getMoodleLevel(MoodleType.FoodEaten) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Hungry.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.FoodEaten, self.character:getMoodles():getMoodleLevel(MoodleType.FoodEaten))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Panic) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Panic.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Panic, self.character:getMoodles():getMoodleLevel(MoodleType.Panic))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Sick) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Sick.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Sick, self.character:getMoodles():getMoodleLevel(MoodleType.Sick))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Bored) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Bored.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Bored, self.character:getMoodles():getMoodleLevel(MoodleType.Bored))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Unhappy) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Unhappy.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Unhappy, self.character:getMoodles():getMoodleLevel(MoodleType.Unhappy))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Bleeding) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Bleeding.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Bleeding, self.character:getMoodles():getMoodleLevel(MoodleType.Bleeding))) 
        self.moodles[c].shiftY = -2
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Wet) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Wet.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Wet, self.character:getMoodles():getMoodleLevel(MoodleType.Wet))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.HasACold) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Cold.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.HasACold, self.character:getMoodles():getMoodleLevel(MoodleType.HasACold))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Windchill) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Windchill.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Windchill, self.character:getMoodles():getMoodleLevel(MoodleType.Windchill))) 
        self.moodles[c].shiftY = -4
        self.moodles[c].shiftX = 1
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Stress) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Stressed.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Stress, self.character:getMoodles():getMoodleLevel(MoodleType.Stress))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Thirst) > 1 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Thirsty.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Thirst, self.character:getMoodles():getMoodleLevel(MoodleType.Thirst))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Injured) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Injured.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Injured, self.character:getMoodles():getMoodleLevel(MoodleType.Injured))) 
        self.moodles[c].shiftY = -2
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Pain) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Pain.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Pain, self.character:getMoodles():getMoodleLevel(MoodleType.Pain))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_HeavyLoad.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.HeavyLoad, self.character:getMoodles():getMoodleLevel(MoodleType.HeavyLoad))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Drunk) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Drunk.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Drunk, self.character:getMoodles():getMoodleLevel(MoodleType.Drunk))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Zombie) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/ui/Moodle_Icon_Zombie.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Zombie, self.character:getMoodles():getMoodleLevel(MoodleType.Zombie))) 
        c = c + 1 
    end
    if self.character:getMoodles():getMoodleLevel(MoodleType.Hyperthermia) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/textures/Moodle_hyperthermia.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Hyperthermia, self.character:getMoodles():getMoodleLevel(MoodleType.Hyperthermia))) 
        c = c + 1 
    elseif self.character:getMoodles():getMoodleLevel(MoodleType.Hypothermia) > 0 then
        self.moodles[c].isOn = true;
        self.moodles[c].icon:ReadString("[img=media/textures/Moodle_hypothermia.png]")
        self.moodles[c].backIcon:ReadString(NPCSayDialog:GetMoodleBack(MoodleType.Hypothermia, self.character:getMoodles():getMoodleLevel(MoodleType.Hypothermia))) 
        c = c + 1 
    end
    self.moodlesCount = c-1
end

function NPCSayDialog:GetMoodleBack(moodle, moodleLevel)
    local moodleCategory = MoodleType.GoodBadNeutral(moodle)
    if moodleCategory == 0 then
        return "[img=media/ui/Moodle_Bkg_Bad_1.png]"
    elseif moodleCategory == 1 then
        return "[img=media/ui/Moodle_Bkg_Good_".. tostring(moodleLevel) ..".png]"
    else
        return "[img=media/ui/Moodle_Bkg_Bad_".. tostring(moodleLevel) ..".png]"
    end
end

function NPCSayDialog:SayNote(text, color)
    self.noteText:ReadString(text)
    self.noteText:setDefaultColors(color.r, color.g, color.b, color.a)
    self.noteTimer = 120
end

function NPCSayDialog:Say(text, color)
    if #self.dialogs > 0 and text == self.dialogs[1][4] then
        return
    end

    local textObj = TextDrawObject.new()
    textObj:setAllowAnyImage(true);
    textObj:setDefaultFont(UIFont.Medium)
    textObj:setDefaultColors(color.r, color.g, color.b, color.a)
    textObj:ReadString(text)
    textObj:setAllowChatIcons(true)

    table.insert(self.dialogs, 1, {textObj, 240, color, text})
    if #self.dialogs > 5 then
        table.remove(self.dialogs, 6)
    end
end

function NPCSayDialog:update()
    if self.noteTimer > 0 then 
        local x, y = self:getNoteCoords()
        self.noteText:AddBatchedDraw(x, y, false)
        self.noteTimer = self.noteTimer - 1
    end

    local tmp = {}
    for i, tab in ipairs(self.dialogs) do
        local x, y = self:getSayCoords()
        y = y - (i-1)*20

        tab[1]:AddBatchedDraw(x, y, true)

        if tab[2] > 0 then
            if tab[2] < 60 then
                tab[1]:setDefaultColors(tab[3].r, tab[3].g, tab[3].b, tab[3].a * (tab[2]/60))
            end

            tab[2] = tab[2] - 1
            table.insert(tmp, tab)
        end
    end
    self.dialogs = tmp 
    
    ----
    if NPCManager.moodlesTimer > 0 then
        self:UpdateMoodles()
        local x, y = self:getSayCoords()
        y = y - 10
        local shiftX = 0
        if self.moodlesCount == 0 then
            shiftX = -32
        elseif self.moodlesCount == 1 then
            shiftX = -32
        elseif self.moodlesCount == 2 then
            shiftX = -47
        elseif self.moodlesCount == 3 then
            shiftX = -75
        elseif self.moodlesCount == 4 then
            shiftX = -90
        elseif self.moodlesCount == 5 then
            shiftX = -115
        elseif self.moodlesCount == 6 then
            shiftX = -130
        elseif self.moodlesCount == 7 then
            shiftX = -155
        elseif self.moodlesCount == 8 then
            shiftX = -170
        elseif self.moodlesCount == 9 then
            shiftX = -195
        else
            shiftX = -210
        end

        for i=1, 20 do
            if self.moodles[i].isOn then
                self.moodles[i].backIcon:AddBatchedDraw(x + self.moodles[i].dx + shiftX, y + self.moodles[i].dy, true)
                self.moodles[i].icon:AddBatchedDraw(x + self.moodles[i].dx + self.moodles[i].shiftX + shiftX, y + self.moodles[i].dy + self.moodles[i].shiftY + 2, true)
            end
        end
        
        NPCManager.moodlesTimer = NPCManager.moodlesTimer - 1
    end
end

function NPCSayDialog:getNoteCoords()
    local sx = IsoUtils.XToScreen(self.character:getX(), self.character:getY(), self.character:getZ(), 0);
	local sy = IsoUtils.YToScreen(self.character:getX(), self.character:getY(), self.character:getZ(), 0);
	sx = sx - IsoCamera.getOffX() - self.character:getOffsetX();
	sy = sy - IsoCamera.getOffY() - self.character:getOffsetY();

	local dy = getCore():getScreenHeight()/100.0
	sy = sy - dy*13

	sx = sx / getCore():getZoom(0)
	sy = sy / getCore():getZoom(0)

	sy = sy - self.noteText:getHeight()/2 - 20

    return sx, sy
end

function NPCSayDialog:getSayCoords()
    local sx = IsoUtils.XToScreen(self.character:getX(), self.character:getY(), self.character:getZ(), 0);
	local sy = IsoUtils.YToScreen(self.character:getX(), self.character:getY(), self.character:getZ(), 0);
	sx = sx - IsoCamera.getOffX() - self.character:getOffsetX();
	sy = sy - IsoCamera.getOffY() - self.character:getOffsetY();

	local dy = getCore():getScreenHeight()/100.0
	sy = sy - dy*13

	sx = sx / getCore():getZoom(0)
	sy = sy / getCore():getZoom(0)

	sy = sy - 16/2 - 20

    if self.noteTimer > 0 then
        sy = sy - 20
    end

    return sx, sy
end