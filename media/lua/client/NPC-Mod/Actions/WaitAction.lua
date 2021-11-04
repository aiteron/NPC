
require "TimedActions/ISBaseTimedAction"

WaitAction = ISBaseTimedAction:derive("WaitAction");

function WaitAction:isValid()
	return true
end

function WaitAction:update()
end

function WaitAction:start()
	
end

function WaitAction:stop()
    ISBaseTimedAction.stop(self);
end

function WaitAction:perform()
	ISBaseTimedAction.perform(self);
end

function WaitAction:new(character, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stopOnWalk = false;
	o.stopOnRun = false;
	o.forceProgressBar = false;

	o.mul = 2;
	o.maxTime = time;

	return o;
end
