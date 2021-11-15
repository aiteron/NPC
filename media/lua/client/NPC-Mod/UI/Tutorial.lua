NPCTutorial = {}

NPCTutorialRichText = ISPanelJoypad:derive("NPCTutorialRichText");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function NPCTutorialRichText:initialise()
	ISPanelJoypad.initialise(self);
	local btnWid = 100
	local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
	local padBottom = 10
	
    self.ok = ISButton:new((self:getWidth() / 2) - btnWid / 2, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("UI_Ok"), self, NPCTutorialRichText.onClick);
    self.ok.internal = "OK";
    self.ok.anchorTop = false
    self.ok.anchorBottom = true
    self.ok:initialise();
    self.ok:instantiate();
    self.ok.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.ok);

    self.chatText = ISRichTextPanel:new(2, 2, self.width - 4, self.height - padBottom - btnHgt);
    self.chatText.marginRight = self.chatText.marginLeft;
    self.chatText:initialise();
    self:addChild(self.chatText);
    self.chatText:addScrollBars()
    
    self.chatText.background = false;
    self.chatText.clip = true
    self.chatText.autosetheight = false
    self.chatText.text = self.text;
    self.chatText:paginate();

	--[[
    local tickBox = ISTickBox:new(self.ok:getRight() + 10, self:getHeight() + 70, 150, 20, "")
	tickBox:initialise()
    tickBox:addOption("DISABLE WELCOME MESSAGE")
	self:addChild(tickBox)
	self.tickBox = tickBox
	]]--
end

function NPCTutorialRichText:updateButtons()
	local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10
    if self.yesno then
        self.yes:setY(self:getHeight() - padBottom - btnHgt);
        self.no:setY(self:getHeight() - padBottom - btnHgt);
    else
        self.ok:setY(self:getHeight() - padBottom - btnHgt);
    end
end

function NPCTutorialRichText:destroy()
	UIManager.setShowPausedMessage(true);
	self:setVisible(false);
    if self.destroyOnClick then
	    self:removeFromUIManager();
    end
	if UIManager.getSpeedControls() then
		UIManager.getSpeedControls():SetCurrentGameSpeed(1);
	end
	if self.player and JoypadState.players[self.player+1] then
		setJoypadFocus(self.player, nil);
	elseif self.joyfocus and self.joyfocus.focus == self then
		self.joyfocus.focus = self.prevFocus
		updateJoypadFocus(self.joyfocus)
	end
end

function NPCTutorialRichText:onClick(button)
	--if self.tickBox:isSelected(1) then
    --    NPCConfig.config["NPC_POPUP_WINDOW"] = false
    --    NPCConfigSettings.saveConfig()
    --end
    self:destroy();
end

function NPCTutorialRichText:prerender()
	self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
--	self:drawTextCentre(self.text, self:getWidth() / 2, (self:getHeight() / 2) - 10, 1, 1, 1, 1, UIFont.Small);
end

function NPCTutorialRichText:onMouseDown(x, y)
--	ISPanelJoypad.onMouseDown(self, x, y)
	-- FIXME: this prevents clicks being passed to windows behind, but need to swallow clicks outside and mouse-move events as well
	return true
end

function NPCTutorialRichText:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData);
	if self.yesno then
		self:setISButtonForA(self.yes)
		self:setISButtonForB(self.no)
		self.yes.mouseOver = true;
	else
		self:setISButtonForA(self.ok)
		self.ok.mouseOver = true;
	end
end

function NPCTutorialRichText:onLoseJoypadFocus(joypadData)
	ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
	if self.yesno then
		self.yes:clearJoypadButton()
		self.no:clearJoypadButton()
	else
		self.ok:clearJoypadButton()
	end
end

function NPCTutorialRichText:onJoypadDown(button)
	if button == Joypad.AButton then
		if self.yesno then
			if self.yes.mouseOver then
				self.yes.player = self.player;
				self.yes.onclick(self.yes.target, self.yes);
			else
				self.no.player = self.player;
				self.no.onclick(self.no.target, self.no);
			end
		else
			self.ok.onclick(self.ok.target, self.ok);
		end
	end
	if button == Joypad.BButton then
		if self.yesno then
			self.no.player = self.player;
			self.no.onclick(self.no.target, self.no);
		else
			self.ok.onclick(self.ok.target, self.ok);
		end
	end
end

function NPCTutorialRichText:onJoypadDirRight()
	if self.yesno then
		self.no.mouseOver = true;
		self.yes.mouseOver = false;
	end
end

function NPCTutorialRichText:onJoypadDirLeft()
	if self.yesno then
		self.no.mouseOver = false;
		self.yes.mouseOver = true;
	end
end

function NPCTutorialRichText:update()
	ISPanelJoypad.update(self)
	local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
	local minHeight = self.chatText:getScrollHeight() + btnHgt + 10
	maxHeight = getCore():getScreenHeight() - 40
	minHeight = math.min(minHeight, maxHeight)
	if self:getHeight() < minHeight then
		local dh = minHeight - self:getHeight()
		self:setHeight(minHeight)
		self:ignoreHeightChange()
		self:setY(math.max(self:getY() - dh / 2, 20))
		self:updateButtons()
	elseif self:getHeight() > maxHeight then
		local dh = self:getHeight() - maxHeight
		self:setHeight(maxHeight)
		self:ignoreHeightChange()
		self:setY(20)
		self:updateButtons()
    end
	self.chatText:setHeight(self.height - btnHgt - 10)
	self.chatText:updateScrollbars()
    if self.alwaysOnTop then
        self:bringToTop();
    end
end

function NPCTutorialRichText:setHeightToContents()
	local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
	local minHeight = self.chatText:getScrollHeight() + btnHgt + 10
	self:setHeight(minHeight)
	self:ignoreHeightChange()
	self:updateButtons()
end

--************************************************************************--
--** NPCTutorialRichText:new
--**
--************************************************************************--
function NPCTutorialRichText:new(x, y, width, height, text, yesno, target, onclick, player, param1, param2)
	local o = {}
	o = ISPanelJoypad:new(x, y, width, height);
	setmetatable(o, self)
    self.__index = self
	local playerObj = player and getSpecificPlayer(player) or nil
	if y == 0 then
		if playerObj and playerObj:getJoypadBind() ~= -1 then
			o.y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
		else
			o.y = o:getMouseY() - (height / 2)
		end
		o:setY(o.y)
	end
	if x == 0 then
		if playerObj and playerObj:getJoypadBind() ~= -1 then
			o.x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
		else
			o.x = o:getMouseX() - (width / 2)
		end
		o:setX(o.x)
	end
	o.name = nil;
    o.backgroundColor = {r=0, g=0, b=0, a=0.9};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = true;
	o.anchorTop = true;
	o.anchorBottom = true;
	o.text = text;
	o.yesno = yesno;
	o.target = target;
	o.onclick = onclick;
	o.yes = nil;
    o.player = player;
	o.no = nil;
	o.ok = nil;
	o.param1 = param1;
	o.param2 = param2;
    o.destroyOnClick = true;
    return o;
end





local text = "<H1> Hi! Thanks for choosing Project Humanoid <BR> <TEXT> <IMAGECENTRE:media/ui/AiteronLogo.png> <LINE><LINE> " ..
"<CENTRE> <SIZE:large> This is a alpha build <LINE><LINE> " ..
"<CENTRE> It took hundreds of hours of development to create the mod and thousands of lines of code were written. <LINE><LINE> " ..
"<CENTRE> Enjoy! If you want to support me - below links to my patreon and ko-fi. <LINE><LINE> " ..
"<CENTRE> YouTube:  shorturl.at/xyBQY <LINE>" ..
"<CENTRE> Patreon: patreon.com/aiteron <LINE>" ..
"<CENTRE> Ko-fi: ko-fi.com/aiteron <LINE><LINE>" ..
"<CENTRE> Tutorial: <LINE> " ..
"<CENTRE> Radial menu - Tab key <LINE> " ..
"<CENTRE> NPC settings - in global settings <LINE> " ..
"<CENTRE> Video tutorial: TODO <LINE><LINE> "

function NPCTutorial.onGameBoot()
    if NPCConfig.config["NPC_POPUP_WINDOW"] then
        local animPopup = NPCTutorialRichText:new(getCore():getScreenWidth()/2-350,getCore():getScreenHeight()/2-300,700,600, text, false);
        animPopup:initialise();
        animPopup.backgroundColor = {r=0, g=0, b=0, a=0.9};
        animPopup.alwaysOnTop = true;
        animPopup.chatText:paginate();
        animPopup:setY(getCore():getScreenHeight()/2-(animPopup:getHeight()/2));
        animPopup:setVisible(true);
        animPopup:addToUIManager();
    end
end

Events.OnGameBoot.Add(NPCTutorial.onGameBoot)