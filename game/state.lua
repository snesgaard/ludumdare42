local dict = Dictionary.create
local rng = love.math.random

local function create_actor_state()
    return dict{

    }
end


local function create_events()
    return dict{

    }
end


local State = {}
State.__index = State

function State:create(actor_state, events)
    self.actor = actor_state() or dict{}
    self.event = events() or dict{}
    self.stat_events = dict{}
end

local function get_path_parts(path)
    return string.split(path, '/')
end

local function get_stat_table(parts, root)
    if parts:size() == 0 then
        return root
    end
    local p = parts:head()
    local leaf = root[p]
    if type(leaf) == "table" then
        return get_stat_table(parts:body(), leaf)
    else
        return leaf
    end
end

function State:map_stat(path, id, f)
    local value = self:get_stat(path, id)
    value = f(value)
    self:set_stat(path, id, value)
    return self
end

function State:set_stat(path, id, value)
    local stat = get_stat_table(get_path_parts(path), self.actor)
    if type(stat) == "table" then
        local prev_value = stat[id]
        stat[id] = value
        local event = self.stat_events[path]
        if event then
            event(id, value, prev_value)
        end
    else
        log.warn("Stat %s does not exist", path)
    end
    return self
end

function State:get_stat(path, id)
    local stat = get_stat_table(get_path_parts(path), self.actor)
    if type(stat) == "table" then
        if id then
            return stat[id]
        else
            return stat
        end
    else
        --log.warn("Stat %s does not exist", path)
        return
    end
end

function State:monitor_stat(path, callback, id)
    local stat = get_stat_table(get_path_parts(path), self.actor)

    if type(stat) ~= "table" then
        log.warn("Stat %s does not exist", path)
        return
    end

    if not self.stat_events[path] then
        self.stat_events[path] = event()
    end
    local e = self.stat_events[path]

    if id then
        local old_cb = callback
        callback = function(_id, _value)
            if _id == id then
                return old_cb(_id, _value)
            end
        end

        local stat = self:get_stat(path, id)
        if stat then
            callback(id, stat)
        end
    else
        local stat_tab = get_stat_table(get_path_parts(path), self.actor)
        for id, value in pairs(stat_tab) do
            callback(id, value)
        end
    end
    return e:listen(callback)
end


return State
