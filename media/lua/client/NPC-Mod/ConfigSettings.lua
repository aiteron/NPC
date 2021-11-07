---Original NPCConfigSettings found in Sandbox+ (author: derLoko)
NPCConfigSettings = NPCConfigSettings or {}
NPCConfigSettings.mods = NPCConfigSettings.mods or {}


function NPCConfigSettings.prepModForLoad(mod)

	--link all the things!
	for gameOptionName,menuEntry in pairs(mod.menu) do
		if menuEntry then
			if menuEntry.options then
				menuEntry.optionsIndexes = menuEntry.options
				menuEntry.optionsKeys = {}
				menuEntry.optionsValues = {}
				menuEntry.optionLabels = {} -- passed on to UI elements
				for i,table in ipairs(menuEntry.optionsIndexes) do
					menuEntry.optionLabels[i] = table[1]
					local k = table[1]
					local v = table[2]
					menuEntry.optionsKeys[k] = {i, v}
					menuEntry.optionsValues[v] = {i, k}
				end
			end
		end
	end

	for gameOptionName,value in pairs(mod.config) do
		local menuEntry = mod.menu[gameOptionName]
		if menuEntry then
			if menuEntry.options then
				menuEntry.selectedIndex = menuEntry.optionsValues[value][1]
				menuEntry.selectedLabel = menuEntry.optionsValues[value][2]
			end
			menuEntry.selectedValue = value
		end
	end
end


local GameOption = ISBaseObject:derive("GameOptions")
function GameOption:new(name, control)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.name = name
	o.control = control

	if control.isCombobox then
		control.onChange = self.onChange
		control.target = o
	elseif control.isTickBox then
		control.changeOptionMethod = self.onChange
		control.changeOptionTarget = o
	else
		local go = o.gameOptions
		control.onTextChange = function()
			o.gameOptions.changed = true
		end
	end
	return o
end
function GameOption:onChange()
	self.gameOptions:onChange(self)
end


NPCConfigSettings_MainOptions_create = MainOptions.create

function MainOptions:create() -- override

	if NPCConfigSettings_MainOptions_create then
		NPCConfigSettings_MainOptions_create(self) -- call original
	end

	local NPCConfigSettings_self_gameOptions_toUI = self.gameOptions.toUI
	function self.gameOptions.toUI(self)
		for _,option in ipairs(self.options) do
			if option then option:toUI() end
		end
		self.changed = false
		return NPCConfigSettings_self_gameOptions_toUI(self)
	end

	local NPCConfigSettings_self_gameOptions_apply = self.gameOptions.apply
	function self.gameOptions.apply(self)
		for _,option in ipairs(self.options) do
			if option then
				option:apply()
			end
		end
		NPCConfigSettings.saveConfig()
		NPCConfigSettings.loadConfig()
		self.changed = false
		return NPCConfigSettings_self_gameOptions_apply(self)
	end

	local x = self:getWidth()/2.5
	local y = 30
	local width = 200
	local height = 20

	--new addText because MainOptions doesn't have it
	function addText(text, font, r, g, b, a, customX)
		self.addY = self.addY +7
		local label = ISLabel:new(x+(customX or 20),y+self.addY,height, text, r or 1, g or 1, b or 1, a or 1, font or UIFont.Small, true)
		label:initialise()
		self.mainPanel:addChild(label)
		self.addY = self.addY + height +5
		return label
	end

	--alternative addTickBox because I didn't like the one in MainOptions
	function addTickBox(text)
		local label = ISLabel:new(x,y+self.addY,height, text, 1,1,1,1, UIFont.Small, false)
		label:initialise()
		self.mainPanel:addChild(label)
		local box = ISTickBox:new(x+20,y+self.addY, width,height)
		box.choicesColor = {r=1, g=1, b=1, a=1}
		box:initialise()
		self.mainPanel:addChild(box)
		self.mainPanel:insertNewLineOfButtons(box)
		box:addOption("", nil) -- only add a single option with no values, our tickbox can only be true/false.
		self.addY = self.addY + height +5
		return box
	end

	--new addNumberBox because MainOptions doesn't have it
	function addNumberBox(text)
		local label = ISLabel:new(x,y+self.addY,height, text, 1,1,1,1, UIFont.Small, false)
		label:initialise()
		self.mainPanel:addChild(label)
		local box = ISTextEntryBox:new("", x+20,y+self.addY, 200,20)
		box.font = UIFont.Small
		box:initialise()
		box:instantiate()
		box:setOnlyNumbers(true)
		self.mainPanel:addChild(box)
		self.mainPanel:insertNewLineOfButtons(box)
		self.addY = self.addY + height +5
		return box
	end

	--new addSpace
	function addSpace()
		self.addY = self.addY + height +5
	end

	function createElements(mod, invalidAccess)
		--addText(mod.name, UIFont.Medium)
		--addSpace()
		if (not mod) or (not mod.menu) or (not (type(mod.menu) == "table")) then
			return
		end
		
		for gameOptionName,menuEntry in pairs(mod.menu) do
			if gameOptionName and menuEntry then
				if (not invalidAccess) or menuEntry.alwaysAccessible then

					--- TEXT ---
					if menuEntry.type == "Text" then
						addText(menuEntry.text, menuEntry.font, menuEntry.r, menuEntry.g, menuEntry.b, menuEntry.a, menuEntry.customX)
					end

					--- SPACE ---
					if menuEntry.type == "Space" then
						local iteration = menuEntry.iteration or 1
						for i=1, iteration do
							addSpace()
						end
					end

					--- TICK BOX ---
					if menuEntry.type == "Tickbox" then
						local box = addTickBox(menuEntry.title)
						local gameOption = GameOption:new(gameOptionName, box)
						function gameOption.toUI(self)
							local box = self.control
							local bool = menuEntry.selectedValue
							box.selected[1] = bool
						end
						function gameOption.apply(self)
							local box = self.control
							local bool = box.selected[1]
							menuEntry.selectedValue = bool
							menuEntry.selectedLabel = tostring(bool)
						end
						self.gameOptions:add(gameOption)
					end

					--- NUMBER BOX ---
					if menuEntry.type == "Numberbox" then
						local box = addNumberBox(menuEntry.title)
						local gameOption = GameOption:new(gameOptionName, box)
						function gameOption.toUI(self)
							local box = self.control
							box:setText( tostring(menuEntry.selectedValue) )
						end
						function gameOption.apply(self)
							local box = self.control
							local value = box:getText()
							menuEntry.selectedValue = tonumber(value)
						end
						self.gameOptions:add(gameOption)
					end

					--- COMBO BOX ---
					if menuEntry.type == "Combobox" then
						--addCombo(x,y,w,h, name,options, selected, target, onchange)
						local box = self:addCombo(x,y,200,20, menuEntry.title, menuEntry.optionLabels)
						if menuEntry.tooltip then
							box:setToolTipMap({defaultTooltip = menuEntry.tooltip})
						end
						local gameOption = GameOption:new(gameOptionName, box)
						function gameOption.toUI(self)
							local box = self.control
							box.selected = menuEntry.selectedIndex
						end
						function gameOption.apply(self)
							local box = self.control
							menuEntry.selectedIndex = box.selected
							menuEntry.selectedLabel = menuEntry.optionsIndexes[box.selected][1]
							menuEntry.selectedValue = menuEntry.optionsIndexes[box.selected][2]
						end
						self.gameOptions:add(gameOption)
						--self.addY = self.addY - 8
					end

					--- SPIN BOX ---
					if menuEntry.type == "Spinbox" then
						--addSpinBox(x,y,w,h, name, options, selected, target, onchange)
						local box = self:addSpinBox(x,y,200,20, menuEntry.title, menuEntry.optionLabels)
						local gameOption = GameOption:new(gameOptionName, box)
						function gameOption.toUI(self)
							local box = self.control
							box.selected = menuEntry.selectedIndex
						end
						function gameOption.apply(self)
							local box = self.control
							menuEntry.selectedIndex = box.selected
							menuEntry.selectedLabel = menuEntry.optionsIndexes[box.selected][1]
							menuEntry.selectedValue = menuEntry.optionsIndexes[box.selected][2]
						end
						self.gameOptions:add(gameOption)
					end
				end
			end
		end
		self.addY = self.addY + 15
	end

	for modId,mod in pairs(NPCConfigSettings.mods) do

		self.addY = 0
		self:addPage(string.upper(mod.name))

		local invalidAccess = false

		if (not mod.menuSpecificAccess) or (getPlayer() and mod.menuSpecificAccess=="ingame") or (not getPlayer() and mod.menuSpecificAccess=="mainmenu") then
		else
			invalidAccess = true
			if (not getPlayer() and mod.menuSpecificAccess=="ingame") then
				addText("This mod's options can only be accessed from the in-game options menu.", UIFont.Medium, 1, 1, 1, 1, -100)
			end
			if (getPlayer() and mod.menuSpecificAccess=="mainmenu") then
				addText("This mod has options that can only be accessed from the main-menu options.", UIFont.Medium, 1, 1, 1, 1, -100)
				addText("Note: Make sure to enable this mod from the main-menu to view the options.", UIFont.Small, 1, 1, 1, 1, -100)
			end
			addText(" ", UIFont.Medium)
		end

		createElements(mod, invalidAccess)

		self.addY = self.addY + MainOptions.translatorPane:getHeight() + 22
		self.mainPanel:setScrollHeight(self.addY + 20)
	end

end



function NPCConfigSettings.saveConfig()
	for modId,mod in pairs(NPCConfigSettings.mods) do
		local config = mod.config
		local menu = mod.menu
		local configFile = "media/config/"..modId..".config"
		local fileWriter = getModFileWriter(modId, configFile, true, false)
		if fileWriter then
			print("modId: "..modId.." saving")
			for gameOptionName,_ in pairs(config) do
				local menuEntry = menu[gameOptionName]
				if menuEntry then
					if menuEntry.selectedLabel then
						local menuEntry_selectedLabel = menuEntry.selectedLabel
						if type(menuEntry.selectedLabel) == "boolean" then
							menuEntry_selectedLabel = tostring(menuEntry_selectedLabel)
						end
						fileWriter:write(gameOptionName.."="..menuEntry_selectedLabel..",\r")
					else
						local menuEntry_selectedValue = menuEntry.selectedValue
						if type(menuEntry.selectedValue) == "boolean" then
							menuEntry_selectedValue = tostring(menuEntry_selectedValue)
						end
						fileWriter:write(gameOptionName.."="..menuEntry_selectedValue..",\r")
					end
				else
					print("ERROR: Easy-Config-Chucked: menuEntry=null in saveConfig")
				end
			end
			fileWriter:close()
		end
	end
end

function NPCConfigSettings.loadConfig()
	for modId,mod in pairs(NPCConfigSettings.mods) do

		NPCConfigSettings.prepModForLoad(mod)

		local config = mod.config
		local menu = mod.menu
		local configFile = "media/config/"..modId..".config"
		local fileReader = getModFileReader(modId, configFile, false)
		if fileReader then
			print("modId: "..modId.." loading")
			for _,_ in pairs(config) do
				local line = fileReader:readLine()
				if not line then break end
				for gameOptionName,label in string.gmatch(line, "([^=]*)=([^=]*),") do
					local menuEntry = menu[gameOptionName]
					if menuEntry then
						if menuEntry.options then
							if menuEntry.optionsKeys[label] then
								menuEntry.selectedIndex = menuEntry.optionsKeys[label][1]
								menuEntry.selectedValue = menuEntry.optionsKeys[label][2]
								menuEntry.selectedLabel = label
							end
						else
							if label == "true" then menuEntry.selectedValue = true
							elseif label == "false" then menuEntry.selectedValue = false
							else menuEntry.selectedValue = tonumber(label) end
						end
						config[gameOptionName] = menuEntry.selectedValue
					else
						print("ERROR: Easy-Config-Chucked: menuEntry=null in loadConfig")
					end
				end
			end
			fileReader:close()
		end
	end
end

Events.OnGameBoot.Add(NPCConfigSettings.loadConfig)


-------------------------


NPCConfig = {}
NPCConfig.config = { ["NPC_NUM"] = 3, ["NPC_NEED_FOOD"] = true, ["NPC_NEED_AMMO"] = true, ["NPC_CAN_INFECT"] = true, ["NPC_POPUP_WINDOW"] = true, ["NPC_DEBUG_CONTEXT"] = true }
NPCConfig.modId = "NPC-Mod" -- needs to the same as in your mod.info
NPCConfig.name = "NPC Settings" -- the name that will be shown in the MOD tab
NPCConfig.menu = {}

NPCConfig.menu["NPC_NUM"] = {type = "Combobox", title = "NPC number", options = {{"0", 0},  {"1", 1}, {"2", 2}, {"3", 3}, {"4", 4}, {"5", 5}, {"6", 6}, {"7", 7}, {"8", 8}, {"9", 9}, {"10", 10}, {"11", 11}, {"12", 12}} }
NPCConfig.menu["NPC_NEED_FOOD"] = {type = "Tickbox", title = "NPC need food"}
NPCConfig.menu["NPC_NEED_AMMO"] = {type = "Tickbox", title = "NPC need ammo"}
NPCConfig.menu["NPC_CAN_INFECT"] = {type = "Tickbox", title = "NPC can get zombie infection"}
NPCConfig.menu["NPC_POPUP_WINDOW"] = {type = "Tickbox", title = "Welcome window"}
NPCConfig.menu["NPC_DEBUG_CONTEXT"] = {type = "Tickbox", title = "Debug context options"}

NPCConfigSettings = NPCConfigSettings or {}
NPCConfigSettings.mods = NPCConfigSettings.mods or {}
NPCConfigSettings.mods[NPCConfig.modId] = NPCConfig