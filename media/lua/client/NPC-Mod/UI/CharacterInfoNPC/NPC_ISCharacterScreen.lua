--***********************************************************
--**                    ROBERT JOHNSON                     **
--**              Panel wich display all our skills        **
--***********************************************************

require "ISUI/ISPanelJoypad"
require "ISUI/ISUI3DModel"

NPC_ISCharacterScreen = ISPanelJoypad:derive("NPC_ISCharacterScreen");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-----

NPC_ISCharacterScreenAvatar = ISUI3DModel:derive("NPC_ISCharacterScreenAvatar")

function NPC_ISCharacterScreenAvatar:onMouseUp(x, y)
	ISUI3DModel.onMouseUp(self, x, y)
end

function NPC_ISCharacterScreenAvatar:new(x, y, width, height)
	local o = ISUI3DModel.new(self, x, y, width, height)
	return o
end

-----

--************************************************************************--
--** ISPanel:initialise
--**
--************************************************************************--

local function predicateNotBroken(item)
	return not item:isBroken()
end

function NPC_ISCharacterScreen:initialise()
	ISPanelJoypad.initialise(self);
	self:create();
end


function NPC_ISCharacterScreen:setVisible(visible, joypadData)
--    self.parent:setVisible(visible);
	if visible then
		self:loadTraits();
		self:loadProfession();
	end
    self.javaObject:setVisible(visible);
end

function NPC_ISCharacterScreen:prerender()
	ISPanelJoypad.prerender(self)

	self:updateAvatar()

	if self.bFemale ~= self.char:isFemale() then
		self.bFemale = self.char:isFemale()
		self.sexText = self.bFemale and getText("IGUI_char_Female") or getText("IGUI_char_Male")
	end

	local x,y,w,h = self.avatarX, self.avatarY, self.avatarWidth, self.avatarHeight
	self:drawRectBorder(x - 2, y - 2, w + 4, h + 4, 1, 0.3, 0.3, 0.3);
	self:drawTextureScaled(self.avatarBackgroundTexture, x, y, w, h, 1, 1, 1, 1);
--	self:drawRect(x, y, w, h, 0.8,0,0,0);
end

function NPC_ISCharacterScreen:render()

--	if self.Strength ~= self.char:getPerkLevel(Perks.Strength) or
--			self.Fitness ~= self.char:getPerkLevel(Perks.Fitness) then
	if self:traitsChanged() then
		self:loadTraits();
    end
    self:loadProfession();
	self:loadBeardAndHairStyle();
--	end
	
--~ 	NPC_ISCharacterScreen.loadTraits(self);

	NPC_ISCharacterScreen.loadFavouriteWeapon(self);


	local z = 25;

	local nameText = self.char:getDescriptor():getForename().." "..self.char:getDescriptor():getSurname()
	local nameX = self.avatarX + self.avatarWidth + 25
	local nameWid = getTextManager():MeasureStringX(UIFont.Medium, nameText)
	self:drawText(nameText, nameX, z, 1,1,1,1, UIFont.Medium);

	local professionWid = self.profImage:getWidth()
    if not self.professionTexture then
		professionWid = math.max(professionWid, getTextManager():MeasureStringX(UIFont.Small, self.profession))
        self:drawText(self.profession, self.width - 20 - professionWid, z, 1,1,1,1,UIFont.Small);
        self.profImage:setVisible(false);
    else
        self.profImage:setVisible(true);
        self.profImage:setMouseOverText(self.profession);
        self.profImage.texture = self.professionTexture;
    end

	local hairWidth = getTextManager():MeasureStringX(UIFont.Small, self.hairStyle)
	local beardWidth = self.char:isFemale() and 0 or getTextManager():MeasureStringX(UIFont.Small, self.beardStyle)
	local hairBeardButtonX = self.xOffset + 10 + math.max(hairWidth, beardWidth) + 10

	local panelWidth = self.avatarX + self.avatarWidth + 25 + nameWid + 20 + professionWid + 20
	panelWidth = math.max(panelWidth, nameX + nameWid + 40 + self.profImage.width + 20)
	panelWidth = math.max(panelWidth, hairBeardButtonX + self.hairButton.width + 20)
	self:setWidthAndParentWidth(panelWidth)

	self.profImage:setX(panelWidth - 20 - self.profImage.width)

	z = z + FONT_HGT_MEDIUM;
	self:drawRect(nameX, z, nameWid + 2, 1, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

	z = z + 10;

	local smallFontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()

	z = z + smallFontHgt;
	self:drawTextRight(getText("IGUI_char_Sex"), self.xOffset, z, 1,1,1,1, UIFont.Small);
	self:drawText(self.sexText, self.xOffset + 10, z, 1,1,1,0.5, UIFont.Small);

    z = z + smallFontHgt;
--    self:drawTextRight("Cal", self.xOffset, z, 1,1,1,1, UIFont.Small);
--    self:drawText(round(self.char:getNutrition():getCalories(), 2) .. "", self.xOffset + 10, z, 1,1,1,0.5, UIFont.Small);
    self:drawTextRight(getText("IGUI_char_Weight"), self.xOffset, z, 1,1,1,1, UIFont.Small);
    local weightStr = tostring(round(self.char:getNutrition():getWeight(), 0))
    self:drawText(weightStr, self.xOffset + 10, z, 1,1,1,0.5, UIFont.Small);
	if self.char:getNutrition():isIncWeight() or self.char:getNutrition():isIncWeightLot() or self.char:getNutrition():isDecWeight() then
		local nutritionWidth = getTextManager():MeasureStringX(UIFont.Small, weightStr) + 13;
		if self.char:getNutrition():isIncWeight() and not self.char:getNutrition():isIncWeightLot() then
			self:drawTexture(self.weightIncTexture, self.xOffset + nutritionWidth, z + 3, 1, 0.8, 0.8, 0.8)
		end
		if self.char:getNutrition():isIncWeightLot() then
			self:drawTexture(self.weightIncLotTexture, self.xOffset + nutritionWidth, z, 1, 0.8, 0.8, 0.8)
		end
		if self.char:getNutrition():isDecWeight() then
			self:drawTexture(self.weightDecTexture, self.xOffset + nutritionWidth, z + 3, 1, 0.8, 0.8, 0.8)
		end
	end
--    z = z + 14;
--    self:drawTextRight("Carb/Prot/Lip", self.xOffset, z, 1,1,1,1, UIFont.Small);
--    self:drawText(round(self.char:getNutrition():getCarbohydrates(),2) .. "," .. round(self.char:getNutrition():getProteins(),2) .. "," .. round(self.char:getNutrition():getLipids(),2), self.xOffset + 10, z, 1,1,1,0.5, UIFont.Small);
--    z = z + 14;

	z = z + smallFontHgt;
	local traitBottom = z
	local finalY = z + (math.max(FONT_HGT_SMALL, 18) - 18) / 2 + 2;
	if #self.traits > 0 then
		self:drawTextRight(getText("IGUI_char_Traits"), self.xOffset, z, 1,1,1,1, UIFont.Small);
		local x = self.xOffset + 10;
		local y = z + (math.max(FONT_HGT_SMALL, 18) - 18) / 2 + 2
		for i,v in ipairs(self.traits) do
			v:setY(y);
			v:setX(x);
            v:setVisible(true);
			traitBottom = y + v:getTexture():getHeightOrig() + 2
			x = x + v:getTexture():getWidthOrig() + 6;
			if (i < #self.traits) and (x + v:getTexture():getWidthOrig() > self:getWidth() - 20) then
				x = self.xOffset + 10
				y = y + v:getTexture():getHeightOrig() + 2
			end
		end
		finalY = y + self.traits[1]:getTexture():getHeightOrig();
	end

	finalY = finalY + 20;

	self:drawTextRight(getText("IGUI_char_HairStyle"), self.xOffset, finalY, 1,1,1,1, UIFont.Small);
	self:drawText(self.hairStyle, self.xOffset + 10, finalY, 1,1,1,0.5, UIFont.Small);
	self.hairButton:setVisible(true);
	self.hairButton:setX(hairBeardButtonX);
	self.hairButton:setY(finalY);
	self.hairButton.enable = true;
	self.hairButton.tooltip = nil;
	
	if not isDebugEnabled() then
		local currentHairStyle = getHairStylesInstance():FindMaleStyle(self.char:getHumanVisual():getHairModel())
		if self.char:isFemale() then
			currentHairStyle = getHairStylesInstance():FindFemaleStyle(self.char:getHumanVisual():getHairModel())
		end
		if not currentHairStyle or currentHairStyle:getLevel() <= 0 then
			self.hairButton.enable = false;
			self.hairButton.tooltip = getText("Tooltip_NoHair");
		end
--		if not self.char:getInventory():containsTypeRecurse("Scissors") then
--			self.hairButton.enable = false;
--			self.hairButton.tooltip = getText("Tooltip_RequireScissors");
--		end
	end

	finalY = finalY + smallFontHgt + 4;

	if not self.char:isFemale() then
		self:drawTextRight(getText("IGUI_char_BeardStyle"), self.xOffset, finalY, 1,1,1,1, UIFont.Small);
		self:drawText(self.beardStyle, self.xOffset + 10, finalY, 1,1,1,0.5, UIFont.Small);
		self.beardButton:setVisible(true);
		self.beardButton:setX(hairBeardButtonX);
		self.beardButton:setY(finalY);
		self.beardButton.enable = true;
		self.beardButton.tooltip = nil;
	
		local currentBeardStyle = getBeardStylesInstance():FindStyle(self.char:getHumanVisual():getBeardModel())
		if not isDebugEnabled() then
			if not currentBeardStyle or currentBeardStyle:getLevel() <= 0 then
				self.beardButton.enable = false;
				self.beardButton.tooltip = getText("Tooltip_NoBeard");
			end
--			if not self.char:getInventory():containsTypeRecurse("Razor") and not self.char:getInventory():containsTypeRecurse("Scissors") then
--				self.beardButton.enable = false;
--				self.beardButton.tooltip = getText("Tooltip_requireRazorOrScissors");
--			end
		end
	end

	z = math.max(z + 45, traitBottom);
	z = math.max(z, self.avatarY + self.avatarHeight + 25)
	local textWid1 = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_char_Favourite_Weapon"))
	local textWid2 = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_char_Zombies_Killed"))
	local textWid3 = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_char_Survived_For"))
	local x = 20 + math.max(textWid1, math.max(textWid2, textWid3))
	
	if self.favouriteWeapon then
		self:drawTextRight(getText("IGUI_char_Favourite_Weapon"), x, z, 1,1,1,1, UIFont.Small);
		self:drawText(self.favouriteWeapon, x + 10, z, 1,1,1,0.5, UIFont.Small);
		z = z + smallFontHgt;
	end
	self:drawTextRight(getText("IGUI_char_Zombies_Killed"), x, z, 1,1,1,1, UIFont.Small);
	self:drawText(self.char:getZombieKills() .. "", x + 10, z, 1,1,1,0.5, UIFont.Small);
	z = z + smallFontHgt;
	--[[
	self:drawTextRight(getText("IGUI_char_Survivor_Killed"), x, z, 1,1,1,1, UIFont.Small);
	self:drawText("0", x + 10, z, 1,1,1,0.5, UIFont.Small);
	z = z + smallFontHgt + 6;
	self:drawRect(30, z, self.width - 60, 1, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	z = z + 6;
	--]]
	local clock = UIManager.getClock()
	if instanceof(self.char, 'IsoPlayer') and clock and clock:isDateVisible() then
		self:drawTextRight(getText("IGUI_char_Survived_For"), x, z, 1,1,1,1, UIFont.Small);
		self:drawText(self.char:getTimeSurvived(), x + 10, z, 1,1,1,0.5, UIFont.Small);
	end
	
	z = z + smallFontHgt + 10

	self:setHeightAndParentHeight(z)
end

function NPC_ISCharacterScreen:maxTextWidth(font, text, maxWidth)
	local width = getTextManager():MeasureStringX(font, text)
	return math.max(width, maxWidth)
end

function NPC_ISCharacterScreen:create()
--~ 	if self.avatar == nil then
--~ 		self:createAvatar();
--~ 	end

--~ 	self.avatarPanel = ISPanel:new(30, 80, 96, 96);
--~ 	self.avatarPanel:initialise();

--~ 	self:addChild(self.avatarPanel);
--~ 	self.avatarPanel.backgroundColor = {r=0, g=0, b=0, a=0.8};
--~ 	self.avatarPanel.borderColor = {r=1, g=1, b=1, a=0.2};
--~ 	self.avatarPanel.render = NPC_ISCharacterScreen.drawAvatar;

	self.sexText = getText("IGUI_char_Male");
	if self.char:isFemale() then
		self.sexText = getText("IGUI_char_Female");
	end

	NPC_ISCharacterScreen.loadTraits(self);

	NPC_ISCharacterScreen.loadProfession(self);

	local texSize = 64
	self.profImage = ISImage:new(self:getWidth() - texSize - 20, 25, texSize, texSize, nil);
	self.profImage:initialise();
	self:addChild(self.profImage);

	self.avatarX = 25
	self.avatarY = 25
	self.avatarWidth = 128
	self.avatarHeight = 256
	self.avatarPanel = NPC_ISCharacterScreenAvatar:new(self.avatarX, self.avatarY, self.avatarWidth, self.avatarHeight)
	self.avatarPanel:setVisible(true)
	self:addChild(self.avatarPanel)
	self.avatarPanel:setOutfitName("Foreman", false, false)
	self.avatarPanel:setState("idle")
	self.avatarPanel:setDirection(IsoDirections.S)
	self.avatarPanel:setIsometric(false)

	self.avatarBackgroundTexture = getTexture("media/ui/avatarBackground.png")

	local textWid = 0
	textWid = self:maxTextWidth(UIFont.Small, getText("IGUI_char_Age"), textWid)
	textWid = self:maxTextWidth(UIFont.Small, getText("IGUI_char_Sex"), textWid)
	textWid = self:maxTextWidth(UIFont.Small, getText("IGUI_char_Weight"), textWid)
	textWid = self:maxTextWidth(UIFont.Small, getText("IGUI_char_Traits"), textWid)
	textWid = self:maxTextWidth(UIFont.Small, getText("IGUI_char_HairStyle"), textWid)
	textWid = self:maxTextWidth(UIFont.Small, getText("IGUI_char_BeardStyle"), textWid)
	self.xOffset = self.avatarX + self.avatarWidth + 25 + textWid
	
	local btnWid = 70
	local btnHgt = FONT_HGT_SMALL

	self.hairButton = ISButton:new(0,0, btnWid, btnHgt, getText("IGUI_PlayerStats_Change"), self, NPC_ISCharacterScreen.hairMenu);
	self.hairButton.anchorTop = false
	self.hairButton.anchorBottom = true
	self.hairButton:initialise();
	self.hairButton:instantiate();
	self.hairButton.borderColor = {r=1, g=1, b=1, a=0.1};
	self.hairButton:setVisible(false);
	self:addChild(self.hairButton);
	
	self.beardButton = ISButton:new(0,0, btnWid, btnHgt, getText("IGUI_PlayerStats_Change"), self, NPC_ISCharacterScreen.beardMenu);
	self.beardButton.anchorTop = false
	self.beardButton.anchorBottom = true
	self.beardButton:initialise();
	self.beardButton:instantiate();
	self.beardButton.borderColor = {r=1, g=1, b=1, a=0.1};
	self.beardButton:setVisible(false);
	self:addChild(self.beardButton);
end

function NPC_ISCharacterScreen:hairMenu(button)
	local player = self.char;
	local context = ISContextMenu.get(0, button:getAbsoluteX(), button:getAbsoluteY() + button:getHeight());
	local playerInv = player:getInventory()
	
	-- hair
	local currentHairStyle = getHairStylesInstance():FindMaleStyle(player:getHumanVisual():getHairModel())
	local hairList = getHairStylesInstance():getAllMaleStyles();
	if player:isFemale() then
		currentHairStyle = getHairStylesInstance():FindFemaleStyle(player:getHumanVisual():getHairModel())
		hairList = getHairStylesInstance():getAllFemaleStyles();
	end
	-- if we have hair long enough to trim it
	if currentHairStyle and currentHairStyle:getLevel() > 0 then
--		local option = context:addOption(getText("IGUI_char_HairStyle"))
--		local hairMenu = context:getNew(context)
--		context:addSubMenu(option, hairMenu)
		local hairMenu = context
		
		if isDebugEnabled() then
			if player:isFemale() then
				hairMenu:addOption("[DEBUG] Grow Long2", player, NPC_ISCharacterScreen.onCutHair, "Long2", 10);
			else
				hairMenu:addOption("[DEBUG] Grow Fabian", player, NPC_ISCharacterScreen.onCutHair, "Fabian", 10);
			end
		end
		
		-- if we have an attached hair model but non nonAttachedHair reference, we get one
		if currentHairStyle:isAttachedHair() and not player:getVisual():getNonAttachedHair() then
			-- get the growReference of our current level, it'll become our nonAttachedHair, so if we decide to detach our hair (from a pony tail for ex.) we'll go back to this growReference
			for i=0, hairList:size()-1 do
				local hairStyle = hairList:get(i);
				if hairStyle:getLevel() == currentHairStyle:getLevel() and hairStyle:isGrowReference() then
					player:getVisual():setNonAttachedHair(hairStyle:getName());
				end
			end
		end
		
		-- untie hair
		if player:getVisual():getNonAttachedHair() then
			hairMenu:addOption(getText("ContextMenu_UntieHair"), player, NPC_ISCharacterScreen.onCutHair, player:getVisual():getNonAttachedHair(), 100);
		end
		
		if not player:getVisual():getNonAttachedHair() then
			-- add attached hair
			for i=0, hairList:size()-1 do
				local hairStyle = hairList:get(i);
				if hairStyle:getLevel() <= currentHairStyle:getLevel() and hairStyle:getName() ~= currentHairStyle:getName() and hairStyle:isAttachedHair() and hairStyle:getName() ~= "" then
					hairMenu:addOption(getText("ContextMenu_TieHair", getText("IGUI_Hair_" .. hairStyle:getName())), player, NPC_ISCharacterScreen.onCutHair, hairStyle:getName(), 100);
				end
			end
			
			-- add all "under level" we can find, any level 2 hair can be cut into a level 1
			for i=0, hairList:size()-1 do
				local hairStyle = hairList:get(i);
				if not hairStyle:isAttachedHair() and hairStyle:getLevel() < currentHairStyle:getLevel() and hairStyle:getName() ~= "" then
					local option = hairMenu:addOption(getText("ContextMenu_CutHairFor", getText("IGUI_Hair_" .. hairStyle:getName())), player, NPC_ISCharacterScreen.onCutHair, hairStyle:getName(), 300);
					if hairStyle:getName() == "Bald" then
						option.name = getText("ContextMenu_ShaveHair");
						if not player:getInventory():containsTypeRecurse("Razor") and not player:getInventory():containsTypeRecurse("Scissors") then
							self:addTooltip(option, getText("Tooltip_requireRazorOrScissors"));
						end
					elseif not player:getInventory():containsTypeRecurse("Scissors") then
						self:addTooltip(option, getText("Tooltip_RequireScissors"));
					end
				end
			end
			-- add other special trim
			for i=0, currentHairStyle:getTrimChoices():size()-1 do
				local hairStyle = currentHairStyle:getTrimChoices():get(i);
				local option = hairMenu:addOption(getText("ContextMenu_CutHairFor", getText("IGUI_Hair_" .. hairStyle)), player, NPC_ISCharacterScreen.onCutHair, hairStyle, 300);
				if not player:getInventory():containsTypeRecurse("Scissors") then
					self:addTooltip(option, getText("Tooltip_RequireScissors"));
				end
			end
		end
	else
--		local option = context:addOption(getText("IGUI_char_HairStyle"))
--		local hairMenu = context:getNew(context)
--		context:addSubMenu(option, hairMenu)
		local hairMenu = context
		
		if isDebugEnabled() then
			if player:isFemale() then
				hairMenu:addOption("[DEBUG] Grow Long2", player, NPC_ISCharacterScreen.onCutHair, "Long2", 10);
			else
				hairMenu:addOption("[DEBUG] Grow Fabian", player, NPC_ISCharacterScreen.onCutHair, "Fabian", 10);
			end
		end
	end

end

function NPC_ISCharacterScreen:addTooltip(option, text)
	local tooltip = ISWorldObjectContextMenu.addToolTip();
	option.notAvailable = true;
	tooltip.description = text;
	option.toolTip = tooltip;
end

function NPC_ISCharacterScreen:beardMenu(button)
	local player = self.char;
	local context = ISContextMenu.get(0, button:getAbsoluteX(), button:getAbsoluteY() + button:getHeight());
	local playerInv = player:getInventory()
	
	local currentBeardStyle = getBeardStylesInstance():FindStyle(player:getHumanVisual():getBeardModel())
	-- if we have a beard long enough to trim it
	if currentBeardStyle and currentBeardStyle:getLevel() > 0 then
--		local option = context:addOption(getText("IGUI_char_BeardStyle"))
--		local beardMenu = context:getNew(context)
--		context:addSubMenu(option, beardMenu)
		local beardMenu = context
		
		if isDebugEnabled() then
			beardMenu:addOption("[DEBUG] Grow Long", player, NPC_ISCharacterScreen.onTrimBeard, "Long");
		end
		
		local option = beardMenu:addOption(getText("ContextMenu_TrimBeard"), player, NPC_ISCharacterScreen.onTrimBeard)
		if not player:getInventory():containsTypeRecurse("Razor") and not player:getInventory():containsTypeRecurse("Scissors") then
			self:addTooltip(option, getText("Tooltip_requireRazorOrScissors"));
		end
		-- add all "under level" we can find, any level 2 beard/hair can be trim into a level 1
		local allBeard = getBeardStylesInstance():getAllStyles();
		for i=0, allBeard:size()-1 do
			local beardStyle = allBeard:get(i);
			if beardStyle:getLevel() < currentBeardStyle:getLevel() and beardStyle:getName() ~= "" then
				local option = beardMenu:addOption(getText("ContextMenu_TrimBeard_For", getText("IGUI_Beard_" .. beardStyle:getName())), player, NPC_ISCharacterScreen.onTrimBeard, beardStyle:getName());
				if not player:getInventory():containsTypeRecurse("Razor") and not player:getInventory():containsTypeRecurse("Scissors") then
					self:addTooltip(option, getText("Tooltip_requireRazorOrScissors"));
				end
			end
		end
		-- add other special trim (a goatee can become a moustache, etc.)
		for i=0, currentBeardStyle:getTrimChoices():size()-1 do
			local beardStyle = currentBeardStyle:getTrimChoices():get(i);
			local option = beardMenu:addOption(getText("ContextMenu_TrimBeard_For", getText("IGUI_Beard_" .. beardStyle)), player, NPC_ISCharacterScreen.onTrimBeard, beardStyle);
			if not player:getInventory():containsTypeRecurse("Razor") and not player:getInventory():containsTypeRecurse("Scissors") then
				self:addTooltip(option, getText("Tooltip_requireRazorOrScissors"));
			end
		end
	else
--		local option = context:addOption(getText("IGUI_char_BeardStyle"))
--		local beardMenu = context:getNew(context)
--		context:addSubMenu(option, beardMenu)
		local beardMenu = context
		
		if isDebugEnabled() then
			beardMenu:addOption("[DEBUG] Grow Long", player, NPC_ISCharacterScreen.onTrimBeard, "Long");
		end
	end
end

NPC_ISCharacterScreen.onTrimBeard = function(playerObj, beardStyle)
	local playerInv = playerObj:getInventory()
	local scissors = playerInv:getFirstTypeEvalRecurse("Base.Razor", predicateNotBroken) or playerInv:getFirstTypeEvalRecurse("Base.Scissors", predicateNotBroken);
	ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), scissors, true)
	ISTimedActionQueue.add(ISTrimBeard:new(playerObj, beardStyle, scissors, 300));
end

NPC_ISCharacterScreen.onCutHair = function(playerObj, hairStyle, time)
	local playerInv = playerObj:getInventory()
	local newHairStyle = getHairStylesInstance():FindMaleStyle(hairStyle)
	if playerObj:isFemale() then
		newHairStyle = getHairStylesInstance():FindFemaleStyle(hairStyle)
	end
	
	local scissors = playerInv:getFirstTypeEvalRecurse("Base.Scissors", predicateNotBroken);
	local razor = playerInv:getFirstTypeEvalRecurse("Base.Razor", predicateNotBroken);
	if newHairStyle:getName() ~= "Bald" and not newHairStyle:isAttachedHair() and not playerObj:getVisual():getNonAttachedHair() then
		ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), scissors or razor, true)
	end
	if newHairStyle:getName() == "Bald" then
		if scissors then
			ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), scissors, true)
		elseif razor then
			ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), razor, true)
		end
	end
	
	ISTimedActionQueue.add(ISCutHair:new(playerObj, hairStyle, scissors or razor, time));
end

NPC_ISCharacterScreen.setDisplayedTraits = function(self)
	table.wipe(self.displayedTraits)
	local traits = self.char:getTraits()
	for i=1,traits:size() do
		local trait = TraitFactory.getTrait(traits:get(i-1))
		if trait and trait:getTexture() then
			table.insert(self.displayedTraits, trait)
		end
	end
end

NPC_ISCharacterScreen.traitsChanged = function(self)
	self:setDisplayedTraits()
	if #self.displayedTraits ~= #self.traits then
		return true
	end
	for i=1,#self.traits do
		if self.displayedTraits[i] ~= self.traits[i].trait then
			return true
		end
	end
	return false
end

NPC_ISCharacterScreen.loadTraits = function(self)
	for _,image in ipairs(self.traits) do
		self:removeChild(image)
	end
	table.wipe(self.traits);
	self:setDisplayedTraits()
	for _,trait in ipairs(self.displayedTraits) do
		local textImage = ISImage:new(0, 0, trait:getTexture():getWidthOrig(), trait:getTexture():getHeightOrig(), trait:getTexture());
		textImage:initialise();
		textImage:setMouseOverText(trait:getLabel());
		textImage:setVisible(false);
		textImage.trait = trait;
		self:addChild(textImage);
		table.insert(self.traits, textImage);
	end
	self.Strength = self.char:getPerkLevel(Perks.Strength)
	self.Fitness = self.char:getPerkLevel(Perks.Fitness)
end

NPC_ISCharacterScreen.loadBeardAndHairStyle = function(self)
	local currentHairStyle = getHairStylesInstance():FindMaleStyle(self.char:getHumanVisual():getHairModel())
	local currentBeardStyle;
	if self.char:isFemale() then
		currentHairStyle = getHairStylesInstance():FindFemaleStyle(self.char:getHumanVisual():getHairModel())
	else
		currentBeardStyle = getBeardStylesInstance():FindStyle(self.char:getHumanVisual():getBeardModel())
		if currentBeardStyle and currentBeardStyle:getName() ~= "" then
			self.beardStyle =  getText("IGUI_Beard_" .. currentBeardStyle:getName());
		else
			self.beardStyle = getText("IGUI_Beard_None");
		end
	end
	if currentHairStyle and currentHairStyle:getName() ~= "" then
		self.hairStyle =  getText("IGUI_Hair_" .. currentHairStyle:getName());
	else
		self.hairStyle = getText("IGUI_Hair_Bald");
	end
end

NPC_ISCharacterScreen.loadProfession = function(self)
	self.professionTexture = nil;
	self.profession = nil;
	if self.char:getDescriptor() and self.char:getDescriptor():getProfession() then
		local prof = ProfessionFactory.getProfession(self.char:getDescriptor():getProfession());
		if prof then
			self.profession = prof:getName();
			self.professionTexture = prof:getTexture();
		end
	end
end

NPC_ISCharacterScreen.loadFavouriteWeapon = function(self)
	self.favouriteWeapon = nil;
	local swing = 0;
	for iPData,vPData in pairs(self.char:getModData()) do
		for index in string.gmatch(iPData, "^Fav:(.+)") do
			if vPData > swing then
				self.favouriteWeapon = index;
				swing = vPData;
			end
		end
	end
end

function NPC_ISCharacterScreen:updateAvatar()
	if not self.refreshNeeded then return end
	self.refreshNeeded = false
	self.avatarPanel:setCharacter(self.char)
end

--[[
function NPC_ISCharacterScreen:drawAvatar()
	local x = self:getAbsoluteX();
	local y = self:getAbsoluteY();
	x = x + 96/2 + 22;
	y = y + 190;


	-- we recreate the survivor display every tick, so if you changed clothes, you'll see it
	if not self.avatar then
		self.avatar = IsoSurvivor.new(self.char:getDescriptor(), nil, 0, 0, 0);
		self.avatar:setDir(IsoDirections.SE);
		self.avatar:PlayAnimWithSpeed("Idle", 0.1);
	end

	self.avatar:drawAt(x,y);
end
--]]

function NPC_ISCharacterScreen:initJoypadButtons(joypadData)
	self.joypadButtonsY = {}
	self:insertNewLineOfButtons(self.hairButton)
	if not self.char:isFemale() then
		self:insertNewLineOfButtons(self.beardButton)
	end
	if #self.joypadButtonsY > 0 then
		self.joypadIndex = 1
		self.joypadIndexY = 1
		self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
		self.joypadButtons[self.joypadIndex]:setJoypadFocused(true)
	end
end

function NPC_ISCharacterScreen:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData)
	self:initJoypadButtons(joypadData)
end

function NPC_ISCharacterScreen:onLoseJoypadFocus(joypadData)
	ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
	self:clearJoypadFocus(joypadData)
end

function NPC_ISCharacterScreen:new(x, y, width, height, character)
	local o = {};
	o = ISPanelJoypad:new(x, y, width, height);
	o:noBackground();
	setmetatable(o, self);
    self.__index = self;
	o.char = character
--[[
	o.avatar = IsoSurvivor.new(o.char:getDescriptor(), nil, 0, 0, 0);
	o.avatar:setDir(IsoDirections.SE);
	o.avatar:PlayAnimWithSpeed("Idle", 0.1);
--]]
	o.refreshNeeded = true
	o.bFemale = o.char:isFemale()
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.backgroundColor = {r=0, g=0, b=0, a=0.8};
	o.weightIncTexture = getTexture("media/ui/chevron_up.png")
	o.weightIncLotTexture = getTexture("media/ui/chevron_double.png")
	o.weightDecTexture = getTexture("media/ui/chevron_down.png")
	o.traits = {}
	self.displayedTraits = {}
	return o;
end
