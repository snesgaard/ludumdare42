local mutator = {}
mutator.__index = mutator

local function create(master)
    local this = {}
    this.__read = Dictionary.create()
    this.__write = Dictionary.create()
    this.__master = master

    return setmetatable(this, mutator)
end


function mutator:bind(key, read, write)
    self.__read[key] = read
    self.__write[key] = write
    return self
end


function mutator:release(key)
    self.__read[key] = nil
    self.__write[key] = nil
    return self
end


function mutator:__newindex(key, val)
    local f = self.__write[key]
    if not f then
        log.warn("Binding %s does not exist", key)
    else
        if self.__master then
            f(self.__master, val)
        else
            f(val)
        end
    end
end

function mutator:__index(key)
    local f = self.__read[key]

    if not f then
        local r = mutator[key]
        if not r then
            return rawget(self, key)
        else
            return r
        end
    else
        if self.__master then
            return f(self.__master, key)
        else
            return f(key)
        end
    end
end

return create
