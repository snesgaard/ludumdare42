local ai = {}

function ai:create(id)
    self:set_state(ai.active, id)
end

ai.active = {}
function ai.active.enter(self, id)
    local function cool_cb(id)
        self:set_state(ai.passive, id, self.prev)
    end

    set_stat("on_collision", id, cool_cb)

    self.__update = ai.active.__update_tile
end

function ai.active.exit(self, id)
    set_stat("on_collision", id)
end

function ai.active.__update_tile(self, dt, id)
    if self.skip then
        return
    end

    if self.prev_tile then
        local l, u = unpack(self.prev_tile)
        for x = l.x, u.x do
            for y = l.y, u.y do
                nodes.level:remove_phantom(x, y)
            end
        end
    end

    local s = get_stat("spatial", id)
    local l, u, c = nodes.level:rectangle(s:unpack())

    for x = l.x, u.x do
        for y = l.y, u.y do
            nodes.level:insert_phantom(x, y, 1)
        end
    end

    self.prev_tile = {l, u}

    if c then
        return self:set_state(ai.passive, id, self.prev)
    end
end

ai.passive = {}
function ai.passive.enter(self, id, prev)
    if not prev or true then
        local s = get_stat("spatial", id)
        local l, u, c = nodes.level:rectangle(s:unpack())
        prev = {l, u}
    end

    local l, u = unpack(prev)

    for x = l.x, u.x do
        for y = l.y, u.y do
            nodes.level:remove_phantom(x, y, 1)
            nodes.level:insert_tile(x, y, 1, 1)
        end
    end

    set_stat("gravity", id, vec2(0, 0))
    set_stat("speed", id, vec2(0, 0))

    self.__update = function() end
end

local blast = {}

function blast.state(id, s, props)
    set_stat("spatial", id, s)
    set_stat("gravity", id, vec2(0, 1000))
    set_stat("script", id, process.create(ai, id))
    set_stat("tile/ghost", id, true)

    if props.setup then
        set_stat("speed", id, vec2(500, 0))
    else
        set_stat("speed", id, vec2(-500, 0))
    end
end


return blast
