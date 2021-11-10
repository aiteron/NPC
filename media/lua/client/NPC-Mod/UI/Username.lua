NPCUsername = {}
NPCUsername.__index = NPCUsername

function NPCUsername:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character

    o.text = TextDrawObject.new()
	o.text:setAllowAnyImage(true);
	o.text:setDefaultFont(UIFont.Small);
	o.text:setDefaultColors(1, 1, 1, 1);
	
	if o.character:getModData()["NPC"].nickname then
		o.text:ReadString(o.character:getModData()["NPC"].nickname)
	else
		o.text:ReadString(o.character:getDescriptor():getForename() .. " " .. o.character:getDescriptor():getSurname())
	end

	---
	o.groupText = TextDrawObject.new()
	o.groupText:setAllowAnyImage(true);
	o.groupText:setDefaultFont(UIFont.Small);

	o.showName = true

	return o
end

function NPCUsername:update()
	if self.showName then
		local x, y = self:getTextCoords()
		self.text:AddBatchedDraw(x, y, true)
		if self.isGroup ~= nil then
			self.groupText:AddBatchedDraw(x + self.text:getWidth()/1.5 + self.groupText:getWidth()/2.0, y, true)
		end
	end
end

function NPCUsername:updateName()
	if self.character:getModData()["NPC"].nickname then
		self.text:ReadString(self.character:getModData()["NPC"].nickname)
	else
		self.text:ReadString(self.character:getDescriptor():getForename() .. " " .. self.character:getDescriptor():getSurname())
	end
end

function NPCUsername:getTextCoords()
	local sx = IsoUtils.XToScreen(self.character:getX(), self.character:getY(), self.character:getZ(), 0);
	local sy = IsoUtils.YToScreen(self.character:getX(), self.character:getY(), self.character:getZ(), 0);
	sx = sx - IsoCamera.getOffX() - self.character:getOffsetX();
	sy = sy - IsoCamera.getOffY() - self.character:getOffsetY();

	local dy = getCore():getScreenHeight()/100.0

	sy = sy - dy*13

	sx = sx / getCore():getZoom(0)
	sy = sy / getCore():getZoom(0)

	sy = sy - self.text:getHeight()/2

	return sx, sy
end

function NPCUsername:setGroupText(color, text)
	self.groupText:setDefaultColors(color.r, color.g, color.b, 1);
	self.groupText:ReadString("[" .. text .. "]")
	self.isGroup = true
end

function NPCUsername:removeGroupText()
	self.isGroup = nil
end

function NPCUsername:setRaiderNickname()
	self.text:setDefaultColors(1, 0, 0, 1)
end

function NPCUsername:setShowName(bool)
	self.showName = bool
end