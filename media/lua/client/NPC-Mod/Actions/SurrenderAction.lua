
require "TimedActions/ISBaseTimedAction"

SurrenderAction = ISBaseTimedAction:derive("SurrenderAction");

function SurrenderAction:isValid()
	return true
end

function SurrenderAction:update()
    if self.character then
		self.character:faceThisObjectAlt(self.enemy)
		self.character:setMetabolicTarget(Metabolics.LightDomestic);
    end
end

function SurrenderAction:start()
	self:setActionAnim("surrender")
	self:setOverrideHandModels(nil, nil)
end

function SurrenderAction:stop()
    ISBaseTimedAction.stop(self);
end

function SurrenderAction:perform()
	ISBaseTimedAction.perform(self);
end

function SurrenderAction:new(character, enemy)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.enemy = enemy

	o.mul = 2;
	o.maxTime = 300;

	return o;
end
