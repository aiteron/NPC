require "TimedActions/ISBaseTimedAction"

NPCWalkToAction = ISBaseTimedAction:derive("NPCWalkToAction");

function NPCWalkToAction:isValid()
	if self.character:getVehicle() then return false end
    if self.location == nil then return false end
    return true;
end

function NPCWalkToAction:update()
    if not self:isValid() then return end

    if self.isRun then
        self.character:setRunning(true)
        self.character:setVariable("WalkSpeed", 10);    
    else
        self.character:setVariable("WalkSpeed", 1); 
    end

    if NPCUtils.hasAnotherNPCOnSquare(self.location, self.character:getModData()["NPC"]) then
        local sq = NPCUtils.AdjacentFreeTileFinder_Find(self.location)
        self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
        self.location = sq
    end

    self.result = self.character:getPathFindBehavior2():update();

    if self.result == BehaviorResult.Failed then
        NPCPrint("NPCWalkToAction", "Pathfind failed", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
        
        local nearestDoor = self:getNearestDoor(self.character:getX(), self.character:getY(), self.character:getZ())
        local window = self:getNearestWindow(self.character:getX(), self.character:getY(), self.character:getZ())

        if nearestDoor and (nearestDoor:isLocked() or nearestDoor:isBarricaded()) then
            if window then
                local sq = self:getSameOutsideSquare(self.character, window:getSquare(), window:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ())

                if window:isPermaLocked() or window:isLocked() then
                    if window:isSmashed() then
                        if window:isGlassRemoved() then
                            local act1 = ISClimbThroughWindow:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                            ISTimedActionQueue.addAfter(act1, act2)
                        else
                            local act1 = ISRemoveBrokenGlass:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = ISClimbThroughWindow:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(act1, act2)
                            local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                            ISTimedActionQueue.addAfter(act2, act3)
                        end
                    else
                        local act1 = ISSmashWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = ISRemoveBrokenGlass:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                else
                    if window:IsOpen() then
                        local act2 = ISClimbThroughWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISOpenCloseWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = ISClimbThroughWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                        ISTimedActionQueue.addAfter(act2, act3)
                    end
                end
            end
        end
        
        self.character:getModData().NPC.lastWalkActionFailed = true
        self:forceStop();
        return;
    end

    if self.result == BehaviorResult.Succeeded then
        NPCPrint("NPCWalkToAction", "Pathfind succeeded", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
        self:forceComplete();
    end

    if math.abs(self.lastX - self.character:getX()) > 1 or math.abs(self.lastY - self.character:getY()) > 1 or math.abs(self.lastZ - self.character:getZ()) > 1 then
        self.lastX = self.character:getX();
        self.lastY = self.character:getY();
        self.lastZ = self.character:getZ();
        self.timer = 0
    end
    self.timer = self.timer + 1

    if self.timer == 500 then
        NPCPrint("NPCWalkToAction", "Stop by timer 500", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
        self.character:getModData().NPC.lastWalkActionFailed = true
        self:forceStop()
    end    

    -- Close doors
    if(self.character:getLastSquare() ~= nil ) then
        local cs = self.character:getCurrentSquare()
        local ls = self.character:getLastSquare()
        local tempdoor = ls:getDoorTo(cs);
        if(tempdoor ~= nil and tempdoor:IsOpen()) then
            tempdoor:ToggleDoor(self.character);
        end		
    end
end

function NPCWalkToAction:start()
    if not self:isValid() then return end
    NPCPrint("NPCWalkToAction", "Calling pathfind method", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 

    if self.character:getSquare():isOutside() and not self.location:isOutside() and self.location:getBuilding() then
        local buildID = self.location:getBuilding():getID()

        local doorUnlocked, doorLocked = self:getNearestDoorWithBuildingID(self.location:getX(), self.location:getY(), self.character:getZ(), buildID)
        local windowUnlocked, windowLocked = self:getNearestWindowWithBuildingID(self.location:getX(), self.location:getY(), self.character:getZ(), buildID)
        
        local door = doorUnlocked
        if door == nil then door = doorLocked end
        local window = windowUnlocked
        if window == nil then window = windowLocked end

        if door and not door:isLocked() and not door:isLockedByKey() then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, door:getSquare(), door:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                ISTimedActionQueue.addAfter(self, NPCWalkToAction:new(self.character, self.location, self.isRun, false))
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        elseif window then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, window:getSquare(), window:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                
                if window:isPermaLocked() or window:isLocked() then
                    if window:isSmashed() then
                        if window:isGlassRemoved() then
                            local act1 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act1, act2)
                        else
                            local act1 = ISRemoveBrokenGlass:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(act1, act2)
                            local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act2, act3)
                        end
                    else
                        local act1 = ISSmashWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = ISRemoveBrokenGlass:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                else
                    if window:IsOpen() then
                        local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(self, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISOpenCloseWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = WaitAction:new(self.character, 40)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                end
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        else
            self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
        end
    elseif not self.character:getSquare():isOutside() and self.character:getSquare():getBuilding() and self.location:isOutside() then
        local buildID = self.character:getSquare():getBuilding():getID()

        local doorUnlocked, doorLocked = self:getNearestDoorWithBuildingID(self.location:getX(), self.location:getY(), self.character:getZ(), buildID)
        local windowUnlocked, windowLocked = self:getNearestWindowWithBuildingID(self.location:getX(), self.location:getY(), self.character:getZ(), buildID)

        local door = doorUnlocked
        if door == nil then door = doorLocked end
        local window = windowUnlocked
        if window == nil then window = windowLocked end

        if door then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, door:getSquare(), door:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                ISTimedActionQueue.addAfter(self, NPCWalkToAction:new(self.character, self.location, self.isRun, false))
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        elseif window then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, window:getSquare(), window:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                
                if window:isPermaLocked() then
                    if window:isSmashed() then
                        if window:isGlassRemoved() then
                            local act1 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act1, act2)
                        else
                            local act1 = ISRemoveBrokenGlass:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(act1, act2)
                            local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act2, act3)
                        end
                    else
                        local act1 = ISSmashWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = ISRemoveBrokenGlass:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                else
                    if window:IsOpen() then
                        local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(self, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISOpenCloseWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = WaitAction:new(self.character, 40)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                end
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        else
            self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
        end
    else
        self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
    end
end

function NPCWalkToAction:stop()
    NPCPrint("NPCWalkToAction", "Pathfind cancelled", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
    ISBaseTimedAction.stop(self);
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);
end

function NPCWalkToAction:perform()
    NPCPrint("NPCWalkToAction", "Pathfind complete", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);

    ISBaseTimedAction.perform(self);

    if self.onCompleteFunc then
        local args = self.onCompleteArgs
        self.onCompleteFunc(args[1], args[2], args[3], args[4])
    end
end

function NPCWalkToAction:setOnComplete(func, arg1, arg2, arg3, arg4)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4 }
end


function NPCWalkToAction:new(character, location, isRun, withOptimisation)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;

    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.location = location;
    o.pathIndex = 0;

    o.isRun = isRun
    o.withOptimisation = withOptimisation
    if o.withOptimisation == nil then
        o.withOptimisation = true
    end

    o.lastX = character:getX();
    o.lastY = character:getY();
    o.lastZ = character:getZ();
    o.timer = 0

    return o
end


function NPCWalkToAction:getNearestDoor(x, y, z)
    local result = nil
	local dist = 9999
    for _, door in ipairs(ScanSquaresSystem.doors) do
        if door:getSquare() ~= nil then
            if not door:isBarricaded() then
				local d = NPCUtils.getDistanceBetween(door:getSquare(), getSquare(x, y, z))
				if d < dist then
					result = door
					dist = d
				end
			end
        end
    end
	return result
end

function NPCWalkToAction:getNearestWindow(x, y, z)
    local result = nil
	local dist = 9999
    for _, win in ipairs(ScanSquaresSystem.windows) do
        if win:getSquare() ~= nil then
            if not win:isBarricaded() then
				local d = NPCUtils.getDistanceBetween(win:getSquare(), getSquare(x, y, z))
				if d < dist then
					result = win
					dist = d
				end
			end
        end
    end
	return result
end

function NPCWalkToAction:getSameOutsideSquare(char, sq1, sq2)
    local charSq = char:getSquare()

    if charSq:isOutside() then
        if sq1:isOutside() then
            return sq1
        else
            return sq2
        end
    else
        if not sq1:isOutside() then
            return sq1
        else
            return sq2
        end
    end
end

function NPCWalkToAction:getNearestWindowWithBuildingID(x, y, z, id)
    local resultUnlocked = nil
	local distToUnlocked = 9999
    local resultLocked = nil
	local distToLocked = 9999

    for _, win in ipairs(ScanSquaresSystem.windows) do
        if win:getSquare() ~= nil then
            if not win:isBarricaded() then
                if (win:getSquare() and win:getSquare():getBuilding() and win:getSquare():getBuilding():getID() == id and win:getOppositeSquare() and win:getOppositeSquare():isOutside()) or (win:getOppositeSquare() and win:getOppositeSquare():getBuilding() and win:getOppositeSquare():getBuilding():getID() == id and win:getSquare() and win:getSquare():isOutside()) then
                    local d = NPCUtils.getDistanceBetween(win:getSquare(), getSquare(x, y, z))
                    if win:isLocked() or win:isPermaLocked() then
                        if d < distToLocked then
                            resultLocked = win
                            distToLocked = d
                        end
                    else
                        if d < distToUnlocked then
                            resultUnlocked = win
                            distToUnlocked = d
                        end
                    end
                end
            end
        end
    end
	return resultUnlocked, resultLocked
end

function NPCWalkToAction:getNearestDoorWithBuildingID(x, y, z, id)
    local resultUnlocked = nil
	local distToUnlocked = 9999
    local resultLocked = nil
	local distToLocked = 9999

    for _, door in ipairs(ScanSquaresSystem.doors) do
        if door:getSquare() ~= nil then
            if not door:isBarricaded() then
                if (door:getSquare() and  door:getSquare():getBuilding() and door:getSquare():getBuilding():getID() == id and door:getOppositeSquare() and door:getOppositeSquare():isOutside()) or (door:getOppositeSquare() and door:getOppositeSquare():getBuilding() and door:getOppositeSquare():getBuilding():getID() == id and door:getSquare() and door:getSquare():isOutside()) then
                    local d = NPCUtils.getDistanceBetween(door:getSquare(), getSquare(x, y, z))
                    if door:isLocked() or door:isLockedByKey() then
                        if d < distToLocked then
                            resultLocked = door
                            distToLocked = d
                        end
                    else
                        if d < distToUnlocked then
                            resultUnlocked = door
                            distToUnlocked = d
                        end
                    end
                end
            end
        end
    end
	return resultUnlocked, resultLocked
end