
require "TimedActions/ISBaseTimedAction"

ISGetHitAction = ISBaseTimedAction:derive("ISGetHitAction");

function ISGetHitAction:isValid()
	return true
end

function ISGetHitAction:update()
end

local function dist(x, y, player)
    local dx = player:getX() - x
    local dy = player:getY() - y
    local dist = math.sqrt(dx*dx + dy*dy)
    return dist
end

function ISGetHitAction:start()
	local vec = self.character:getForwardDirection()
	
	local x = vec:getX() + self.character:getX()
	local y = vec:getY() + self.character:getY()	
	local forw_dist = dist(x, y, self.enemy)

	local x = vec:getX()*-1 + self.character:getX()
	local y = vec:getY()*-1 + self.character:getY()	
	local back_dist = dist(x, y, self.enemy)

	if forw_dist < back_dist then
		self:setActionAnim("NPC_HitAnim_FRONT")
	else
		self:setActionAnim("NPC_HitAnim_BACK")
	end
end

function ISGetHitAction:stop()
    ISBaseTimedAction.stop(self);
end

function ISGetHitAction:perform()
	ISBaseTimedAction.perform(self);
end

function ISGetHitAction:new(character,enemy)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stopOnWalk = false;
	o.stopOnRun = false;
	o.forceProgressBar = false;
	o.enemy = enemy

	o.mul = 2;
	o.maxTime = 40;

	return o;
end
