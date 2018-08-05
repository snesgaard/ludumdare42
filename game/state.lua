local dict = Dictionary.create
local rng = love.math.random

local function create_actor_state()
    return dict{
        health = dict{
            max = dict{}, current = dict{}
        },
        ability = dict{},
        power = dict{},
        defense = dict{},
        agility = dict{},
        armor = dict{},
        shield = dict{},
        charge = dict{},
        script = dict{},
        name = dict{}
    }
end


local function create_events()
    return dict{
        on_damage = Event.create(),
        on_heal = Event.create(),
    }
end


local State = {}
State.__index = State

function State:create()
    self.actor = create_actor_state()
    self.event = create_events()
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
        return stat[id]
    else
        log.warn("Stat %s does not exist", path)
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

function State:is_alive(id)
    local hp = self.actor.health.current[id]
    return hp and hp > 0
end

function State:damage(attacker, defender, damage)
    local agi_a = self:get_stat("agility", attacker) or 0
    local agi_d = self:get_stat("agility", defender) or 0

    local crit_chance = (agi_a - agi_d) / 10.0
    local miss_chance = (agi_d - agi_a) / 10.0

    local crit = crit_chance > rng()
    local miss = miss_chance > rng()

    local power = self.actor.power[attacker]
    local armor = self:get_stat("armor", defender) or 0

    local charge = self:get_stat("charge", attacker) or 0
    local s = charge > 0 and 2 or 1
    local shield = self:get_stat("shield", defender) or 0
    s = shield > 0 and 0 or s
    s = miss and 0 or s
    s = crit and s * 2 or s

    damage = math.max(0, s * (damage + power) - armor)
    local hp = self.actor.health.current[defender]
    local next_hp = math.max(0, hp - damage)

    self:set_stat("charge", attacker, 0)
    if not miss then
        self:set_stat("shield", defender, 0)
    end
    self:set_stat("health/current", defender, next_hp)

    local effective_damage = hp - next_hp

    local info = dict{
        attacker = attacker,
        defender = defender,
        damage = effective_damage,
        charged = charge > 0,
        shielded = shield > 0,
        miss = miss,
        crit = crit,
    }

    self.event.on_damage(info)

    return info
end

function State:heal(caster, target, heal)
    local power = self.actor.power[caster] or 0
    heal = math.max(0, heal + power)
    local hp = self.actor.health.current[target]
    local max_hp = self.actor.health.max[target]
    local next_hp = math.clamp(hp + heal, 0, max_hp)

    self:set_stat("health/current", target, next_hp)

    local effective_heal = next_hp - hp

    local info = dict{
        caster = caster,
        target = target,
        heal = effective_heal
    }

    self.event.on_heal(info)

    return info
end

return State
