local sti = require "modules/sti"
local tilemap = require "physics/tilemap"
local collision = require "physics/collision"

local level = {}

function level:create(path)
    self.visual = sti(path)
    self.physics = tilemap.from_tiled(self.visual, "geometry")

    self:__init_actors(self.visual)

    local _old_draw = self.visual.layers.phantom.draw

    function self.visual.layers.phantom:draw(...)
        gfx.setColor(0.2, 0.5, 1, 1)
        _old_draw(self, ...)
    end
end

function level:insert_phantom(x, y, gid)
    return self:__insert_tile(x, y, gid, nil, true)
end

function level:insert_tile(x, y, gid, type)
    return self:__insert_tile(x, y, gid, type)
end

function level:__insert_tile(x, y, gid, type, phantom)
    phantom = phantom or nil

    type = type or self.physics.types.FULL
    local tile = self.visual.tiles[gid]

    if not tile then return end

    local layers = self.visual.layers

    local layer = phantom and layers.phantom or layers.geometry

    if x < 1 or y < 1 or layer.width < x or layer.height < y then
        return
    end

    layer.data[y][x] = tile
    self.visual:addLayerTile(
        layer, tile, x, y
    )

    if not phantom then
        self.physics:insert(x - 1, y - 1, self.physics.types.FULL)
    end
end

function level:remove_phantom(x, y)
    return self:__remove_tile(x, y, true)
end

function level:remove_tile(x, y)
    return self:__remove_tile(x, y, false)
end

function level:__remove_tile(x, y, phantom)
    local layer_key = phantom and "phantom" or "geometry"
    local layer = self.visual.layers[layer_key]

    if x < 1 or y < 1 or layer.width < x or layer.height < y then
        return
    end

    self.visual:removeLayerTile(layer, x, y)

    if not phantom then
        self.physics:insert(x - 1, y - 1, nil)
    end
end


function level:__init_actors(map)
    local layer = map.layers["actor"]

    if not layer then return end

    layer.actors = dict()

    for _, obj in pairs(layer.objects) do
        local act = require("actor/" .. obj.type)
        local id = obj.name ~= "" and obj.name or obj.type .. obj.id

        if layer.actors[id] then
            log.warn("Naming collision <%s>", id)
        end

        if act.visual and obj.visible then
            act.visual(id)
        end
        if act.state and obj.visible then
            local s = spatial(obj.x, obj.y, obj.width, obj.height)
            act.state(id, s, obj.properties)
        end

        layer.actors[id] = obj
    end

    function layer:update(dt)
        for _, s in pairs(visual.sprite) do
            s:update(dt)
        end
    end

    function layer:draw(...)
        for id, _ in pairs(self.actors) do
            local pos = nodes.actor_state:get_stat("spatial", id)
            local s = visual.sprite[id]
            if s and pos then
                s:draw(pos.x + pos.w * 0.5, pos.y + pos.h)
            end
        end
    end
end

function level:rectangle(...)
    local s, e, c = self.physics:rectangle(...)
    local o = vec2(1, 1)
    return s + o, e + o, c
end

function level:__update_physics(dt)
    local physics = self.physics
    local default_gravity = vec2(0, 10000)

    function get_actors()
        local a = self.visual.layers.actor
        if not a then
            return
        end
        return a.actors
    end

    local a = get_actors()

    if not a then return end

    local nas = nodes.actor_state
    for id, _ in pairs(a) do
        local g = nas:get_stat("gravity", id) or default_gravity
        local s = nas:get_stat("speed", id) or vec2(0, 0)
        local b = nas:get_stat("spatial", id)

        s = s + g * dt

        nas:set_stat("speed", id, s)

        local function handle_physics()
            if not b then return end

            local b, cx, cy = physics:move(b, s * dt)

            if cx then
                local cbx = get_stat("tile/collision/x", id)
                if cbx then
                    cbx(id, b)
                end
            end
            if cy then
                local cby = get_stat("tile/collision/y", id)
                if cby then
                    cby(id, b)
                end
                nas:set_stat("speed", id, vec2(s.x, 0))
            end

            nas:set_stat("spatial", id, b)
        end

        if not get_stat("tile/ghost", id) then
            handle_physics()
        elseif b then
            local st = s * dt
            set_stat("spatial", id, b:move(st.x, st.y))
        end
    end
end

function level:__update_collision()
    local spatials = nodes.actor_state:get_stat("spatial")

    for id, s in pairs(spatials) do
        s.id = id
    end

    local smash = collision.detect(spatials:values())

    for box, all_boxes in pairs(smash) do
        local id = box.id

        local c = get_stat("on_collision", id) or function() end
        c(id, all_boxes)
    end

    local tile_col = nodes.actor_state:get_stat("tile/collision/tile")

    for id, cb in pairs(tile_col) do
        local s = nodes.actor_state:get_stat("spatial", id)
        if s then
            local l, u = self:rectangle(s:unpack())
            for x = l.x, u.x do
                for y = l.y, u.y do
                    local type = self.physics:index(x - 1, y - 1)
                    if type then
                        cb(id, x, y, type)
                    end
                end
            end
        end
    end
end

function level:__update(dt)
    for id, ai in pairs(nodes.actor_state:get_stat("script")) do
        ai:update(dt, id)
    end

    self:__update_physics(dt)

    self:__update_collision()

    self.visual:update(dt)
end

function level:__draw(x, y)
    gfx.setColor(1, 1, 1)
    self.visual:draw(x, y)

    if not self.draw_physics then
        gfx.setColor(1, 1, 1, 0.5)
        self.physics:draw(x ,y)

        for _, s in pairs(nodes.actor_state:get_stat("spatial")) do
            gfx.setColor(0.2, 0.5, 1, 0.75)
            gfx.rectangle("line", s.x, s.y, s.w, s.h)
            gfx.setColor(0.2, 0.5, 1, 0.25)
            gfx.rectangle("fill", s.x, s.y, s.w, s.h)
        end
    end
end

return level
