TaskManager = {}
TaskManager.__index = TaskManager

function TaskManager:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.mainPlayer = getPlayer()
    o.character = character

    o.tasks = {}

    return o
end

function TaskManager:update()

    if self.tasks[0] ~= nil then
        NPCInsp("NPC", self.character:getDescriptor():getForename() .. " " .. self.character:getDescriptor():getSurname(), self.tasks[0].task.name)    

        if not self.tasks[0].task:update() then
            self:moveDown()
            return
        end

        if self.tasks[0].task:isComplete() then
            self:moveDown()
            return
        end
    else
        NPCInsp("NPC", self.character:getDescriptor():getForename() .. " " .. self.character:getDescriptor():getSurname(), "None")
    end
end

function TaskManager:addToTop(task, score)
    if self.tasks[0] ~= nil then
        self.tasks[0].task:stop()
    end

    self.tasks[0] = {}
    self.tasks[0].task = task    
    self.tasks[0].score = score
end

function TaskManager:moveDown()
    self.tasks[0] = nil
end

function TaskManager:getCurrentTaskScore()
    if self.tasks[0] == nil then return 0 end
    return self.tasks[0].score
end

function TaskManager:clear()
    if self.tasks[0] ~= nil then
        self.tasks[0].task:stop()
    end
    self.tasks = {}
end

function TaskManager:getCurrentTaskName()
    if self.tasks[0] == nil then return end
    return self.tasks[0].task.name
end