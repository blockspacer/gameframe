local GameLogic 			= class('GameLogic')

function GameLogic:ctor()
	print('hcc>>GameLogic:ctor')
	self:setMetaTable()
	self:init()
end

function GameLogic.getAllFunction(class,meathon)
    meathon = meathon or {}
    if class.super ~= nil then
        meathon = GameLogic.getAllFunction(class.super,meathon)
    end

    local metatable = getmetatable(class)
    if metatable == nil then
        metatable = class
    end
    for i,v in pairs(metatable) do
        meathon[i] = v
    end
    return meathon
end

function GameLogic:setMetaTable()
    local scriptPath = {}
    local path = 'logic_server/GameLogic'
    table.insert(scriptPath, path .. "/GameBaseLogic")
    table.insert(scriptPath, path .. "/GameStepInit")
    table.insert(scriptPath, path .. "/GameStep")
    table.insert(scriptPath, path .. "/GameSendMsg")
    table.insert(scriptPath, path .. "/GameData")

    local tmpmetatable = {}
    for i,v in ipairs(scriptPath) do
        local script = require(v)
        local object = script.new()
        local objectemetatable = getmetatable(object)
        for scripti,scriptv in pairs(objectemetatable) do
            tmpmetatable[scripti] = scriptv
        end
    end
    local metatable = GameLogic.getAllFunction(self)
    for i,v in pairs(metatable) do
        tmpmetatable[i] = v
    end
    setmetatable(self, {__index = tmpmetatable}) 
end

function GameLogic:init()
	if self.init_data then
		self:init_data()
	end
end

return GameLogic