require "ISUI/ISCollapsableWindow"
require "ISUI/ISLayoutManager"

NPC_ISCharacterInfoWindow = ISCollapsableWindow:derive("NPC_ISCharacterInfoWindow");
NPC_ISCharacterInfoWindow.view = {};

function NPC_ISCharacterInfoWindow:initialise()
	ISCollapsableWindow.initialise(self);
end

--~ function NPC_ISCharacterInfoWindow:setVisible(bVisible)
--~ 	if not bVisible then
--~ 		self.healthView:setVisible(bVisible);
--~ 		self.charScreen:setVisible(bVisible);
--~ 		self.characterView:setVisible(bVisible);
--~ 	end
--~ 	self.javaObject:setVisible(bVisible);
--~ end

function NPC_ISCharacterInfoWindow:isActive(viewName)
	-- first test, is the view still inside our tab panel ?
	for ind,value in ipairs(self.panel.viewList) do
		-- we get the view we want to display
		if value.name == viewName then
			return value.view:getIsVisible() and self:getIsVisible();
		end
	end
	-- if not (if we dragged it outside our tab panel), we look for it
	for i,v in pairs(NPC_ISCharacterInfoWindow.view) do
		if v:getTitle() == viewName then
			return v:getIsVisible();
		end
	end
	return false;
end


function NPC_ISCharacterInfoWindow:toggleView(viewName)
	-- if we haven't found our view in the tab panel, it's because someone dragged it outside
--~ 	if not self.panel:activateView(viewName) then
--~ 		for i,v in pairs(NPC_ISCharacterInfoWindow.view) do
--~ 			if v.name == viewName then
--~ 				print("found view : " .. v.name .. " visible ");
--~ 				print(v.view:getIsVisible());
--~ 				v.view:setVisible(not v.view:getIsVisible());

--~ 			end
--~ 		end
--~ 	else

--~ 	end
	local view = self.panel:getView(viewName);
	if view then
        if view.infoText then
           self:setInfo(view.infoText);
        else
            self:setInfo(nil);
        end
		if self:getIsVisible() then
			if view == self.panel:getActiveView() then
				self:close()
			else
				self.panel:activateView(viewName)
			end
		else
			self.panel:activateView(viewName)
			self:setVisible(true)
			self:addToUIManager()
		end
	else
		for i,v in pairs(NPC_ISCharacterInfoWindow.view) do
			if v:getTitle() == viewName then
				v:setVisible(not v:getIsVisible())
			end
		end
	end
end

function NPC_ISCharacterInfoWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	local th = self:titleBarHeight()
	local rh = self:resizeWidgetHeight()
	self.panel = ISTabPanel:new(0, th, self.width, self.height-th-rh);
	self.panel:initialise();
    self.panel.tabPadX = 15;
    self.panel.equalTabWidth = false;
--~ 	self.panel.allowDraggingTab = false;
	self:addChild(self.panel);

	self.charScreen = NPC_ISCharacterScreen:new(0, 8, 420, 250, self.character);
	self.charScreen:initialise()
	self.panel:addView(xpSystemText.info, self.charScreen)

	self.character:getPerkLevel(Perks.Woodwork)
	self.characterView = NPC_ISCharacterInfo:new(0, 8, self.width, self.height-8, self.character);
	self.characterView:initialise()
    self.characterView.infoText = getText("UI_SkillPanel");
	self.panel:addView(xpSystemText.skills, self.characterView)

	self.healthView = ISHealthPanel:new(self.character, 0, 8, self.width, self.height-8)
	self.healthView:initialise()
    self.healthView.infoText = getText("UI_HealthPanel");
	self.panel:addView(xpSystemText.health, self.healthView)
	
	self.protectionView = NPC_ISCharacterProtection:new(0, 8, self.width, self.height-8, self.character)
	self.protectionView:initialise()
	self.protectionView.infoText = getText("UI_ProtectionPanel");
	self.panel:addView(xpSystemText.protection, self.protectionView)

    self.clothingView = ISClothingInsPanel:new(self.character, 0, 8, self.width, self.height-8)
    self.clothingView:initialise()
    self.clothingView.infoText = getText("UI_ClothingInsPanel");
    self.panel:addView(xpSystemText.clothingIns, self.clothingView)

	-- Set the correct size before restoring the layout.  Currently, ISCharacterScreen:render sets the height/width.
    print(self.charScreen)
	self:setWidth(self.charScreen.width)
	self:setHeight(self.charScreen.height);
    self.visibleOnStartup = self:getIsVisible() -- hack, see ISPlayerDataObject.lua
    if getCore():getGameMode() == "Tutorial" then self:setVisible(false); end
end

function NPC_ISCharacterInfoWindow:render()
	ISCollapsableWindow.render(self)
end

function NPC_ISCharacterInfoWindow:close()
    NPC_ISCharacterInfoWindow.instance = nil
	self:setVisible(false)
	self:removeFromUIManager() -- so update() isn't called
end

function NPC_ISCharacterInfoWindow:RestoreLayout(name, layout)
    ISLayoutManager.DefaultRestoreWindow(self, layout)
	local floating = { info = true, skills = true, health = true, protection = true, clothingIns = true  }
    if layout.tabs ~= nil then
		local tabs = string.split(layout.tabs, ',')
		for k,v in pairs(tabs) do
			if v == 'info' then
				floating.info = false
			elseif v == 'skills' then
				floating.skills = false
			elseif v == 'health' then
				floating.health = false
			elseif v == 'protection' then
				floating.protection = false
            elseif v == 'clothingIns' then
                floating.clothingIns = false
			end		end
	else
		floating.info = false
		floating.skills = false
		floating.health = false
		floating.protection = false
        floating.clothingIns = false	end
	if floating.info then
		self.panel:removeView(self.charScreen)
		local newWindow = ISCollapsableWindow:new(0, 0, self.charScreen:getWidth(), self.charScreen:getHeight());
		newWindow:initialise();
		newWindow:addToUIManager();
		newWindow:addView(self.charScreen);
		newWindow:setTitle(xpSystemText.info);
	end
	if floating.skills then
		self.panel:removeView(self.characterView)
		-- ISCharacterInfo:render() sets the desired window size, BIG CHEAT to get it now 
		local width = self.characterView.txtLen + 180
		local height = (110 + PerkFactory.PerkList:size() * 20) + 8
		local newWindow = ISCollapsableWindow:new(0, 0, width, height);
		newWindow:initialise();
		newWindow:addToUIManager();
		newWindow:addView(self.characterView);
		newWindow:setTitle(xpSystemText.skills);
	end
	if floating.health then
		self.panel:removeView(self.healthView)
		-- ISHealthPanel:render() sets the desired window size, BIG CHEAT to get it now 
		local width = self.healthView.healthPanel:getWidth()
		local height = self.healthView.healthPanel:getHeight() + 30
		local newWindow = ISCollapsableWindow:new(0, 0, width, height);
		newWindow:initialise();
		newWindow:addToUIManager();
		newWindow:addView(self.healthView);
		newWindow:setTitle(xpSystemText.health);
    end
    if floating.clothingIns and false then
        self.panel:removeView(self.clothingView)
        -- ISHealthPanel:render() sets the desired window size, BIG CHEAT to get it now
        local width = self.clothingView:getWidth()
        local height = self.clothingView:getHeight() + 30
        local newWindow = ISCollapsableWindow:new(0, 0, width, height);
        newWindow:initialise();
        newWindow:addToUIManager();
        newWindow:addView(self.clothingView);
        newWindow:setTitle(xpSystemText.clothingIns);
    end
	if floating.porotection then
		self.panel:removeView(self.protectionView)
		local newWindow = ISCollapsableWindow:new(0, 0, self.protectionView:getWidth(), self.protectionView:getHeight());
		newWindow:initialise();
		newWindow:addToUIManager();
		newWindow:addView(self.protectionView);
		newWindow:setTitle(xpSystemText.protection);
	end
	if layout.current and not floating[layout.current] then
		self.panel:activateView(xpSystemText[layout.current])
	end
end

function NPC_ISCharacterInfoWindow:SaveLayout(name, layout)
    ISLayoutManager.DefaultSaveWindow(self, layout)
    layout.width = nil
    layout.height = nil
    layout.current = nil
	local tabs = {}
	if self.charScreen.parent == self.panel then
		table.insert(tabs, 'info')
		if self.charScreen == self.panel:getActiveView() then
			layout.current = 'info'
		end
	end
	if self.characterView.parent == self.panel then
		table.insert(tabs, 'skills')
		if self.characterView == self.panel:getActiveView() then
			layout.current = 'skills'
		end
	end
	if self.healthView.parent == self.panel then
		table.insert(tabs, 'health')
		if self.healthView == self.panel:getActiveView() then
			layout.current = 'health'
		end
    end
    if self.clothingView.parent == self.panel then
        table.insert(tabs, 'clothingIns')
        if self.clothingView == self.panel:getActiveView() then
            layout.current = 'clothingIns'
        end
    end
	if self.protectionView.parent == self.panel then
		table.insert(tabs, 'protection')
		if self.protectionView == self.panel:getActiveView() then
			layout.current = 'protection'
		end
	end
	layout.tabs = table.concat(tabs, ',')
end

function NPC_ISCharacterInfoWindow:new(x, y, width, height, character)
	local o = {};
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
--	o:noBackground();
	o:setResizable(false)
	o.visibleOnStartup = false
    o.character = character
	NPC_ISCharacterInfoWindow.instance = o;
	return o;
end

function NPC_ISCharacterInfoWindow.OnClothingUpdated(chr)
	if (chr:getModData().NPC and NPC_ISCharacterInfoWindow.instance) then
    	NPC_ISCharacterInfoWindow.instance.charScreen.refreshNeeded = true
	end
end

Events.OnClothingUpdated.Add(NPC_ISCharacterInfoWindow.OnClothingUpdated)

